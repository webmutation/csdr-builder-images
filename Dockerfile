FROM debian:11-slim AS base

# Install dependencies
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        ca-certificates-java \
        git \
        openjdk-11-jre-headless \
        openjdk-11-jdk-headless \
        curl \
        unzip \
        wget \
        gnupg \
        xvfb \
        bzip2 \
        zip \
        gcc \
        g++ \
        make \
    && rm -rf /var/lib/apt/lists/*

# Set locale
ENV LANG C.UTF-8
RUN locale-gen $LANG

# Install Maven
ENV MAVEN_VERSION 3.8.8
RUN mkdir -p /usr/share/maven \
    && curl -fsSL https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
VOLUME /root/.m2

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Node packages
RUN npm install -g \
    @semantic-release/git \
    @semantic-release/gitlab \
    @semantic-release/exec \
    @semantic-release/changelog \
    @terrestris/maven-semantic-release \
    @saithodev/semantic-release-backmerge

# Install Chrome
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Sonar Scanner
ENV SONAR_SCANNER_VERSION 4.7.0.2747
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip \
    && unzip sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip -d /opt \
    && ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /usr/bin/sonar-scanner

# Utility for Sonar Scanner
COPY sonar-scanner-run.sh /usr/bin

# Set JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64/
RUN export JAVA_HOME

# Make 'node' available
RUN echo 'alias nodejs=node' >> ~/.bashrc

# Add xvfb-chrome script
ADD scripts/xvfb-chrome /usr/bin/xvfb-chrome
RUN ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome
ENV CHROME_BIN /usr/bin/google-chrome
