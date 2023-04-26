# NFIS Geoservices Fylr plugin

## Installation

1. Clone repository into the Fylr directory "files/plugins/easydb"
2. Load submodule easydb-library:
```
git submodule update --init --recursive
````
3. Install CoffeeScript:
```
npm install --global coffeescript
```
4. Build plugin:
```
make
```
5. Add path to plugin directory to section "fylr/plugin/paths" of Fylr configuration file ("config/fylr/fylr.yml")
6. Restart Fylr
