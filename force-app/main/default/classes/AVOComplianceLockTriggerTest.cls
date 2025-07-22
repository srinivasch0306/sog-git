@isTest
public class AVOComplianceLockTriggerTest {

    // Helper method to create a compliant test record
    private static AVO_Compliance__c createCompliance(Boolean locked, Id countyId) {
        return new AVO_Compliance__c(
            AVO_Locked__c = locked,
            AVO_Compliance_Plan_Submitted__c = 'Yes',
            AVO_Basin__c = 'FLINT',
            AVO_FRBP__c = '1',
            AVO_StrBuffer__c = '1',
            AVO_Suspension__c = '1',
            AVO_Coastal24__c = '1',
            AVO_SubArea4__c = '1',
            AVO_County__c = countyId,
            AVO_Geolocation__Latitude__s = 32,
            AVO_Geolocation__Longitude__s = -82, 
            AVO_ReviewReason__c = 'Test'
        );
    }

    @isTest
    static void testLockedNonOwner_FieldChanged_ShouldFail() {
        // Create county
        AVO_County__c county = new AVO_County__c(
            Name = 'Test County',
            AVO_County__c = 100,
            AVO_FIPS__c = 200,
            AVO_24_Coastal__c = 'No'
        );
        insert county;

        // Insert unlocked compliance record
        AVO_Compliance__c compliance = createCompliance(false, county.Id);
        insert compliance;

        // Lock it
        compliance.AVO_Locked__c = true;
        compliance.AVO_ReviewReason__c = 'Locking';
        update compliance;

        compliance = [SELECT Id, OwnerId FROM AVO_Compliance__c WHERE Id = :compliance.Id];
        User nonOwner = [SELECT Id FROM User WHERE IsActive = true AND Id != :compliance.OwnerId LIMIT 1];

        System.runAs(nonOwner) {
            AVO_Compliance__c updateAttempt = [SELECT Id, AVO_ReviewReason__c FROM AVO_Compliance__c WHERE Id = :compliance.Id];
            updateAttempt.AVO_ReviewReason__c = 'Changed by non-owner';
            Test.startTest();
            try {
                update updateAttempt;
                System.assert(false, 'Expected error not thrown.');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('You cannot modify this record'), 'Error message mismatch.');
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testLockedNonOwner_NoFieldChange_ShouldPass() {
        AVO_County__c county = new AVO_County__c(
            Name = 'County 2',
            AVO_County__c = 101,
            AVO_FIPS__c = 201,
            AVO_24_Coastal__c = 'No'
        );
        insert county;

        AVO_Compliance__c compliance = createCompliance(true, county.Id);
        insert compliance;

        compliance = [SELECT Id, AVO_Locked__c, OwnerId FROM AVO_Compliance__c WHERE Id = :compliance.Id];
        User nonOwner = [SELECT Id FROM User WHERE IsActive = true AND Id != :compliance.OwnerId LIMIT 1];

        System.runAs(nonOwner) {
            AVO_Compliance__c updateAttempt = [SELECT Id, AVO_Locked__c FROM AVO_Compliance__c WHERE Id = :compliance.Id];
            updateAttempt.AVO_Locked__c = true; // same value
            Test.startTest();
            update updateAttempt; // should pass
            Test.stopTest();
        }
    }
    
    @isTest
    static void testUnlocking_ShouldPass() {
        AVO_County__c county = new AVO_County__c(
            Name = 'County 4',
            AVO_County__c = 103,
            AVO_FIPS__c = 203,
            AVO_24_Coastal__c = 'No'
        );
        insert county;

        AVO_Compliance__c compliance = createCompliance(true, county.Id);
        insert compliance;

        compliance = [SELECT Id, AVO_Locked__c FROM AVO_Compliance__c WHERE Id = :compliance.Id];
        compliance.AVO_Locked__c = false;
        compliance.AVO_ReviewReason__c = 'Unlocking';
        Test.startTest();
        update compliance; // unlock should pass
        Test.stopTest();
    }

    @isTest
    static void testPreviouslyUnlockedNowLocked_ShouldPass() {
        AVO_County__c county = new AVO_County__c(
            Name = 'County 5',
            AVO_County__c = 104,
            AVO_FIPS__c = 204,
            AVO_24_Coastal__c = 'No'
        );
        insert county;

        AVO_Compliance__c compliance = createCompliance(false, county.Id);
        insert compliance;

        compliance = [SELECT Id, AVO_Locked__c FROM AVO_Compliance__c WHERE Id = :compliance.Id];
        compliance.AVO_Locked__c = true;
        compliance.AVO_ReviewReason__c = 'Locking for first time';
        Test.startTest();
        update compliance; // previously not locked, now locked – allowed
        Test.stopTest();
    }
}