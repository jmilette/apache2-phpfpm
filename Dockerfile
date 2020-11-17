FROM ubuntu:18.04

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:ondrej/php
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor libgmp-dev smbclient libsmbclient-dev apache2 php-fpm
RUN a2enmod proxy_fcgi setenvif
RUN a2enconf php7.4-fpm
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php-curl php-gd php-mbstring php-zip php-bz2 php-ldap php-imap php-bcmath php-redis php-apcu php-imagick php-gmp php-intl smbclient php7.4-mysql php7.4-pgsql php7.4-xml php7.4-sqlite3

COPY --from=hipages/php-fpm_exporter:1.2.1 /php-fpm_exporter /usr/local/bin/php-fpm_exporter
COPY ./root/ /

ENTRYPOINT ["/init.sh"]

EXPOSE 80 443 9253
