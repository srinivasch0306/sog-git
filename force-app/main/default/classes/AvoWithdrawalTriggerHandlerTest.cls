@isTest
public class AvoWithdrawalTriggerHandlerTest {
    
    @isTest
static void testBeforeUpdate_addErrorOnLowFlow() {
    // Create a Permit record
    MUSW__Permit2__c permit = new MUSW__Permit2__c(
        Name = 'Test Permit',
        MUSW__Status__c = 'Pending',
        MUSW__Type__c = 'Agricultural Water Withdrawal Application',
        AVO_Permitted_Acres__c = 1
    );
    insert permit;

    // Create a Submission with name "Low Flow Guidance" and a non-null Submission Date
    MUSW__Submission__c submission = new MUSW__Submission__c(
        Name = 'Low Flow Guidance',
        MUSW__Permit2__c = permit.Id,
        MUSW__Submission_DateTime__c = System.now()
    );
    insert submission;

    // Insert a Withdrawal that bypasses validation on insert
    AVO_Withdrawals__c withdrawal = new AVO_Withdrawals__c(
        Name = 'Test Withdrawal',
        AVO_Type__c = 'Surface Water Withdrawal Application', // required type
        AVO_Permit__c = permit.Id,
        AVO_GIS_UNIQUE__c = 'UNIQUE-123',
        AVO_Low_Flow_cfs__c = 0,  // avoid validation error on insert
        AVO_Low_Flow_gpm__c = 0
    );
    insert withdrawal;

    // Now update it to trigger your Apex logic
    Test.startTest();
    try {
        withdrawal.AVO_Low_Flow_cfs__c = 10;
        withdrawal.AVO_Low_Flow_gpm__c = 100;
        update withdrawal;
        System.assert(false, 'Expected error due to missing LF Plan flag');
    } catch (DmlException e) {
        System.assert(
            e.getMessage().contains('LF cfs and/or LF gpm >0 and LF Plan not marked as on file.'),
            'Expected error was not thrown'
        );
    }
    Test.stopTest();
}


    @isTest
    static void testBeforeUpdate_noErrorWhenLowFlowZero() {
        MUSW__Permit2__c permit = new MUSW__Permit2__c(
            Name = 'Permit No Error',
            MUSW__Status__c = 'Draft',
            MUSW__Type__c = 'Agricultural Water Withdrawal Application',
            AVO_Permitted_Acres__c = 1
        );
        insert permit;

        AVO_Withdrawals__c withdrawal = new AVO_Withdrawals__c(
            Name = 'No Error Withdrawal',
            AVO_Type__c = 'Ground Water Withdrawal Application',
            AVO_Permit__c = permit.Id,
            AVO_GIS_UNIQUE__c = 'UNIQUE-456',
            AVO_Low_Flow_cfs__c = 0,
            AVO_Low_Flow_gpm__c = 0
        );
        insert withdrawal;

        Test.startTest();
        withdrawal.Name = 'Still No Error';
        update withdrawal; // Should not throw error
        Test.stopTest();

        System.assertEquals('Still No Error', [SELECT Name FROM AVO_Withdrawals__c WHERE Id = :withdrawal.Id].Name);
    }
}