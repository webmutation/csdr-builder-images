FROM buildpack-deps:24.04-scm

# Set environment variables
ENV LANG=C.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/ \
    MAVEN_VERSION=3.8.8 \
    MAVEN_HOME=/usr/share/maven \
    SONAR_SCANNER_VERSION=7.0.2.4839-linux-x64 \
    CHROME_BIN=/usr/bin/google-chrome

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
        nodejs \
        gcc \
        g++ \
        make \
        xvfb \
        bzip2 \
        zip \
        unzip \
    && locale-gen $LANG \
    && curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm uninstall -g cross-spawn || true \
    && npm cache clean --force \
    && npm install -g cross-spawn@7.0.5 \
    && rm -rf /var/lib/apt/lists/*

# Add Google Chrome repository and install Chrome
RUN set -x \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install fix version of cross-spawn
RUN set -x \
    && npm uninstall -g cross-spawn || true \
    && find $(npm root -g) -name "cross-spawn" -type d -exec rm -rf {} + \
    && npm cache clean --force \
    && npm install -g cross-spawn@7.0.5

# Install Maven
RUN mkdir -p /usr/share/maven \
    && curl -fsSL https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# Install Sonar Scanner
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip -O /tmp/sonar-scanner.zip \
    && unzip /tmp/sonar-scanner.zip -d /usr/share \
    && ln -s /usr/share/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /usr/bin/sonar-scanner \
    && rm -rf /tmp/sonar-scanner.zip

# Add utility scripts
COPY scripts/xvfb-chrome /usr/bin/xvfb-chrome
COPY sonar-scanner-run.sh /usr/bin

# Set up Chrome
RUN ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome

# Make 'node' available
RUN echo 'alias nodejs=node' >> ~/.bashrc