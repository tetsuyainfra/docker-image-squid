#!/bin/bash

# Squid OCI image entrypoint

# This entrypoint aims to forward the squid logs to stdout to assist users of
# common container related tooling (e.g., kubernetes, docker-compose, etc) to
# access the service logs.

# Moreover, it invokes the squid binary, leaving all the desired parameters to
# be provided by the "command" passed to the spawned container. If no command
# is provided by the user, the default behavior (as per the CMD statement in
# the Dockerfile) will be to use Ubuntu's default configuration [1] and run
# squid with the "-NYC" options to mimic the behavior of the Ubuntu provided
# systemd unit.

# [1] The default configuration is changed in the Dockerfile to allow local
# network connections. See the Dockerfile for further information.

echo "called: $0 $@"
if [ -n "$DEBUG" ]; then
    echo "DEBUG is set, enabling debug mode"
    set -ex
else
    echo "DEBUG is not set, running in normal mode"
fi

# re-create snakeoil self-signed certificate removed in the build process
if [ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]; then
    /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite > /dev/null 2>&1
fi

SQUID_CONF="/etc/squid/squid.conf"
CACHE_DIR=${CACHE_DIR:-ufs /var/cache/squid 10000 16 256}
MAXIMUM_OBJECT_SIZE=${MAXIMUM_OBJECT_SIZE:-512 MB}
CACHE_MEM=${CACHE_MEM:-256 MB}
MAX_FILEDESCRIPTORS=${MAX_FILEDESCRIPTORS:-1024}
sed -i -e "s|cache_dir .*|cache_dir ${CACHE_DIR}|" ${SQUID_CONF}
sed -i -e "s/maximum_object_size .*/maximum_object_size ${MAXIMUM_OBJECT_SIZE}/" ${SQUID_CONF}
sed -i -e "s/cache_mem .*/cache_mem ${CACHE_MEM}/" ${SQUID_CONF}
sed -i -e "s/max_filedescriptors .*/max_filedescriptors ${MAX_FILEDESCRIPTORS}/" ${SQUID_CONF}


# example:
#    SQUID_HTTPS_USERS="user1@password1 user2@password2 user3@password3"
# separator is @, so dont use @ in username or password
#
SQUID_HTTPS_USERS=${SQUID_HTTPS_USERS}
HTPASSWD_CONF=$(dirname ${SQUID_CONF})/htpasswd.users
touch ${HTPASSWD_CONF}
for user in $SQUID_HTTPS_USERS; do
    IFS='@' read -r username password <<< "$user"
    echo "Adding user: $username with password: $password"
    htpasswd -b -B ${HTPASSWD_CONF} "$username" "$password"
done

# Change cache,log directory ownership and permissions
chown proxy:proxy /var/cache/squid
chown proxy:proxy /var/log/squid

# tail -F /var/log/squid/access.log 2>/dev/null &
# tail -F /var/log/squid/error.log 2>/dev/null &
# tail -F /var/log/squid/store.log 2>/dev/null &
# tail -F /var/log/squid/cache.log 2>/dev/null &
# create missing cache directories and exit
/usr/sbin/squid -Nz

# execute the squid as swapped UID=1(bash entrypoint.sh)
# /usr/sbin/squid "$@"
exec /usr/sbin/squid "$@"
