@isTest
public class AvoReviewDataRetrieverControllerTest {
        @TestSetup
    static void dataSetup() {
         Account acc = new Account(
            Name = 'Michael L',
            BillingStreet = '123 Michael Street',
            BillingCity = 'Surrey',
            BillingState = 'BC',
            BillingPostalCode = '12345',
            BillingCountry = 'Canada'
        );
        insert acc;
        Contact contact = new Contact(
            LastName = 'Inc.',
            AccountId = acc.Id
        );
        insert contact;

 
        
        MUSW__Permit2__c entity = new MUSW__Permit2__c(
            MUSW__Type__c = 'Agricultural Water Withdrawal Application',
            MUSW__Status__c = 'Pending',
           // MUSW__Account__c = contact.AccountId,
           // MUSW__Applicant__c = contact.id,
            AVO_Planned_Date_of_Well_Install__c =system.today().addDays(-1),
            AVO_Planned_Date_of_Pump_Installation__c = system.today().addDays(-1),
            AVO_Property_Owner__c =contact.id,
            AVO_Operator_Manager__c = contact.id,
            AVO_PurIR__c = 'No',
            AVO_ZeroAcreage__c = 'No',
            AVO_Volumetric_Limits__c = 1
        );
        insert entity;
        Id devRecordTypeId = Schema.SObjectType.MUSW__Review__c.getRecordTypeInfosByName().get('AVO Review Default').getRecordTypeId();
        Master_Review_List__c MsType = new Master_Review_List__c();
                  MsType.Name ='test1'; 
        MsType.Record_Type_ID__c =devRecordTypeId;
        MsType.Avo_Permit_Type__c ='Agricultural Water Withdrawal Application';
       // MsType.Avo_Offset__c =2;
         MsType.Effective_Start_Date__c = system.today().addDays(-1); 
        MsType.Effective_End_Date__c = system.today().addDays(+5);
        MsType.Manual_Creation_Allowed__c = true;
        MsType.Avo_Offset_Type__c  = '3';
        MsType.Avo_Offset_Type__c = 'Business Days';
        insert MsType;
          Id recordTypeId = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Condition'
            AND SobjectType = 'MUSW__Violation_Type__c'
            LIMIT 1
        ].Id;
        MUSW__Violation_Type__c ordinance = new MUSW__Violation_Type__c(RecordTypeId = recordTypeId);
        insert ordinance;
        MUSW__Condition__c con=new MUSW__Condition__c(
            MUSW__Type__c='Supplementary Conditions',
            MUSW__Status__c='Final',
            MUSW__Permit2__c = entity.Id,
            MUSW__Ordinance__c = ordinance.Id
        );
        insert con;
     /*   MUSW__Condition__c con=new MUSW__Condition__c(
            MUSW__Type__c='Supplementary Conditions',
            MUSW__Status__c='Final',
            MUSW__Permit2__c = entity.Id,
            MUSW__Ordinance__c ='a0L3K000001CzMiUAK'
        );
        insert con;*/
    }
@isTest
    private static void testgetAllowedReviewTypes_Permit(){
        Id recordId = [Select id from MUSW__Permit2__c limit 1].Id;
        Test.startTest();
       string Result = AvoReviewDataRetrieverController.getAllowedReviewTypes(recordId,'MUSW__Permit2__c');
        Test.stopTest();
        System.assertNotEquals(null, Result);
    }  
     @isTest
    private static void testgetReviewRecordTypeId(){
        String record = 'License_Review';
        Test.startTest();
        Id permitResult = AvoReviewDataRetrieverController.getReviewRecordTypeId(record);
        Test.stopTest();
        System.assertNotEquals(null,permitResult);
    }
   /*  @isTest
    Private static void testgetMasterListInfo(){
        string recordId = [select id,name from MUSW__Master_Submission_List__c  limit 1 ].id;
        AvoReviewDataRetrieverController.getMasterListInfo(recordId);
    }*/
    @isTest
    private static void testgetMasterListInfo(){
        List<String> ids = new List<String>{[select id from Master_Review_List__c  limit 1 ].id};
        Test.startTest();
        List<Master_Review_List__c> result = AvoReviewDataRetrieverController.getMasterListInfo(ids);
        Test.stopTest();
        System.assertNotEquals(null,result);
    }
   @isTest
    private static void testcreateReviews(){
        AvoReviewDataRetrieverController.ResponseJSONWrapper wrapper= new AvoReviewDataRetrieverController.ResponseJSONWrapper();
        List<String> ids = new List<String>();
        List<MUSW__Permit2__c> recordid = [Select id from MUSW__Permit2__c limit 1];
        List<Master_Review_List__c> listids = [SELECT Name,Record_Type_ID__c,Record_Type__c, Owner_Queue_User__c, Avo_Offset__c, Avo_Offset_Type__c
            FROM Master_Review_List__c limit 2];
        for(Master_Review_List__c a :listids){
            ids.add(a.Id);
        }
        String Objectname ='MUSW__Permit2__c';
        Test.startTest();
        Id result = AvoReviewDataRetrieverController.createReviews(recordid[0].Id,ids,Objectname);
        Test.stopTest();
        System.assertNotEquals(null,result);
    }

 
    
}