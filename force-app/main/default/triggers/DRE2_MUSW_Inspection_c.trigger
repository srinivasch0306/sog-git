trigger DRE2_MUSW_Inspection_c on MUSW__Inspection__c (after insert, before update, before delete, after undelete) 
{ 
//BGCM.TriggerManager.execute('DRE2_MUSW_Inspection_c', new DRETriggerHandler());
 Set<String> Scope = new Set<String>();
    String Status;
    
    if(Trigger.New != null)
    {
        for(MUSW__Inspection__c Inspection: Trigger.New)
        {
            // Add Status to DRE Scope
            if(Inspection.MUSW__Status__c != null){
                Status = Inspection.MUSW__Status__c;
                Status = Status.replace('-',''); //to remove non-alpha numeric values
                Status = Status.replace('  ',' '); //to remove double spaces
                Scope.add(Status);
            }
            
            // Add Close Inspection to DRE Scope
            if(Inspection.close_inspection__c)
                Scope.add('Close Inspection');
        }
    }
   
    System.debug('### Scope: ' + Scope);
    
    if(Scope.size() > 0)
        BGCM.TriggerManager.execute('DRE2_MUSW_Inspection_c', new DRETriggerHandler(Scope));
    else
        BGCM.TriggerManager.execute('DRE2_MUSW_Inspection_c', new DRETriggerHandler());
 
}