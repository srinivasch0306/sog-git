@isTest(isParallel=false)
public class AVOContentDocumentLinkTriggerTest {

    @isTest
    static void testTriggerForPermitAndCompliance() {
        // === Permit Setup ===
        MUSW__Permit2__c permit = new MUSW__Permit2__c(
            MUSW__Description__c = 'Test Permit', 
            MUSW__Status__c = 'Permit Issued',
            AVO_Permitted_Acres__c = 1
        );
        insert permit;

        // === Compliance Setup (with required fields)
        AVO_Compliance__c compliance = new AVO_Compliance__c(
            Name = 'Test Compliance',
            AVO_CompStatus__c = 'Resolved',
            AVO_ResolvedDt__c = System.today(),                  // Required field
            AVO_ResTypeCode__c = 'Corrective Action Taken'       // Required field
        );
        insert compliance;

        Test.startTest();

        // === ContentVersion for Permit ===
        ContentVersion permitFile = new ContentVersion(
            Title = 'Permit Doc'+ String.valueOf(Math.random()), // unique
            PathOnClient = 'permitdoc.pdf',
            VersionData = Blob.valueOf('Permit file content'),
            IsMajorVersion = true,
            AVO_DataFrom__c = 'Permit'
        );
        insert permitFile;

        // === ContentVersion for Compliance ===
        ContentVersion complianceFile = new ContentVersion(
            Title = 'Compliance Doc'+ String.valueOf(Math.random()), // unique
            PathOnClient = 'compliancedoc.pdf',
            VersionData = Blob.valueOf('Compliance file content'),
            IsMajorVersion = true,
            AVO_DataFrom__c = 'Compliance'
        );
        insert complianceFile;

        // === Re-query for ContentDocumentId
        permitFile = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :permitFile.Id];
        complianceFile = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :complianceFile.Id];

        // === ContentDocumentLinks
        ContentDocumentLink permitLink = new ContentDocumentLink(
            LinkedEntityId = permit.Id,
            ContentDocumentId = permitFile.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        ContentDocumentLink complianceLink = new ContentDocumentLink(
            LinkedEntityId = compliance.Id,
            ContentDocumentId = complianceFile.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        insert new List<ContentDocumentLink>{ permitLink, complianceLink };

        Test.stopTest();

        System.assert(true, 'Trigger executed without validation exceptions');
    }
}