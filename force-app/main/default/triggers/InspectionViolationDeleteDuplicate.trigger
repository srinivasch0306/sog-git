trigger InspectionViolationDeleteDuplicate on MUSW__Inspection_Violation__c (after insert)
{
  Map<Id, MUSW__Inspection_Violation__c> trigMap = trigger.newMap;
  MUSW__Inspection_Violation__c[] trig = [select Id, MUSW__Violation__c, MUSW__Inspection__c, MUSW__Inspection__r.MUSW__Previous_Inspection__c from MUSW__Inspection_Violation__c where Id in :trigMap.keySet()];
    
    MUSW__Inspection_Violation__c[] dupIVs = new MUSW__Inspection_Violation__c[]{};
    MUSW__Inspection__c[] dupIns = new MUSW__Inspection__c[]{};
    for (Integer i=trig.size()-1; i>=0; i--)
    {
        for (Integer j=0; j<trig.size(); j++)
        {
            if (trig[i].MUSW__Violation__c == trig[j].MUSW__Violation__c && 
              trig[i].MUSW__Inspection__r.MUSW__Previous_Inspection__c == trig[j].MUSW__Inspection__r.MUSW__Previous_Inspection__c && 
              trig[i].Id != trig[j].Id)
          {
              dupIVs.add(new MUSW__Inspection_Violation__c(Id=trig[i].Id));
              dupIns.add(trig[i].MUSW__Inspection__r);
              trig.remove(i);
              break;
          }
        }
    }
    
    if (dupIVs.size() > 0)
    {
      delete dupIVs;
      delete dupIns;
  }
}