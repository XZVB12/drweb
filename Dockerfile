####################################################
# GOLANG BUILDER
####################################################
# FROM golang:1.11 as go_builder

# COPY . /go/src/github.com/malice-plugins/drweb
# WORKDIR /go/src/github.com/malice-plugins/drweb
# RUN go get github.com/golang/dep/cmd/dep && dep ensure
# RUN go build -ldflags "-s -w -X main.Version=v$(cat VERSION) -X main.BuildTime=$(date -u +%Y%m%d)" -o /bin/avscan

####################################################
# PLUGIN BUILDER
####################################################
FROM ubuntu:xenial

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/drweb.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

# Create a malice user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN groupadd -r malice \
    && useradd --no-log-init -r -g malice malice \
    && mkdir /malware \
    && chown -R malice:malice /malware
# Install Dr.WEB AV
# COPY drweb-11.0.5-av-linux-amd64.run /tmp/drweb-11.0.5-av-linux-amd64.run
RUN buildDeps='libreadline-dev:i386 \
    ca-certificates \
    libc6-dev:i386 \
    build-essential' \
    && set -x \
    && dpkg --add-architecture i386 && apt-get update -qq \
    && apt-get install -y psmisc gnupg libc6-i386 libfontconfig1 libxrender1 libglib2.0-0 libxi6 xauth $buildDeps --no-install-recommends \
    # && apt-get install -yq gnupg libc6-i386 $buildDeps --no-install-recommends \
    && set -x \
    && echo "Install Dr Web..." \
    # && chmod 755 /tmp/drweb-11.0.5-av-linux-amd64.run \
    # && DRWEB_NON_INTERACTIVE=yes /tmp/drweb-11.0.5-av-linux-amd64.run \
    # && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 10100609 \
    && echo 'deb http://repo.drweb.com/drweb/debian 11.0 non-free' >> /etc/apt/sources.list \
    && apt-key adv --fetch-keys http://repo.drweb.com/drweb/drweb.key \
    && apt-get update -q && apt-get install -y drweb-file-servers \
    && echo "===> Clean up unnecessary files..." \
    && apt-get purge -y --auto-remove $buildDeps gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives /tmp/* /var/tmp/*


#COPY drweb.ini /etc/opt/drweb.com/drweb.ini

ARG DRWEB_KEY
ENV DRWEB_KEY=$DRWEB_KEY

# RUN if [ "x$DRWEB_KEY" != "x" ]; then \
#     echo "===> Adding Dr.WEB License Key..."; \
#     /opt/drweb.com/bin/drweb-configd -d -p /var/run/drweb-configd.pid; \
#     /opt/drweb.com/bin/drweb-ctl license --GetRegistered "$DRWEB_KEY"; \
#     else \
#     echo "===> Running Dr.WEB as DEMO..."; \
#     /opt/drweb.com/bin/drweb-configd -d -p /var/run/drweb-configd.pid; \
#     /opt/drweb.com/bin/drweb-ctl license --GetDemo; \
#     fi

# Ensure ca-certificates is installed for elasticsearch to use https
RUN apt-get update -qq && apt-get install -yq --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Update Dr.WEB Definitions
# RUN mkdir -p /opt/malice && drweb-configd && drweb-ctl update

# Add EICAR Test Virus File to malware folder
ADD http://www.eicar.org/download/eicar.com.txt /malware/EICAR

# COPY --from=go_builder /bin/avscan /bin/avscan

WORKDIR /malware

# ENTRYPOINT ["/bin/avscan"]
# CMD ["--help"]
