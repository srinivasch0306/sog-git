@isTest
public class AvoMeterControllerTest {

    @isTest static void testSetMOSIDAssignsValues() {
        // Create meters without MOSID
        List<AVO_Meter__c> meters = new List<AVO_Meter__c>();
        for (Integer i = 0; i < 3; i++) {
            meters.add(new AVO_Meter__c(Name = 'Test Meter ' + i));
        }
        insert meters;

        // Call the method under test
        Test.startTest();
        List<Integer> mosidList = AvoMeterController.setMOSID(meters);
        Test.stopTest();

        // Query updated meters
        List<AVO_Meter__c> updatedMeters = [
            SELECT Id, AVO_Meter_On_Site_ID__c FROM AVO_Meter__c WHERE Id IN :meters
            ORDER BY AVO_Meter_On_Site_ID__c
        ];

        // Assert returned list size and values
        System.assertEquals(3, mosidList.size(), 'Returned MOSID list should have 3 items');
        
        // The MOSID should be assigned and incremented starting from existing max or 1
        Integer expectedMosid = mosidList[0] - 0; // first MOSID assigned

        for (Integer i = 0; i < updatedMeters.size(); i++) {
            System.assertEquals(expectedMosid + i, updatedMeters[i].AVO_Meter_On_Site_ID__c, 'Meter MOSID should be sequential');
            System.assertEquals(expectedMosid + i, mosidList[i], 'Returned MOSID should match assigned MOSID');
        }
    }

    @isTest static void testSetMOSIDWithExistingMaxMOSID() {
        // Create an existing meter with a MOSID of 10
        AVO_Meter__c existingMeter = new AVO_Meter__c(Name = 'Existing Meter', AVO_Meter_On_Site_ID__c = 10);
        insert existingMeter;

        // Create new meters without MOSID
        List<AVO_Meter__c> newMeters = new List<AVO_Meter__c>{
            new AVO_Meter__c(Name = 'New Meter 1'),
            new AVO_Meter__c(Name = 'New Meter 2')
        };
        insert newMeters;

        // Call the method under test
        Test.startTest();
        List<Integer> mosidList = AvoMeterController.setMOSID(newMeters);
        Test.stopTest();

        // Assert that MOSIDs start from 11 and increment
        System.assertEquals(2, mosidList.size());
        System.assertEquals(11, mosidList[0]);
        System.assertEquals(12, mosidList[1]);

        // Query updated meters and verify MOSID assigned
        List<AVO_Meter__c> updatedMeters = [SELECT AVO_Meter_On_Site_ID__c FROM AVO_Meter__c WHERE Id IN :newMeters ORDER BY AVO_Meter_On_Site_ID__c];
        System.assertEquals(11, updatedMeters[0].AVO_Meter_On_Site_ID__c);
        System.assertEquals(12, updatedMeters[1].AVO_Meter_On_Site_ID__c);
    }
}