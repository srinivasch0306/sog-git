///////////////////////////////////////////////////////////////////////////
// Copyright © 2014 - 2016 Esri. All Rights Reserved.
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
    'jimu/BaseWidget',
    'esri/dijit/Directions',
    'esri/tasks/locator',
    'esri/tasks/RouteParameters',
    'esri/request',
	'esri/graphic',
    'esri/graphicsUtils',
	'esri/layers/GraphicsLayer',
    'esri/layers/ArcGISDynamicMapServiceLayer',
	'esri/symbols/PictureMarkerSymbol',
	'esri/geometry/Point',
    'dojo/on',
    'dojo/_base/lang',
    'dojo/_base/html',
    'dojo/_base/array',
    'dojo/_base/config',
    'dojo/Deferred',
    'dojo/promise/all',
	'dojo/date/locale',
    'jimu/portalUtils',
	'esri/InfoTemplate',
	'dijit/form/Button',
	'esri/tasks/GeometryService',
    'esri/tasks/BufferParameters',
	'esri/SpatialReference',
	'jimu/dijit/Message',
	'jimu/dijit/LoadingShelter'
  ],
  function(declare, BaseWidget, Directions, Locator, RouteParameters, esriRequest, Graphic, graphicsUtils, GraphicsLayer, 
    ArcGISDynamicMapServiceLayer, PictureMarkerSymbol, Point, on, lang, html, array, dojoConfig, Deferred, all, locale, 
	portalUtils, InfoTemplate, Button, GeometryService, BufferParameters, SpatialReference, Message, LoadingShelter) {

    return declare([BaseWidget], {
      name: 'Directions',
      baseClass: 'jimu-widget-directions',
      _dijitDirections:null,
      _routeTaskUrl: "//route.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World",
      _locatorUrl: "//geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer",
      _active: false,//save last active state
      _dijitDef: null,
      _trafficLayer: null,
	  bgManager: null,
	  bgFields: null,

      onOpen: function(){
        this.widgetManager.activateWidget(this);
      },

      onClose: function(){
        this._hide();
      },

      onNormalize: function(){
        this._show();
      },

      onMinimize: function(){
        this._hide();
      },

      onMaximize: function(){
        this._show();
      },

      onDeActive: function(){
        this._deactivateDirections();
        this._enableWebMapPopup();
      },

      setStartStop: function(stop){
        this.getDirectionsDijit().then(lang.hitch(this, function(directionsDijit){
          directionsDijit.reset().then(lang.hitch(this, function(){
            directionsDijit.addStop(stop);
          }), lang.hitch(this, function(err){
            console.error(err);
          }));
        }), lang.hitch(this, function(err){
          console.error(err);
        }));
      },
	  
	  /* Adds multiple stops for Directions Widget, from Layer List widget or Url params 
	   * reset - > add stops -> optimize route
	   * stops - is a list of objects containing spatialreference and the lat long of each stop
	   */
	  addBGStops: function(stops){
        this.getDirectionsDijit().then(lang.hitch(this, function(directionsDijit) {
		  directionsDijit.reset().then(lang.hitch(this, function(){  // resets the Directions widget to remove previous results
			  directionsDijit.addStops(stops).then(lang.hitch(this, function(stops) {
				  directionsDijit._optionsButtonNode.click();     //opens options sections
				  directionsDijit.set("optimalRoute", true);  //sets the Optimize Order checkbox to true
				  directionsDijit._getDirectionsButtonNode.click();   // Runs the getDirections again to get the optimal route
			  }), lang.hitch(this, function(err) {
					console.error(err);
			  }));
		  }), lang.hitch(this, function(err){
				console.error(err);
			}));
		}), lang.hitch(this, function(err) {
				console.error(err);
        }));
      },
	  
	  /* Adds multiple stops at once */
	  addStops: function(stops){
        this.getDirectionsDijit().then(lang.hitch(this, function(directionsDijit) {
          directionsDijit.addStops(stops);
        }), lang.hitch(this, function(err) {
          console.error(err);
        }));
      },

      addStop: function(stop){
        this.getDirectionsDijit().then(lang.hitch(this, function(directionsDijit) {
          directionsDijit.addStop(stop);
        }), lang.hitch(this, function(err) {
          console.error(err);
        }));
      },
	  
	  /* this is to reset the Directions Widget*/
	  resetDirections: function(){
        this.getDirectionsDijit().then(lang.hitch(this, function(directionsDijit) {
		  directionsDijit.reset();
		}), lang.hitch(this, function(err) {
          console.error(err);
        }));
      },

      getDirectionsDijit: function(){
        if(!this._dijitDef){
          this._dijitDef = new Deferred();
        }
        if(this._dijitDef.isFulfilled()){
          this._dijitDef = new Deferred();
        }
        if(this._dijitDirections){
          this._dijitDef.resolve(this._dijitDirections);
        }
        return this._dijitDef;
      },

      _handlePopup: function(){
        if(this.map.activeDirectionsWidget && this.map.activeDirectionsWidget.mapClickActive){
          this._disableWebMapPopup();
        }else{
          this._enableWebMapPopup();
        }
      },

      _disableWebMapPopup:function(){
        if(this.map){
          this.map.setInfoWindowOnClick(false);
        }
      },

      _enableWebMapPopup:function(){
        if(this.map){
          this.map.setInfoWindowOnClick(true);
        }
      },

      destroy: function(){
        if(this.map.activeDirectionsWidget === this._dijitDirections){
          this.map.activeDirectionsWidget = null;
        }
        if(this._trafficLayer){
          this.map.removeLayer(this._trafficLayer);
          this._trafficLayer = null;
        }
        this._handlePopup();
        this.inherited(arguments);
      },

      startup: function(){
        this.inherited(arguments);
        this.portal = portalUtils.getPortal(this.appConfig.portalUrl);

        this._preProcessConfig().then(lang.hitch(this, function(){
          var routeParams = new RouteParameters();
          var routeOptions = this.config.routeOptions;
          if(routeOptions){
            if(routeOptions.directionsLanguage){
              routeParams.directionsLanguage = routeOptions.directionsLanguage;
            }
            else{
              routeParams.directionsLanguage = dojoConfig.locale || "en_us";
            }
            routeParams.directionsLengthUnits = routeOptions.directionsLengthUnits;
            routeParams.directionsOutputType = routeOptions.directionsOutputType;
            if(routeOptions.impedanceAttribute){
              routeParams.impedanceAttribute = routeOptions.impedanceAttribute;
            }
          }

          var options = {
            map: this.map,
            searchOptions: this.config.searchOptions,
            routeParams: routeParams,
            routeTaskUrl: this.config.routeTaskUrl,
            dragging: true,
            showClearButton: true,
            mapClickActive: true
          };

          if(this.config.trafficLayerUrl){
            this._trafficLayer = new ArcGISDynamicMapServiceLayer(this.config.trafficLayerUrl);
            options.trafficLayer = this._trafficLayer;
            options.traffic = true;
          }else{
            options.traffic = false;
          }

          if(this.config.travelModesUrl){
            options.travelModesServiceUrl = this.config.travelModesUrl;
            options.doNotFetchTravelModesFromOwningSystem = false;
          } else {
            options.doNotFetchTravelModesFromOwningSystem = true;
          }

          html.empty(this.directionController);
          var directionContainer = html.create('div', {}, this.directionController);
          //Only init Directions dijit when we can access the route task url.
          esriRequest({
            url: options.routeTaskUrl,
            content: {
              f: 'json'
            },
            handleAs: 'json',
            callbackParamName: 'callback'
          }).then(lang.hitch(this, function(){
            this._dijitDirections = new Directions(options, directionContainer);
            //html.place(this._dijitDirections.domNode, this.directionController);
            this._dijitDirections.startup();

            this.own(on(this._dijitDirections,
                       'directions-finish',
                       lang.hitch(this, this._onDirectionsFinish)));

            this.own(on(this._dijitDirections,
                        'map-click-active',
                        lang.hitch(this, this._handlePopup)));

            this._activateDirections();
            this._storeLastActiveState();

            if(this._dijitDef && !this._dijitDef.isFulfilled()){
              this._dijitDef.resolve(this._dijitDirections);
            }
			
			if(showDirections == 'true')
			{
				this.bgManager = new BGManager();
				//this.directionShelter.show();
				this.bgManager.getDirectionRecordResults(fieldsetName, recordIds);
  			    if(dojoSubscribersMap['directionRecordResults_onBGSearchFinish'+'Directions'] != true){
					dojo.subscribe('directionRecordResults', lang.hitch(this, this._onBGSearchFinish));
					dojoSubscribersMap['directionRecordResults_onBGSearchFinish'+'Directions'] = true;
			    }
			}
          }), lang.hitch(this, function(err){
            console.log("Can't access " + options.routeTaskUrl, err);
          }));
        }), lang.hitch(this, function(err){
          console.error(err);
        }));
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
			if(dojoSubscribersMap['bgDirectionResultFinish'+'Directions'] != true){
				dojo.subscribe('bgDirectionResultFinish', lang.hitch(this, this._routeBGPoints, points));
				dojoSubscribersMap['bgDirectionResultFinish'+'Directions'] = true;
			}
			
				
		} else {
			this._addBGLayer(resultsToProject, null);
		}
	  },
	  
	  /* Check if there is more than one stop to add to Directions Widget, else throw error*/
	  _routeBGPoints: function(points) {
		if(points.length > 1)
		{
			this.addBGStops(points);
		}
		else
		{
			new Message({message: "More than 1 stop is needed for routing."});
			return;
		}
	  },
	  	  	  
	  /**  Now plot the BG records on the map  **/
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
		var results = rawResults;
		
		if(results.length == 1){
			new Message({
			  message: 'Cannot find ' + results[0].split('__c_')[1].replace('_bgBufferSearchLayerList','.')
			});
			//this.directionShelter.hide();
			return;
		}
		
		var graphL = new GraphicsLayer();
		//index 0 is always Id
		graphL.id = results[0];			  
		var sym;
		if(results.length > 1){
		    console.debug('*** Inside the marker symbol');
			sym =  new PictureMarkerSymbol(results[1].iconUrl, 24, 24);
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
			
			/* Removing Assign to BG User functionality
			//The default assignee is the record owner
			var bgOwnerId = results[i].ownerId;
			var userOptionString = this.bgAllUsersString;
			if(userOptionString.indexOf(bgOwnerId) != -1)
			{
				userOptionString = userOptionString.replace("\""+bgOwnerId+"\"","\""+bgOwnerId+"\""+" selected = \"true\"");
			} 
			templateString += "Assignee&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<select id=\"cboAssignToUser\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + userOptionString + "</select>" +
			" <button id='btnAssignUser' onClick='var selectListUser = dojo.byId(\"cboAssignToUser\"); var pickValueUser = selectListUser.value; var objectLink = dojo.byId(\"bgObjectLink\"); var objectId = objectLink.href.split(\"visual.force.com\/\")[1]; var params = []; params.push(objectId); params.push(pickValueUser); dojo.publish(\"assignToUserEventBG"+"\", [params]);' dojoType='dijit/form/Button'>Assign</button> <br/><br/>";			
			templateString += "<a href=\"javascript:void(0);\" onClick='var objectLink = dojo.byId(\"bgObjectLink\"); var objectId = objectLink.href.split(\"visual.force.com\/\")[1]; var params = []; params.push(objectId); params.push(currentUserId); dojo.publish(\"assignToUserEventBG"+"\", [params]);' >Assign to me </a> <br/><br/>";*/
			
			//show nearby needs the Layer list which is unknown in the directions widget
			/*templateString += "Show nearby <select id=\"cboProximitySearch\" style=\"width:150px;\" dojoType='dijit/form/Select'>" + this.bgLayersString + "</select>" +
			"<br> Within <input id=\"bufferRadiusValue\" style=\"width:80px;\" type=\"number\" value=\"1000\"> "+
			"<select id=\"bufferRadiusUnitSelect\" style=\"width:130px;\" dojoType='dijit/form/Select'>" + this.bufferRadiusUnits + "</select>" +		
			" <button id='btnGo' onClick='var selectList = dojo.byId(\"cboProximitySearch\"); var pickValue = selectList.value; var bufferValueSelect = dojo.byId(\"bufferRadiusValue\"); var bufferValue = bufferValueSelect.value; var bufferUnitSelectList = dojo.byId(\"bufferRadiusUnitSelect\"); var bufferUnit = bufferUnitSelectList.value; dojo.publish(\"proximitySearchEventBG"+"\", {pickValue, bufferValue, bufferUnit});' dojoType='dijit/form/Button'>Go</button> ";*/
			infoTemplate = new InfoTemplate("Information",templateString);
			graphL.add(new Graphic(po, sym, attr, infoTemplate));
		}
		this.map.addLayer(graphL);		
		
		// publishing to invoke routBGPoints()
		dojo.publish("bgDirectionResultFinish");
		//this.directionShelter.hide();
	  },
	  
	  /* Formats Date type field for BG layer infoTemplate */
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
	  
	  /* Clears the BG Layer drawn on map when "Clear" button is clicked */
	  _clearBGLayers: function(objName){
		var layerIds = this.map.graphicsLayerIds;
		var layer;
		this._hideInfoWindow();
		for(var i = 0 ; i < layerIds.length; i++){
		    //Remove the LayerList layer, do not remove the search Layer
			//if((layerIds[i].indexOf(objName) != -1 || layerIds[i].indexOf('_bgBufferSearchLayerList') != -1) && layerIds[i].indexOf('_bgSearch') == -1) {
			if(layerIds[i].indexOf('directionRecordResults') != -1) {
				layer = this.map.getLayer(layerIds[i]);
				this.map.removeLayer(layer);
			}
		}
	  },
	  
	  /* Hides the Info Popup window when BG Layers are cleared */
	  _hideInfoWindow:function(){
        if(this.map &&this.map.infoWindow){
          this.map.infoWindow.hide();
        }
      },
	  
	  /*Returns true or false based on whter an error is thrown */
	  _isBGError: function(result){
		if(result.indexOf('Exception:') != -1)
		{
			new Message({
			  message: result
			});
			//this.directionShelter.hide();
			return true;
		} else
		{
			return false;
		}
	  },

      onAppConfigChanged: function(appConfig){
        this.appConfig = appConfig;
      },

      _onDirectionsFinish: function(evt){
        if(evt && evt.result){
          var routeResults = evt.result.routeResults;
          if(lang.isArrayLike(routeResults) && routeResults.length > 0){
            var routes = [];
            array.forEach(routeResults, function(routeResult){
              if(routeResult.route){
                routes.push(routeResult.route);
              }
            });
            if(routes.length > 0){
              var ext = null;
              try{
                ext = graphicsUtils.graphicsExtent(routes);
                if(ext){
                  ext = ext.expand(1.3);
                }
              }catch(e){
                console.log(e);
              }
              if(ext){
                this.map.setExtent(ext);
              }
            }
          }
        }
      },

      _preProcessConfig:function(){
        if(!this.config.geocoderOptions){
          this.config.geocoderOptions = {};
        }
        if(!(this.config.geocoderOptions.geocoders &&
         this.config.geocoderOptions.geocoders.length > 0)){
          this.config.geocoderOptions.geocoders = [{
            url: '',
            placeholder: ''
          }];
        }

        var placeholder = this.config.geocoderOptions.geocoders[0].placeholder;

        if(!placeholder){
          if(!this.config.routeTaskUrl){
            //user doesn't open the setting page, we use the default placeholder
            placeholder = this.nls.searchPlaceholder;
          }
        }

        this.config.searchOptions = {
          enableSuggestions: this.config.geocoderOptions.autoComplete,
          maxSuggestions: this.config.geocoderOptions.maxLocations,
          minCharacters: this.config.geocoderOptions.minCharacters,
          suggestionDelay: this.config.geocoderOptions.searchDelay,
          sources: [{
            locator: null,
            name: '',
            singleLineFieldName: '',
            outFields: ["*"],
            placeholder: placeholder
          }]
        };

        var def = new Deferred();
        all([this._getRouteTaskUrl(), this._getLocatorUrl(), this._getTravelModesUrl()]).then(
          lang.hitch(this, function(results){
          this.config.routeTaskUrl = results[0];

          this.config.routeTaskUrl = this._replaceRouteTaskUrlWithAppProxy(this.config.routeTaskUrl);

          var locatorUrl = results[1];
          this.config.travelModesUrl = results[2];
          esriRequest({
            url: locatorUrl,
            hanleAs:'json',
            content:{
              f:'json'
            },
            callbackParamName:'callback'
          }).then(lang.hitch(this, function(geocodeMeta){
            this.config.searchOptions.sources[0].locator = new Locator(locatorUrl);
            this.config.searchOptions.sources[0].name = geocodeMeta.serviceDescription || '';
            this.config.searchOptions.sources[0].singleLineFieldName =
             geocodeMeta.singleLineAddressField && geocodeMeta.singleLineAddressField.name || '';
            def.resolve();
          }), lang.hitch(this, function(err){
            console.error(err);
            def.reject();
          }));
        }), lang.hitch(this, function(err){
          console.error(err);
          def.reject();
        }));
        return def;
      },

      _replaceRouteTaskUrlWithAppProxy: function(routeTaskUrl){
        // Use proxies to replace the routeTaskUrl
        var ret = routeTaskUrl;
        if(!window.isBuilder && !this.appConfig.mode &&
            this.appConfig.appProxies && this.appConfig.appProxies.length > 0) {
          array.some(this.appConfig.appProxies, function(proxyItem) {
            if(routeTaskUrl === proxyItem.sourceUrl) {
              ret = proxyItem.proxyUrl;
              return true;
            }
          });
        }
        return ret;
      },

      _getRouteTaskUrl: function(){
        var def = new Deferred();
        if(this.config.routeTaskUrl){
          def.resolve(this.config.routeTaskUrl);
        }
        else{
          this.portal.loadSelfInfo().then(lang.hitch(this, function(response){
            if(response && response.helperServices && response.helperServices.route){
              def.resolve(response.helperServices.route.url);
            }
            else{
              def.resolve(this._routeTaskUrl);
            }
          }), lang.hitch(this, function(err){
            console.error(err);
            def.resolve(this._routeTaskUrl);
          }));
        }
        return def;
      },

      _getLocatorUrl: function(){
        var def = new Deferred();
        var geocodeArgs = this.config.geocoderOptions &&
         this.config.geocoderOptions.geocoders &&
          this.config.geocoderOptions.geocoders[0];
        var url = geocodeArgs && geocodeArgs.url;
        if(url){
          def.resolve(url);
        }
        else{
          this.portal.loadSelfInfo().then(lang.hitch(this, function(response){
            if(response && response.helperServices &&
             response.helperServices.geocode &&
              response.helperServices.geocode.length > 0){
              var geocode = response.helperServices.geocode[0];
              def.resolve(geocode.url);
            }
            else{
              def.resolve(this._locatorUrl);
            }
          }), lang.hitch(this, function(err){
            console.error(err);
            def.resolve(this._locatorUrl);
          }));
        }
        return def;
      },

      _getTravelModesUrl: function(){
        var def = new Deferred();
        if(this.config.travelModesUrl){
          def.resolve(this.config.travelModesUrl);
        }else{
          if(this.config.routeTaskUrl){
            //user has opend the setting page
            def.resolve(this.config.travelModesUrl);
          }else{
            //user doesn't open the setting page
            this.portal.loadSelfInfo().then(lang.hitch(this, function(response){
              if(response && response.helperServices && response.helperServices.routingUtilities){
                def.resolve(response.helperServices.routingUtilities.url);
              }else{
                def.resolve("");
              }
            }), lang.hitch(this, function(err){
              console.error(err);
              def.reject(err);
            }));
          }
        }
        return def;
      },

      _hide: function(){
        if(this._dijitDirections){
          this._storeLastActiveState();
          this._deactivateDirections();
        }
      },

      _show: function(){
        if(this._dijitDirections){
          this._resetByLastActiveState();
        }
      },

      _storeLastActiveState: function(){
        if(this._dijitDirections){
          this._active = this._dijitDirections.mapClickActive;
        }
      },

      _resetByLastActiveState: function(){
        if(this._dijitDirections){
          if(this._active){
            this._activateDirections();
          }
          else{
            this._deactivateDirections();
          }
          this._storeLastActiveState();
        }
      },

      _activateDirections: function() {
        if (this._dijitDirections) {
          if (typeof this._dijitDirections.activate === 'function') {
            this._dijitDirections.activate();//Deprecated at v3.13
          }
          if (typeof this._dijitDirections.mapClickActive !== "undefined") {
            this._dijitDirections.set("mapClickActive", true);
          }
          this._disableWebMapPopup();
        }
      },

      _deactivateDirections: function() {
        if (this._dijitDirections) {
          if (typeof this._dijitDirections.deactivate === 'function') {
            this._dijitDirections.deactivate();//Deprecated at v3.13
          }
          if (typeof this._dijitDirections.mapClickActive !== "undefined") {
            this._dijitDirections.set("mapClickActive", false);
          }
          this._enableWebMapPopup();
        }
      }

    });
  });