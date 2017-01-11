
function ec2_instance_ip() {
  aws ec2 describe-instances --filter Name=tag:Name,Values=$env.xpenses \
    | jq -r '.Reservations[0].Instances[0].PublicIpAddress'
}

private_key=/Users/mvaccari/work/thoughtworks/aws-cloud-guru/mv-cloudguru-keypair.pem
