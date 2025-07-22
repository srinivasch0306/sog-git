trigger InspectionViolationAddInspection on MUSW__Inspection_Violation__c (before insert)
{
    /*  creates Inspections for IV's inserted by DRE as a result of a re-inspection request
     *  uses the DREgen flag to determine if IV was created by DRE
     */
    
    Map<Id, MUSW__Inspection_Violation__c[]> inspIvsMap = new Map<Id, MUSW__Inspection_Violation__c[]>();
    Id[] insIds = new Id[]{};
    Id[] vids = new Id[]{};
    for (MUSW__Inspection_Violation__c iv : trigger.new)
    {
             if (iv.MUSW__DREgen__c)
        {
            if (inspIvsMap.containsKey(iv.MUSW__Inspection__c)) inspIvsMap.get(iv.MUSW__Inspection__c).add(iv);
            else inspIvsMap.put(iv.MUSW__Inspection__c, new MUSW__Inspection_Violation__c[]{iv});
            
            insIds.add(iv.MUSW__Inspection__c);
            vids.add(iv.MUSW__Violation__c);
        }
    }
    if (insIds.size() == 0 && vids.size() == 0) return;
    
    // query for related Inspections and Violations
    MUSW__Inspection__c[] insq = database.query('select ' + MUSW.UtilityDb.getFieldsFor_Str('MUSW__Inspection__c', false) + ', RecordTypeId from MUSW__Inspection__c where Id in :insIds');
    Map<Id, MUSW__Inspection__c> insqMap = new Map<Id, MUSW__Inspection__c>(insq);
    
    MUSW__Violation__c[] vq = [select MUSW__Status__c, MUSW__Complaint2__c, Permit2__c from MUSW__Violation__c where Id in :vids];
    Map<Id, MUSW__Violation__c> vqMap = new Map<Id, MUSW__Violation__c>(vq);
    
    // create one/many Inspections for each IV, depending on whether Days_to_next is specified
    MUSW__Inspection__c[] reinsList = new MUSW__Inspection__c[]{};
    Map<MUSW__Inspection_Violation__c, MUSW__Inspection__c> ivReinsMap = new Map<MUSW__Inspection_Violation__c, MUSW__Inspection__c>();
    for (Id insId : inspIvsMap.keySet())
    {
      // if Days_to_next specified: one re-Inspection for all IV's
        if (insqMap.get(insId).Days_to_Next_Inspection__c != null)
        {
            MUSW__Inspection_Violation__c iv = inspIvsMap.get(insId)[0];
            MUSW__Inspection__c reins = TriggerService.createReinspectionFromIV(
                insqMap.get(insId), vqMap.get(iv.MUSW__Violation__c), iv);
            reinsList.add(reins);
            
            for (MUSW__Inspection_Violation__c ivx : inspIvsMap.get(insId)) ivReinsMap.put(ivx, reins);
        }
        else // group by IV.days_to_correct, and create one re-inspection for group
        {
            Map<String, MUSW__Inspection_Violation__c[]> ivGrouped = TriggerService.groupIVs(inspIvsMap.get(insId));
            
            // for each key create a re-inspection
            for (String key : ivGrouped.keySet())
            {
                MUSW__Inspection_Violation__c iv = ivGrouped.get(key)[0];
                MUSW__Inspection__c reins = TriggerService.createReinspectionFromIV(
                    insqMap.get(insId), vqMap.get(iv.MUSW__Violation__c), iv);
                reinsList.add(reins);
                
                for (MUSW__Inspection_Violation__c ivx : ivGrouped.get(key)) ivReinsMap.put(ivx, reins);
            }
        }
    }
    
    if (reinsList.size() > 0)
    {
        insert reinsList;
        
        // overwrite IV.Inspection with the corresponding newly inserted Inspection
        for (MUSW__Inspection_Violation__c iv : ivReinsMap.keySet())
        {
            iv.MUSW__Inspection__c = ivReinsMap.get(iv).Id;
        }
    }
}