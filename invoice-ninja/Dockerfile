FROM debian:buster-slim

ENV HOSTNAME="hostname"

# snippet:gomplate_info
ENV GOMPLATE_VERION="v3.8.0"
ENV GOMPLATE_CHECKSUM="847f7d9fc0dc74c33188c2b0d0e9e4ed9204f67c36da5aacbab324f8bfbf29c9"
# /snippet:gomplate_info

ENV USER=invoice-ninja
ENV USER_ID=4000
ENV USER_GID=4000
ENV DEBIAN_FRONTEND="noninteractive"

RUN groupadd --gid "${USER_GID}" "${USER}" && \
    useradd \
      --uid ${USER_ID} \
      --gid ${USER_GID} \
      --create-home \
      --home-dir /${USER} \
      --shell /bin/bash \
      ${USER}

RUN apt-get update && \
    apt-get dist-upgrade -y --no-install-recommends -qq -y

RUN apt-get install -y --no-install-recommends -qq -y \
    nginx \
    supervisor \
    curl \
    ca-certificates \
    unzip \
    php-fpm \
    php-gmp \
    php-curl \
    php-intl \
    php-mbstring \
    php-xmlrpc \
    php-gd \
    php-xml \
    php-cli \
    php-zip \
    php-mysql

RUN mkdir invoice-ninja/log && \
    mkdir invoice-ninja/run

RUN curl -L -o /usr/local/bin/gomplate https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERION}/gomplate_linux-amd64-slim && \
    echo "${GOMPLATE_CHECKSUM}" /usr/local/bin/gomplate | sha256sum -c && \
    chmod +x /usr/local/bin/gomplate

RUN curl -L -o /tmp/ninja.zip https://github.com/invoiceninja/invoiceninja/releases/download/v5.1.14-release/invoiceninja.zip && \
    unzip -d /invoice-ninja /tmp/ninja.zip && \
    rm -f /tmp/ninja.zip

#RUN chown ${USER} -R /invoice-ninja/ninja/storage/framework/views/
#RUN chown ${USER} /invoice-ninja/ninja/

RUN rm -rf /tmp/* && apt-get clean autoclean && apt-get autoremove --yes

EXPOSE 80

COPY config /invoice-ninja/config
COPY templates /invoice-ninja/templates
COPY bin /invoice-ninja/bin

CMD [ "/invoice-ninja/bin/run.sh" ]