
//Wei Zhang
define([
    'dojo/_base/declare',
    'dijit/_WidgetsInTemplateMixin',
    'jimu/BaseWidget',
    'jimu/dijit/TabContainer',
    'jimu/dijit/List',
    'jimu/dijit/Message',
    'jimu/utils',
    'jimu/tokenUtils',
	'jimu/WidgetManager',
    'esri/tasks/QueryTask',
    'esri/layers/GraphicsLayer',
    'esri/layers/FeatureLayer',
    'esri/graphic',
	'esri/units',
    'esri/geometry/Point',
	'esri/geometry/Circle',
    'esri/symbols/SimpleMarkerSymbol',
    'esri/symbols/PictureMarkerSymbol',
    'esri/geometry/Polyline',
    'esri/symbols/SimpleLineSymbol',
    'esri/geometry/Polygon',
    'esri/symbols/SimpleFillSymbol',
    'esri/toolbars/draw',
    'esri/InfoTemplate',
    'esri/request',
    'dijit/ProgressBar',
    'dojo/_base/lang',
    'dojo/on',
    'dojo/_base/html',
    'dojo/_base/array',
    'dojo/promise/all',
    'dijit/form/Select',
    'dijit/form/TextBox',
    'jimu/dijit/DrawBox',
    'jimu/dijit/LoadingShelter',
    'dojo/dom-construct',
    'dojo/dom-geometry',
    'dojo/dom',
    'dojo/_base/unload',
    'dojo/aspect',
    'dojo/query',
	'dojo/date',		
	'dojo/date/locale',
    'jimu/dijit/Selectionbox',
    './LayerListView',
    './PopupMenu',
    'dojo/dom-style',
    './NlsStrings',
    './LayerInfos',
	'jimu/dijit/CheckBox',
	'dojo/_base/Color',
	'esri/InfoTemplate',
	'dijit/form/Button',
	'esri/tasks/GeometryService',
    'esri/tasks/BufferParameters',
	'esri/SpatialReference'
  ],
  function(
    declare, _WidgetsInTemplateMixin, BaseWidget,TabContainer, List, Message, utils, tokenUtils, WidgetManager, QueryTask, GraphicsLayer, FeatureLayer,
    Graphic, esriUnits, Point, Circle, SimpleMarkerSymbol, PictureMarkerSymbol, Polyline, SimpleLineSymbol, Polygon, SimpleFillSymbol, Draw, InfoTemplate,
    esriRequest,ProgressBar, lang, on, html, array, all, Select, TextBox, DrawBox,LoadingShelter, domConstruct, domGeometry, dom, baseUnload, aspect, query, date, locale, 
	Selectionbox, LayerListView,PopupMenu, domStyle, NlsStrings, LayerInfos, topic, Deferred, CheckBox, Color, InfoTempalte, Button, GeometryService, BufferParameters, SpatialReference) {/*jshint unused: false*/
    return declare([BaseWidget, _WidgetsInTemplateMixin], {
      name: 'LayerList2',
      baseClass: 'jimu-widget-layerList',
      tabContainer: null,
	  layerListView: null,
	  bgLayerListView: null,
	  operLayerInfos: null,
	  objectNames: [],
	  bgManager: null,
	  bgLayersString:"",
	  featureLayersString:"",
	  bgAllUsersString:"",
	  symbolArray:["esriSMSCircle", "esriSMSDiamond", "esriSMSCross", "esriSMSSquare"],
	  isBufferSearch: null,
	  geometryForBGRegularSearch: null,
	  bgFields : null,
	  isBGRouting: false,
	  isBGLayerRouted: false,
	  
	  startup: function() {
        NlsStrings.value = this.nls;
        // summary:
        //    this function will be called when widget is started.
        // description:
        //    according to webmap or basemap to create LayerInfos instance and initialize operLayerInfos 
        //    show layers list
        //    bind events of layerList and create popup menu.
        var mapLayers;
		
        if (this.map.itemId) {
          this.operLayerInfos = new LayerInfos(this.map.itemInfo.itemData.baseMap.baseMapLayers, this.map.itemInfo.itemData.operationalLayers, this.map);
        } else {
          mapLayers = this._obtainMapLayers();
          this.operLayerInfos = new LayerInfos(mapLayers.basemapLayers, mapLayers.operationalLayers, this.map);
        }		
		this.shelter.show();
		this.bgManager = new BGManager();
		this.bgManager.getAllUsersLayerList(); // comment this when removing the assign to functionality
		/* to put the Assign to User functionality back in, remove everything after this comment and uncomment out the getBGUsers(); */		
		/*this.buildInfoTemplateOptionString();		
		this.buildBGLayerList();		
		this.showLayers();		
        this.bindEvents();			
        dom.setSelectable(this.layersSection, false);*/
      },
  		
	  postMixInProperties: function(){		
        this._resetUnitsArrays();		
      },
	  
      postCreate:function(){
		this._initUnitSelect();
		this.inherited(arguments);
		//Check the subscribers map first prevent to subscribe too many times
		if(dojoSubscribersMap['proximitySearchEventBG'+'bgLayerBufferQuery'+'LayerList2'] != true){
			dojo.subscribe('proximitySearchEventBG', lang.hitch(this, this.bgLayerBufferQuery));
			dojoSubscribersMap['proximitySearchEventBG'+'bgLayerBufferQuery'+'LayerList2'] = true;
		}
		if(dojoSubscribersMap['listViews_layerList'+'createDomForBGLayers'+'LayerList2'] != true){
			dojo.subscribe('listViews_layerList', lang.hitch(this, this.createDomForBGLayers));
			dojoSubscribersMap['listViews_layerList'+'createDomForBGLayers'+'LayerList2'] = true;
		}
		if(dojoSubscribersMap['proximitySearchEvent'+'bgLayerBufferQuery'+'LayerList2'] != true){
			dojo.subscribe('proximitySearchEvent', lang.hitch(this, this.bgLayerBufferQuery));
			dojoSubscribersMap['proximitySearchEvent'+'bgLayerBufferQuery'+'LayerList2'] = true;
		}
		
		//comment below 3 subscribes to remove assign to functionality
		if(dojoSubscribersMap['allUsers_layerList'+'getBGUsers'+'LayerList2'] != true){
			dojo.subscribe('allUsers_layerList', lang.hitch(this, this.getBGUsers));
			dojoSubscribersMap['allUsers_layerList'+'getBGUsers'+'LayerList2'] = true;
		}
	    if(dojoSubscribersMap['assignToUserEventBG'+'assignToBGUser'+'LayerList2'] != true){
			dojo.subscribe('assignToUserEventBG', lang.hitch(this, this.assignToBGUser));
			dojoSubscribersMap['assignToUserEventBG'+'assignToBGUser'+'LayerList2'] = true;
		}
		if(dojoSubscribersMap['assignToUser_layerList'+'onAssignFinish'+'LayerList2'] != true){
			dojo.subscribe('assignToUser_layerList', lang.hitch(this, this.onAssignFinish));
			dojoSubscribersMap['assignToUser_layerList'+'onAssignFinish'+'LayerList2'] = true;
		}
      },
	  
	  //comment below 3 methods to remove assign to functionality
	  getBGUsers: function(results) {
		//console.debug('***** All users');
		//console.dir(results);
		for(var i = 0; i< results.length; i++)
		{							
			this.bgAllUsersString += "<option value=\"" + results[i].Id + "\">" + results[i].Name + "</option>";
		}
		//console.debug(this.bgAllUsersString);
		this.buildInfoTemplateOptionString();
		this.buildBGLayerList();
		this.showLayers();
        this.bindEvents();	
        dom.setSelectable(this.layersSection, false);
	  },
	  
	  assignToBGUser: function(params) {
		console.debug("*** Params" + params);
		this.shelter.show();
		this.bgManager.assignToUserLayerList(params[0], params[1]);
	  },
	  
	  onAssignFinish: function(result) {
		new Message({
		  message: result
		});
		this.shelter.hide();
		this._hideInfoWindow();
	  },

      onClose: function() {
        this.inherited(arguments);
      },

      destroy:function(){
	    this._clearLayers();
        this.inherited(arguments);
      },
	  
	  _obtainMapLayers: function() {
        // summary:
        //    obtain basemap layers and operational layers if the map is not webmap.
        var basemapLayers = [],
          operLayers = [],
          layer;
        array.forEach(this.map.layerIds.concat(this.map.graphicsLayerIds), function(layerId) {
          layer = this.map.getLayer(layerId);
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
        return {
          basemapLayers: basemapLayers || [],
          operationalLayers: operLayers || []
        };
      },
	  
	  showLayers: function() {
        // summary:
        //    create a LayerListView module used to draw layers list in browser.
        this.layerListView = new LayerListView({
          operLayerInfos: this.operLayerInfos,
          layerListTable: this.layerListTable,
          layerListWidget: this,
          config: this.config
        }).placeAt(this.layerListTable);
      },
	  
	  _createPopupMenu: function() {
        // summary:
        //    popup menu is a dijit used to do some operations of layer
        this.popupMenu = new PopupMenu({
          layerListWidget: this
        });
        domConstruct.place(this.popupMenu.domNode, this.domNode);
      },
	  
	  moveUpLayer: function(id) {
        // summary:
        //    move up layer in layer list.
        // description:
        //    call the moveUpLayer method of LayerInfos to change the layer order in map, and update the data in LayerInfos
        //    then, change layerNodeTr and layerContentTr domNode
        var beChangedId = this.operLayerInfos.moveUpLayer(id);
        if(beChangedId) {
          this._exchangeLayerTrNode(beChangedId, id);
        }
      },
	  
	  moveDownLayer: function(id) {
        // summary:
        //    move down layer in layer list.
        // description:
        //    call the moveDownLayer method of LayerInfos to change the layer order in map, and update the data in LayerInfos
        //    then, change layerNodeTr and layerContentTr domNode
        var beChangedId = this.operLayerInfos.moveDownLayer(id);

        if(beChangedId) {
          this._exchangeLayerTrNode(id, beChangedId);
        }
      },
	  
	  // befor exchange:  id1 -> id2
      // after exchanged: id2 -> id1
      _exchangeLayerTrNode: function(id1, id2) {
        var layer1TrNode = query("tr[layerTrNodeId='" + id1 + "']", this.layerListTable)[0];
        //var layer1ContentTrNode = query("tr[layerContentTrNodeId='" + id1 + "']", this.layerListTable)[0];
        var layer2TrNode = query("tr[layerTrNodeId='" + id2 + "']", this.layerListTable)[0];
        var layer2ContentTrNode = query("tr[layerContentTrNodeId='" + id2 + "']", this.layerListTable)[0];
        // change layerTr
        this.layerListTable.removeChild(layer2TrNode);
        this.layerListTable.insertBefore(layer2TrNode, layer1TrNode);
        // change LayerContentTr
        this.layerListTable.removeChild(layer2ContentTrNode);
        this.layerListTable.insertBefore(layer2ContentTrNode, layer1TrNode);
      },
	  
	  _clearLayers: function() {
        // summary:
        //    clear layer list 
        domConstruct.empty(this.layerListTable);
		//BG, If we clear BG layer, when we open Search, BG layer will gone, do not know why
		//domConstruct.empty(this.bgLayerListTable);
      },
	  
	  _createEmptyRow: function() {
        // summary:
        //    the purpose is layer list format 
        var node = domConstruct.create('tr', {
          'class': 'jimu-widget-row-selected'
        }, this.layerListTable);

        domConstruct.create('td', {
          'class': 'col col-showLegend'
        }, node);
        domConstruct.create('td', {
          'class': 'col-select'
        }, node);

        domConstruct.create('td', {
          'class': 'col-layer-label'
        }, node);
        domConstruct.create('td', {
          'class': 'col col-popupMenu'
        }, node);
      },
	  
	  bindEvents: function() {
        // summary:
        //    bind events are listened by this module
        var handleRemove, handleRemoves;
        this.own(aspect.after(this.map, "onLayerAddResult", lang.hitch(this, this._onLayersChange)));
        handleRemove = aspect.after(this.map, "onLayerRemove", lang.hitch(this, this._onLayersChange));
        this.own(handleRemove);
        //aspect.after(this.map, "onLayerReorder", lang.hitch(this, this._onLayersChange));
        this.own(aspect.after(this.map, "onLayersAddResult", lang.hitch(this, this._onLayersChange)));
        handleRemoves =  aspect.after(this.map, "onLayersRemoved", lang.hitch(this, this._onLayersChange));
        this.own(handleRemoves);
        //aspect.after(this.map, "onLayersReorder", lang.hitch(this, this._onLayersChange));

        baseUnload.addOnUnload(function(){
          handleRemove.remove();
          handleRemoves.remove();
        });
      },
	  
	  _onLayersChange: function(evt) {
        /*jshint unused: false*/
        // summary:
        //    response to any layer change.
        // description:
        //    udate LayerInfos data, cleare layer list and redraw
        this.operLayerInfos.update();
        this._clearLayers();
        this.showLayers();
      },
	  
	  buildInfoTemplateOptionString: function(){
		var len = this.config.layers.length;
		for(var i = 0; i < len; i++) {
			if(this.config.layers[i].type == 'basicgov'){
				this.objectNames.push(this.config.layers[i].url);
			} else if(this.config.layers[i].type == 'feature'){
				var	optionValue = this.config.layers[i].label+'_feature';
				var	optionLabel = this.config.layers[i].label;
				this.featureLayersString += "<option value=\"" + optionValue + "\">" + optionLabel + "</option>";
			}
		}
	  },

	  /** Check if there is Token Authentication, if yes return token */
	  checkTokenAuth: function(){
	  	if(this.appConfig.tokenInfo && this.appConfig.tokenInfo.tokenServicesUrl && this.appConfig.tokenInfo.tokenServicesUrl != '' && this.appConfig.tokenInfo.serviceUrl && this.appConfig.tokenInfo.serviceUrl != ''){
	  		var cred = tokenUtils.getPortalCredential(this.appConfig.tokenInfo.serviceUrl);
	  		if(cred != null)
	    		return cred.token;
	    	else return '';
	  	}
	  	return '';
	  },
	  
	  addLayersToMap: function(){
		var len = this.config.layers.length;
		for(var i = 0; i < len; i++) {
			//BG we only need to add GIS feature layer
			if(this.config.layers[i].type == 'feature'){
				
				/*var templateString = "Show nearby <select id=\"cboProximityObjects\" style=\"\" dojoType='dijit/form/Select'>" + this.featureLayersString + this.bgLayersString + "</select>" +
					" <button id='btnGo' onClick='var selectList = dojo.byId(\"cboProximityObjects\"); var pickValue = selectList.value; dojo.publish(\"proximitySearchEvent"+"\", pickValue);' dojoType='dijit/form/Button'>Go</button> ";*/
				//var featureLayerTemplate = new InfoTemplate("Information", "${*}");
						
				var featureURL = this.config.layers[i].url;
						
				//if the fieldInfos are defined in config.json then create PopupTemplate, then set FeatureLayer infoTemplate		
				var fieldInfos = this.config.layers[i].fieldInfos;		
				var featureLayerTemplate=null;		
				if(fieldInfos &&  fieldInfos.length > 0)		
				{		
					var popupInfo = {		
					  title: this.config.layers[i].label,		
					  fieldInfos: fieldInfos		
					};		
					featureLayerTemplate = new esri.dijit.PopupTemplate(popupInfo);		
				}
				
				// Check if token auth is required, if yes then append the token to the Feature Layer's url
				var token = this.checkTokenAuth();
				if(token && token != ''){
					featureURL += '?token=' + token;
				}
				
				//Now, only show the Parcel Layer by default ---> Not used right now
				var showLayer = false;
				/*if(this.config.layers[i].label.indexOf('Parcel') != -1 || this.config.layers[i].label.indexOf('parcel') != -1){
					showLayer = true;
				}*/
				var featureLayer = new FeatureLayer(featureURL,{
					name:this.config.layers[i].label,
					outFields: ["*"],
					infoTemplate: featureLayerTemplate,
					visible: showLayer,
					id: this.config.layers[i].label+'_feature'
				});
				/*var symbol = new SimpleMarkerSymbol(
						SimpleMarkerSymbol.STYLE_CIRCLE, 
						12, 
						new SimpleLineSymbol(
							SimpleLineSymbol.STYLE_NULL, 
							new Color([247, 34, 101, 0.9]), 
							1
						),
						new Color([207, 34, 171, 0.5])			
				);
				featureLayer.setSelectionSymbol(symbol);*/
				//make unselected features invisible
				//var nullSymbol = new SimpleMarkerSymbol().setSize(0);
				//featureLayer.setRenderer(new SimpleRenderer(nullSymbol));

				this.map.addLayer(featureLayer);
			} 
			/*else if(this.config.layers[i].type == 'basicgov'){
				this.objectNames.push(this.config.layers[i].url);
			}*/
		}
		this.shelter.hide();
	  },
	  
	  showBuffer:function(bufferedGeometries) {
		var symbol = new SimpleFillSymbol(
			SimpleFillSymbol.STYLE_SOLID,
			new SimpleLineSymbol(
			  SimpleLineSymbol.STYLE_SOLID,
			  new Color([255,0,0,0.65]), 2
			),
			new Color([255,0,0,0.35])
		  );

	    array.forEach(bufferedGeometries, function(geometry) {
			var graphic = new Graphic(geometry, symbol);
			this.map.graphics.add(graphic);
		  });
	  },
	  
	  buildBGLayerList: function(){
		console.debug('*** ObjectNames' +this.objectNames);	
		this.bgManager.getListViewsLayerList(this.objectNames);

	  },
	  	  
	  createDomForBGLayers: function(lvs){
		console.debug('*** Result Views');
		console.dir(lvs);
		
		// This is to dynamically create the route checkbox
		/*var routeTrNode = domConstruct.create('tr', {
			'class': 'jimu-widget-row layer-row ' + ( false ? 'jimu-widget-row-selected' : ''),
			'id': 'route_node'
			}, this.bgLayerListTable),routeTdNode,routeCkSelectDiv,routeDivLabel;
			
			routeTdNode = domConstruct.create('td', {
			'class': 'col'
			}, routeTrNode);
			
			domConstruct.create('div', {
			  'class': 'begin-blank-div'
			}, routeTdNode);
			
			routeCkSelectDiv = domConstruct.create('div', {
			'class': 'div-select'
			}, routeTdNode);
			
			var routeCkBox = domConstruct.create('input', {
				'type': 'checkbox',
				'checked': false,
				'id': 'routecb',
				'value': 'route'
			}, routeCkSelectDiv);
			
			routeDivLabel = domConstruct.create('div', {
			'innerHTML': 'Route',
			'class': 'div-content'
			}, routeTdNode);
			domStyle.set(routeDivLabel, 'width', '50%');*/
			
        for(var j = 0; j < lvs.length; j++){
			var objectName = lvs[j].objectName;	
            var objectLabel = lvs[j].objectLabel;	
			var layerTrNode = domConstruct.create('tr', {
			'class': 'jimu-widget-row layer-row ' + ( false ? 'jimu-widget-row-selected' : ''),
			'layerTrNodeId': objectName+'_node'
			}, this.bgLayerListTable),layerTdNode,ckSelectDiv,ckSelect,divLabel,plSelectDiv;
			layerTdNode = domConstruct.create('td', {
			'class': 'col'
			}, layerTrNode);
			domConstruct.create('div', {
			  'class': 'begin-blank-div'
			}, layerTdNode);
			ckSelectDiv = domConstruct.create('div', {
			'class': 'div-select'
			}, layerTdNode);
			/*var ckBox = new jimu.dijit.CheckBox({
				checked: true
			});
			domConstruct.place(ckBox.domNode, ckSelectDiv);*/
		    var ckBox = domConstruct.create('input', {
				'type': 'checkbox',
				'checked': false,
				'id': objectName+'_cb',
				'value': objectName
			}, ckSelectDiv);
			
			divLabel = domConstruct.create('div', {
			'innerHTML': objectLabel,
			'class': 'div-content'
			}, layerTdNode);
			domStyle.set(divLabel, 'width', '50%');
			
			
			plSelectDiv = domConstruct.create('div', {
			'class': 'div-select'
			}, layerTdNode);	
			domStyle.set(plSelectDiv, 'width', '35%');
			var plSelect = new Select({
				id: objectName+'_select'
			});
			var listViews = lvs[j].listViews;
			console.debug('***ListViews '+ listViews);
			var options = [];
			for(var i = 0; i< listViews.length; i++)
			{							
				var option = {
					label: listViews[i],
					value: objectName+'_'+listViews[i]
				};
				this.bgLayersString += "<option value=\"bgLayer/" + objectName+'/'+listViews[i] + "\">" + objectLabel+' - '+listViews[i] + "</option>";
				options.push(option);
				if(i == 0){
					options[i].selected = true;
				}
			}
			plSelect.addOption(options);
			domStyle.set(plSelect.domNode, 'height', '12px');
			domStyle.set(plSelect.domNode, 'width', '35%');
		    domConstruct.place(plSelect.domNode, plSelectDiv);
				
			this.own(on(ckBox, 'click',lang.hitch(this, this.toggleLayer, ckBox, plSelect,false)));
			this.own(on(plSelect, 'change', lang.hitch(this, this.toggleLayer, ckBox, plSelect,false)));
			
			/* Route Button to use Layer Features in Directions Widget */
			if(routingServiceAvailable == 'true')
			{
				domStyle.set(divLabel, 'width', '20%');
				domStyle.set(plSelectDiv, 'width', '50%');
				domStyle.set(plSelect.domNode, 'width', '50%');
				
				routeDiv = domConstruct.create('div', {
				'class': 'div-select'
				}, layerTdNode);
				domStyle.set(routeDiv, 'width', '20%');
				
				routeBtn = domConstruct.create('button', {
				'innerHTML': 'Route',
				'style': 'height:20px;'
				}, routeDiv);
				
				this.own(on(routeBtn, 'click', lang.hitch(this, this.toggleLayer, ckBox, plSelect,true)));
			}
		}
		
		this.addLayersToMap();
	  },
	  
	  bgLayerBufferQuery:function(selectionValue){
		var layerString = selectionValue.pickValue;
		
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
		
		this._clearCircle();
		// draw circle
		var circleSymb = new SimpleFillSymbol().setColor(null).outline.setColor("blue");
		var gl = new GraphicsLayer({ id: "circles" });
		var pt = new Point(selectedX, selectedY, this.map.spatialReference);
		var circle = new Circle({
			center: pt,
			//geodesic: true, /*This attribute does not work if the current spatial reference is not wkid 4326*/
			radius: selectionValue.bufferValue,
			radiusUnit: esriUnits[selectionValue.bufferUnit]
			});;
		var g = new Graphic(circle, circleSymb);
		gl.add(g);
		this.map.addLayer(gl);
		this.geometryForBGRegularSearch = g.geometry;
		
		if(layerString.indexOf('bgLayer/') != -1){
			this.shelter.show();
			var layerArray = layerString.split('/');
			var objName = layerArray[1];
			var lvName = layerArray[2];
			console.debug('*** Paras'+ layerArray+" " + objName+" " + lvName+" " + selectedX+ " "+ selectedY);
			console.dir(selectedGraphic);
			this._clearBGLayers(objName);
			this.bgManager.getAllResultsLayerList (objName, lvName);
			this.isBufferSearch = true;
			if(dojoSubscribersMap['bufferSearchResults_layerList'+objName+'_'+lvName+'_addBGLayer'+'LayerList2'] != true){
				dojo.subscribe('bufferSearchResults_layerList'+objName+'_'+lvName, lang.hitch(this, this._onBGSearchFinish));	
				dojoSubscribersMap['bufferSearchResults_layerList'+objName+'_'+lvName+'_addBGLayer'+'LayerList2'] = true;
			}				
		}
	  },
	  
	  toggleLayer: function(ckBox, plSelect, isRouting){
		var layerName = plSelect.value;
		var checked = ckBox.checked;
		var objName = ckBox.value;
		var listViewName = layerName.replace(objName+'_','');
		console.debug('*** Layer Ids' + this.map.graphicsLayerIds);
		//Clear the Circle from BGBufferSearch
		this._clearCircle();
		this._clearBGLayers(objName);
		if(this.isBGLayerRouted)
			this._clearBGLayerRoute();
		if(checked){
			this.shelter.show();
			this.bgManager.getListViewResults(objName, listViewName);
			this.isBufferSearch = false;
			this.geometryForBGRegularSearch = null;
			this.isBGRouting = isRouting;
			if(dojoSubscribersMap['listViewResults_'+objName+'_'+listViewName+'_addBGLayer'+'LayerList2'] != true){
				dojo.subscribe('listViewResults_'+objName+'_'+listViewName, lang.hitch(this, this._onBGSearchFinish));
				dojoSubscribersMap['listViewResults_'+objName+'_'+listViewName+'_addBGLayer'+'LayerList2'] = true;
			}
		}
	  },
	  
	  /**  Do the projection of Points from Standard spatial reference to base map's spatial reference here.  **/
	  _onBGSearchFinish: function(resultsToProject){
		var bgError = this._isBGError(resultsToProject);
		if(bgError == true)
		{
			return;
		}
		this.bgFields = resultsToProject.splice(1, 1)[0]; // remove fields array and story separately
		if(resultsToProject.length > 1){
			var points = [];
			var standardSpatialReference = new esri.SpatialReference({wkid: 4326});
			for (var i = 1; i < resultsToProject.length; i++){
				var po = new Point(resultsToProject[i].lon, resultsToProject[i].lat, standardSpatialReference);
				points.push(po);
			}
			
			var params = new esri.tasks.ProjectParameters();
			params.geometries = points;
			params.outSR = this.map.spatialReference;
			esriConfig.defaults.geometryService.project(params, lang.hitch(this, this._addBGLayer, resultsToProject));
			
			// this is to get the optimized route by using the Directions Widget (id='_9')
			if(this.isBGRouting)
			{
				WidgetManager.getInstance().triggerWidgetOpen('_9').then(function(directionWidget) {
					directionWidget._routeBGPoints(points);
				});
				this.isBGLayerRouted = true;
				this.isBGRouting = false;
			}
		} else {
			this._addBGLayer(resultsToProject, null);
		}
	  },
	  	  	  
	  /**  Now filter the results for circle searches.  **/
	  _addBGLayer: function(rawResults, projectedPts){
		//Need to replace the lon, lat in the results with projected x, y
		if(projectedPts != null && rawResults.length > 1)
		{
			for(var i = 1;  i < rawResults.length; i++){
				rawResults[i].lon = projectedPts[i -1].x;
				rawResults[i].lat = projectedPts[i -1].y;
			}
		}
		console.dir(rawResults);
		//Filter the results if user use circle search on BG layers. reset the circle
		var results = [];
		if(this.geometryForBGRegularSearch && this.geometryForBGRegularSearch.type == 'polygon'){
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
		
		if(results.length == 1){
			new Message({
			  message: 'Cannot find ' + results[0].split('__c_')[1].replace('_bgBufferSearchLayerList','.')
			});
			this.shelter.hide();
			return;
		}
		
		var graphL = new GraphicsLayer();
		//index 0 is always Id
		graphL.id = results[0];			  
		var sym;
		if(results.length > 1){
		    console.debug('*** Inside the marker symbol');
			sym =  new PictureMarkerSymbol(this._getBGIcon(results), 24, 24);
		}
			  
	    var attr;
        var infoTemplate;
		var fields = this.bgFields;		
		for(var i = 1; i < results.length; i++){
			//first create Point base on standard one 
			var po = new Point(results[i].lon, results[i].lat, this.map.spatialReference);			
			attr = results[i].obj;			
			var templateString = '';
			templateString += "<a id = 'bgObjectLink' href=\"/" + results[i].obj.Id + "\" target=\"_blank\">View Details</a><br/><br/>";
			for (var j=0; j<fields.length; j++) {
				var key = fields[j];
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
				// only add to template string if the field has a value		
				if (val && val.length > 0) {		
					templateString += key.label + ': ' + val.replace(':', '-') + '<br/>';		
				}
			}
			templateString += "<br/>";
			for( var key in  results[i].actionLinks){
				templateString += "<a href=\"" + results[i].actionLinks[key]+"\" target=\"_blank\">" + key+ "</a> <br/><br/>";
			}
			
			//Future enhancement: Need to figure out a way to show search results on Search widget
			/*templateString += "Show nearby <select id=\"cboProximitySearch\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + this.featureLayersString + this.bgLayersString + "</select>" +
			" <button id='btnGo' onClick='var selectList = dojo.byId(\"cboProximitySearch\"); var pickValue = selectList.value; dojo.publish(\"proximitySearchEventBG"+"\", pickValue);' dojoType='dijit/form/Button'>Go</button> ";*/
			
			// Removing Assign to BG User functionality - comment from here to show nearby
			//The default assignee is the record owner
			var bgOwnerId = results[i].ownerId;
			var userOptionString = this.bgAllUsersString;
			if(userOptionString.indexOf(bgOwnerId) != -1)
			{
				userOptionString = userOptionString.replace("\""+bgOwnerId+"\"","\""+bgOwnerId+"\""+" selected = \"true\"");
			} 
			templateString += "Assignee&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<select id=\"cboAssignToUser\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + userOptionString + "</select>" +
			" <button id='btnAssignUser' onClick='var selectListUser = dojo.byId(\"cboAssignToUser\"); var pickValueUser = selectListUser.value; var objectLink = dojo.byId(\"bgObjectLink\"); var objectId = objectLink.href.split(\"visual.force.com\/\")[1]; var params = []; params.push(objectId); params.push(pickValueUser); dojo.publish(\"assignToUserEventBG"+"\", [params]);' dojoType='dijit/form/Button'>Assign</button> <br/><br/>";			
			templateString += "<a href=\"javascript:void(0);\" onClick='var objectLink = dojo.byId(\"bgObjectLink\"); var objectId = objectLink.href.split(\"visual.force.com\/\")[1]; var params = []; params.push(objectId); params.push(currentUserId); dojo.publish(\"assignToUserEventBG"+"\", [params]);' >Assign to me </a> <br/><br/>";
			templateString += "Show nearby <select id=\"cboProximitySearch\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + this.bgLayersString + "</select>" +
			"<br> Within <input id=\"bufferRadiusValue\" style=\"width:80px;\" type=\"number\" value=\"1000\"> "+
			"<select id=\"bufferRadiusUnitSelect\" style=\"width:130px;\" dojoType='dijit/form/Select'>" + this.bufferRadiusUnits + "</select>" +		
			" <button id='btnGo' onClick='var selectList = dojo.byId(\"cboProximitySearch\"); var pickValue = selectList.value; var bufferValueSelect = dojo.byId(\"bufferRadiusValue\"); var bufferValue = bufferValueSelect.value; var bufferUnitSelectList = dojo.byId(\"bufferRadiusUnitSelect\"); var bufferUnit = bufferUnitSelectList.value; dojo.publish(\"proximitySearchEventBG"+"\", {pickValue, bufferValue, bufferUnit});' dojoType='dijit/form/Button'>Go</button> ";
			infoTemplate = new InfoTemplate("Information",templateString);
			graphL.add(new Graphic(po, sym, attr, infoTemplate));
		}
		this.map.addLayer(graphL);		
		this.shelter.hide();
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
	  
	  _clearBGLayers: function(objName){
		var layerIds = this.map.graphicsLayerIds;
		var layer;
		this._hideInfoWindow();
		for(var i = 0 ; i < layerIds.length; i++){
		    //Remove the LayerList layer, do not remove the search Layer
			//if((layerIds[i].indexOf(objName) != -1 || layerIds[i].indexOf('_bgBufferSearchLayerList') != -1) && layerIds[i].indexOf('_bgSearch') == -1) {
			if((layerIds[i].indexOf(objName) != -1 && layerIds[i].indexOf('_bgSearch') == -1) || layerIds[i].indexOf('directionRecordResults') != -1) {
				layer = this.map.getLayer(layerIds[i]);
				this.map.removeLayer(layer);
			}
		}
	  },
	  
	  _clearCircle: function(){
		var circleLayer = this.map.getLayer("circles");
		if (circleLayer) this.map.removeLayer(circleLayer);
	  },
	  
	  _hideInfoWindow:function(){
        if(this.map &&this.map.infoWindow){
          this.map.infoWindow.hide();
        }
      },
	  
	  _clearBGLayerRoute: function(){
		WidgetManager.getInstance().triggerWidgetOpen('_9').then(function(directionWidget) {
			directionWidget.resetDirections();
		});
		this.isBGLayerRouted = false;
	  },
	  
	  _isBGError: function(result){
		if(result.indexOf('Exception:') != -1)
		{
			new Message({
			  message: result
			});
			this.shelter.hide();
			return true;
		} else
		{
			return false;
		}
	  },
	  
	  _htmlDecode: function(string){
		var e = document.createElement('div');
		e.innerHTML = string;
		return e.childNodes.length === 0 ? "" : e.childNodes[0].nodeValue;
	  },
	  		
	  _resetUnitsArrays: function(){		
        this.defaultDistanceUnits = [];		
        this.configDistanceUnits = [];		
        this.distanceUnits = [];		
      },		
	  		
	  _initUnitSelect:function(){		
		this._initDefaultUnits();		
		this._initConfigUnits();		
		var options = [];		
		var a = this.configDistanceUnits;		
        var b = this.defaultDistanceUnits;		
		this.distanceUnits = a.length > 0 ? a : b;		
		var len = this.distanceUnits.length;		
		for (var i = 0; i < len; i++) {		
			var option = {		
				value:this.distanceUnits[i].unit,		
				label:this.distanceUnits[i].label		
			};		
			options.push(option);		
			if (i === 3) {		
				this.bufferRadiusUnits += "<option selected=\"selected\" value=\"" + this.distanceUnits[i].unit + "\">" + this.distanceUnits[i].label + "</option>";		
			}		
			else {		
				this.bufferRadiusUnits += "<option value=\"" + this.distanceUnits[i].unit + "\">" + this.distanceUnits[i].label + "</option>";		
			}		
		}		
	  },		
	  		
	  _initDefaultUnits:function(){		
        this.defaultDistanceUnits = [{		
          unit: 'KILOMETERS',		
          label: this.nls.kilometers		
        }, {		
          unit: 'MILES',		
          label: this.nls.miles		
        }, {		
          unit: 'METERS',		
          label: this.nls.meters		
        }, {		
          unit: 'FEET',		
          label: this.nls.feet		
        }, {		
          unit: 'YARDS',		
          label: this.nls.yards		
        }];		
      },		
	  		
	  _initConfigUnits:function(){		
        array.forEach(this.config.distanceUnits, lang.hitch(this, function(unitInfo){		
          var unit = unitInfo.unit;		
          if(esriUnits[unit]){		
            var defaultUnitInfo = this._getDefaultDistanceUnitInfo(unit);		
            unitInfo.label = defaultUnitInfo.label;		
            this.configDistanceUnits.push(unitInfo);		
          }		
        }));		
      },		
	  		
	  _getDefaultDistanceUnitInfo:function(unit){		
        for(var i = 0; i < this.defaultDistanceUnits.length; i++){		
          var unitInfo = this.defaultDistanceUnits[i];		
          if(unitInfo.unit === unit){		
            return unitInfo;		
          }		
        }		
        return null;		
      }
    });
  });