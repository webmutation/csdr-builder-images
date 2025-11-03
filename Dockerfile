FROM buildpack-deps:25.10-scm

ARG TEMURIN_VERSION=jdk-21.0.4+7
ARG TEMURIN_BUILD=21.0.4_7
ARG JAVA_SDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/${TEMURIN_VERSION}/OpenJDK21U-jdk_x64_linux_hotspot_${TEMURIN_BUILD}.tar.gz"

ENV LANG=C.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/temurin-21 \
    MAVEN_VERSION=3.9.9 \
    MAVEN_HOME=/usr/share/maven \
    SONAR_SCANNER_VERSION=7.3.0.5189-linux-x64 \
    CHROME_BIN=/usr/bin/google-chrome \
    NODE_VERSION=20.18.0 \
    NPM_VERSION=10.9.0 \
    JQ_VERSION=1.8.1 \
    PATH="/usr/lib/jvm/temurin-21/bin:/usr/share/maven/bin:$PATH"

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

RUN set -eux \
    && curl -fsSL "${JAVA_SDK_URL}" -o /tmp/temurin.tar.gz \
    && mkdir -p "${JAVA_HOME}" \
    && tar -xzf /tmp/temurin.tar.gz -C "${JAVA_HOME}" --strip-components=1 \
    && ln -sf "${JAVA_HOME}" /usr/lib/jvm/default-java \
    && ln -sf "${JAVA_HOME}/bin/java" /usr/bin/java \
    && ln -sf "${JAVA_HOME}/bin/javac" /usr/bin/javac \
    && rm -f /tmp/temurin.tar.gz

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

RUN set -eux \
    && curl -fsSL -o /usr/local/bin/jq "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" \
    && chmod +x /usr/local/bin/jq

RUN set -eux \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
    && mkdir -p /usr/share/maven \
    && curl -fsSL https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-bin.tar.gz \
        | tar -xzC /usr/share/maven --strip-components=1 \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

VOLUME /root/.m2

RUN set -eux \
    && curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip -o /tmp/sonar-scanner.zip \
    && unzip /tmp/sonar-scanner.zip -d /usr/share \
    && ln -s /usr/share/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner /usr/bin/sonar-scanner \
    && ln -s /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner \
    && rm -rf /tmp/sonar-scanner.zip

COPY scripts/xvfb-chrome /usr/bin/xvfb-chrome
COPY sonar-scanner-run.sh /usr/bin

RUN ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome \
    && echo 'alias nodejs=node' >> ~/.bashrc
