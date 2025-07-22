trigger DRE2_MUSW_Fee_c on MUSW__Fee__c (after insert, before update, before delete, after undelete) 
//trigger DRE2_MUSW_Fee_c on MUSW__Fee__c (after insert, before update, before delete, after undelete) { BGCM.TriggerManager.execute('DRE2_MUSW_Fee_c', new DRETriggerHandler()); }
{ 
    Set<String> Scope = new Set<String>();
    
    System.debug('### Before Scoping');
    
    if(Trigger.New != null)
    {
        for(MUSW__Fee__c Fee: Trigger.New)
        {
            // Add Fee Type and Status to DRE Scope
            if (Fee.MUSW__Type__c != null)
                Scope.add(Fee.MUSW__Type__c);
            //if (Fee.MUSW__Permit2__r.MUSW__Status__c != null)    
                //Scope.add(Fee.MUSW__Permit2__r.MUSW__Status__c);
        }
        
                
    }
    
    System.debug('### Scope: ' + Scope);
    
    if(Scope.size() > 0)
        BGCM.TriggerManager.execute('DRE2_MUSW_Fee_c', new DRETriggerHandler(Scope));
    else
        BGCM.TriggerManager.execute('DRE2_MUSW_Fee_c', new DRETriggerHandler());
}