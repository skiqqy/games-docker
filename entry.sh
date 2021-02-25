#!/bin/bash
# Run the API

# Production Deploy
deploy () {
	echo "Starting web Server"
	/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf
	echo "Web server Closing"
}

cd /var/www/localhost/htdocs/
deploy
