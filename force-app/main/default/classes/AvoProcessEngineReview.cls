/**
 * Description of class
 * a sub clas from AvoProcessEngineBase for reviews
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoProcessEngineReview extends AvoProcessEngineBase{
    public AvoProcessEngineReview(MUSW__Review__c review) {
        system.debug('AvoProcessEngineReview created');
        this.review  = review;
		triggerFrom = TriggerFromObjectEnum.REVIEW;
    }
}