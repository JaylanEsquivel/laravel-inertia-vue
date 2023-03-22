FROM composer AS composer
FROM node:latest AS node
FROM php:8.1-apache

COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN a2enmod rewrite

RUN apt-get update && apt-get install -y git zip unzip libzip-dev libpq-dev zlib1g-dev libpng-dev nano gnupg2 supervisor openssh-server\
  && docker-php-ext-install exif gd zip mysqli pdo pdo_mysql

#SSH Server Configuration
RUN mkdir /var/run/sshd
RUN echo 'root:P@ssw0rd' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN printf 'AllowUsers root \n\
PermitRootLogin Yes' >> /etc/ssh/sshd_config.d/sshd_custom_config.conf

EXPOSE 22

RUN printf '[PHP]\ndate.timezone = "America/Sao_Paulo"\n' > /usr/local/etc/php/conf.d/tzone.ini

RUN apt-get update -yqq \
    && apt-get install -y --no-install-recommends openssl \
    && sed -i 's,^\(MinProtocol[ ]*=\).*,\1'TLSv1.0',g' /etc/ssl/openssl.cnf \
    && sed -i 's,^\(CipherString[ ]*=\).*,\1'DEFAULT@SECLEVEL=1',g' /etc/ssl/openssl.cnf\
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/laravelInertiaVue

COPY . .

RUN cd .. && rm -rf html && ln -s laravelInertiaVue/public html && chmod -R 775 laravelInertiaVue/storage && chmod -R 775 laravelInertiaVue/bootstrap && cd laravelInertiaVue && composer install && php artisan key:generate && npm install && npm run build && php artisan optimize:clear

# RUN npm run dev

EXPOSE 8089
