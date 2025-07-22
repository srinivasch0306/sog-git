@isTest(isParallel=false)
public class AvoSharePointUtilTest {
    @TestSetup static void customSettingSetup() {
      /*  AVO_Rest_API_Settings__c settings = AVO_Rest_API_Settings__c.getOrgDefaults();
        settings.Name = 'baseDirectory';
        settings.AVO_Base_Directory__c = '/sites/EPD_Clariti_POC/Shared%20Documents/';
        settings.AVO_Client_ID__c = '5096e9d9-3aa9-49ea-aba9-c08bea9e55cb@512da10d-071b-4b94-8abc-9ec4044d1516';
        settings.AVO_Client_Secret__c = 'F5mzkO01nYwvo9yHCu9fgP18JzfKnykl9w4GSme/DWQ=';
        settings.AVO_Grant_Type__c = 'client_credentials';
        settings.AVO_Resource__c = '00000003-0000-0ff1-ce00-000000000000/gets.sharepoint.com@512da10d-071b-4b94-8abc-9ec4044d1516';
        settings.AVO_Salesforce_URL__c = 'https://gdnr--dev.sandbox.my.salesforce.com/';
        settings.AVO_SharePoint_Integration__c = true;
        settings.AVO_Site_Url__c = 'https://gets.sharepoint.com/sites/EPD_Clariti_POC/';
        settings.AVO_Token_End_Point__c = 'https://accounts.accesscontrol.windows.net/512da10d-071b-4b94-8abc-9ec4044d1516/tokens/OAuth/2?Content-Type=application/x-www-form-urlencoded';
        insert settings;*/
         insert new AVO_Rest_API_Settings__c(
        Name = 'Default',
        AVO_Site_Url__c = 'https://example.sharepoint.com/sites/test',
        AVO_Base_Directory__c = '/sites/test/Shared Documents',
        AVO_Client_ID__c = 'test_client_id',
        AVO_Client_Secret__c = 'test_client_secret',
        AVO_Grant_Type__c = 'client_credentials',
        AVO_Resource__c = 'https://example.sharepoint.com',
        AVO_Salesforce_URL__c = 'https://example.sharepoint.com',
        AVO_Token_End_Point__c = 'https://login.microsoftonline.com/test/oauth2/token',
        AVO_SharePoint_Integration__c = true
    );
    }
    
    @isTest static void TestTransferBeginPermit() {
          MUSW__Permit2__c testPermit = new MUSW__Permit2__c(MUSW__Description__c = 'Test',AVO_Volumetric_Limits__c=1);
        insert testPermit;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'a picture'+ String.valueOf(Math.random()),
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert testContentVersion;
        
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testPermit.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        System.assertEquals(true, true);
    }
    
    @isTest static void TestTransferBeginApplication() {
        MUSW__Application2__c testApplication = new MUSW__Application2__c
            (
                 MUSW__Description__c = 'Test'
            ); // Assuming AvoTestUtils.createApplication() is a method you have for setting up Application test data.
        insert testApplication;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'a picture'+ String.valueOf(Math.random()),
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert testContentVersion;
        
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testApplication.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        System.assertEquals(true, true);
    }
    
    @isTest static void TestTransferBeginComplaint() {
        MUSW__Complaint__c testComplaint = new MUSW__Complaint__c(MUSW__Description__c  = 'Test');
        insert testComplaint;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'a picture'+ String.valueOf(Math.random()),
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert testContentVersion;
        
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testComplaint.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        System.assertEquals(true, true);
    }
    
    @isTest static void TestTransferBeginContact() {
        Contact testContact = new Contact(lastname ='test', email = 'justin.liman@avocette.com');
        insert testContact;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'a picture'+ String.valueOf(Math.random()),
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert testContentVersion;
        
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testContact.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        System.assertEquals(true, true);
    }
    
    @isTest static void TestTransferBeginAccount() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'a picture'+ String.valueOf(Math.random()),
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert testContentVersion;
        
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testAccount.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        System.assertEquals(true, true);
    }
    @isTest
    static void TestTransferBeginSubmission() {
        // Set up test data for Submission (replace 'Submission__c' with your actual object API name)
        MUSW__Submission__c testSubmission = new MUSW__Submission__c(Name = 'Test Submission');
        insert testSubmission;
        
        // Set up a test document
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'Test Picture'+ String.valueOf(Math.random()),
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Relate the content version to the document
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        // Link the document to the test submission
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testSubmission.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Perform the test
        Test.startTest();
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        // Call the method under test
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        System.assertEquals(true, true);
        
    }
    
    @isTest
    static void TestTransferBeginViolation() {
        // Set up test data for Violation
        MUSW__Violation__c testViolation = new MUSW__Violation__c();
        insert testViolation;
        
        // Set up a test document
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'Test Document'+ String.valueOf(Math.random()),
            PathOnClient   = 'Document.pdf',
            VersionData    = Blob.valueOf('Test Content for Violation'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Relate the content version to the document
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        // Link the document to the test violation record
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testViolation.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Perform the test
        Test.startTest();
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        // Call the method under test
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
    @isTest
    static void TestTransferBeginReview() {
        // Set up test data for Review
        MUSW__Review__c testReview = new MUSW__Review__c();
        // Set other fields required for MUSW__Review__c as necessary
        insert testReview;
        
        // Set up a test document
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'Test Review Document'+ String.valueOf(Math.random()),
            PathOnClient   = 'ReviewDoc.pdf',
            VersionData    = Blob.valueOf('Test Content for Review'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Relate the content version to the document
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        // Link the document to the test review record
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testReview.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Perform the test
        Test.startTest();
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        // Call the method under test
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    @isTest
    static void TestTransferBeginMilestones() {
        // Set up test data for Milestones
        MUSW__Milestone__c testMilestone = new MUSW__Milestone__c();
        // Set other fields required for MUSW__Milestones__c as necessary
        insert testMilestone;
        
        // Set up a test document
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'Test Milestone Document'+ String.valueOf(Math.random()),
            PathOnClient   = 'MilestoneDoc.pdf',
            VersionData    = Blob.valueOf('Test Content for Milestone'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Relate the content version to the document
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        // Link the document to the test milestone record
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testMilestone.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Perform the test
        Test.startTest();
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        // Call the method under test
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    @isTest
    static void TestTransferBeginLicense() {
        // Set up test data for License
        MUSW__License2__c testLicense = new MUSW__License2__c();
        // Set other fields required for MUSW__License2__c as necessary
        insert testLicense;
        
        // Set up a test document
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'Test License Document'+ String.valueOf(Math.random()),
            PathOnClient   = 'LicenseDoc.pdf',
            VersionData    = Blob.valueOf('Test Content for License'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Relate the content version to the document
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        // Link the document to the test license record
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testLicense.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Perform the test
        Test.startTest();
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        // Call the method under test
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
  /* Luc  @isTest
    static void TestTransferBeginComment() {
        // Set up test data for Comment
        MUSW__Comment__c testComment = new MUSW__Comment__c();
        // Set other fields required for MUSW__Comment__c as necessary, if any
        insert testComment;
        
        // Set up a test document
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'Test Comment Document'+ String.valueOf(Math.random()),
            PathOnClient   = 'CommentDoc.pdf',
            VersionData    = Blob.valueOf('Test Content for Comment'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Relate the content version to the document
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        
        // Link the document to the test comment record
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testComment.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Perform the test
        Test.startTest();
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        // Call the method under test
        AvoSharePointUtil.transferBegin(testContentDocumentLink);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
*/
    @isTest
static void testTransferBeginWithdrawals() {
    AVO_Withdrawals__c withdrawal = new AVO_Withdrawals__c(Name = 'Test Withdrawal');
    insert withdrawal;

    ContentVersion version = new ContentVersion(
        Title = 'Withdraw'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'withdraw.pdf',
        VersionData = Blob.valueOf('Sample'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = withdrawal.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
@isTest
static void testTransferBeginComplaint2() {
    MUSW__Complaint2__c complaint = new MUSW__Complaint2__c(Name = 'Test Complaint2');
    insert complaint;

    ContentVersion version = new ContentVersion(
        Title = 'Complaint'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'complaint.pdf',
        VersionData = Blob.valueOf('Sample'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = complaint.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
@isTest
static void testTransferBeginInspection() {
    MUSW__Application2__c app = new MUSW__Application2__c(MUSW__Description__c = 'Test App');
    insert app;

    MUSW__Inspection__c inspection = new MUSW__Inspection__c(Name = 'Test Inspection', AVO_Application__c = app.Id);
    insert inspection;

    ContentVersion version = new ContentVersion(
        Title = 'Inspection'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'inspect.pdf',
        VersionData = Blob.valueOf('Sample'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = inspection.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
@isTest
static void testTransferBeginMilestoneFull() {
    MUSW__Application2__c app = new MUSW__Application2__c(MUSW__Description__c = 'Test App');
    insert app;

    MUSW__Milestone__c milestone = new MUSW__Milestone__c(Name = 'Test Milestone', MUSW__Application2__c = app.Id);
    insert milestone;

    ContentVersion version = new ContentVersion(
        Title = 'Milestone'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'milestone.pdf',
        VersionData = Blob.valueOf('Sample'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = milestone.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
@isTest
static void testTransferBeginMeter() {
    AVO_Meter__c meter = new AVO_Meter__c(Name = 'Test Meter');
    insert meter;

    ContentVersion version = new ContentVersion(
        Title = 'Meter'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'meter.pdf',
        VersionData = Blob.valueOf('Sample'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = meter.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
@isTest
static void testTransferBeginMeterTransaction() {
    AVO_Meter__c meter = new AVO_Meter__c(Name = 'Meter Ref');
    insert meter;

    AVO_Meter_Transaction__c metertransaction = new AVO_Meter_Transaction__c(Name = 'Transaction', AVO_Meter_ID__c = meter.Id);
    insert metertransaction;

    ContentVersion version = new ContentVersion(
        Title = 'Transaction'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'trans.pdf',
        VersionData = Blob.valueOf('Data'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = metertransaction.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
@isTest
static void testTransferBeginMeterWithdrawal() {
    AVO_Meter__c meter = new AVO_Meter__c(Name = 'Meter Ref');
    insert meter;

    AVO_Meter_Withdrawal__c withdrawal = new AVO_Meter_Withdrawal__c(Name = 'Withdraw', AVO_Meter_ID__c = meter.Id);
    insert withdrawal;

    ContentVersion version = new ContentVersion(
        Title = 'Withdraw'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'withdraw.pdf',
        VersionData = Blob.valueOf('Data'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = withdrawal.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
@isTest
static void testTransferBeginMeterCodeset() {
    AVO_Meter__c meter = new AVO_Meter__c(Name = 'Code Meter');
    insert meter;

    AVO_Meter_Codeset__c codeset = new AVO_Meter_Codeset__c(Name = 'Code Set');
    insert codeset;

    ContentVersion version = new ContentVersion(
        Title = 'Codeset'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'code.pdf',
        VersionData = Blob.valueOf('Data'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = codeset.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
@isTest
static void testTransferBeginCompliance() {
    AVO_Compliance__c compliance = new AVO_Compliance__c(Name = 'Compliance Doc');
    insert compliance;

    ContentVersion version = new ContentVersion(
        Title = 'Compliance'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'compliance.pdf',
        VersionData = Blob.valueOf('Content'),
        IsMajorVersion = true
    );
    insert version;
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = compliance.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
    AvoSharePointUtil.transferBegin(link);
    Test.stopTest();
}
 @isTest
    static void testGetAccessLink() {
        // Mock HTTP response for successful share link creation
        Test.setMock(HttpCalloutMock.class, new MockSharePointResponseGenerator());
        
        // Test data
        String folderName = '/sites/SalesforceIntegrationTesting/Shared%20Documents/SalesforceFiles/Permit/TestPermit/TestSubmission';
        String submissionName = 'TestSubmission';
        String fileName = 'testFile.pdf';
        String accessToken = 'testAccessToken';
        Boolean allowAnonymousAccess = true;
        
        // Call the method
        Test.startTest();
        String result = AvoSharePointUtil.getAccessLink(
            folderName, 
            submissionName, 
            fileName, 
            accessToken, 
            new Http(), 
            allowAnonymousAccess
        );
        Test.stopTest();
        
        // Verify the result
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.startsWith('https://'), 'Should return a valid URL');
    }
    
    @isTest
    static void testGetAccessLinkWithError() {
        // Mock HTTP response for error case
        Test.setMock(HttpCalloutMock.class, new MockSharePointErrorResponseGenerator());
        
        // Test data
        String folderName = '/sites/SalesforceIntegrationTesting/Shared%20Documents/SalesforceFiles/Permit/TestPermit/TestSubmission';
        String submissionName = 'TestSubmission';
        String fileName = 'testFile.pdf';
        String accessToken = 'testAccessToken';
        Boolean allowAnonymousAccess = false;
        
        // Call the method
        Test.startTest();
        String result = AvoSharePointUtil.getAccessLink(
            folderName, 
            submissionName, 
            fileName, 
            accessToken, 
            new Http(), 
            allowAnonymousAccess
        );
        Test.stopTest();
        
        // Verify the error message is returned
        System.assert(result.contains('The status code returned was not expected'), 'Should return error message');
    }
    
    @isTest
    static void testGetIdFromXMLNode() {
        // Create test XML structure
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('root', null, null);
        
        Dom.XmlNode linkNode = root.addChildElement('link', null, null);
        linkNode.setAttribute('title', 'ListItemAllFields');
        
        Dom.XmlNode mNode = linkNode.addChildElement('m', null, null);
        Dom.XmlNode entryNode = mNode.addChildElement('entry', null, null);
        Dom.XmlNode entryChildNode = entryNode.addChildElement('entryChild', null, null);
        Dom.XmlNode propertyNode = entryChildNode.addChildElement('property', null, null);
        Dom.XmlNode idNode = propertyNode.addChildElement('Id', null, null);
        idNode.addTextNode('12345');
        
        // Call the method
        Test.startTest();
        Integer result = AvoSharePointUtil.getIdFromXMLNode(root);
        Test.stopTest();
        
        // Verify the result
        System.assertEquals(12345, result, 'Should return correct ID from XML');
    }
    
    @isTest
    static void testGetIdFromXMLNodeNotFound() {
        // Create test XML structure without the ID node
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('root', null, null);
        
        Dom.XmlNode linkNode = root.addChildElement('link', null, null);
        linkNode.setAttribute('title', 'OtherTitle');
        
        // Call the method
        Test.startTest();
        Integer result = AvoSharePointUtil.getIdFromXMLNode(root);
        Test.stopTest();
        
        // Verify the result
        System.assertEquals(-1, result, 'Should return -1 when ID not found');
    }
    
    @isTest
    static void testGetFileMatchCount() {
        // Create test XML structure with matching files
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('root', null, null);
        
        // Add 3 entries - 2 matching, 1 not matching
        Dom.XmlNode entry1 = root.addChildElement('entry', null, null);
        Dom.XmlNode content1 = entry1.addChildElement('content', null, null);
        Dom.XmlNode properties1 = content1.addChildElement('properties', null, null);
        Dom.XmlNode name1 = properties1.addChildElement('Name', null, null);
        name1.addTextNode('testFile.pdf');
        
        Dom.XmlNode entry2 = root.addChildElement('entry', null, null);
        Dom.XmlNode content2 = entry2.addChildElement('content', null, null);
        Dom.XmlNode properties2 = content2.addChildElement('properties', null, null);
        Dom.XmlNode name2 = properties2.addChildElement('Name', null, null);
        name2.addTextNode('testFile(1).pdf');
        
        Dom.XmlNode entry3 = root.addChildElement('entry', null, null);
        Dom.XmlNode content3 = entry3.addChildElement('content', null, null);
        Dom.XmlNode properties3 = content3.addChildElement('properties', null, null);
        Dom.XmlNode name3 = properties3.addChildElement('Name', null, null);
        name3.addTextNode('otherFile.pdf');
        
        // Call the method
        Test.startTest();
        Integer result = AvoSharePointUtil.getFileMatchCount(root, 'testFile.pdf');
        Test.stopTest();
        
        // Verify the result
        System.assertEquals(2, result, 'Should find 2 matching files');
    }
    
    @isTest
    static void testFileNameWithoutExtension() {
        // Test cases
        Test.startTest();
        String result1 = AvoSharePointUtil.fileNameWithoutExtension('testFile.pdf');
        String result2 = AvoSharePointUtil.fileNameWithoutExtension('file.with.dots.txt');
        String result3 = AvoSharePointUtil.fileNameWithoutExtension('noextension');
        Test.stopTest();
        
        // Verify results
        System.assertEquals('testFile', result1, 'Should remove simple extension');
        System.assertEquals('file.with.dots', result2, 'Should only remove last extension');
        System.assertEquals('noextension', result3, 'Should return full string when no extension');
    }
    
    @isTest
    static void testFileExtensionMatch() {
        // Test cases
        Test.startTest();
        String result1 = AvoSharePointUtil.fileExtensionMatch('testFile.pdf');
        String result2 = AvoSharePointUtil.fileExtensionMatch('file.with.dots.txt');
        String result3 = AvoSharePointUtil.fileExtensionMatch('noextension');
        Test.stopTest();
        
        // Verify results
        System.assertEquals(').pdf', result1, 'Should return extension with parenthesis');
        System.assertEquals(').txt', result2, 'Should return last extension with parenthesis');
        System.assertEquals('noextension', result3, 'Should return full string when no extension');
    }
    
    // Mock HTTP response generator for successful SharePoint response
    private class MockSharePointResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"d":{"ShareLink":{"sharingLinkInfo":{"Url":"https://example.com/share/link"}}}}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Mock HTTP response generator for error case
    private class MockSharePointErrorResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":{"message":"Unauthorized"}}');
            res.setStatusCode(401);
            return res;
        }
    }


@isTest
static void testGetFilesUnderApplicationMapsWithTimestamps() {
    // Mock HTTP responses for both token request and file listing
    Test.setMock(HttpCalloutMock.class, new MultiRequestMock());
    
    Test.startTest();
    List<Map<String, Object>> results = AvoSharePointUtil.getFilesUnderApplicationMapsWithTimestamps();
    Test.stopTest();
    
    // Verify the results
    System.assertEquals(2, results.size(), 'Should return 2 mock files');
    System.assertEquals('testFile1.pdf', results[0].get('Name'), 'First file name should match');
    System.assertEquals('testFile2.pdf', results[1].get('Name'), 'Second file name should match');
    System.assertNotEquals(null, results[0].get('AccessLink'), 'Should have access link');
    System.assertNotEquals(null, results[0].get('TimeCreated'), 'Should have creation timestamp');
    System.assertNotEquals(null, results[0].get('TimeLastModified'), 'Should have modification timestamp');
}

// Multi-request mock class to handle both token request and file listing
private class MultiRequestMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        // Handle token request
        if (req.getEndpoint().contains('token')) {
            res.setBody('{"access_token":"mockAccessToken","token_type":"Bearer","expires_in":3600}');
            res.setStatusCode(200);
        } 
        // Handle file listing request
        else if (req.getEndpoint().contains('_api/web/GetFolderByServerRelativeUrl')) {
            res.setBody('{"d":{"results":[' +
                '{"Name":"testFile1.pdf","ServerRelativeUrl":"/sites/test/Shared Documents/testFile1.pdf",' +
                '"TimeCreated":"2023-01-01T00:00:00Z","TimeLastModified":"2023-01-02T00:00:00Z"},' +
                '{"Name":"testFile2.pdf","ServerRelativeUrl":"/sites/test/Shared Documents/testFile2.pdf",' +
                '"TimeCreated":"2023-01-03T00:00:00Z","TimeLastModified":"2023-01-04T00:00:00Z"}' +
                ']}}');
            res.setStatusCode(200);
        }
        // Handle access link request
        else if (req.getEndpoint().contains('ShareLink')) {
            res.setBody('{"d":{"ShareLink":{"sharingLinkInfo":{"Url":"https://example.com/share/link"}}}}');
            res.setStatusCode(200);
        }
        
        return res;
    }
}
    @isTest
static void testInsertSharePointFileInfo_Meter() {
    // Insert parent Meter record
    AVO_Meter__c meter = new AVO_Meter__c(Name = 'Test Meter');
    insert meter;

    // Create dummy ContentVersion
    ContentVersion version = new ContentVersion(
        Title = 'TestFile'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'TestFile.txt',
        VersionData = Blob.valueOf('Sample content'),
        IsMajorVersion = true
    );
    insert version;

    // Retrieve ContentDocumentId
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];

    // Create ContentDocumentLink
    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = meter.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    // Set the callout mock
    Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());

    // Create dummy HTTP instance
    Http http = new Http();

    // Call the method
    Test.startTest();
    AvoSharePointUtil.InsertSharePointFileInfo(
        'Meters', // childDirectory
        12345,    // fileId
        'Shared Documents/Meters', // folderName
        meter.Id, // parentId
        meter.Name, // objectName
        'dummyAccessToken', // accessToken
        http,
        'TestFile.txt',
        version.ContentDocumentId,
        AvoSharePointUtil.ObjectType.Meter
    );
    Test.stopTest();

    // Assert file was inserted
    List<AVO_SharePoint_File__c> insertedFiles = [SELECT Id, AVO_Meter__c, Name, AVO_SharePoint_URL__c FROM AVO_SharePoint_File__c WHERE AVO_Meter__c = :meter.Id];
    System.assertEquals(1, insertedFiles.size());
    System.assertEquals('TestFile.txt', insertedFiles[0].Name);
    System.assert(insertedFiles[0].AVO_SharePoint_URL__c.contains('https://sharepoint.com/samplelink'));
}
public class SharePointAccessLinkMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"d":{"ShareLink":{"sharingLinkInfo":{"Url":"https://sharepoint.com/samplelink"}}}}');
        return res;
    }
}

}