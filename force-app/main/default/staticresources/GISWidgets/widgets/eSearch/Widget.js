///////////////////////////////////////////////////////////////////////////
// Robert Scheitlin WAB eSearch Widget
///////////////////////////////////////////////////////////////////////////
/*global define, dojo, console, window, setTimeout, jimuConfig*/
define([
    'dojo/_base/declare',
    'dijit/_WidgetsInTemplateMixin',
    'jimu/BaseWidget',
    'jimu/dijit/TabContainer',
    './List',
    './Parameters',
    './RelateChooser',
    'jimu/dijit/Message',
    'jimu/utils',
	'jimu/tokenUtils',
    'esri/urlUtils',
    'esri/tasks/query',
    'esri/tasks/QueryTask',
    'esri/tasks/RelationshipQuery',
    'esri/layers/CodedValueDomain',
    'esri/layers/Domain',
    'esri/layers/GraphicsLayer',
    'esri/layers/FeatureLayer',
    'esri/layers/FeatureType',
    'esri/layers/Field',
    'esri/layers/RangeDomain',
    'esri/tasks/BufferParameters',
    'esri/tasks/GeometryService',
    'esri/config',
    'esri/graphic',
    'esri/graphicsUtils',
    'esri/geometry/Point',
    'esri/symbols/SimpleMarkerSymbol',
    'esri/symbols/PictureMarkerSymbol',
    'esri/geometry/Polyline',
    'esri/symbols/SimpleLineSymbol',
    'esri/geometry/Polygon',
    'esri/geometry/Circle',
    'esri/units',
    'esri/geometry/Multipoint',
    'esri/geometry/Extent',
    'esri/symbols/SimpleFillSymbol',
    'esri/symbols/jsonUtils',
    'esri/renderers/SimpleRenderer',
    'esri/renderers/jsonUtils',
    'esri/toolbars/draw',
    'esri/dijit/PopupTemplate',
    'esri/InfoTemplate',
    'esri/request',
    'esri/Color',
    'dojo/Deferred',
    'dijit/ProgressBar',
    'dojo/_base/lang',
    'dojo/on',
    'dojo/_base/html',
    'dojo/_base/array',
    'dojo/promise/all',
    'dojo/date',
    'dojo/date/locale',
    'dijit/form/Select',
    'dijit/form/TextBox',
    'dijit/form/NumberTextBox',
    'jimu/dijit/DrawBox',
    'jimu/dijit/LoadingShelter',
    'dojo/io-query',
    'dojo/query',
    'esri/SpatialReference',
    'dijit/registry',
    'jimu/WidgetManager',
    'jimu/PanelManager',
    'dojo/aspect',
    'esri/domUtils',
    'jimu/LayerInfos/LayerInfos',
    'jimu/CSVUtils',
    'jimu/BaseFeatureAction',
    'jimu/FeatureActionManager',
    'jimu/dijit/PopupMenu',
    'esri/tasks/FeatureSet',
    'dojox/lang/functional/object',
    'esri/tasks/RelationshipQuery',
    'jimu/dijit/CheckBox',
    'dijit/form/DropDownButton',
    'dijit/Menu',
    'dijit/MenuItem'
  ],
  function (
    declare, _WidgetsInTemplateMixin, BaseWidget, TabContainer, List, Parameters, RelateChooser, Message, jimuUtils, tokenUtils, urlUtils, Query, QueryTask,
    RelationshipQuery, CodedValueDomain, Domain, GraphicsLayer, FeatureLayer, FeatureType, Field, RangeDomain, BufferParameters, GeometryService,
    esriConfig, Graphic, graphicsUtils, Point, SimpleMarkerSymbol, PictureMarkerSymbol, Polyline, SimpleLineSymbol, Polygon, Circle, esriUnits, Multipoint, Extent,
    SimpleFillSymbol, symUtils, SimpleRenderer, jsonUtil, Draw, PopupTemplate, InfoTemplate, esriRequest, Color, Deferred, ProgressBar, lang, on, html, array,
    all, date, locale, Select, TextBox, NumberTextBox, DrawBox, LoadingShelter, ioquery, dojoQuery, SpatialReference, registry, WidgetManager,
    PanelManager, aspect, domUtils, LayerInfos, CSVUtils, BaseFeatureAction, FeatureActionManager, PopupMenu, FeatureSet, dojoObject, RelationshipQuery
  ) { /*jshint unused: true*/
    return declare([BaseWidget, _WidgetsInTemplateMixin], {
      name: 'eSearch',
      label:'Enhanced Search',
      baseClass: 'widget-esearch',
      resultLayers: [],
      operationalLayers: [],
      graphicLayerIndex: 0,
      AttributeLayerIndex: 0,
      spatialLayerIndex: 0,
      expressIndex: 0,
      progressBar: null,
      tabContainer: null,
      list: null,
      selTab: null,
      garr: [],
      pointSearchTolerance: 6,
      polygonsToDiscard: [],
      autozoomtoresults: false,
      layerautozoomtoresults: false,
      keepgraphicalsearchenabled: false,
      layerDomainsCache: {},
      layerUniqueCache: null,
      graphicsLayerBuffer: null,
      bufferWKID: null,
      initiator: null,
      currentLayerIndex: null,
      lastWhere: null,
      wManager: null,
      pManager: null,
      attTableOpenedbySearch: false,
      oidArray: null,
      disabledTabs: null,
      shapeTab: true,
      attribTab: true,
      spatTab: true,
      rsltsTab: true,
      mouseovergraphics: false,
      lastDrawCommonType: null,
      lastDrawTool: null,
      zoomAttempt: 0,
      tempResultLayer: null,
      currentSearchLayer: null,
      currentFeatures: null,
      eLocateGLFound: false,
      locateGraphicsLayer: null,
      mapLayerAddResultEvent: null,
      eLocateEnabled: true,
      gSelectTypeVal: 'new',
      aSelectTypeVal: 'new',
      serviceFailureNames: [],
      resultFormatString: "",
      operLayerInfos: null,
      sumResultArr: [],
      sumFields: [],
      currentCSVResults: null,
      popupMenu: null,
      autoactivatedtool: null,
	  bgManager: null,
	  bgAllUsersString:"",
	  s_geometry: null, 
	  s_layerIndex: 0, 
	  s_layerValue: null, 
	  s_proxyErrors: 0,
	  geometryForBGRegularSearch: null,
	  basicgovLayerSelected: false,
    isBufferSearch: null,
    circleLayer: null,
    featureLayerString: null,
	bgFields: null,

      postCreate: function () {
        this.inherited(arguments);
        this.popupMenu = PopupMenu.getInstance();
        this.featureActionManager = FeatureActionManager.getInstance();
        if(this.config.graphicalsearchoptions.autoactivatedtool){
          this.autoactivatedtool = this.config.graphicalsearchoptions.autoactivatedtool;
        }
        if (this.map.itemId) {
          LayerInfos.getInstance(this.map, this.map.itemInfo)
            .then(lang.hitch(this, function(operLayerInfos) {
              this.operLayerInfos = operLayerInfos;
            }));
        } else {
          var itemInfo = this._obtainMapLayers();
          LayerInfos.getInstance(this.map, itemInfo)
            .then(lang.hitch(this, function(operLayerInfos) {
              this.operLayerInfos = operLayerInfos;
            }));
        }
        html.empty(this.divResultMessage);
        this.resultLayers = [];
        this.layerUniqueCache = {};
        this._initResultFormatString();
        this._initTabContainer();
        this._initBufferUnits();
        //this._initSpatialRelationships();
        this._initLayerSelect();
        this._initProgressBar();
        this._initDrawBox();
        this._initCheckForSupportedWidgets();
        this._combineRadioCheckBoxWithLabel();
        this.garr = [];
        this.polygonsToDiscard = [];
        this._addBufferLayer();
        this.wManager = WidgetManager.getInstance();
        this.pManager = PanelManager.getInstance();
        aspect.before(this, "onClose", this.closeDDs);
        //this._addThemeFixes();
        this.own(on(this.domNode, 'mousedown', lang.hitch(this, function (event) {
          event.stopPropagation();
          if (event.altKey) {
            var msgStr = this.nls.widgetverstr + ': ' + this.manifest.version;
            msgStr += '\n' + this.nls.wabversionmsg + ': ' + this.manifest.wabVersion;
            msgStr += '\n' + this.manifest.description;
            new Message({
              titleLabel: this.nls.widgetversion,
              message: msgStr
            });
          }
        })));
		if(dojoSubscribersMap['searchWidgetEventBG'+'bufferSearchInSearchWidget'+'Search'] != true){
			dojo.subscribe('searchWidgetEventBG', lang.hitch(this, this.bufferSearchInSearchWidget));
			dojoSubscribersMap['searchWidgetEventBG'+'bufferSearchInSearchWidget'+'Search'] = true;
		} 
		if(dojoSubscribersMap['searchWidgetEvent'+'bufferSearchInSearchWidget'+'Search'] != true){
			dojo.subscribe('searchWidgetEvent', lang.hitch(this, this.bufferSearchInSearchWidget));
			dojoSubscribersMap['searchWidgetEvent'+'bufferSearchInSearchWidget'+'Search'] = true;
		}
		if(dojoSubscribersMap['listViews_search'+'_addBGLayersToLayerSelect'+'Search'] != true){
			dojo.subscribe('listViews_search', lang.hitch(this, this._addBGLayersToLayerSelect));
			dojoSubscribersMap['listViews_search'+'_addBGLayersToLayerSelect'+'Search'] = true;
		}
		/*if(dojoSubscribersMap['allUsers_search'+'getBGUsers'+'Search'] != true){
			dojo.subscribe('allUsers_search', lang.hitch(this, this.getBGUsers));
			dojoSubscribersMap['allUsers_search'+'getBGUsers'+'Search'] = true;
		}
	    if(dojoSubscribersMap['assignToUserEventBGSearch'+'assignToBGUser'+'Search'] != true){
			dojo.subscribe('assignToUserEventBGSearch', lang.hitch(this, this.assignToBGUser));
			dojoSubscribersMap['assignToUserEventBGSearch'+'assignToBGUser'+'Search'] = true;
		}
		if(dojoSubscribersMap['assignToUser_search'+'onAssignFinish'+'Search'] != true){
			dojo.subscribe('assignToUser_search', lang.hitch(this, this.onAssignFinish));
			dojoSubscribersMap['assignToUser_search'+'onAssignFinish'+'Search'] = true;
		}*/
      },
	  
	  /*assignToBGUser: function(params) {
		console.debug("*** Params" + params);
		this.shelter.show();
		this.bgManager.assignToUserSearch(params[0], params[1]);
	  },
	  
	  onAssignFinish: function(result) {
		new Message({
		  message: result
		});
		this.shelter.hide();
		this._hideInfoWindow();
	  },*/

      _obtainMapLayers: function() {
        // summary:
        //    obtain basemap layers and operational layers if the map is not webmap.
        var basemapLayers = [],
          operLayers = [];
        // emulate a webmapItemInfo.
        var retObj = {
          itemData: {
            baseMap: {
              baseMapLayers: []
            },
            operationalLayers: []
          }
        };
        array.forEach(this.map.graphicsLayerIds, function(layerId) {
          var layer = this.map.getLayer(layerId);
          if (layer.isOperationalLayer) {
            operLayers.push({
              layerObject: layer,
              title: layer.label || layer.title || layer.name || layer.id || " ",
              id: layer.id || " "
            });
          }
        }, this);
        array.forEach(this.map.layerIds, function(layerId) {
          var layer = this.map.getLayer(layerId);
          if (layer.isOperationalLayer) {
            operLayers.push({
              layerObject: layer,
              title: layer.label || layer.title || layer.name || layer.id || " ",
              id: layer.id || " "
            });
          } else {
            basemapLayers.push({
              layerObject: layer,
              id: layer.id || " "
            });
          }
        }, this);

        retObj.itemData.baseMap.baseMapLayers = basemapLayers;
        retObj.itemData.operationalLayers = operLayers;
        return retObj;
      },

      _initCheckForSupportedWidgets: function () {
        if(this.eLocateEnabled){
          array.forEach(this.map.graphicsLayerIds, lang.hitch(this, function(glId){
            var layer = this.map.getLayer(glId);
            if(layer.name && layer.name.toLowerCase() === "elocate results"){
              this.locateGraphicsLayer = layer;

              on(this.locateGraphicsLayer, 'graphic-add', lang.hitch(this, this.checkeLocateNumGras));
              on(this.locateGraphicsLayer, 'graphic-remove', lang.hitch(this, this.checkeLocateNumGras));
              on(this.locateGraphicsLayer, 'graphic-clear',  lang.hitch(this, this.checkeLocateNumGras));
              this.eLocateGLFound = true;

              //Add the button
              var itemsDiv = dojoQuery('.draw-items', this.drawBox.domNode);
              var eLocateButton = html.create('div', {
                'style': 'display:none;',
                'class': 'draw-item',
                'data-gratype': 'ELOCATE',
                'title': this.nls.eLocateTip
              }, itemsDiv[0]);
              html.addClass(eLocateButton, 'elocate-icon');
              this.own(on(eLocateButton, 'click', lang.hitch(this, this._eLocateButtonOnClick)));

              if(this.locateGraphicsLayer.graphics.length > 0){
                this.checkeLocateNumGras();
              }
            }
          }));
          if(!this.eLocateGLFound){
            this.own(this.mapLayerAddResultEvent = this.map.on('layer-add-result', lang.hitch(this, this.checkForeLocateGL)));
          }
        }
      },

      _initResultFormatString: function () {
        this.list._wrapResults = this.config.resultFormat.wrap || false;
        var tBold = false, tItalic = false, tUnder = false, tColorHex = "#000000";
        var vBold = false, vItalic = false, vUnder = false, vColorHex = "#000000";
        this.resultFormatString = "";
        if(this.config.resultFormat){
          var attribName = '[attribname]';
          tBold = this.config.resultFormat.attTitlesymbol.bold;
          tItalic = this.config.resultFormat.attTitlesymbol.italic;
          tUnder = this.config.resultFormat.attTitlesymbol.underline;
          if(this.config.resultFormat.attTitlesymbol.color){
            tColorHex = new Color(this.config.resultFormat.attTitlesymbol.color).toHex();
          }
          if(tBold){
            attribName = "<strong>" + attribName + "</strong>";
          }
          if(tItalic){
            attribName = "<em>" + attribName + "</em>";
          }
          if(tUnder){
            attribName = "<u>" + attribName + "</u>";
          }
          if(tColorHex){
            attribName = "<font color='" + tColorHex + "'>" + attribName + "</font>";
          }
          var attribValue = '[attribvalue]';
          vBold = this.config.resultFormat.attValuesymbol.bold;
          vItalic = this.config.resultFormat.attValuesymbol.italic;
          vUnder = this.config.resultFormat.attValuesymbol.underline;
          if(this.config.resultFormat.attValuesymbol.color){
            vColorHex = new Color(this.config.resultFormat.attValuesymbol.color).toHex();
          }
          if(vBold){
            attribValue = "<strong>" + attribValue + "</strong>";
          }
          if(vItalic){
            attribValue = "<em>" + attribValue + "</em>";
          }
          if(vUnder){
            attribValue = "<u>" + attribValue + "</u>";
          }
          if(vColorHex){
            attribValue = "<font color='" + vColorHex + "'>" + attribValue + "</font>";
          }
          this.resultFormatString = attribName + ": " + attribValue + '<br>';
        }else{
          this.resultFormatString = '<font><em>[attribname]</em></font>: <font>[attribvalue]</font><br>';
        }
      },

      startup: function(){
        this.inherited(arguments);
        this.fetchData();
        this.list.parentWidget = this;
      },

      onReceiveData: function(name, widgetId, data) {
        if(data.message && data.message === "Deactivate_DrawTool"){
          this.drawBox.deactivate();
        }
      },

      _getFeatureSet: function(){
        var layer = this.currentSearchLayer;
        var featureSet = new FeatureSet();
        featureSet.fields = lang.clone(layer.fields);
        featureSet.features = [].concat(layer.graphics);
        featureSet.geometryType = layer.geometryType;
        featureSet.fieldAliases = {};
        array.forEach(featureSet.fields, lang.hitch(this, function(fieldInfo){
          var fieldName = fieldInfo.name;
          var fieldAlias = fieldInfo.alias || fieldName;
          featureSet.fieldAliases[fieldName] = fieldAlias;
        }));
        return featureSet;
      },

      _onBtnMenuClicked: function(evt){
        var position = html.position(evt.target || evt.srcElement);
        var featureSet = this._getFeatureSet();
		
		// Following block is to set the actions for BG layers
		if(!featureSet.geometryType && this.basicgovLayerSelected)
		{
		  featureSet.geometryType = "esriGeometryPoint";
          featureSet.fields = [];
		}
		
        var layer = this.currentSearchLayer;
        if(!layer.fields){
          layer.fields = [];
        }
        if(!featureSet.geometryType){
          var geomType = "";
          switch(layer.graphics[0].geometry.type){
            case "point":
            case "multipoint":
              geomType = "esriGeometryPoint";
              break;
            case "polygon":
            case "extent":
              geomType = "esriGeometryPolygon";
              break;
            case "polyline":
              geomType = "esriGeometryPolyline";
              break;
          }
          featureSet.geometryType = geomType;
          featureSet.fields = [];
        }
        var layerConfig = this.config.layers[this.currentLayerIndex];
        var noStats = this.getNoStatFieldNames(layerConfig);
        this.featureActionManager.getSupportedActions(featureSet, layer).then(lang.hitch(this, function(actions){
          array.forEach(actions, lang.hitch(this, function(action){
            //console.info(action);
            if(action.name === "eShowStatistics"){
              if(noStats.length > 0){
                var gFlds = array.filter(featureSet.fields, lang.hitch(this, function(field){
                  return noStats.indexOf(field.name) === -1;
                }));
                console.info(gFlds);
                featureSet.fields = gFlds;
              }
              action.data = featureSet;
            }else{
              action.data = featureSet;
            }
          }));

          // if(layerConfig.relates && layerConfig.relates.relate && this.list.getSelectedItem){
          //   var showRelateAction = new BaseFeatureAction({
          //     name: "eShowRelate",
          //     iconClass: 'icon-show-related-record',
          //     label: this.nls._featureAction_eShowRelate,
          //     iconFormat: 'svg',
          //     map: this.map,
          //     onExecute: lang.hitch(this, function(){
          //       this._relateResultItem(0, this.list.getSelectedItem());
          //     })
          //   });
          //   showRelateAction.name = "eShowRelate";
          //   showRelateAction.data = featureSet;
          //   actions.push(showRelateAction);
          // }

          if(!layerConfig.export2Geo){
            actions = array.filter(actions, lang.hitch(this, function(action){
              return action.name !== 'ExportToGeoJSON';
            }));
          }

          if(!layerConfig.export2FC){
            actions = array.filter(actions, lang.hitch(this, function(action){
              return action.name !== 'ExportToFeatureCollection';
            }));
          }

          // filtering out eShowStatistics, ViewInTable, Zoom to, Pan to, Flash for BG
          actions = array.filter(actions, lang.hitch(this, function(action){
            return action.name !== 'CreateLayer' && action.name !== 'ShowStatistics' && action.name !== 'eShowStatistics' && action.name !== 'ExportToCSV' && action.name !== 'ViewInTable' && action.label !== 'Zoom to' && action.label !== 'Pan to' && action.label !== 'Flash';
          }));

          if(layerConfig.export2Csv){
            var exportCSVAction = new BaseFeatureAction({
              name: "eExportToCSV",
              iconClass: 'icon-export',
              label: this.nls._featureAction_eExportToCSV,
              iconFormat: 'svg',
              map: this.map,
              onExecute: lang.hitch(this, function(){
                CSVUtils.exportCSV(this.currentSearchLayer.name, this.currentCSVResults.data, this.currentCSVResults.columns);
              })
            });
            exportCSVAction.name = "eExportToCSV";
            exportCSVAction.data = featureSet;
            actions.push(exportCSVAction);
          }

          if(this.initiator && this.initiator === 'attribute' && this.config.exportsearchurlchecked){
            var exportUrlAction = new BaseFeatureAction({
              name: "exportSearchUrl",
              iconClass: 'icon-export',
              label: this.nls.exporturl,
              iconFormat: 'svg',
              map: this.map,
              onExecute: lang.hitch(this, this.exportURL)
            });
            exportUrlAction.name = "exportSearchUrl";
            exportUrlAction.data = featureSet;
            actions.push(exportUrlAction);
          }

          if(this.graphicsLayerBuffer && this.graphicsLayerBuffer.graphics.length > 0){
            var removeBufferAction = new BaseFeatureAction({
              name: "RemoveBufferResult",
              iconClass: 'icon-close',
              label: this.nls.clearBuffer,
              iconFormat: 'svg',
              map: this.map,
              onExecute: lang.hitch(this, this.clearbuffer)
            });
            removeBufferAction.name = "RemoveBufferResult";
            removeBufferAction.data = featureSet;
            actions.push(removeBufferAction);
          }

          var removeAction = new BaseFeatureAction({
            name: "CleareSearchResult",
            iconClass: 'icon-close',
            label: this.nls.clearResults,
            iconFormat: 'svg',
            map: this.map,
            onExecute: lang.hitch(this, this.clear)
          });
          removeAction.name = "CleareSearchResult";
          removeAction.data = featureSet;
          actions.push(removeAction);

          this.popupMenu.setActions(actions);
          this.popupMenu.show(position);
        }));
      },

      getNoStatFieldNames: function(layerConfig){
        var retval = [];
        array.forEach(layerConfig.fields.field, lang.hitch(this, function(fld){
          if(fld.excludestat){
            retval.push(fld.name);
          }
        }));
        return retval;
      },

      checkForeLocateGL: function (result) {
        if(result.layer.name && result.layer.name.toLowerCase() === "elocate results"){
          this.locateGraphicsLayer = result.layer;
          on(this.locateGraphicsLayer, 'graphic-add', lang.hitch(this, this.checkeLocateNumGras));
          on(this.locateGraphicsLayer, 'graphic-remove', lang.hitch(this, this.checkeLocateNumGras));
          on(this.locateGraphicsLayer, 'graphic-clear',  lang.hitch(this, this.checkeLocateNumGras));
          this.mapLayerAddResultEvent.remove();

          //Add the button
          var itemsDiv = dojoQuery('.draw-items', this.drawBox.domNode);
          var eLocateButton = html.create('div', {
            'style': 'display:none;',
            'class': 'draw-item',
            'data-gratype': 'ELOCATE',
            'title': this.nls.eLocateTip
          }, itemsDiv[0]);
          html.addClass(eLocateButton, 'elocate-icon');
          this.own(on(eLocateButton, 'click', lang.hitch(this, this._eLocateButtonOnClick)));
        }
      },

      checkeLocateNumGras: function (){
        if(this.locateGraphicsLayer){
          var eLocateButton = dojoQuery('.draw-item.elocate-icon', this.drawBox.domNode);
          if(this.locateGraphicsLayer.graphics.length > 0){
            //show the button
            html.setStyle(eLocateButton[0], 'display', 'block');
          }else{
            //hide the button
            html.setStyle(eLocateButton[0], 'display', 'none');
          }
        }
      },

      _eLocateButtonOnClick: function() {
        var graLayGras = this.locateGraphicsLayer.graphics;
        if (graLayGras.length > 1){
          this.processInputs(this.unionGeoms(graLayGras));
        }else if (graLayGras.length == 1){
          this.processInputs(graLayGras[0].geometry);
        }
      },

      processInputs: function (geom) {
        if (geom === Polygon && geom.isSelfIntersecting(geom)){
          esriConfig.defaults.geometryService.simplify([geom], lang.hitch(this, function (result) {
            if (this.cbxBufferGraphic.getValue()) {
				if(this.txtBufferValue.get('value') && this.txtBufferValue.get('value') > 0)
				{
            	  this._bufferGeometries([geom], new SpatialReference({
                    wkid: this.bufferWKID
                  }), [parseFloat(this.txtBufferValue.get('value'))], this.bufferUnits.get('value'), true);
				} else {
          		  new Message({
            		  titleLabel: this.nls.bufferSearchErrorTitle,
            		  message: this.nls.bufferValueError
          		  });
        	    }
            } else {
              this.search(result[0], this.graphicLayerIndex);
            }
          }));
        }else{
          //create extent around map point to improve search results
          if (geom.type === "point" && this.cbxAddTolerance.getValue()) {
            geom = this.pointToExtent(geom, this.pointSearchTolerance);
          }
          if (this.cbxBufferGraphic.getValue()) {
            this._bufferGeometries([geom], new SpatialReference({
              wkid: this.bufferWKID
            }), [parseFloat(this.txtBufferValue.get('value'))], this.bufferUnits.get('value'), true);
          } else {
            this.search(geom, this.graphicLayerIndex);
          }
        }
      },

      _addBufferLayer: function () {
        if (this.config.bufferDefaults.addtolegend) {
          //new a feature layer
          var layerInfo = {
            "type" : "Feature Layer",
            "description" : "",
            "definitionExpression" : "",
            "name": "Search Buffer Results",
            "geometryType": "esriGeometryPolygon",
            "objectIdField": "ObjectID",
            "drawingInfo": {
              "renderer": {
                "type": "simple",
                "label": "Buffer",
                "description" : "Buffer",
                "symbol": this.config.bufferDefaults.simplefillsymbol
              }
            },
            "fields": [{
              "name": "ObjectID",
              "alias": "ObjectID",
              "type": "esriFieldTypeOID"
            }, {
              "name": "bufferdist",
              "alias": "Buffer Distance",
              "type": "esriFieldTypeString"
            }]
          };

          var featureCollection = {
            layerDefinition: layerInfo,
            featureSet: null
          };
          this.graphicsLayerBuffer = new FeatureLayer(featureCollection);
          this.graphicsLayerBuffer.name = "Search Buffer Results";
        } else {
          //use graphics layer
          this.graphicsLayerBuffer = new GraphicsLayer();
          this.graphicsLayerBuffer.name = "Search Buffer Results";
          this.map.addLayer(this.graphicsLayerBuffer);
        }
      },

      closeDDs: function () {
        this.selectLayerAttribute.closeDropDown();
        this.selectLayerGraphical.closeDropDown();
        this.selectExpression.closeDropDown();
        this.selectLayerSpatial.closeDropDown();
		// for BG GIS we will not be using this functionality
        /*this.gSelectType.closeDropDown();
        this.aSelectType.closeDropDown();*/
      },

      onDeactivate: function() {
        this.drawBox.deactivate();
      },

      onClose: function () {
        this.drawBox.deactivate();
        this._hideInfoWindow();
        this.inherited(arguments);
        if (!this.config.bufferDefaults.addtolegend) {
          if (this.graphicsLayerBuffer) {
            this.graphicsLayerBuffer.hide();
          }
        }
        if (this.tempResultLayer) {
          this.tempResultLayer.hide();
        }
      },

      onOpen: function () {
        if (!this.config.bufferDefaults.addtolegend) {
          if (this.graphicsLayerBuffer) {
            this.graphicsLayerBuffer.show();
          }
        }
        if (this.tempResultLayer) {
          this.tempResultLayer.show();
        }
      },

      _resetDrawBox: function () {
        this.drawBox.deactivate();
        this.drawBox.clear();
      },

      destroy: function () {
        this._hideInfoWindow();
        this._resetDrawBox();
        this._removeAllResultLayers();
        this.inherited(arguments);
      },

      _removeAllResultLayers: function () {
        this._hideInfoWindow();
        this._removeTempResultLayer();
        this._removeAllOperatonalLayers();
      },

      _removeAllOperatonalLayers: function () {
        var layers = this.operationalLayers;
        while (layers.length > 0) {
          var layer = layers[0];
          if (layer) {
            this.map.removeLayer(layer);
          }
          layers[0] = null;
          layers.splice(0, 1);
        }
        this.operationalLayers = [];
      },

      _addOperationalLayer: function (resultLayer) {
        this.operationalLayers.push(resultLayer);
        this.map.addLayer(resultLayer);
      },

      _resetAndAddTempResultLayer: function () {
        this._removeTempResultLayer();
        this.tempResultLayer = new GraphicsLayer();
        this.tempResultLayer.name = "Search Results";
        this.tempResultLayer.infoTemplate = new PopupTemplate();
        this.map.addLayer(this.tempResultLayer);
      },

      _removeTempResultLayer: function () {
        if (this.tempResultLayer) {
          this.map.removeLayer(this.tempResultLayer);
        }
        this.tempResultLayer = null;
      },

      onSpatialLayerChange: function (newValue) {
        this.spatialLayerIndex = newValue;
      },

      onGraphicalLayerChange: function (newValue) {
		if(this.config.layers[newValue])
		{
          this.graphicLayerIndex = newValue;
		  if(this.basicgovLayerSelected)
		  {
			this.basicgovLayerSelected = false;
		  }
		}
		else
		{
		  if(!this.basicgovLayerSelected)
		  {
			this.basicgovLayerSelected = true;
		  }
		  
		  var v = this.selectLayerGraphical.get('value');
			var objName = v.split('/')[1];
			for (var lx in this.config.layers) {
				if (this.config.layers[lx].url == objName) {
					this.graphicLayerIndex = lx;
					break;
				}
			}
		}
        //determine if this layer has any expressions
        if(this.config.layers[this.graphicLayerIndex].expressions.expression.length > 0){
          this.cbxAddTextQuery.setStatus(true);
        }else{
          this.cbxAddTextQuery.setStatus(false);
        }
        //determine if this layer has any sum field(s)
        this._getSumFields(this.graphicLayerIndex);
        if(this.sumFields.length > 0){
          html.addClass(this.list.domNode, 'sum');
          html.setStyle(this.divSum, 'display', '');
        }else{
          html.removeClass(this.list.domNode, 'sum');
          html.setStyle(this.divSum, 'display', 'none');
        }
      },

      onAttributeLayerChange: function (newValue) {
		if(this.config.layers[newValue])
		{
          this.AttributeLayerIndex = newValue;
		  if(this.basicgovLayerSelected)
		  {
			this.basicgovLayerSelected = false;
		  }
		}
		else
		{
		  if(!this.basicgovLayerSelected)
		  {
			this.basicgovLayerSelected = true;
		  }
		  
		  var v = this.selectLayerAttribute.get('value');
			var objName = v.split('/')[1];
			for (var lx in this.config.layers) {
				if (this.config.layers[lx].url == objName) {
					this.AttributeLayerIndex = lx;
					break;
				}
			}
		}
		this._initSelectedLayerExpressions();
        var valuesObj = lang.clone(this.config.layers[this.AttributeLayerIndex].expressions.expression[0].values.value);
        html.empty(this.textsearchlabel);
        if(this.config.layers[this.AttributeLayerIndex].expressions.expression[0].textsearchlabel !== ""){
          html.place(html.toDom(this.config.layers[this.AttributeLayerIndex].expressions.expression[0].textsearchlabel), this.textsearchlabel);
          html.style(this.textsearchlabel, 'display', 'block');
        }else{
          html.style(this.textsearchlabel, 'display', 'none');
        }
        this.paramsDijit.clear();
        this.paramsDijit.build(valuesObj, this.resultLayers[this.AttributeLayerIndex], this.config.layers[this.AttributeLayerIndex].url,
                             this.config.layers[this.AttributeLayerIndex].definitionexpression);
        this.paramsDijit.setFocusOnFirstParam();
        this.expressIndex = 0;
        //set the graphical layer to be the same // not required for BG
        //this.graphicLayerIndex = this.AttributeLayerIndex;
        //this.selectLayerGraphical.set('value', this.AttributeLayerIndex);
        //determine if this layer has any sum field(s)
        this._getSumFields(this.AttributeLayerIndex);
        if(this.sumFields.length > 0){
          html.addClass(this.list.domNode, 'sum');
          html.setStyle(this.divSum, 'display', '');
        }else{
          html.removeClass(this.list.domNode, 'sum');
          html.setStyle(this.divSum, 'display', 'none');
        }
      },

      onAttributeLayerExpressionChange: function (newValue) {
        this.expressIndex = newValue;
        var valuesObj = lang.clone(this.config.layers[this.AttributeLayerIndex].expressions.expression[newValue].values.value);
        html.empty(this.textsearchlabel);
        if(this.config.layers[this.AttributeLayerIndex].expressions.expression[newValue].textsearchlabel !== ""){
          html.place(html.toDom(this.config.layers[this.AttributeLayerIndex].expressions.expression[newValue].textsearchlabel), this.textsearchlabel);
          html.style(this.textsearchlabel, 'display', 'block');
        }else{
          html.style(this.textsearchlabel, 'display', 'none');
        }
        this.paramsDijit.clear();
        this.paramsDijit.build(valuesObj, this.resultLayers[this.AttributeLayerIndex], this.config.layers[this.AttributeLayerIndex].url,
                               this.config.layers[this.AttributeLayerIndex].definitionexpression);
        this.paramsDijit.setFocusOnFirstParam();
      },

      _initBufferUnits: function () {
        if(this.config.bufferDefaults.maxBufferValue){
          this.txtBufferValue.constraints.max = this.config.bufferDefaults.maxBufferValue;
          this.txtBufferValueSpat.constraints.max = this.config.bufferDefaults.maxBufferValue;
        }

        var options = [];
        var len = this.config.bufferDefaults.bufferUnits.bufferUnit.length;
        for (var i = 0; i < len; i++) {
          var option = {
            value: this.config.bufferDefaults.bufferUnits.bufferUnit[i].name,
            label: this.config.bufferDefaults.bufferUnits.bufferUnit[i].label
          };
          options.push(option);
          if (i === 0) {
            options[i].selected = true;
          }
        }
        this.bufferUnits.addOption(options);
        this.bufferUnitsSpat.addOption(options);
      },

      _initSpatialRelationships: function () {
        var len = this.config.spatialrelationships.spatialrelationship.length;
        for (var i = 0; i < len; i++) {
          var iClass = this._getSpatialIconClass(this.config.spatialrelationships.spatialrelationship[i].name);
          var spatButton = html.create('div', {
            'class': 'spatial-item',
            'data-spatialtype': this.config.spatialrelationships.spatialrelationship[i].name,
            'title': this.config.spatialrelationships.spatialrelationship[i].label
          }, this.spatialItems);
          html.addClass(spatButton, iClass);
          this.own(on(spatButton, 'click', lang.hitch(this, this._spatButtonOnClick)));
        }
      },

      _spatButtonOnClick: function (event) {
        event.stopPropagation();
        this._intersectResults(event.target.getAttribute('data-spatialtype'));
      },

      _intersectResults: function (dataSpatialType) {
        this.garr = [];
        var intersectGeom;
        if (this.graphicsLayerBuffer && this.graphicsLayerBuffer.graphics.length > 0 && this.currentLayerAdded && this.currentLayerAdded.graphics.length > 0) {
          var qMessage = new Message({
            type: 'question',
            titleLabel: this.nls.spatialchoicetitle,
            message: this.nls.spatialchoicemsg,
            buttons: [{
              label: this.nls.buffergraphics,
              onClick: lang.hitch(this, lang.hitch(this, function () {
                qMessage.close();
                var g = this.graphicsLayerBuffer.graphics[0];
                intersectGeom = g.geometry;
                this.search(intersectGeom, this.spatialLayerIndex, null, null, dataSpatialType);
              }))
            }, {
              label: this.nls.selectiongraphics,
              onClick: lang.hitch(this, lang.hitch(this, function () {
                qMessage.close();
                intersectGeom = this.unionGeoms(this.currentLayerAdded.graphics);
                this.search(intersectGeom, this.spatialLayerIndex, null, null, dataSpatialType);
              }))
            }]
          });
          return;
        }
        var gra;
        if (this.graphicsLayerBuffer && this.graphicsLayerBuffer.graphics.length > 0) {
          gra = this.graphicsLayerBuffer.graphics[0];
          intersectGeom = gra.geometry;
//          console.info("spatial layer index: " + this.spatialLayerIndex);
          this.search(intersectGeom, this.spatialLayerIndex, null, null, dataSpatialType);
        } else if (this.currentLayerAdded && this.currentLayerAdded.graphics.length > 0) {
          intersectGeom = this.unionGeoms(this.currentLayerAdded.graphics);
          if (intersectGeom === Polygon && (intersectGeom.isSelfIntersecting(intersectGeom) || intersectGeom.rings.length > 1)) {
            esriConfig.defaults.geometryService.simplify([intersectGeom], lang.hitch(this,
              function (result) {
//                console.info("spatial layer index: " + this.spatialLayerIndex);
                this.search(result[0], this.spatialLayerIndex, null, null, dataSpatialType);
              }));
          } else {
//            console.info("spatial layer index: " + this.spatialLayerIndex);
            this.search(intersectGeom, this.spatialLayerIndex, null, null, dataSpatialType);
          }
        } else {
          new Message({
            titleLabel: this.nls.spatialSearchErrorTitle,
            message: this.nls.intersectMessage
          });
        }
      },

      _getSpatialIconClass: function (spatRel) {
        var iClass;
        switch (spatRel) {
        case 'esriSpatialRelContains':
          iClass = 'contain-icon';
          break;
        case 'esriSpatialRelIntersects':
          iClass = 'intersect-icon';
          break;
        case 'esriSpatialRelEnvelopeIntersects':
          iClass = 'envintersects-icon';
          break;
        case 'esriSpatialRelCrosses':
          iClass = 'crosses-icon';
          break;
        case 'esriSpatialRelIndexIntersects':
          iClass = 'indexintersects-icon';
          break;
        case 'esriSpatialRelOverlaps':
          iClass = 'overlaps-icon';
          break;
        case 'esriSpatialRelTouches':
          iClass = 'touches-icon';
          break;
        case 'esriSpatialRelWithin':
          iClass = 'within-icon';
          break;
        default:
          iClass = 'contain-icon';
        }
        return iClass;
      },

      _combineRadioCheckBoxWithLabel: function () {
        this.own(on(this.bufferGraphicLabel, 'click', lang.hitch(this, function () {
          this.cbxBufferGraphic.setValue(!this.cbxBufferGraphic.getValue());
        })));
        this.own(on(this.multiGraphicLabel, 'click', lang.hitch(this, function () {
          this.cbxMultiGraphic.setValue(!this.cbxMultiGraphic.getValue());
        })));
      },

      _initTabContainer: function () {
        if (this.config.hasOwnProperty('disabledtabs')) {
          this.disabledTabs = this.config.disabledtabs;
        } else {
          this.disabledTabs = [];
        }
        this.limitMapExtentCbx.setValue(this.config.limitsearch2mapextentchecked || false);
        this.eLocateEnabled = this.config.graphicalsearchoptions.enableeLocateselect || false;
        this.txtBufferValue.set('value', this.config.bufferDefaults.bufferDefaultValue || 0);
        this.txtBufferValueSpat.set('value', this.config.bufferDefaults.bufferDefaultValue || 0);
        this.bufferWKID = this.config.bufferDefaults.bufferWKID;
        this.keepgraphicalsearchenabled = this.config.graphicalsearchoptions.keepgraphicalsearchenabled || false;
        this.autozoomtoresults = this.config.autozoomtoresults || false;
        this.mouseovergraphics = this.config.mouseovergraphics || false;
        var initView = this.config.initialView || "text";
        this.pointSearchTolerance = this.config.graphicalsearchoptions.toleranceforpointgraphicalselection || 6;
        this.cbxAddTolerance.setValue(this.config.graphicalsearchoptions.addpointtolerancechecked || false);
        this.cbxMultiGraphic.setValue(this.config.graphicalsearchoptions.multipartgraphicsearchchecked || false);
        this.cbxBufferGraphic.setValue(false);
        if (this.config.graphicalsearchoptions.showmultigraphicsgraphicaloption) {
          html.setStyle(this.multiGraDiv, 'display', '');
        } else {
          html.setStyle(this.multiGraDiv, 'display', 'none');
        }
        if (this.config.graphicalsearchoptions.showaddtolerancegraphicaloption) {
          html.setStyle(this.addToleranceDiv, 'display', '');
        } else {
          html.setStyle(this.addToleranceDiv, 'display', 'none');
        }
        if (this.config.graphicalsearchoptions.showaddsqltextgraphicaloption) {
          html.setStyle(this.addSqlTextDiv, 'display', '');
        } else {
          html.setStyle(this.addSqlTextDiv, 'display', 'none');
        }
        if (this.config.graphicalsearchoptions.showbuffergraphicaloption) {
          html.setStyle(this.bufferGraDiv, 'display', '');
        } else {
          html.setStyle(this.bufferGraDiv, 'display', 'none');
        }
        this.cbxBufferGraphic.setValue(this.config.graphicalsearchoptions.buffercheckedbydefaultgraphicaloption);

        this.cbxMultiGraphic.onChange = lang.hitch(this, this._onCbxMultiGraphicClicked);

        array.map(this.disabledTabs, lang.hitch(this, function (dTab) {
          if (dTab === 'graphic') {
            this.shapeTab = false;
          }
          if (dTab === 'text') {
            this.attribTab = false;
          }
          if (dTab === 'spatial') {
            this.spatTab = false;
          }
          if (dTab === 'result') {
            this.rsltsTab = false;
          }
        }));

        //determine if this layer has any expressions
        if(this.config.layers[0].expressions.expression.length > 0){
          this.cbxAddTextQuery.setStatus(true);
        }else{
          this.cbxAddTextQuery.setStatus(false);
        }

        if (this.cbxMultiGraphic.getValue()) {
          html.setStyle(this.btnGraSearch, 'display', 'inline-block');
        } else {
          html.setStyle(this.btnGraSearch, 'display', 'none');
        }
        var len = this.config.layers.length;
        if (initView === "text" && this.attribTab) {
          this.selTab = this.nls.selectByAttribute;
        } else if (initView === "graphical" && this.shapeTab) {
          this.selTab = this.nls.selectFeatures;
          if(this.autoactivatedtool){
            this.drawBox.activate(this.autoactivatedtool.toUpperCase());
          }
        }
        var tabs = [];
        if (this.shapeTab) {
          tabs.push({
            title: this.nls.selectFeatures,
            content: this.tabNode1
          });
          html.replaceClass(this.tabNode1, 'search-tab-node', 'search-tab-node-hidden');
        }
        if (this.attribTab) {
          for (var a = 0; a < len; a++) {
            if (this.config.layers[a].expressions.expression.length > 0) {
              tabs.push({
                title: this.nls.selectByAttribute,
                content: this.tabNode2
              });
              html.replaceClass(this.tabNode2, 'search-tab-node', 'search-tab-node-hidden');
              break;
            }
          }
        }
        if (this.spatTab) {
          for (var i = 0; i < len; i++) {
            if (this.config.layers[i].spatialsearchlayer) {
              tabs.push({
                title: this.nls.selectSpatial,
                content: this.tabNode3
              });
              html.replaceClass(this.tabNode3, 'search-tab-node', 'search-tab-node-hidden');
              break;
            }
          }
        }
        if (this.rsltsTab) {
          tabs.push({
            title: this.nls.results,
            content: this.tabNode4
          });
          html.replaceClass(this.tabNode4, 'search-tab-node', 'search-tab-node-hidden');
        }
        this.tabContainer = new TabContainer({
          tabs: tabs,
          selected: this.selTab
        }, this.tabSearch);

        this.tabContainer.startup();
        this.own(on(this.tabContainer, "tabChanged", lang.hitch(this, function (title) {
          if (title !== this.nls.results) {
            this.selTab = title;
          }
          if(title === this.nls.selectFeatures) {
            if(this.autoactivatedtool){
              this.drawBox.activate(this.autoactivatedtool.toUpperCase());
            }
          }else{
            if (title === this.nls.selectByAttribute || title === this.nls.selectSpatial) {
              this.drawBox.deactivate();
            }else if(title === this.nls.results && !this.keepgraphicalsearchenabled) {
              this.drawBox.deactivate();
            }
          }
        })));
        jimuUtils.setVerticalCenter(this.tabContainer.domNode);
      },

      _getSumFields: function(index) {
        this.sumFields = [];
        array.map(this.config.layers[index].fields.field, lang.hitch(this,function(field){
          if(field.sumfield){
            this.sumFields.push({field: field.name, sumlabel: field.sumlabel});
          }
        }));
      },

      _initLayerSelect: function () {
        this.serviceFailureNames = [];
        if(!this.currentFeatures){
          this.currentFeatures = [];
        }
        var options = [];
        var spatialOptions = [];
        var attribOptions = [];
        var len = this.config.layers.length;
        var objectNames = [];
        for (var i = 0; i < len; i++) {
			if(this.config.layers[i].type != 'basicgov'){
				var option = {
					value: i,
					label: this.config.layers[i].name
				};
				options.push(option);
				if (this.config.layers[i].spatialsearchlayer) {
					spatialOptions.push(option);
				}
				if(this.config.layers[i].expressions.expression.length > 0){
					attribOptions.push(option);
				}
        this.featureLayersString += "<option value=\"" + this.config.layers[i].url + "\">" + this.config.layers[i].name + "</option>";
			} else{
				// objectNames will be used to get ListViews further down
				// then on callback the dropdown is populated
				objectNames.push(this.config.layers[i].url);
			}
        }
        //select the first layer in the lists
        if (options.length > 0) {
          options[0].selected = true;
        }
        if (spatialOptions.length > 0) {
          spatialOptions[0].selected = true;
        }
        if (attribOptions.length > 0) {
          attribOptions[0].selected = true;
        }else{
          html.setStyle(this.addSqlTextDiv, 'display', 'none');
        }

        if (len > 0) {
		  this.paramsDijit = new Parameters({
            nls: this.nls,
            layerUniqueCache: this.layerUniqueCache,
            disableuvcache: this.config.disableuvcache,
            selectFilterType: this.config.selectfilter
          });
          this.paramsDijit.placeAt(this.parametersDiv);
          this.paramsDijit.startup();
          this.paramsDijit.on('enter-pressed', lang.hitch(this, function () {
            this.search(null, this.AttributeLayerIndex, this.expressIndex);
          }));
          this.shelter.show();

          var defs = array.map(this.config.layers, lang.hitch(this, function (layerConfig) {
			  if(layerConfig.type != 'basicgov'){
				return this._getLayerInfoWithRelationships(layerConfig.url);
			  }
          }));

          all(defs).then(lang.hitch(this, function (results) {
            //this.shelter.hide();
            array.forEach(results, lang.hitch(this, function (result, j) {
			  if(result)
			  {
				if(result.state === 'success'){
				  var layerInfo = result.value;
				  console.info(layerInfo);
				  var layerConfig = this.config.layers[j];

				  if (layerInfo.objectIdField) {
				    layerConfig.objectIdField = layerInfo.objectIdField;
				  } else {
				    var fields = layerInfo.fields;
				    var oidFieldInfos = array.filter(fields, lang.hitch(this, function (fieldInfo) {
					  return fieldInfo.type === 'esriFieldTypeOID';
				    }));
				    if (oidFieldInfos.length > 0) {
					  var oidFieldInfo = oidFieldInfos[0];
					  layerConfig.objectIdField = oidFieldInfo.name;
				    }
				  }
				  layerConfig.existObjectId = array.some(layerConfig.fields.field, lang.hitch(this, function (element) {
				    return element.name === layerConfig.objectIdField;
				   }));
				  layerConfig.typeIdField = layerInfo.typeIdField;
				  //ImageServiceLayer doesn't have drawingInfo
				  if (!layerInfo.drawingInfo) {
				    layerInfo.drawingInfo = {};
				  }
				  layerInfo.name = this.nls.search + ' ' + this.nls.results + ': ' + layerConfig.name;
				  layerInfo._titleForLegend = layerInfo.name;
				  layerInfo.minScale = 0;
				  layerInfo.maxScale = 0;
				  layerInfo.effectiveMinScale = 0;
				  layerInfo.effectiveMaxScale = 0;
				  layerInfo.defaultVisibility = true;
				  this.resultLayers.push(layerInfo);
			    }else{
				  //remove this layer from the options list
				  var oIndex = -1;
				  array.some(options, lang.hitch(this, function(option,o){
				    if(option.label === this.config.layers[j].name){
					  oIndex = o;
					  return true;
				    }
				    return false;
				  }));
				  options.splice(oIndex, 1);
				  if (this.config.layers[j].spatialsearchlayer) {
				    spatialOptions.splice(spatialOptions.indexOf(this.config.layers[j].spatialsearchlayer), 1);
				  }
				  this.serviceFailureNames.push(this.config.layers[j].name);
				  this.resultLayers.push({});
			    }
			  }
            }));

            this.selectLayerGraphical.addOption(options);
            this.selectLayerAttribute.addOption(attribOptions);
            this.selectLayerSpatial.addOption(spatialOptions);
            if(spatialOptions.length > 0){
              this.spatialLayerIndex = spatialOptions[0].value;
            }
			
			//Add BGLayers into the SelectLayer1 for now
		    this.bgManager = new BGManager();
		    if(objectNames.length > 0)
		    {		
				this.bgManager.getListViewsSearch(objectNames);		
			}		
			else		
			{		
				this.shelter.hide();		
			}
			
			//now check if there is a url search to do
            var myObject = this.getUrlParams();
			
			//if there are url params in VF page then the  zoomParcelName & zoomLayerName will be set in the VF page
			if(zoomParcelName != '' && zoomLayerName != '')
			  {
				myObject.esearch = zoomParcelName;					//gisSearchValue support for Url params feature
				for(var i = 0; i<this.config.layers.length; i++)
				{
					if(this.config.layers[i].name == zoomLayerName)
					{
						myObject.slayer = i;						//gisLayerName support for Url params feature
						break;
					}
				}
			  }
			
            if (myObject.esearch) {
              if(myObject.esearch === "last48"){
                var today = new Date();
                var priorDate = new Date(today.getTime() - (((24 * 60 * 60 * 1000) - 1000) * 2));
                var priorDateStr = this._formatDate(priorDate.getTime(), 'yyyy/MM/dd');
                myObject.esearch = priorDateStr + "~" + this._formatDate(new Date().getTime(), 'yyyy/MM/dd');
              }
              if(myObject.esearch === "thismonth"){
                var today = new Date();
                today.setDate(1);
                var thisMonthStr = this._formatDate(today.getTime(), 'yyyy/MM/dd');
                myObject.esearch = thisMonthStr + "~" + this._formatDate(new Date().getTime(), 'yyyy/MM/dd');
              }
              if(myObject.esearch === "thisyear"){
                var today = new Date();
                today.setMonth(0,1);
                var thisMonthStr = this._formatDate(today.getTime(), 'yyyy/MM/dd');
                myObject.esearch = thisMonthStr + "~" + this._formatDate(new Date().getTime(), 'yyyy/MM/dd');
              }
			  
              if(this.config.layers[myObject.slayer].expressions.expression.length > 0){
                var valuesObj1 = lang.clone(this.config.layers[myObject.slayer].expressions.expression[myObject.exprnum || 0].values.value);
                var values = myObject.esearch.split("|");
                array.forEach(values, lang.hitch(this, function(val, index){
                  if (val.indexOf('~') > -1){
                    var ranges = val.split("~");
                    valuesObj1[index].valueObj.value1 = ranges[0];
                    valuesObj1[index].valueObj.value2 = ranges[1];
                  }else{
                    valuesObj1[index].valueObj.value = val;
                  }
                }));
                html.empty(this.textsearchlabel);
                if(this.config.layers[myObject.slayer].expressions.expression[myObject.exprnum || 0].textsearchlabel !== ""){
                  html.place(html.toDom(this.config.layers[myObject.slayer].expressions.expression[myObject.exprnum || 0].textsearchlabel), this.textsearchlabel);
                  html.style(this.textsearchlabel, 'display', 'block');
                }else{
                  html.style(this.textsearchlabel, 'display', 'none');
                }
                console.info(valuesObj1);
                this.paramsDijit.build(valuesObj1, this.resultLayers[myObject.slayer], this.config.layers[myObject.slayer].url,
                                     this.config.layers[myObject.slayer].definitionexpression);
                on.once(this.paramsDijit, 'param-ready', lang.hitch(this, function () {
                  this._queryFromURL(myObject.esearch, myObject.slayer, myObject.exprnum || 0, myObject.close || false);
                }));
              }
              /*this.publishData({
                message: myObject.slayer
              });*/
            } else {
              //init the first available attrib layers paramsDijit
              if(attribOptions.length > 0){
                var aIndex = attribOptions[0].value;
                this.AttributeLayerIndex = aIndex;
                this._initSelectedLayerExpressions();
                if(this.config.layers[aIndex].expressions.expression.length > 0){
                  var valuesObj = lang.clone(this.config.layers[aIndex].expressions.expression[0].values.value);
                  html.empty(this.textsearchlabel);
                  if(this.config.layers[aIndex].expressions.expression[0].textsearchlabel !== ""){
                    html.place(html.toDom(this.config.layers[aIndex].expressions.expression[0].textsearchlabel), this.textsearchlabel);
                    html.style(this.textsearchlabel, 'display', 'block');
                  }else{
                    html.style(this.textsearchlabel, 'display', 'none');
                  }
                  this.paramsDijit.build(valuesObj, this.resultLayers[aIndex], this.config.layers[aIndex].url,
                                       this.config.layers[aIndex].definitionexpression);
                  on.once(this.paramsDijit, 'param-ready', lang.hitch(this, function () {
                    this.paramsDijit.setFocusOnFirstParam();
                  }));
                }
                //determine if this layer has any sum field(s)
                this._getSumFields(aIndex);
                if(this.sumFields.length > 0){
                  html.addClass(this.list.domNode, 'sum');
                  html.setStyle(this.divSum, 'display', '');
                }else{
                  html.removeClass(this.list.domNode, 'sum');
                  html.setStyle(this.divSum, 'display', 'none');
                }
              }
            }

            if(this.serviceFailureNames.length > 0){
              console.info("service failed", this.serviceFailureNames);
              new Message({
                titleLabel: this.nls.mapServiceFailureTitle,
                message: this.nls.mapServicefailureMsg + this.serviceFailureNames.join(", ") + this.nls.mapServicefailureMsg2
              });
            }
          }), lang.hitch(this, function (err) {
            this.shelter.hide();
            this.selectLayerGraphical.addOption(options);
            this.selectLayerAttribute.addOption(options);
            this.selectLayerSpatial.addOption(spatialOptions);
            console.error(err);
            for (var j = 0; j < this.config.layers.length; j++) {
              var layer = new GraphicsLayer();
              this.resultLayers.push(layer);
            }
          }));
        }
        this.own(on(this.selectLayerGraphical, "change", lang.hitch(this, this.onGraphicalLayerChange)));
        this.own(on(this.selectLayerAttribute, "change", lang.hitch(this, this.onAttributeLayerChange)));
        this.own(on(this.selectLayerSpatial, "change", lang.hitch(this, this.onSpatialLayerChange)));
        this.own(on(this.selectExpression, "change", lang.hitch(this, this.onAttributeLayerExpressionChange)));
        this.own(on(this.list, 'remove', lang.hitch(this, this._removeResultItem)));
      },
	  
	  _addBGLayersToLayerSelect:function(lvs){
		var bgLayersOptions = [];
		for(var i = 0; i < lvs.length; i++){
			var listViews = lvs[i].listViews;
			for(var j = 0; j < listViews.length; j++){
				var bgOption = {
					label: lvs[i].objectLabel+' - '+listViews[j],
					value: 'basicgov/'+lvs[i].objectName+'/'+listViews[j]
				}
				bgLayersOptions.push(bgOption);
				this.bgLayersString += "<option value=\"basicgov/" + lvs[i].objectName+'/'+listViews[j] + "\">" + lvs[i].objectLabel +' - '+listViews[j]+ "</option>";
			}
		}
		this.selectLayerGraphical.addOption(bgLayersOptions);
		this.selectLayerAttribute.addOption(bgLayersOptions);
		for(var i = 0; i< this.config.layers.length; i++)
		{
			if(this.config.layers[i].type == 'basicgov')
			{
				var bgLayerInfo = {
					url : this.config.layers[i].url,
					fields : this.config.layers[i].fields.field
				}
				this.resultLayers.push(bgLayerInfo); //TODO: have to find out what should be in layerInfo so that we can create the same object to add here
			}
		}
		
		/* Removing Assign to BG User functionality. To put back in, uncomment out this block and the getBGUsers() function below and remove everything below this.bgManager.getAllUsersSearch() call				
        //get all BG users for assign purpose
        this.bgManager.getAllUsersSearch();
        */		
        this.shelter.hide();		
        //BG if zoomOnLoad is true, zoom to parcel or point		
        //TODO: find out if this can be achieved as part of _queryFromUrl()		
        if(zoomOnLoad == 'true' && zoomParcelName != '')		
        {		
			//Set the search text here. MAKE SURE the Parcel layer is in index 0 if there is no zoomLayerName set through url param (gisLayerName)		
			//TODO: find out if this can be achieved as part of _queryFromUrl(), if yes then we should remove this block		
			/*this.inputSearchName.value = zoomParcelName;  		
			var zoomLayerIndex = 0;		
			if(zoomLayerName != '')		
			{		
				for(var i = 0; i<this.config.layers.length; i++)		
				{		
					if(this.config.layers[i].name == zoomLayerName)		
					{			
						zoomLayerIndex = i;		
						break;		
					}		
				}		
			}		
			this.search(null, zoomLayerIndex , null, null, null);*/		
		} else if(zoomOnLoad == 'true' && zoomObjects != null && zoomLayerName != null)		
		{		
			console.debug('************** Print Zoom Object');		
			console.dir(zoomObjects);		
			this.tabContainer.selectTab(this.nls.results);		
			html.setStyle(this.progressBar.domNode,'display','block');		
			html.setStyle(this.divOptions,'display','none');		
			for(var i = 0; i<this.config.layers.length; i++)		
			{		
				if(zoomLayerName == this.config.layers[i].url)		
					this.currentLayerIndex = i;		
			}		
			this.currentSearchLayer = this._createSearchResultLayer(this.currentLayerIndex || 0);		
			if(!this.basicgovLayerSelected)		
			{		
				this.basicgovLayerSelected = true;		
			}		
			this._onBGSearchFinish(zoomObjects);		
		}

	  },
	  
	  /*getBGUsers: function(results) {
		//console.debug('***** All users');
		//console.dir(results);
		for(var i = 0; i< results.length; i++)
		{							
			this.bgAllUsersString += "<option value=\"" + results[i].Id + "\">" + results[i].Name + "</option>";
		}
		//console.debug(this.bgAllUsersString);
		this.shelter.hide();
		//BG if zoomOnLoad is true, zoom to parcel or point
		//TODO: find out if this can be achieved as part of _queryFromUrl()
		if(zoomOnLoad == 'true' && zoomParcelName != '')
		{
			//Set the search text here. MAKE SURE the Parcel layer is in index 0 if there is no zoomLayerName set through url param (gisLayerName)
			//TODO: find out if this can be achieved as part of _queryFromUrl(), if yes then we should remove this block
			//this.inputSearchName.value = zoomParcelName;  
			//var zoomLayerIndex = 0;
			//if(zoomLayerName != '')
			//{
				//for(var i = 0; i<this.config.layers.length; i++)
				//{
					//if(this.config.layers[i].name == zoomLayerName)
					//{
						//zoomLayerIndex = i;
						//break;
					//}
				//}
			//}
			//this.search(null, zoomLayerIndex , null, null, null);
		} else if(zoomOnLoad == 'true' && zoomObjects != null && zoomLayerName != null)
		{
			console.debug('************** Print Zoom Object');
			console.dir(zoomObjects);
			this.tabContainer.selectTab(this.nls.results);
			html.setStyle(this.progressBar.domNode,'display','block');
			html.setStyle(this.divOptions,'display','none');
			for(var i = 0; i<this.config.layers.length; i++)
			{
				if(zoomLayerName == this.config.layers[i].url)
					this.currentLayerIndex = i;
			}
			this.currentSearchLayer = this._createSearchResultLayer(this.currentLayerIndex || 0);
			if(!this.basicgovLayerSelected)
			{
				this.basicgovLayerSelected = true;
			}
			this._onBGSearchFinish(zoomObjects);
		}
	  },*/
	  
	  /** getListViewResults() finished. Do the projection of Points from Standard spatial reference to base map's spatial reference here. **/
	  _onBGSearchFinish: function(resultsToProject){
		var bgError = this._isBGError(resultsToProject);
		if(bgError == true)
		{
			this.clear();
			html.setStyle(this.progressBar.domNode,'display','none');
			html.setStyle(this.divResultMessage,'display','block');
			//html.setStyle(this.divOptions,'display','block');
			return;
		}
		
		if(zoomOnLoad == 'true' && zoomObjects != null && zoomObjects[0].indexOf('bgDefaultObjectToZoom') > -1)
		{
			// incase of zoomObjects only the Name is returned
			this.bgFields = [{
				"datatype":'STRING',
				"label":'Number',
				"path":'Name'
			}];
		}
		else
		{
			this.bgFields = resultsToProject.splice(1, 1)[0]; // remove fields from resultsToProject and store separately
		}
		if(resultsToProject.length > 1){
			var points = [];
			console.log(this.bgFields);
			var standardSpatialReference = new esri.SpatialReference({wkid: 4326});
			for (var i = 1; i < resultsToProject.length; i++){
				var po = new Point(resultsToProject[i].lon, resultsToProject[i].lat, standardSpatialReference);
				points.push(po);
			}
			var params = new esri.tasks.ProjectParameters();
			params.geometries = points;
			params.outSR = this.map.spatialReference;
			esriConfig.defaults.geometryService.project(params, lang.hitch(this, this._filterRawResults, resultsToProject));
		} else {
			this._filterRawResults(resultsToProject, null);
		}
	  },
	  
	  /**   Now filter the results for circle searches.  **/
	  _filterRawResults: function(rawResults, projectedPts) {
		//Need to replace the lon, lat in the results with projected x, y
		if(projectedPts != null && rawResults.length > 1)
		{
			for(var i = 1;  i < rawResults.length; i++){
				rawResults[i].lon = projectedPts[i -1].x;
				rawResults[i].lat = projectedPts[i -1].y;
			}
		}
	    var resultCircleLayer = this.circleLayer;
	    //Filter the results if user use circle search on BG layers. reset the circle
		var results = [];
		if(this.geometryForBGRegularSearch && this.geometryForBGRegularSearch.type == 'polygon'){
			console.debug('*** BG Circle Search.');
			results.push(rawResults[0]);
			for(var i = 1; i < rawResults.length; i++){
				var p = new Point(rawResults[i].lon, rawResults[i].lat, this.map.spatialReference); 
				if(this.geometryForBGRegularSearch.contains(p) == true){
					console.debug('*** Results added ' + i);
					results.push(rawResults[i]);
				}
			}
		} else {
			results = rawResults;
		}
		console.debug('*** Results...');
		console.dir(results);
		
		this._drawBGResults(results);
		if(resultCircleLayer && this.isBufferSearch){
			this.map.addLayer(resultCircleLayer);
		}
	  },

      _relateResultItem: function(index, item) {
        var layerConfig = this.config.layers[this.currentLayerIndex];
        var oidField = layerConfig.objectIdField;
        var sResult = item;
        //console.info(sResult);
        //console.info(this.currentSearchLayer.relationships);
        var relArray = [];
        for(var r=0; r < layerConfig.relates.relate.length; r++){
          var relRslt = {
            id: layerConfig.relates.relate[r].id,
            name: layerConfig.relates.relate[r].label,
            fields: layerConfig.relates.relate[r].fields,
            oid: sResult.graphic.attributes[oidField],
            icon: layerConfig.relates.relate[r].icon
          };
          relArray.push(relRslt);
        }

        if (this.wManager) {
          var widgetCfg = this._getWidgetConfig('AttributeTable');
          if(widgetCfg){
            var attWidget = this.wManager.getWidgetByLabel(widgetCfg.label);
            if(attWidget){
              this.attTableOpenedbySearch = !attWidget.showing;
              this.wManager.openWidget(attWidget);
              if(relArray.length === 1){
                var relQuery = new RelationshipQuery();
                relQuery.outSpatialReference = this.map.spatialReference;
                relQuery.outFields = ["*"];
                relQuery.relationshipId = relArray[0].id;
                relQuery.objectIds = [relArray[0].oid];
                var queryTask = new QueryTask(layerConfig.url);
                queryTask.executeRelationshipQuery(relQuery, lang.hitch(this, this._onRelSearchFinish));
              }else{
                new RelateChooser({
                  relatesArr: relArray,
                  height: 400,
                  titleLabel: this.nls.chooserelate,
                  folderurl: this.folderUrl
                });
              }
            }
          }
        }
      },

      _onRelSearchFinish: function (result) {
        console.info(result);
      },

      _removeResultItem: function (index, item) {
        //console.info(item);

        if (this.currentCSVResults) {
          array.some(this.currentCSVResults.data, lang.hitch(this, function(csvRow){
            if(csvRow.OID === item.OID){
              this.currentCSVResults.data.splice(this.currentCSVResults.data.indexOf(csvRow), 1);
              return true;
            }
            return false;
          }));
        }

        var sResult = item;
        var layerConfig;
        if (item.bgid) {
          layerConfig = this.config.layers.find(function(l){
            return (item.bgid.includes(l.url));
          });
        } else {
          layerConfig = this.config.layers[this.currentLayerIndex];
        }

        var numFeaturesLeft;
        if (this.currentFeatures.length > 0) {
          this.currentFeatures.splice(this.currentFeatures.indexOf(sResult.graphic), 1);
          numFeaturesLeft = this.currentFeatures.length;
        } else {
          // bgSearch isn't using this.currentFeatures so using a Workaround
          var resultMsg = this.divResultMessage.innerText; // resultMsg is Features Selected: numFeatures
          var colonIndex = resultMsg.lastIndexOf(":");
          var num = parseInt(resultMsg.slice(colonIndex + 2));
          numFeaturesLeft = num -1;
        }
        if(numFeaturesLeft === 0){
            this.clear();
            if (this.isSelTabVisible()) {
              this.tabContainer.selectTab(this.selTab);
            }
            return;
          }
      
        if (item.bgid) {
          var bgLayer = this.map.getLayer(item.bgid);
          bgLayer.remove(sResult.graphic);
          bgLayer.refresh();
        } else {
          this.currentSearchLayer.remove(sResult.graphic);
          this.currentSearchLayer.refresh();
          html.empty(this.divResultMessage);
          html.place(html.toDom("<label>" + this.nls.featuresSelected + numFeaturesLeft + "</label>"), this.divResultMessage);
        }


        this.list.remove(index);
        this._hideInfoWindow();
        if (layerConfig.shareResult && layerConfig.addToAttrib && !item.bgid) { // bgSearch not using attribute table
          if (this.wManager) {
            var widgetCfg = this._getWidgetConfig('AttributeTable');
            if(widgetCfg){
              var attWidget = this.wManager.getWidgetByLabel(widgetCfg.label);
              if(attWidget){
                this.attTableOpenedbySearch = !attWidget.showing;
                this.wManager.openWidget(attWidget);
                attWidget._activeTable.refresh();
              }
            }
          }
        }
      },

      _getServiceUrlByLayerUrl: function (layerUrl) {
        var lastIndex = layerUrl.lastIndexOf("/");
        var serviceUrl = layerUrl.slice(0, lastIndex);
        return serviceUrl;
      },

      _isServiceSupportsOrderBy: function(layerInfo){
        var isSupport = false;
        if(layerInfo.advancedQueryCapabilities){
          if(layerInfo.advancedQueryCapabilities.supportsOrderBy){
            isSupport = true;
          }
        }
        return isSupport;
      },

      _getLayerInfoWithRelationships: function (layerUrl) {
		var token = this._checkTokenAuth();
		
        var def = new Deferred();
        esriRequest({
          url: layerUrl,
          content: {
            f: 'json',
			token: token
          },
          handleAs: 'json',
          callbackParamName: 'callback'
        }).then(lang.hitch(this, function (layerInfo) {
          if (!layerInfo.relationships) {
            layerInfo.relationships = [];
          }
          layerInfo._origLayerURL = layerUrl;
          var serviceUrl = this._getServiceUrlByLayerUrl(layerUrl);
          layerInfo._origServiceURL = serviceUrl
          var defs = array.map(layerInfo.relationships, lang.hitch(this, function (relationship) {
            return esriRequest({
              url: serviceUrl + '/' + relationship.relatedTableId,
              content: {
                f: 'json'
              },
              handleAs: 'json',
              callbackParamName: 'callback'
            });
          }));
          all(defs).then(lang.hitch(this, function (results) {
            array.forEach(results, lang.hitch(this, function (relationshipInfo, index) {
              var relationship = layerInfo.relationships[index];
              relationship.name = relationshipInfo.name;
              //ignore shape field
              relationship.fields = array.filter(relationshipInfo.fields,
                lang.hitch(this, function (relationshipFieldInfo) {
                  return relationshipFieldInfo.type !== 'esriFieldTypeGeometry';
                }));
            }));
            def.resolve({state: 'success', value: layerInfo});
          }), lang.hitch(this, function (err) {
            def.resolve({state: 'failure', value: err});
          }));
          def.resolve({state: 'success', value: layerInfo});
        }), lang.hitch(this, function (err) {
          def.resolve({state: 'failure', value: err});
        }));
        return def;
      },

      _queryFromURL: function (value, slayerId, exprNum, close) {
        slayerId = typeof slayerId !== 'undefined' ? slayerId : 0;
        exprNum = typeof exprNum !== 'undefined' ? exprNum : 0;
        this.AttributeLayerIndex = slayerId;
        this.expressIndex = exprNum;
//make sure the form reflects what was searched
        this.selectLayerAttribute.set('value', slayerId);
        setTimeout(lang.hitch(this, function(){
          this.selectExpression.set('value', exprNum || 0);
          setTimeout(lang.hitch(this, function(){
            var valuesObj = lang.clone(this.config.layers[slayerId].expressions.expression[exprNum || 0].values.value);
            this.paramsDijit.setSingleParamValues(valuesObj, value);
          }), 200);
        }), 200);

        var valsArr = this._buildSearchValues(value);
        //determine if this layer has any sum field(s)
        this._getSumFields(slayerId);
        if(this.sumFields.length > 0){
          html.addClass(this.list.domNode, 'sum');
          html.setStyle(this.divSum, 'display', '');
        }else{
          html.removeClass(this.list, 'sum');
          html.setStyle(this.divSum, 'display', 'none');
        }
        this.search(null, slayerId, exprNum, valsArr, null, close);
      },

      _createSearchResultLayer: function (layerIndex) {
        var resultLayer = null;
        var layerConfig = this.config.layers[layerIndex];
        var layerInfo = lang.clone(this.resultLayers[layerIndex]);
        var _hasInfoTemplate = false;
        var _infoTemplate = null;
        var _popupNeedFields = [];

        //now setup the infoTemplate
        //check if this layer is part of map and if it has a popup defined already
        var lyrDisablePopupsAndTrue = (layerConfig.hasOwnProperty("disablePopups") && layerConfig.disablePopups)?true:false;
        if(!this.config.disablePopups && !lyrDisablePopupsAndTrue){
          if(layerConfig.popupfrom && layerConfig.popupfrom === "webmap"){
            array.forEach(this.operLayerInfos.getLayerInfoArray(), function(layerInfo2) {
              //console.info(layerInfo2);
              if(layerInfo2.layerObject && layerInfo2.layerObject.url === layerInfo._origServiceURL || layerInfo2.layerObject.url === layerInfo._origLayerURL){
                //console.info(layerInfo2);
                if(layerInfo2.controlPopupInfo.hasOwnProperty("infoTemplates")){
                  if(layerInfo2.controlPopupInfo.infoTemplates[layerInfo.id]){
                    //console.info(layerInfo2.controlPopupInfo.infoTemplates[layerInfo.id].infoTemplate);
                    _popupNeedFields = this._addPopupFields(layerInfo2.controlPopupInfo.infoTemplates[layerInfo.id].infoTemplate._fieldLabels);
                    _infoTemplate = layerInfo2.controlPopupInfo.infoTemplates[layerInfo.id].infoTemplate;
                    _hasInfoTemplate = true;
                  }else{
                    _hasInfoTemplate = false;
                  }
                }else{
                  _popupNeedFields = this._addPopupFields(layerInfo2.controlPopupInfo.infoTemplate._fieldLabels);
                  _infoTemplate = layerInfo2.controlPopupInfo.infoTemplate;
                  _hasInfoTemplate = true;
                }
              }
            }, this);
          }else{
            _hasInfoTemplate = false;
          }
        }

        if (layerConfig.shareResult) {
          //only keep necessary fields
          var necessaryFieldNames = this._getOutputFields(layerIndex, _popupNeedFields);
          layerInfo.fields = array.filter(layerInfo.fields, lang.hitch(this, function (fieldInfo) {
            if(!layerConfig.fields.all){
              return necessaryFieldNames.indexOf(fieldInfo.name) >= 0;
            }else{
              return true;
            }
          }));
/*Adjust field aliases to those configured in the json*/
          array.map(layerInfo.fields, lang.hitch(this, function (fieldInfo){
            if(necessaryFieldNames.indexOf(fieldInfo.name) >= 0){
              var cnfgFldObj = this._getConfigFieldObject(fieldInfo.name, layerIndex);
              if(cnfgFldObj && cnfgFldObj.alias !== fieldInfo.alias){
                fieldInfo.alias = cnfgFldObj.alias;
              }
            }
          }));
          var featureCollection = {
            layerDefinition: layerInfo,
            featureSet: null
          };
          resultLayer = new FeatureLayer(featureCollection);
        } else {
          //use graphics layer
          this._resetAndAddTempResultLayer();
          resultLayer = this.tempResultLayer;
        }
        if(_hasInfoTemplate){
          resultLayer._hasInfoTemplate = true;
          resultLayer.infoTemplate = _infoTemplate;
        }else{
          resultLayer._hasInfoTemplate = false;
        }
        return resultLayer;
      },

      _addPopupFields: function(fields) {
        var popFldArr = [];
        for(var fld in fields){
          popFldArr.push(fields[fld]);
        }
        return popFldArr;
      },

      _getConfigFieldObject: function (fldName, layerIndex) {
//        console.info(fldName, layerIndex);
        var layerConfig = this.config.layers[layerIndex];
        var fields = layerConfig.fields.field;
        var retFldObj = null;
        array.some(fields, lang.hitch(this, function (fieldInfo) {
          if(fieldInfo.name === fldName){
            retFldObj = fieldInfo;
            return true;
          }else{
            return false;
          }
        }));
        return retFldObj;
      },

      _getOutputFields: function (layerIndex, popupFieldName) {
        var layerConfig = this.config.layers[layerIndex];
        var fields = layerConfig.fields.field;
        var outFields = array.map(fields, lang.hitch(this, function (fieldInfo) {
          return fieldInfo.name;
        }));
        //we need to add objectIdField into outFields because relationship query
        //needs objectId infomation
        var objectIdField = layerConfig.objectIdField;
        if (array.indexOf(outFields, objectIdField) < 0) {
          outFields.push(objectIdField);
        }

        //Make sure the title field is added to the fields array
        var title = layerConfig.titlefield;
        if (array.indexOf(outFields, title) < 0) {
          outFields.push(title);
        }

        var allFieldInfos = this.resultLayers[layerIndex].fields;
        var allFieldNames = array.map(allFieldInfos, lang.hitch(this, function (fieldInfo) {
          return fieldInfo.name;
        }));
        //make sure every fieldName of outFields exists in fieldInfo
        outFields = array.filter(outFields, lang.hitch(this, function (fieldName) {
          return allFieldNames.indexOf(fieldName) >= 0;
        }));
        //make sure every popupfield is added
        array.map(popupFieldName, lang.hitch(this, function(fldname){
          if (array.indexOf(outFields, fldname) < 0) {
            outFields.push(fldname);
            //console.info("Added popup field: " + fldname);
          }
        }));
        if(layerConfig.fields.all){
          outFields = allFieldNames;
        }
        //console.info(outFields);
        return outFields;
      },

      _bufferGeometries: function (geomArr, sr, dist, unit, isGraphicalBufferOp) {
        if (geomArr) {
          var bufferParameters = new BufferParameters();
          var resultEvent;
          bufferParameters.geometries = geomArr;
          bufferParameters.bufferSpatialReference = sr;
          bufferParameters.unit = GeometryService[unit];
          bufferParameters.distances = dist;
          bufferParameters.unionResults = true;
          bufferParameters.geodesic = true;
          bufferParameters.outSpatialReference = this.map.spatialReference;
          esriConfig.defaults.geometryService.buffer(bufferParameters, lang.hitch(this, function (evt) {
            resultEvent = evt[0];
            var graphic = new Graphic();
            graphic.geometry = resultEvent;
            graphic.symbol = new SimpleFillSymbol(this.config.bufferDefaults.simplefillsymbol);

            this.graphicsLayerBuffer.clear();
            this.graphicsLayerBuffer.add(graphic);
            html.setStyle(this.btnClearBuffer2, 'display', 'block');
            html.setStyle(this.btnClearBuffer3, 'display', 'block');
            if (isGraphicalBufferOp) {
              this.search(resultEvent, this.graphicLayerIndex);
            }
          }));
        }
      },

      _buildSearchValues: function (value) {
        var valArray = [];
        var values = value.split("|");
        array.forEach(values, lang.hitch(this, function (val) {
          var retValueObj = {};
          if (val.indexOf('~') > -1) {
            var ranges = val.split("~");
            retValueObj.value1 = ranges[0];
            retValueObj.value2 = ranges[1];
          } else {
            retValueObj.value = val;
          }
          valArray.push(retValueObj);
        }));
        return valArray;
      },

      getUrlParams: function () {
        var s = window.location.search,
          p;
        if (s === '') {
          return {};
        }
        p = ioquery.queryToObject(s.substr(1));
        return p;
      },

      _initProgressBar: function () {
        this.progressBar = new ProgressBar({
          indeterminate: true
        }, this.progressbar);
        html.setStyle(this.progressBar.domNode, 'display', 'none');
      },

      _initSelectedLayerExpressions: function () {
        this.selectExpression.removeOption(this.selectExpression.getOptions());
        var express = [];
        //now loop through the expressions
        var elen = this.config.layers[this.AttributeLayerIndex].expressions.expression.length;
        for (var e = 0; e < elen; e++) {
          var eoption = {
            value: e,
            label: this.config.layers[this.AttributeLayerIndex].expressions.expression[e].alias
          };
          express.push(eoption);
          if (e === 0) {
            express[e].selected = true;
          }
        }
        this.selectExpression.addOption(express);
        if (elen === 1) {
          domUtils.hide(this.expressionDiv);
        } else {
          domUtils.show(this.expressionDiv);
        }
      },

      _initDrawBox: function () {
        aspect.before(this.drawBox, "_activate", lang.hitch(this, function(){
          this.publishData({message: "Deactivate_DrawTool"});
        }));
        this.drawBox.setMap(this.map);
        var enabledButtons = [];
        if (this.config.graphicalsearchoptions.enablepointselect) {
          enabledButtons.push('POINT');
        }
        if (this.config.graphicalsearchoptions.enablelineselect) {
          enabledButtons.push('LINE');
        }
        if (this.config.graphicalsearchoptions.enablepolylineselect) {
          enabledButtons.push('POLYLINE');
        }
        if (this.config.graphicalsearchoptions.enablefreehandlineselect) {
          enabledButtons.push('FREEHAND_POLYLINE');
        }
        if (this.config.graphicalsearchoptions.enabletriangleselect) {
          enabledButtons.push('TRIANGLE');
        }
        if (this.config.graphicalsearchoptions.enableextentselect) {
          enabledButtons.push('EXTENT');
        }
        if (this.config.graphicalsearchoptions.enablecircleselect) {
          enabledButtons.push('CIRCLE');
        }
        if (this.config.graphicalsearchoptions.enableellipseselect) {
          enabledButtons.push('ELLIPSE');
        }
        if (this.config.graphicalsearchoptions.enablepolyselect) {
          enabledButtons.push('POLYGON');
        }
        if (this.config.graphicalsearchoptions.enablefreehandpolyselect) {
          enabledButtons.push('FREEHAND_POLYGON');
        }
        this.drawBox.geoTypes = enabledButtons;
        this.drawBox._initTypes();
        if(this.keepgraphicalsearchenabled){
          this.drawBox.deactivateAfterDrawing = false;
        }
        this.own(on(this.drawBox, 'IconSelected', lang.hitch(this, function (tool, geotype, commontype) {
          if (this.lastDrawCommonType && this.lastDrawCommonType !== commontype && this.garr.length > 0) {
            var qMessage = new Message({
              type: 'question',
              titleLabel: this.nls.warning,
              message: this.nls.graphicgeomtypemsg1 + "\n\n" + this.nls.graphicgeomtypemsg2,
              buttons: [{
                label: this.nls._continue,
                onClick: lang.hitch(this, lang.hitch(this, function () {
                  qMessage.close();
                  this.lastDrawCommonType = commontype;
                  this.lastDrawTool = geotype;
                  this.drawBox.clear();
                  this.garr = [];
                }))
              }, {
                label: this.nls.cancel,
                onClick: lang.hitch(this, lang.hitch(this, function () {
                  qMessage.close();
                  this.drawBox.activate(this.lastDrawTool);
                }))
              }]
            });
          }else{
            this.lastDrawCommonType = commontype;
            this.lastDrawTool = geotype;
          }
        })));
        this.own(on(this.drawBox, 'DrawEnd', lang.hitch(this, function (graphic) {
          if (!this.cbxMultiGraphic.getValue()) {
            if (graphic.geometry.type === "point" && this.cbxAddTolerance.getValue()) {
              var ext = this.pointToExtent(graphic.geometry, this.pointSearchTolerance);
              this.search(ext, this.graphicLayerIndex);
            } else {
              if (this.cbxBufferGraphic.getValue()) {
				if(this.txtBufferValue.get('value') && this.txtBufferValue.get('value') > 0)
				{
            	  this._bufferGeometries([graphic.geometry], new SpatialReference({
                    wkid: this.bufferWKID
                  }), [parseFloat(this.txtBufferValue.get('value'))], this.bufferUnits.get('value'), true);
				} else {
          		  new Message({
            		  titleLabel: this.nls.bufferSearchErrorTitle,
            		  message: this.nls.bufferValueError
          		  });
        	    }
              } else {
                this.search(graphic.geometry, this.graphicLayerIndex);
              }
            }
          } else {
            this.garr.push(graphic);
          }
        })));
        this.own(on(this.btnClear2, "click", lang.hitch(this, this.clear, true)));
        this.own(on(this.btnClear3, "click", lang.hitch(this, this.clear, true)));
        this.own(on(this.btnClear4, "click", lang.hitch(this, this.clearFields, true)));
        this.own(on(this.btnClearBuffer2, "click", lang.hitch(this, this.clearbuffer)));
        this.own(on(this.btnClearBuffer3, "click", lang.hitch(this, this.clearbuffer)));
        html.setStyle(this.btnClearBuffer2, 'display', 'none');
        html.setStyle(this.btnClearBuffer3, 'display', 'none');
        html.setStyle(this.btnClear2, 'display', 'none');
        html.setStyle(this.btnClear3, 'display', 'none');
      },

      exportURL: function () {
        var useSeparator, eVal;
        var url = window.location.protocol + '//' + window.location.host + window.location.pathname;
        var urlObject = urlUtils.urlToObject(window.location.href);
        urlObject.query = urlObject.query || {};
        var content = this.paramsDijit.getSingleParamValues();
        for (var s = 0; s < content.length; s++) {
          eVal = content[s].value.toString();
        }
        urlObject.query.esearch = eVal;
        urlObject.query.slayer = this.AttributeLayerIndex.toString();
        urlObject.query.exprnum = this.expressIndex.toString();
        // each param
        for (var i in urlObject.query) {
          if (urlObject.query[i] && urlObject.query[i] !== 'config') {
            // use separator
            if (useSeparator) {
              url += '&';
            } else {
              url += '?';
              useSeparator = true;
            }
            url += i + '=' + urlObject.query[i];
          }
        }
        /*new Message({
          titleLabel: "eSearch widget url search string.",
          message: url
        });*/
        window.prompt(this.nls.copyurlprompt, url);
      },

      _bufferFeatures: function () {
        if (this.currentLayerAdded && this.currentLayerAdded.graphics.length > 0) {
          var geoms = array.map(this.currentLayerAdded.graphics, function (gra) {
            return gra.geometry;
          });
          this._bufferGeometries(geoms, new SpatialReference({
            wkid: this.bufferWKID
          }), [parseFloat(this.txtBufferValueSpat.get('value'))], this.bufferUnitsSpat.get('value'), false);
        } else {
          new Message({
            titleLabel: this.nls.bufferSearchErrorTitle,
            message: this.nls.bufferMessage
          });
        }
      },

      onSearch: function () {
        var content = this.paramsDijit.getSingleParamValues();
        if (!content || content.length === 0 || !this.config.layers.length) {
          return;
        }
        this.search(null, this.AttributeLayerIndex, this.expressIndex);
      },

      _onBtnGraSearchClicked: function () {
        if (this.garr.length > 0) {
          if (!this.keepgraphicalsearchenabled) {
            this.map.enableMapNavigation();
          }
          this.lastDrawCommonType = null;
          this.lastDrawTool = null;
          if (this.cbxBufferGraphic.getValue()) {
            var geoms = array.map(this.garr, function (gra) {
              return gra.geometry;
            });
            if(this.txtBufferValue.get('value') && this.txtBufferValue.get('value') > 0)
            {
            	this._bufferGeometries(geoms, new SpatialReference({
              		wkid: this.bufferWKID
            	}), [parseFloat(this.txtBufferValue.get('value'))], this.bufferUnits.get('value'), true);
            } else {
          		new Message({
            		titleLabel: this.nls.bufferSearchErrorTitle,
            		message: this.nls.bufferValueError
          		});
        	}
          } else {
            this.search(this.unionGeoms(this.garr), this.graphicLayerIndex);
          }
        }
      },

      _onCbxMultiGraphicClicked: function () {
        if (this.cbxMultiGraphic.getValue()) {
          html.setStyle(this.btnGraSearch, 'display', 'inline-block');
        } else {
          html.setStyle(this.btnGraSearch, 'display', 'none');
        }
      },

      unionGeoms: function (gArray) {
        var retGeom;
        var mPoint = new Multipoint(this.map.spatialReference);
        var mPoly = new Polygon(this.map.spatialReference);
        var mPolyL = new Polyline(this.map.spatialReference);
        var rType;
        this.polygonsToDiscard = [];
        if (gArray.length > 0 && gArray[0].geometry.type === "polygon") {
          //For each polygon, test if another polgon exists that contains the first polygon.
          //If it does, the polygon will not be included in union operation and it will added to the polygonsToDiscard array.
          dojo.forEach(gArray, lang.hitch(this, function (graphic) {
            var poly1 = graphic.geometry;
            dojo.forEach(this.gArray, lang.hitch(this, function (aGraphic) {
              var aPoly = aGraphic.geometry;
              if (aPoly.extent.contains(this.graphic.geometry) && (aPoly.extent.center.x !== poly1.extent.center.x ||
                                                                   aPoly.extent.center.y !== poly1.extent.center.y)) {
                this.polygonsToDiscard.push(poly1);
              }
            }));
          }));
        }
        //globals
        var poly, ext, j, mp, ringArray;
        dojo.forEach(gArray, lang.hitch(this, function (graphic) {
          if (graphic.geometry.type === "point" && !this.cbxAddTolerance.getValue()) {
            mPoint.addPoint(graphic.geometry);
            rType = "point";
          } else if (graphic.geometry.type === "point" && this.cbxAddTolerance.getValue()) {
            ext = this.pointToExtent(graphic.geometry, this.pointSearchTolerance);
            ringArray = this.extentToMPArray(ext);
            mPoly.addRing(ringArray);
            rType = "poly";
            mPoly.spatialReference = ext.spatialReference;
          }
          if (graphic.geometry.type === "multipoint") {
            var mp1 = graphic.geometry;
            for (var p = 0; p < mp1.points.length; p++) {
              mPoint.addPoint(mp1.points[p]);
            }
            rType = "point";
          }
          if (graphic.geometry.type === "polyline") {
            var polyl = graphic.geometry;
            for (var l = polyl.paths.length - 1; l >= 0; l--) {
              var pathArray = [];
              for (j = 0; j < polyl.paths[l].length; j++) {
                mp = polyl.getPoint(l, j);
                mp.spatialReference = polyl.spatialReference;
                pathArray.push(mp);
              }
              mPolyL.addPath(pathArray);
            }
            rType = "line";
          }
          if (graphic.geometry.type === "extent") {
            ext = graphic.geometry;
            ringArray = this.extentToMPArray(ext);
            mPoly.addRing(ringArray);
            rType = "poly";
            mPoly.spatialReference = ext.spatialReference;
          }
          if (graphic.geometry.type === "polygon") {
            poly = graphic.geometry;
            //Consider only the rings that not coincide with any polygon ring on polygonsToDiscard array.
            var targetRings = [];
            for (var m = 0; m < poly.rings.length; m++) {
              var polygonToDiscard;
              var targetRing = [];
              var targetPolygon = new Polygon([poly.rings[m]], poly.spatialReference);
              var add = true;
              if (this.polygonsToDiscard.length > 0) {
                for (polygonToDiscard in this.polygonsToDiscard) {
                  add = true;
                  if (targetPolygon.extent.center.x === polygonToDiscard.extent.center.x &&
                      targetPolygon.extent.center.y === polygonToDiscard.extent.center.y) {
                    add = false;
                    break;
                  }
                }
                if (add) {
                  targetRing[0] = m;
                  targetRing[1] = poly.rings[m];
                  targetRings.push(targetRing);
                }
              } else {
                targetRing[0] = m;
                targetRing[1] = poly.rings[m];
                targetRings.push(targetRing);
              }
            }
            for (var i2 = targetRings.length - 1; i2 >= 0; i2--) {
              ringArray = [];
              for (var j1 = 0; j1 < targetRings[i2][1].length; j1++) {
                var mp2 = poly.getPoint(i2, j1);
                mp2.spatialReference = poly.spatialReference;
                ringArray.push(mp2);
              }
              mPoly.addRing(ringArray);
            }
            rType = "poly";
            mPoly.spatialReference = poly.spatialReference;
          }
        }));

        switch (rType) {
        case "point":
          {
            retGeom = mPoint;
            break;
          }
        case "poly":
          {
            retGeom = mPoly;
            break;
          }
        case "line":
          {
            retGeom = mPolyL;
            break;
          }
        }
        this.garr = [];
        return retGeom;
      },

      pointToExtent: function (objPoint, distance) {
        var clickOffset = distance || 6;
        var centerPoint = new Point(objPoint.x, objPoint.y, objPoint.spatialReference);
        var mapWidth = this.map.extent.getWidth();
        var pixelWidth = mapWidth / this.map.width;
        var tolerance = clickOffset * pixelWidth;
        var queryExtent = new Extent(1, 1, tolerance, tolerance, objPoint.spatialReference);
        return queryExtent.centerAt(centerPoint);
      },

      extentToPolygon: function (extent) {
        var polygon = new Polygon([extent.xmax, extent.ymax], [extent.xmax, extent.ymin], [extent.xmin, extent.ymin],
                                  [extent.xmin, extent.ymax], [extent.xmax, extent.ymax]);
        polygon.setSpatialReference(this.map.spatialReference);
        return polygon;
      },

      extentToMPArray: function (extent) {
        var MPArr = [[extent.xmax, extent.ymax], [extent.xmax, extent.ymin], [extent.xmin, extent.ymin],
                     [extent.xmin, extent.ymax], [extent.xmax, extent.ymax]];
        return MPArr;
      },

      checkforenterkey: function (evt) {
        var keyNum = evt.keyCode !== undefined ? evt.keyCode : evt.which;
        if (keyNum === 13) {
          this.search(null, this.AttributeLayerIndex, this.expressIndex);
        }
      },
	
	  // for BG GIS we will not be using this functionality
      /*onNewSelection: function(){
        html.replaceClass(this.gSelectType.iconNode, 'newSelIcon', 'removeSelIcon');
        html.replaceClass(this.gSelectType.iconNode, 'newSelIcon', 'addSelIcon');
        this.gSelectTypeVal = 'new';
      },

      onAddSelection: function(){
        html.replaceClass(this.gSelectType.iconNode, 'addSelIcon', 'newSelIcon');
        html.replaceClass(this.gSelectType.iconNode, 'addSelIcon', 'removeSelIcon');
        this.gSelectTypeVal = 'add';
      },

      onRemoveSelection: function(){
        html.replaceClass(this.gSelectType.iconNode, 'removeSelIcon', 'newSelIcon');
        html.replaceClass(this.gSelectType.iconNode, 'removeSelIcon', 'addSelIcon');
        this.gSelectTypeVal = 'rem';
      },

      onNewSelection2: function(){
        html.replaceClass(this.aSelectType.iconNode, 'newSelIcon', 'removeSelIcon');
        html.replaceClass(this.aSelectType.iconNode, 'newSelIcon', 'addSelIcon');
        this.aSelectTypeVal = 'new';
      },

      onAddSelection2: function(){
        html.replaceClass(this.aSelectType.iconNode, 'addSelIcon', 'newSelIcon');
        html.replaceClass(this.aSelectType.iconNode, 'addSelIcon', 'removeSelIcon');
        this.aSelectTypeVal = 'add';
      },

      onRemoveSelection2: function(){
        html.replaceClass(this.aSelectType.iconNode, 'removeSelIcon', 'newSelIcon');
        html.replaceClass(this.aSelectType.iconNode, 'removeSelIcon', 'addSelIcon');
        this.aSelectTypeVal = 'rem';
      },*/

      search: function (geometry, layerIndex, /* optional */ expressIndex, theValue, spatialRelationship, closeOnComplete, isBufferSearch, layerValue) {
		    this.geometryForBGRegularSearch = null;		        
        this.isBufferSearch = isBufferSearch;
        this.circleLayer = this.map.getLayer("circles");
		    this.geometryForBGRegularSearch = null;
        var adding = false,
            removing = false;
        if (typeof closeOnComplete === 'undefined') {
          closeOnComplete = false;
        }
        this.oidArray = [];
        if (!this.config.layers) {
          return;
        }
        if (this.config.layers.length === 0) {
          return;
        }

        if (geometry) {
          //get the adding or removing
          if(this.gSelectTypeVal === 'add'){
            adding = true;
          }
          if(this.gSelectTypeVal === 'rem'){
            removing = true;
          }
        }else{
          //get the adding or removing
          if(this.aSelectTypeVal === 'add'){
            adding = true;
          }
          if(this.aSelectTypeVal === 'rem'){
            removing = true;
          }
        }
        var queryParams = new Query();
        if(!adding && !removing){
          this.clear();
        }else{
          this._clearLayers();
          this.drawBox.clear();
          this.garr = [];
          this.lastDrawCommonType = null;
          this.lastDrawTool = null;
        }
        this.currentSearchLayer = this._createSearchResultLayer(layerIndex || 0);
        this.currentLayerIndex = layerIndex;

        var layerConfig = this.config.layers[layerIndex];

        if (geometry) {
          this.initiator = 'graphic';
          if (!layerValue){
            layerValue = this.selectLayerGraphical.get('value');      // graphical search layer
          }
         
        // BG Graphic search
        if(typeof layerValue == 'string' && layerValue.indexOf('basicgov') != -1){
          this._clearBGSearchLayer();
          var values = layerValue.split('/');
          var objName = values[1];
          var listViewName = values[2];
          var searchType = geometry.type;
          var points;
          if(searchType  == 'point'){
            searchType = 'Point';
            points = [[geometry.x,geometry.y]];				
          } else if(searchType == 'polyline'){
            searchType = 'Line';
            points = geometry.paths[0];
          } else if(searchType == 'extent'){
            points = [[geometry.xmax, geometry.xmin, geometry.ymax, geometry.ymin]];
            //BG try to convert extent to polygon
            searchType = 'Circle';
            var newPolygon = new Polygon(this.map.spatialReference);
            newPolygon.addRing([[geometry.xmin,geometry.ymin],[geometry.xmin,geometry.ymax],[geometry.xmax,geometry.ymax],[geometry.xmax,geometry.ymin],[geometry.xmin,geometry.ymin]]);
            this.geometryForBGRegularSearch = newPolygon;
          } else if(searchType == 'polygon'){
            searchType = 'Circle';
            points = geometry.rings[0];
            this.geometryForBGRegularSearch = geometry;
          }
          console.debug('*** spatialReference ' + this.map.spatialReference.wkid);
          console.debug('*** Points ' +points);
          console.debug('*** Search Type ' +searchType);
          console.debug('*** Object Name '+objName);
          console.debug('*** ListView Name '+listViewName);
          //BG future enhancement: May be need to convert every non-Polygon Geometry to Polygon (Circle) to do the search
          /*if(searchType != 'Circle'){
            console.debug('*** Non Circle Search');
            this.bgManager.getSearchResults(points, searchType, objName, listViewName);
            if(dojoSubscribersMap['searchResults_'+objName+'_'+listViewName+'_onBGSearchFinish'+'Search'] != true){
              dojo.subscribe('searchResults_'+objName+'_'+listViewName, lang.hitch(this, this._onBGSearchFinish));
              dojoSubscribersMap['searchResults_'+objName+'_'+listViewName+'_onBGSearchFinish'+'Search'] = true;
            }
          } else 
          {*/
            console.debug('*** Circle Search');
            this.bgManager.getAllResultsFromSearch(objName, listViewName);
            if(dojoSubscribersMap['allBGRecords_'+objName+'_'+listViewName+'_onBGSearchFinish'+'Search'] != true){
              dojo.subscribe('allBGRecords_'+objName+'_'+listViewName, lang.hitch(this, this._onBGSearchFinish));
              dojoSubscribersMap['allBGRecords_'+objName+'_'+listViewName+'_onBGSearchFinish'+'Search'] = true;
            }
          /*}*/
          
          this.tabContainer.selectTab(this.nls.results);
          html.setStyle(this.progressBar.domNode,'display','block');
          html.setStyle(this.divOptions, 'display', 'none');
        } else {  //GIS Graphic Search
          queryParams.geometry = geometry;
          queryParams.spatialRelationship = spatialRelationship || Query.SPATIAL_REL_INTERSECTS;
          if (this.cbxAddTextQuery.getValue()) {
          var gwhere = this.buildWhereClause(layerIndex, this.expressIndex, theValue);
          queryParams.where = this.lastWhere = gwhere;
          if(!gwhere){
            console.info('No SQL expression found');
          }else{
            console.info(gwhere);
          }
          }
          if (layerConfig.definitionexpression) {
            queryParams.where = layerConfig.definitionexpression;
            if (this.lastWhere) {
              queryParams.where += ' AND ' + this.lastWhere;
            }
            console.info('SQL Where with layers definition expression: ', queryParams.where);
            }
          this._doQueryTask(queryParams, layerIndex, closeOnComplete, removing, adding);
        }
      } else { //BG Text Search
        this.initiator = 'attribute';
        if (!layerValue) {
          layerValue = this.selectLayerAttribute.get('value');      // text search layer
        }
        if(typeof layerValue == 'string' && layerValue.indexOf('basicgov') != -1){
          this._clearBGSearchLayer();
          var optionValue = this.selectLayerAttribute.get('value');
          var values = optionValue.split('/');
          var objName = values[1];
          var listViewName = values[2];
          var paramValues = this.paramsDijit.getSingleParamValues();
		  
		  // old code for SOSL query only sending the search text
          /*var content2 = paramValues[0].value;
		  console.debug('*** Search text ' +content2);
		  if(!content2){
          new Message({
            message: 'Search text cannot be empty.'
          });
          return;
          }
		  this.bgManager.getSearchResultsText(content2, objName, listViewName);
		  if(dojoSubscribersMap['searchResultsText_'+objName+'_'+listViewName+'_onBGSearchFinish'+'Search'] != true){
			dojo.subscribe('searchResultsText_'+objName+'_'+listViewName, lang.hitch(this, this._onBGSearchFinish));
			dojoSubscribersMap['searchResultsText_'+objName+'_'+listViewName+'_onBGSearchFinish'+'Search'] = true;
          }*/
		  
		  //new code to suport multiple field SOQL query
		  var where = this.buildWhereClause(layerIndex, expressIndex, theValue);
          
          console.debug('*** Object Name '+objName);
          console.debug('*** ListView Name '+listViewName);
		  console.debug('*** BG where '+where);
          
		  this.bgManager.getSearchResultsWhereClause(where, objName, listViewName);
          if(dojoSubscribersMap['searchResultsWhere_'+objName+'_'+listViewName+'_onBGSearchFinish'+'Search'] != true){
			dojo.subscribe('searchResultsWhere_'+objName+'_'+listViewName, lang.hitch(this, this._onBGSearchFinish));
			dojoSubscribersMap['searchResultsWhere_'+objName+'_'+listViewName+'_onBGSearchFinish'+'Search'] = true;
          }
          this.tabContainer.selectTab(this.nls.results);
          html.setStyle(this.progressBar.domNode,'display','block');
            html.setStyle(this.divOptions, 'display', 'none');
        } else {  //GIS Text Search
        var where = this.buildWhereClause(layerIndex, expressIndex, theValue);
        queryParams.where = this.lastWhere = where;
        if (this.limitMapExtentCbx.getValue()) {
          queryParams.geometry = this.map.extent;
        }
        if (layerConfig.definitionexpression && this.lastWhere.indexOf(layerConfig.definitionexpression) === -1) {
          queryParams.where = layerConfig.definitionexpression + ' AND ' + this.lastWhere;
        }
        console.info('SQL Where with layers definition expression: ', queryParams.where);
        this._doQueryTask(queryParams, layerIndex, closeOnComplete, removing, adding);
        }
      }

        //check for required fields, moved to _doQueryTask()
      },
	  
	  _doQueryTask: function(queryParams, layerIndex, closeOnComplete, removing, adding) {
		  //check for required fields
          if(this.initiator === 'attribute' || this.initiator === 'graphic' && this.cbxAddTextQuery.getValue()){
            if(!this.checkForRequiredFieldsEntered()){
              new Message({
                titleLabel: this.nls.requiredWarning,
                message: this.nls.requiredErrorMessage
              });
              return;
            }
          }
		
		  if (this.rsltsTab) {
            this.tabContainer.selectTab(this.nls.results);
          }
          html.setStyle(this.progressBar.domNode, 'display', 'block');
          html.setStyle(this.divOptions, 'display', 'none');
          var fields = [];
          if (this.config.layers[layerIndex].fields.all) {
            fields[0] = "*";
          } else {
            for (var i = 0, len = this.config.layers[layerIndex].fields.field.length; i < len; i++) {
			  fields[i] = this.config.layers[layerIndex].fields.field[i].name;
		    }
          }
          if (!this.config.layers[layerIndex].existObjectId && fields.indexOf(this.config.layers[layerIndex].objectIdField) < 0) {
            if(!this.config.layers[layerIndex].fields.all){
              fields.push(this.config.layers[layerIndex].objectIdField);
            }
          }

          queryParams.returnGeometry = true;
          queryParams.outSpatialReference = this.map.spatialReference;
          queryParams.outFields = fields;

          if(this._isServiceSupportsOrderBy(this.resultLayers[layerIndex])){
            //set sorting info
            var orderByFields = this.config.layers[layerIndex].orderByFields;   //Need to feed in my orderby field array

            if(orderByFields && orderByFields.length > 0){
              queryParams.orderByFields = orderByFields;

              var orderFieldNames = array.map(orderByFields, lang.hitch(this, function(orderByField){
                var splits = orderByField.split(' ');
                return splits[0];
              }));

              //make sure orderFieldNames exist in outFields, otherwise the query will fail
              array.forEach(orderFieldNames, lang.hitch(this, function(orderFieldName){
                if(queryParams.outFields.indexOf(orderFieldName) < 0){
                  queryParams.outFields.push(orderFieldName);
                }
              }));
            }
          }

          var queryTask = new QueryTask(this.config.layers[layerIndex].url);
		
		  // Check if token auth is required, if yes then append the token to the Query Task's query object
		  var token = this._checkTokenAuth();
		  if(token && token != '') {
			queryTask._url.query={token:token};
		  }
		
          html.empty(this.divResultMessage);
          html.place(html.toDom(this.nls.searching), this.divResultMessage);
          queryTask.execute(queryParams, lang.hitch(this, this._onSearchFinish, layerIndex, closeOnComplete, removing, adding),
            lang.hitch(this, this._onSearchError));
	  },
	  
	  /** Check if there is Token Authentication, if yes return token */
	  _checkTokenAuth: function(){
	  	if(this.appConfig.tokenInfo && this.appConfig.tokenInfo.tokenServicesUrl && this.appConfig.tokenInfo.tokenServicesUrl != '' && this.appConfig.tokenInfo.serviceUrl && this.appConfig.tokenInfo.serviceUrl != ''){
	  		var cred = tokenUtils.getPortalCredential(this.appConfig.tokenInfo.serviceUrl);
	  		if(cred != null)
	    		return cred.token;
	    	else return '';
	  	}
	  	return '';
	  },

      checkForRequiredFieldsEntered: function() {
        var content = this.paramsDijit.getSingleParamValues();
        //console.info(content);
        if (!content || content.length === 0 || !this.config.layers.length) {
          return false;
        }
        //loop though the single params
        for (var s = 0; s < content.length; s++) {
          var spRequired = this.config.layers[this.AttributeLayerIndex].expressions.expression[this.expressIndex].values.value[s].required || false;

          //console.info("Is required:", spRequired, "Single Param Value:", content[s].value);
          var hasAValue = false;
          if (!content[s].hasOwnProperty('value') || content[s].value === null) {
            if(!content[s].hasOwnProperty('value1') || content[s].value1 === null){
              continue;
            }
            if (content[s].value1.toString() !== "NaN" && content[s].value2.toString() !== "NaN") {
              hasAValue = false;
            }
          }else{
            if(content[s].value === "" || content[s].value.toString().toLowerCase() === "nan"){
              hasAValue = false;
            }else{
              hasAValue = true;
            }
          }
          //console.info("Is required:", spRequired, "Has a value:", hasAValue);
          if(spRequired && !hasAValue){
             return false;
          }
        }
        return true;
      },

      isSelTabVisible: function () {
        switch (this.selTab) {
        case this.nls.selectByAttribute:
          return this.attribTab;
        case this.nls.selectFeatures:
          return this.shapeTab;
        case this.nls.selectSpatial:
          return this.spatTab;
        case this.nls.results:
          return this.rsltsTab;
        }
      },

      clearFields: function () {
        if(this.AttributeLayerIndex || this.AttributeLayerIndex === 0){
          var exInd = this.expressIndex || 0;
          if(exInd > 0){
            this.onAttributeLayerExpressionChange(this.expressIndex);
          }else{
            this.onAttributeLayerChange(this.AttributeLayerIndex);
          }
          var valuesObj = lang.clone(this.config.layers[this.AttributeLayerIndex].expressions.expression[exInd].values.value);
          console.info(valuesObj);
          array.map(valuesObj, lang.hitch(this, function(valObj){
            if(valObj.operation.toLowerCase().indexOf('date') > -1){
              if(valObj.valueObj.hasOwnProperty('value')){
                valObj.valueObj.value = "";
              }
              if(valObj.valueObj.hasOwnProperty('value1')){
                valObj.valueObj.value1 = "";
              }
              if(valObj.valueObj.hasOwnProperty('value2')){
                valObj.valueObj.value2 = "";
              }
              this.paramsDijit.setSingleParamValues(valuesObj, "");
            }
          }));
        }
      },

      clear: function ( /* optional */ closeAtt) {
        if(this.sumDivEvt){
          this.sumDivEvt.remove();
        }
        html.removeClass(this.list.domNode, 'sum');
        html.setStyle(this.divSum, 'display', 'none');
        html.setStyle(this.divOptions, 'display', 'none');
        this.currentLayerIndex = null;
        this.currentCSVResults = null;
        this.initiator = null;
        this.lastWhere = null;
        this.oidArray = [];
        this.currentFeatures = [];
        this._hideInfoWindow();
        this._clearLayers();
        this._clearBGSearchLayer();
        this._clearCircle();
        this.divSum.innerHTML = '';
        this.zoomAttempt = 0;
        this.gSelectTypeVal = 'new';
        this.aSelectTypeVal = 'new';
        this.sumResultArr = [];
		// for BG GIS we will not be using this functionality
        /*html.replaceClass(this.gSelectType.iconNode, 'newSelIcon', 'removeSelIcon');
        html.replaceClass(this.gSelectType.iconNode, 'newSelIcon', 'addSelIcon');
        html.replaceClass(this.aSelectType.iconNode, 'newSelIcon', 'removeSelIcon');
        html.replaceClass(this.aSelectType.iconNode, 'newSelIcon', 'addSelIcon');*/
        if (closeAtt) {
          if (this.list.items.length > 0 && this.isSelTabVisible()) {
            this.tabContainer.selectTab(this.selTab);
          }
        }
        this.list.clear();
        html.empty(this.divResultMessage);
        this.drawBox.clear();
        this.garr = [];
        this.lastDrawCommonType = null;
        this.lastDrawTool = null;
        if (closeAtt) {
          if (this.wManager && this.attTableOpenedbySearch) {
            var widgetCfg = this._getWidgetConfig('AttributeTable');
            if(widgetCfg){
              var attWidget = this.wManager.getWidgetByLabel(widgetCfg.label);
              if (attWidget) {
                attWidget._closeTable();
              }
              this.attTableOpenedbySearch = false;
            }
          }
        }
        return false;
      },

      clearbuffer: function () {
        this.garr = [];
        this.graphicsLayerBuffer.clear();
        html.setStyle(this.btnClearBuffer2, 'display', 'none');
        html.setStyle(this.btnClearBuffer3, 'display', 'none');
        return false;
      },

      buildWhereClause: function (layerIndex, expressIndex, /* optional */ theValue) {
        var myPattern = /\[value\]/g;
        var myPattern1 = /\[value1\]/g;
        var myPattern2 = /\[value2\]/g;
        var myPattern3 = /\[value\]/;
        var expr = "";
        var eVal;
        var eVal1;
        var eVal2;
        var criteriaFromValue;
        var content = theValue || this.paramsDijit.getSingleParamValues();
        if (!content || content.length === 0 || !this.config.layers.length) {
          return;
        }
        //loop though the SPs and assemble the where clause
        for (var s = 0; s < content.length; s++) {
          var tOperator = (this.config.layers[layerIndex].expressions.expression[expressIndex].values.value[s] &&
            typeof this.config.layers[layerIndex].expressions.expression[expressIndex].values.value[s].operator !== 'undefined') ? this.config.layers[layerIndex].expressions.expression[expressIndex].values.value[s].operator : 'OR';
          var tOperation = this.config.layers[layerIndex].expressions.expression[expressIndex].values.value[s].operation;
          var queryExpr = this.config.layers[layerIndex].expressions.expression[expressIndex].values.value[s].sqltext;
          if (!content[s].hasOwnProperty('value') || content[s].value === null) {
            if(!content[s].hasOwnProperty('value1') || content[s].value1 === null){
              continue;
            }
            if (content[s].value1.toString() !== "NaN" && content[s].value2.toString() !== "NaN") {
              eVal1 = content[s].value1.toString();
              eVal2 = content[s].value2.toString();
              criteriaFromValue = queryExpr.replace(myPattern1, eVal1);
              criteriaFromValue = criteriaFromValue.replace(myPattern2, eVal2);
              expr = this.AppendTo(expr, criteriaFromValue, tOperator);
              continue;
            } else {
              continue;
            }
          }

          if (tOperation === 'stringOperatorContains') {
            var sa = content[s].value.toString().split(" "), word;
            for(w=0; w < sa.length; w++){
              word = sa[w];
              criteriaFromValue = queryExpr.replace(myPattern, word);
              expr = this.AppendTo(expr, criteriaFromValue, "AND");
            }
            continue;
          }

          if (tOperation === 'dateOperatorIsOn' || tOperation === 'dateOperatorIsNotOn') {
            eVal = content[s].value.toString();
            criteriaFromValue = queryExpr.replace(myPattern3, eVal);
            criteriaFromValue = criteriaFromValue.replace(myPattern3, eVal.replace('00:00:00', '23:59:59'));
            expr = this.AppendTo(expr, criteriaFromValue, tOperator);
            continue;
          } else if (tOperation === 'dateOperatorIsAfter') {
            eVal = content[s].value.toString();
            criteriaFromValue = queryExpr.replace(myPattern, eVal.replace('00:00:00', '23:59:59'));
            expr = this.AppendTo(expr, criteriaFromValue, tOperator);
            continue;
          }

          if (queryExpr === "[value]" || queryExpr.toLowerCase().indexOf(" in (") > 0) {
            //meaning an open SQL expression or an SQL with an IN Statement
            eVal = content[s].value.toString();
          } else {
            eVal = content[s].value.toString().replace(/'/g, "''");
          }

          /*If the expression is an IN Statement and the the value is a string then
          replace the user defines comma seperated values with single quoted values*/
          if (queryExpr.toLowerCase().indexOf(" in (") > 0 && queryExpr.toLowerCase().indexOf("'[value]'") > -1) {
            //replace the begining and trailing single qoutes if they exist
            eVal = eVal.replace(/^'|'$/g, "").replace(/,|','/g, "','");
          }

          if (content[s].value.toString().toLowerCase().trim() === "all") {
            var mExpr;
            if (queryExpr.indexOf("=") > -1) {
              mExpr = queryExpr.replace("=", "IN(") + ")";
            } else {
              mExpr = queryExpr;
            }
            var uList = this.config.layers[layerIndex].expressions.expression[expressIndex].values.value[s].userlist;
            var myPat;
            var uaList;
            if (uList.indexOf("','") > -1) {
              myPat = /,\s*'all'/gi;
              uList = uList.replace(myPat, "");
              uaList = this.trimArray(uList.split("','"));
              if (String(uaList[0]).substring(0, 1) === "'") {
                uaList[0] = String(uaList[0]).substring(1);
              }
              var lVal = String(uaList[uaList.length - 1]);
              if (lVal.substring(lVal.length - 1) === "'") {
                uaList[uaList.length - 1] = lVal.substring(0, lVal.length - 1);
              }
            } else {
              myPat = /,\s*all/gi;
              uList = uList.replace(myPat, "");
              uaList = this.trimArray(uList.split(","));
            }

            if (mExpr.indexOf("'[value]'") > -1) {
              uList = uaList.join("','");
            }
            criteriaFromValue = mExpr.replace(myPattern, uList);
            expr = this.AppendTo(expr, criteriaFromValue, tOperator);
          } else if (content[s].value.toString().toLowerCase() === "allu") {
            expr = this.AppendTo(expr, "1=1", tOperator);
          } else if (content[s].value.toString().toLowerCase() === "null" || content[s].value.toString().toLowerCase() === "nan"){
            console.info(content[s].value.toString().toLowerCase());
            if (content[s].isValueRequired === true){
              var mExpr2 = queryExpr.substr(0, queryExpr.indexOf("=")) + " is null";
              expr = this.AppendTo(expr, mExpr2, tOperator);
            }
          } else {
            //don't add the expression if there is no user input
            if (eVal !== "") {
              criteriaFromValue = queryExpr.replace(myPattern, eVal);
              expr = this.AppendTo(expr, criteriaFromValue, tOperator);
            }
            //unless we are using isblank or notisblank
            if (tOperation === 'stringOperatorIsBlank' ||
                tOperation === 'stringOperatorIsNotBlank' ||
                tOperation === 'numberOperatorIsBlank' ||
                tOperation === 'numberOperatorIsNotBlank' ||
                tOperation === 'dateOperatorIsBlank' ||
                tOperation === 'dateOperatorIsNotBlank') {
              expr = this.AppendTo(expr, queryExpr, tOperator);
            }
          }
        }
        return expr;
      },

      AppendTo: function (string1, string2, operator) {
        if (string1.length > 0) {
          return string1 + " " + operator + " " + string2;
        } else {
          return string2;
        }
      },

      trimArray: function (arr) {
        for (var i = 0; i < arr.length; i++) {
          arr[i] = arr[i].replace(/^\s*/, '').replace(/\s*$/, '');
        }
        return arr;
      },

      zoomall: function () {
        var layerConfig = this.config.layers[this.currentLayerIndex];
        var zoomScale = layerConfig.zoomScale || 10000;
        if (!this.currentLayerAdded) {
          return false;
        }
        if (this.currentLayerAdded.graphics.length === 1 && this.currentLayerAdded.graphics[0].geometry.type === "point") {
          var mp = this.currentLayerAdded.graphics[0].geometry;
          this.map.setScale(zoomScale);
          this.map.centerAt(mp);
        } else {
          if (this.currentLayerAdded.graphics.length === 0) {
            if (this.zoomAttempt <= 10) {
              setTimeout(lang.hitch(this, function () {
                this.zoomall();
              }), 300);
              this.zoomAttempt++;
            } else {
              this.zoomAttempt = 0;
              new Message({
                titleLabel: this.nls.warning,
                message: this.nls.zoomErrorMessage
              });
            }
          }
          var gExt = graphicsUtils.graphicsExtent(this.currentLayerAdded.graphics);
          if (gExt) {
            this.map.setExtent(gExt.expand(1.5), true);
          } else {
            var mp2 = this.currentLayerAdded.graphics[0].geometry;
            this.map.setScale(zoomScale);
            this.map.centerAt(mp2);
          }
        }
        return false;
      },

      _clearLayers: function () {
        this._removeAllResultLayers();
        html.setStyle(this.btnClear2, 'display', 'none');
        html.setStyle(this.btnClear3, 'display', 'none');
      },

      _onSearchError: function (error) {
		// retry if proxy was called (cannot disable proxy for whatever reason -tried removing from config.json to no effect)
		if (error.message.indexOf("Unable to load") > -1 && error.message.indexOf("proxy") > -1 && this.s_proxyErrors == 0) {
			this.s_proxyErrors++;
			this.search(this.s_geometry, this.s_layerIndex, this.s_layerValue, true, null); //TODO: have to correct the parameters as per the enhanced search
		}
		else {
          this.clear();
          html.setStyle(this.progressBar.domNode, 'display', 'none');
          //html.setStyle(this.divOptions, 'display', 'block');
          new Message({
            message: this.nls.searchError
          });
          console.debug(error);
		}
      },

      _substitute: function (string, Attribs, currentLayer) {
        var lfields = this._getFieldsfromLink(string);
        for (var lf = 0; lf < lfields.length; lf++) {
          if (Attribs[lfields[lf]]) {
            var fld = this._getField(currentLayer, lfields[lf]);
            if (fld.type === "esriFieldTypeString") {
              string = string.replace(new RegExp('{' + lang.trim(lfields[lf]) + '}', 'g'), lang.trim(Attribs[lfields[lf]]));
            } else {
              string = string.replace(new RegExp('{' + lang.trim(lfields[lf]) + '}', 'g'), Attribs[lfields[lf]]);
            }
          }
        }
        return string;
      },

      _getFieldsfromLink: function (strLink) {
        var retArr = [];
        var b1 = 0;
        var e1 = 0;
        var fldName = '';
        do {
          b1 = strLink.indexOf("{", e1);
          if (b1 === -1) {
            break;
          }
          e1 = strLink.indexOf("}", b1);
          fldName = strLink.substring(b1 + 1, e1);
          retArr.push(fldName);
        } while (e1 < strLink.length - 1);
        return retArr;
      },

      _getAllLyrFields: function(){
        var tempFlds = array.filter(this.resultLayers[this.currentLayerIndex].fields, lang.hitch(this, function (fieldInfo) {
          return fieldInfo.type !== 'esriFieldTypeGeometry';
        }));
        return tempFlds;
      },

      _onSearchFinish: function (layerIndex, closeOnComplete, removing, adding, results) {
        var layerConfig = this.config.layers[layerIndex];
        var resultCircleLayer = this.circleLayer;
        var currentLayer;
        array.map(this.currentSearchLayer.fields, lang.hitch(this, function (element) {
          if(layerConfig.fields.all){
            element.show = true;
          }else{
            element.show = false;
            for (var f = 0; f < layerConfig.fields.field.length; f++) {
              if (layerConfig.fields.field[f].name == element.name) {
                element.show = true;
              }
            }
          }
        }));
        currentLayer = this.currentSearchLayer;
        if (layerConfig.layersymbolfrom === 'server') {
          currentLayer.setRenderer(this._setCurentLayerRenderer('server'));
        } else if(layerConfig.layersymbolfrom === 'layer') {
          currentLayer.setRenderer(this._setCurentLayerRenderer('layer'));
        } else{
          currentLayer.setRenderer(this._setCurentLayerRenderer('config'));
        }
        if (this.rsltsTab) {
          this.tabContainer.selectTab(this.nls.results);
        }
        html.setStyle(this.progressBar.domNode, 'display', 'none');
        html.setStyle(this.divOptions, 'display', 'block');

        var title = "";
        var titlefield = layerConfig.titlefield;
        var sumfield = layerConfig.sumfield || null;
        var objectIdField = layerConfig.objectIdField;
        var existObjectId = layerConfig.existObjectId;
        var typeIdField = layerConfig.typeIdField;

//modify the currentFeatures with the new results
        var csvData;
        if(adding && this.currentFeatures && this.currentFeatures.length > 0){
          csvData = this.currentCSVResults.data || [];
          array.forEach(results.features, lang.hitch(this, function(gra){
            if(this.currentFeatures.indexOf(gra) < 0){
              this.currentFeatures.push(gra);
            }
          }));
        }else if (removing && this.currentFeatures && this.currentFeatures.length > 0){
          csvData = this.currentCSVResults.data || [];
          array.forEach(results.features, lang.hitch(this, function(gra){
            for (var g = this.currentFeatures.length - 1; g >= 0; g--){
              if(this.currentFeatures[g].attributes[objectIdField] == gra.attributes[objectIdField]){
                this.currentFeatures.splice(g, 1);
                break;
              }
            }
            for (var g1 = csvData.length - 1; g1 >= 0; g1--){
              var csvRowRem = csvData[g1];
              if(csvRowRem.OID == gra.attributes[objectIdField]){
                csvData.splice(g1, 1);
                break;
              }
            }
          }));
        }else{
          csvData = [];
          this.currentCSVResults = null;
          this.currentFeatures = results.features;
        }

        var listLen = this.list.items.length;
        var len = results.features.length;
        if (this.currentFeatures.length === 0) {
          html.empty(this.divResultMessage);
          html.place(html.toDom(this.nls.noResults), this.divResultMessage);
          html.setStyle(this.list.domNode, 'top', '25px');
          this.list.clear();
          this.gSelectTypeVal = 'new';
          this.aSelectTypeVal = 'new';
		  // for BG GIS we will not be using this functionality
          /*html.replaceClass(this.gSelectType.iconNode, 'newSelIcon', 'removeSelIcon');
          html.replaceClass(this.gSelectType.iconNode, 'newSelIcon', 'addSelIcon');
          html.replaceClass(this.aSelectType.iconNode, 'newSelIcon', 'removeSelIcon');
          html.replaceClass(this.aSelectType.iconNode, 'newSelIcon', 'addSelIcon');*/
          html.setStyle(this.divOptions, 'display', 'none');
          return;
        } else if (results.exceededTransferLimit){
          // SF limit of showing only 2000 records, this will add a message to the user to let them know they've selected an area with more than 2000 records
          html.empty(this.divResultMessage);
          html.place(html.toDom("<label>The search area you selected contains more than 2000 records. Please try again and select a smaller search area.</label>"), this.divResultMessage);
          html.setStyle(this.list.domNode, 'top', '40px'); // move the list down so there's room for the longer message
        } else {
          html.empty(this.divResultMessage);
          html.place(html.toDom("<label>" + this.nls.featuresSelected + this.currentFeatures.length + "</label>"), this.divResultMessage);
          html.setStyle(this.list.domNode, 'top', '25px');
        }
        var i, slen, sumTotal, numFormat, currFormat, args, sValue, args2;
        //determine if this layer has any sum field(s)
        this._getSumFields(layerIndex);
        if(this.sumFields.length > 0){
          html.addClass(this.list.domNode, 'sum');
          html.setStyle(this.divSum, 'display', '');
        }else{
          html.removeClass(this.list.domNode, 'sum');
          html.setStyle(this.divSum, 'display', 'none');
        }
        if(this.sumFields.length > 0){
          this.sumResultArr = [];
          if(this.sumDivEvt){
            this.sumDivEvt.remove();
          }
          array.map(this.sumFields, lang.hitch(this, function(sumfield){
            sumTotal = 0;
            for ( i = 0, slen = this.currentFeatures.length; i < slen; i++) {
              var feature = this.currentFeatures[i];
              sumTotal += Number(feature.attributes[sumfield.field]);
            }

            numFormat = this._getNumberFormat(sumfield.field, layerIndex);
            if (numFormat) {
              args = numFormat.split("|");
              /*value,percision,symbol,thousands,decimal*/
              sValue = this._formatNumber(sumTotal, args[0] || null, args[1] || null, args[2] || null);
            }
            currFormat = this._getCurrencyFormat(sumfield.field, layerIndex);
            if (currFormat) {
              args2 = currFormat.split("|");
              /*value,percision,symbol,thousands,decimal*/
              sValue = this._formatCurrency(sumTotal, args2[1] || null, args2[0] || null, args2[2] || null, args2[3] || null);
            }
            this.sumResultArr.push(sumfield.sumlabel + ' ' + sValue);
          }));
          if(this.sumFields.length > 1){
            this.divSum.innerHTML = this.sumResultArr[0] + '&nbsp;&nbsp;' + this.nls.more + '...';
            html.setStyle(this.divSum, 'cursor', 'pointer');
            this.sumDivEvt = on(this.divSum, 'click', lang.hitch(this, function(){
              new Message({titleLabel: this.nls.summaryresults, message: this.sumResultArr.join('<br>')});
            }));
          }else if(this.sumFields.length === 1){
            html.setStyle(this.divSum, 'cursor', 'default');
            this.divSum.innerHTML = this.sumResultArr[0];
          }
        }
        var csvColumns = [];
        for (i = 0; i < len; i++) {
          var featureAttributes = results.features[i].attributes;
          //console.info(results.features[i]);
          //work with the links now
          var qLinks = [];
          if (layerConfig.links && layerConfig.links.link) {
            qLinks = layerConfig.links.link;
          }
          var lyrQLinks = [];
          for (var a = 0; a < qLinks.length; a++) {
            var link = "",
              alias = "",
              linkicon = "",
              linkFieldNull = false,
              disableInPopUp = false,
              popupType;
            if (qLinks[a].disableinpopup) {
              disableInPopUp = true;
            }
            if (qLinks[a].disablelinksifnull) {
              var lfields = this._getFieldsfromLink(qLinks[a].content);
              for (var lf = 0; lf < lfields.length; lf++) {
                if (!featureAttributes[lfields[lf]] || featureAttributes[lfields[lf]] === "") {
                  linkFieldNull = true;
                  break;
                }
              }
            }
            if (linkFieldNull) {
              link = "";
            } else {
              link = this._substitute(qLinks[a].content, featureAttributes, results);
            }
            var sub = this._substitute(qLinks[a].alias, featureAttributes, results);
            alias = (sub) ? sub : qLinks[a].alias;
            linkicon = this._substitute((qLinks[a].icon || this.folderUrl + 'images/w_link.png'), featureAttributes, results);
            popupType = qLinks[a].popuptype;
            var lObj = {
              link: link,
              icon: linkicon,
              alias: alias,
              disableinpopup: disableInPopUp,
              popuptype: popupType
            };
            if(!linkFieldNull){
              lyrQLinks.push(lObj);
            }
          }

          var content = "",
            rsltcontent = "",
            value = "",
            csvRow = {},
            oidVal;
          csvColumns = [];
          //ensure fields are ordered the same way they are configuraed in the json (this is an issue for ArcGIS Server 10.2.x)
          var tempFlds = lang.clone(this.config.layers[layerIndex].fields.field);
          if(this.config.layers[layerIndex].fields.all){
            var tempFlds = this._getAllLyrFields();
          }
          if(!existObjectId && objectIdField && tempFlds.indexOf({"name": objectIdField}) < 0){
            tempFlds.push(
              {"name": objectIdField}
            );
          }
          array.map(tempFlds, lang.hitch(this, function (attr) {
            var att = attr.name;
            var fld = this._getField(results, att);
            if(!fld){
              console.info(att, results);
            }
            if (fld.name === objectIdField) {
              oidVal = featureAttributes[att];
              if(existObjectId){
                csvColumns.push(this._getAlias(att, layerIndex));
                csvRow[this._getAlias(att, layerIndex)] = oidVal;
              }
              csvRow["OID"] = oidVal;
            }else{
              csvColumns.push(this._getAlias(att, layerIndex));
            }
            if (this.initiator && (this.initiator === 'graphic' || this.limitMapExtentCbx.getValue())) {
              if (fld.name === objectIdField) {
                this.oidArray.push(oidVal);
              }
            }

            if (!existObjectId && fld.name === objectIdField) {
              //continue;
              return;
            }
            var fieldValue = featureAttributes[att];
            value = fieldValue !== null ? String(fieldValue) : "";
            if (value !== "") {
              var isDateField;
              if (fld) {
                isDateField = fld.type === "esriFieldTypeDate";
              }
              if (isDateField) {
                var dateMS = Number(fieldValue);
                if (!isNaN(dateMS)) {
                  if (this._getDateFormat(att, layerIndex) !== "") {
                    value = this._formatDate(dateMS, this._getDateFormat(att, layerIndex));
                  } else {
                    value = this._formatDate(dateMS, 'MM/dd/yyyy');
                  }
                }
              }
              numFormat = this._getNumberFormat(att, layerIndex);
              if (numFormat) {
                args = numFormat.split("|");
                /*value,percision,symbol,thousands,decimal*/
                value = this._formatNumber(fieldValue, args[0] || null, args[1] || null, args[2] || null);
              }
              currFormat = this._getCurrencyFormat(att, layerIndex);
              if (currFormat) {
                args2 = currFormat.split("|");
                /*value,percision,symbol,thousands,decimal*/
                value = this._formatCurrency(fieldValue, args2[1] || null, args2[0] || null, args2[2] || null, args2[3] || null);
              }
              var typeID = typeIdField ? featureAttributes[typeIdField] : null;
              if (att === typeIdField) {
                var featureType = this._getFeatureType(this.resultLayers[layerIndex], typeID);
                if (featureType && featureType.name) {
                  value = featureType.name;
                }
              } else {
                var codedValue = this._getCodedValue(this.resultLayers[layerIndex], att, fieldValue, null);
                if (codedValue) {
                  value = codedValue.name;
                }
              }
            }

            var upperCaseFieldName = att.toUpperCase();
            if (titlefield && upperCaseFieldName === titlefield.toUpperCase()) {
              title = value;
              csvRow[this._getAlias(att, layerIndex)] = value;
            } else {
              if (this._isVisible(att, layerIndex)) {
                content = content + this.resultFormatString.replace('[attribname]', this._getAlias(att, layerIndex)).replace('[attribvalue]', value);
                if (!this._isPopupOnly(att, layerIndex)) {
                  rsltcontent = rsltcontent + this.resultFormatString.replace('[attribname]',
                                                                              this._getAlias(att, layerIndex)).replace('[attribvalue]', value);
                }
                csvRow[this._getAlias(att, layerIndex)] = value;
              }
            }
          }));
          if (content.lastIndexOf('<br>') === (content.length - 4)) {
            content = content.substr(0, content.length - 4);
          } else {
            content = content;
          }
          if (rsltcontent.lastIndexOf('<br>') === (rsltcontent.length - 4)) {
            rsltcontent = rsltcontent.substr(0, rsltcontent.length - 4);
          } else {
            rsltcontent = rsltcontent;
          }
          var symbol = currentLayer.renderer.getSymbol(results.features[i]);

          if(!removing){
            csvData.push(csvRow);
            this.list.add({
              id: "id_" + i + listLen,
              OID: oidVal,
              title: title,
              content: content,
              rsltcontent: rsltcontent,
              alt: (i % 2 === 0),
              sym: symbol,
              links: lyrQLinks,
              removeResultMsg: this.nls.removeResultMsg
            });
            //,
            //showRelate: layerConfig.relates && layerConfig.relates.relate,
            //relalias: this.nls.showrelates
          }else{
            var index = this._returnListIndexFromOID(oidVal);
            if(index > -1){
              this.list.remove(index);
            }
          }
        }
        this.currentCSVResults = {
          data: csvData,
          columns: csvColumns
        }
        html.setStyle(this.btnClear2, 'display', 'block');
        html.setStyle(this.btnClear3, 'display', 'block');
        this._drawResults(layerIndex, results, currentLayer, closeOnComplete);
        if(resultCircleLayer && this.isBufferSearch){
          this.map.addLayer(resultCircleLayer);
        }
      },

      _returnListIndexFromOID: function (OID) {
        var retVal = -1;
        array.some(this.list.items, lang.hitch(this, function(item, index){
          if (item.OID === OID) {
            retVal = index;
            return true;
          }
        }));
        return retVal;
      },

      _setCurentLayerRenderer: function (symFromWhere) {
        if (symFromWhere === 'server') {
          return jsonUtil.fromJson(this.resultLayers[this.currentLayerIndex].drawingInfo.renderer);
        } else {
          var symbol,
            type = this.resultLayers[this.currentLayerIndex].geometryType;

          if(symFromWhere === 'layer'){
            var layerConfig = this.config.layers[this.currentLayerIndex];
            if(layerConfig.symbology){
              symbol = symUtils.fromJson(layerConfig.symbology);
              var sRend = new SimpleRenderer(symbol);
              sRend.label = sRend.description = this.config.layers[this.currentLayerIndex].name;
              return sRend;
            }
          }

          //Determine the geometry type to set the symbology
          switch (type) {
          case "esriGeometryMultipoint":
          case "esriGeometryPoint":
            if (this.config.symbols && this.config.symbols.simplemarkersymbol) {
              symbol = new SimpleMarkerSymbol(this.config.symbols.simplemarkersymbol);
            } else {
              if (this.config.symbols && this.config.symbols.picturemarkersymbol) {
                var pms = lang.clone(this.config.symbols.picturemarkersymbol);
                pms.url = this.folderUrl + pms.url;
                symbol = new PictureMarkerSymbol(pms);
              } else {
                symbol = new SimpleMarkerSymbol();
              }
            }
            break;
          case "esriGeometryPolyline":
            if (this.config.symbols && this.config.symbols.simplelinesymbol) {
              symbol = new SimpleLineSymbol(this.config.symbols.simplelinesymbol);
            } else {
              symbol = new SimpleLineSymbol();
            }
            break;
          case "esriGeometryEnvelope":
          case "esriGeometryPolygon":
            if (this.config.symbols && this.config.symbols.simplefillsymbol) {
              symbol = new SimpleFillSymbol(this.config.symbols.simplefillsymbol);
            } else {
              symbol = new SimpleFillSymbol();
            }
            break;
          default:
            break;
          }
          var simpRend = new SimpleRenderer(symbol);
          simpRend.label = simpRend.description = this.config.layers[this.currentLayerIndex].name;
          return simpRend;
        }
      },

      _openResultInAttributeTable: function (currentLayer) {
        var layerConfig = this.config.layers[this.currentLayerIndex];
        var lyrZoomExistsAndTrue = (layerConfig.hasOwnProperty("autozoomtoresults") && !layerConfig.autozoomtoresults)?false:true;
        if (this.autozoomtoresults && lyrZoomExistsAndTrue) {
          setTimeout(lang.hitch(this, function () {
            this.zoomall();
          }), 300);
        }
        var layerInfo = this.operLayerInfos.getLayerInfoById(currentLayer.id);
        this.publishData({
          'target': 'AttributeTable',
          'layer': layerInfo
        });
      },

      _getFeatureType: function (layer, typeID) {
        var result;
        if (layer) {
          for (var t = 0; t < layer.types.length; t++) {
            var featureType = layer.types[t];
            if (typeID === featureType.id) {
              result = featureType;
              break;
            }
          }
        }
        return result;
      },

      _getCodedValue: function (layer, fieldName, fieldValue, typeID) {
        var result;
        var codedValueDomain;
        if (typeID) {
          var featureType = this._getFeatureType(layer, typeID);
          if (featureType) {
            codedValueDomain = featureType.domains[fieldName];
          }
        } else {
          var field = this._getField(layer, fieldName);
          if (field) {
            codedValueDomain = field.domain;
          }
        }
        if (codedValueDomain) {
          if (codedValueDomain.type === 'codedValue') {
            for (var cv = 0; cv < codedValueDomain.codedValues.length; cv++) {
              var codedValue = codedValueDomain.codedValues[cv];
              if (fieldValue === codedValue.code) {
                result = codedValue;
                break;
              }
            }
          }
        }
        return result;
      },

      _getField: function (layer, fieldName) {
        var result;
        if (layer) {
          for (var f = 0; f < layer.fields.length; f++) {
            var field = layer.fields[f];
            if (fieldName === field.name) {
              result = field;
              break;
            }
          }
        }
        return result;
      },

      _formatDate: function (value, dateFormat) {
        if (dateFormat) {
          dateFormat = dateFormat.replace(/D/g, "d").replace(/Y/g, "y");
        }
        var inputDate = new Date(value);
        return locale.format(inputDate, {
          selector: 'date',
          datePattern: dateFormat
        });
      },

      _getAlias: function (att, layerIndex) {
        var field = this.config.layers[layerIndex].fields.field;
        var item;
        for (var i in field) {
          item = field[i];
          if (item && item.name && item.name.toLowerCase() === att.toLowerCase() && item.alias) {
            return item.alias;
          }
        }
        return att;
      },

      _isVisible: function (att, layerIndex) {
        var field = this.config.layers[layerIndex].fields.field;
        var item;
        for (var i in field) {
          item = field[i];
          if (item && item.name && item.name.toLowerCase() === att.toLowerCase()) {
            if (item.hasOwnProperty('visible') && item.visible === false) {
              return false;
            } else {
              return true;
            }
          }
        }
        return true;
      },

      _isPopupOnly: function (att, layerIndex) {
        var field = this.config.layers[layerIndex].fields.field;
        var item;
        for (var i in field) {
          item = field[i];
          if (item && item.name && item.name.toLowerCase() === att.toLowerCase()) {
            if (item.hasOwnProperty('popuponly') && item.popuponly === true) {
              return true;
            } else {
              return false;
            }
          }
        }
        return false;
      },

      _getDateFormat: function (att, layerIndex) {
        var field = this.config.layers[layerIndex].fields.field;
        var item;
        for (var i in field) {
          item = field[i];
          if (item && item.name && item.name.toLowerCase() === att.toLowerCase() && item.dateformat) {
            return item.dateformat;
          }
        }
        return "";
      },

      _getCurrencyFormat: function (att, layerIndex) {
        var field = this.config.layers[layerIndex].fields.field;
        var item;
        for (var i in field) {
          item = field[i];
          if (item && item.name && item.name.toLowerCase() === att.toLowerCase() && item.currencyformat) {
            return item.currencyformat;
          }
        }
        return null;
      },

      _formatCurrency: function (value, percision, symbol, thousand, decimal) {
        value = value || 0;
        percision = !isNaN(percision = Math.abs(percision)) ? percision : 2;
        symbol = symbol !== undefined ? symbol : "$";
        thousand = thousand || ",";
        decimal = decimal || ".";
        var negative = value < 0 ? "-" : "",
          i = parseInt(value = Math.abs(+value || 0).toFixed(percision), 10) + "",
          j = (j = i.length) > 3 ? j % 3 : 0;
        return symbol + negative + (j ? i.substr(0, j) + thousand : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + thousand) +
          (percision ? decimal + Math.abs(value - i).toFixed(percision).slice(2) : "");
      },

      _getNumberFormat: function (att, layerIndex) {
        var field = this.config.layers[layerIndex].fields.field;
        var item;
        for (var i in field) {
          item = field[i];
          if (item && item.name && item.name.toLowerCase() === att.toLowerCase() && item.numberformat) {
            return item.numberformat;
          }
        }
        return null;
      },

      _formatNumber: function (value, percision, thousand, decimal) {
        value = value || 0;
        percision = !isNaN(percision = Math.abs(percision)) ? percision : 2;
        thousand = thousand || ",";
        decimal = decimal || ".";
        var negative = value < 0 ? "-" : "",
          i = parseInt(value = Math.abs(+value || 0).toFixed(percision), 10) + "",
          j = (j = i.length) > 3 ? j % 3 : 0;
        return negative + (j ? i.substr(0, j) + thousand : "") + i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + thousand) +
          (percision ? decimal + Math.abs(value - i).toFixed(percision).slice(2) : "");
      },
	  
	  //This is to add the BG Action Links to the Details Tool Tip
	  _addLinksGISResults: function(layerIndex, results, features) {
		// wrapper object to contain all the parameters for the bgManager.getBGLinks function		
		var LinkParamVO = declare(null, {		
			fieldVals: [],		
			field: "",		
			objName: "",		
			lvLabel: "",		
					
			constructor: function(fieldVals, field, objName, lvLabel) {		
				this.fieldVals = fieldVals;		
				this.field = field;		
				this.objName = objName;		
				this.lvLabel = lvLabel;		
					
			}		
		});		
		var fieldVals = [];
	  	var layerConfig = this.config.layers[layerIndex];
	  	var layerFields = layerConfig.fields.field;
	  	var bgFieldName, bgFieldValue;
        for(var j = 0; j<layerFields.length; j++){
			if(layerFields[j].bgField != null){
				bgFieldName = layerFields[j].bgField;
				attrName = layerFields[j].name
			}
		} // end layerFields loop
        if(results != null && layerConfig.bgObject != null){
			//this.shelter.show();
			var maploader = document.getElementById('jimu_dijit_LoadingShelter_0');
			esri.show(maploader);
			for (var k = 0; k<features.length; k++) {
				var featureIndex = k;
				var feature = features[k];
				if (feature.actionLinks == null) {
					var featureAttributes = feature.attributes;		
					for (var att in featureAttributes) {		
						if(att==attrName){		
							bgFieldValue = featureAttributes[att];		
							break;		
						}			
					}		
					if(bgFieldValue != null && bgFieldValue != ""){		
						fieldVals.push(bgFieldValue);		
					}			
				}
			} // end features loop		
			var params = new LinkParamVO(fieldVals, bgFieldName, layerConfig.bgObject, layerConfig.name);		
			this.bgManager.getBGLinks(params);		
			dojo.subscribe('bgLinkResults_'+layerConfig.name+'_'+layerConfig.bgObject, lang.hitch(this, this._addBGLinks, layerIndex, features));
		}
	  },

	  // Async callback method that captures the action links and places them into the Details Tooltip for GIS Shape search
	  _addBGLinks(layerIndex, features, fullResults) {
			// fullResults[0] is a graphic Id layer, fullResults[1] is the map object returned from controller
			if (fullResults.length > 1) {
				var bgResultMap = fullResults[1];
				var layerConfig = this.config.layers[layerIndex];
				var layerFields = layerConfig.fields.field;
				var bgFieldName, GISFieldName;
				if(layerConfig.bgObject != null){
					for(var j = 0; j<layerFields.length; j++){
						if(layerFields[j].bgField != null){
							bgFieldName = layerFields[j].bgField;
							GISFieldName = layerFields[j].name;		
							break;		
						}		
					}
				}
			}
			console.log(bgResultMap);
			for (var i=0; i<features.length; i++) {
				var feature = features[i];
				var fieldVal = feature.attributes[GISFieldName];
				var bgResult = bgResultMap[fieldVal];		
				if(bgResult!=null && bgResult.length>0){		
					if(bgResult[0].obj[bgFieldName] != null && feature.attributes[GISFieldName] == bgResult[0].obj[bgFieldName]){		
						feature.infoTemplate.info.description += "<br/>";		
						if (isLightning) {
							for (var key in results[i].ltngLinks) {
								templateString += '<a href=\'javascript:void(0);\' onclick=\'getRecordTypes(' + JSON.stringify(results[i].ltngLinks[key]) + ');\'>' + key + '</a><br/><br/>';
							}
					    } else {
						    for( var key in  results[i].actionLinks){
							  templateString += "<a href=\"" + results[i].actionLinks[key]+"\" target=\"_blank\">" + key+ "</a> <br/><br/>";
						    }
						}		
					} 		
				}
			}
			//this.shelter.hide();
			var maploader = document.getElementById('jimu_dijit_LoadingShelter_0');
			esri.hide(maploader);		
	  },

      _drawResults: function (layerIndex, results, currentLayer, closeOnComplete) {
        var layerConfig = this.config.layers[layerIndex];
        if (this.graphicsLayerBuffer instanceof FeatureLayer) {
          this._addOperationalLayer(this.graphicsLayerBuffer);
        }
        if (currentLayer instanceof FeatureLayer) {
          this._addOperationalLayer(currentLayer);
        }

        var type, centerpoint;
		// fetch all the BG Action Links if this object exists in BG		
        this._addLinksGISResults(layerIndex, results, this.currentFeatures);
        for (var i = 0, len = this.currentFeatures.length; i < len; i++) {
          var feature = this.currentFeatures[i];
          var listItem = this.list.items[this._returnListIndexFromOID(feature.attributes[layerConfig.objectIdField])];
          type = feature.geometry.type;
          switch (type) {
          case "multipoint":
          case "point":
            centerpoint = feature.geometry;
            break;
          case "polyline":
            centerpoint = feature.geometry.getPoint(0, 0);
            break;
          case "extent":
          case "polygon":
            centerpoint = feature.geometry.getExtent().getCenter();
            break;
          default:
            break;
          }
          listItem.centerpoint = centerpoint;
          var lyrDisablePopupsAndTrue = (layerConfig.hasOwnProperty("disablePopups") && layerConfig.disablePopups)?true:false;
          if((!this.config.disablePopups && !lyrDisablePopupsAndTrue) && !currentLayer._hasInfoTemplate){
            feature.setInfoTemplate(this._configurePopupTemplate(listItem));
          }
          feature.setSymbol(listItem.sym);
          if (feature.geometry) {
            currentLayer.add(feature);
            listItem.graphic = feature;
          }
        }
        this.zoomAttempt = 0;
        if (layerConfig.shareResult && layerConfig.addToAttrib) {
          if (this.wManager) {
            var widgetCfg = this._getWidgetConfig('AttributeTable');
            if(widgetCfg){
              var attWidget = this.wManager.getWidgetByLabel(widgetCfg.label);
              if(attWidget){
                this.attTableOpenedbySearch = !attWidget.showing;
                this.wManager.openWidget(attWidget);
                attWidget._openTable().then(lang.hitch(this, this._openResultInAttributeTable, currentLayer));
              }else{
                /*Attribute Table Widget is not loaded*/
                this.wManager.loadWidget(widgetCfg).then(lang.hitch(this, function(widget){
                  if(widget){
                    this.attTableOpenedbySearch = true;
                    widget.setPosition(this.getOffPanelWidgetPosition(widget));
                    this.wManager.openWidget(widget);
                    widget._openTable().then(lang.hitch(this, this._openResultInAttributeTable, currentLayer));
                  }
                }));
              }
            }else{
              console.warn('The Attribute Table Widget is not configured in this app.');
              this._zoomAndClose(closeOnComplete);
            }
          }
          if (closeOnComplete) {
            setTimeout(lang.hitch(this, function () {
              this.pManager.closePanel(this.id + '_panel');
            }), 500);
          }
        } else {
          this._zoomAndClose(closeOnComplete);
        }

        if (this.mouseovergraphics) {
          on(currentLayer, 'mouse-over', lang.hitch(this, this.onMouseOverGraphic));
        }
        this.currentLayerAdded = currentLayer;
      },

      _zoomAndClose: function (closeOnComplete) {
        var layerConfig = this.config.layers[this.currentLayerIndex];
        var lyrZoomExistsAndTrue = (layerConfig.hasOwnProperty("autozoomtoresults") && !layerConfig.autozoomtoresults)?false:true;
        if (this.autozoomtoresults && lyrZoomExistsAndTrue) {
          setTimeout(lang.hitch(this, function () {
            this.zoomall();
          }), 300);
        }
        if (closeOnComplete) {
          setTimeout(lang.hitch(this, function () {
            this.pManager.closePanel(this.id + '_panel');
          }), 500);
        }
      },

      _getWidgetConfig: function(widgetName){
        var widgetCnfg = null;
        array.some(this.wManager.appConfig.widgetPool.widgets, function(aWidget) {
          if(aWidget.name == widgetName) {
            widgetCnfg = aWidget;
            return true;
          }
          return false;
        });
        if(!widgetCnfg){
          /*Check OnScreen widgets if not found in widgetPool*/
          array.some(this.wManager.appConfig.widgetOnScreen.widgets, function(aWidget) {
            if(aWidget.name == widgetName) {
              widgetCnfg = aWidget;
              return true;
            }
            return false;
          });
        }
        return widgetCnfg;
      },

      getOffPanelWidgetPosition: function(widget){
        var position = {
          relativeTo: widget.position.relativeTo
        };
        var pbox = html.getMarginBox(this.domNode);
        var sbox = this.widgetManager.getWidgetMarginBox(widget);
        var containerBox = html.getMarginBox(position.relativeTo === 'map'?
          this.map.id: jimuConfig.layoutId);

        var top = pbox.t + pbox.h + 1;//put under icon by default
        if(top + sbox.h > containerBox.h){
          position.bottom = containerBox.h - pbox.t + 1;
        }else{
          position.top = top;
        }

        if (window.isRTL) {
          if(pbox.l + pbox.w - sbox.w < 0){
            position.right = 0;
          }else{
            position.right = pbox.l + pbox.w - sbox.w;
          }
        } else {
          if(pbox.l + sbox.w > containerBox.w){
            position.right = 0;
          }else{
            position.left = pbox.l;
          }
        }
        return position;
      },

      _searchResultListByOID: function (OID) {
        var layerConfig = this.config.layers[this.currentLayerIndex];
        var lyrHasPopupDisabled = (layerConfig.hasOwnProperty("disablePopups") && layerConfig.disablePopups)?true:false;
        for (var i = 0; i < this.list.items.length; i++) {
          var item = this.list.items[i];
          var point = item.centerpoint;
          if (item.OID === OID) {
            var itemDom = dojo.byId(this.list.id.toLowerCase() + item.id);
            if(itemDom){
              itemDom.scrollIntoView(false);
            }
            this.list.setSelectedItem(this.list.id.toLowerCase() + item.id);
            if ((this.map.infoWindow && this.config.enablePopupsOnResultClick) && !lyrHasPopupDisabled) {
              this.map.infoWindow.setFeatures([item.graphic]);
              if (this.map.infoWindow.reposition) {
                this.map.infoWindow.reposition();
              }
              this.map.infoWindow.show(point);
            }
          }
        }
      },

      onMouseOverGraphic: function (evt) {
        var layerConfig = this.config.layers[this.currentLayerIndex];
        var oidField = layerConfig.objectIdField;
        this._searchResultListByOID(evt.target.e_graphic.attributes[oidField]);
      },

      _configurePopupTemplate: function (listItem) {
        var popUpInfo = {
          title: listItem.title,
          description: listItem.content,
          showAttachments: true
        };
        var pminfos = [];
        var popUpMediaInfo;

        for (var l = 0; l < listItem.links.length; l++) {
          if (listItem.links[l].link) {
            var pos = listItem.links[l].link.length - 4;
            var sfx = String(listItem.links[l].link).substr(pos, 4).toLowerCase();
            if (((sfx === ".jpg") || (sfx === ".png") || (sfx === ".gif")) && listItem.links[l].popuptype !== "text") {
              // use PopUpMediaInfo if it is an image
              if (!listItem.links[l].disableinpopup) {
                popUpMediaInfo = {};
                popUpMediaInfo.type = "image";
                var val = {};
                val.sourceURL = listItem.links[l].link;
                val.linkURL = listItem.links[l].link;
                popUpMediaInfo.value = val;
                popUpMediaInfo.caption = listItem.links[l].alias;
                pminfos.push(popUpMediaInfo);
              }
            } else if (listItem.links[l].icon !== "" && listItem.links[l].popuptype !== "text") {
              if (!listItem.links[l].disableinpopup) {
                popUpMediaInfo = {};
                popUpMediaInfo.type = 'image';
                popUpMediaInfo.value = {};
                popUpMediaInfo.value.sourceURL = listItem.links[l].icon;
                popUpMediaInfo.value.linkURL = listItem.links[l].link;
                popUpMediaInfo.caption = listItem.links[l].alias;
                pminfos.push(popUpMediaInfo);
              }
            } else {
              if (!listItem.links[l].disableinpopup) {
                var lText = (listItem.links[l].alias !== "") ? listItem.links[l].alias : listItem.links[l].link;
                popUpInfo.description += "<br><a href='" + listItem.links[l].link + "'>" + lText + "</a>";
              }
            }
          }
        }
        if (pminfos.length > 0) {
          popUpInfo.mediaInfos = pminfos;
        }
        var bgInfoTemplate = "<div>Show nearby <select id=\"bgSearchInfoSelect\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + this.featureLayersString + this.bgLayersString + "</select>" +
			    "<br> Within <input id=\"bufferRadiusValue\" style=\"width:80px;\" type=\"number\" value=\"1000\"> " +
			    "<select id=\"bufferRadiusUnitSelect\" style=\"width:130px;\" dojoType='dijit/form/Select'>" + this._parseBufferUnits() + "</select>" +
			    "<br> <button id='btnGo' onClick='var selectList = dojo.byId(\"bgSearchInfoSelect\"); var pickValue = selectList.value; var bufferValueSelect = dojo.byId(\"bufferRadiusValue\"); var bufferValue = bufferValueSelect.value; var bufferUnitSelectList = dojo.byId(\"bufferRadiusUnitSelect\"); var bufferUnit = bufferUnitSelectList.value; var msg = new Object(); msg.bufferUnit = bufferUnit; msg.bufferValue = bufferValue; msg.pickValue = pickValue; dojo.publish(\"searchWidgetEvent\", [msg]);' dojoType='dijit/form/Button'>Go</button> </div>";
        popUpInfo.description += bgInfoTemplate;
        //        console.info(popUpInfo);
        var pt = new PopupTemplate(popUpInfo);
        return pt;
      },

      _selectResultItem: function (index, item) {
        var point = item.centerpoint;
        var layerConfig = this.config.layers[this.currentLayerIndex];
        var lyrHasPopupDisabled = (layerConfig.hasOwnProperty("disablePopups") && layerConfig.disablePopups)?true:false;
        var zoomScale = layerConfig.zoomScale || 10000;
        if (item.graphic.geometry.type === "point") {
          if ((this.map.getScale() > zoomScale || layerConfig.forceZoomScale) && !lyrHasPopupDisabled) {
            this.map.setScale(zoomScale).then(lang.hitch(this, this.map.centerAt(point).then(lang.hitch(this, function () {
              if (this.map.infoWindow && this.config.enablePopupsOnResultClick) {
                this.map.infoWindow.setFeatures([item.graphic]);
                if (this.map.infoWindow.reposition) {
                  this.map.infoWindow.reposition();
                }
                this.map.infoWindow.show(point);
              }
            }))));
          } else {
            this.map.centerAt(point).then(lang.hitch(this, function () {
              if ((this.map.infoWindow && this.config.enablePopupsOnResultClick) && !lyrHasPopupDisabled) {
                this.map.infoWindow.setFeatures([item.graphic]);
                if (this.map.infoWindow.reposition) {
                  this.map.infoWindow.reposition();
                }
                this.map.infoWindow.show(point);
              }
            }));
          }
        } else {
          var gExt = graphicsUtils.graphicsExtent([item.graphic]);
          if (gExt && !layerConfig.forceZoomScale) {
            this.map.setExtent(gExt.expand(1.5), true).then(lang.hitch(this, function () {
              if ((this.map.infoWindow && this.config.enablePopupsOnResultClick) && !lyrHasPopupDisabled) {
                this.map.infoWindow.setFeatures([item.graphic]);
                if (this.map.infoWindow.reposition) {
                  this.map.infoWindow.reposition();
                }
                this.map.infoWindow.show(point);
              }
            }));
          } else {
            if (this.map.getScale() > zoomScale || layerConfig.forceZoomScale) {
              this.map.setScale(zoomScale).then(lang.hitch(this, this.map.centerAt(point).then(lang.hitch(this, function () {
                if ((this.map.infoWindow && this.config.enablePopupsOnResultClick) && !lyrHasPopupDisabled) {
                  this.map.infoWindow.setFeatures([item.graphic]);
                  if (this.map.infoWindow.reposition) {
                    this.map.infoWindow.reposition();
                  }
                  this.map.infoWindow.show(point);
                }
              }))));
            } else {
              this.map.centerAt(point).then(lang.hitch(this, function () {
                if ((this.map.infoWindow && this.config.enablePopupsOnResultClick) && !lyrHasPopupDisabled) {
                  this.map.infoWindow.setFeatures([item.graphic]);
                  if (this.map.infoWindow.reposition) {
                    this.map.infoWindow.reposition();
                  }
                  this.map.infoWindow.show(point);
                }
              }));
            }
          }
        }
      },

      _hideInfoWindow: function () {
        if (this.map && this.map.infoWindow) {
          this.map.infoWindow.hide();
        }
      },

       /** Take filtered results and show on the map*/
      _drawBGResults: function(results) {
        
        //hide loading bar, show results div
        html.setStyle(this.progressBar.domNode,'display','none');
        html.setStyle(this.divOptions, 'display', 'block');
        var graphL = new GraphicsLayer();
        // results[0] is always the Id of the graphics layer
        graphL.id = results[0];

        var sym;
        if (results.length > 1) {
          sym = new PictureMarkerSymbol(this._getBGIcon(results), 24, 24);
        }

        var attr;
        var infoTemplate;
        var newGraphic;

        // add BG layer to Result Tab on widget
        var len = results.length;
        if (len <=1) {
          this.divResultMessage.textContent = this.nls.noResults;
          // reset zoom on load 
          if (zoomOnLoad == 'true') {
            zoomOnLoad = 'false';
          }
          return;
        } else {
          this.divResultMessage.textContent = this.nls.featuresSelected + (len - 1).toString();
        }

		var csvColumns = [];		
        var csvData = this.currentCSVResults || [];		
        // create the CSV colums		
        var fields = this.bgFields;		
        for (var j = 0; j< fields.length; j++) {		
          csvColumns.push(fields[j].label);		
        }
		
        // iterate through results and create Points and the tool-tip

        for (var i = 1; i < len; i++) {
          var po = new Point(results[i].lon, results[i].lat, this.map.spatialReference);			
			    attr = results[i].obj;
          var label = "";
          var content = "";
          var title = "";
          var templateString = "";
          var bufferOptions = this._parseBufferUnits();
		  var csvRow = {};
          templateString += "<a id = 'bgObjectLinkSearch' href=\"/" + results[i].obj.Id + "\" target=\"_blank\">View Details</a><br/><br/>";
          // iterate through fields and add values to template string and to the csv data
          for (var k=0; k<fields.length; k++) {
            var key = fields[k];
            var val = results[i].obj[key.path];
            
            // formatting
            var dtype = key.datatype.toUpperCase();
            if (dtype === 'DATE' || dtype === 'DATETIME') {		
              if (val) {		
                var date = new Date(val); // dates from salesforce come in UTC Timezone, but JS tried to parse as if they're local timezone, so have to add the offset		
                var offset = date.getTimezoneOffset();		
                date = date.setMinutes(date.getMinutes() + offset);		
                val = this._formatDate(date, 'MM/dd/yyyy');		
              }		
             		
            }
            if (dtype === 'REFERENCE') {		
              var path = '';		
              var obj = null;
              if (key.path.includes('__c')) {		
                path = key.path.replace('__c', '__r');		
                obj = results[i].obj[path];		
                val = (obj)? obj.Name : '';	
              } else {		
				key.label = key.label.replace('ID','');
                path = key.path.replace('Id', '');
                obj = results[i].obj[path];	
                val = (obj)? obj.Alias: ''; 		
              }		
            
            }	
			
            if (dtype === 'DOUBLE' || dtype === 'INTEGER') {		
              if (val) {		
                val = val.toString();		
              }		
            }		
            // have to remove : character from val because List.js parses it out 		
            if (val && val.length > 0) {		
              templateString += this.resultFormatString.replace('[attribname]', key.label).replace('[attribvalue]', val.replace(':', '-'));		
              label += this.resultFormatString.replace('[attribname]', key.label).replace('[attribvalue]', val.replace(':', '-'));		
            } 		
            csvRow[key.label] = val;		
          }
          templateString += "<br/>";
          
		  //add action links - check if user is in Lightning experience. Action links are formatted differently in LEX vs SF Classic
		  if (isLightning) {
            for (var key in results[i].ltngLinks) {
              templateString += '<a href=\'javascript:void(0);\' onclick=\'getRecordTypes(' + JSON.stringify(results[i].ltngLinks[key]) + ');\'>' + key + '</a><br/><br/>';
            }
          } else {
            for( var key in  results[i].actionLinks){
              templateString += "<a href=\"" + results[i].actionLinks[key]+"\" target=\"_blank\">" + key+ "</a> <br/><br/>";
            }
          }
		  
		  /* Not using Assign To User function now.
          // User assignment, default is current user
          var bgOwnerId = results[i].ownerId;
          var userOptionString = this.bgAllUsersString;
          if(userOptionString.indexOf(bgOwnerId) != -1)
          {
            userOptionString = userOptionString.replace("\""+bgOwnerId+"\"","\""+bgOwnerId+"\""+" selected = \"true\"");
          } 
          templateString += "Assignee&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<select id=\"bgSearchAssignToUser\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + userOptionString + "</select>" +
			    " <button id='btnAssignUserSearch' onClick='var selectListUser = dojo.byId(\"bgSearchAssignToUser\"); var pickValueUser = selectListUser.value; var objectLink = dojo.byId(\"bgObjectLinkSearch\"); var objectId = objectLink.href.split(\"visual.force.com\/\")[1]; var params = []; params.push(objectId); params.push(pickValueUser); dojo.publish(\"assignToUserEventBGSearch"+"\", [params]);' dojoType='dijit/form/Button'>Assign</button> <br/><br/>";	
          templateString += "<a href=\"javascript:void(0);\" onClick='var objectLink = dojo.byId(\"bgObjectLinkSearch\"); var objectId = objectLink.href.split(\"visual.force.com\/\")[1]; var params = []; params.push(objectId); params.push(currentUserId); dojo.publish(\"assignToUserEventBGSearch"+"\", [params]);' >Assign to me </a> <br/><br/>";
		  */
          // Show Nearby
          templateString += "Show nearby <select id=\"bgSearchInfoSelect\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + this.featureLayersString + this.bgLayersString + "</select>" +
			    "<br> Within <input id=\"bufferRadiusValue\" style=\"width:80px;\" type=\"number\" value=\"1000\"> " +
			    "<select id=\"bufferRadiusUnitSelect\" style=\"width:130px;\" dojoType='dijit/form/Select'>" + bufferOptions + "</select>" +
			    "<br> <button id='btnGo' onClick='var selectList = dojo.byId(\"bgSearchInfoSelect\"); var pickValue = selectList.value; var bufferValueSelect = dojo.byId(\"bufferRadiusValue\"); var bufferValue = bufferValueSelect.value; var bufferUnitSelectList = dojo.byId(\"bufferRadiusUnitSelect\"); var bufferUnit = bufferUnitSelectList.value; var msg = new Object(); msg.bufferUnit = bufferUnit; msg.bufferValue = bufferValue; msg.pickValue = pickValue; dojo.publish(\"searchWidgetEventBG\", [msg]);' dojoType='dijit/form/Button'>Go</button> ";

          infoTemplate = new InfoTemplate("Information", templateString);
          newGraphic = new Graphic(po, sym, attr, infoTemplate);
          graphL.add(newGraphic);

          // add to results list - Search2 was using label: label.slice(0,-2), but I don't know why - keeping as just label for now.
          this.list.add({
            id: "id_" + (i-1).toString(),
            title: title,
            content: templateString,
            rsltcontent: label.slice(0, -4), // remove the last <br> tag from label
            alt: ((i-1) % 2 === 0),
            sym: sym,
            removeResultMsg: this.nls.removeResultMsg,
            bgid: graphL.id
          });
          this.list.items[i-1].graphic = newGraphic;
          this.list.items[i-1].content = templateString;
		  this.list.items[i-1].centerpoint = po;
		  csvData.push(csvRow);
        }
		this.currentCSVResults = {		
          data: csvData,		
          columns: csvColumns		
        };
        this.map.addLayer(graphL);
        console.debug("*** Search Finish.");

        this._bgZoomToPoint();

      },
      
      _parseBufferUnits: function() {
        var opts = this.bufferUnits.options;
        var optString = "";
        for (var i=0; i<opts.length; i++) {
          if (i===0) {
            optString += "<option selected='true' value='" + opts[i].value + "'>" + opts[i].label + "</option>";  
          } else {
            optString += "<option value='" + opts[i].value + "'>" + opts[i].label + "</option>";  
          } 
        }
        return optString;
      },

      /** Clear results from BG Search */
      _clearBGSearchLayer: function() {
        var layerIds = this.map.graphicsLayerIds;
		    var layer;
        for(var i = 0 ; i < layerIds.length; i++){
          if(layerIds[i].indexOf('_bgSearch') != -1 || layerIds[i].indexOf('bgDefaultObjectToZoom') != -1 || layerIds[i].indexOf('directionRecordResults') != -1){
            layer = this.map.getLayer(layerIds[i]);
            this.map.removeLayer(layer);
          }
        }
      },

      _clearCircle: function() {
        var circleLayer = this.map.getLayer("circles");
		    if (circleLayer) this.map.removeLayer(circleLayer);
      },

      /** get the icon for the features based on the icon path specified for hte layer in config.json */
      _getBGIcon: function(results) {
        // tries to find a path to an icon in this.config and if one isn't provided, then use the iconUrl returned from Apex Controller
		var layerObjName = results[0].split('__c')[0] + '__c';
		var layerConfig = this.config.layers.find(function(layer){		
          return layer.url === layerObjName;		
        });		
        var path;		
        if (layerConfig.iconPath && layerConfig.iconPath.length > 0) {		
          path = this.folderUrl + layerConfig.iconPath;		
        } else {		
          path = results[1].iconUrl;		
        }		
        return path;		
      },

      /** helper to convert to valid html string */
      _htmlDecode: function(string) {
        var e = document.createElement('div');
	      e.innerHTML = string;
		    return e.childNodes.length === 0 ? "" : e.childNodes[0].nodeValue;
      },

      _bgZoomToPoint: function() {

        // BG if zoomOnLoad == true, zoom to the first point
        if (zoomOnLoad == 'true' && this.list.items.length > 0) {
          // zoom to the first result
          this.list.selectedIndex = 0;
			    this._selectResultItem(0, this.list.items[0]); 
          //reset zoom on load
          zoomOnLoad = 'false';
        }
      },

      _isBGError: function(result) {
        if(result.indexOf('Exception:') != -1) {
          new Message({
            message: result
          });
          this.shelter.hide();
          return true;
        } else {
          return false;
        }
      },
      bufferSearchInSearchWidget:function(msg){
        var bufferUnit = msg.bufferUnit;
        var bufferValue = msg.bufferValue;
        var pickValue = msg.pickValue;
        this.geometryForBGRegularSearch = null;
        console.debug('*** Buffer search...');
        html.setStyle(this.progressBar.domNode,'display','block');
        //html.setStyle(this.divResult,'display','none');
        this.clear();
        var layerString = pickValue;
        
        // get centre point for selected graphic
        var selectedGraphic = this.map.graphics.graphics[0];
        var selectedX;
        if(selectedGraphic.geometry['x']){
          selectedX = selectedGraphic.geometry['x'];	
        } else if(selectedGraphic._extent.type == 'extent'){
          selectedX = (selectedGraphic._extent.xmax + selectedGraphic._extent.xmin)/2
        }
        var selectedY;
        if(selectedGraphic.geometry['y']){
          selectedY = selectedGraphic.geometry['y'];
        } else if(selectedGraphic._extent.type == 'extent') {
          selectedY = (selectedGraphic._extent.ymax + selectedGraphic._extent.ymin)/2
        }
         // parse excess characters out of buffer unit
        var lastIndex = bufferUnit.lastIndexOf('_');
        var unit = bufferUnit.slice(lastIndex + 1) + 'S';
        if (unit === "FOOTS") unit = "FEET";
        // create circle
        var circleSymb = new SimpleFillSymbol().setColor(null).outline.setColor("blue");
        var gl = new GraphicsLayer({ id: "circles" });
        var pt = new Point(selectedX, selectedY, this.map.spatialReference);
        var circle = new Circle({
          center: pt,
          //geodesic: true, /*This attribute does not work if the current spatial reference is not wkid 4326*/
          radius: bufferValue,
          radiusUnit: esriUnits[unit]
          });
        var g = new Graphic(circle, circleSymb);
        gl.add(g);
        // add circle to map
        this.map.addLayer(gl);
        
        this.geometryForBGRegularSearch = g.geometry;
        
        // BG search
        if(layerString.indexOf('basicgov/') != -1){
          this._clearBGSearchLayer();
		  if(!this.basicgovLayerSelected)
          {
          	this.basicgovLayerSelected = true;
          }
		  for (var i in this.config.layers) {		
            if (layerString.includes(this.config.layers[i].url)) {		
              this.currentLayerIndex = i; break;		
            }		
          }
          this.search(g.geometry, this.currentLayerIndex, null, null, true, null, true, layerString);
        
        // GIS search
        } else if(layerString.indexOf('https://') != -1){
          var layerIndex;
		  if(this.basicgovLayerSelected)
          {
          	this.basicgovLayerSelected = false;
          }
          for(var i in this.config.layers) {
            if (this.config.layers[i].url == layerString) {
              layerIndex = i; break;
            }
          }
          this.currentLayerIndex = layerIndex;
          this.search(g.geometry, layerIndex, null, null ,null, false, true, layerString);
        }
      },

      // },
      //
      // _addThemeFixes: function () {
      //   /*Workaround for the LanunchPad theme not firing onClose and onOpen for the widget*/
      //   if(this.appConfig.theme.name === "LaunchpadTheme"){
      //     var tPanel = this.getPanel();
      //     if(tPanel){
      //       aspect.after(tPanel, "onClose", lang.hitch(this, this.onClose));
      //       aspect.after(tPanel, "onOpen", lang.hitch(this, this.onOpen));
      //     }
      //   }
      //   /*end work around for LaunchPad*/
      //   /*Workaround for TabTheme moregroup not calling onClose and onOpen when the SidebarController is minimized*/
      //   if(this.appConfig.theme.name === "TabTheme"){
      //     var sidebarWidget = this.wManager.getWidgetsByName('SidebarController');
      //     if (sidebarWidget[0]) {
      //       aspect.after(sidebarWidget[0], "onMinimize", lang.hitch(this, this.onClose));
      //       aspect.after(sidebarWidget[0], "onMaximize", lang.hitch(this, this.onOpen));
      //     }
      //   }
      // }

    });
  });
