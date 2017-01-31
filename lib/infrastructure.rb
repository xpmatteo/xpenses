require 'aws-sdk'
require 'ostruct'

# see api docs here: http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Instance.html
# see examples here: http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/

$region = 'eu-central-1'
$key_name = 'matteo-free'

module Infrastructure

  def create_instance name, env, params
    find_instances(name, env).each do |i|
      next if %w(terminated shutting-down).include?(i.state.name)
      puts "Instance #{name} #{i} in #{env} already exists (#{i.state.name})"
      return i
    end

    puts "Creating instance #{name} in #{env}"
    ec2 = Aws::EC2::Resource.new(region: $region)
    defaults = {
      min_count: 1,
      max_count: 1,
    }

    instances = ec2.create_instances(defaults.merge(params))
    instances.batch_create_tags(make_tags(name, env))
    instances.each { |i| i.wait_until_running }
    return instances.first
  end

  def find_instance name, env
    instances = find_instances(name, env)
    if instances.count == 0
      nil
    else
      return instances.first
    end
  end

  def find_instances name, env
    ec2 = Aws::EC2::Resource.new(region: $region)

    instances= ec2.instances({filters: [
      {name: 'tag:Name', values: [name]},
      {name: 'tag:Env', values: [env]},
    ]})
    return instances
  end

  def find_all_live_instances env
    find_all_instances(env).reject { |i| %w(terminated shutting-down).include?(i.state.name) }
  end

  def find_all_instances env
    ec2 = Aws::EC2::Resource.new(region: $region)
    return ec2.instances({filters: [
      {name: 'tag:Env', values: [env]},
    ]})
  end

  def find_security_group name, env
    ec2 = Aws::EC2::Resource.new(region: $region)

    groups = ec2.security_groups({filters: [
      {name: 'tag:Name', values: [name]},
      {name: 'tag:Env', values: [env]},
    ]})
    return groups.first
  end

  def delete_instances env
    find_all_instances(env).each do |i|
      if i.exists?
        case i.state.name
        when "terminated"
          puts "instance #{i.id} is already #{i.state.name}"
        else
          puts "terminating #{i.id} (#{i.state.name})"
          i.terminate
        end
      end
    end
  end

  def delete_security_groups env
    ec2 = Aws::EC2::Resource.new(region: $region)

    groups = ec2.security_groups({filters: [
      {name: 'tag:Env', values: [env]},
    ]})
    groups.each do |i|
      puts "Deleting security group #{i.group_name} in #{env}"
      i.delete
    end
  end

  def create_security_group name, env
    if sg = find_security_group(name, env)
      puts "Security group #{name} in #{env} already exists"
      return sg
    end
    puts "Creating security group #{name} in #{env}"
    ec2 = Aws::EC2::Resource.new(region: $region)
    sg = ec2.create_security_group({
      group_name: name,
      description: "SG for #{name} in #{env}",
    })
    sg.create_tags(make_tags(name, env))
    yield sg
    return sg
  end

  def delete_tables env
    dyn = Aws::DynamoDB::Resource.new(region: $region)
    dyn.tables.each do |table|
      if table.name.end_with?(env)
        puts "Deleting table #{table.name}"
        table.delete
      end
    end
  end

  def create_table name, params
    dyn = Aws::DynamoDB::Resource.new(region: $region)
    if dyn.tables.find { |t| t.table_name == name }
      puts "Table #{name} already exists"
    else
      puts "Creating table #{name}"
      dynamodb_client = Aws::DynamoDB::Client.new(region: $region)
      dynamodb_client.create_table(params)
      dynamodb_client.wait_until(:table_exists, table_name: name)
    end
  end

  def find_all_tables env
    dyn = Aws::DynamoDB::Resource.new(region: $region)
    dyn.tables.select { |t| t.table_name.end_with? env }
  end

  def find_table name
    dyn = Aws::DynamoDB::Resource.new(region: $region)
    dyn.tables.find { |t| t.table_name == name }
  end

  def create_instance_profile_with_policy name, policy
    # see https://aws.amazon.com/blogs/developer/iam-roles-for-amazon-ec2-instances-credential-management-part-4/

    puts "Creating instance profile and role #{name}"

    role_name = name
    policy_name = name
    profile_name = name

    client = Aws::IAM::Client.new(region: $region)
    iam = Aws::IAM::Resource.new(client: client)

    # Let EC2 assume a role
    policy_doc = {
      Version:"2012-10-17",
      Statement:[
        {
          Effect:"Allow",
          Principal:{
            Service:"ec2.amazonaws.com"
          },
          Action:"sts:AssumeRole"
      }]
    }

    role = iam.create_role({
      role_name: role_name,
      assume_role_policy_document: policy_doc.to_json
    })

    # Give the role full access to DynamoDB
    role.attach_policy policy

    response = client.create_instance_profile({
      instance_profile_name: profile_name,
    })
    puts "Waiting for roles to propagate..."
    sleep 10

    client.add_role_to_instance_profile({
      instance_profile_name: profile_name,
      role_name: role_name,
    })

    return response.instance_profile
  end

  private

  def make_tags name, env
    { tags: [
        { key: 'Name', value: name },
        { key: 'Env', value: env },
    ]}
  end
end
