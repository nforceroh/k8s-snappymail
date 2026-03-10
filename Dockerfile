FROM ghcr.io/nforceroh/k8s-nginx-php:latest

ARG \
  BUILD_DATE=now \
  VERSION=unknown \
  SNAPPYMAIL_SOURCE=release \
  SNAPPYMAIL_VERSION=2.38.2 \
  SNAPPYMAIL_REF= \
  PHP_GNUPG_REF=gnupg-1.5.4

LABEL \
  org.label-schema.maintainer="Sylvain Martin (sylvain@nforcer.com)" \
  org.label-schema.build-date="${BUILD_DATE}" \
  org.label-schema.version="${VERSION}" \
  org.label-schema.vcs-url="https://github.com/nforcer/k8s-snappymail" \
  org.label-schema.vcs-ref="${VERSION}" \
  org.label-schema.schema-version="1.0"

ENV \
    UPLOAD_MAX_SIZE=25M \
    LOG_TO_STDERR=true \
    MEMORY_LIMIT=128M \
    SECURE_COOKIES=true

RUN set -xe \
  && apk --quiet --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ add --virtual=.build-deps php85-dev gpgme-dev make g++ gcc git \
    && apk --quiet --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ add --virtual=run-deps \
    curl php85-iconv php85-zlib php85-imap php85-openssl php85-pdo_sqlite php85-pdo_mysql php85-pecl-uuid php85-tidy \
    php85-sodium php85-zip php85-pecl-apcu php85-pecl-imagick php85-phar php85-sqlite3 sqlite-libs php85-mbstring \
    php85-intl gpgme sed \
    && rm /data/web -fr \
    && mkdir /data/web /snappymail \
    && cd /data/web \
    && if [ "${SNAPPYMAIL_SOURCE}" = "ref" ]; then \
         test -n "${SNAPPYMAIL_REF}"; \
         curl -fsSL "https://github.com/the-djmaze/snappymail/archive/${SNAPPYMAIL_REF}.tar.gz" | tar zx --strip-components=1 -C /data/web; \
       else \
         curl -fsSL "https://github.com/the-djmaze/snappymail/releases/download/v${SNAPPYMAIL_VERSION}/snappymail-${SNAPPYMAIL_VERSION}.tar.gz" | tar zx -C /data/web; \
       fi \
    && chown www-data:www-data /data/web -R \
    && git clone --branch "${PHP_GNUPG_REF}" --depth 1 --recurse-submodules https://github.com/php-gnupg/php-gnupg.git /tmp/php-gnupg \
    && cd /tmp/php-gnupg \
    && phpize85 \
    && ./configure --with-php-config=/usr/bin/php-config85 \
    && make && make install && rm -fr /tmp/php-gnupg \
    && apk del --quiet --no-cache --purge .build-deps \
    && rm -rf /var/cache/apk/*

ADD /content /
ADD --chmod=755 /content/etc/s6-overlay /etc/s6-overlay

VOLUME [ "/snappymail" ]

EXPOSE 8080

ENTRYPOINT [ "/init" ]
