FROM debian:11-slim AS base

# Set environment variables
ENV LANG=C.UTF-8 \
    MAVEN_VERSION=3.8.8 \
    SONAR_SCANNER_VERSION=4.7.0.2747 \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/ \
    MAVEN_HOME=/usr/share/maven \
    CHROME_BIN=/usr/bin/google-chrome

# Install dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
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
        make; \
    locale-gen "$LANG"; \
    rm -rf /var/lib/apt/lists/*

# Install Maven
RUN set -eux; \
    mkdir -p "$MAVEN_HOME"; \
    curl -fsSL "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-bin.tar.gz" \
    | tar -xzC "$MAVEN_HOME" --strip-components=1; \
    ln -s "$MAVEN_HOME/bin/mvn" /usr/bin/mvn

VOLUME /root/.m2

# Install Node.js
RUN set -eux; \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -; \
    apt-get update; \
    apt-get install -y --no-install-recommends nodejs; \
    npm install -g npm@10.9.0; \
    npm uninstall -g cross-spawn; \
    npm cache clean --force; \
    npm install -g \
        cross-spawn@7.0.5 \
        @semantic-release/git \
        @semantic-release/gitlab \
        @semantic-release/exec \
        @semantic-release/changelog \
        @terrestris/maven-semantic-release \
        @saithodev/semantic-release-backmerge; \
    rm -rf /var/lib/apt/lists/*

# Install Chrome
RUN set -eux; \
    mkdir -p /etc/apt/keyrings; \
    wget -qO /etc/apt/keyrings/google-chrome.asc https://dl.google.com/linux/linux_signing_key.pub; \
    echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.asc] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends google-chrome-stable; \
    rm -rf /var/lib/apt/lists/*

# Install Sonar Scanner
RUN set -eux; \
    wget -q "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip"; \
    unzip "sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip" -d /opt; \
    ln -s "/opt/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner" /usr/bin/sonar-scanner; \
    rm -f "sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip"

# Copy utility scripts
COPY sonar-scanner-run.sh /usr/bin/
COPY scripts/xvfb-chrome /usr/bin/xvfb-chrome
RUN ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome

# Ensure 'node' command is available
RUN echo 'alias nodejs=node' >> /etc/bash.bashrc
