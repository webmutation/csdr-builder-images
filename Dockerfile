FROM buildpack-deps:20.04-curl

# Install Java 8

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        locales git curl=7.68.0-1ubuntu2.13 libgcrypt20=1.8.5-5ubuntu1.1

ENV LANG en_US.UTF-8
RUN locale-gen $LANG

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        ca-certificates-java \
        openjdk-8-jre-headless \
        openjdk-8-jre \
        openjdk-8-jdk-headless \
        openjdk-8-jdk

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

# Install maven
ENV MAVEN_VERSION 3.6.3

RUN mkdir -p /usr/share/maven \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

VOLUME /root/.m2

# Install node 10
RUN set -x \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get update \
    && apt-get install -y \
        nodejs \
    && npm install -g npm@6.14.12

# Make 'node' available
RUN set -x \
    && touch ~/.bashrc \
    && echo 'alias nodejs=node' > ~/.bashrc

# Install yarn 1.7+

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        yarn

# Install Chrome

RUN echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/chrome.list

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        xvfb \
        google-chrome-stable

ADD scripts/xvfb-chrome /usr/bin/xvfb-chrome
RUN ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome

ENV CHROME_BIN /usr/bin/google-chrome

# This is needed for PhantomJS
RUN set -x && \
    apt-get update && \
    apt-get install -y \
        bzip2 \
        zip

# Install Sonar Scanner 
# In case of problems try to downgrade the version of the scanner

ENV SONAR_SCANNER_VERSION 3.2.0.1227

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip && \
    unzip sonar-scanner-cli-${SONAR_SCANNER_VERSION} && \
    cd /usr/bin && ln -s /sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner sonar-scanner && \
    ln -s /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner

# Utility for Sonar Scanner 
	
COPY sonar-scanner-run.sh /usr/bin

# RUN node -v
# RUN npm -v
# RUN yarn -v
# RUN java -version
# RUN mvn -v
# RUN apt-cache policy firefox-esr | grep Installed | sed -e "s/Installed/Firefox/"
# RUN apt-cache policy google-chrome-stable | grep Installed | sed -e "s/Installed/Chrome/"
