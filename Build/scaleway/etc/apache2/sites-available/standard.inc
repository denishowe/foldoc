# Common vhost configuration

# Usage:

# Define SERVER_NAME tailortravels.co.uk

# <VirtualHost *:80>
#	Include sites-enabled/standard.inc
# </VirtualHost>

# <VirtualHost *:80>
#	ServerName www.${SERVER_NAME}
#	RedirectMatch permanent . https://${SERVER_NAME}/
# </VirtualHost>

# HTTPS is forwarded as HTTP

ServerName ${SERVER_NAME}
DocumentRoot /var/www/${SERVER_NAME}

AddType application/x-httpd-perl .pl .cgi
AddHandler cgi-script .pl .cgi
<Directory /var/www/${SERVER_NAME}>
	Options +ExecCGI
</Directory>

LogFormat "%h %t \"%r\" %>s" short
CustomLog "|/usr/bin/rotatelogs ${APACHE_LOG_DIR}/${SERVER_NAME}/access-%Y%m%d 86400" short

# Redirect HTTP (as determined from Cloudflare X-FORWARDED-PROTO header) to HTTPS

RewriteEngine on
RewriteCond %{HTTP:X-FORWARDED-PROTO} =http
RewriteRule (.*) https://%{SERVER_NAME}$1 [R=301,L]
