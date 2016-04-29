#!/bin/bash

set -e

__handle_passwords() {
    if [ -z "$DBNAME" ]; then
        printf "No DBNAME variable.\n"
        exit 1
    fi
    if [ -z "$DBUSER" ]; then
        printf "No DBUSER variable.\n"
        exit 1
    fi
    # Here we generate random passwords (thank you pwgen!) for random keys in wp-config.php
    printf "Creating wp-config.php...\n"
    # There used to be a huge ugly line of sed and cat and pipe and stuff below,
    # but thanks to @djfiander's thing at https://gist.github.com/djfiander/6141138
    # there isn't now.
    sed -e "s/database_name_here/$DBNAME/
    s/username_here/$DBUSER/
    s/password_here/$DBPASS/" /var/www/html/wp-config-sample.php > /var/www/html/wp-config.php
    #
    # Update keys/salts in wp-config for security
    RE='put your unique phrase here'
    for i in {1..8}; do
        KEY=$(openssl rand -base64 40)
        sed -i "0,/$RE/s|$RE|$KEY|" /var/www/html/wp-config.php
    done
}

__handle_db_host() {
    # Update wp-config.php to point to our linked container's address.
    DB_PORT='tcp://127.0.0.1:3306' # Using localhost for this one
    sed -i -e "s/^\(define('DB_HOST', '\).*\(');.*\)/\1${DB_PORT#tcp://}\2/" \
        /var/www/html/wp-config.php
}

__httpd_perms() {
    chown apache:apache /var/www/html/wp-config.php
}

__check() {
    if [ ! -f /var/www/html/wp-config.php ]; then
        __handle_passwords
        __httpd_perms
    fi
    __handle_db_host
}

# Call all functions
__check
