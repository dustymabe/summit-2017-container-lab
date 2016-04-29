Bulding bigapp
==============
```
cd bigapp/
docker build -t monolithic .
```

Running bigapp
==============
```
docker run -p 80:80 --name=bigapp -e DBUSER=user -e DBPASS=mypassword -e DBNAME=mydb -d monolithic
```

Accessing bigapp
================

To access wordpress on the bigapp container you must point your
browser to the host the container is running on:

*http://host:80*
