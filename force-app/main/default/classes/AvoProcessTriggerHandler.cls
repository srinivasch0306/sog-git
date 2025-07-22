/**
 * Description of class
 * enforce data integrity for the process object
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/18/2021
 *  
 */
public class AvoProcessTriggerHandler extends AvoTriggerHandler { 
    public override void beforeUpdate() {
        for(AVO_Process__c AvoProcess : (List<AVO_Process__c>) Trigger.new) { 
            ValidateData(AvoProcess);           
        }
    }

    public override void beforeInsert() {
        for(AVO_Process__c AvoProcess : (List<AVO_Process__c>) Trigger.new) { 
            ValidateData(AvoProcess);
        }
    }
    
    private void ValidateData(AVO_Process__c AvoProcess)
    {
        If (AvoProcess.AVO_Permit_Type__c != null && AvoProcess.AVO_Planning_Application_Type__c != null ||
            AvoProcess.AVO_Permit_Type__c == null && AvoProcess.AVO_Planning_Application_Type__c == null){
            AvoProcess.addError('Select either Permit Types or Planning Application Typesd');
        }  
    }
}