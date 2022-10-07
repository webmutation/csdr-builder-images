FROM buildpack-deps:22.04-curl

RUN set -x \
    && apt-get update \
    && apt-get install -y locales ca-certificates-java git openjdk-11-jre openjdk-11-jre-headless openjdk-11-jdk openjdk-11-jdk-headless

# NOTE: adding ca-certificates-java jdk8 version, before adding the backport. new version is not compatible.    
       
ENV LANG C.UTF-8
RUN locale-gen $LANG

#
# Install Java 11 LTS / OpenJDK 11
#
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
RUN export JAVA_HOME

# Install maven
ENV MAVEN_VERSION 3.6.3

RUN mkdir -p /usr/share/maven \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
VOLUME /root/.m2

# Install node 14
RUN set -x \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get update \
    && apt-get install -y \
        nodejs \
    && npm install -g npm@latest
    && npm install -g yarn

# Make 'node' available
RUN set -x \
    && touch ~/.bashrc \
    && echo 'alias nodejs=node' > ~/.bashrc

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        bzip2 zip

# Install Sonar Scanner 
# In case of problems try to downgrade the version of the scanner
ENV SONAR_SCANNER_VERSION 4.7.0.2747

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip && \
    unzip sonar-scanner-cli-${SONAR_SCANNER_VERSION} && \
    cd /usr/bin && ln -s /sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner sonar-scanner && \
    ln -s /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner

# Utility for Sonar Scanner 
COPY sonar-scanner-run.sh /usr/bin