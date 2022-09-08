# Dockerfile for CSDR/eUI Gitlab Builds

Is a fork of https://bitbucket.org/atlassian/docker-node-jdk-chrome-firefox

This Dockerfile contains:

* Ubuntu 22.04 LTS
* SCM tools
* Java OpenJDK 8 (latest)
* Maven (3.6.3) older version for compatibility 
* Node 14.x LTS
* npm and yarn latest
* Google Chrome latest
* Bzip2 & Zip
* SonarScanner CLI (4.7.0.2747)

## How to build the image
```
docker build -t docker-gitlab-build .
```

then use `docker images` to find the image ID.

With `docker run -it <IMAGE_ID>` you can test if your changes are the desired ones.

Then tag it: `docker tag <IMAGE_ID> <YOUR-USER>/docker-gitlab-build:latest`

and finally publish it: `docker push <YOUR-USER>/docker-gitlab-build`