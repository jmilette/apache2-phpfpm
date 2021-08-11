FROM ubuntu:18.04

ARG PHPVERSION
ENV PHPVERSION=$PHPVERSION
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:ondrej/php
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor libgmp-dev smbclient libsmbclient-dev apache2 

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php$PHPVERSION-fpm php$PHPVERSION-curl \
        php$PHPVERSION-gd php$PHPVERSION-mbstring php$PHPVERSION-zip php$PHPVERSION-bz2 \ 
        php$PHPVERSION-ldap php$PHPVERSION-imap php$PHPVERSION-bcmath php$PHPVERSION-redis \
        php$PHPVERSION-apcu php$PHPVERSION-imagick php$PHPVERSION-gmp php$PHPVERSION-intl \
        php$PHPVERSION-mysql php$PHPVERSION-pgsql php$PHPVERSION-xml php$PHPVERSION-sqlite3 \
        php$PHPVERSION-smbclient


RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libmagickcore-6.q16-3-extra
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-geoip2
RUN a2enmod proxy_fcgi setenvif
RUN a2enconf php$PHPVERSION-fpm

COPY --from=hipages/php-fpm_exporter:1.2.1 /php-fpm_exporter /usr/local/bin/php-fpm_exporter
COPY ./root/ /

ENTRYPOINT ["/init.sh"]

EXPOSE 80 443 9253
