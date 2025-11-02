FROM buildpack-deps:25.10-scm

# Configure key runtime tooling while keeping OpenJDK pinned to 17
ENV LANG=C.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/ \
    MAVEN_VERSION=3.9.9 \
    MAVEN_HOME=/usr/share/maven \
    SONAR_SCANNER_VERSION=7.3.0.5189-linux-x64 \
    CHROME_BIN=/usr/bin/google-chrome \
    NODE_VERSION=20.18.0 \
    NPM_VERSION=10.9.0 \
    JQ_VERSION=1.8.1

# Install required packages and dependencies
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        ca-certificates \
        ca-certificates-java \
        gnupg \
        git \
        openjdk-17-jre \
        openjdk-17-jre-headless \
        openjdk-17-jdk \
        openjdk-17-jdk-headless \
        gcc \
        g++ \
        make \
        xvfb \
        bzip2 \
        xz-utils \
        zip \
        unzip \
    && locale-gen $LANG \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js from official tarball (NodeSource lacks Ubuntu 25.10 repo)
RUN set -x \
    && curl -fsSL https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm -f /tmp/node.tar.xz \
    && ln -sf /usr/local/bin/node /usr/bin/node \
    && ln -sf /usr/local/bin/npm /usr/bin/npm \
    && ln -sf /usr/local/bin/npx /usr/bin/npx \
    && npm install -g npm@$NPM_VERSION \
    && npm uninstall -g cross-spawn || true \
    && npm_root="$(npm root -g)" \
    && find "$npm_root" -name "cross-spawn" -type d -prune -exec rm -rf {} + \
    && npm cache clean --force \
    && npm install -g cross-spawn@7.0.6

# Install jq
RUN set -x \
    && curl -fsSL -o /usr/local/bin/jq "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" \
    && chmod +x /usr/local/bin/jq

# Add Google Chrome repository and install Chrome
RUN set -x \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Maven
RUN mkdir -p /usr/share/maven \
    && curl -fsSL https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
VOLUME /root/.m2

# Install Sonar Scanner
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip -O /tmp/sonar-scanner.zip \
    && unzip /tmp/sonar-scanner.zip -d /usr/share \
    && ln -s /usr/share/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /usr/bin/sonar-scanner \
    && ln -s /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner \
    && rm -rf /tmp/sonar-scanner.zip

# Add utility scripts
COPY scripts/xvfb-chrome /usr/bin/xvfb-chrome
COPY sonar-scanner-run.sh /usr/bin

# Set up Chrome and helper aliases
RUN ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome
RUN echo 'alias nodejs=node' >> ~/.bashrc