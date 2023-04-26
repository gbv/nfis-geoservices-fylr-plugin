class ez5.NFISMaskSplitter extends CustomMaskSplitter

    isSimpleSplit: ->
        true

    getOptions: ->
        [
            form:
                label: $$('nfis.mask.splitter.masterportalUrl')
            type: CUI.Input
            name: 'masterportalUrl'
        ,
            form:
                label: $$('nfis.mask.splitter.geoserverUrl')
            type: CUI.Input
            name: 'geoserverUrl'
        ,
            form:
                label: $$('nfis.mask.splitter.geoserverUsername')
            type: CUI.Input
            name: 'geoserverUsername'
        ,
            form:
                label: $$('nfis.mask.splitter.geoserverPassword')
            type: CUI.Input
            name: 'geoserverPassword'
        ]

    renderField: (opts) ->
        contentElement = CUI.dom.div('nfis-plugin-content')
        geometryId = opts.data.geometry_id
        
        @__loadContent(contentElement, geometryId, opts.mode)

        return contentElement

    isEnabledForNested: ->
        return false

    __loadContent: (contentElement, geometryId, mode) ->
        ```
        const wfsUrl = this.__getWfsUrl(geometryId);
        if (!wfsUrl) return;

        const xhr = new XMLHttpRequest();
        xhr.open('GET', wfsUrl);
        xhr.setRequestHeader('Authorization', this.__getAuthenticationString());
        xhr.onload = () => {
            if (xhr.status == 200) {
                const data = JSON.parse(xhr.responseText);
                this.__renderContent(contentElement, geometryId, mode, data.totalFeatures);
            } else {
                console.error('Failed to load data from WFS service');
            }
        };
        xhr.onerror = error => {
            console.error(error);
        };
        xhr.send();
        ```
        return

    __renderContent: (contentElement, geometryId, mode, totalFeatures) ->
        ```
        if (totalFeatures > 0) {
            this.__renderMap(contentElement, geometryId);
            if (mode === 'detail') {
                this.__renderViewGeometriesButton(contentElement, geometryId);
            } else if (mode === 'editor') {
                this.__renderEditGeometriesButton(contentElement, geometryId);
            }
        } else if (mode === 'editor') {
            this.__renderCreateGeometriesButton(contentElement);
        }
        ```
        return

    __renderMap: (contentElement, geometryId) ->
        mapElement = CUI.dom.div(undefined, { 'id': 'nfis-plugin-map' })
        CUI.dom.append(contentElement, mapElement)

        @__initializeMap(geometryId)

    __renderCreateGeometriesButton: (contentElement) ->
        createGeometriesButton = new CUI.ButtonHref
            id: 'create-geometries-button'
            href: @__getCreateGeometriesUrl()
            target: '_blank'
            icon_left: new CUI.Icon(class: 'fa-external-link')
            text: $$('nfis.mask.splitter.createGeometries')

        CUI.dom.append(contentElement, createGeometriesButton)

    __renderEditGeometriesButton: (contentElement, geometryId) ->
        editGeometriesButton = new CUI.ButtonHref
            id: 'edit-geometries-button'
            href: @__getEditGeometriesUrl(geometryId)
            target: '_blank'
            icon_left: new CUI.Icon(class: 'fa-external-link')
            text: $$('nfis.mask.splitter.editGeometries')

        CUI.dom.append(contentElement, editGeometriesButton)

    __renderViewGeometriesButton: (contentElement, geometryId) ->
        showGeometriesButton = new CUI.ButtonHref
            id: 'view-geometries-button'
            href: @__getViewGeometriesUrl(geometryId)
            target: '_blank'
            icon_left: new CUI.Icon(class: 'fa-external-link')
            text: $$('nfis.mask.splitter.viewGeometries')

        CUI.dom.append(contentElement, showGeometriesButton)

    __initializeMap: (geometryId, delay = 0) ->
        ```
        setTimeout(() => {
            if (!document.getElementById('nfis-plugin-map')) {
                return this.__initializeMap(geometryId, 100);
            }

            const epsg = 'EPSG:25832';
            proj4.defs(epsg, '+proj=utm +zone=32 +ellps=GRS80 +units=m +no_defs');
            ol.proj.proj4.register(proj4);

            const projection = ol.proj.get(
                new ol.proj.Projection({
                    code: epsg,
                    units: 'm',
                    extent: [120000, 5661139.2, 1378291.2, 6500000]
                })
            );

            const wfsUrl = this.__getWfsUrl(geometryId);
            const authenticationString = this.__getAuthenticationString();

            const vectorSource = new ol.source.Vector({
                format: new ol.format.GeoJSON(),
                loader: function(extent, resolution, projection, success, failure) {
                    const xhr = new XMLHttpRequest();
                    xhr.open('GET', wfsUrl);
                    xhr.setRequestHeader('Authorization', authenticationString);

                    const onError = () => {
                        vectorSource.removeLoadedExtent(extent);
                        failure();
                    }

                    xhr.onerror = onError;
                    xhr.onload = () => {
                        if (xhr.status == 200) {
                            const features = vectorSource.getFormat().readFeatures(xhr.responseText);
                            vectorSource.addFeatures(features);
                            success(features);
                        } else {
                            onError();
                        }
                    }
                    if (wfsUrl) xhr.send();
                },
                strategy: ol.loadingstrategy.all,
            });

            vectorSource.on('featuresloadend', () => {
                map.getView().fit(vectorSource.getExtent());
            });

            const rasterSource = new ol.source.TileWMS({
                url: 'https://sgx.geodatenzentrum.de/wms_basemapde',
                params: {
                    LAYERS: 'de_basemapde_web_raster_farbe'
                },
                projection
            });

            const rasterLayer = new ol.layer.Tile({
                extent: projection.getExtent(),
                source: rasterSource
            });

            const vectorLayer = new ol.layer.Vector({
                source: vectorSource,
                style: {
                    'stroke-width': 1.5,
                    'stroke-color': 'black',
                    'fill-color': 'rgba(100,100,100,0.25)'
                }
            });

            const map = new ol.Map({
                target: 'nfis-plugin-map',
                layers: [rasterLayer, vectorLayer],
                view: new ol.View({
                    projection,
                    center: [561397, 5709705],
                    maxZoom: 19,
                    zoom: 7,
                })
            });
        }, delay);
        ```
        return
    
    __getViewGeometriesUrl: (geometryId) ->
        masterportalUrl = @getDataOptions().masterportalUrl
        if !masterportalUrl
            return ''
        return masterportalUrl + '?api/highlightFeaturesByAttribute=1279&wfsId=1279&attributeName=municipality&attributeValue=' + geometryId + '&attributeQuery=isequal&zoomToGeometry=' + geometryId;

    __getEditGeometriesUrl: (geometryId) ->
        masterportalUrl = @getDataOptions().masterportalUrl
        if !masterportalUrl
            return ''
        return masterportalUrl + '?api/highlightFeaturesByAttribute=1279&wfsId=1279&attributeName=municipality&attributeValue=' + geometryId + '&attributeQuery=isequal&zoomToGeometry=' + geometryId + '&isinitopen=wfst';

    __getCreateGeometriesUrl: () ->
        masterportalUrl = @getDataOptions().masterportalUrl
        if !masterportalUrl
            return ''
        return masterportalUrl + '?isinitopen=wfst';

    __getWfsUrl: (geometryId) ->
        geoserverUrl = @getDataOptions().geoserverUrl
        if !geoserverUrl
            return ''
        geoserverUrl += '/' if !geoserverUrl.endsWith('/')
        ```
        const url = geoserverUrl + 'nfis/wfs?service=WFS&' +
            'version=1.1.0&request=GetFeature&typename=wfst&' +
            'outputFormat=application/json&srsname=EPSG:25832&' +
            'cql_filter=municipality=\''+ geometryId + '\'';
        ```
        return url

    __getAuthenticationString: () ->
        username = @getDataOptions().geoserverUsername
        password = @getDataOptions().geoserverPassword
        return 'Basic ' + window.btoa(username + ':' + password)

MaskSplitter.plugins.registerPlugin(ez5.NFISMaskSplitter)
