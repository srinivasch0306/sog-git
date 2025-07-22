/**
 * Description of class
 * a sub clas from AvoProcessEngineBase for fees
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoProcessEngineFee extends AvoProcessEngineBase{
    public AvoProcessEngineFee(MUSW__Fee__c fee) {
        system.debug('AvoProcessEngineFee created');
        this.fee = fee;
		triggerFrom = TriggerFromObjectEnum.FEE;        
    }
}