@isTest
public class AvoInspectionDataRetrieverControllerTest {

    @TestSetup
    static void dataSetup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact contact = new Contact(
            LastName = 'Tester',
            AccountId = acc.Id
        );
        insert contact;

        MUSW__Permit2__c permit = new MUSW__Permit2__c(
            MUSW__Type__c = 'Agricultural Water Withdrawal Permit',
            MUSW__Status__c = 'Submitted',
            MUSW__Account__c = acc.Id,
            MUSW__Applicant__c = contact.Id,
            AVO_PurIR__c = 'No',
            AVO_ZeroAcreage__c = 'No',
            AVO_Volumetric_Limits__c = 1
        );
        insert permit;

        Master_Review_List__c review = new Master_Review_List__c(Name = 'Test Review');
        insert review;

        MUSW__Condition__c condition = new MUSW__Condition__c(
            MUSW__Type__c = 'Supplementary Conditions',
            MUSW__Status__c = 'Final',
            MUSW__Permit2__c = permit.Id
        );
        insert condition;

        Id inspRecordTypeId = Schema.SObjectType.MUSW__Master_Inspection_List__c
            .getRecordTypeInfosByName()
            .get('Inspection Template')
            .getRecordTypeId();

        MUSW__Master_Inspection_List__c insp1 = new MUSW__Master_Inspection_List__c(
            Name = 'Site Visit Request',
            RecordTypeId = inspRecordTypeId,
            Record_Type__c = 'Site Visit Request', // matches record type name on MUSW__Inspection__c
            Avo_Permit_Type__c = 'Agricultural Water Withdrawal Permit',
            Effective_Start_Date__c = Date.today().addDays(-1),
            Effective_End_Date__c = Date.today().addDays(5),
            Avo_Manual_Creation_Allowed__c = true
        );
        insert insp1;

        MUSW__Master_Inspection_List__c insp2 = new MUSW__Master_Inspection_List__c(
            Name = 'Second Inspection',
            RecordTypeId = inspRecordTypeId,
            Record_Type__c = 'Site Visit Request',
            Avo_Permit_Type__c = 'Agricultural Water Withdrawal Permit',
            Effective_Start_Date__c = Date.today().addDays(-1),
            Effective_End_Date__c = Date.today().addDays(5),
            Avo_Manual_Creation_Allowed__c = true
        );
        insert insp2;

        // Add optional metadata if needed (mocked via Custom Metadata Loader or Tooling API in real test setup)
    }

    @isTest
    static void testGetAllowedInspectionTypes() {
        Id permitId = [SELECT Id FROM MUSW__Permit2__c LIMIT 1].Id;

        Test.startTest();
        String result = AvoInspectionDataRetrieverController.getAllowedInspectionTypes(permitId, 'MUSW__Permit2__c');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.contains('Site Visit Request'));
    }

    @isTest
    static void testGetInspectionName() {
        String inspId = [SELECT Id FROM MUSW__Master_Inspection_List__c LIMIT 1].Id;

        Test.startTest();
        String name = AvoInspectionDataRetrieverController.getInspectionName(inspId);
        Test.stopTest();

        System.assertEquals('Site Visit Request', name);
    }

    @isTest
    static void testGetInspectionInformation() {
        List<String> ids = new List<String>{
            [SELECT Id FROM MUSW__Master_Inspection_List__c LIMIT 1].Id
        };

        Test.startTest();
        List<MUSW__Master_Inspection_List__c> result = AvoInspectionDataRetrieverController.getInspectionInformation(ids);
        Test.stopTest();

        System.assertEquals(1, result.size());
    }

    @isTest
    static void testCreateInspections() {
        Id permitId = [SELECT Id FROM MUSW__Permit2__c LIMIT 1].Id;
        List<MUSW__Master_Inspection_List__c> inspections = [SELECT Id FROM MUSW__Master_Inspection_List__c];
        List<String> inspIds = new List<String>();
        for (MUSW__Master_Inspection_List__c insp : inspections) {
            inspIds.add(insp.Id);
        }

        Test.startTest();
        Id createdId = AvoInspectionDataRetrieverController.createInspections(permitId, inspIds, 'MUSW__Permit2__c');
        Test.stopTest();

        System.assertNotEquals(null, createdId);
    }

    @isTest
    static void testGetInspectionRecordTypeId() {
        MUSW__Master_Inspection_List__c insp = [SELECT Id FROM MUSW__Master_Inspection_List__c WHERE Record_Type__c = 'Site Visit Request' LIMIT 1];

        Test.startTest();
        Id rtId = AvoInspectionDataRetrieverController.getInspectionRecordTypeId(insp.Id);
        Test.stopTest();

        System.assertNotEquals(null, rtId, 'Record type ID should not be null');
    }

    @isTest
    static void testGetInspectionRecordTypeIds() {
        List<MUSW__Master_Inspection_List__c> inspections = [SELECT Id FROM MUSW__Master_Inspection_List__c LIMIT 2];
        List<String> inspIds = new List<String>();
        for (MUSW__Master_Inspection_List__c insp : inspections) {
            inspIds.add(insp.Id);
        }

        Test.startTest();
        Map<Id, Id> mapResult = AvoInspectionDataRetrieverController.getInspectionRecordTypeIds(inspIds);
        Test.stopTest();

        System.assertEquals(inspections.size(), mapResult.size(), 'Map should return record types for each ID');
    }
}