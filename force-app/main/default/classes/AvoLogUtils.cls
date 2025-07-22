public class AvoLogUtils {
    public static void logError(string message, string details) { 
        logError(message, details, null);
    }

    public static void logInfo(string message, string details) { 
        logInfo(message, details, null);
    }

    public static void logError(string message, string details, Id recordId) {         
        log(message, details,'ERROR', recordId );
    }

    public static void logInfo(string message, string details,Id recordId) { 
        log(message, details,'GENERAL', recordId );
    }
    
    public static void log(string message, string details, string type, Id recordId) { 
        MUSW__EventLog__c eventLog = new MUSW__EventLog__c();
        
        if (type == 'ERROR'){
            eventLog.MUSW__Type__c = 'EXCEPTION';
            eventLog.MUSW__Severity__c = 'ERROR';
        }else {
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
        insert eventLog;
    }
}