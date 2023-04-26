PLUGIN_NAME = custom-mask-splitter-nfis
PLUGIN_PATH = nfis-geoservices-fylr-plugin

EASYDB_LIB = easydb-library

L10N_FILES = l10n/$(PLUGIN_NAME).csv

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(WEB)/l10n/es-ES.json \
	$(WEB)/l10n/it-IT.json \
	$(JS) \
	$(CSS) \
	manifest.yml

COFFEE_FILES = src/webfrontend/NFISMaskSplitter.coffee
MAIN_CSS = src/webfrontend/css/main.css
OPENLAYERS = src/external/openLayers/ol.js
OPENLAYERS_CSS = src/external/openLayers/ol.css
PROJ4 = src/external/proj4js/proj4.js

all: build

include easydb-library/tools/base-plugins.make

build: code completecss buildinfojson

code: $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(L10N)
	mkdir -p build
	mkdir -p build/webfrontend
	cat $^ > build/webfrontend/custom-mask-splitter-nfis.js
	cat $(OPENLAYERS) >> build/webfrontend/custom-mask-splitter-nfis.js
	cat $(PROJ4) >> build/webfrontend/custom-mask-splitter-nfis.js

completecss:
	rm -f build/webfrontend/custom-mask-splitter-nfis.css
	cat $(MAIN_CSS) >> build/webfrontend/custom-mask-splitter-nfis.css
	cat $(OPENLAYERS_CSS) >> build/webfrontend/custom-mask-splitter-nfis.css

clean: clean-base

wipe: wipe-base
