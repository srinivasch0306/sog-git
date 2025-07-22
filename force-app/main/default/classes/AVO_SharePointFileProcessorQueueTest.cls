@isTest(isParallel=false)
private class AVO_SharePointFileProcessorQueueTest {

    // Static initializer inserts required setting before any test runs
    static {
        insert new AVO_Rest_API_Settings__c(
            Name = 'Default',
            AVO_Site_Url__c = 'https://example.sharepoint.com/sites/test',
            AVO_Base_Directory__c = '/sites/test/Shared Documents',
            AVO_Client_ID__c = 'test_client_id',
            AVO_Client_Secret__c = 'test_client_secret',
            AVO_Grant_Type__c = 'client_credentials',
            AVO_Resource__c = 'https://example.sharepoint.com',
            AVO_Salesforce_URL__c = 'https://example.sharepoint.com',
            AVO_Token_End_Point__c = 'https://login.microsoftonline.com/test/oauth2/token'
        );
    }

    // Dummy callout mock to prevent real HTTP callout errors
    private class DummyCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            // Simulate token or file response
            if (req.getEndpoint().contains('oauth2/token')) {
                res.setBody('{"access_token":"dummy_token"}');
            } else if (req.getEndpoint().contains('/Files')) {
                res.setBody('{"d":{"results":[]}}'); // simulate empty folder
            } else {
                res.setBody('{}');
            }

            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testQueueableExecution() {
        // Prevent infinite queuing
        AVO_SharePointFileProcessor.isTestMode = true;

        // Register callout mock
        Test.setMock(HttpCalloutMock.class, new DummyCalloutMock());

        Test.startTest();
        System.enqueueJob(new AVO_SharePointFileProcessorQueue(0, 0));
        Test.stopTest();

        AVO_SharePointFileProcessor.isTestMode = false;

        // Assert job was queued
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        System.assert(!jobs.isEmpty(), 'Expected at least one queueable job to have run.');
    }
}