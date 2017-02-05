

 - require the XPENSES_REGION env var

 - make second part of key a hash of all values
 - upload xls file from UI
 - find end-of-file automatically


 - destroy vpc when destroying env
 - create subnet in vpc
 - create instanc in given subnet

 - remove hardcoded key pair references, use env vars
 - remove hardcoded region references, use env vars

 - actually load the data in dynamodb and perform the calculation

 - smoke test: get the IP dynamically
 - use puma for serving content
 - avoid running ruby under root