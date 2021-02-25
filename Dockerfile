FROM alpine:latest

EXPOSE 80

RUN apk update && apk add lighttpd wget git

# Lighttpd Setup
RUN mkdir -p /var/www/localhost/htdocs/stats /var/log/lighttpd /var/lib/lighttpd

RUN sed -i -r 's#\#.*server.port.*=.*#server.port          = 80#g' /etc/lighttpd/lighttpd.conf && \
	sed -i -r 's#.*server.stat-cache-engine.*=.*# server.stat-cache-engine = "simple"#g' /etc/lighttpd/lighttpd.conf && \
	sed -i -r 's#\#.*server.event-handler = "linux-sysepoll".*#server.event-handler = "linux-sysepoll"#g' /etc/lighttpd/lighttpd.conf && \
	chown -R lighttpd:lighttpd /var/www/localhost/ && \
	chown -R lighttpd:lighttpd /var/lib/lighttpd && \
	chown -R lighttpd:lighttpd /var/log/lighttpd && \
	sed -i -r 's#\#.*mod_status.*,.*#    "mod_status",#g' /etc/lighttpd/lighttpd.conf && \
	sed -i -r 's#.*status.status-url.*=.*#status.status-url  = "/stats/server-status"#g' /etc/lighttpd/lighttpd.conf && \
	sed -i -r 's#.*status.config-url.*=.*#status.config-url  = "/stats/server-config"#g' /etc/lighttpd/lighttpd.conf

# PHP Setup
RUN apk add php7 php7-bcmath php7-bz2 php7-ctype php7-curl php7-dom php7-enchant php7-exif php7-fpm php7-gd php7-gettext php7-gmp php7-iconv php7-imap php7-intl php7-json php7-mbstring php7-opcache php7-openssl php7-phar php7-posix php7-pspell php7-recode php7-session php7-simplexml php7-sockets php7-sysvmsg php7-sysvsem php7-sysvshm php7-tidy php7-xml php7-xmlreader php7-xmlrpc php7-xmlwriter php7-xsl php7-zip php7-sqlite3
RUN apk add php7-pgsql php7-mysqli php7-mysqlnd php7-snmp php7-soap php7-ldap php7-pcntl php7-pear php7-shmop php7-wddx php7-cgi php7-pdo php7-snmp php7-tokenizer
RUN apk add php7-dba php7-sqlite3 php7-mysqli php7-mysqlnd php7-pgsql php7-pdo_dblib php7-pdo_odbc php7-pdo_pgsql php7-pdo_sqlite 

# PHP Configs
RUN sed -i -r 's|.*cgi.fix_pathinfo=.*|cgi.fix_pathinfo=1|g' /etc/php*/php.ini && \
	sed -i -r 's#.*safe_mode =.*#safe_mode = Off#g' /etc/php*/php.ini && \
	sed -i -r 's#.*expose_php =.*#expose_php = Off#g' /etc/php*/php.ini && \
	sed -i -r 's#memory_limit =.*#memory_limit = 536M#g' /etc/php*/php.ini && \
	sed -i -r 's#upload_max_filesize =.*#upload_max_filesize = 128M#g' /etc/php*/php.ini && \
	sed -i -r 's#post_max_size =.*#post_max_size = 256M#g' /etc/php*/php.ini && \
	sed -i -r 's#^file_uploads =.*#file_uploads = On#g' /etc/php*/php.ini && \
	sed -i -r 's#^max_file_uploads =.*#max_file_uploads = 12#g' /etc/php*/php.ini && \
	sed -i -r 's#^allow_url_fopen = .*#allow_url_fopen = On#g' /etc/php*/php.ini && \
	sed -i -r 's#^.default_charset =.*#default_charset = "UTF-8"#g' /etc/php*/php.ini && \
	sed -i -r 's#^.max_execution_time =.*#max_execution_time = 150#g' /etc/php*/php.ini && \
	sed -i -r 's#^max_input_time =.*#max_input_time = 90#g' /etc/php*/php.ini

# Final PHP prep
RUN mkdir -p /var/run/php-fpm7/ && \
	chown lighttpd:root /var/run/php-fpm7 && \
	sed -i -r 's|^.*listen =.*|listen = /run/php-fpm7/php7-fpm.sock|g' /etc/php*/php-fpm.d/www.conf && \
	sed -i -r 's|^pid =.*|pid = /run/php-fpm7/php7-fpm.pid|g' /etc/php*/php-fpm.conf && \
	sed -i -r 's|^.*listen.mode =.*|listen.mode = 0640|g' /etc/php*/php-fpm.d/www.conf

ADD cgi.conf /etc/lighttpd/mod_fastcgi_fpm.conf
RUN mkdir -p /var/www/localhost/cgi-bin && \
	sed -i -r 's#\#.*mod_alias.*,.*#    "mod_alias",#g' /etc/lighttpd/lighttpd.conf && \
	sed -i -r 's#.*include "mod_cgi.conf".*#   include "mod_cgi.conf"#g' /etc/lighttpd/lighttpd.conf && \
	sed -i -r 's#.*include "mod_fastcgi.conf".*#\#   include "mod_fastcgi.conf"#g' /etc/lighttpd/lighttpd.conf && \
	sed -i -r 's#.*include "mod_fastcgi_fpm.conf".*#   include "mod_fastcgi_fpm.conf"#g' /etc/lighttpd/lighttpd.conf && \
	sed -i -r 's|^.*listen =.*|listen = /var/run/php-fpm7/php7-fpm.sock|g' /etc/php*/php-fpm.d/www.conf && \
	sed -i -r 's|^.*listen.owner = .*|listen.owner = lighttpd|g' /etc/php*/php-fpm.d/www.conf && \
	sed -i -r 's|^.*listen.group = .*|listen.group = lighttpd|g' /etc/php*/php-fpm.d/www.conf && \
	sed -i -r 's|^.*listen.mode = .*|listen.mode = 0660|g' /etc/php*/php-fpm.d/www.conf && \
	echo "<?php echo phpinfo(); ?>" > /var/www/localhost/htdocs/info.php

# Download games repo
RUN rm -rf /var/www/localhost/htdocs && git clone https://github.com/skiqqy/games /var/www/localhost/htdocs
RUN cd /var/www/localhost/htdocs/_build && php build.php install

ADD entry.sh /entry.sh
ENTRYPOINT ["sh", "/entry.sh"]
