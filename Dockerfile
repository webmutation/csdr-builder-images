FROM buildpack-deps:22.04-curl
ARG GRAAL_URL=https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-17.0.9/graalvm-community-jdk-17.0.9_linux-x64_bin.tar.gz

# Install graalvm java 17
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        locales git libgcrypt20=1.9.4-3ubuntu3 make gcc

ENV LANG en_US.UTF-8
RUN locale-gen $LANG

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    curl --retry 3 -Lfso /tmp/graalvm.tar.gz ${GRAAL_URL}; \
    mkdir -p /opt/java/graalvm; \
    cd /opt/java/graalvm; \
    tar -xf /tmp/graalvm.tar.gz --strip-components=1; \
    export PATH="/opt/java/graalvm/bin:$PATH"; \
    rm -rf /tmp/graalvm.tar.gz;

ENV JAVA_HOME=/opt/java/graalvm \
    PATH="/opt/java/graalvm/bin:$PATH"
    
RUN export JAVA_HOME

RUN gu install native-image
# Install maven
ENV MAVEN_VERSION 3.8.8

RUN mkdir -p /usr/share/maven \
  && curl -fsSL https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

VOLUME /root/.m2

# Install node 10
RUN set -x \
    && curl -sL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y \
        nodejs \
    && npm install -g npm@8.19.2

# Make 'node' available
RUN set -x \
    && touch ~/.bashrc \
    && echo 'alias nodejs=node' > ~/.bashrc

# Install yarn

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

ENV SONAR_SCANNER_VERSION 4.7.0.2747

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip && \
    unzip sonar-scanner-cli-${SONAR_SCANNER_VERSION} && \
    cd /usr/bin && ln -s /sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner sonar-scanner && \
    ln -s /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner

# Utility for Sonar Scanner 
	
COPY sonar-scanner-run.sh /usr/bin