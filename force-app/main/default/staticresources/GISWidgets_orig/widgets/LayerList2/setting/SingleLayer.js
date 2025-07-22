//Wei Zhang

define([
  'dojo/_base/declare',
  'dojo/_base/lang',
  'dojo/_base/array',
  'dojo/_base/html',
  'dojo/_base/query',
  'dojo/on',
  'dojo/json',
  'dijit/_WidgetBase',
  'dijit/_TemplatedMixin',
  'dijit/_WidgetsInTemplateMixin',
  'dijit/Tooltip',
  'dojo/text!./SingleLayer.html',
  'dijit/form/TextBox',
  'jimu/dijit/LayerFieldChooser',
  'jimu/dijit/IncludeButton',
  'jimu/dijit/SimpleTable',
  'jimu/dijit/URLInput',
  'esri/request',
  'dijit/form/Select'
],
function(declare, lang, array, html, query, on,json,_WidgetBase,_TemplatedMixin, _WidgetsInTemplateMixin,
  Tooltip,template,TextBox,LayerFieldChooser,IncludeButton,SimpleTable,URLInput,esriRequest, Select, domStyle) {/*jshint unused: false*/
  return declare([_WidgetBase,_TemplatedMixin,_WidgetsInTemplateMixin], {
    baseClass: 'jimu-widget-singlelayer-setting',
    templateString:template,
    nls:null,
    config:null,
    layerSetting:null,
    _url:"",
    _layerDef:null,
    _isAddNow:true,

    postCreate:function(){
      this.inherited(arguments);
	  this._initSelectbox();
      this._bindEvents();
      this.setConfig(this.config);
      this._isAddNow = this.config ? false : true;
      this.updateStatus(this._isAddNow);
    },

    setConfig:function(config){
      this.config = config;
      this.resetAll();
      if(!this.config){
        return;
      }
      
      this._url = lang.trim(this.config.url || "");
	  this.layerUrl.set('value', this._url);
      this.layerName.set('value', lang.trim(this.config.label || ""));
      this.layerType.set('value', lang.trim(this.config.type || ""));
    },

    getConfig:function(){
      if(!this.validate(false)){
        return false;
      }

      var config = {
        //url:this._url,
		url:lang.trim(this.layerUrl.get('value')),
		label:lang.trim(this.layerName.get('value')),       
        type:lang.trim(this.layerType.get('value'))
      };
      this.config = config;
      return this.config;
    },

    updateStatus:function(isAddNow){
      this._isAddNow = !!isAddNow;
      if(this._isAddNow){
        html.setStyle(this.btnAdd,'display','block');
        html.setStyle(this.btnUpdate,'display','none');
      }
      else{
        html.setStyle(this.btnUpdate,'display','block');
        html.setStyle(this.btnAdd,'display','none');
      }
    },

    onAdd:function(config){/*jshint unused: false*/},

    onUpdate:function(config){/*jshint unused: false*/},

    onAddCancel:function(){},

    onUpdateCancel:function(){},
	
	_initSelectbox:function(){		
		var layerOptions = [
			{
				label:"BasicGov Layer",
				value:"basicgov"
			},
			{
				label:"GIS Feature Layer",
				value:"feature"
			}
		];
		layerOptions[1].selected = true;
		this.layerType.addOption(layerOptions);
	},

    _bindEvents:function(){
      this.own(on(this.btnAdd,'click',lang.hitch(this,function(){
        var config = this.getConfig();
        if(config){
          this.setConfig(config);
          this.updateStatus(false);
          this.onAdd(config);
        }
      })));
      this.own(on(this.btnUpdate,'click',lang.hitch(this,function(){
        var config = this.getConfig();
        if(config){
          this.updateStatus(false);
          this.onUpdate(config);
        }
      })));
      this.own(on(this.btnCancel,'click',lang.hitch(this,function(){
        if(this._isAddNow){
          this.onAddCancel();
        }
        else{
          this.setConfig(this.config);
          this.onUpdateCancel();
        }
      })));
    },

    validate:function(showTooltip){
	  if(lang.trim(this.layerUrl.get('value')) === ''){
		if(showTooltip){
		  this._showTooltip(this.layerUrl.domNode,"Please input value.");
		}
		return false;
	  }
      if(lang.trim(this.layerName.get('value')) === ''){
        if(showTooltip){
          this._showTooltip(this.layerName.domNode,"Please input value.");
        }
        return false;
      }
      if(lang.trim(this.layerType.get('value')) === ''){
        if(showTooltip){
          this._showTooltip(this.layerType.domNode,"Please input value.");
        }
        return false;
      }
      return true;
    },

    _showTooltip:function(aroundNode, content, time){
      this._scrollToDom(aroundNode);
      Tooltip.show(content,aroundNode);
      time = time ? time : 2000;
      setTimeout(function(){
        Tooltip.hide(aroundNode);
      },time);
    },

    _scrollToDom:function(dom){
      var scrollDom = this.layerSetting.domNode.parentNode;
      var y1 = html.position(scrollDom).y;
      var y2 = html.position(dom).y;
      scrollDom.scrollTop = y2 - y1;
    },

    onBack:function(singleLayer,config){/*jshint unused: false*/},
	
    resetAll:function(){
      this._url = '';
      this.layerUrl.set('value', this._url);
      this.layerName.set('value', '');
      this.layerType.set('value', 'feature');
    }
  });
});