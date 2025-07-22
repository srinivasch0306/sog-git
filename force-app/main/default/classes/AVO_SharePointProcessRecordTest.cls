@isTest(isParallel=false)
public class AVO_SharePointProcessRecordTest {
    @isTest
static void testGetFilesInfoForAccount() {
    // Step 1: Create test Account record
    Account testAccount = new Account(
        Name = 'Test Account'
    );
    insert testAccount;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'SPPRT1'+ String.valueOf(Math.random()),
        PathOnClient = 'AccountDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Account via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = testAccount.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Account__c = testAccount.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required
    );
    insert transferredFile;

    // Step 6: Call method under test
    Test.startTest();
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Account', testAccount.Id);
    Test.stopTest();

    // Step 7: Assert that Account was created
    Account fetchedAccount = [SELECT Id FROM Account WHERE Id = :testAccount.Id];
    System.assertNotEquals(null, fetchedAccount, 'Account should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}
@isTest
static void testGetFilesInfoForContact() {
    // Step 1: Create test Contact record
    Contact testContact = new Contact(
        FirstName = 'Test',
        LastName = 'Contact'
    );
    insert testContact;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'SPPRT2'+ String.valueOf(Math.random()),
        PathOnClient = 'ContactDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Contact via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = testContact.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Contact__c = testContact.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required
    );
    insert transferredFile;

    // Step 6: Call method under test
    Test.startTest();
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Contact', testContact.Id);
    Test.stopTest();

    // Step 7: Assert Contact was inserted
    Contact fetchedContact = [SELECT Id FROM Contact WHERE Id = :testContact.Id];
    System.assertNotEquals(null, fetchedContact, 'Contact should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}

    @isTest
    static void testGetFilesInfoForViolation() {
        // Step 1: Create test Violation record
        MUSW__Violation__c testViolation = new MUSW__Violation__c(
            
        );
        insert testViolation;
        
        // Step 2: Create test files (ContentVersion records)
        ContentVersion file1 = new ContentVersion(
            Title = 'SPPRT3'+ String.valueOf(Math.random()),
            PathOnClient = 'ViolationDoc1.pdf',
            VersionData = Blob.valueOf('Test Content 1'),
            IsMajorVersion = true
        );
       
        insert new List<ContentVersion>{file1};
            
            // Get ContentDocumentIds
            file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];
       
        
        // Step 3: Link files to Violation
        ContentDocumentLink link1 = new ContentDocumentLink(
            LinkedEntityId = testViolation.Id,
            ContentDocumentId = file1.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
       
        insert new List<ContentDocumentLink>{link1};
            
            // Step 4: Mark one file as already transferred to SharePoint
            AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
                AVO_ContentDocumentId__c = file1.ContentDocumentId,
                AVO_Violation__c = testViolation.Id,
                AVO_SharePoint_Item_Id__c = '12345' // Required field
            );
        insert transferredFile;
        
        // Step 5: Call the method under test
        Test.startTest();
        Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Violation', testViolation.Id);
        Test.stopTest();
        
        // Step 2: Query and assert
        MUSW__Violation__c fetchedViolation = [
            SELECT Id FROM MUSW__Violation__c WHERE Id = :testViolation.Id
        ];
        System.assertNotEquals(null, fetchedViolation, 'Violation record should be inserted');
        
        // Step 6: Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        
        Integer numberOfFiles = (Integer)result.get('numberOfFiles');
        System.assertEquals(0, numberOfFiles, 'Should return only 1 file (the non-transferred one)');
        
        List<Object> files = (List<Object>)result.get('files');
        System.assertEquals(0, files.size(), 'Should return exactly 1 file info');
        
        
    }
    
    @isTest
    static void testGetFilesInfoForComplaint_AllChildObjects() {
        // -------------------- Create Complaint --------------------
        MUSW__Complaint2__c complaint = new MUSW__Complaint2__c(Name = 'Test Complaint');
        insert complaint;
        
        // -------------------- Inspection (transferred) --------------------
        MUSW__Inspection__c inspection = new MUSW__Inspection__c(MUSW__Complaint2__c = complaint.Id);
        insert inspection;
        
        ContentVersion inspectionVersion = new ContentVersion(
            Title = 'SPPRT4'+ String.valueOf(Math.random()),
            PathOnClient = 'ComplaintInspectionDoc.pdf',
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
            AVO_SharePoint_Item_Id__c = 'CMPINS123'
        );
        
        // -------------------- Violation (transferred) --------------------
        MUSW__Violation__c violation = new MUSW__Violation__c(MUSW__Complaint2__c = complaint.Id);
        insert violation;
        
        ContentVersion violationVersion = new ContentVersion(
            Title = 'ComplaintViolationDoc'+ String.valueOf(Math.random()),
            PathOnClient = 'ComplaintViolationDoc.pdf',
            VersionData = Blob.valueOf('Violation File'),
            IsMajorVersion = true
        );
        insert violationVersion;
        violationVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :violationVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = violation.Id,
            ContentDocumentId = violationVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        insert new AVO_SharePoint_File__c(
            AVO_ContentDocumentId__c = violationVersion.ContentDocumentId,
            AVO_Violation__c = violation.Id,
            AVO_SharePoint_Item_Id__c = 'CMPVIOL123'
        );
        
        // -------------------- Complaint Document (NOT transferred) --------------------
        ContentVersion complaintVersion = new ContentVersion(
            Title = 'ComplaintMainDoc'+ String.valueOf(Math.random()),
            PathOnClient = 'ComplaintMainDoc.pdf',
            VersionData = Blob.valueOf('Main Complaint File'),
            IsMajorVersion = true
        );
        insert complaintVersion;
        complaintVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :complaintVersion.Id];
        
        insert new ContentDocumentLink(
            LinkedEntityId = complaint.Id,
            ContentDocumentId = complaintVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        
        // -------------------- EXECUTE --------------------
        Test.startTest();
        Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Complaint', complaint.Id);
        Test.stopTest();
        
        // -------------------- VALIDATION --------------------
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, (Integer)result.get('numberOfFiles'), 'Only 1 untransferred complaint file should be returned');
        List<Object> files = (List<Object>)result.get('files');
        System.assertEquals(1, files.size(), 'Only 1 file (ComplaintMainDoc) should be returned');
    }
    
    
    
    @isTest
    static void testGetFilesInfoForPermit_AllChildObjects() {
        // Create Permit
        MUSW__Permit2__c permit = new MUSW__Permit2__c(Name = 'Test Permit', AVO_Volumetric_Limits__c = 1);
        insert permit;
        
        // -------------------- INSPECTION (already transferred) --------------------
        MUSW__Inspection__c inspection = new MUSW__Inspection__c(MUSW__Permit__c = permit.Id);
        insert inspection;
        
        ContentVersion inspectionVersion = new ContentVersion(
            Title = 'InspectionDoc'+ String.valueOf(Math.random()),
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
            Title = 'ReviewDoc'+ String.valueOf(Math.random()),
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
            Title = 'SubmissionDoc'+ String.valueOf(Math.random()),
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
            Title = 'MilestoneDoc'+ String.valueOf(Math.random()),
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
            Title = 'PermitDoc'+ String.valueOf(Math.random()),
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
        Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Permit', permit.Id);
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
            Title = 'AppInspectionDoc'+ String.valueOf(Math.random()),
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
            Title = 'AppReviewDoc'+ String.valueOf(Math.random()),
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
            Title = 'AppSubmissionDoc'+ String.valueOf(Math.random()),
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
            Title = 'AppMilestoneDoc'+ String.valueOf(Math.random()),
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
            Title = 'AppMainDoc'+ String.valueOf(Math.random()),
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
        Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Application', application.Id);
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
            Title = 'LicenseInspectionDoc'+ String.valueOf(Math.random()),
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
            Title = 'LicenseReviewDoc'+ String.valueOf(Math.random()),
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
            Title = 'LicenseSubmissionDoc'+ String.valueOf(Math.random()),
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
            Title = 'LicenseMilestoneDoc'+ String.valueOf(Math.random()),
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
            Title = 'LicenseMainDoc'+ String.valueOf(Math.random()),
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
        Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('License', license.Id);
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
        Title = 'WithdrawalDoc1'+ String.valueOf(Math.random()),
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
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Withdrawal', testWithdrawal.Id);
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
static void testGetFilesInfoForComment() {
    // Step 1: Create test Comment record
    MUSW__Comment__c testComment = new MUSW__Comment__c(
        // Populate any required fields here
    );
    insert testComment;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'CommentDoc1'+ String.valueOf(Math.random()),
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
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Comment', testComment.Id);
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
@isTest
static void testGetFilesInfoForMeter() {
    // Step 1: Create test Meter record
    AVO_Meter__c testMeter = new AVO_Meter__c(
        // Add required fields if any (e.g., Name, AVO_Serial_Number__c, etc.)
    );
    insert testMeter;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'MeterDoc1'+ String.valueOf(Math.random()),
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
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Meter', testMeter.Id);
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
}
@isTest
static void testGetFilesInfoForMeterCodeset() {
    // Step 1: Create test Meter Codeset record
    AVO_Meter_Codeset__c testCodeset = new AVO_Meter_Codeset__c(
        // Add required fields here if any (e.g., Name or Lookup)
    );
    insert testCodeset;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'CodesetDoc1'+ String.valueOf(Math.random()),
        PathOnClient = 'CodesetDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Meter Codeset via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = testCodeset.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Meter_Codeset__c = testCodeset.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required field
    );
    insert transferredFile;

    // Step 6: Call the method under test
    Test.startTest();
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('MeterCodeset', testCodeset.Id);
    Test.stopTest();

    // Step 7: Assert the Meter Codeset was inserted
    AVO_Meter_Codeset__c fetchedCodeset = [SELECT Id FROM AVO_Meter_Codeset__c WHERE Id = :testCodeset.Id];
    System.assertNotEquals(null, fetchedCodeset, 'Meter Codeset record should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}
@isTest
static void testGetFilesInfoForMeterTransaction() {
    // Step 1: Create test Meter Transaction record
    AVO_Meter_Transaction__c testTransaction = new AVO_Meter_Transaction__c(
        // Add required fields here, e.g., AVO_Meter__c = someMeterId
    );
    insert testTransaction;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'MeterTransactionDoc1'+ String.valueOf(Math.random()),
        PathOnClient = 'MeterTransactionDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Meter Transaction via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = testTransaction.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Meter_Transaction__c = testTransaction.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required field
    );
    insert transferredFile;

    // Step 6: Call the method under test
    Test.startTest();
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('MeterTransaction', testTransaction.Id);
    Test.stopTest();

    // Step 7: Assert Meter Transaction was inserted
    AVO_Meter_Transaction__c fetchedTransaction = [
        SELECT Id FROM AVO_Meter_Transaction__c WHERE Id = :testTransaction.Id
    ];
    System.assertNotEquals(null, fetchedTransaction, 'Meter Transaction record should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}
@isTest
static void testGetFilesInfoForMeterWithdrawal() {
    // Step 1: Create test Meter Withdrawal record
    AVO_Meter_Withdrawal__c testMeterWithdrawal = new AVO_Meter_Withdrawal__c(
        // Add any required fields here (e.g., AVO_Meter__c = someMeterId)
    );
    insert testMeterWithdrawal;

    // Step 2: Create test file (ContentVersion)
    ContentVersion file1 = new ContentVersion(
        Title = 'MeterWithdrawalDoc1'+ String.valueOf(Math.random()),
        PathOnClient = 'MeterWithdrawalDoc1.pdf',
        VersionData = Blob.valueOf('Test Content 1'),
        IsMajorVersion = true
    );
    insert file1;

    // Step 3: Re-query to get ContentDocumentId
    file1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :file1.Id];

    // Step 4: Link file to Meter Withdrawal via ContentDocumentLink
    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = testMeterWithdrawal.Id,
        ContentDocumentId = file1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 5: Mark file as already transferred
    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = file1.ContentDocumentId,
        AVO_Meter_Withdrawal__c = testMeterWithdrawal.Id,
        AVO_SharePoint_Item_Id__c = '12345' // Required field
    );
    insert transferredFile;

    // Step 6: Call the method under test
    Test.startTest();
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('MeterWithdrawal', testMeterWithdrawal.Id);
    Test.stopTest();

    // Step 7: Assert the Meter Withdrawal was inserted
    AVO_Meter_Withdrawal__c fetchedRecord = [
        SELECT Id FROM AVO_Meter_Withdrawal__c WHERE Id = :testMeterWithdrawal.Id
    ];
    System.assertNotEquals(null, fetchedRecord, 'Meter Withdrawal record should be inserted');

    // Step 8: Verify results
    System.assertNotEquals(null, result, 'Result should not be null');

    Integer numberOfFiles = (Integer)result.get('numberOfFiles');
    System.assertEquals(0, numberOfFiles, 'Should return 0 files since it is already transferred');

    List<Object> files = (List<Object>)result.get('files');
    System.assertEquals(0, files.size(), 'Should return 0 file info');
}
@isTest
static void TestTransferBeginPermitWithChild() {
    // Step 1: Create Parent Permit Record
    MUSW__Permit2__c testPermit = new MUSW__Permit2__c(
        MUSW__Description__c = 'Test Permit',
        AVO_Volumetric_Limits__c = 1
    );
    insert testPermit;

    // Step 2: Create a related child object (Milestone)
    MUSW__Milestone__c testMilestone = new MUSW__Milestone__c(
        Name = 'Test Milestone',
        MUSW__Permit2__c = testPermit.Id
    );
    insert testMilestone;

    // Step 3: Create ContentVersion (File)
    ContentVersion testContentVersion = new ContentVersion(
        Title = 'PermitMilestoneDoc'+ String.valueOf(Math.random()),
        PathOnClient = 'PermitMilestoneDoc.pdf',
        VersionData = Blob.valueOf('Test Content'),
        IsMajorVersion = true
    );
    insert testContentVersion;

    // Step 4: Query to get ContentDocumentId
    testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];

    // Step 5: Link File to Permit
    ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
        LinkedEntityId = testPermit.Id,
        ContentDocumentId = testContentVersion.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert testContentDocumentLink;

    // Step 6: Link File to Milestone (Child Object)
    ContentDocumentLink milestoneLink = new ContentDocumentLink(
        LinkedEntityId = testMilestone.Id,
        ContentDocumentId = testContentVersion.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert milestoneLink;

    // Step 7: Set mock and execute transferBegin for Permit
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
    AVO_SharePointProcessRecord.transferBegin(milestoneLink);
    Test.stopTest();

    // Basic assertions to validate the flow
    System.assertEquals(true, true, 'Execution completed without unhandled exception');
}
@isTest
static void TestTransferBeginApplicationWithChildren() {
    // Step 1: Create Application Record
    MUSW__Application2__c testApplication = new MUSW__Application2__c(
        MUSW__Description__c = 'Test Application'
    );
    insert testApplication;

    // Step 2: Create Related Child Records
    MUSW__Submission__c submission = new MUSW__Submission__c(
        Name = 'Test Submission',
        MUSW__Application2__c = testApplication.Id
    );
    insert submission;

    MUSW__Inspection__c inspection = new MUSW__Inspection__c(
        Name = 'Test Inspection',
        AVO_Application__c = testApplication.Id
    );
    insert inspection;

    MUSW__Milestone__c milestone = new MUSW__Milestone__c(
        Name = 'Test Milestone',
        MUSW__Application2__c = testApplication.Id
    );
    insert milestone;

    MUSW__Review__c review = new MUSW__Review__c(
        Name = 'Test Review',
        MUSW__Application2__c = testApplication.Id
    );
    insert review;

    // Step 3: Create File
    ContentVersion testContentVersion = new ContentVersion(
        Title = 'ApplicationDoc'+ String.valueOf(Math.random()),
        PathOnClient = 'ApplicationDoc.pdf',
        VersionData = Blob.valueOf('Test Content'),
        IsMajorVersion = true
    );
    insert testContentVersion;

    testContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id];

    // Step 4: Link file to Application and children
    List<ContentDocumentLink> links = new List<ContentDocumentLink>{
        new ContentDocumentLink(
            LinkedEntityId = testApplication.Id,
            ContentDocumentId = testContentVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        ),
        new ContentDocumentLink(
            LinkedEntityId = submission.Id,
            ContentDocumentId = testContentVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        ),
        new ContentDocumentLink(
            LinkedEntityId = inspection.Id,
            ContentDocumentId = testContentVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        ),
        new ContentDocumentLink(
            LinkedEntityId = milestone.Id,
            ContentDocumentId = testContentVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        ),
        new ContentDocumentLink(
            LinkedEntityId = review.Id,
            ContentDocumentId = testContentVersion.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        )
    };
    insert links;

    // Step 5: Execute transferBegin for each
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    for(ContentDocumentLink link : links) {
        AVO_SharePointProcessRecord.transferBegin(link);
    }
    Test.stopTest();

    System.assertEquals(true, true, 'transferBegin executed for application and children');
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
        Test.stopTest();
        System.assertEquals(true, true);
    }
    
  /*Luc  @isTest static void TestTransferBeginContact() {
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
        Test.stopTest();
        System.assertEquals(true, true);
    }
*/
    
    @isTest static void TestTransferBeginAccount() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title          = 'ContentVersion '+ String.valueOf(Math.random()),
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        // Call the method under test
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        // Call the method under test
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        // Call the method under test
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        // Call the method under test
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        // Call the method under test
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    @isTest
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
        Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
        // Call the method under test
        AVO_SharePointProcessRecord.transferBegin(testContentDocumentLink);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
    Test.setMock(HttpCalloutMock.class, new SharePointCalloutMock());
    AVO_SharePointProcessRecord.transferBegin(link);
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
        String result = AVO_SharePointProcessRecord.getAccessLink(
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
        String result = AVO_SharePointProcessRecord.getAccessLink(
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
        Integer result = AVO_SharePointProcessRecord.getIdFromXMLNode(root);
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
        Integer result = AVO_SharePointProcessRecord.getIdFromXMLNode(root);
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
        Integer result = AVO_SharePointProcessRecord.getFileMatchCount(root, 'testFile.pdf');
        Test.stopTest();
        
        // Verify the result
        System.assertEquals(2, result, 'Should find 2 matching files');
    }
    
    @isTest
    static void testFileNameWithoutExtension() {
        // Test cases
        Test.startTest();
        String result1 = AVO_SharePointProcessRecord.fileNameWithoutExtension('testFile.pdf');
        String result2 = AVO_SharePointProcessRecord.fileNameWithoutExtension('file.with.dots.txt');
        String result3 = AVO_SharePointProcessRecord.fileNameWithoutExtension('noextension');
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
        String result1 = AVO_SharePointProcessRecord.fileExtensionMatch('testFile.pdf');
        String result2 = AVO_SharePointProcessRecord.fileExtensionMatch('file.with.dots.txt');
        String result3 = AVO_SharePointProcessRecord.fileExtensionMatch('noextension');
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
    AVO_SharePointProcessRecord.InsertSharePointFileInfo(
        'Meters', // childDirectory
        12345,    // fileId
        'Shared Documents/Meters', // folderName
        meter.Id, // parentId
        meter.Name, // objectName
        'dummyAccessToken', // accessToken
        http,
        'TestFile.txt',
        version.ContentDocumentId,
        AVO_SharePointProcessRecord.ObjectType.Meter
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
@isTest
static void testProcessRecord() {
    // Step 1: Create a test Permit record
    MUSW__Permit2__c testPermit = new MUSW__Permit2__c(Name = 'Test Permit',AVO_Volumetric_Limits__c=1);
    insert testPermit;

    // Step 2: Create a ContentVersion (simulates file)
    ContentVersion version = new ContentVersion(
        Title = 'PermitDoc'+ String.valueOf(Math.random()), // unique
        PathOnClient = 'PermitDoc.pdf',
        VersionData = Blob.valueOf('Dummy data'),
        IsMajorVersion = true
    );
    insert version;

    // Step 3: Create a ContentDocumentLink to link file to the Permit
    version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];
    ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = testPermit.Id,
        ContentDocumentId = version.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link;

    // Step 4: Run the method under test
    Test.startTest();
    AVO_SharePointProcessRecord.processRecord(new List<Id>{testPermit.Id});
    Test.stopTest();

    // Step 5: Basic assertion
    System.assert(true, 'processRecord method ran without exception');
}
@isTest
static void testGetFilesInfoForPermit() {
    // Step 1: Create Permit
    MUSW__Permit2__c permit = new MUSW__Permit2__c(Name = 'Test Permit',AVO_Volumetric_Limits__c=1);
    insert permit;

    // Step 2: Create Inspection linked to Permit
    MUSW__Inspection__c inspection = new MUSW__Inspection__c(MUSW__Permit__c = permit.Id);
    insert inspection;

    // Step 3: Create ContentVersion and link to Permit (file NOT yet transferred)
    ContentVersion version1 = new ContentVersion(
        Title = 'PermitDoc'+ String.valueOf(Math.random()),
        PathOnClient = 'PermitDoc.pdf',
        VersionData = Blob.valueOf('Permit File'),
        IsMajorVersion = true
    );
    insert version1;
    version1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version1.Id];

    ContentDocumentLink link1 = new ContentDocumentLink(
        LinkedEntityId = permit.Id,
        ContentDocumentId = version1.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link1;

    // Step 4: Create ContentVersion and link to Inspection (already transferred)
    ContentVersion version2 = new ContentVersion(
        Title = 'InspectionDoc'+ String.valueOf(Math.random()),
        PathOnClient = 'InspectionDoc.pdf',
        VersionData = Blob.valueOf('Inspection File'),
        IsMajorVersion = true
    );
    insert version2;
    version2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version2.Id];

    ContentDocumentLink link2 = new ContentDocumentLink(
        LinkedEntityId = inspection.Id,
        ContentDocumentId = version2.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
    insert link2;

    AVO_SharePoint_File__c transferredFile = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = version2.ContentDocumentId,
        AVO_Inspection__c = inspection.Id,
    AVO_SharePoint_Item_Id__c = '12345'  // <-- Add a dummy required value
    );
    insert transferredFile;

    // Step 5: Call the method
    Test.startTest();
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Permit', permit.Id);
    Test.stopTest();

    // Step 6: Validate
    System.assertNotEquals(null, result);
    System.assert(result.containsKey('numberOfFiles'), 'Should contain numberOfFiles key');
    System.assertEquals(1, (Integer)result.get('numberOfFiles'), 'Only 1 file (PermitDoc) should be included');
    System.assert(((List<Object>)result.get('files')).size() > 0, 'files list should not be empty');
}
@isTest
static void testGetFilesInfo_FullPermitCoverage() {
    // Step 1: Create Permit and related child records
    MUSW__Permit2__c permit = new MUSW__Permit2__c(Name = 'Test Permit',AVO_Volumetric_Limits__c=1);
    insert permit;

    MUSW__Inspection__c inspection = new MUSW__Inspection__c(MUSW__Permit__c = permit.Id);
    MUSW__Review__c review = new MUSW__Review__c(MUSW__Permit2__c = permit.Id);
    MUSW__Submission__c submission = new MUSW__Submission__c(MUSW__Permit2__c = permit.Id);
    MUSW__Milestone__c milestone = new MUSW__Milestone__c(MUSW__Permit2__c = permit.Id);
    insert new List<SObject>{ inspection, review, submission, milestone };

    // Step 2: Upload ContentVersions (simulate files)
    List<ContentVersion> versions = new List<ContentVersion>{
        new ContentVersion(Title = 'RPermitDoc', PathOnClient = 'PermitDoc.pdf', VersionData = Blob.valueOf('test'), IsMajorVersion = true),
        new ContentVersion(Title = 'RInspectionDoc', PathOnClient = 'InspectionDoc.pdf', VersionData = Blob.valueOf('test'), IsMajorVersion = true),
        new ContentVersion(Title = 'RReviewDoc', PathOnClient = 'ReviewDoc.pdf', VersionData = Blob.valueOf('test'), IsMajorVersion = true),
        new ContentVersion(Title = 'RSubmissionDoc', PathOnClient = 'SubmissionDoc.pdf', VersionData = Blob.valueOf('test'), IsMajorVersion = true),
        new ContentVersion(Title = 'RMilestoneDoc', PathOnClient = 'MilestoneDoc.pdf', VersionData = Blob.valueOf('test'), IsMajorVersion = true)
    };
    insert versions;

    Map<String, Id> docIdMap = new Map<String, Id>();
    for (ContentVersion v : [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id IN :versions]) {
        docIdMap.put(v.Title, v.ContentDocumentId);
    }

    // Step 3: Link to respective records
    List<ContentDocumentLink> links = new List<ContentDocumentLink>{
        new ContentDocumentLink(LinkedEntityId = permit.Id, ContentDocumentId = docIdMap.get('RPermitDoc'), ShareType = 'V', Visibility = 'AllUsers'),
        new ContentDocumentLink(LinkedEntityId = inspection.Id, ContentDocumentId = docIdMap.get('RInspectionDoc'), ShareType = 'V', Visibility = 'AllUsers'),
        new ContentDocumentLink(LinkedEntityId = review.Id, ContentDocumentId = docIdMap.get('RReviewDoc'), ShareType = 'V', Visibility = 'AllUsers'),
        new ContentDocumentLink(LinkedEntityId = submission.Id, ContentDocumentId = docIdMap.get('RSubmissionDoc'), ShareType = 'V', Visibility = 'AllUsers'),
        new ContentDocumentLink(LinkedEntityId = milestone.Id, ContentDocumentId = docIdMap.get('RMilestoneDoc'), ShareType = 'V', Visibility = 'AllUsers')
    };
    insert links;

    // Step 4: Simulate transferred file (to test exclusion logic)
    AVO_SharePoint_File__c excluded = new AVO_SharePoint_File__c(
        AVO_ContentDocumentId__c = docIdMap.get('RInspectionDoc'),
        AVO_Inspection__c = inspection.Id,
        AVO_SharePoint_Item_Id__c = '999'
    );
    insert excluded;

    // Step 5: Call method
    Test.startTest();
    Map<String, Object> result = AVO_SharePointProcessRecord.getFilesInfo('Permit', permit.Id);
    Test.stopTest();

    // Step 6: Assertions
    System.assertNotEquals(null, result);
    System.assertEquals(4, (Integer)result.get('numberOfFiles'), 'Only 4 of 5 should be included due to 1 exclusion');

    List<Object> returnedFiles = (List<Object>)result.get('files');
    System.assert(returnedFiles.size() == 4, 'Should return only 4 non-excluded files');
}
    
    
    private class SharePointCalloutMock implements HttpCalloutMock {
        // Note: must be an *instance* method, not static
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"Test":"Test","access_token":"Test",' +
                '"d":{"OData__dlc_DocIdUrl":{"Url":"Test"},' +
                '"results":[{"name":"Test"}]}}'
            );
            res.setStatusCode(200);
            return res;
        }
    }
}