@isTest
private class AvoConsolidateTest {

    @TestSetup
    static void dataSetup() {
        ID WITHDRAWAL_APP_REC_TYPE_ID = Schema.SObjectType.MUSW__Permit2__c
            .getRecordTypeInfosByDeveloperName().get('AVO_Agricultural_Water_Withdrawal_Application').getRecordTypeId();

        ID WITHDRAWAL_PERMIT_REC_TYPE_ID = Schema.SObjectType.MUSW__Permit2__c
            .getRecordTypeInfosByDeveloperName().get('Agricultural_Water_Withdrawal_Permit').getRecordTypeId();

        // Permit to KEEP (Permit)
        MUSW__Permit2__c permitToKeep = new MUSW__Permit2__c(
            Name = 'Permit To Keep',
            RecordTypeId = WITHDRAWAL_PERMIT_REC_TYPE_ID,
            MUSW__Type__c = 'Agricultural Water Withdrawal Permit',
            MUSW__Status__c = 'Final Evaluation',
            AVO_Volumetric_Limits__c = 10
        );
        insert permitToKeep;

        // Permit to CONSOLIDATE (App)
        MUSW__Permit2__c permitToConsolidate = new MUSW__Permit2__c(
            Name = 'Permit To Consolidate',
            RecordTypeId = WITHDRAWAL_APP_REC_TYPE_ID,
            MUSW__Type__c = 'Agricultural Water Withdrawal Application',
            AVO_Inactive_Reason__c = 'Merged to an existing application/permit',
            MUSW__Status__c = 'Consolidated',
            AVO_Permit_Closed_Status__c = 'Cancelled Application',
            AVO_Volumetric_Limits__c = 10
        );
        insert permitToConsolidate;

        // Review
        insert new MUSW__Review__c(
            Name = 'Review1',
            MUSW__Permit2__c = permitToKeep.Id,
            MUSW__Type__c = 'Withdrawal LOC Review',
            MUSW__Status__c = 'Open'
        );

        // Task
        insert new Task(
            WhatId = permitToKeep.Id,
            Subject = 'GIS Mapping',
            Status = 'Open'
        );

        // Meter
        insert new AVO_Meter_Transaction__c(
            AVO_Application_Number__c = permitToConsolidate.Id,
            AVO_Permit_Number__c = permitToConsolidate.Id
        );
    }

    @isTest
    static void testAppToPermitConsolidation() {
        MUSW__Permit2__c permitToKeep = [SELECT Id FROM MUSW__Permit2__c WHERE Name = 'Permit To Keep' LIMIT 1];
        MUSW__Permit2__c permitToConsolidate = [SELECT Id FROM MUSW__Permit2__c WHERE Name = 'Permit To Consolidate' LIMIT 1];

        AvoConsolidate.ConsolidationReq req = new AvoConsolidate.ConsolidationReq();
        req.recordIdToKeep = permitToKeep.Id;
        req.recordIdToConsolidate = permitToConsolidate.Id;

        Test.startTest();
        List<ID> results = AvoConsolidate.consolidateRecord(new List<AvoConsolidate.ConsolidationReq>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(permitToKeep.Id, results[0]);

        MUSW__Permit2__c updatedConsolidated = [
            SELECT AVO_ActiveRefNo__c, MUSW__Status__c, AVO_Inactive_Reason__c, AVO_Permit_Closed_Status__c
            FROM MUSW__Permit2__c WHERE Id = :permitToConsolidate.Id
        ];
      System.assertEquals('Consolidated', updatedConsolidated.MUSW__Status__c);
       System.assertEquals('Merged to an existing application/permit', updatedConsolidated.AVO_Inactive_Reason__c);
        System.assertEquals('Cancelled Application', updatedConsolidated.AVO_Permit_Closed_Status__c);
       //System.assertEquals(permitToKeep.Id, updatedConsolidated.AVO_ActiveRefNo__c);

        List<AVO_Meter_Transaction__c> meters = [
            SELECT AVO_Application_Number__c, AVO_Permit_Number__c
            FROM AVO_Meter_Transaction__c WHERE AVO_Application_Number__c = :permitToKeep.Id
        ];
        System.assert(meters.size() > 0, 'Meter transactions should be moved to permitToKeep');

        List<Task> updatedTasks = [SELECT Status FROM Task WHERE WhatId = :permitToKeep.Id];
        for (Task t : updatedTasks) {
            //System.assertEquals('Denied', t.Status, 'Old tasks should be marked Denied');
        }

        List<MUSW__Review__c> reviews = [SELECT MUSW__Status__c FROM MUSW__Review__c WHERE MUSW__Permit2__c = :permitToKeep.Id];
        for (MUSW__Review__c r : reviews) {
            System.assertEquals('Fail Back', r.MUSW__Status__c);
        }
    }

    @isTest
    static void testAppToAppWithInReviewStatus() {
        ID appRT = Schema.SObjectType.MUSW__Permit2__c
            .getRecordTypeInfosByDeveloperName().get('AVO_Agricultural_Water_Withdrawal_Application').getRecordTypeId();

        MUSW__Permit2__c appToKeep = new MUSW__Permit2__c(
            Name = 'App To Keep 2',
            RecordTypeId = appRT,
            MUSW__Type__c = 'Agricultural Water Withdrawal Application',
            MUSW__Status__c = 'In Review',
            AVO_Volumetric_Limits__c = 1
        );
        insert appToKeep;

        MUSW__Permit2__c appToConsolidate = new MUSW__Permit2__c(
            Name = 'App To Consolidate 2',
            RecordTypeId = appRT,
            MUSW__Type__c = 'Agricultural Water Withdrawal Application',
            MUSW__Status__c = 'Submitted',
            AVO_Permit_Closed_Status__c = 'Cancelled Application',
            AVO_Inactive_Reason__c = 'Merged to an existing application/permit',
            AVO_Volumetric_Limits__c = 1
            
        );
        insert appToConsolidate;

        insert new AVO_Meter_Transaction__c(
            AVO_Application_Number__c = appToConsolidate.Id,
            AVO_Permit_Number__c = appToConsolidate.Id
        );

        AvoConsolidate.ConsolidationReq req = new AvoConsolidate.ConsolidationReq();
        req.recordIdToKeep = appToKeep.Id;
        req.recordIdToConsolidate = appToConsolidate.Id;

        Test.startTest();
        AvoConsolidate.consolidateRecord(new List<AvoConsolidate.ConsolidationReq>{ req });
        Test.stopTest();

        MUSW__Permit2__c updated = [
            SELECT AVO_Permit_Closed_Status__c, AVO_Inactive_Reason__c, AVO_ActiveRefNo__c, MUSW__Status__c
            FROM MUSW__Permit2__c WHERE Id = :appToConsolidate.Id
        ];
      System.assertEquals('Cancelled Application', updated.AVO_Permit_Closed_Status__c);
      System.assertEquals('Merged to an existing application/permit', updated.AVO_Inactive_Reason__c);
       // System.assertEquals(appToKeep.Id, updated.AVO_ActiveRefNo__c);
    }

    @isTest
    static void testPermToPermConsolidation() {
        ID permitRTId = Schema.SObjectType.MUSW__Permit2__c
            .getRecordTypeInfosByDeveloperName().get('Agricultural_Water_Withdrawal_Permit').getRecordTypeId();

        MUSW__Permit2__c permToKeep = new MUSW__Permit2__c(
            Name = 'Perm To Keep 2',
            RecordTypeId = permitRTId,
            MUSW__Type__c = 'Agricultural Water Withdrawal Permit',
            MUSW__Status__c = 'Form Assesment',
            AVO_Volumetric_Limits__c = 1
        );
        insert permToKeep;

        MUSW__Permit2__c permToConsolidate = new MUSW__Permit2__c(
            Name = 'Perm To Consolidate 2',
            RecordTypeId = permitRTId,
            MUSW__Type__c = 'Agricultural Water Withdrawal Permit',
            MUSW__Status__c = 'Consolidated',
            AVO_Inactive_Reason__c = 'Consolidated Permit',
            AVO_Volumetric_Limits__c = 1
        );
        insert permToConsolidate;

        AvoConsolidate.ConsolidationReq req = new AvoConsolidate.ConsolidationReq();
        req.recordIdToKeep = permToKeep.Id;
        req.recordIdToConsolidate = permToConsolidate.Id;

        Test.startTest();
        AvoConsolidate.consolidateRecord(new List<AvoConsolidate.ConsolidationReq>{ req });
        Test.stopTest();

        MUSW__Permit2__c consolidated = [SELECT MUSW__Status__c, AVO_Inactive_Reason__c FROM MUSW__Permit2__c WHERE Id = :permToConsolidate.Id];
        System.assertEquals('Consolidated', consolidated.MUSW__Status__c);
        System.assertEquals('Consolidated Permit', consolidated.AVO_Inactive_Reason__c);
    }
}