FROM buildpack-deps:25.10-curl

# Versions / URLs
ARG GRAAL_VERSION=21.0.2
ARG GRAAL_URL=https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${GRAAL_VERSION}/graalvm-community-jdk-${GRAAL_VERSION}_linux-x64_bin.tar.gz
ARG MUSL_URL=https://more.musl.cc/10/x86_64-linux-musl/x86_64-linux-musl-native.tgz
ARG ZLIB_URL=https://zlib.net/zlib-1.3.1.tar.gz
ARG NODE_VERSION=20.18.0
ARG NPM_VERSION=10.9.0

# Base packages (no pinned vulnerable versions)
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        ca-certificates \
        gnupg \
        git \
        make \
        gcc \
        g++ \
        zlib1g-dev \
        build-essential \
        xz-utils \
        bzip2 \
        zip \
        unzip \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
RUN locale-gen ${LANG}

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    curl --retry 3 -Lfso /tmp/graalvm.tar.gz "${GRAAL_URL}"; \
    mkdir -p /opt/java/graalvm; \
    tar -xf /tmp/graalvm.tar.gz -C /opt/java/graalvm --strip-components=1; \
    rm -f /tmp/graalvm.tar.gz;

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    curl --retry 3 -Lfso /tmp/musl.tar.gz "${MUSL_URL}"; \
    mkdir -p /opt/musl; \
    tar -xf /tmp/musl.tar.gz -C /opt/musl --strip-components=1; \
    rm -f /tmp/musl.tar.gz;

ENV TOOLCHAIN_DIR=/opt/musl \
    PATH="/opt/musl/bin:$PATH"

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    curl --retry 3 -Lfso /tmp/zlib.tar.gz "${ZLIB_URL}"; \
    mkdir -p /opt/zlib; \
    tar -xf /tmp/zlib.tar.gz -C /opt/zlib --strip-components=1; \
    export CC="$TOOLCHAIN_DIR/bin/gcc"; \
    cd /opt/zlib; \
    ./configure --prefix="$TOOLCHAIN_DIR" --static; \
    make -j"$(nproc)"; \
    make install; \
    rm -f /tmp/zlib.tar.gz;    

ENV JAVA_HOME=/opt/java/graalvm \
    PATH="/opt/java/graalvm/bin:$PATH"
    
RUN export JAVA_HOME

## Maven
ENV MAVEN_VERSION=3.9.9 \
        MAVEN_HOME=/usr/share/maven
RUN set -eux; \
    mkdir -p /usr/share/maven; \
    curl -fsSL "https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${MAVEN_VERSION}/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
        | tar -xzC /usr/share/maven --strip-components=1; \
    ln -sf /usr/share/maven/bin/mvn /usr/bin/mvn

VOLUME /root/.m2

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

RUN set -eux; \
    touch ~/.bashrc; \
    echo 'alias nodejs=node' >> ~/.bashrc

## Sonar Scanner (newer) + patch logback-core to 1.5.19
ENV SONAR_SCANNER_VERSION=7.3.0.5189-linux-x64
RUN set -eux; \
    curl -fsSL -o /tmp/sonar-scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip"; \
    unzip /tmp/sonar-scanner.zip -d /usr/share; \
    ln -sf "/usr/share/sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner" /usr/bin/sonar-scanner; \
    mkdir -p /bin; \
    ln -sf /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner; \
    rm -f /tmp/sonar-scanner.zip; \
    curl -fsSL -o /usr/share/sonar-scanner-${SONAR_SCANNER_VERSION}/lib/logback-core-1.5.19.jar "https://repo1.maven.org/maven2/ch/qos/logback/logback-core/1.5.19/logback-core-1.5.19.jar"; \
    find /usr/share/sonar-scanner-${SONAR_SCANNER_VERSION}/lib -name 'logback-core-*.jar' ! -name 'logback-core-1.5.19.jar' -delete

# Utility for Sonar Scanner 
COPY sonar-scanner-run.sh /usr/bin