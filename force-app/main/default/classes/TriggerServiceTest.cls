@isTest
public class TriggerServiceTest {
	@isTest(SeeAllData=true)
    private static void testSubTotals()
    {
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='zsdfsf');
        insert par;
        MUSW__Permit2__c p = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.Id,AVO_Volumetric_Limits__c= 10, name = 'Sequence Number');
        insert p;
        MUSW__Submission__c s = new MUSW__Submission__c(MUSW__Permit2__c=p.Id);
        insert s;
        MUSW__Review__c r = new MUSW__Review__c(MUSW__Submission__c=s.Id, MUSW__Due_Date__c=system.today());
        insert r;
    }
    
    @isTest(SeeAllData=true)
    private static void testSubTotals1()
    {
        
        
           MUSW__Parcel__c par = new MUSW__Parcel__c(Name='zsdfsf');
           insert par;
           MUSW__Permit2__c p = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.Id,AVO_Volumetric_Limits__c= 10, name = 'Sequence Number');
           insert p;
           MUSW__Submission__c s = new MUSW__Submission__c(MUSW__Permit2__c=p.Id, MUSW__Total_Approved_Reviews__c = 3, MUSW__Total_Failed_Reviews__c = 2);
           insert s;
           MUSW__Review__c r = new MUSW__Review__c(MUSW__Submission__c=s.Id, MUSW__Status__c = ' ',  MUSW__Due_Date__c=system.today());
           insert r;
        
    }
    
    @isTest(SeeAllData=true)  
    private static void testFinalPerm()
    {
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='zsdfsf');
        insert par;
        MUSW__Permit2__c p = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.Id,AVO_Volumetric_Limits__c= 10, name = 'Sequence Number');
        insert p;
        
        MUSW__Permit2__c[] subs = [select id from MUSW__Permit2__c where Permit2__c = :p.Id];
        if (subs.size() > 0)
        {
            for (MUSW__Permit2__c pp : subs)
            {
                pp.MUSW__Status__c = 'Finaled';
            }
            update subs;
        }
        
        p.MUSW__Status__c = 'Finaled';
        update p;
    }
    @isTest(SeeAllData=true)
    private static void testIsRulesEngineActive()
    {
        if (TriggerService.isRulesEngineActive())
            System.assert(TriggerService.isRulesEngineActive()==true);
        else
        {
            BGBK__GlobalSettings__c[] bkglobalsettings = [select BGBK__rulesEngineActive__c from BGBK__GlobalSettings__c where name = 'Default'];
            if (bkglobalsettings.size() != 1)
            {
                BGBK__GlobalSettings__c bkglob = new BGBK__GlobalSettings__c(BGBK__rulesEngineActive__c = true, name = 'Default');
                insert bkglob;
                System.assert(TriggerService.isRulesEngineActive()==true);
            }
            else if (bkglobalsettings.size() == 1)
            {
                System.assert(TriggerService.isRulesEngineActive()==false);
            }
        }
    }
    
    @isTest(SeeAllData = true)
    private static void testUpdateSubmissionTotals(){

        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='81238123');
        insert par;
        MUSW__Permit2__c p = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.Id,AVO_Volumetric_Limits__c= 10, name = 'Sequence Number');
        insert p;  
        MUSW__Submission__c s = new MUSW__Submission__c( MUSW__Total_Approved_Reviews__c = 3, MUSW__Total_Failed_Reviews__c = 2, MUSW__Total_Reviews__c = 5, MUSW__Permit2__c =p.id );
        insert s;
        MUSW__Review__c r = new MUSW__Review__c(MUSW__Submission__c=s.Id, MUSW__Due_Date__c=system.today());
        insert r; 
        List<id> subIds = new List<Id>();
        subIds.add(s.id);

        if(!TriggerService.isLocked()){
            TriggerService.setLock();
        } 
        TriggerService.UpdateSubmissionTotals(subIds);       
        TriggerService.releaseLock();
    }    

    @isTest(SeeAllData = true)
    private static void testCreateReinspectionFromIV(){
        
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='zsdfsf');
        insert par;
        TriggerService.setLock();    
        MUSW__Complaint2__c c = new MUSW__Complaint2__c();
        c.MUSW__Type__c = 'Other';
        c.MUSW__Status__c = 'New';
        c.MUSW__Parcel__c = par.id;
        insert c;

        MUSW__Violation__c v = new MUSW__Violation__c();
        v.MUSW__Status__c = 'Open';
        v.MUSW__Complaint2__c = c.id;
        insert v;
        
        MUSW__Inspection__c ins = new MUSW__Inspection__c();
                
        ins.Name = null;
        ins.MUSW__Type__c = 'Mechanical';
        ins.MUSW__Priority__c= '2 Normal';
        ins.MUSW__Status__c = 'Pending';
        ins.Close_Inspection__c = false;
        ins.MUSW__On_Itinerary__c = false;
        ins.Letter_Generated__c = false;
        ins.MUSW__Scheduled_Start_Date__c = null;
        ins.Requested_DateTime__c = null;
        ins.MUSW__Completed_Date__c = null;
        
        insert ins;

        MUSW__Inspection_Violation__c  iv = new MUSW__Inspection_Violation__c();
        iv.MUSW__Inspection__c = ins.id;
        iv.MUSW__Violation__c = v.id;
        
        TriggerService.createReinspectionFromIV(ins,v, iv);
    }     
}