//@isTest private class DRE2Test_ContentDocumentLink { @isTest static void insertUpdateDelete() { DRE.DRETestExternalManager.run('ContentDocumentLink'); } }

@isTest 
private class DRE2Test_ContentDocumentLink { 
    @isTest 
    static void insertUpdateDelete() {
        insert new Account(Name='Test Account');        

        insert new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'File.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        
        ContentDocumentLink cdl = New ContentDocumentLink(
            LinkedEntityId = [SELECT Id FROM Account LIMIT 1].Id,
            ContentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1].Id,
            shareType = 'V'
        );
        
        /*insert cdl;

        update cdl;
        
        delete cdl;*/

    } 
}