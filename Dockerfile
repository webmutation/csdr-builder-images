FROM buildpack-deps:22.04-curl
ARG GRAAL_URL=https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-17.0.9/graalvm-community-jdk-17.0.9_linux-x64_bin.tar.gz
ARG MUSL_URL=https://more.musl.cc/10/x86_64-linux-musl/x86_64-linux-musl-native.tgz
ARG ZLIB_URL=https://zlib.net/zlib-1.3.tar.gz
ARG NODE_MAJOR=20 # NodeJS

# Install graalvm java 17
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        locales gnupg git libgcrypt20=1.9.4-3ubuntu3 make gcc zlib1g-dev build-essential

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

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    curl --retry 3 -Lfso /tmp/musl.tar.gz ${MUSL_URL}; \
    mkdir -p /opt/musl; \
    cd /opt/musl; \
    tar -xf /tmp/musl.tar.gz --strip-components=1; \
    rm -rf /tmp/musl.tar.gz;

ENV TOOLCHAIN_DIR=/opt/musl \
    PATH="/opt/musl/bin:$PATH"

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    curl --retry 3 -Lfso /tmp/zlib.tar.gz ${ZLIB_URL}; \
    mkdir -p /opt/zlib; \
    cd /opt/zlib; \
    tar -xf /tmp/zlib.tar.gz --strip-components=1; \
    export  CC="$TOOLCHAIN_DIR/bin/gcc"; \
    ./configure --prefix=$TOOLCHAIN_DIR --static; \
    make; \
    make install; \
    rm -rf /tmp/zlib.tar.gz;    

ENV JAVA_HOME=/opt/java/graalvm \
    PATH="/opt/java/graalvm/bin:$PATH"
    
RUN export JAVA_HOME

# Install maven
ENV MAVEN_VERSION 3.8.8

RUN mkdir -p /usr/share/maven \
  && curl -fsSL https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

VOLUME /root/.m2

# Install node 10
# RUN set -x \
#     && curl -sL https://deb.nodesource.com/setup_20.x | bash - \
#     && apt-get update \
#     && apt-get install -y \
#         nodejs \
#     && npm install -g npm@8.19.2

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

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

# Install Sonar Scanner 
# In case of problems try to downgrade the version of the scanner

ENV SONAR_SCANNER_VERSION 4.7.0.2747

RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip && \
    unzip sonar-scanner-cli-${SONAR_SCANNER_VERSION} && \
    cd /usr/bin && ln -s /sonar-scanner-${SONAR_SCANNER_VERSION}/bin/sonar-scanner sonar-scanner && \
    ln -s /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner

# Utility for Sonar Scanner 
COPY sonar-scanner-run.sh /usr/bin