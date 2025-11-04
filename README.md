# CSDR Builder Images

[![Docker Hub](https://img.shields.io/docker/pulls/webmutation/docker-gitlab-build-sonar.svg)](https://hub.docker.com/r/webmutation/docker-gitlab-build-sonar)
[![Image Size](https://img.shields.io/docker/image-size/webmutation/docker-gitlab-build-sonar/JDK21)](https://hub.docker.com/r/webmutation/docker-gitlab-build-sonar/tags)

Temurin-based CI builder images for CSDR/eUI GitLab pipelines. Each tag shares the same Ubuntu 25.10 base and tooling while providing different LTS JDK versions.

## Supported Tags

| Tag | Java | Notes |
| --- | --- | --- |
| `JDK21` | Temurin 21.0.4+7 LTS | Default track for Spring Boot 3.x workloads |
| `JDK17` | Temurin 17.0.12+7 LTS | Long-term support for legacy services |
| `JDK11` | Temurin 11.0.25+9 LTS | Maintenance builds for older agents |

All variants inherit from `buildpack-deps:25.10-scm`, keeping Git and other SCM tooling available.

## Tooling Snapshot

- Maven `3.9.9`
- Node.js `20.18.0`, npm `10.9.0`, `cross-spawn@7.0.6`
- Google Chrome (stable) with XVFB launcher (`scripts/xvfb-chrome`)
- Sonar Scanner CLI `7.3.0.5189`
- jq `1.8.1`, build-essential toolchain, zip utilities

## Build Locally

```bash
# From the branch matching the desired tag (JDK21/JDK17/JDK11)
docker build -t webmutation/docker-gitlab-build-sonar:JDK21 .
```

## Quick Validation

```bash
docker run --rm webmutation/docker-gitlab-build-sonar:JDK21 java -XshowSettings:properties -version
docker run --rm webmutation/docker-gitlab-build-sonar:JDK21 mvn -v
docker run --rm webmutation/docker-gitlab-build-sonar:JDK21 node -v
```

Swap in `JDK17` or `JDK11` to test the other variants.

## Publish

```bash
docker push webmutation/docker-gitlab-build-sonar:JDK21
```

Repeat for any additional tags you build.

## Contributing Updates

Tool versions live near the top of the `Dockerfile`. Update the relevant environment variables, rebuild, run the validation commands above, and raise a PR. Please update this README when bumping key dependencies or adding new tooling.
