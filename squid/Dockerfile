FROM debian:trixie

RUN set -eux; \
	env ; \
	apt-get update; \
	DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y; \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		squid squidclient ca-certificates tzdata procps ssl-cert apache2-utils; \
	DEBIAN_FRONTEND=noninteractive apt-get remove --purge --auto-remove -y; \
	rm -rf /var/lib/apt/lists/*; \
	# Change default configuration to allow local network access \
	rm -f /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key; \
    mkdir -p /var/cache/squid; \
	# smoketest
	/usr/sbin/squid --version; \
	# create manifest \
	mkdir -p /usr/share/rocks; \
	# (echo "# os-release" && cat /etc/os-release && echo "# dpkg-query" && dpkg-query -f '${db:Status-Abbrev},${binary:Package},${Version},${source:Package},${Source:Version}\n' -W) > /usr/share/rocks/dpkg.query \
	(dpkg-query -f '${binary:Package},${Version}\n' -W | sort) > /usr/share/rocks/packages.list

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 3128 3142
VOLUME /var/log/squid \
	/var/spool/squid
ENTRYPOINT ["entrypoint.sh"]
CMD ["-f", "/etc/squid/squid.conf", "-NYC"]
