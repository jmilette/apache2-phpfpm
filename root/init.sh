#!/bin/bash
shopt -s nullglob
set -e


#Set default vars and enable needed apache configs
if [[ -z $PHPVERSION ]]; then echo "ERROR: empty PHPVERSION, this should not happen" && exit 1; fi
if [[ -z $GROUP_ID ]]; then GROUP_ID=1000; fi
if [[ -z $USER_ID ]]; then USER_ID=1000; fi
if [[ -n $APACHE_MODULES ]]; then a2enmod $APACHE_MODULES; fi
if [[ -z $PHP_FPM_SCRAPE_URI ]]; then export PHP_FPM_SCRAPE_URI='unix:///run/php/php$PHPVERSION-fpm.sock;/status'; fi


function createUser() {
    #delete user if already exists, i.e. container is restarted.
    if $(id "application" &>/dev/null); then
        deluser "application"
        delgroup "application" || true
    fi
    addgroup --gid $GROUP_ID application
    useradd -s /usr/sbin/nologin --uid $USER_ID --gid $GROUP_ID --no-create-home application
    

}

# List environment variables (based on prefix)
function envListVars() {
    if [[ $# -eq 1 ]]; then
        env | grep "^${1}" | cut -d= -f1
    else
        env | cut -d= -f1
    fi
}
# Get environment variable (even with dots in name)
function envGetValue() {
    awk "BEGIN {print ENVIRON[\"$1\"]}"
}


function cleanConfigs() {
    #back up and clean php.ini
    if [ ! -f /config/php/php.ini.original ]; then cp /config/php/php.ini /config/php/php.ini.original;fi
    cat /config/php/php.ini.original > /config/php/php.ini

    #back up and clean global php-fpm.conf
    if [ ! -f /config/php/fpm/php-fpm.conf.original ]; then cp /config/php/fpm/php-fpm.conf /config/php/fpm/php-fpm.conf.original;fi
    cat /config/php/fpm/php-fpm.conf.original > /config/php/fpm/php-fpm.conf

    #back up and clean pool php-fpm.conf
    if [ ! -f /config/php/fpm/pool.d/application.conf.original ]; then cp /config/php/fpm/pool.d/application.conf /config/php/fpm/pool.d/application.conf.original;fi
    cat /config/php/fpm/pool.d/application.conf.original > /config/php/fpm/pool.d/application.conf

    #Remove php socket dir if it exists and create it
    if [ -d /run/php ]; then rm -rf /run/php;fi
    mkdir /run/php
    #Remove default apache site configs
    rm -rf /etc/apache2/sites-enabled && mkdir /etc/apache2/sites-enabled
    #Wipe phpfpm pool config
    rm -rf /etc/php/$PHPVERSION/fpm/pool.d && mkdir /etc/php/$PHPVERSION/fpm/pool.d

    #Remove old configs, reset mpm_event.config
    if [[ -e /etc/php/$PHPVERSION/fpm/php.ini ]]; then rm /etc/php/$PHPVERSION/fpm/php.ini; fi
    if [[ -e /etc/php/$PHPVERSION/cli/php.ini ]]; then rm /etc/php/$PHPVERSION/cli/php.ini; fi
    if [[ -e /etc/php/$PHPVERSION/cli/php.ini ]]; then rm /etc/php/$PHPVERSION/cli/php.ini; fi
    if [[ -e /etc/apache2/conf-enabled/docker.conf ]]; then rm /etc/apache2/conf-enabled/docker.conf; fi
    if [[ -e /etc/apache2/mods-enabled/mpm_event.conf ]]; then rm /etc/apache2/mods-enabled/mpm_event.conf && \
        ln -s /etc/apache2/mods-available/mpm_event.conf /etc/apache2/mods-enabled/mpm_event.conf; fi
}


function generatePHPini() {
    # Main php.ini config modifications
    echo '' >> /config/php/php.ini
    echo '; container env settings' >> /config/php/php.ini

    # General php setting
    for ENV_VAR in $(envListVars "php\."); do
        env_key=${ENV_VAR#php.}
        env_val=$(envGetValue "$ENV_VAR")
        echo "$env_key = ${env_val}" >> /config/php/php.ini
    done

    if [[ -n "${PHP_DATE_TIMEZONE+x}" ]]; then echo "date.timezone = ${PHP_DATE_TIMEZONE}" >> /config/php/php.ini;fi
    if [[ -n "${PHP_DISPLAY_ERRORS+x}" ]]; then echo "display_errors = ${PHP_DISPLAY_ERRORS}" >> /config/php/php.ini;fi
    if [[ -n "${PHP_MEMORY_LIMIT+x}" ]]; then echo "memory_limit = ${PHP_MEMORY_LIMIT}" >> /config/php/php.ini;fi
    if [[ -n "${PHP_MAX_EXECUTION_TIME+x}" ]]; then echo "max_execution_time = ${PHP_MAX_EXECUTION_TIME}" >> /config/php/php.ini;fi
    if [[ -n "${PHP_POST_MAX_SIZE+x}" ]]; then echo "post_max_size = ${PHP_POST_MAX_SIZE}" >> /config/php/php.ini;fi
    if [[ -n "${PHP_UPLOAD_MAX_FILESIZE+x}" ]]; then echo "upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}" >> /config/php/php.ini;fi
    if [[ -n "${PHP_OPCACHE_MEMORY_CONSUMPTION+x}" ]]; then echo "opcache.memory_consumption = ${PHP_OPCACHE_MEMORY_CONSUMPTION}" >> /config/php/php.ini;fi
    if [[ -n "${PHP_OPCACHE_MAX_ACCELERATED_FILES+x}" ]]; then echo "opcache.max_accelerated_files = ${PHP_OPCACHE_MAX_ACCELERATED_FILES}" >> /config/php/php.ini; fi
    if [[ -n "${PHP_OPCACHE_VALIDATE_TIMESTAMPS+x}" ]]; then echo "opcache.validate_timestamps = ${PHP_OPCACHE_VALIDATE_TIMESTAMPS}" >> /config/php/php.ini; fi
    if [[ -n "${PHP_OPCACHE_REVALIDATE_FREQ+x}" ]]; then echo "opcache.revalidate_freq = ${PHP_OPCACHE_REVALIDATE_FREQ}" >> /config/php/php.ini; fi
    if [[ -n "${PHP_OPCACHE_INTERNED_STRINGS_BUFFER+x}" ]]; then echo "opcache.interned_strings_buffer = ${PHP_OPCACHE_INTERNED_STRINGS_BUFFER}" >> /config/php/php.ini;fi
    if [[ -n "${PHP_SENDMAIL_PATH+x}" ]]; then echo "sendmail_path = ${PHP_SENDMAIL_PATH}" >> /config/php/php.ini;fi

}

function generateGlobalFPMconf() {

    echo '' >> /config/php/fpm/php-fpm.conf
    echo '; container env settings' >> /config/php/fpm/php-fpm.conf
    echo '[global]' >> /config/php/fpm/php-fpm.conf

    if [[ -n "${FPM_PROCESS_MAX+x}" ]]; then echo "process.max = ${FPM_PROCESS_MAX}" >> /config/php/fpm/php-fpm.conf;fi

    # General fpm main setting
    for ENV_VAR in $(envListVars "fpm\.global\."); do
        env_key=${ENV_VAR#fpm.global.}
        env_val=$(envGetValue "$ENV_VAR")
        echo "$env_key = ${env_val}" >> /config/php/fpm/php-fpm.conf
    done
}


function generatePoolFPMconf() {
    echo '' >> /config/php/fpm/pool.d/application.conf
    echo '; container env settings' >> /config/php/fpm/pool.d/application.conf
    echo '[www]' >> /config/php/fpm/pool.d/application.conf

    # General fpm pool setting
    for ENV_VAR in $(envListVars "fpm\.pool\."); do
        env_key=${ENV_VAR#fpm.pool.}
        env_val=$(envGetValue "$ENV_VAR")
        echo "$env_key = ${env_val}" >> /config/php/fpm/pool.d/application.conf
    done

    if [[ -n "${FPM_PM_MAX_CHILDREN+x}" ]]; then echo "pm.max_children = ${FPM_PM_MAX_CHILDREN}" >> /config/php/fpm/pool.d/application.conf;fi
    if [[ -n "${FPM_PM_START_SERVERS+x}" ]]; then echo "pm.start_servers = ${FPM_PM_START_SERVERS}" >> /config/php/fpm/pool.d/application.conf;fi
    if [[ -n "${FPM_PM_MIN_SPARE_SERVERS+x}" ]]; then echo "pm.min_spare_servers = ${FPM_PM_MIN_SPARE_SERVERS}" >> /config/php/fpm/pool.d/application.conf;fi
    if [[ -n "${FPM_PM_MAX_SPARE_SERVERS+x}" ]]; then echo "pm.max_spare_servers = ${FPM_PM_MAX_SPARE_SERVERS}" >> /config/php/fpm/pool.d/application.conf; fi
    if [[ -n "${FPM_PROCESS_IDLE_TIMEOUT+x}" ]]; then echo "pm.process_idle_timeout = ${FPM_PROCESS_IDLE_TIMEOUT}" >> /config/php/fpm/pool.d/application.conf;fi
    if [[ -n "${FPM_MAX_REQUESTS+x}" ]]; then echo "pm.max_requests = ${FPM_MAX_REQUESTS}" >> /config/php/fpm/pool.d/application.conf;fi
    if [[ -n "${FPM_REQUEST_TERMINATE_TIMEOUT+x}" ]]; then echo "request_terminate_timeout = ${FPM_REQUEST_TERMINATE_TIMEOUT}" >> /config/php/fpm/pool.d/application.conf;fi
    if [[ -n "${FPM_RLIMIT_FILES+x}" ]]; then echo "rlimit_files = ${FPM_RLIMIT_FILES}" >> /config/php/fpm/pool.d/application.conf;fi
    if [[ -n "${FPM_RLIMIT_CORE+x}" ]]; then echo "rlimit_core = ${FPM_RLIMIT_CORE}" >> /config/php/fpm/pool.d/application.conf;fi
    if [[ -n "${PHP_SENDMAIL_PATH+x}" ]]; then echo "php_admin_value[sendmail_path] = ${PHP_SENDMAIL_PATH}" >> /config/php/fpm/pool.d/application.conf;fi
    echo "listen = /run/php/php$PHPVERSION-fpm.sock" >> /config/php/fpm/pool.d/application.conf
}


function installConfigs() {
    #Install container configs
    cp /config/php/php.ini /etc/php/$PHPVERSION/fpm/php.ini
    cp /config/php/php.ini /etc/php/$PHPVERSION/cli/php.ini
    cp /config/php/fpm/php-fpm.conf /etc/php/$PHPVERSION/fpm/pool.d/container-fpm.conf
    cp /config/httpd/docker.conf /etc/apache2/conf-enabled/docker.conf
    cp -R /config/php/fpm/pool.d/*.conf /etc/php/$PHPVERSION/fpm/pool.d/
    if [[ -e /config/httpd/conf.d/mpm_event.conf ]]; then echo "Installing mpm_event.conf override" && rm /etc/apache2/mods-enabled/mpm_event.conf && \
        ln -s /config/httpd/conf.d/mpm_event.conf /etc/apache2/mods-enabled/mpm_event.conf; fi
    #Fix permissions on crontab
    chown root:root /etc/crontab
}


echo "Setting UID/GID"
createUser
echo "Cleaning configurations"
cleanConfigs
echo "Generating and installing configuration"
generatePHPini
generateGlobalFPMconf
generatePoolFPMconf
installConfigs

echo "Starting supervisord"
chown -R application:application /var/log/supervisor && /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
