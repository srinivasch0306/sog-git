/**
 * Description of class
 * original source https://github.com/kevinohara80/sfdc-trigger-framework 
 * last modified by Jason Li
 * @date 06/20/2021
 *  
 */

public virtual class AvoTriggerHandler {

    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;
  
    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;
  
    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;
  
    // static initialization
    static {
      loopCountMap = new Map<String, LoopCount>();
      bypassedHandlers = new Set<String>();
    }
    
    // constructor
    public AvoTriggerHandler() {
      this.setTriggerContext();
    }
  
    /***************************************
     * public instance methods
     ***************************************/
  
    // main method that will be called during execution
    public void run() {
        
        List<AVO_Process_Engine_Settings__c> settings = [SELECT Id FROM AVO_Process_Engine_Settings__c];
        if (settings.isEmpty()) {
            AVO_Process_Engine_Settings__c defaultSettings = new AVO_Process_Engine_Settings__c();
            Insert defaultSettings;
        }
        
        if (AVO_Process_Engine_Settings__c.getOrgDefaults().AVO_Process_Engine_Enabled__c == false) {
            return;
        }
        
      if(!validateRun()) {
        return;
      }
  
      addToLoopCount();
  
      // dispatch to the correct handler method
      switch on this.context {
        when BEFORE_INSERT {
          this.beforeInsert();
        }
        when BEFORE_UPDATE {
          this.beforeUpdate();
        }
        when BEFORE_DELETE {
          this.beforeDelete();
        }
        when AFTER_INSERT {
          this.afterInsert();
        }
        when AFTER_UPDATE {
          this.afterUpdate();
        }
        when AFTER_DELETE {
          this.afterDelete();
        }
        when AFTER_UNDELETE {
          this.afterUndelete();
        }
      }
    }
  
    public void setMaxLoopCount(Integer max) {
      String handlerName = getHandlerName();
      if(!AvoTriggerHandler.loopCountMap.containsKey(handlerName)) {
        AvoTriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
      } else {
        AvoTriggerHandler.loopCountMap.get(handlerName).setMax(max);
      }
    }
  
    public void clearMaxLoopCount() {
      this.setMaxLoopCount(-1);
    }
  
    /***************************************
     * public static methods
     ***************************************/
  
    public static void bypass(String handlerName) {
      AvoTriggerHandler.bypassedHandlers.add(handlerName);
    }
  
    public static void clearBypass(String handlerName) {
      AvoTriggerHandler.bypassedHandlers.remove(handlerName);
    }
  
    public static Boolean isBypassed(String handlerName) {
      return AvoTriggerHandler.bypassedHandlers.contains(handlerName);
    }
  
    public static void clearAllBypasses() {
      AvoTriggerHandler.bypassedHandlers.clear();
    }
  
    /***************************************
     * private instancemethods
     ***************************************/
  
    @TestVisible
    private void setTriggerContext() {
      this.setTriggerContext(null, false);
    }
  
    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
      if(!Trigger.isExecuting && !testMode) {
        this.isTriggerExecuting = false;
        return;
      } else {
        this.isTriggerExecuting = true;
      }
      
      if((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
          (ctx != null && ctx == 'before insert')) {
        this.context = TriggerContext.BEFORE_INSERT;
      } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
          (ctx != null && ctx == 'before update')){
        this.context = TriggerContext.BEFORE_UPDATE;
      } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
          (ctx != null && ctx == 'before delete')) {
        this.context = TriggerContext.BEFORE_DELETE;
      } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
          (ctx != null && ctx == 'after insert')) {
        this.context = TriggerContext.AFTER_INSERT;
      } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
          (ctx != null && ctx == 'after update')) {
        this.context = TriggerContext.AFTER_UPDATE;
      } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
          (ctx != null && ctx == 'after delete')) {
        this.context = TriggerContext.AFTER_DELETE;
      } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
          (ctx != null && ctx == 'after undelete')) {
        this.context = TriggerContext.AFTER_UNDELETE;
      }
    }
  
    // increment the loop count
    @TestVisible
    private void addToLoopCount() {
      String handlerName = getHandlerName();
      if(AvoTriggerHandler.loopCountMap.containsKey(handlerName)) {
        Boolean exceeded = AvoTriggerHandler.loopCountMap.get(handlerName).increment();
        if(exceeded) {
          Integer max = AvoTriggerHandler.loopCountMap.get(handlerName).max;
          throw new AvoTriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
        }
      }
    }
  
    // make sure this trigger should continue to run
    @TestVisible
    private Boolean validateRun() {
      if(!this.isTriggerExecuting || this.context == null) {
        throw new AvoTriggerHandlerException('Trigger handler called outside of Trigger execution');
      }
      return !AvoTriggerHandler.bypassedHandlers.contains(getHandlerName());
    }
  
    @TestVisible
    private String getHandlerName() {
      return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }
  
    /***************************************
     * context methods
     ***************************************/
  
    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert(){}
    @TestVisible
    protected virtual void beforeUpdate(){}
    @TestVisible
    protected virtual void beforeDelete(){}
    @TestVisible
    protected virtual void afterInsert(){}
    @TestVisible
    protected virtual void afterUpdate(){}
    @TestVisible
    protected virtual void afterDelete(){}
    @TestVisible
    protected virtual void afterUndelete(){}
  
    /***************************************
     * inner classes
     ***************************************/
  
    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
      private Integer max;
      private Integer count;
  
      public LoopCount() {
        this.max = 5;
        this.count = 0;
      }
  
      public LoopCount(Integer max) {
        this.max = max;
        this.count = 0;
      }
  
      public Boolean increment() {
        this.count++;
        return this.exceeded();
      }
  
      public Boolean exceeded() {
        return this.max >= 0 && this.count > this.max;
      }
  
      public Integer getMax() {
        return this.max;
      }
  
      public Integer getCount() {
        return this.count;
      }
  
      public void setMax(Integer max) {
        this.max = max;
      }
    }
  
    // possible trigger contexts
    @TestVisible
    private enum TriggerContext {
      BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
      AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
      AFTER_UNDELETE
    }
  
    // exception class
    public class AvoTriggerHandlerException extends Exception {}
  
  }