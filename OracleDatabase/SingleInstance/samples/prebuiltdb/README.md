# Example of creating an image with pre-built DB

## 1. Startup a container and create the database

First, you need to start up a container to get a database created. For this you will have to have the image already built.

```
docker run --name oracle-build -p 1521:1521 -p 5500:5500 oracle/database:19.3.0-ee
```

## 2. Reset passwords (optional)

It's recommended to reset the passwords before creating the new prebuilt image. This way you don't have to reset it every time you create a new container.

Connect to the container and reset passwords:
```
docker exec oracle-build ./setPassword.sh <newPassword>
```
## 3. Stop the running container

Stop the container (and therefore also the database) before generating your new prebuilt image:
```
docker stop -t 600 oracle-build
```

## 4. Create the image with the prebuilt database

Create the new image via `docker commit`:
```
docker commit -m "Image with prebuilt database" oracle-build oracle/db-prebuilt:19.3.0-ee
```

## 5. Clean up

Remove the temporary container:
```
docker rm oracle-build
```

## 6. Ready to use your image with prebuild database

Run your prebuild image:

```
docker run --name <container-name> -p 1521:1521 -p 5500:5500 oracle/db-prebuilt:19.3.0-ee
```

After the container is up and running you can connect to the new database.

You can also run your new image from a docker compose.
Create a directory, for example `ora19c-db01`, and add the following docker-compose.yml file:

```
version: '2'
services:
  orcl-node:
    image: oracle/db-prebuilt:19.3.0-ee
    ports:
      - "1521:1521"
      - "5500:5500"
```

And run:

```
docker-compose up
```

*Copyright (c) 2014, 2020 Oracle and/or its affiliates.*
