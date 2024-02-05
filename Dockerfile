#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:bullseye-slim as phraseanet-php

# prevent Debian's PHP packages from being installed
# https://github.com/docker-library/php/pull/542
#RUN set -eux; \
#	{ \
#		echo 'Package: php*'; \
#		echo 'Pin: release *'; \
#		echo 'Pin-Priority: -1'; \
#	} > /etc/apt/preferences.d/no-debian-php
#
# dependencies required for running "phpize"
# (see persistent deps below)
ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkg-config \
		re2c

ENV PHRASEANET_DEPS \
                wget \
                automake \
                git \
                ghostscript \
                gpac \
                imagemagick \
                inkscape \
                libfreetype6-dev \
                libmagickwand-dev \
                libmcrypt-dev \
                libpng-dev \
                librabbitmq-dev \
                libssl-dev \
                libxslt-dev \
                libzmq3-dev \
                libtool \
                locales \
                gettext \
                mcrypt \
                unoconv \
                unzip \
                poppler-utils \
                libreoffice-base-core \
                libreoffice-impress \
                libreoffice-calc \
                libreoffice-math \
                libreoffice-writer \
                libde265-dev \
                libopenjp2-7-dev \
                librsvg2-dev \
                libwebp-dev \
                yasm \
                libvorbis-dev \
                texi2html \
                nasm \
                zlib1g-dev \
                libx264-dev \
                libopus-dev \
                libvpx-dev \
                libmp3lame-dev \
                libogg-dev \
                libopencore-amrnb-dev \
                libopencore-amrwb-dev \
                libx11-dev \
                libswscale-dev \
                libpostproc-dev \
                libxvidcore-dev \
                libtheora-dev \
                libgsm1-dev \
                libfreetype6-dev \
                libldap2-dev \
                libdc1394-dev \
                nano

# persistent / runtime deps
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		$PHPIZE_DEPS \
		ca-certificates \
		curl \
		xz-utils \
                $PHRASEANET_DEPS \
	; \
	rm -rf /var/lib/apt/lists/*
RUN set -eux; \
        mkdir /tmp/icu \
        && cd /tmp/icu \
        && wget https://github.com/unicode-org/icu/releases/download/release-57-1/icu4c-57_1-src.tgz \
        && tar -zxf icu4c-57_1-src.tgz \
        && cd icu/source \
        && ./configure \
        && make \
        && make install

RUN set -eux; \
    mkdir /tmp/libjq \
    && git clone https://github.com/stedolan/jq.git /tmp/libjq \
    && cd /tmp/libjq \
    && git checkout fd9da6647c0fa619f03464fe37a4a10b70147e73 \
    && git submodule update --init \
    && autoreconf -fi \
    && ./configure --with-oniguruma=builtin --disable-maintainer-mode \
    && make -j8 \
    && make check \
    && make install

RUN set -eux; \
    mkdir /tmp/libheif \
    && git clone https://github.com/strukturag/libheif.git /tmp/libheif \
    && cd /tmp/libheif \
    && git checkout v1.13.0 \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install

RUN echo "BUILDING AND INSTALLING IMAGEMAGICK" \
    && git clone https://github.com/ImageMagick/ImageMagick.git /tmp/ImageMagick \
    && cd /tmp/ImageMagick \
    && git checkout 7.1.0-39 \
    && ./configure \
    && make \
    && make install 

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 1777 /var/www/html

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV GPG_KEYS 528995BFEDFBA7191D46839EF9BA0ADA31CBD89E 39B641343D8C104B2B146DC3F9C39DC0B9698544 F1F692238FBC1666E5A5CCD4199F9DFEF6FFBAFD

ENV PHP_VERSION 7.0.33
ENV PHP_URL="https://www.php.net/distributions/php-7.0.33.tar.xz" 
ENV PHP_ASC_URL=
ENV PHP_SHA256="ab8c5be6e32b1f8d032909dedaaaa4bbb1a209e519abb01a52ce3914f9a13d96"

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends gnupg; \
	rm -rf /var/lib/apt/lists/*; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	curl -fsSL -o php.tar.xz "$PHP_URL"; \
	\
	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	fi; \
	\
	if [ -n "$PHP_ASC_URL" ]; then \
		curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
		done; \
		gpg --batch --verify php.tar.xz.asc php.tar.xz; \
		gpgconf --kill all; \
		rm -rf "$GNUPGHOME"; \
	fi; \
	\
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

COPY docker-php-source /usr/local/bin/

RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libargon2-dev \
		libcurl4-openssl-dev \
		libonig-dev \
		libreadline-dev \
		libsodium-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		zlib1g-dev \
	; \
	\
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
# https://github.com/php/php-src/blob/d6299206dd828382753453befd1b915491b741c6/configure.ac#L1496-L1511
		PHP_BUILD_PROVIDER='https://github.com/docker-library/php' \
		PHP_UNAME='Linux - Docker' \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
# https://bugs.php.net/bug.php?id=74125
	if [ ! -d /usr/include/curl ]; then \
		ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
	fi; \
	./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		\
# make sure invalid --configure-flags are fatal errors instead of just warnings
		--enable-option-checking=fatal \
		\
# https://github.com/docker-library/php/issues/439
		--with-mhash \
		\
# https://github.com/docker-library/php/issues/822
		--with-pic \
		\
# --enable-ftp is included here for compatibility with existing versions. ftp_ssl_connect() needed ftp to be compiled statically before PHP 7.0 (see https://github.com/docker-library/php/issues/236).
		--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
# https://wiki.php.net/rfc/argon2_password_hash
#		--with-password-argon2 \
# https://wiki.php.net/rfc/libsodium
#		--with-sodium=shared \
# always build against system sqlite3 (https://github.com/php/php-src/commit/6083a387a81dbbd66d6316a3a12a63f06d5f7109)
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		\
		--with-curl \
		--with-iconv \
		--with-openssl \
		--with-readline \
		--with-zlib \
		\
# https://github.com/bwoebi/phpdbg-docs/issues/1#issuecomment-163872806 ("phpdbg is primarily a CLI debugger, and is not suitable for debugging an fpm stack.")
		--disable-phpdbg \
		\
# in PHP 7.4+, the pecl/pear installers are officially deprecated (requiring an explicit "--with-pear")
		--with-pear \
		\
# bundled pcre does not support JIT on s390x
# https://manpages.debian.org/bullseye/libpcre3-dev/pcrejit.3.en.html#AVAILABILITY_OF_JIT_SUPPORT
		$(test "$gnuArch" = 's390x-linux-gnu' && echo '--without-pcre-jit') \
		--with-libdir="lib/$debMultiarch" \
		\
		--disable-cgi \
		\
		--enable-fpm \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
	; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
	; \
	make clean; \
	\
# https://github.com/docker-library/php/issues/692 (copy default example "php.ini" files somewhere easily discoverable)
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	\
	cd /; \
	docker-php-source delete; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual \
	; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*; \
	\
# update pecl channel definitions https://github.com/docker-library/php/issues/443
	pecl update-channels; \
	rm -rf /tmp/pear ~/.pearrc; \
	\
# smoke test
	php --version

COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/

# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
# RUN docker-php-ext-enable sodium

RUN echo "PHRASEANET : BUILDING PHP PECL EXTENTIONS" \
    ldconfig 
RUN docker-php-ext-configure gd 
RUN docker-php-ext-install -j$(nproc) gd
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/
RUN docker-php-ext-install -j$(nproc) ldap
RUN docker-php-ext-install intl
RUN docker-php-ext-install zip 
RUN docker-php-ext-install exif 
RUN docker-php-ext-install iconv 
RUN docker-php-ext-install mbstring 
RUN docker-php-ext-install pcntl 
RUN docker-php-ext-install sockets 
RUN docker-php-ext-install xsl 
RUN docker-php-ext-install pdo_mysql 
RUN docker-php-ext-install gettext 
RUN docker-php-ext-install bcmath 
RUN docker-php-ext-install mcrypt
 
# --- extension jq - sources _must_ be in /usr/src/php/ext/ for the docker-php-ext-install script to find it

RUN  mkdir -p /usr/src/php/ext/ \
    && git clone --depth=1 https://github.com/kjdev/php-ext-jq.git /usr/src/php/ext/php-ext-jq \
    && docker-php-ext-install php-ext-jq

# --- end of extension jq

RUN pecl install \
        redis-5.3.7 \
        amqp-1.9.3 \
        zmq-beta \
        imagick-beta \
        xdebug-2.6.1 \
    && docker-php-ext-enable redis.so amqp.so zmq.so imagick.so \
    && pecl clear-cache \
    && docker-php-source delete

RUN echo "PHRASEANET : INSTALLING NEWRELIC EXTENTION" \
    && echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | tee /etc/apt/sources.list.d/newrelic.list \
    && curl -o- https://download.newrelic.com/548C16BF.gpg | apt-key add - \
    && apt-get update \ 
    && apt-get install -y newrelic-php5 \ 
    && NR_INSTALL_SILENT=1 newrelic-install install \
    && touch /etc/newrelic/newrelic.cfg

ENV XDEBUG_ENABLED=0
ENV FFMPEG_VERSION=4.2.2

RUN echo "PHRASEANET : BUILDING AND INSTALLING FFMPEG" \
    && mkdir /tmp/ffmpeg \
    && curl -s https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 | tar jxf - -C /tmp/ffmpeg \
    && ( \
        cd /tmp/ffmpeg/ffmpeg-${FFMPEG_VERSION} \
        && ./configure \
            --enable-gpl \
            --enable-nonfree \
            --enable-libgsm \
            --enable-libmp3lame \
            --enable-libtheora \
            --enable-libvorbis \
            --enable-libvpx \
            --enable-libfreetype \
            --enable-libopus \
            --enable-libx264 \
            --enable-libxvid \
            --enable-zlib \
            --enable-postproc \
            --enable-swscale \
            --enable-pthreads \
            --enable-libdc1394 \
            --enable-version3 \
            --enable-libopencore-amrnb \
            --enable-libopencore-amrwb \
        && make \
        && make install \
        && make distclean \
    )

RUN echo "PHRASEANET : FINALIZING BUILD AND CLEANING" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists \
    && rm -rf /tmp/* \
    && mkdir /entrypoint /var/alchemy \
    && useradd -u 1000 app \
    && mkdir -p /home/app/.composer \
    && chown -R app: /home/app /var/alchemy

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

RUN set -eux; \
	cd /usr/local/etc; \
	if [ -d php-fpm.d ]; then \
		# for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
		sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
		cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	else \
		# PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
		mkdir php-fpm.d; \
		cp php-fpm.conf.default php-fpm.d/www.conf; \
		{ \
			echo '[global]'; \
			echo 'include=etc/php-fpm.d/*.conf'; \
		} | tee php-fpm.conf; \
	fi; \
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
#		echo; echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; echo 'log_limit = 8192'; \
		echo; \
		echo '[www]'; \
		echo '; php-fpm closes STDOUT on startup, so sending logs to /proc/self/fd/1 does not work.'; \
		echo '; https://bugs.php.net/bug.php?id=73886'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
#		echo 'decorate_workers_output = no'; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/zz-docker.conf; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	{ \
		echo '; https://github.com/docker-library/php/issues/878#issuecomment-938595965'; \
		echo 'fastcgi.logging = Off'; \
	} > "$PHP_INI_DIR/conf.d/docker-fpm.ini"

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.7.in#L163
STOPSIGNAL SIGQUIT

EXPOSE 9000
CMD ["php-fpm"]
