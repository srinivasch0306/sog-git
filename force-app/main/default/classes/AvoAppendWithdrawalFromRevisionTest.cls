@isTest
private class AvoAppendWithdrawalFromRevisionTest {

    @isTest
    static void testSyncFilesFromChildToParentFlow() {
        // Step 1: Create a parent and child permit
        MUSW__Permit2__c parentPermit = new MUSW__Permit2__c(Name = 'Parent Permit', AVO_Volumetric_Limits__c = 10);
        MUSW__Permit2__c childPermit = new MUSW__Permit2__c(Name = 'Child Permit', AVO_Volumetric_Limits__c = 10);
        insert new List<MUSW__Permit2__c>{ parentPermit, childPermit };
        
        // Step 2: Create a child AVO_Withdrawals__c record
        AVO_Withdrawals__c childWithdrawal = new AVO_Withdrawals__c(
            Name = 'Test Withdrawal',
            AVO_Permit__c = childPermit.Id
        );
        insert childWithdrawal;

        // Step 3: Build SyncRequest
        AvoAppendWithdrawalFromRevision.SyncRequest request = new AvoAppendWithdrawalFromRevision.SyncRequest();
        request.childRecordId = childPermit.Id;
        request.parentRecordId = parentPermit.Id;

        // Step 4: Invoke the method
        Test.startTest();
        AvoAppendWithdrawalFromRevision.syncFilesFromChildToParentFlow(new List<AvoAppendWithdrawalFromRevision.SyncRequest>{ request });
        Test.stopTest();

        // Step 5: Assert that new AVO_Withdrawals__c was created for parent
        List<AVO_Withdrawals__c> parentWithdrawals = [
            SELECT Id, AVO_Permit__c, AVO_From_Revision__c 
            FROM AVO_Withdrawals__c 
            WHERE AVO_Permit__c = :parentPermit.Id
        ];

        System.assertEquals(1, parentWithdrawals.size(), 'One withdrawal record should be copied to parent');
        System.assertEquals(true, parentWithdrawals[0].AVO_From_Revision__c, 'Copied withdrawal should be marked as from revision');
    }
}