FROM php:8.2-fpm

MAINTAINER DIMA KULAHYN <d.kulahyn@gmail.com>

ARG UID
ARG GID

RUN apt update \
    && apt install -y curl

RUN apt update \
    && apt install -y libxpm-dev libfreetype6-dev

RUN apt update && apt install -y \
    zlib1g-dev \
    libjpeg-dev \
    libxml2-dev \
    libxslt-dev \
    libfreetype6 \
    libfreetype6-dev \
    libpng16-16 \
    libpng-dev \
    libzip-dev \
    libpcre3-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    libxpm-dev \
    libpq-dev

RUN apt-get update

# Install Postgre PDO
RUN docker-php-ext-install pdo_pgsql

RUN apt-get update \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install soap \
    && docker-php-ext-install xsl \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install intl \
    && docker-php-ext-install sockets \
    && docker-php-ext-install zip

RUN pecl install redis \
    && rm -rf /tmp/pear \
    && docker-php-ext-enable redis

RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install gd

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

#TODO: change to production
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host = host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN apt-get install -y -f ffmpeg

RUN apt-get install -y supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /var/log/supervisor

CMD /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf