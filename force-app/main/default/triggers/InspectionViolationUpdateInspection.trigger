Trigger InspectionViolationUpdateInspection on MUSW__Inspection_Violation__c (after insert, after update, after delete)
{
    MUSW__Inspection_Violation__c[] ivs = trigger.isDelete ? trigger.old : trigger.new;
    Id[] insIds = new Id[]{};
    for (MUSW__Inspection_Violation__c iv : ivs) insIds.add(iv.MUSW__Inspection__c);
    
    if (insIds.size() > 0)
    {
        MUSW__Inspection__c[] ins = [select Id, Current_Violations__c, (select Id, Ordinance__c from MUSW__Inspection_Violations__r) from MUSW__Inspection__c where Id in :insIds];
        
        for (MUSW__Inspection__c i : ins)
        {
            String types = '';
            for (MUSW__Inspection_Violation__c iv : i.MUSW__Inspection_Violations__r)
            {
              if (!types.contains(', ' + iv.Ordinance__c)) types += ', ' + iv.Ordinance__c;
            }
            types = types.replaceFirst(', ', '');
            if (types.length() > 255) types = types.substring(0, 251) + '...';
            i.Current_Violations__c = types;
        }
        
        // the inspection might be locked by another trigger. if so skip
        try
        {
            TriggerService.setLock();
            update ins;
        }
        catch (System.Dmlexception ex)
        {
            if (!ex.getMessage().contains('SELF_REFERENCE_FROM_TRIGGER')) throw ex;
        }
        finally
        {
            TriggerService.releaseLock();
        }
    }
}