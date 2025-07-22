/**
 * Description of class
 * a sub clas from AvoProcessEngineBase for submissions
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoProcessEngineSubmission extends AvoProcessEngineBase{
    public AvoProcessEngineSubmission(MUSW__Submission__c submission) {
        this.submission  = submission;
        triggerFrom = TriggerFromObjectEnum.SUBMISSION;
    }
}