global with sharing class TriggerService
{
    private static Boolean locked = false;
    private static Integer counter = 0;
    
    public static void setLock()
    {
        BGBK.RulesEngineState.setLock();
        // Added for SUP-676
        DRE.DREManager.setLock();
        counter++;
        locked = true;
    }
    
    public static void releaseLock()
    {
        // Added for SUP-676
        // DRE 2.0 has a counter for its locks (when count = 0 it gets unlocked)
        // DRE 1.0 has a boolean (which is not ideal for nested executions)
        DRE.DREManager.releaseLock();

        counter--;
        if (counter == 0)
        {
            BGBK.RulesEngineState.releaseLock();
            locked = false;
        }
    }
    
    public static Boolean isLocked()
    {
        return locked;
    }
    
    public static Boolean isRulesEngineActive()
    {
        Boolean active = false;
        Map<String, BGBK__GlobalSettings__c> gsMap = BGBK__GlobalSettings__c.getAll();
        if (gsMap.containsKey('Default'))
        {
            BGBK__GlobalSettings__c gs = BGBK__GlobalSettings__c.getValues('Default');
            active = Boolean.valueOf(gs.BGBK__rulesEngineActive__c);
        }
        
        return active;
    }
    
    @future
    public static void updateSubmissionTotals(Id[] subIds)
    {
        if (subIds.size() > 0)
        {
            MUSW__Submission__c[] subs = [select Id, MUSW__Total_Approved_Reviews__c, MUSW__Total_Failed_Reviews__c, MUSW__Total_Reviews__c, (select Id, Status2__c from MUSW__Reviews__r) from MUSW__Submission__c where Id in :subIds];
            
            for (MUSW__Submission__c s : subs)
            {
                Integer countTotal = 0, countFailed = 0, countApproved = 0;
                for (MUSW__Review__c r : s.MUSW__Reviews__r)
                {
                    countTotal++;
                    if (r.Status2__c == 'Approved') countApproved++;
                    else if (r.Status2__c == 'Failed') countFailed++;
                }
                
                s.MUSW__Total_Reviews__c = countTotal;
                s.MUSW__Total_Approved_Reviews__c = countApproved;
                s.MUSW__Total_Failed_Reviews__c = countFailed;
            }
            
            //TriggerService.setLock();
            update subs;
            //TriggerService.releaseLock();
        }
    }
    
        
    /*
     *  Groups IV's by whatever criteria if Inspection.Days_to_next is blank
     */
    public static Map<String, MUSW__Inspection_Violation__c[]> groupIVs(MUSW__Inspection_Violation__c[] ivs)
    {
        Map<String, MUSW__Inspection_Violation__c[]> ivGrouped = new Map<String, MUSW__Inspection_Violation__c[]>(); // <days_to_correct, IVs>
        String key;
        for (MUSW__Inspection_Violation__c iv : ivs)
        {
            // true if Inspection already there (for reinspections)
            if (iv.Days_to_correct__c != null) key = iv.Days_to_correct__c.toPlainString();
            else key = iv.MUSW__Violation__r.Days_to_correct__c.toPlainString();
            
            if (ivGrouped.containsKey(key)) ivGrouped.get(key).add(iv);
            else ivGrouped.put(key, new MUSW__Inspection_Violation__c[]{iv});
        }
        
        return ivGrouped;
    }
    
    public static MUSW__Inspection__c createReinspectionFromIV(MUSW__Inspection__c initInsp, MUSW__Violation__c v, MUSW__Inspection_Violation__c iv)
    {
        MUSW__Inspection__c ins = initInsp.clone(false, true);
                    
        ins.Name = null;
        ins.MUSW__Type__c = (v.MUSW__Status__c == 'Contractor Completed') ? 'Re-inspection Contractor Completion' : 'Re-inspection';
        ins.MUSW__Status__c = 'Pending';
        ins.Close_Inspection__c = false;
        ins.MUSW__On_Itinerary__c = false;
        ins.Letter_Generated__c = false;
        ins.MUSW__Scheduled_Start_Date__c = null;
        ins.Requested_DateTime__c = null;
        ins.MUSW__Completed_Date__c = null;

        ins.MUSW__Due_Date__c = 
            (iv.Due_Date__c != null) 
            ? Date.newInstance(iv.Due_Date__c.year(), iv.Due_Date__c.month(), iv.Due_Date__c.day())
            : null;
        ins.MUSW__Previous_Inspection__c = initInsp.Id;
        ins.RecordTypeId = initInsp.RecordTypeId;
        
        if (ins.Group__c == 'Fire') ins.OwnerId = UserInfo.getUserId();
        
        // MOS: this was causing re-inspection to be created with no parent while SOME violations had a parent
        //      therefore those violations wouldn't show up on New/Edit Violations page
        // comment obsolete: prior inspection may be on parent but IV may be unrelated (i.e. no parents)
        ins.MUSW__Permit__c = initInsp.MUSW__Permit__c; //v.Permit2__c;
        ins.MUSW__Complaint2__c = initInsp.MUSW__Complaint2__c; //v.MUSW__Complaint2__c;
        
        return ins;
    }
}