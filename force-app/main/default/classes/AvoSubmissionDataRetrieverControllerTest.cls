@isTest
public class AvoSubmissionDataRetrieverControllerTest {
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
        
            AVO_Compliance__c compliance = new AVO_Compliance__c(
            Name = 'Test Compliance',
            AVO_CompStatus__c = 'Resolved',
            AVO_ResolvedDt__c = System.today(),                  // Required field
            AVO_ResTypeCode__c = 'Corrective Action Taken'       // Required field
        );
        insert compliance;
        
        Id devRecordTypeId = Schema.SObjectType.MUSW__Master_Submission_List__c.getRecordTypeInfosByName().get('Application Submission').getRecordTypeId();
        
        MUSW__Master_Submission_List__c mstrSub = new MUSW__Master_Submission_List__c();
        mstrSub.Name ='testMaster';
        mstrSub.RecordTypeId =devRecordTypeId;
       // mstrSub.Permit_Type__c ='Groundwater';
        mstrSub.avo_Offset__c =2;
        mstrSub.Effective_Start_Date__c = system.today().addDays(-1); 
        mstrSub.Effective_End_Date__c = system.today().addDays(+5);
        mstrSub.Manual_Creation_Allowed__c = true;
        insert mstrSub;
        
    }
    @isTest
    private static void testgetAllowedSubmissionTypes(){
        Id recordId = [Select id from MUSW__Permit2__c limit 1].Id;
        Test.startTest();
        string Result = AvoSubmissionDataRetrieverController.getAllowedSubmissionTypes(recordId,'MUSW__Permit2__c');
        Test.stopTest();
        System.assertNotEquals(null, Result);
    }  
    
    @isTest
    private static void testgetSubmissionRecordTypeId(){
        string mstr = [select id,name from MUSW__Master_Submission_List__c where name='testMaster' limit 1].id; 
        //Id devRecordTypeId = Schema.SObjectType.MUSW__Master_Submission_List__c.getRecordTypeInfosByName().get('eb Submission Default').getRecordTypeId();
        //string recordType=string.valueOf(devRecordTypeId);
        Test.startTest();
        Id resultId = AvoSubmissionDataRetrieverController.getSubmissionRecordTypeId(mstr);
        Test.stopTest();
        System.assertNotEquals(null, resultId);
        
    }
    
    
    @isTest
    Private static void testgetSubmissionInformation(){
        string recordId = [select id,name from MUSW__Master_Submission_List__c  limit 1 ].id;
        AvoSubmissionDataRetrieverController.getSubmissionInformation(recordId);
    }
    
    @isTest
    private static void testCalculateDueDate(){
        MUSW__Master_Submission_List__c record =[
            SELECT Name, avo_Offset__c, avo_Offset_Type__c,Required__c
            FROM MUSW__Master_Submission_List__c LIMIT 1];
        Test.startTest();
        date resultdate = AvoSubmissionDataRetrieverController.CalculateDueDate(record);
        Test.stopTest();
        System.assertNotEquals(null, resultdate);
    }
    @isTest
    private static void testcreateSubmissions(){
        List<String> ids = new List<String>();
        List<MUSW__Permit2__c> recordid = [Select id from MUSW__Permit2__c limit 1];
        List<MUSW__Master_Submission_List__c> listids = [SELECT Id,Name,RecordTypeId,avo_Offset_Type__c
                                                         FROM MUSW__Master_Submission_List__c limit 2];
        for(MUSW__Master_Submission_List__c a :listids){
            ids.add(a.Id);
        }
        String Objectname ='MUSW__Permit2__c';
        Test.startTest();
        Id result = AvoSubmissionDataRetrieverController.createSubmissions(recordid[0].Id,ids,Objectname);
        Test.stopTest();
        System.assertNotEquals(null,result);
    }
        @isTest
    private static void testcreateSubmissionsCompliance(){
        List<String> ids = new List<String>();
        List<AVO_Compliance__c> recordid = [Select id from AVO_Compliance__c limit 1];
        List<MUSW__Master_Submission_List__c> listids = [SELECT Id,Name,RecordTypeId,avo_Offset_Type__c
                                                         FROM MUSW__Master_Submission_List__c limit 2];
        for(MUSW__Master_Submission_List__c a :listids){
            ids.add(a.Id);
        }
        String Objectname ='AVO_Compliance__c';
        Test.startTest();
        Id result = AvoSubmissionDataRetrieverController.createSubmissions(recordid[0].Id,ids,Objectname);
        Test.stopTest();
        System.assertNotEquals(null,result);
    }
    @istest
    public static void testcreateSubmissionsWithConfig(){
        string objname='MUSW__Permit2__c';
        //string recordId =[select id,name,MUSW__Status__c from MUSW__Permit2__c where MUSW__Status__c='Submitted' Limit 1 ].id;
        string recordId =[select id,name,MUSW__Status__c from MUSW__Permit2__c Limit 1 ].id;
        string masterRecId = [select id,name from MUSW__Master_Submission_List__c  limit 1 ].id;
        map<string,boolean> testMap=new map<string,boolean>();
        testMap.put(masterRecId, true);
        AvoSubmissionDataRetrieverController.createSubmissionsWithConfig(recordId, testMap, objname);
    }
    
    @istest
    public static void testcreateSubmissionsWithConfigCompliance(){
        string objname='AVO_Compliance__c';
        string recordId =[select id,name from AVO_Compliance__c Limit 1 ].id;
        string masterRecId = [select id,name from MUSW__Master_Submission_List__c  limit 1 ].id;
        map<string,boolean> testMap=new map<string,boolean>();
        testMap.put(masterRecId, true);
        AvoSubmissionDataRetrieverController.createSubmissionsWithConfig(recordId, testMap, objname);
    }

}