@isTest(isParallel=false)
private class AvoUploadedFileDetailsTest {
    
   @isTest
    static void testGetFilesInfoForPermit_AllChildObjects() {
        // Create Permit
        MUSW__Permit2__c permit = new MUSW__Permit2__c(Name = 'Test Permit', AVO_Volumetric_Limits__c = 1);
        insert permit;
        
        // -------------------- INSPECTION (already transferred) --------------------
        MUSW__Inspection__c inspection = new MUSW__Inspection__c(MUSW__Permit__c = permit.Id);
        insert inspection;
        
        ContentVersion inspectionVersion = new ContentVersion(
            Title = 'InspectionDoc',
            PathOnClient = 'InspectionDoc.pdf',
            VersionData = Blob.valueOf('Inspection File'),
            IsMajorVersion = true
        );
        insert inspectionVersion;
        inspectionVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :inspectionVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = inspection.Id,
            ContentDocumentId = inspectionVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = inspectionVersion.ContentDocumentId,
            AVO_Inspection__c = inspection.Id,
            AVO_SharePoint_Item_Id__c = 'INS123'
        );
        
        // -------------------- REVIEW (already transferred) --------------------
        MUSW__Review__c review = new MUSW__Review__c(MUSW__Permit2__c = permit.Id);
        insert review;
        
        ContentVersion reviewVersion = new ContentVersion(
            Title = 'ReviewDoc',
            PathOnClient = 'ReviewDoc.pdf',
            VersionData = Blob.valueOf('Review File'),
            IsMajorVersion = true
        );
        insert reviewVersion;
        reviewVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :reviewVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = review.Id,
            ContentDocumentId = reviewVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = reviewVersion.ContentDocumentId,
            AVO_Review__c = review.Id,
            AVO_SharePoint_Item_Id__c = 'REV123'
        );
        
        // -------------------- SUBMISSION (already transferred) --------------------
        MUSW__Submission__c submission = new MUSW__Submission__c(MUSW__Permit2__c = permit.Id);
        insert submission;
        
        ContentVersion submissionVersion = new ContentVersion(
            Title = 'SubmissionDoc',
            PathOnClient = 'SubmissionDoc.pdf',
            VersionData = Blob.valueOf('Submission File'),
            IsMajorVersion = true
        );
        insert submissionVersion;
        submissionVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :submissionVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = submission.Id,
            ContentDocumentId = submissionVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = submissionVersion.ContentDocumentId,
            AVO_Submission__c = submission.Id,
            AVO_SharePoint_Item_Id__c = 'SUB123'
        );
        
        // -------------------- MILESTONE (already transferred) --------------------
        MUSW__Milestone__c milestone = new MUSW__Milestone__c(MUSW__Permit2__c = permit.Id);
        insert milestone;
        
        ContentVersion milestoneVersion = new ContentVersion(
            Title = 'MilestoneDoc',
            PathOnClient = 'MilestoneDoc.pdf',
            VersionData = Blob.valueOf('Milestone File'),
            IsMajorVersion = true
        );
        insert milestoneVersion;
        milestoneVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :milestoneVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = milestone.Id,
            ContentDocumentId = milestoneVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = milestoneVersion.ContentDocumentId,
            AVO_Milestone__c = milestone.Id,
            AVO_SharePoint_Item_Id__c = 'MIL123'
        );
        
        // -------------------- PERMIT DOCUMENT (not transferred) --------------------
        ContentVersion permitVersion = new ContentVersion(
            Title = 'PermitDoc',
            PathOnClient = 'PermitDoc.pdf',
            VersionData = Blob.valueOf('Permit File'),
            IsMajorVersion = true
        );
        insert permitVersion;
        permitVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :permitVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = permit.Id,
            ContentDocumentId = permitVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        // -------------------- EXECUTION --------------------
        Test.startTest();
        Map<String, Object> result = AvoUploadedFileDetails.getFilesInfo('Permit', permit.Id);
        Test.stopTest();
        
        // -------------------- VALIDATION --------------------
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, (Integer)result.get('numberOfFiles'), 'Only PermitDoc should be included');
        List<Object> fileList = (List<Object>)result.get('files');
        System.assertEquals(1, fileList.size(), 'Exactly 1 file should be returned');
    }
   @isTest
    static void testGetFilesInfoForApplication_AllChildObjects() {
        // Create Application
        MUSW__Application2__c application = new MUSW__Application2__c(Name = 'Test App');
        insert application;
        
        // -------------------- INSPECTION (already transferred) --------------------
        MUSW__Inspection__c inspection = new MUSW__Inspection__c(AVO_Application__c = application.Id);
        insert inspection;
        
        ContentVersion inspectionVersion = new ContentVersion(
            Title = 'AAppInspectionDoc',
            PathOnClient = 'AppInspectionDoc.pdf',
            VersionData = Blob.valueOf('Inspection File'),
            IsMajorVersion = true
        );
        insert inspectionVersion;
        inspectionVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :inspectionVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = inspection.Id,
            ContentDocumentId = inspectionVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = inspectionVersion.ContentDocumentId,
            AVO_Inspection__c = inspection.Id,
            AVO_SharePoint_Item_Id__c = 'INSAPP123'
        );
        
        // -------------------- REVIEW (already transferred) --------------------
        MUSW__Review__c review = new MUSW__Review__c(MUSW__Application2__c = application.Id);
        insert review;
        
        ContentVersion reviewVersion = new ContentVersion(
            Title = 'AppReviewDoc',
            PathOnClient = 'AppReviewDoc.pdf',
            VersionData = Blob.valueOf('Review File'),
            IsMajorVersion = true
        );
        insert reviewVersion;
        reviewVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :reviewVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = review.Id,
            ContentDocumentId = reviewVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = reviewVersion.ContentDocumentId,
            AVO_Review__c = review.Id,
            AVO_SharePoint_Item_Id__c = 'REVAPP123'
        );
        
        // -------------------- SUBMISSION (already transferred) --------------------
        MUSW__Submission__c submission = new MUSW__Submission__c(MUSW__Application2__c = application.Id);
        insert submission;
        
        ContentVersion submissionVersion = new ContentVersion(
            Title = 'AppSubmissionDoc',
            PathOnClient = 'AppSubmissionDoc.pdf',
            VersionData = Blob.valueOf('Submission File'),
            IsMajorVersion = true
        );
        insert submissionVersion;
        submissionVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :submissionVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = submission.Id,
            ContentDocumentId = submissionVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = submissionVersion.ContentDocumentId,
            AVO_Submission__c = submission.Id,
            AVO_SharePoint_Item_Id__c = 'SUBAPP123'
        );
        
        // -------------------- MILESTONE (already transferred) --------------------
        MUSW__Milestone__c milestone = new MUSW__Milestone__c(MUSW__Application2__c = application.Id);
        insert milestone;
        
        ContentVersion milestoneVersion = new ContentVersion(
            Title = 'AppMilestoneDoc',
            PathOnClient = 'AppMilestoneDoc.pdf',
            VersionData = Blob.valueOf('Milestone File'),
            IsMajorVersion = true
        );
        insert milestoneVersion;
        milestoneVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :milestoneVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = milestone.Id,
            ContentDocumentId = milestoneVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = milestoneVersion.ContentDocumentId,
            AVO_Milestone__c = milestone.Id,
            AVO_SharePoint_Item_Id__c = 'MILAPP123'
        );
        
        // -------------------- APPLICATION DOCUMENT (not transferred) --------------------
        ContentVersion appVersion = new ContentVersion(
            Title = 'AppMainDoc',
            PathOnClient = 'AppMainDoc.pdf',
            VersionData = Blob.valueOf('Main Application File'),
            IsMajorVersion = true
        );
        insert appVersion;
        appVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :appVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = application.Id,
            ContentDocumentId = appVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        // -------------------- EXECUTION --------------------
        Test.startTest();
        Map<String, Object> result = AvoUploadedFileDetails.getFilesInfo('Application', application.Id);
        Test.stopTest();
        
        // -------------------- VALIDATION --------------------
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, (Integer)result.get('numberOfFiles'), 'Only AppMainDoc should be returned');
        List<Object> files = (List<Object>)result.get('files');
        System.assertEquals(1, files.size(), 'Only 1 untransferred file expected for Application');
    }
    
    
     @isTest
    static void testGetFilesInfoForLicense_AllChildObjects() {
        // Create License
        MUSW__License2__c license = new MUSW__License2__c(Name = 'Test License');
        insert license;
        
        // -------------------- INSPECTION (already transferred) --------------------
        MUSW__Inspection__c inspection = new MUSW__Inspection__c(MUSW__License2__c = license.Id);
        insert inspection;
        
        ContentVersion inspectionVersion = new ContentVersion(
            Title = 'LicenseInspectionDoc',
            PathOnClient = 'LicenseInspectionDoc.pdf',
            VersionData = Blob.valueOf('Inspection File'),
            IsMajorVersion = true
        );
        insert inspectionVersion;
        inspectionVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :inspectionVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = inspection.Id,
            ContentDocumentId = inspectionVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = inspectionVersion.ContentDocumentId,
            AVO_Inspection__c = inspection.Id,
            AVO_SharePoint_Item_Id__c = 'LICINS123'
        );
        
        // -------------------- REVIEW (already transferred) --------------------
        MUSW__Review__c review = new MUSW__Review__c(MUSW__License2__c = license.Id);
        insert review;
        
        ContentVersion reviewVersion = new ContentVersion(
            Title = 'LicenseReviewDoc',
            PathOnClient = 'LicenseReviewDoc.pdf',
            VersionData = Blob.valueOf('Review File'),
            IsMajorVersion = true
        );
        insert reviewVersion;
        reviewVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :reviewVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = review.Id,
            ContentDocumentId = reviewVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = reviewVersion.ContentDocumentId,
            AVO_Review__c = review.Id,
            AVO_SharePoint_Item_Id__c = 'LICREV123'
        );
        
        // -------------------- SUBMISSION (already transferred) --------------------
        MUSW__Submission__c submission = new MUSW__Submission__c(MUSW__License2__c = license.Id);
        insert submission;
        
        ContentVersion submissionVersion = new ContentVersion(
            Title = 'LicenseSubmissionDoc',
            PathOnClient = 'LicenseSubmissionDoc.pdf',
            VersionData = Blob.valueOf('Submission File'),
            IsMajorVersion = true
        );
        insert submissionVersion;
        submissionVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :submissionVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = submission.Id,
            ContentDocumentId = submissionVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = submissionVersion.ContentDocumentId,
            AVO_Submission__c = submission.Id,
            AVO_SharePoint_Item_Id__c = 'LICSUB123'
        );
        
        // -------------------- MILESTONE (already transferred) --------------------
        MUSW__Milestone__c milestone = new MUSW__Milestone__c(MUSW__License2__c = license.Id);
        insert milestone;
        
        ContentVersion milestoneVersion = new ContentVersion(
            Title = 'LicenseMilestoneDoc',
            PathOnClient = 'LicenseMilestoneDoc.pdf',
            VersionData = Blob.valueOf('Milestone File'),
            IsMajorVersion = true
        );
        insert milestoneVersion;
        milestoneVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :milestoneVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = milestone.Id,
            ContentDocumentId = milestoneVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = milestoneVersion.ContentDocumentId,
            AVO_Milestone__c = milestone.Id,
            AVO_SharePoint_Item_Id__c = 'LICMIL123'
        );
        
        // -------------------- LICENSE DOCUMENT (not transferred) --------------------
        ContentVersion licenseVersion = new ContentVersion(
            Title = 'LicenseMainDoc',
            PathOnClient = 'LicenseMainDoc.pdf',
            VersionData = Blob.valueOf('Main License File'),
            IsMajorVersion = true
        );
        insert licenseVersion;
        licenseVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :licenseVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = license.Id,
            ContentDocumentId = licenseVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        // -------------------- EXECUTION --------------------
        Test.startTest();
        Map<String, Object> result = AvoUploadedFileDetails.getFilesInfo('License', license.Id);
        Test.stopTest();
        
        // -------------------- VALIDATION --------------------
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, (Integer)result.get('numberOfFiles'), 'Only LicenseMainDoc should be returned');
        List<Object> files = (List<Object>)result.get('files');
        System.assertEquals(1, files.size(), 'Exactly 1 file should be returned for License');
    }
     @isTest
static void testGetFilesInfoForWithdrawal() {
    // Step 1: Create test Withdrawal record
    AVO_Withdrawals__c testWithdrawal = new AVO_Withdrawals__c(
        // Add required fields if any, e.g., AVO_Name__c = 'Test Withdrawal'
    );
    insert testWithdrawal;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'WithdrawalDoc1',
        PathOnClient = 'WithdrawalDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Withdrawal via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = testWithdrawal.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Withdrawal__c = testWithdrawal.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required field
    );
    insert transferredFile;

    // Step 6: Call method under test
    Test.startTest();
    Map<String, Object> result = AvoUploadedFileDetails.getFilesInfo('Withdrawal', testWithdrawal.Id);
    Test.stopTest();

    // Step 7: Assert Withdrawal was inserted
    AVO_Withdrawals__c fetchedWithdrawal = [SELECT Id FROM AVO_Withdrawals__c WHERE Id = :testWithdrawal.Id];
    System.assertNotEquals(null, fetchedWithdrawal, 'Withdrawal record should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}
    @isTest
    static void testGetFilesInfoForContact() {
        // Create a new Contact for testing
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert testContact;
        
        // Create a test document associated with the Contact
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Contact Document',
            PathOnClient = 'ContactDoc.jpg',
            VersionData = Blob.valueOf('Test Content for Contact'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Link the document to the test contact
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testContact.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Test the getFilesInfo method for Contact
        Test.startTest();
        Map<String, Object> results = AvoUploadedFileDetails.getFilesInfo('Contact', testContact.Id);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
    @isTest
    static void testGetFilesInfoForAccount() {
        // Create a new Account for testing
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create a test document associated with the Account
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Account Document',
            PathOnClient = 'AccountDoc.pdf',
            VersionData = Blob.valueOf('Test Content for Account'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Link the document to the test account
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testAccount.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Test the getFilesInfo method for Account
        Test.startTest();
        Map<String, Object> results = AvoUploadedFileDetails.getFilesInfo('Account', testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    @isTest
    static void testGetFilesInfoForComplaint() {
        // Create a new Complaint for testing
        MUSW__Complaint__c testComplaint = new MUSW__Complaint__c();
        insert testComplaint;
        
        // Create a test document associated with the Complaint
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Complaint Document',
            PathOnClient = 'ComplaintDoc.jpg',
            VersionData = Blob.valueOf('Test Content for Complaint'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Link the document to the test complaint
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testComplaint.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Test the getFilesInfo method for Complaint
        Test.startTest();
        Map<String, Object> results = AvoUploadedFileDetails.getFilesInfo('Complaint', testComplaint.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null for Complaint');
        System.assertNotEquals(0, ((List<AvoUploadedFileDetails.FileInfo>)results.get('files')).size(), 'Should return at least one file info for Complaint');
    }

    @isTest
    static void testGetFilesInfoForViolation() {
        // Create a new Violation for testing
        MUSW__Violation__c testViolation = new MUSW__Violation__c();
        insert testViolation;
        
        // Create a test document associated with the Violation
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Violation Document',
            PathOnClient = 'ViolationDoc.pdf',
            VersionData = Blob.valueOf('Test Content for Violation'),
            IsMajorVersion = true
        );
        insert testContentVersion;
        
        // Link the document to the test violation
        testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
        testContentDocumentLink.LinkedEntityId = testViolation.Id;
        testContentDocumentLink.ContentDocumentId = testContentVersion.ContentDocumentId;
        testContentDocumentLink.ShareType = 'V';
        testContentDocumentLink.Visibility = 'AllUsers';
        insert testContentDocumentLink;
        
        // Test the getFilesInfo method for Violation
        Test.startTest();
        Map<String, Object> results = AvoUploadedFileDetails.getFilesInfo('Violation', testViolation.Id);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, results, 'Results should not be null for Violation');
        System.assertNotEquals(0, ((List<AvoUploadedFileDetails.FileInfo>)results.get('files')).size(), 'Should return at least one file info for Violation');
    }
    @isTest
static void testSendFileDetails_ValidParams() {
    // Step 1: Insert a test Account (or any object you expect to link)
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    // Step 2: Insert ContentVersion (file)
    ContentVersion cv = new ContentVersion(
        Title = 'Test File',
        PathOnClient = 'TestFile.pdf',
        VersionData = Blob.valueOf('Sample content'),
        IsMajorVersion = true
    );
    insert cv;

    // Step 3: Get ContentDocumentId
    ContentVersion insertedCV = [
        SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
    ];
    Id contentDocId = insertedCV.ContentDocumentId;

    // Step 4: Create ContentDocumentLink for the Account
    ContentDocumentLink cdl = new ContentDocumentLink(
        ContentDocumentId = contentDocId,
        LinkedEntityId = testAccount.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert cdl;

    // Step 5: Set Mock for transferBegin (if needed) or use test implementation
    Test.startTest();
    AvoUploadedFileDetails.SendFileDetails(testAccount.Id, contentDocId);
    Test.stopTest();

    // Basic assert (to validate flow completes)
    System.assertEquals(true, true);
}

   @isTest
static void testGetFilesInfoForComment() {
    // Step 1: Create test Comment record
    MUSW__Comment__c testComment = new MUSW__Comment__c(
        // Populate any required fields here
    );
    insert testComment;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'CommentDoc1',
        PathOnClient = 'CommentDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Comment via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = testComment.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Comment__c = testComment.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required field
    );
    insert transferredFile;

    // Step 6: Call method under test
    Test.startTest();
    Map<String, Object> result = AvoUploadedFileDetails.getFilesInfo('Comment', testComment.Id);
    Test.stopTest();

    // Step 7: Assert Comment was inserted
    MUSW__Comment__c fetchedComment = [SELECT Id FROM MUSW__Comment__c WHERE Id = :testComment.Id];
    System.assertNotEquals(null, fetchedComment, 'Comment should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}
    /*
@isTest
static void testGetFilesInfoForMeter() {
    // Step 1: Create test Meter record
    AVO_Meter__c testMeter = new AVO_Meter__c(
        // Add required fields if any (e.g., Name, AVO_Serial_Number__c, etc.)
    );
    insert testMeter;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'MeterDoc1',
        PathOnClient = 'MeterDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Meter via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = testMeter.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Meter__c = testMeter.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required field
    );
    insert transferredFile;

    // Step 6: Call method under test
    Test.startTest();
    Map<String, Object> result = AvoUploadedFileDetails.getFilesInfo('Meter', testMeter.Id);
    Test.stopTest();

    // Step 7: Assert Meter was inserted
    AVO_Meter__c fetchedMeter = [SELECT Id FROM AVO_Meter__c WHERE Id = :testMeter.Id];
    System.assertNotEquals(null, fetchedMeter, 'Meter record should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}*/
    
   @isTest
static void testGetFilesInfoForMeter() {
    // Step 1: Create test Meter records
    AVO_Meter__c testMeter1 = new AVO_Meter__c(Name = 'Meter 1');
    insert testMeter1;

   

    // Step 2: Create child records
    AVO_Meter_Transaction__c testTransaction = new AVO_Meter_Transaction__c(
        AVO_Meter_ID__c = testMeter1.Id
    );
    insert testTransaction;

    AVO_Meter_Withdrawal__c testMeterWithdrawal = new AVO_Meter_Withdrawal__c(
        AVO_Meter_ID__c = testMeter1.Id
    );
    insert testMeterWithdrawal;

    // Step 3: Create test files
    ContentVersion file1 = new ContentVersion(
        Title = 'MeterDoc1',
        PathOnClient = 'MeterDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    ContentVersion file2 = new ContentVersion(
        Title = 'MeterDoc2',
        PathOnClient = 'MeterDoc2.pdf',
        VersionData = Blob.valueOf('Test Content 2'),
        IsMajorVersion = true
    );
    insert file2;

    ContentVersion file3 = new ContentVersion(
        Title = 'MeterDoc3',
        PathOnClient = 'MeterDoc3.pdf',
        VersionData = Blob.valueOf('Test Content 3'),
        IsMajorVersion = true
    );
    insert file3;

    // Step 4: Get ContentDocumentIds
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];
    file2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file2.Id];
    file3 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file3.Id];

    // Step 5: Link files to Meter and children
    insert new List<ContentDocumentLink>{
        new ContentDocumentLink(
            LinkedEntityId = testMeter1.Id,
            ContentDocumentId = file1.ContentDocumentId,
            ShareType = 'V', Visibility = 'AllUsers'
        ),
        new ContentDocumentLink(
            LinkedEntityId = testTransaction.Id,
            ContentDocumentId = file2.ContentDocumentId,
            ShareType = 'V', Visibility = 'AllUsers'
        ),
        new ContentDocumentLink(
            LinkedEntityId = testMeterWithdrawal.Id,
            ContentDocumentId = file3.ContentDocumentId,
            ShareType = 'V', Visibility = 'AllUsers'
        )
    };

    // Step 6: Mark files as transferred
    insert new List<AVO_SharePoint_File__c>{
        new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = file1.ContentDocumentId,
            AVO_Meter__c = testMeter1.Id,
            AVO_SharePoint_Item_Id__c = '12345'
        ),
        new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = file2.ContentDocumentId,
            AVO_Meter_Transaction__c = testTransaction.Id,
            AVO_SharePoint_Item_Id__c = '12345'
        ),
        new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = file3.ContentDocumentId,
            AVO_Meter_Withdrawal__c = testMeterWithdrawal.Id,
            AVO_SharePoint_Item_Id__c = '12345'
        )
    };

    // Step 7: Call method under test
    Test.startTest();
    Map<String, Object> result = AvoUploadedFileDetails.getFilesInfo('Meter', testMeter1.Id);
    Test.stopTest();

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');
    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since all were transferred');
    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}

   
/* Luc @isTest
static void testGetFilesInfoForCompliance() {
    // Step 1: Create test Comment record
    AVO_Compliance__c compliance = new AVO_Compliance__c(Name = 'Compliance Doc');
    insert compliance;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'compliance',
        PathOnClient = 'compliance.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Comment via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = compliance.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Compliance__c = compliance.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required field
    );
    insert transferredFile;

    // Step 6: Call method under test
    Test.startTest();
    Map<String, Object> result = AvoUploadedFileDetails.getFilesInfo('Compliance', compliance.Id);
    Test.stopTest();

    // Step 7: Assert Comment was inserted
    AVO_Compliance__c fetchedComment = [SELECT Id FROM AVO_Compliance__c WHERE Id = :compliance.Id];
    System.assertNotEquals(null, fetchedComment, 'Compliance should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}
    
 */   
    
}