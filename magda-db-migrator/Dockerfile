FROM ghcr.io/magda-io/openjdk:8-jre-buster

ARG FLYWAY_VERSION=7.15.0
ENV FLYWAY_VERSION=${FLYWAY_VERSION}

RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org|http://archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    apt-get update && apt-get install -y postgresql-client curl && \
    rm -r /var/lib/apt/lists /var/cache/apt/archives

RUN mkdir -p /flyway/sql && \
    curl -fL "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}-linux-x64.tar.gz" -o /tmp/flyway.tgz && \
    tar xzf /tmp/flyway.tgz -C /flyway && \
    rm -f /tmp/flyway.tgz && \
    rm -rf "/flyway/flyway-${FLYWAY_VERSION}/jre"

COPY component/migrate.sh /usr/local/bin/

CMD ["migrate.sh"]
