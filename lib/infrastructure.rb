require 'aws-sdk'
require 'ostruct'
require 'pry'

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
    defaults = {
      min_count: 1,
      max_count: 1,
    }

    instances = ec2_resource.create_instances(defaults.merge(params))
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
    instances= ec2_resource.instances({filters: [
      {name: 'tag:Name', values: [name]},
      {name: 'tag:Env', values: [env]},
    ]})
    return instances
  end

  def find_all_live_instances env
    find_all_instances(env).reject { |i| %w(terminated shutting-down).include?(i.state.name) }
  end

  def find_all_instances env
    ec2_resource.instances({filters: [
      {name: 'tag:Env', values: [env]},
    ]})
  end

  def find_security_group name, env
    groups = ec2_resource.security_groups({filters: [
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
    groups = ec2_resource.security_groups({filters: [
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
    sg = ec2_resource.create_security_group({
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
    table = dyn.tables.find { |t| t.table_name == name }
    if table
      puts "Table #{name} already exists"
    else
      puts "Creating table #{name}"
      client = Aws::DynamoDB::Client.new(region: $region)
      table = client.create_table(params)
      client.wait_until(:table_exists, table_name: name)
    end
    return table
  end

  def find_all_tables env
    dyn = Aws::DynamoDB::Resource.new(region: $region)
    dyn.tables.select { |t| t.table_name.end_with? env }
  end

  def find_table name
    dyn = Aws::DynamoDB::Resource.new(region: $region)
    dyn.tables.find { |t| t.table_name == name }
  end

  def find_role name
    iam_resource.roles.find { |r| r.name == name }
  end

  def find_instance_profile name
    iam_resource.instance_profiles.find { |ip| ip.name == name }
  end

  def create_instance_profile_with_policy name, policy
    role = find_role(name)
    if role
      puts "Role #{name} already exists"
    else
      puts "Creating role #{name}"
      # This role can be assumed by EC2
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

      role = iam_resource.create_role({
        role_name: name,
        assume_role_policy_document: policy_doc.to_json
      })

      # for a managed policy, use
      # role.attach_policy policy

      # the following is for an inline policy
      client.put_role_policy({
        role_name: name,
        policy_name: name,
        policy_document: policy,
      })
    end

    instance_profile = find_instance_profile(name)
    if instance_profile
      puts "Instance profile #{name} already exists"
    else
      puts "Creating instance profile #{name}"
      response = client.create_instance_profile({
        instance_profile_name: name,
      })
      client.add_role_to_instance_profile({
        instance_profile_name: name,
        role_name: name,
      })
      instance_profile = response.instance_profile
      puts "Waiting for instance_profile to propagate..."
      sleep 10
    end
    return instance_profile
  end

  def delete_roles env
    iam_resource.instance_profiles.each do |ip|
      name = ip.instance_profile_name
      if name.end_with? env
        puts "Detaching role #{name} from instance profile #{name}"
        iam_client.remove_role_from_instance_profile({instance_profile_name: name, role_name: name})
        puts "Deleting instance profile #{name}"
        iam_client.delete_instance_profile({instance_profile_name: name})
      end
    end
    iam_resource.roles.each do |role|
      name = role.name
      if name.end_with? env
        role.attached_policies.each do |policy|
          puts "Removing managed policy #{policy.policy_name} from role #{name}"
          role.detach_policy({policy_arn: policy.arn})
        end
        begin
          puts "Removing inline policy from role #{name}"
          iam_client.delete_role_policy({
            role_name: name,
            policy_name: name,
          })
        rescue Aws::IAM::Errors::NoSuchEntity
          puts "No inline policy found in role #{name}"
        end
        puts "Deleting role #{name}"
        role.delete
      end
    end
  end

  def find_all_vpcs env
    ec2_resource.vpcs({filters: [
      {name: 'tag:Env', values: [env]},
    ]})
  end

  def find_vpcs name, env
    ec2_resource.vpcs({filters: [
      {name: 'tag:Name', values: [name]},
      {name: 'tag:Env', values: [env]},
    ]})
  end

  def create_vpc name, env, cidr_block
    vpcs = find_vpcs(name, env)
    if vpcs.count > 0
      puts "Already exists: vpc #{name} in #{env}"
      return vpcs.first
    else
      puts "Creating vpc #{name} in #{env} cidr #{cidr_block}"
      vpc = ec2_resource.create_vpc({ cidr_block: cidr_block })
      vpc.create_tags(make_tags(name, env))
      return vpc
    end
  end

  def destroy_vpc vpc_id
    puts "Destroying vpc #{vpc_id}"
    ec2_client.delete_vpc(vpc_id: vpc_id)
  end

  def destroy_all_vpcs env
    find_all_vpcs(env).each do |vpc|
      destroy_vpc vpc.vpc_id
    end
  end

  def create_subnet name, env, vpc_id, cidr_block
    puts "Creating subnet #{name} in #{env} cidr #{cidr_block}"
    subnet = ec2_resource.create_subnet({
      cidr_block: cidr_block,
      vpc_id: vpc_id
    })
    subnet.create_tags(make_tags(name, env))
    return subnet

    def find_all_subnets env
      ec2_resource.subnets({filters: [
        {name: 'tag:Env', values: [env]},
      ]})
    end
  end

  private

  def ec2_resource
    Aws::EC2::Resource.new(region: $region)
  end

  def ec2_client
    Aws::EC2::Client.new(region: $region)
  end

  def iam_client
    Aws::IAM::Client.new(region: $region)
  end

  def iam_resource
    Aws::IAM::Resource.new(client: iam_client)
  end

  def make_tags name, env
    { tags: [
        { key: 'Name', value: name },
        { key: 'Env', value: env },
    ]}
  end
end
