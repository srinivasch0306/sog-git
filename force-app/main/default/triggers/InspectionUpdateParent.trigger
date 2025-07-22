trigger InspectionUpdateParent on MUSW__Inspection__c (before update)
{
  /* 
   *  this trigger runs recursively for the chain of Inspections all the way to the root Inspection
   */
    
    MUSW__Inspection__c[] recs = trigger.new;
    
    Set<Id> closedIds = new Set<Id>();
    Id[] parentIds = new Id[]{};
    for (Integer i=0; i<recs.size(); i++)
    {
        if (((recs[i].Pass_Fail__c == 'Passed' && recs[i].Pass_Fail__c != trigger.old[i].Pass_Fail__c) ||
          (recs[i].Inspection_Chain_Closed__c && recs[i].Inspection_Chain_Closed__c != trigger.old[i].Inspection_Chain_Closed__c)) &&
          recs[i].MUSW__Type__c != 'Field Observation')
        {
            recs[i].Inspection_Chain_Closed__c = true;
            closedIds.add(recs[i].Id);
            if (recs[i].MUSW__Previous_Inspection__c != null) parentIds.add(recs[i].MUSW__Previous_Inspection__c);
        }
    }
    
    // mark off parent inspections as Chain_Closed if they have no open children
    if (parentIds.size() > 0)
    {
        MUSW__Inspection__c[] parentIns = [select Id, MUSW__Previous_Inspection__c, (select Id, Inspection_Chain_Closed__c from MUSW__Next_Inspections__r) from MUSW__Inspection__c where Id in :parentIds];
        
        MUSW__Inspection__c[] parents2closeChain = new MUSW__Inspection__c[]{};
        MUSW__Inspection__c[] parents2closeChainRoot = new MUSW__Inspection__c[]{};
        for (MUSW__Inspection__c parIns : parentIns)
        {
            Boolean foundOpenSub = false;
            for (MUSW__Inspection__c sub : parIns.MUSW__Next_Inspections__r)
            {
                if (!sub.Inspection_Chain_Closed__c && !closedIds.contains(sub.Id))
                {
                    foundOpenSub = true;
                    break;
                }
            }
            
            if (!foundOpenSub)
            {
                parIns.Inspection_Chain_Closed__c = true;
                
                if (parIns.MUSW__Previous_Inspection__c == null) parents2closeChainRoot.add(parIns);
                else parents2closeChain.add(parIns);
            }
        }
        
        if (parents2closeChain.size() > 0 || parents2closeChainRoot.size() > 0)
        {
            // do not block DRE for root Inspections (DRE letter rules need to run)
            if (parents2closeChainRoot.size() > 0)
            {
                update parents2closeChainRoot;
            }
            if (parents2closeChain.size() > 0)
            {
                TriggerService.setLock();
                update parents2closeChain;
                TriggerService.releaseLock();
            }
        }
    }
}