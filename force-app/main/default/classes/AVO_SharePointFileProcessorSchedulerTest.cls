@isTest(isParallel=false)
private class AVO_SharePointFileProcessorSchedulerTest {

    // Static initializer runs before any test method
    static {
        insert new AVO_Rest_API_Settings__c(
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
    }

    @isTest
    static void testSchedulerExecution() {
        String jobName = 'Test SharePoint File Processor Scheduler';
        String cronExp = '0 0 12 * * ?'; // Every day at 12 PM

        Test.startTest();
        String jobId = System.schedule(jobName, cronExp, new AVO_SharePointFileProcessorScheduler());
        Test.stopTest();

        // Assert a queueable job was added
        List<AsyncApexJob> jobs = [SELECT Id, JobType, Status FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assert(!jobs.isEmpty(), 'Expected a queueable job to be enqueued by the scheduler.');
    }
}