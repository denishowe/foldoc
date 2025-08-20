# Common vhost configuration

# Usage:

# <VirtualHost *:80>
#	Define SERVER_NAME tailortravels.co.uk
#	Include sites-enabled/standard.inc
# </VirtualHost>

# HTTPS is forwarded as HTTP

ServerName ${SERVER_NAME}
ServerAlias www.${SERVER_NAME}
DocumentRoot /var/www/${SERVER_NAME}

AddType application/x-httpd-perl .pl
AddHandler cgi-script .pl
<Directory /var/www/${SERVER_NAME}>
	Options +ExecCGI
</Directory>

LogFormat "%h %t \"%r\" %>s" short
CustomLog "|/usr/bin/rotatelogs ${APACHE_LOG_DIR}/${SERVER_NAME}/access-%Y%m%d 86400" short
