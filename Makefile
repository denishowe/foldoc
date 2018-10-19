# Makefile for FOLDOC

# Denis Howe 2003-09-15 - 2018-09-07

# From another directory:  $(MAKE) --directory=/var/www/foldoc.org

# Run in the document root

default: $(HOSTNAME)

logged:
	$(MAKE) > make.out 2>&1

foldoc-paris-1: unix

unix: date keys offsets foldoc.tar.gz
	-date

date:
	-date

# List built HTML explicitly

DISTFILES = Dictionary Makefile *.gif *.png *.jpg \
	index.cgi build.pl Foldoc.pm *.html \
	about.html contents.html contributors.html help.html \
	home.html missing.html sitemap.html source.html

foldoc.tar.gz: $(DISTFILES)
	tar cfz $@ $(DISTFILES)

# Make the contents pages (all, A-Z, other, subject) and the keys and offset indexes

Dictionary keys offsets:	new/Dictionary junk_searches build.pl Foldoc.pm template.html Makefile
	-rm -rf jUnK
	cd new && ../build.pl index
	-mv -f contents jUnK
	cd new && mv -f contents keys offsets sitemap.html .. && cp -f Dictionary ..
	chmod 444 Dictionary
	rm -rf jUnK

%.html: %.inc.html template.html Foldoc.pm
	./build.pl do_template $(@:.html=.inc.html) $@

new.html rss.xml: Dictionary build.pl Foldoc.pm
	./build.pl new

LOGS = /var/log/apache2/foldoc.org-access-*

missing.html: Dictionary build.pl Foldoc.pm template.html $(LOGS)
	./build.pl missing

cgi-test:
	REQUEST_METHOD=1 QUERY_STRING='query=database' index.cgi

Windows_NT:
	$(MAKE) -f Makefile.windows
