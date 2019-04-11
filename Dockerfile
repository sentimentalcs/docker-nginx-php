FROM php:7.1.13-fpm

MAINTAINER Abed Halawi <abed.halawi@vinelab.com>

ENV php_conf /usr/local/etc/php/php.ini
ENV fpm_conf /usr/local/etc/php/php-fpm.conf
ENV fpm_conf_dir /usr/local/etc/php-fpm.d/

RUN apt-get update && apt-get install -y autoconf pkg-config libssl-dev

# RUN apt-get install -y libpq-dev \
#    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
#    && docker-php-ext-install pdo pdo_pgsql pgsql

# RUN apt-get update && apt-get install -y zlib1g-dev

# Install components
RUN apt-get update -y && apt-get install -y \
        libpq-dev \
		gzip \
		unzip \
		zip \
	--no-install-recommends && \
	apt-get autoremove -y && \
	rm -r /var/lib/apt/lists/*

# Install PHP Extensions
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql zip


# git
RUN apt-get update && apt-get install -y git

# Composer
ENV COMPOSER_HOME /var/www/.composer

RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/bin \
    --filename=composer

RUN chown -R www-data:www-data /var/www/

RUN mkdir -p $COMPOSER_HOME/cache

#VOLUME $COMPOSER_HOME

RUN apt-get update
RUN apt-get install -y nginx supervisor cron
#RUN apt-get install -y postgresql

RUN mkdir /code

#copy the project code to the container
#COPY ./ /code


RUN useradd --no-create-home nginx

#chanage the permission
RUN chmod -R 777 /code

# tweak php-fpm config
COPY php/php.ini ${php_conf}
COPY php/www.conf.default ${fpm_conf_dir}/www.conf
COPY php/pools/pool-1.conf ${fpm_conf_dir}/pool-1.conf
COPY php/pools/pool-2.conf ${fpm_conf_dir}/pool-2.conf
COPY php/pools/pool-3.conf ${fpm_conf_dir}/pool-3.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/php.conf /etc/nginx/php.conf
COPY nginx/host.conf /etc/nginx/conf.d/default.conf

# add cron runner script
COPY cron.sh /cron.sh

COPY supervisord.conf /etc/supervisor/supervisord.conf

WORKDIR /code

#composer install project dependencies
#RUN composer install

EXPOSE 443 80

CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
