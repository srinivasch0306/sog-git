public with sharing class DRETriggerHandler implements BGCM.ITriggerHandler
{
    private set<String> HandlerScope;
    public DRETriggerHandler(){}
    public DRETriggerHandler(Set<String> scope){
        HandlerScope = scope;
    }

    public void onBeforeInsert() {}
    public void onBeforeUpdate() { executeDRE(); }
    public void onBeforeDelete() { executeDRE(); }
    public void onBeforeUndelete() {}
    public void onAfterInsert() { executeDRE(); }
    public void onAfterUpdate() {}
    public void onAfterDelete() {}
    public void onAfterUndelete() { executeDRE(); }
  
    private void executeDRE()
    {
        Boolean commitResults = false;
        DRE.DREOutput output;
        
        if((HandlerScope != null) && (HandlerScope.size() > 0)){
            output = DRE.DREManager.runTriggerWithScope(HandlerScope);
        }
        else{
            output = DRE.DREManager.runTrigger(commitResults);
            
            if (output == null) return;
 
            BGCM.DMLManager.upsertRecords(output.getSObjectsForUpsert());
     
            Boolean commitUpserts = false,
                    commitDeletes = true,
                    commitCustomResults = true,
                    sendEmails = true;
      
            // must be the last thing that happens
            DRE.DREManager.commitResults(output, commitUpserts, commitDeletes, commitCustomResults, sendEmails);
        }
    }
}