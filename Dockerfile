FROM buildpack-deps:25.10-scm

# --- Arguments for Temurin 17 & tool versions ---
ARG TEMURIN_VERSION=jdk-17.0.13+11
ARG TEMURIN_BUILD=17.0.13_11
ARG JAVA_SDK_URL="https://github.com/adoptium/temurin17-binaries/releases/download/${TEMURIN_VERSION}/OpenJDK17U-jdk_x64_linux_hotspot_${TEMURIN_BUILD}.tar.gz"

ARG NODE_VERSION=18.20.3
ARG NPM_VERSION=10.9.0

# --- Environment ---
ENV LANG=C.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/temurin-17 \
    MAVEN_VERSION=3.9.9 \
    MAVEN_HOME=/usr/share/maven \
    SONAR_SCANNER_VERSION=7.3.0.5189-linux-x64 \
    CHROME_BIN=/usr/bin/google-chrome \
    PATH="/usr/lib/jvm/temurin-17/bin:/usr/share/maven/bin:$PATH"

# --- Base packages ---
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        ca-certificates \
        gnupg \
        git \
        gcc \
        g++ \
        make \
        xvfb \
        bzip2 \
        xz-utils \
        zip \
        unzip \
        libfreetype6 \
        libfontconfig1 \
        libasound2t64 \
    && locale-gen $LANG \
    && rm -rf /var/lib/apt/lists/*

# --- Install Temurin JDK 17 ---
RUN set -eux \
    && curl -fsSL "${JAVA_SDK_URL}" -o /tmp/temurin.tar.gz \
    && mkdir -p "${JAVA_HOME}" \
    && tar -xzf /tmp/temurin.tar.gz -C "${JAVA_HOME}" --strip-components=1 \
    && ln -sf "${JAVA_HOME}" /usr/lib/jvm/default-java \
    && ln -sf "${JAVA_HOME}/bin/java" /usr/bin/java \
    && ln -sf "${JAVA_HOME}/bin/javac" /usr/bin/javac \
    && rm -f /tmp/temurin.tar.gz

# --- Install Node.js 18 & pinned npm, cleanup & cross-spawn fix ---
RUN set -eux \
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

# --- Google Chrome ---
RUN set -eux \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# --- Maven ---
RUN set -eux \
    && mkdir -p /usr/share/maven \
    && curl -fsSL https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-bin.tar.gz \
        | tar -xzC /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

VOLUME /root/.m2

# --- Sonar Scanner ---
RUN set -eux \
    && curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip -o /tmp/sonar-scanner.zip \
    && unzip /tmp/sonar-scanner.zip -d /usr/share \
    && ln -s /usr/share/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /usr/bin/sonar-scanner \
    && rm -rf /tmp/sonar-scanner.zip

# --- Utility scripts ---
COPY scripts/xvfb-chrome /usr/bin/xvfb-chrome
COPY sonar-scanner-run.sh /usr/bin

# --- Chrome wrapper & shell niceties ---
RUN set -eux \
    && ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome \
    && echo 'alias nodejs=node' >> ~/.bashrc