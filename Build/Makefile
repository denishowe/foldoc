# Makefile for FOLDOC

# Denis Howe 2003-09-15 - 2025-06-22

# Run in FOLDOC/foldoc where the source files are

B = ../Build
BUILD_PROG = $B/build.pl
# List built HTML explicitly
HTML_FILES = about.html contents.html contributors.html help.html home.html missing.html new.html source.html
LOGS = /var/log/apache2/foldoc.org/access-*
WEB_ROOT = /var/www/foldoc.org
COPY = cp
COPYFLAGS = --recursive --update -p

# Publish built files all at once

default: pub keys offsets $(HTML_FILES)
	$(COPY) $(COPYFLAGS) . $(WEB_ROOT)

pub:
	 $(COPY) $(COPYFLAGS) $@ $(WEB_ROOT)/$@ # Publish static files for early test

logged:
	$(MAKE) > make.out 2>&1

# Make the contents pages, the keys and offset indexes

keys offsets: $B/Dictionary $B/junk_searches $(BUILD_PROG) Foldoc.pm template.html $B/Makefile
	$(BUILD_PROG) index

%.html: $B/%.inc.html template.html Foldoc.pm
	$(BUILD_PROG) do_template $< $@

new.html rss.xml: Dictionary $(BUILD_PROG) Foldoc.pm
	$(BUILD_PROG) new

missing.html: Dictionary $(BUILD_PROG) Foldoc.pm template.html $(LOGS)
	$(BUILD_PROG) missing

cgi-test:
	REQUEST_METHOD=1 QUERY_STRING='query=database' index.pl
