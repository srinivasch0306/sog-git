public class AvoDataMigrationQueueable implements Queueable {

    private string sObjectName;
    public AvoDataMigrationQueueable(string sObjectName) {
        this.sObjectName = sObjectName;
    }

    public void execute(QueueableContext context) {

        // this will update all records from the sObjectName without a value in the AVO_GUID__c field;
        try {
            AvoDataMigration.updateGuid(this.sObjectName);
        } catch (Exception e) {
            system.debug(this.sObjectName);
            log('GUID update failed -' + sObjectName, e.getMessage() + '\r\n' + e.getStackTraceString(), 'ERROR', null );
        } finally {
        }
    }

    private void log(string message, string details, string type, Id recordId) { 
        MUSW__EventLog__c eventLog = new MUSW__EventLog__c();
        
        if (type == 'ERROR') {
            eventLog.MUSW__Type__c = 'EXCEPTION';
            eventLog.MUSW__Severity__c = 'ERROR';
        } else {
            eventLog.MUSW__Type__c = 'GENERAL';
            eventLog.MUSW__Severity__c = 'INFO';
        }

        eventLog.MUSW__Message__c = message;
        eventLog.MUSW__MessageLong__c = details;
        eventLog.MUSW__User__c = UserInfo.getUserId();
        eventlog.MUSW__Time_Stamp__c = System.now();
        if (recordId !=null){
            eventLog.MUSW__Record_ID__c = recordId;
        }
        Insert eventLog;
    }
}