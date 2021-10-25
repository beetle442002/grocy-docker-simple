# FROM php:7.3.12-apache-buster
#FROM php:7.4.0-apache-buster
#FROM php:7.4.24-apache-bullseye
FROM php:8.0.12-apache-bullseye

# ensure www-data user exists
#RUN set -eux; \
#	addgroup --gid 82 --system www-data; \
#	adduser --system --uid 82 --no-create-home --ingroup www-data www-data
# 82 is the standard uid/gid for "www-data" in Alpine

#ARG GROCY_VERSION
#ENV GROCY_VERSION=v3.1.2
ENV GROCY_VERSION=master

RUN apt-get update && apt-get install -y zlib1g-dev libzip-dev libpng-dev libicu-dev git zip gnupg wget nano

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -

RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update

RUN apt-get install -y yarn

RUN docker-php-ext-install gd intl # pdo_sqlite
# RUN docker-php-ext-enable gd # pdo_sqlite php7.4-sqlite3

RUN curl -sS https://getcomposer.org/installer | php \
        && mv composer.phar /usr/local/bin/ \
        && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer


#RUN mkdir /var/www/html/grocy.lan
#COPY grocy /var/www/html/grocy.lan
#WORKDIR /var/www/html/grocy.lan

RUN a2enmod rewrite



# Install application dependencies (unprivileged)

WORKDIR /var/www
RUN rm -rf html
#USER www-data
# Extract application release package
#ENV GROCY_RELEASE_KEY_URI="https://berrnd.de/data/Bernd_Bestel.asc"
#RUN     set -eo pipefail && \
RUN        export GNUPGHOME=$(mktemp -d) && \
#        wget ${GROCY_RELEASE_KEY_URI} -O - | gpg --batch --import && \
#        git clone --branch ${GROCY_VERSION} --config advice.detachedHead=false --depth 1 "https://github.com/grocy/grocy.git" . && \
        git clone --branch ${GROCY_VERSION} --config advice.detachedHead=false --depth 1 "https://github.com/beetle442002/grocy.git" . && \
#        git verify-commit ${GROCY_VERSION} && \
#        rm -rf ${GNUPGHOME} && \
        mkdir data/viewcache && \
        cp config-dist.php data/config.php

# Install application dependencies
#RUN     composer install --no-interaction --no-dev --optimize-autoloader && \
#        composer clear-cache

# Remove build-time dependencies (privileged)
#USER root
RUN chown -R www-data:www-data /var/www
#RUN     apk del \
#            composer \
#            git \
#            gnupg \
#            wget




RUN composer install --prefer-source --no-interaction

RUN yarn install

RUN sed -i '/DocumentRoot*/c\ DocumentRoot\ /var/www/public' /etc/apache2/sites-enabled/000-default.conf

#RUN chown -R www-data:www-data /var/www
#RUN cp /var/www/html/grocy.lan/config-dist.php /var/www/html/grocy.lan/data/config.php

# nano /etc/apache2/sites-enabled/000-default.conf
# DocumentRoot /var/www/html/grocy.lan/public
# /etc/init.d/apache2 reload
# mkdir /var/www/html/grocy.lan/data/viewcache

#sed -i '/DocumentRoot*/c\ DocumentRoot\ /var/www/html/grocy.lan/public' /etc/apache2/sites-enabled/000-default.conf


