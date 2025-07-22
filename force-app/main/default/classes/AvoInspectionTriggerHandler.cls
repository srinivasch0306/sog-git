/**
 * Description of class
 * trigger proxy for inspections
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoInspectionTriggerHandler extends AvoTriggerHandler { 
    
    public override void afterUpdate() {
        for(MUSW__Inspection__c inspection : (List<MUSW__Inspection__c>) Trigger.new) { 

            MUSW__Inspection__c oldInspection = (MUSW__Inspection__c)Trigger.oldMap.get(inspection.Id);
            // trigger the process engine only if the inspection result has changed.
            if (inspection.MUSW__Status__c != null && oldInspection.MUSW__Status__c != inspection.MUSW__Status__c){
            	AvoProcessEngineInspection avoProcessEngineInspection = new AvoProcessEngineInspection(inspection);
            	avoProcessEngineInspection.run(); 
            }
        }


    }
}