@isTest
private class AVOAttachmentCloneServiceTest {
    @isTest
    static void testAVOCloneAttachments() {
        // Step 1: Create a source record
        Account sourceAccount = new Account(Name = 'Source Account');
        insert sourceAccount;
        
        // Step 2: Create a target record
        Account targetAccount = new Account(Name = 'Target Account');
        insert targetAccount;
        
        // Step 3: Create a ContentVersion and associate it with the source record
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test Data'),
            FirstPublishLocationId = sourceAccount.Id  // Automatically links ContentDocument to source
        );
        insert contentVersion;
        
        // Retrieve ContentDocumentId (since ContentVersion auto-links ContentDocument)
        ContentDocument contentDoc = [ 
            SELECT Id FROM ContentDocument 
            WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id) 
            LIMIT 1 
        ];
        
        // Step 4: Prepare request and call method
        AVOAttachmentCloneService.AVOAttachmentCloneRequest request = new AVOAttachmentCloneService.AVOAttachmentCloneRequest();
        request.sourceRecordId = sourceAccount.Id;
        request.targetRecordId = targetAccount.Id;
        
        Test.startTest();
        AVOAttachmentCloneService.AVOCloneAttachments(new List<AVOAttachmentCloneService.AVOAttachmentCloneRequest>{ request });
        Test.stopTest();
        
        // Step 5: Verify new attachments were created for the target record
        List<ContentDocumentLink> targetLinks = [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :targetAccount.Id
        ];
        
        System.assertEquals(1, targetLinks.size(), 'One attachment should be linked to the target record.');
    }
}