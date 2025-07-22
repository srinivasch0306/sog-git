@isTest
public class AvoProcessTriggerHandlerTest {

    // Invalid case: Neither field is filled
    @isTest
    static void testInsert_InvalidNeitherTypeFilled() {
        AVO_Process__c process = new AVO_Process__c(
            Name = 'Test'
        );

        Test.startTest();
        try {
            insert process;
            System.assert(false, 'Expected validation error was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Select either Permit Types or Planning Application Typesd'));
        }
        Test.stopTest();
    }

    // Covers the beforeUpdate method in the trigger handler
    @isTest
    static void testBeforeUpdate_CoversHandler() {
        AVO_Process__c process = new AVO_Process__c(
            Name = 'Coverage Test',
            AVO_Permit_Type__c = 'Agricultural Water Withdrawal Permit'
        );
        insert process;

        // Trigger update to cover beforeUpdate()
        process.Name = 'Updated Name';
        update process;
    }
}