/**
 * Description of class
 * trigger proxy for submisisons
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoSubmissionTriggerHandler extends AvoTriggerHandler { 
    
    public override void afterUpdate() {
        for(MUSW__Submission__c submission : (List<MUSW__Submission__c>) Trigger.new) { 
            MUSW__Submission__c oldSubmission = (MUSW__Submission__c)Trigger.oldMap.get(submission.Id);
            string oldStatus =  submission.MUSW__Status__c;
            string newStatus =  oldSubmission.MUSW__Status__c;
            System.debug('Triggering submission process engine');
           if (oldStatus <> newStatus){
                // task status has changed
                AvoProcessEngineSubmission engine = new AvoProcessEngineSubmission(submission);
                engine.run();
            }            
        }
    }
}