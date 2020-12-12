This is Apache2 with integrated PHP-FPM and PHPFPM prometheus exporter (hipages/php-fpm_exporter:1.2.1)

/config/php/php.ini       replacable user config
/config/php/fpm/pool.d/   add any custom phpfpm configs here
/config/httpd/conf.d/  add any custom apache configs here


The majority of configuration can be done using environment variables, using methods borrowed from webdevops/php-apache.  As such, their documentation regarding php.ini and phpfpm configs apply: https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-apache.html#php-ini-variables


ENV VARS:

php.<PHPKEY>  variables are injected into the container php.ini
fpm.global.<KEY> variables are injected into global php-fpm.conf, for example: `fpm.global.log_level: error`
fpm.pool.<KEY> variables are injected into pool "www" fpm config, for example: `fpm.pool.pm.status_path: /status`
APACHE_MODULES space seperated list of modules for apache to load, for example:  `remoteip headers rewrite http2`
