public class AvoDataMigration {
    public AvoDataMigration() {

    }

    // this method will update all missing guids for all objects
    public static void updateGuids(){

        System.enqueueJob(new AvoDataMigrationQueueable('AVO_Process__c'));
        System.enqueueJob(new AvoDataMigrationQueueable('AVO_Process_State_Transition__c'));
        System.enqueueJob(new AvoDataMigrationQueueable('AVO_Process_State_Transition_Trigger__c'));
        System.enqueueJob(new AvoDataMigrationQueueable('AVO_Process_State_Transition_Stopper__c'));
        System.enqueueJob(new AvoDataMigrationQueueable('AVO_Process_State_Post_Actions__c'));
        
        System.enqueueJob(new AvoDataMigrationQueueable('BGBL__Merge_Template__c '));
        System.enqueueJob(new AvoDataMigrationQueueable('BGBL__Query__c '));
        System.enqueueJob(new AvoDataMigrationQueueable('BGBL__Batch_Letter__c '));
        System.enqueueJob(new AvoDataMigrationQueueable('BGBL__Applied_Query__c '));
        
        System.enqueueJob(new AvoDataMigrationQueueable('MUSW__Master_Inspection_List__c'));
        System.enqueueJob(new AvoDataMigrationQueueable('MUSW__Master_Submission_List__c'));
        System.enqueueJob(new AvoDataMigrationQueueable('Master_Task_List__c'));
        System.enqueueJob(new AvoDataMigrationQueueable('Master_Review_List__c'));
        System.enqueueJob(new AvoDataMigrationQueueable('AVO_Condition_Template__c'));
        
    }
    // prepare GUID for all records with GUID 
    public static void updateGuid(string sObjectName){
           
        // retrieve existing records without AVO_GUID__c
        List<sObject> recordsTobeUpdated = Database.query('SELECT ID, avo_Legacy_Id__c FROM ' + sObjectName);

        system.debug('number of records to be updated from ' + sObjectName + ' : ' + recordsTobeUpdated.size());
        // add AVO_GUID__c to each record without AVO_GUID__c
        for (sObject record:recordsTobeUpdated) {
            record.put('avo_Legacy_Id__c',record.get('ID'));
        }

        Update recordsTobeUpdated;
    }
}