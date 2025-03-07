FROM buildpack-deps:22.04-curl
ARG JAVA_SDK_URL=https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.tar.gz
ARG NODE_MAJOR=20 # NodeJS

RUN set -eux; \
    apt-get update; \
    apt-get install -y locales ca-certificates-java git; \
    locale-gen C.UTF-8; \
    curl --retry 3 -Lfso /tmp/openjdk21.tar.gz ${JAVA_SDK_URL}; \
    mkdir -p /opt/java/openjdk21; \
    tar -xf /tmp/openjdk21.tar.gz -C /opt/java/openjdk21 --strip-components=1; \
    rm -rf /tmp/openjdk21.tar.gz; \
    mkdir -p /usr/share/maven; \
    curl -fsSL http://apache.osuosl.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz | tar -xzC /usr/share/maven --strip-components=1; \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list; \
    apt-get update; \
    apt-get install -y nodejs yarn bzip2 zip unzip; \
    npm uninstall -g cross-spawn || true; \
    find $(npm root -g) -name "cross-spawn" -type d -exec rm -rf {} +; \
    npm cache clean --force; \
    npm install -g cross-spawn@7.0.5; \
    echo 'alias nodejs=node' > ~/.bashrc; \
    echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/chrome.list; \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -; \
    apt-get update; \
    apt-get install -y xvfb google-chrome-stable; \
    wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-7.0.2.4839-linux-x64.zip; \
    unzip sonar-scanner-cli-7.0.2.4839-linux-x64.zip; \
    ln -s /sonar-scanner-7.0.2.4839-linux-x64/bin/sonar-scanner /usr/bin/sonar-scanner; \
    ln -s /usr/bin/sonar-scanner-run.sh /bin/gitlab-sonar-scanner; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=C.UTF-8
ENV JAVA_HOME=/opt/java/openjdk21
ENV PATH="/opt/java/openjdk21/bin:/usr/share/maven/bin:$PATH"
ENV MAVEN_HOME=/usr/share/maven
ENV CHROME_BIN=/usr/bin/google-chrome
ENV SONAR_SCANNER_VERSION=7.0.2.4839-linux-x64

VOLUME /root/.m2

ADD scripts/xvfb-chrome /usr/bin/xvfb-chrome
RUN ln -sf /usr/bin/xvfb-chrome /usr/bin/google-chrome

COPY sonar-scanner-run.sh /usr/bin
