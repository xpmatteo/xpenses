
 - remove randomization of role name;
 - check if role exists before creating it
 - check if sleeps are still needed; try to get rid of one
 - move role permissions out of the lib and into the script/create-env
 - give permission to one table only
 - clean names; use hyphens everywhere, remove "host"





 - use VPC per env so that each VPC gets its own sec group and instance_profile







 - actually load the data in dynamodb and perform the calculation
 - use cloudfront for serving static content
 - smoke test: get the IP dynamically
 - use puma for serving content
 - avoid running ruby under root