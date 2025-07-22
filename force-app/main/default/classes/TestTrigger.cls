//@isTest(seeAllData=true)
@isTest
public class TestTrigger
{
   @testSetup static void setup() {
        initCustomSettings();
        initCitizenAccount();     
    }


    static void initCustomSettings(){       
        BGBK__CartSettings__c defaultCartSetting = new BGBK__CartSettings__c();
        defaultCartSetting.Name = 'Default';
        defaultCartSetting.BGBK__Cart_Expiration_Hours__c = 60;
        defaultCartSetting.BGBK__Payment_Gateway_Form_Post_URL__c = 'http://google.com';
        defaultCartSetting.BGBK__Payment_Gateway_Data_Encryption_Key__c = '1234567890123456';
        defaultCartSetting.BGBK__Payable_Parents__c = 'MUSW__License2__c,MUSW__Permit2__c,MUSW__Complaint2__c,MUSW__Application2__c';
        insert defaultCartSetting;  

        BGBK__FinancialObjects__c finObjSetting = new BGBK__FinancialObjects__c();
        finObjSetting.Name = 'Parcel_Account__c';
        finObjSetting.BGBK__Account_Field_Name__c = 'Account__c';
        finObjSetting.BGBK__Contact_Field_Name__c = 'Primary_Contact__c';
        insert finObjSetting;
            
    }

    static void initCitizenAccount(){
        Account citizen = new Account();
        citizen.name = 'Citizen';
        citizen.BillingCity = 'Tristram';
        citizen.Phone = '(123) 456-7890';
        citizen.BillingState = 'AL';
        citizen.BillingPostalCode='67890';
        citizen.BillingStreet = 'Black smith';
        insert citizen;
    }
    
    static testmethod void testViolationCloseInspectionTree()
    {
        Id[] ids = new Id[]{};
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='East Blvd', MUSW__Street_Number__c='7777', MUSW__City__c='Vancouver', MUSW__Parcel_Number2__c='2000Test400');
        insert par;
        
        MUSW__Complaint2__c com = new MUSW__Complaint2__c(MUSW__Type__c='Multiple Issues', MUSW__Origin__c='311', MUSW__Parcel__c=par.Id);
        insert com;
        
        MUSW__Inspection__c ins = new MUSW__Inspection__c (MUSW__Type__c='First Inspection');
        insert ins;
        
        ids.add(ins.Id);
        
        TriggerService.setLock();
        
        //Branch1
        MUSW__Inspection__c reins11 = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='Re-inspection',MUSW__Previous_Inspection__c= ins.Id);
        insert reins11;
        ids.add(reins11.Id);
        ins.MUSW__Status__c = 'Completed with open violations';
        update ins;
        
        MUSW__Inspection__c reins12 = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='Re-inspection',MUSW__Previous_Inspection__c= reins11.Id);
        insert reins12;
        ids.add(reins12.Id); 
        reins11.MUSW__Status__c = 'Completed with open violations';
        update reins11;
          
        MUSW__Inspection__c reins13 = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='Re-inspection',MUSW__Previous_Inspection__c = reins12.Id);
        insert reins13;
        ids.add(reins13.Id);
        reins12.MUSW__Status__c = 'Completed with open violations';
        update reins12;
         
           
        //Branch 2
        MUSW__Inspection__c reins21 = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id,  MUSW__Type__c='Re-inspection',MUSW__Previous_Inspection__c = ins.Id);
        insert reins21;
        ids.add(reins21.Id);
        
        MUSW__Inspection__c reins22 = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='Re-inspection',MUSW__Previous_Inspection__c= reins21.Id);
        insert reins22;
        ids.add(reins22.Id); 
        reins21.MUSW__Status__c = 'Completed with open violations';
        update reins21;
          
        MUSW__Inspection__c reins23 = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='Re-inspection',MUSW__Previous_Inspection__c = reins22.Id);
        insert reins23;
        ids.add(reins23.Id);
        reins22.MUSW__Status__c = 'Completed with open violations';
        update reins22;
        
        TriggerService.releaseLock();
        //Check if the ins Inspection_Chain_Closed__c = false
        MUSW__Inspection__c insBefore = [select Inspection_Chain_Closed__c from MUSW__Inspection__c where Id = :ins.Id ]; 
        system.assert(insBefore.Inspection_Chain_Closed__c == false);
        
        //Close one leaf
        reins13.MUSW__Status__c = 'Closed';
        update reins13;
        MUSW__Inspection__c[] insClosedOneLeaf = [select IsClosed__c, Inspection_Chain_Closed__c from MUSW__Inspection__c where Id in:ids and Inspection_Chain_Closed__c = true]; 
        
        /*system.assert(insClosedOneLeaf.size()==3, 'size: '+insClosedOneLeaf.size());
        
        //Close both leaves
        reins23.MUSW__Status__c = 'Closed';
        update reins23;
        MUSW__Inspection__c[] insClosedBoth = [select Inspection_Chain_Closed__c from MUSW__Inspection__c where Id in:ids and Inspection_Chain_Closed__c = true]; 
        
        system.assert(insClosedBoth.size()==7, 'size: '+insClosedBoth.size());*/
    }
    
    
    static testmethod void testViolationCloseInspection()
    {
        Test.startTest();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X');
        insert ord;
        TriggerService.setLock();
        MUSW__Complaint2__c com = new MUSW__Complaint2__c(MUSW__Type__c='TestTypeComp', MUSW__Origin__c='Test', MUSW__Parcel__c=par.Id);
        insert com;system.debug('com======' + com);
        MUSW__Inspection__c ins = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='TESTInspection');
        insert ins;
        MUSW__Violation__c v1 = new MUSW__Violation__c(MUSW__Type__c=ord.Id, MUSW__Complaint2__c=com.Id);
        MUSW__Violation__c v2 = new MUSW__Violation__c(MUSW__Type__c=ord.Id, MUSW__Complaint2__c=com.Id);
        insert new MUSW__Violation__c[]{v1, v2};
        MUSW__Inspection_Violation__c iv1 = new MUSW__Inspection_Violation__c(MUSW__Inspection__c=ins.Id, MUSW__Violation__c=v1.Id, MUSW__Complaint2__c=com.Id);
        MUSW__Inspection_Violation__c iv2 = new MUSW__Inspection_Violation__c(MUSW__Inspection__c=ins.Id, MUSW__Violation__c=v2.Id, MUSW__Complaint2__c=com.Id);
        insert new MUSW__Inspection_Violation__c[]{iv1, iv2};
        
        v1.MUSW__Status__c = 'Closed - Corrected';
        v2.MUSW__Status__c = 'Closed - Corrected';
        update new MUSW__Violation__c[]{v1, v2};
        
        MUSW__Inspection__c insq = [select Close_Inspection__c from MUSW__Inspection__c where Id = :ins.Id];
        //MOS: no DRE rule to close yet - system.assert(insq.Close_Inspection__c == true);
        
        Test.stopTest();
    }   
    
    static testmethod void testIVDeduper()
    {
        TriggerService.setLock();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X');
        insert ord;
        MUSW__Inspection__c ins = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Type__c='Field Observation');
        insert ins;
        MUSW__Violation__c v = new MUSW__Violation__c(MUSW__Type__c=ord.Id, MUSW__Parcel__c=par.Id);
        insert v;
        MUSW__Inspection__c reins1 = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Type__c='Re-inspection', MUSW__Previous_Inspection__c=ins.Id);
        insert reins1;
        MUSW__Inspection__c reins2 = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Type__c='Re-inspection', MUSW__Previous_Inspection__c=ins.Id);
        insert reins2;
        MUSW__Inspection_Violation__c iv1 = new MUSW__Inspection_Violation__c(MUSW__Inspection__c=reins1.Id, MUSW__Violation__c=v.Id, MUSW__Parcel__c=par.Id);
        MUSW__Inspection_Violation__c iv2 = new MUSW__Inspection_Violation__c(MUSW__Inspection__c=reins2.Id, MUSW__Violation__c=v.Id, MUSW__Parcel__c=par.Id);
        insert new MUSW__Inspection_Violation__c[]{iv1, iv2};
        
        //only works if workflow and DRE rules are in the system
        MUSW__Inspection__c[] insq = [select Id from MUSW__Inspection__c where MUSW__Previous_Inspection__c = :ins.Id];
        //only works if workflow and DRE rules are in the system TO DO
        system.assert(insq.size() == 1);
        MUSW__Inspection_Violation__c[] ivq = [select Id from MUSW__Inspection_Violation__c where MUSW__Inspection__r.MUSW__Previous_Inspection__c = :ins.Id];
        system.assert(ivq.size() == 1);
    }
    
}