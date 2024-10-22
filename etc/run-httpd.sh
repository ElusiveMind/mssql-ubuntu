#!/bin/bash

# Handle HTACCESS conditions if configured.
if [[ -n "${HTACCESS_DESCRIPTION}" ]]; then
  /usr/bin/htpasswd -cb /var/www/.htpasswd $HTACCESS_USERNAME $HTACCESS_PASSWORD
  perl -pe 's/-\$(\{)?([a-zA-Z_]\w*)(?(1)\})/$ENV{$2}/g' < /etc/apache2/apache2-auth.conf > /etc/apache2/apache2.conf
else
  perl -pe 's/-\$(\{)?([a-zA-Z_]\w*)(?(1)\})/$ENV{$2}/g' < /etc/apache2/apache2-noauth.conf > /etc/apache2/apache2.conf
fi

# Set our PHP ini environment variable defauts.
if [[ ! -n "${PHP_DISPLAY_ERRORS}" ]]; then
  export PHP_DISPLAY_ERRORS=Off
fi
if [[ ! -n "${PHP_DISPLAY_STARTUP_ERRORS}" ]]; then
  export PHP_DISPLAY_STARTUP_ERRORS=Off
fi
if [[ ! -n "${PHP_MAX_EXECUTION_TIME}" ]]; then
  export PHP_MAX_EXECUTION_TIME=300
fi
if [[ ! -n "${PHP_MAX_INPUT_TIME}" ]]; then
  export PHP_MAX_INPUT_TIME=300
fi
if [[ ! -n "${PHP_MAX_INPUT_VARS}" ]]; then
  export PHP_MAX_INPUT_VARS=1000
fi
if [[ ! -n "${PHP_MEMORY_LIMIT}" ]]; then
  export PHP_MEMORY_LIMIT=512M
fi
if [[ ! -n "${PHP_POST_MAX_SIZE}" ]]; then
  export PHP_POST_MAX_SIZE=256M
fi
if [[ ! -n "${PHP_UPLOAD_MAX_FILESIZE}" ]]; then
  export PHP_UPLOAD_MAX_FILESIZE=256M
fi

envsubst < /etc/apache2/sites-enabled/000-default.conf > /etc/apache2/sites-enabled/000-default-docroot.conf
mv -f /etc/apache2/sites-enabled/000-default-docroot.conf /etc/apache2/sites-enabled/000-default.conf

envsubst < /etc/php/8.3/apache2/php.ini > /etc/php/8.3/apache2/php2.ini
envsubst < /etc/php/8.3/cli/php.ini > /etc/php/8.3/cli/php2.ini
mv -f /etc/php/8.3/apache2/php2.ini /etc/php/8.3/apache2/php.ini
mv -f /etc/php/8.3/cli/php2.ini /etc/php/8.3/cli/php.ini

sqlservr --accept-eula &
service apache2 restart

touch ~/placeholder.txt
tail -f ~/placeholder.txt

