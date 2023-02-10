FROM php:7.2.30-apache-stretch

# Instalacion de librerias
RUN apt-get update && apt-get install -y \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libaio1 \
                libbz2-dev \
                libssl-dev \
                libgmp-dev \
                libldap2-dev \
                mysql-client \
                librecode0 \
                librecode-dev \
                libxslt-dev \
    && pecl install mcrypt-1.0.2 \
    && docker-php-ext-enable mcrypt \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install -j$(nproc) iconv gettext \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd
# Instalacion de SOAP
RUN rm /etc/apt/preferences.d/no-debian-php
RUN apt-get update -y \
  && apt-get install -y \
     libxml2-dev \
     php-soap \
  && apt-get clean -y \
  && docker-php-ext-install soap

# Oracle instantclient - OCI
ADD instantclient/instantclient-basiclite-linux.x64-19.18.0.0.0dbru.zip /tmp/
ADD instantclient/instantclient-sdk-linux.x64-19.18.0.0.0dbru.zip /tmp/

RUN unzip /tmp/instantclient-basiclite-linux.x64-19.18.0.0.0dbru.zip -d /usr/local/
RUN unzip /tmp/instantclient-sdk-linux.x64-19.18.0.0.0dbru.zip -d /usr/local/
RUN ln -s /usr/local/instantclient_19_18 /usr/local/instantclient

ENV LD_LIBRARY_PATH=/usr/local/instantclient
RUN echo 'instantclient,/usr/local/instantclient' | pecl install oci8-2.2.0

RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient
RUN docker-php-ext-install pdo_oci
RUN docker-php-ext-enable oci8

# Librerias adicionales PHP
RUN docker-php-ext-install bz2
RUN docker-php-ext-install exif
RUN docker-php-ext-install ftp
RUN docker-php-ext-install gd
RUN docker-php-ext-install gettext

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h
RUN docker-php-ext-install gmp

RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu
RUN docker-php-ext-install ldap

RUN docker-php-ext-install mbstring
#RUN docker-php-ext-install mcrypt
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
#RUN docker-php-ext-install posix
#RUN docker-php-ext-install recode
RUN docker-php-ext-install shmop
RUN docker-php-ext-install soap
RUN docker-php-ext-install xmlrpc
RUN docker-php-ext-install sockets
RUN docker-php-ext-install tokenizer
RUN docker-php-ext-install wddx
RUN docker-php-ext-install zip
RUN docker-php-ext-install xsl

# Configuracion Apache
COPY docker-php.conf /etc/apache2/conf-enabled/docker-php.conf
COPY pm-custom.ini /usr/local/etc/php/conf.d/pm-custom.ini

RUN printf "log_errors = On \nerror_log = /dev/stderr\n" > /usr/local/etc/php/conf.d/php-logs.ini
RUN a2enmod rewrite
RUN a2enmod headers

RUN ln -s /etc/apache2/mods-available/ssl.load  /etc/apache2/mods-enabled/ssl.load


RUN echo "<?php echo phpinfo(); ?>" > /var/www/html/phpinfo.php

EXPOSE 80 443
