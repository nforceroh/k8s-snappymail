FROM ghcr.io/nforceroh/k8s-nginx-php:latest

ARG \
  BUILD_DATE=now \
  VERSION=unknown

LABEL \
  maintainer="Sylvain Martin (sylvain@nforcer.com)" 

ENV \
    UPLOAD_MAX_SIZE=25M \
    LOG_TO_STDERR=true \
    MEMORY_LIMIT=128M \
    SECURE_COOKIES=true

RUN set -xe \
    && apk --quiet --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ add --virtual=.build-deps php83-dev gpgme-dev make g++ gcc jq \
    && SNAPPYMAIL_VERSION=`curl --silent https://raw.githubusercontent.com/the-djmaze/snappymail/master/package.json | jq -r .version` \
    && apk --quiet --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ add --virtual=run-deps \
        curl php83-iconv php83-zlib php83-imap php83-openssl php83-pdo_sqlite php83-pdo_mysql php83-pecl-uuid php83-tidy \
        php83-sodium php83-zip php83-pecl-apcu php83-pecl-imagick php83-phar php83-sqlite3 sqlite-libs php83-mbstring \
        php83-pecl-apcu php83-intl gpgme sed \
    && rm /data/web -fr \
    && mkdir /data/web /snappymail \
    && cd /data/web \
    && curl -L https://github.com/the-djmaze/snappymail/releases/download/v${SNAPPYMAIL_VERSION}/snappymail-${SNAPPYMAIL_VERSION}.tar.gz | tar zx -C /data/web \
    && chown www-data:www-data /data/web -R \
    && git clone --recursive https://github.com/php-gnupg/php-gnupg.git /tmp/php-gnupg \
    && cd /tmp/php-gnupg \
    && phpize83 \
    && ./configure --with-php-config=/usr/bin/php-config83 \
    && make && make install && rm -fr /tmp/php-gnupg \
    && apk del --quiet --no-cache --purge .build-deps \
    && apk del --quiet --no-cache --purge \
    && rm -rf /var/cache/apk/*

ADD /content /
ADD --chmod=755 /content/etc/s6-overlay /etc/s6-overlay

VOLUME [ "/snappymail" ]

EXPOSE 8080

ENTRYPOINT [ "/init" ]
