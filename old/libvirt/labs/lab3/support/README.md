Bulding mariadb
===============
```
pushd mariadb/
docker build -t dbimg .
popd
```

Building wordpress
==================
```
pushd wordpress
docker build -t wpimg .
popd
```

Running mariadb
===============
```
docker run --name=mariadb -e DBUSER=user -e DBPASS=mypassword -e DBNAME=mydb -d dbimg
```

Running wordpress (linking to db)
=================================
```
docker run -p 80:80 --name=wordpress --link=mariadb:db -d wpimg
```

Accessing the app
=================

To access wordpress on the bigapp container you must point your
browser to the host the container is running on:

**http://host:80**
