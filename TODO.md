
 - destroy vpc when destroying env
 - create subnet in vpc
 - create instanc in given subnet

 - remove hardcoded key pair references, use env vars

 - actually load the data in dynamodb and perform the calculation
 - use cloudfront for serving static content
 - smoke test: get the IP dynamically
 - use puma for serving content
 - avoid running ruby under root