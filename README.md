# Dockerfile for CSDR/eUI Gitlab Builds

Is a fork of https://bitbucket.org/atlassian/docker-node-jdk-chrome-firefox

This Dockerfile contains:

* SCM tools
* Java OpenJDK 8
* Maven 3.6.3
* Node 12.x LTS
* npm and yarn latest
* Google Chrome latest
* Bzip2 (for PhantomJS install)
* Zip
* SonarScanner to be able to run Sonar Runner and send reports to SonarQube

## How to build the image
```
docker build -t docker-gitlab-build .
```

then use `docker images` to find the image ID.

With `docker run -it <IMAGE_ID>` you can test if your changes are the desired ones.

Then tag it: `docker tag <IMAGE_ID> <YOUR-USER>/docker-gitlab-build:latest`

and finally publish it: `docker push <YOUR-USER>/docker-gitlab-build`