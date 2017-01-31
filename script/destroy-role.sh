
name=$1

aws iam remove-role-from-instance-profile --instance-profile-name $name --role-name $name
aws iam delete-instance-profile --instance-profile-name $name
policies=$(aws iam list-attached-role-policies --role-name $name | json AttachedPolicies | json -a PolicyArn)
for p in $policies
do
  echo "Removing policy $p"
  aws iam detach-role-policy --role-name $name --policy-arn $p
done
aws iam delete-role --role-name $name
