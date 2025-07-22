@isTest(isParallel=false)
public class AVO_SharePointFileProcessorTest {
    @TestSetup
    static void setupTestData() {
        // Create custom setting data
       /* AVO_Rest_API_Settings__c settings = new AVO_Rest_API_Settings__c(
            Name = 'Default',
            AVO_Site_Url__c = 'https://example.sharepoint.com/sites/test',
            AVO_Base_Directory__c = '/sites/test/Shared Documents',
            AVO_Client_ID__c = 'test_client_id',
            AVO_Client_Secret__c = 'test_client_secret',
            AVO_Grant_Type__c = 'client_credentials',
            AVO_Resource__c = 'https://example.sharepoint.com',
            AVO_Salesforce_URL__c= 'https://example.sharepoint.com',
            AVO_Token_End_Point__c = 'https://login.microsoftonline.com/test/oauth2/token'
        );
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
        
        
        // Create test permit records
        // Create test permit records
       MUSW__Permit2__c permit1 = new MUSW__Permit2__c(
    Name = 'APP123',
    AVO_Volumetric_Limits__c = 100 // any non-zero positive value
);

       MUSW__Permit2__c permit2 = new MUSW__Permit2__c(
    Name = 'APP123',
    AVO_Volumetric_Limits__c = 100 
);
        insert new List<MUSW__Permit2__c>{permit1, permit2};
            
            AVO_SharePoint_File__c testFile1 = new AVO_SharePoint_File__c(
                Name = 'TestFile1.jpg',
                AVO_Permit__c = permit1.Id,
                
                AVO_SharePoint_URL__c = 'https://sharepoint.com/testfile1.jpg',
                AVO_SharePoint_URL_Text__c = 'https://sharepoint.com/testfile1.jpg',
                AVO_SharePoint_External_Link__c = 'https://sharepoint.com/testfile1.jpg',
                AVO_SharePoint_Item_Id__c = '12345'
            );
        insert testFile1;
        
        AVO_SharePoint_File__c testFile2 = new AVO_SharePoint_File__c(
            Name = 'TestFile2.jpg',
            AVO_Permit__c = permit1.Id,
            
            AVO_SharePoint_URL__c = 'https://sharepoint.com/testfile2.jpg',
            AVO_SharePoint_URL_Text__c = 'https://sharepoint.com/testfile2.jpg',
            AVO_SharePoint_External_Link__c = 'https://sharepoint.com/testfile2.jpg',
            AVO_SharePoint_Item_Id__c = '12345'
        );
        insert testFile2;
        
    }
    
    @isTest
    static void testGetAppIdFromFileName() {
        // Test various filename patterns
        System.assertEquals('APP123', AVO_SharePointFileProcessor.getAppIdFromFileName('County_APP123.jpg'));
        System.assertEquals('APP123', AVO_SharePointFileProcessor.getAppIdFromFileName('County_APP123_G1.jpg'));
        System.assertEquals('APP123', AVO_SharePointFileProcessor.getAppIdFromFileName('County_APP123_G2.jpg'));
        System.assertEquals('PER456', AVO_SharePointFileProcessor.getAppIdFromFileName('County_PER456.pdf'));
        System.assertEquals(null, AVO_SharePointFileProcessor.getAppIdFromFileName('InvalidFilename.jpg'));
        System.assertEquals(null, AVO_SharePointFileProcessor.getAppIdFromFileName(null));
        System.assertEquals(null, AVO_SharePointFileProcessor.getAppIdFromFileName('NoUnderscore.jpg'));
    }
    
    
    @isTest
    static void testProcessSingleFile() {
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new SharePointMock());
        
        // Get initial count of files
        Integer initialFileCount = [SELECT COUNT() FROM AVO_SharePoint_File__c];
        
        Test.startTest();
        AVO_SharePointFileProcessor.testProcessSingleFile();
        Test.stopTest();
        
        // Verify results
        List<AVO_SharePoint_File_Log__c> logs = [SELECT Id, AVO_File_Name__c, AVO_Status__c FROM AVO_SharePoint_File_Log__c];
        System.assertEquals(1, logs.size(), 'Expected one log record');
        System.assertEquals('Link Generated', logs[0].AVO_Status__c, 'Expected successful processing');
        
        // Verify exactly one new file was created
        Integer newFileCount = [SELECT COUNT() FROM AVO_SharePoint_File__c] - initialFileCount;
        System.assertEquals(1, newFileCount, 'Expected one new file record');
    }
    
    @isTest
    static void testQueueableExecution() {
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new SharePointMock());
        
        Test.startTest();
        // Instantiate the class
        AVO_SharePointFileProcessor processor = new AVO_SharePointFileProcessor();

        // Call the  method with test indexes
        processor.run(0, 0);
        Test.stopTest();
        
        // Verify the queueable job was executed
        // Since we're mocking callouts, we can't verify the full chain of execution
        // but we can verify that the process was started
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(1, jobs.size(), 'Expected one queueable job');
    }
    @isTest
    static void testGetAccessLink() {
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new SharePointAccessLinkMock());
        
        // Test data
        String folderName = '/sites/test/Shared%20Documents/Application%20Maps';
        String fileName = 'County_APP123_G1.jpg';
        String accessToken = 'test_access_token';
        Http http = new Http();
        
        Test.startTest();
        AVO_SharePointFileProcessor.SharePointFileInfo result = 
            AVO_SharePointFileProcessor.getAccessLink(folderName, fileName, accessToken, http, false);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('https://example.sharepoint.com/sites/test/Shared%20Documents/Application%20Maps/County_APP123_G1.jpg', 
                            result.url, 'Incorrect URL returned');
        System.assertEquals('12345', result.itemId, 'Incorrect file ID returned');
    }
    private class SharePointAccessLinkMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('ShareLink')) {
                // Mock response for getAccessLink
                res.setBody('{' +
                            '"d": {' +
                            '  "ShareLink": {' +
                            '    "sharingLinkInfo": {' +
                            '      "Url": "https://example.sharepoint.com/sites/test/Shared%20Documents/Application%20Maps/County_APP123_G1.jpg",' +
                            '      "IsActive": true,' +
                            '      "LastModified": "2023-01-01T00:00:00Z"' +
                            '    }' +
                            '  }' +
                            '}' +
                            '}');
            } 
            else if (req.getEndpoint().contains('ListItemAllFields') && !req.getEndpoint().contains('ShareLink')) {
                // Mock response for getFileItemId
                res.setBody('{"d":{"Id":"12345"}}');
            }
            
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void testFileProcessing() {
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new SharePointMock());
        
        // Create test instance
        AVO_SharePointFileProcessor processor = new AVO_SharePointFileProcessor();
        
        // Test data
        Map<String, Object> testFile = new Map<String, Object>{
            'Name' => 'County_APP123_G1.jpg',
                'ServerRelativeUrl' => '/sites/test/Shared Documents/Application Staging Maps/County_APP123_G1.jpg',
                'TimeCreated' => '2023-01-01T00:00:00Z',
                'TimeLastModified' => '2023-01-01T00:00:00Z'
                };
                    
                    Test.startTest();
        processor.processFile(testFile, 'Application Staging Maps');
        processor.finalizeDML();
        Test.stopTest();
        
        // Debugging - query all logs with their error messages
        List<AVO_SharePoint_File_Log__c> allLogs = [SELECT Id, AVO_File_Name__c, AVO_Status__c, AVO_Comment__c 
                                                    FROM AVO_SharePoint_File_Log__c];
        System.debug('All Logs: ' + JSON.serializePretty(allLogs));
        
        // Verify results - get the specific log for our test file
        AVO_SharePoint_File_Log__c fileLog = [SELECT AVO_Status__c, AVO_Comment__c 
                                              FROM AVO_SharePoint_File_Log__c 
                                              WHERE AVO_File_Name__c = 'County_APP123_G1.jpg'
                                              LIMIT 1];
        
        System.debug('File Log Status: ' + fileLog.AVO_Status__c);
        System.debug('File Log Comment: ' + fileLog.AVO_Comment__c);
        
      
    }
    
    @isTest
    static void testErrorHandling() {
        // Mock HTTP callouts to simulate errors
        Test.setMock(HttpCalloutMock.class, new SharePointErrorMock());
        
        // Create test instance
        AVO_SharePointFileProcessor processor = new AVO_SharePointFileProcessor();
        
        // Test data with invalid filename
        Map<String, Object> testFile = new Map<String, Object>{
            'Name' => 'InvalidFilename.jpg',
                'ServerRelativeUrl' => '/sites/test/Shared Documents/Application Staging Maps/InvalidFilename.jpg',
                'TimeCreated' => '2023-01-01T00:00:00Z',
                'TimeLastModified' => '2023-01-01T00:00:00Z'
                };
                    
                    Test.startTest();
        processor.processFile(testFile, 'Application Staging Maps');
        processor.finalizeDML();
        Test.stopTest();
        
        // Verify error was logged
        List<AVO_SharePoint_File_Log__c> logs = [SELECT Id, AVO_File_Name__c, AVO_Status__c FROM AVO_SharePoint_File_Log__c];
        System.assertEquals(1, logs.size(), 'Expected one log record');
        System.assertEquals('Error', logs[0].AVO_Status__c, 'Expected error status');
    }
    
    @isTest
    static void testGetFilesFromFolder() {
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new SharePointMock());
        
        Test.startTest();
        List<Map<String, Object>> files = AVO_SharePointFileProcessor.getFilesFromFolder('test_token', 'Application Staging Maps');
        Test.stopTest();
        
        System.assertEquals(1, files.size(), 'Expected one file in mock response');
        System.assertEquals('County_APP123_G1.jpg', files[0].get('Name'), 'Expected specific filename');
    }
    
    @isTest
    static void testMoveFileRaw() {
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new SharePointMock());
        
        Test.startTest();
        String result = AVO_SharePointFileProcessor.moveFileRaw(
            '/sites/test/Shared Documents/Application Staging Maps/County_APP123_G1.jpg',
            '/sites/test/Shared Documents/Application Maps/County_APP123_G1.jpg',
            true,
            'test_token'
        );
        Test.stopTest();
        
        System.assert(result.contains('successfully'), 'Expected successful move operation');
    }
    
    @isTest
    static void testGetAccessToken() {
        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new TokenMock());
        
        Test.startTest();
        String token = AVO_SharePointFileProcessor.getAccessToken();
        Test.stopTest();
        
        System.assertEquals('test_access_token', token, 'Expected mock access token');
    }
    
    // Mock classes for HTTP callouts
    private class TokenMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"test_access_token","token_type":"Bearer","expires_in":3600}');
            res.setStatusCode(200);
            return res;
        }
    }
    private class SharePointMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('_api/web/GetFolderByServerRelativeUrl')) {
                res.setBody('{"d":{"results":[{"Name":"County_APP123_G1.jpg","ServerRelativeUrl":"/sites/test/Shared Documents/Application Staging Maps/County_APP123_G1.jpg","TimeCreated":"2023-01-01T00:00:00Z","TimeLastModified":"2023-01-01T00:00:00Z"}]}}');
            } 
            else if (req.getEndpoint().contains('moveto')) {
                // Successful move response
                res.setBody('{"d": {}}');
            } 
            else if (req.getEndpoint().contains('ShareLink')) {
                // Complete sharing link response
                res.setBody('{"d":{"ShareLink":{"sharingLinkInfo":{' +
                            '"Url":"https://example.sharepoint.com/sites/test/Shared%20Documents/Application%20Maps/County_APP123_G1.jpg",' +
                            '"IsActive":true,' +
                            '"LastModified":"2023-01-01T00:00:00Z"' +
                            '}}}}');
            } 
            else if (req.getEndpoint().contains('ListItemAllFields') && !req.getEndpoint().contains('ShareLink')) {
                // File metadata response
                res.setBody('{"d":{"Id":"12345","GUID":"abc123"}}');
            } 
            else if (req.getEndpoint().contains('oauth2/token')) {
                // Authentication response
                res.setBody('{"access_token":"test_access_token","token_type":"Bearer","expires_in":3600}');
            }
            
            res.setStatusCode(200);
            return res;
        }
    }  
    
    private class SharePointErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"error":{"message":"Invalid request"}}');
            return res;
        }
    }
    @isTest
static void testSendNotificationEmail() {
    // Step 1: Create a mock User Role
    UserRole role = new UserRole(Name = 'GIS Specialist');
    insert role;

    // Step 2: Create a user with this role (required for email)
    User gisUser = new User(
        FirstName = 'Test',
        LastName = 'GISUser',
        Email = 'gis.specialist@example.com',
        Username = 'gisuser@example.com.test',
        Alias = 'gisu',
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
        LanguageLocaleKey = 'en_US',
        UserRoleId = role.Id
    );
    insert gisUser;

    // Step 3: Prepare mock error messages
    List<String> errors = new List<String>{
        'Failed to move County_APP123.jpg',
        'Permit not found for APP123'
    };

    // Step 4: Call the method
    Test.startTest();
    AVO_SharePointFileProcessor.sendNotificationEmail(errors);
    Test.stopTest();

    // Step 5: Verify email was added to email queue (you can't read it directly, but check for no exception)
    System.debug('sendNotificationEmail executed with errors: ' + errors);
}

}