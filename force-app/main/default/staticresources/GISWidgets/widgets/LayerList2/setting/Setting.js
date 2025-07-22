//Wei Zhang
define([
  'dojo/_base/declare',
  'dojo/_base/lang',
  'dojo/_base/array',
  'dojo/_base/html',
  'dojo/_base/query',
  'dojo/on',
  'dojo/json',
  'dijit/_WidgetsInTemplateMixin',
  'jimu/BaseWidgetSetting',
  'jimu/dijit/SimpleTable',
  './SingleLayer',
  'dijit/form/NumberTextBox',
  'dijit/form/TextBox',
  'dijit/form/Select',
  'esri/request'
],
function(declare, lang, array, html, query, on,json, _WidgetsInTemplateMixin,BaseWidgetSetting,
  SimpleTable,SingleLayer,NumberTextBox,TextBox,Select,esriRequest) {/*jshint unused: false*/
  return declare([BaseWidgetSetting,_WidgetsInTemplateMixin], {
    baseClass: 'jimu-widget-layerList2-setting',

    postCreate:function(){
	  this.inherited(arguments);
      this._bindEvents();
      this.setConfig(this.config);
    },

    setConfig:function(config){
      this._showLayerListSection();
      this.config = config;
      this.reset();
      if(!this.config){
        return;
      }
	  this.showLegend.setChecked(config.showLegend);
      this._initLayerListTable();
    },

    getConfig:function(){
      var config = {};
      var allSingleLayers = this._getAllSingleLayers();
      var valid = this.validate();
      if(!valid){
        return false;
      }
      var layers = array.map(allSingleLayers,lang.hitch(this,function(item){
        return item.getConfig();
      }));
      config.layers = layers;
	  config.showLegend = this.showLegend.checked;
      this.config = lang.mixin({},config);
      return config;
    },

    _bindEvents:function(){
      this.own(on(this.btnAddLayer,'click',lang.hitch(this,function(){
        var args = {
          config:null
        };
        var tr = this._createSingleLayer(args);
        if(tr){
          var sl = tr.singleLayer;
          this._showSingleLayerSection(sl);
        }
      })));
      this.own(on(this.layerListTable,'Edit',lang.hitch(this,function(tr){
        var singleLayer = tr.singleLayer;
        if(singleLayer){
          this._showSingleLayerSection(singleLayer);
        }
      })));
      this.own(on(this.layerListTable,'Delete',lang.hitch(this,function(tr){
        var singleLayer = tr.singleLayer;
        if(singleLayer){
          singleLayer.destroy();
        }
        delete tr.singleLayer;
      })));
      this.own(on(this.layerListTable,'Clear',lang.hitch(this,function(trs){
        array.forEach(trs,lang.hitch(this,function(tr){
          var singleLayer = tr.singleLayer;
          if(singleLayer){
            singleLayer.destroy();
          }
          delete tr.singleLayer;
        }));
      })));
    },

    reset:function(){
      this.layerListTable.clear();
    },

    validate:function(){
      var allSingleLayers = this._getAllSingleLayers();
      var valid = array.every(allSingleLayers,lang.hitch(this,function(item){
        return item.validate(false);
      }));
      return valid;
    },

    _showLayerListSection:function(){
      html.setStyle(this.layerListSection,'display','block');
      html.setStyle(this.singleLayerSection,'display','none');
    },

    _showSingleLayerSection:function(singleLayer){
      this._hideSingleLayer(singleLayer);
      html.setStyle(this.layerListSection,'display','none');
      html.setStyle(this.singleLayerSection,'display','block');
    },

    _initLayerListTable:function(){
      this.layerListTable.clear();
      var layers = this.config && this.config.layers;
      array.forEach(layers, lang.hitch(this, function(layerConfig) {
        var args = {
          config:layerConfig
        };
        this._createSingleLayer(args);
      }));
    },

    _createSingleLayer:function(args){
      args.layerSetting = this;
      args.nls = this.nls;
      var rowData = {
        name: (args.config && args.config.label)||''
      };
      var result = this.layerListTable.addRow(rowData);
      if(!result.success){
        return null;
      }
      var singleLayer = new SingleLayer(args);
      singleLayer.placeAt(this.singleLayerSection);
      singleLayer.startup();
      html.setStyle(singleLayer.domNode,'display','none');
      result.tr.singleLayer = singleLayer;
      this.own(on(singleLayer,'Add',lang.hitch(this,function(config){
        var name = config.label||'';
        this.layerListTable.editRow(result.tr,{name:name});
        this._showLayerListSection();
      })));
      this.own(on(singleLayer,'Update',lang.hitch(this,function(config){
        var name = config.label||'';
        this.layerListTable.editRow(result.tr,{name:name});
        this._showLayerListSection();
      })));
      this.own(on(singleLayer,'AddCancel',lang.hitch(this,function(){
        delete result.tr.singleLayer;
        this.layerListTable.deleteRow(result.tr);
        singleLayer.destroy();
        this._showLayerListSection();
      })));
      this.own(on(singleLayer,'UpdateCancel',lang.hitch(this,function(){
        this._showLayerListSection();
      })));
      // this.own(on(singleLayer,'Back',lang.hitch(this,function(ss,newLayerInfo){
      //   var name = newLayerInfo.name;
      //   this.layerListTable.editRow(result.tr,{name:name});
      //   this._showLayerListSection();
      // })));
      return result.tr;
    },

    _hideSingleLayer:function(ignoredSingleLayer){
      var allSingleLayers = this._getAllSingleLayers();
      array.forEach(allSingleLayers,lang.hitch(this,function(item){
        html.setStyle(item.domNode,'display','none');
      }));
      if(ignoredSingleLayer){
        html.setStyle(ignoredSingleLayer.domNode,'display','block');
      }
    },

    _getAllSingleLayers:function(){
      var trs = this.layerListTable._getNotEmptyRows();
      var allSingleLayers = array.map(trs,lang.hitch(this,function(item){
        return item.singleLayer;
      }));
      return allSingleLayers;
    }
  });
});