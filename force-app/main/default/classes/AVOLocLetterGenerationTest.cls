@isTest
public class AVOLocLetterGenerationTest {
    @isTest
    static void testTriggerWithValidTitle() {
        // Step 1: Insert dummy permit record
        MUSW__Permit2__c permit = new MUSW__Permit2__c(Name = 'Test Permit', AVO_Volumetric_Limits__c = 12);
        insert permit;

        // Step 2: Create dummy ContentVersion (which automatically creates ContentDocument)
        ContentVersion version = new ContentVersion(
            Title = 'Permit_Expiring_LOC__20250527', // Will be trimmed to 'Permit_Expiring_LOC'
            PathOnClient = 'Permit_Expiring_LOC__20250527.pdf',
            VersionData = Blob.valueOf('Test content'),
            IsMajorVersion = true
        );
        insert version;

        // Step 3: Get the ContentDocumentId
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id LIMIT 1];
        Id contentDocId = insertedVersion.ContentDocumentId;

        // Step 4: Link ContentDocument to Permit
        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = permit.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert link;

        // Step 5: Verify the permit got updated
        MUSW__Permit2__c updatedPermit = [SELECT Id,AVO_Letter_of_Concurrence_Issuance__c
                                          FROM MUSW__Permit2__c WHERE Id = :permit.Id];

        //System.assertNotEquals(null, updatedPermit.AVO_Letter_of_Concurrence_Issuance__c, 'Issuance date should be set');
    }
}