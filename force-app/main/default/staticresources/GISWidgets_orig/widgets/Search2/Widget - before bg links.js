///////////////////////////////////////////////////////////////////////////
// Copyright © 2014 Esri. All Rights Reserved.
//
// Licensed under the Apache License Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////

define([
    'dojo/_base/declare',
    'dijit/_WidgetsInTemplateMixin',
    'jimu/BaseWidget',
    'jimu/dijit/TabContainer',
    'jimu/dijit/List',
    'jimu/dijit/Message',
    'jimu/utils',
    'esri/tasks/query',
    'esri/tasks/QueryTask',
    'esri/layers/GraphicsLayer',
    'esri/layers/FeatureLayer',
    'esri/graphic',
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
	'jimu/dijit/Message',
	'dojo/_base/Color'
  ],
  function(
    declare, _WidgetsInTemplateMixin, BaseWidget,TabContainer, List, Message, utils, Query, QueryTask, GraphicsLayer, FeatureLayer,
    Graphic, Point, Circle, SimpleMarkerSymbol, PictureMarkerSymbol, Polyline, SimpleLineSymbol, Polygon, SimpleFillSymbol, Draw, InfoTemplate,
    esriRequest,ProgressBar, lang, on, html, array, all, Select, TextBox, DrawBox,LoadingShelter, Message, Color) {/*jshint unused: false*/
    return declare([BaseWidget, _WidgetsInTemplateMixin], {
      name: 'Search',
      baseClass: 'jimu-widget-search',
      resultLayers:[],
      layerIndex1: 0,
      layerIndex2: 0,
      progressBar: null,
      searchResults: null,
      tabContainer: null,
      list: null,
	  bgManager: null,
	  featureLayersString: '',
	  bgAllUsersString:"",
	  bgLayersString: '',
	  s_geometry: null, 
	  s_layerIndex: 0, 
	  s_layerValue: null, 
	  s_proxyErrors: 0,
	  geometryForBGRegularSearch: null,
	  symbolArray:["esriSMSCircle", "esriSMSDiamond", "esriSMSCross", "esriSMSSquare"],
	  isBufferSearch: null,

      postCreate:function(){
		this.shelter.show();
        this.inherited(arguments);
        this.resultLayers = [];
        this._initTabContainer();
        this._initLayerSelect();
        this._initProgressBar();
        this._initDrawBox();
			
		this._removeUnnecessaryDrawBox();
		if(dojoSubscribersMap['searchWidgetEventBG'+'bufferSearchInSearchWidget'+'Search'] != true){
			dojo.subscribe('searchWidgetEventBG', lang.hitch(this, this.bufferSearchInSearchWidget));
			dojoSubscribersMap['searchWidgetEventBG'+'bufferSearchInSearchWidget'+'Search'] = true;
		} 
		if(dojoSubscribersMap['searchWidgetEvent'+'bufferSearchInSearchWidget'+'Search'] != true){
			dojo.subscribe('searchWidgetEvent', lang.hitch(this, this.bufferSearchInSearchWidget));
			dojoSubscribersMap['searchWidgetEvent'+'bufferSearchInSearchWidget'+'Search'] = true;
		}
		if(dojoSubscribersMap['listViews_search'+'_addBGLayersToSelectLayer1'+'Search'] != true){
			dojo.subscribe('listViews_search', lang.hitch(this, this._addBGLayersToSelectLayer1));
			dojoSubscribersMap['listViews_search'+'_addBGLayersToSelectLayer1'+'Search'] = true;
		}
		if(dojoSubscribersMap['allUsers_search'+'getBGUsers'+'Search'] != true){
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
		}
      },
	  
	  assignToBGUser: function(params) {
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
	  },
	  
	  _removeUnnecessaryDrawBox: function(){
	    console.dir(this.drawBox);
		this.drawBox.domNode.children[0].children[1].style.display = "none";
		this.drawBox.domNode.children[0].children[2].style.display = "none";
		this.drawBox.domNode.children[0].children[3].style.display = "none";
		this.drawBox.domNode.children[0].children[4].style.display = "none";
		this.drawBox.domNode.children[0].children[7].style.display = "none";
		this.drawBox.domNode.children[0].children[8].style.display = "none";
		this.drawBox.domNode.children[0].children[9].style.display = "none";
	  },

      onClose: function() {
        this.drawBox.deactivate();
        this._hideInfoWindow();
        this.inherited(arguments);
      },

      destroy:function(){
        if(this.drawBox){
          this.drawBox.destroy();
          this.drawBox = null;
        }
        while(this.resultLayers.length > 0){
          var layer = this.resultLayers[0];
          if(layer){
            this.map.removeLayer(layer);
            this.resultLayers.splice(0,1);
          }
        }
        this.resultLayers = [];
        this._hideInfoWindow();
        this.inherited(arguments);
      },

      onChange1: function(newValue) {
        this.layerIndex1 = newValue;
      },

      onChange2: function(newValue) {
		if (this.config.layers[newValue]) {
			this.layerIndex2 = newValue;
		}
		else {
			var v = this.selectLayer2.get('value');
			var objName = v.split('/')[1];
			for (var lx in this.config.layers) {
				if (this.config.layers[lx].url == objName) {
					this.layerIndex2 = lx;
					break;
				}
			}
		}
		
		this.labelSearchName.textContent = this.config.layers[this.layerIndex2].textsearchlabel;
		this.inputSearchName.set("placeHolder", this.config.layers[this.layerIndex2].textsearchhint);
      },

      _initTabContainer:function(){
        this.tabContainer = new TabContainer({
          tabs: [{
            title: this.nls.selectFeatures,
            content: this.tabNode1
          }, {
            title: this.nls.selectByAttribute,
            content: this.tabNode2
          }, {
            title: this.nls.results,
            content: this.tabNode3
          }],
          selected: this.nls.conditions
        }, this.tabSearch);
        this.tabContainer.startup();
        utils.setVerticalCenter(this.tabContainer.domNode);
      },

      _initLayerSelect:function(){
        var options = [];
        var len = this.config.layers.length;
		var objectNames = [];
        for (var i = 0; i < len; i++) {
          if(this.config.layers[i].type != 'basicgov'){
			  var option = {
				value:i,
				label:this.config.layers[i].name
			  };
			  options.push(option);
			  if (i === 0) {
				options[i].selected = true;
			  }
			  this.featureLayersString += "<option value=\"" + this.config.layers[i].url + "\">" + this.config.layers[i].name + "</option>";
		  } else{
			// objectNames will be used to get ListViews further down
			// then on callback the dropdown is populated
			objectNames.push(this.config.layers[i].url);
		  }
        }
		
        if (len > 0) {
          this.selectLayer1.addOption(options);
          this.selectLayer2.addOption(options);
          this.labelSearchName.textContent = this.config.layers[0].textsearchlabel;
          this.inputSearchName.set("placeHolder", this.config.layers[0].textsearchhint);
		  
		   //Add BGLayers into the SelectLayer1 for now
		  this.bgManager = new BGManager();
		  this.bgManager.getListViewsSearch(objectNames);

          if(this.config.shareResult){
            this.shelter.show();
            var defs = array.map(this.config.layers,lang.hitch(this,function(layerConfig){
              var def = esriRequest({
                url:layerConfig.url,
                content:{f:'json'},
                handleAs:'json',
                callbackParamName:'callback',
                timeout:30000
              },{
                useProxy:false
              });
              return def;
            }));
            all(defs).then(lang.hitch(this,function(results){
			  this.shelter.hide();
              array.forEach(results,lang.hitch(this,function(response,j){
                response.name = this.nls.searchResult + " : " + response.name;
                var layerConfig = this.config.layers[j];
                var names = array.map(layerConfig.fields.field,lang.hitch(this,function(item){
                  return item.name;
                }));
                var objectIdFieldInfo = (array.filter(response.fields,lang.hitch(this,function(fieldInfo){
                  return fieldInfo.type === 'esriFieldTypeOID';
                })))[0];
                if(objectIdFieldInfo){
                  layerConfig.objectIdField = objectIdFieldInfo.name;
                }
                layerConfig.existObjectId = array.indexOf(layerConfig.objectIdField) >= 0;
                response.fields = array.filter(response.fields,lang.hitch(this,function(fieldInfo){
                  return fieldInfo.type === 'esriFieldTypeOID' || array.indexOf(names,fieldInfo.name) >= 0;
                }));
                layerConfig.fields.field = response.fields;
                var layer = new FeatureLayer({
                  layerDefinition:response,
                  featureSet:null
                });
                this.resultLayers.push(layer);
                this.map.addLayer(layer);
              }));
            }),lang.hitch(this,function(err){
              this.shelter.hide();
              console.error(err);
              for(var j=0;j<this.config.layers.length;j++){
                var layer = new GraphicsLayer();
                this.resultLayers.push(layer);
                this.map.addLayer(layer);
              }
            }));
          }
          else{
            for (var j = 0; j < this.config.layers.length; j++) {
              var layer = new GraphicsLayer();
              this.resultLayers.push(layer);
              this.map.addLayer(layer);
            }
          }
        }
        this.own(on(this.selectLayer1, "change", lang.hitch(this, this.onChange1)));
        this.own(on(this.selectLayer2, "change", lang.hitch(this, this.onChange2)));
      },
	  
	  _addBGLayersToSelectLayer1:function(lvs){
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
		this.selectLayer1.addOption(bgLayersOptions);
		this.selectLayer2.addOption(bgLayersOptions);
		//get all BG users for assign purpose
		this.bgManager.getAllUsersSearch();

	  },
	  
	  getBGUsers: function(results) {
		//console.debug('***** All users');
		//console.dir(results);
		for(var i = 0; i< results.length; i++)
		{							
			this.bgAllUsersString += "<option value=\"" + results[i].Id + "\">" + results[i].Name + "</option>";
		}
		//console.debug(this.bgAllUsersString);
		this.shelter.hide();
		//BG if zoomOnLoad is true, zoom to parcel or point
		if(zoomOnLoad == 'true' && zoomParcelName != '')
		{
			//Set the search text here. MAKE SURE the Parcel layer is in index 0
			this.inputSearchName.value = zoomParcelName;
			this.search(null, 0 , null, null, null);
		} else if(zoomOnLoad == 'true' && zoomObjects != null)
		{
			console.debug('************** Print Zoom Object');
			console.dir(zoomObjects);
			this.tabContainer.selectTab(this.nls.results);
			html.setStyle(this.progressBar.domNode,'display','block');
			html.setStyle(this.divResult,'display','none');
			this._onBGSearchFinish(zoomObjects);
		}
	  },

      _initProgressBar:function(){
        this.progressBar = new ProgressBar({
          indeterminate: true
        }, this.progressbar);
        html.setStyle(this.progressBar.domNode,'display','none');
      },

      _initDrawBox:function(){
        this.drawBox.setMap(this.map);
        this.own(on(this.drawBox,'DrawEnd',lang.hitch(this,function(graphic){
		  this.map.enableMapNavigation();
          this.search(graphic.geometry, this.layerIndex1, this.selectLayer1.get('value'), null, null);
        })));
        this.own(on(this.btnClear, "click", lang.hitch(this, this.clear)));
      },

      onSearch: function() {
        this.search(null, this.layerIndex2, this.selectLayer2.get('value'), null, null);
      },
	  
	  search: function(geometry, layerIndex, layerValue, retryFromProxyError, bufferSearch) {
        this.geometryForBGRegularSearch = null;
		this.isBufferSearch = bufferSearch;
		console.debug('*** Search...');
		
		// cache (in case of error we retry search
		this.s_geometry = geometry;
		this.s_layerIndex = layerIndex;
		this.s_layerValue = layerValue;
		if (!retryFromProxyError) this.s_proxyErrors = 0;
		
		if(!this.config.layers){
          return;
        }
        if(this.config.layers.length === 0){
          return;
        }
		
		//var selectedValue1 = this.selectLayer1.get('value'); // graphical search layer
		var selectedValue2 = this.selectLayer2.get('value'); // text search layer
		console.debug('*** Before Search...');
		// geometry search
		if(geometry){
		    console.debug('*** Graphic Search!');
			// BG search
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
		        html.setStyle(this.divResult,'display','none');
			
			// GIS Search
			} else {
				var query = new Query();
				query.geometry = geometry;
				this._doQueryTask(query, layerIndex);
			}
			
		// text search
		} else {
			// BG search
			console.debug('*** Text Search!');
			if(typeof selectedValue2 == 'string' && selectedValue2.indexOf('basicgov') != -1){
				console.debug('*** BG Text Search!');
				var selectedValue2 = this.selectLayer2.get('value');
				this._clearBGSearchLayer();
				var optionValue = this.selectLayer2.get('value');
				var values = optionValue.split('/');
				var objName = values[1];
				var listViewName = values[2];
				var content2 = this.inputSearchName.value;
				console.debug('*** Search text ' +content2);
				console.debug('*** Object Name '+objName);
				console.debug('*** ListView Name '+listViewName);
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
				}
				this.tabContainer.selectTab(this.nls.results);
				html.setStyle(this.progressBar.domNode,'display','block');
		        html.setStyle(this.divResult,'display','none');
			// GIS search
			} else {
				console.debug('*** GIS Text Search!');
				var content;
				var query = new Query();
				this._clearLayers();
				content = this.inputSearchName.value;
				if (!content || !this.config.layers.length) {
					new Message({
					  message: 'Search text cannot be empty.'
					});
				  return;
				}
				var where = this.config.layers[layerIndex].expression;
				where = where.replace(/\[value\]/g, content);
				query.where = where;
				query.outSpatialReference = this.map.spatialReference;
				this._doQueryTask(query, layerIndex);
			}
		}
      },
	  
	  _doQueryTask: function(query, layerIndex){
	    this.tabContainer.selectTab(this.nls.results);
		html.setStyle(this.progressBar.domNode,'display','block');
		html.setStyle(this.divResult,'display','none');
		var fields = [];
		if (this.config.layers[layerIndex].fields.all) {
		  fields[0] = "*";
		} else {
		  for (var i = 0, len = this.config.layers[layerIndex].fields.field.length; i < len; i++) {
			fields[i] = this.config.layers[layerIndex].fields.field[i].name;
		  }
		}
		
		var url = this.config.layers[layerIndex].url;
		var queryTask = new QueryTask(url);
		query.returnGeometry = true;
		query.outFields = fields;
		queryTask.execute(query, lang.hitch(this, this._onSearchFinish, layerIndex), lang.hitch(this, this._onSearchError));
	  },
	  
	  /** getListViewResults() finished. Do the projection of Points from Standard spatial reference to base map's spatial reference here. **/
	  _onBGSearchFinish: function(resultsToProject){
		var bgError = this._isBGError(resultsToProject);
		if(bgError == true)
		{
			this.clear();
			html.setStyle(this.progressBar.domNode,'display','none');
			html.setStyle(this.divResult,'display','block');
			return;
		}
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
	    var resultCircleLayer = this.map.getLayer("circles");
		this.clear();		
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
	  
	  /**   Results are filtered. Now show them on map   **/
	  _drawBGResults: function(results){
		html.setStyle(this.progressBar.domNode,'display','none');
		html.setStyle(this.divResult,'display','block');

		var graphL = new GraphicsLayer();
		//index 0 is always Id
		graphL.id = results[0];
		
		//BG you can switch between the BG icon or Simple marker here
		/*var sym = new SimpleMarkerSymbol({
			  "color": [100,100,100,64],
			  "size": 12,
			  "angle": -30,
			  "xoffset": 0,
			  "yoffset": 0,
			  "type": "esriSMS",
			  //"style": "esriSMSCircle",
			  "style": this.symbolArray[Math.floor((Math.random() * 3) + 0)],
			  "outline": {
				"color": [Math.floor((Math.random() * 150) + 1),Math.floor((Math.random() * 150) + 1),Math.floor((Math.random() * 150) + 1), 255],
				"width": 1,
				"type": "esriSLS",
				"style": "esriSLSSolid"
			  }});*/
			  
		
		var sym; 		
		if(results.length > 1){
			sym =  new PictureMarkerSymbol(results[1].iconUrl, 24, 24);
		}
			  
	    var attr;
        var infoTemplate;
		var newGraphic;
		
		//BG layer add to Result tab
		var len = results.length;
		if (len <= 1) {
          this.divResultMessage.textContent = this.nls.noResults;
		  //reset zoom on load
		  if(zoomOnLoad == 'true')
		  {
			zoomOnLoad = 'false';
		  }
          return;
        } else {
          this.divResultMessage.textContent = this.nls.featuresSelected + (len - 1).toString();
        }

		for(var i = 1; i < results.length; i++){
			var po = new Point(results[i].lon, results[i].lat, this.map.spatialReference);			
			attr = results[i].obj; 
			
			var line = "",br = "",label = "",content = "",title = "";
			var templateString = '';
			templateString += "<a id = 'bgObjectLinkSearch' href=\"/" + results[i].obj.Id + "\" target=\"_blank\">View Details</a><br/><br/>";
			for (var key in results[i].obj) {
				if(key != 'Id' && key != 'RecordTypeId' && key !='attributes'){
					var val = key.replace("MUSW__", "").replace("BGBK__", "").replace("__c", "").replace("_", " ");
					results[i].obj[key] =  this._htmlDecode(results[i].obj[key]);
					templateString += val + ": " + results[i].obj[key] + "<br/>";
					label += val + ": " + results[i].obj[key] + ", ";
				}
			}
			templateString += "<br/>";
			for( var key in results[i].actionLinks) {
				templateString += "<a href=\"" + results[i].actionLinks[key]+"\" target=\"_blank\">" + key+ "</a> <br/><br/>";
			}
			//The default assignee is the record owner
			var bgOwnerId = results[i].ownerId;
			var userOptionString = this.bgAllUsersString;
			if(userOptionString.indexOf(bgOwnerId) != -1)
			{
				userOptionString = userOptionString.replace("\""+bgOwnerId+"\"","\""+bgOwnerId+"\""+" selected = \"true\"");
			} 
			templateString += "Assignee&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<select id=\"bgSearchAssignToUser\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + userOptionString + "</select>" +
			" <button id='btnAssignUserSearch' onClick='var selectListUser = dojo.byId(\"bgSearchAssignToUser\"); var pickValueUser = selectListUser.value; var objectLink = dojo.byId(\"bgObjectLinkSearch\"); var objectId = objectLink.href.split(\"visual.force.com\/\")[1]; var params = []; params.push(objectId); params.push(pickValueUser); dojo.publish(\"assignToUserEventBGSearch"+"\", [params]);' dojoType='dijit/form/Button'>Assign</button> <br/><br/>";			
			templateString += "<a href=\"javascript:void(0);\" onClick='var objectLink = dojo.byId(\"bgObjectLinkSearch\"); var objectId = objectLink.href.split(\"visual.force.com\/\")[1]; var params = []; params.push(objectId); params.push(currentUserId); dojo.publish(\"assignToUserEventBGSearch"+"\", [params]);' >Assign to me </a> <br/><br/>";
			templateString += "Show nearby <select id=\"bgSearchInfoSelect\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + this.featureLayersString + this.bgLayersString + "</select>" +
			" <button id='btnGoSearch' onClick='var selectList = dojo.byId(\"bgSearchInfoSelect\"); var pickValue = selectList.value; dojo.publish(\"searchWidgetEventBG"+"\", pickValue);' dojoType='dijit/form/Button'>Go</button> ";
						
			infoTemplate = new InfoTemplate("Information", templateString);
			newGraphic = new Graphic(po, sym, attr, infoTemplate);
			graphL.add(newGraphic);
			this.list.add({
				id: "id_" + (i-1).toString(),
				label: label.slice(0, - 2),
				title: title,
				content: templateString
            });
			this.list.items[i-1].graphic = newGraphic;
			this.list.items[i-1].content = templateString;
			this.list.items[i-1].centerpoint = po;		
		}
		this.map.addLayer(graphL);	
		console.debug('*** Search Finish.');
		
		this._bgZoomToPoint();
	  },
	  
	  bufferSearchInSearchWidget:function(selectionValue){
		this.geometryForBGRegularSearch = null;
		console.debug('*** Buffer search...');
		html.setStyle(this.progressBar.domNode,'display','block');
		html.setStyle(this.divResult,'display','none');
		this.clear();
		var layerString = selectionValue;
		
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
		
		// draw circle
		var circleSymb = new SimpleFillSymbol().setColor(null).outline.setColor("blue");
		var gl = new GraphicsLayer({ id: "circles" });
		var pt = new Point(selectedX, selectedY, this.map.spatialReference);
		var circle = new Circle({
			center: pt,
			//geodesic: true, /*This attribute does not work if the current spatial reference is not wkid 4326*/
			radius: 1000,
			radiusUnit: "esriFeet"
			});
		var g = new Graphic(circle, circleSymb);
		gl.add(g);
		this.map.addLayer(gl);
		
		this.geometryForBGRegularSearch = g.geometry;
		
		// BG search
		if(selectionValue.indexOf('basicgov/') != -1){
			this._clearBGSearchLayer();
			this.search(g.geometry, null, selectionValue, null, true);
		
		// GIS search
		} else if(selectionValue.indexOf('https://') != -1){
			var layerIndex;
			for(var i in this.config.layers) {
				if (this.config.layers[i].url == selectionValue) {
					layerIndex = i; break;
				}
			}
			
			this.search(g.geometry, layerIndex, selectionValue, null ,true);
		}
	  },
	  
      _onSearchError: function(error) {
		// retry if proxy was called (cannot disable proxy for whatever reason -tried removing from config.json to no effect)
		if (error.message.indexOf("Unable to load") > -1 && error.message.indexOf("proxy") > -1 && this.s_proxyErrors == 0) {
			this.s_proxyErrors++;
			this.search(this.s_geometry, this.s_layerIndex, this.s_layerValue, true, null);
		}
		else {
			this.clear();
			html.setStyle(this.progressBar.domNode,'display','none');
			html.setStyle(this.divResult,'display','block');
			new Message({
			  message: this.nls.searchError
			});
		}
        console.debug(error);
      },

      _onSearchFinish: function(layerIndex, results) {
		console.debug('*** Search finish');
        var layerConfig = this.config.layers[layerIndex];
		var resultCircleLayer = this.map.getLayer("circles");
        this.clear();
        html.setStyle(this.progressBar.domNode,'display','none');
        html.setStyle(this.divResult,'display','block');
        this.searchResults = results;

        var title = "";
        var titlefield = layerConfig.titlefield;
        var objectIdField = layerConfig.objectIdField;
        var existObjectId = layerConfig.existObjectId;
        var len = results.features.length;
        if (len === 0) {
          this.divResultMessage.textContent = this.nls.noResults;
		  //reset zoom on load
		  if(zoomOnLoad == 'true')
		  {
			zoomOnLoad = 'false';
		  }
          return;
        } else {
          this.divResultMessage.textContent = this.nls.featuresSelected + results.features.length;
        }
		
        for (var i = 0; i < len; i++) {
          var featureAttributes = results.features[i].attributes;
          var line = "",br = "",label = "",content = "";
          for (var att in featureAttributes) {
            if(!existObjectId && att === objectIdField){
              continue;
            }
			var alias = this._getAlias(att, layerIndex);
			if(alias.indexOf("itude") > 0) {
			  continue;
			}
            label = label + line + alias + ": " + featureAttributes[att];
            line = ", ";
            if (titlefield && (att.toLowerCase() === titlefield.toLowerCase())) {
              title = featureAttributes[att];
            } else {
              content = content + br + alias + ": " + featureAttributes[att];
              br = "<br>";
            }
          }
          this.list.add({
            id: "id_" + i,
            label: label,
            title: title,
            content: content
          });
        }
        this._drawResults(layerIndex, results);
		if(resultCircleLayer && this.isBufferSearch){
			this.map.addLayer(resultCircleLayer);
		}
      },

      _drawResults: function(layerIndex, results) {
		console.debug('*** Draw search results...');
        var currentLayer = this.resultLayers[layerIndex];
		console.dir(results.features);
        var features = results.features;
        for (var i = 0, len = features.length; i < len; i++) {
          var feature = features[i];
          var listItem = this.list.items[i];
          var type = feature.geometry.type;
          var geometry, symbol, centerpoint;
          switch (type) {
          case "multipoint":
          case "point":
            if (this.config.symbols &&this.config.symbols.simplemarkersymbol) {
              symbol = new SimpleMarkerSymbol(this.config.symbols.simplemarkersymbol);
            } else {
              if (this.config.symbols&& this.config.symbols.picturemarkersymbol) {
                symbol = new PictureMarkerSymbol(this.config.symbols.picturemarkersymbol);
              }
              else{
                symbol = new SimpleMarkerSymbol();
              }
            }
            centerpoint = feature.geometry;
            break;
          case "polyline":
            if (this.config.symbols && this.config.symbols.simplelinesymbol) {
              symbol = new SimpleLineSymbol(this.config.symbols.simplelinesymbol);
            } else {
              symbol = new SimpleLineSymbol();
            }
            centerpoint = feature.geometry.getPoint(0, 0);
            break;
          case "extent":
          case "polygon":
            if (this.config.symbols && this.config.symbols.simplefillsymbol) {
              symbol = new SimpleFillSymbol(this.config.symbols.simplefillsymbol);
            } else {
              symbol = new SimpleFillSymbol();
            }
            centerpoint = feature.geometry.getPoint(0, 0);
            break;
          default:
            break;
          }
          
          listItem.centerpoint = centerpoint;
          listItem.graphic = feature;
          var title = listItem.title;
          var content = listItem.content;
          if(!feature.symbol){
            feature.setSymbol(symbol);
          }
          if(!feature.infoWindow){
		    content += "<br> Show nearby <select id=\"bgSearchInfoSelect\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + this.featureLayersString + this.bgLayersString + "</select>" +
			" <button id='btnGo' onClick='var selectList = dojo.byId(\"bgSearchInfoSelect\"); var pickValue = selectList.value; dojo.publish(\"searchWidgetEvent\", pickValue);' dojoType='dijit/form/Button'>Go</button> ";
			content += "<br/><br/><a href=\"/a11/e?\" target=\"_blank\">Create Permit</a> <br/><br/><a href=\"/a0y/e?\" target=\"_blank\">Create Complaint</a> <br/><br/><a href=\"/a1Z/e?\" target=\"_blank\">Create Inspection</a> <br/><br/>";
			
			listItem.content = content;
            var it = new InfoTemplate(title, title + "<br>" + content);
            feature.setInfoTemplate(it);
          }
          currentLayer.add(feature);
        }
		
		this._bgZoomToPoint();
      },

      clear: function() {
        this._hideInfoWindow();
        this._clearLayers();
		this._clearCircle();
		this._clearBGSearchLayer();
        this.list.clear();
        this.divResultMessage.textContent = this.nls.noResults;
        this.drawBox.clear();
        return false;
      },
	  
	  /**   Clear results from BG Search   **/
	  _clearBGSearchLayer: function() {
		var layerIds = this.map.graphicsLayerIds;
		var layer;
		for(var i = 0 ; i < layerIds.length; i++){
			if(layerIds[i].indexOf('_bgSearch') != -1 || layerIds[i].indexOf('bgDefaultObjectToZoom') != -1){
				layer = this.map.getLayer(layerIds[i]);
				this.map.removeLayer(layer);
			}
		}
	  },
	  
	  _clearCircle: function(){
		var circleLayer = this.map.getLayer("circles");
		if (circleLayer) this.map.removeLayer(circleLayer);
	  },

      _clearLayers:function(){
        array.forEach(this.resultLayers,lang.hitch(this,function(layer){
          if(layer){
            layer.clear();
          }
        }));
      },

      _getAlias: function(att, layerIndex) {
        var field = this.config.layers[layerIndex].fields.field;
        var item;
        for (var i in field) {
          item = field[i];
          if (item.name.toLowerCase() === att.toLowerCase() && item.alias) {
            return item.alias;
          }
        }
        return att;
      },

      _selectResultItem: function(index, item) {
        var point = this.list.items[this.list.selectedIndex].centerpoint;
		var zoomLevel = defaultZoomLevel;
        this.map.centerAndZoom(point, zoomLevel).then(lang.hitch(this, function() {
          if (this.map.infoWindow) {
            this.map.infoWindow.setFeatures([item.graphic]);
            this.map.infoWindow.setTitle(item.title);
            this.map.infoWindow.setContent(item.content);
            if (this.map.infoWindow.reposition) {
              this.map.infoWindow.reposition();
            }
            this.map.infoWindow.show(item.centerpoint);
          }
        }));
      },

      _hideInfoWindow:function(){
        if(this.map &&this.map.infoWindow){
          this.map.infoWindow.hide();
        }
      },
	  
	  _bgZoomToPoint: function(){
		//BG if zoomOnLoad = true, zoom to the first point
		if(zoomOnLoad == 'true' && this.list.items.length > 0)
		{
			//Zoom to the first result
			this.list.selectedIndex = 0;
			this._selectResultItem(0, this.list.items[0]); 
			//reset zoom on load
			zoomOnLoad = 'false';
		}
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
	  }
    });
  });