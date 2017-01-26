require 'aws-sdk'
require 'ostruct'

# see api docs here: http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Instance.html
# see examples here: http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/

$region = 'eu-central-1'
$key_name = 'matteo-free'

module Infrastructure

  def create_instance name, env, params
    return if find_instance name, env

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

  def find_security_group name, env
    ec2 = Aws::EC2::Resource.new(region: $region)

    groups = ec2.security_groups({filters: [
      {name: 'tag:Name', values: [name]},
      {name: 'tag:Env', values: [env]},
    ]})
    return groups.first
  end

  def delete_instances env
    ec2 = Aws::EC2::Resource.new(region: $region)

    instances= ec2.instances({filters: [
      {name: 'tag:Env', values: [env]},
    ]})
    instances.each do |i|
      if i.exists?
        case i.state.name
        when "terminated"
          # do nothing
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
      i.delete
    end
  end

  def create_security_group name, env
    sg = find_security_group(name, env)
    return sg if sg
    ec2 = Aws::EC2::Resource.new(region: $region)
    sg = ec2.create_security_group({
      group_name: name,
      description: "SG for #{name} in #{env}",
    })
    sg.create_tags(make_tags(name, env))
    yield sg
    return sg
  end

  private

  def make_tags name, env
    { tags: [
        { key: 'Name', value: name },
        { key: 'Env', value: env },
    ]}
  end
end