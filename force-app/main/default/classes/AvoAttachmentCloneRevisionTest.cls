@isTest
private class AvoAttachmentCloneRevisionTest {

    @testSetup
    static void setupData() {
        // Create dummy parent and child records (assuming Permit__c is a custom object)
        MUSW__Permit2__c parent = new MUSW__Permit2__c(Name = 'Parent Account', AVO_Volumetric_Limits__c = 10);
        insert parent;

        MUSW__Permit2__c child = new MUSW__Permit2__c(Name = 'Child Account', AVO_Volumetric_Limits__c = 11);
        insert child;

        // Create ContentDocument and related ContentVersion linked to child
        Blob body = Blob.valueOf('Test file content');
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile.txt',
            PathOnClient = 'TestFile.txt',
            VersionData = body
        );
        insert cv;

        // Fetch the ContentDocumentId
        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = child.Id,
            ShareType = 'V'
        );
        insert cdl;

        // Add a SharePoint file to child
        AVO_SharePoint_File__c spFile = new AVO_SharePoint_File__c(
            Name = 'SharePoint_File_1',
            AVO_Permit__c = child.Id,
            AVO_SharePoint_URL__c = 'https://example.com/file1',
            AVO_SharePoint_Item_Id__c = 'ASDF'
        );
        insert spFile;
    }

    @isTest
    static void testSyncFilesFromChildToParentFlow() {
        // Get child and parent
        MUSW__Permit2__c parent = [SELECT Id FROM MUSW__Permit2__c WHERE Name = 'Parent Account' LIMIT 1];
        MUSW__Permit2__c child = [SELECT Id,MUSW__Status__c FROM MUSW__Permit2__c WHERE Name = 'Child Account' LIMIT 1];

        // Prepare request
        AvoAttachmentCloneRevision.SyncRequest request = new AvoAttachmentCloneRevision.SyncRequest();
        request.childRecordId = child.Id;
        request.parentRecordId = parent.Id;

        Test.startTest();
        AvoAttachmentCloneRevision.syncFilesFromChildToParentFlow(new List<AvoAttachmentCloneRevision.SyncRequest>{ request });
        Test.stopTest();

        // Verify: ContentVersion was copied to parent
        List<ContentDocumentLink> parentLinks = [
            SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :parent.Id
        ];
        System.assertEquals(1, parentLinks.size(), 'ContentDocument should be copied to parent');

        // Verify: SharePoint file was copied
        List<AVO_SharePoint_File__c> parentSPFiles = [
            SELECT Id, Name, AVO_SharePoint_URL__c FROM AVO_SharePoint_File__c WHERE AVO_Permit__c = :parent.Id
        ];
        System.assertEquals(1, parentSPFiles.size(), 'SharePoint file should be copied to parent');
        System.assertEquals('SharePoint_File_1', parentSPFiles[0].Name);
    }

    @isTest
    static void testDuplicateSharePointFileNotCopied() {
        // Setup duplicate SharePoint file on parent
        MUSW__Permit2__c parent = [SELECT Id FROM MUSW__Permit2__c WHERE Name = 'Parent Account' LIMIT 1];
        AVO_SharePoint_File__c duplicate = new AVO_SharePoint_File__c(
            Name = 'SharePoint_File_1',
            AVO_Permit__c = parent.Id,
            AVO_SharePoint_URL__c = 'https://example.com/file1',
            AVO_SharePoint_Item_Id__c = 'ASDF'
        );
        insert duplicate;

        MUSW__Permit2__c child = [SELECT Id FROM MUSW__Permit2__c WHERE Name = 'Child Account' LIMIT 1];
        AvoAttachmentCloneRevision.SyncRequest request = new AvoAttachmentCloneRevision.SyncRequest();
        request.childRecordId = child.Id;
        request.parentRecordId = parent.Id;

        Test.startTest();
        AvoAttachmentCloneRevision.syncFilesFromChildToParentFlow(new List<AvoAttachmentCloneRevision.SyncRequest>{ request });
        Test.stopTest();

        // Verify: Still only 1 SharePoint file with same name on parent
        List<AVO_SharePoint_File__c> parentSPFiles = [
            SELECT Id FROM AVO_SharePoint_File__c WHERE AVO_Permit__c = :parent.Id AND Name = 'SharePoint_File_1'
        ];
        System.assertEquals(1, parentSPFiles.size(), 'Duplicate SharePoint file should not be inserted');
    }
}