#### This is Apache2 with integrated PHP-FPM and PHPFPM prometheus exporter ([hipages/php-fpm_exporter:1.2.1](https://github.com/hipages/php-fpm_exporter))

* `/config/php/php.ini` replacable user config  
* `/config/php/fpm/pool.d/` add any custom phpfpm configs here  
* `/config/httpd/conf.d/` add any custom apache configs here


The majority of configuration can be done using environment variables, using methods borrowed from [webdevops/php-apache](https://hub.docker.com/r/webdevops/php-apache).  As such, their [documentation](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-apache.html#php-ini-variables) regarding php.ini and phpfpm configs apply.


#### Environment Variables:

`php.<PHPKEY>` variables are injected into the container php.ini  
`fpm.global.<KEY>` variables are injected into global php-fpm.conf, for example: `fpm.global.log_level: error`  
`fpm.pool.<KEY>` variables are injected into pool "www" fpm config, for example: `fpm.pool.pm.status_path: /status`  
`APACHE_MODULES` space seperated list of modules for apache to load, for example:  `remoteip headers rewrite http2`  


#### Apache MPM Event Configuration

To override apache's MPM Event configuration, supply the desired config at `/config/httpd/conf.d/mpm_event.conf`

Updated:  10/3/22