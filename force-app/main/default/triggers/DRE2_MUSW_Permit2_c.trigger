trigger DRE2_MUSW_Permit2_c on MUSW__Permit2__c (after insert, before update, before delete, after undelete) 
{ 
    Set<String> Scope = new Set<String>();
    
    if(Trigger.New != null)
    {
        for(MUSW__Permit2__c Permit: Trigger.New)
        {
            // Add Status to DRE Scope
            Scope.add(Permit.MUSW__Status__c);
        }
    }
    
    System.debug('### Scope: ' + Scope);
    
    if(Scope.size() > 0)
        BGCM.TriggerManager.execute('DRE2_MUSW_Permit2_c', new DRETriggerHandler(Scope));
    else
        BGCM.TriggerManager.execute('DRE2_MUSW_Permit2_c', new DRETriggerHandler());
}