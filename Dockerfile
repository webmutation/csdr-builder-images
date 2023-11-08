FROM buildpack-deps:22.04-curl
ARG JAVA_SDK_URL=https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_linux-x64_bin.tar.gz
ARG NODE_MAJOR=20 # NodeJS

RUN set -x \
    && apt-get update \
    && apt-get install -y locales ca-certificates-java git

# NOTE: adding ca-certificates-java jdk8 version, before adding the backport. new version is not compatible.     
ENV LANG C.UTF-8
RUN locale-gen $LANG

# Install Java  LTS / OpenJDK 17
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    curl --retry 3 -Lfso /tmp/openjdk21.tar.gz ${JAVA_SDK_URL}; \
    mkdir -p /opt/java/openjdk21; \
    cd /opt/java/openjdk21; \
    tar -xf /tmp/openjdk21.tar.gz --strip-components=1; \
    export PATH="/opt/java/openjdk21/bin:$PATH"; \
    rm -rf /tmp/openjdk21.tar.gz;


ENV JAVA_HOME=/opt/java/openjdk21 \
    PATH="/opt/java/openjdk21/bin:$PATH"

# Install maven
ENV MAVEN_VERSION 3.8.8

RUN mkdir -p /usr/share/maven \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
VOLUME /root/.m2

# install NodeJS
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs yarn bzip2 zip unzip \
    && npm install -g npm@8.19.2

# Make 'node' available
RUN set -x \
    && touch ~/.bashrc \
    && echo 'alias nodejs=node' > ~/.bashrc

# Install Chrome
RUN echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/chrome.list
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -

RUN set -x \
    && apt-get update \
    && apt-get install -y \
        xvfb \
        google-chrome-stable bzip2 zip

ADD scripts/xvfb-chrome /usr/bin/xvfb-chrome
RUN ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome
ENV CHROME_BIN /usr/bin/google-chrome

# Install Sonar Scanner 
# In case of problems try to downgrade the version of the scanner
ENV SONAR_SCANNER_VERSION 4.7.0.2747

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip && \
    unzip sonar-scanner-cli-${SONAR_SCANNER_VERSION} && \
    cd /usr/bin && ln -s /sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner sonar-scanner && \
    ln -s /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner

# Utility for Sonar Scanner 
COPY sonar-scanner-run.sh /usr/bin