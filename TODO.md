
 smoke test: with Selenium
 integration test: with rack::test, bypass UI
 unit test: unit test


 summary of all months

 sum 0.10 ten times

 fail if file to upload is too big




 - require the XPENSES_REGION env var

 - avoid double-loading the same row
 - upload xls file from UI


 - destroy vpc when destroying env
 - create subnet in vpc
 - create instanc in given subnet

 - remove hardcoded key pair references, use env vars
 - remove hardcoded region references, use env vars

 - actually load the data in dynamodb and perform the calculation

 - smoke test: get the IP dynamically
 - use puma for serving content
 - avoid running ruby under root