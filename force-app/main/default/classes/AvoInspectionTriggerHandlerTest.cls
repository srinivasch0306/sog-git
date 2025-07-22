@isTest
public class AvoInspectionTriggerHandlerTest {

    @isTest
    static void testAfterUpdateInspectionStatusChanged() {
        // Step 1: Insert an inspection with initial status
        MUSW__Inspection__c testInspection = new MUSW__Inspection__c(
            Name = 'Test Inspection',
            MUSW__Status__c = 'Scheduled' // Initial status
            // Add any other required fields
        );
        insert testInspection;

        // Step 2: Change status to simulate update
        testInspection.MUSW__Status__c = 'Completed'; // New status

        Test.startTest();
        update testInspection;
        Test.stopTest();

        // No assertion unless AvoProcessEngineInspection.run() changes something you can check
        // You can add assertions here if there's a DML result or audit trail to verify
    }
}