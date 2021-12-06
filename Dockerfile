FROM ubuntu:18.04

ARG PHPVERSION
ENV PHPVERSION=$PHPVERSION
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common && add-apt-repository -y ppa:ondrej/php

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php$PHPVERSION-fpm php$PHPVERSION-curl \
        php$PHPVERSION-gd php$PHPVERSION-mbstring php$PHPVERSION-zip php$PHPVERSION-bz2 \ 
        php$PHPVERSION-ldap php$PHPVERSION-imap php$PHPVERSION-bcmath php$PHPVERSION-redis \
        php$PHPVERSION-apcu php$PHPVERSION-imagick php$PHPVERSION-gmp php$PHPVERSION-intl \
        php$PHPVERSION-mysql php$PHPVERSION-pgsql php$PHPVERSION-xml php$PHPVERSION-sqlite3 \
        php$PHPVERSION-smbclient libmagickcore-6.q16-3-extra python3-geoip2 supervisor libgmp-dev \
        smbclient libsmbclient-dev apache2 
RUN a2enmod proxy_fcgi setenvif && a2enconf php$PHPVERSION-fpm
COPY --from=hipages/php-fpm_exporter:1.2.1 /php-fpm_exporter /usr/local/bin/php-fpm_exporter
COPY ./root/ /

ENTRYPOINT ["/init.sh"]
EXPOSE 80 443 9253
