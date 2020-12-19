FROM debian:buster-slim

ENV HOSTNAME="hostname"

ENV GOMPLATE_VERION="v3.8.0"
ENV GOMPLATE_CHECKSUM="847f7d9fc0dc74c33188c2b0d0e9e4ed9204f67c36da5aacbab324f8bfbf29c9"

RUN apt-get update && \
    apt-get install -y --no-install-recommends -qq -y \
    nginx curl ca-certificates awstats

RUN curl -L -o /usr/local/bin/gomplate https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERION}/gomplate_linux-amd64-slim && \
    echo "${GOMPLATE_CHECKSUM}" /usr/local/bin/gomplate | sha256sum -c && \
    chmod +x /usr/local/bin/gomplate

RUN rm -rf /tmp/* && apt-get clean autoclean && apt-get autoremove --yes
#&& rm -rf /var/lib/{apt,dpkg,cache,log}/

EXPOSE 443
EXPOSE 80

COPY config /www/config
COPY templates /www/templates
COPY bin /www/bin

CMD /www/bin/run.sh