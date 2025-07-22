@isTest
private class AvoGenericCloneServiceTest {
    @isTest
    static void testCloneRecords() {
        // Step 1: Create a Parent Record
        Account parentAccount = new Account(Name = 'Parent Account');
        insert parentAccount;
        
        Account newParentAccount = new Account(Name = 'New Parent Account');
        insert newParentAccount;
        
        // Step 2: Create Child Records (records to be cloned)
        Contact contact1 = new Contact(LastName = 'Doe', AccountId = parentAccount.Id);
        Contact contact2 = new Contact(LastName = 'Smith', AccountId = parentAccount.Id);
        insert new List<Contact>{ contact1, contact2 };
        
        // Step 3: Create Attachments (ContentVersion)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test Data'),
            FirstPublishLocationId = contact1.Id
        );
        insert contentVersion;
        
        // Retrieve ContentDocumentId
        ContentDocument contentDoc = [
            SELECT Id FROM ContentDocument 
            WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id)
            LIMIT 1
        ];
        
        // Step 4: Prepare CloneRequest
        AvoGenericCloneService.CloneRequest request = new AvoGenericCloneService.CloneRequest();
        request.records = new List<SObject>{ contact1, contact2 };
        request.parentApiName = 'AccountId';
        request.newParentValue = newParentAccount.Id;
        request.includeAttachments = true;
        
        // Step 5: Call cloneRecords method
        Test.startTest();
        AvoGenericCloneService.cloneRecords(new List<AvoGenericCloneService.CloneRequest>{ request });
        Test.stopTest();
        
        // Step 6: Verify Cloning
        List<Contact> clonedContacts = [
            SELECT Id, AccountId FROM Contact WHERE AccountId = :newParentAccount.Id
        ];
        System.assertEquals(2, clonedContacts.size(), 'Two contacts should be cloned.');
        
        // Step 7: Verify Attachments are Cloned
        List<ContentDocumentLink> newAttachments = [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :clonedContacts[0].Id
        ];
        System.assertEquals(1, newAttachments.size(), 'One attachment should be linked to the cloned contact.');
    }
}