/**
 * Description of class
 * a sub clas from AvoProcessEngineBase for inspections
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoProcessEngineInspection extends AvoProcessEngineBase{
    public AvoProcessEngineInspection(MUSW__Inspection__c inspection) {
        this.inspection  = inspection;
        triggerFrom = TriggerFromObjectEnum.INSPECTION;
    }
}