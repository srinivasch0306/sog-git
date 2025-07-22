/**
 * Description of class
 * a process engine fulfills all process related auto logic
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/22/2021
 *  
 */

public class AvoProcessEnginePermit extends AvoProcessEngineBase{
    
    // call this function when the process engine is triggered from a permit record
    public AvoProcessEnginePermit(MUSW__Permit2__c permitTriggeredFrom) {
        permit = permitTriggeredFrom;
		triggerFrom = TriggerFromObjectEnum.PERMIT;
        initialize();
    }

    // check the process definition to see if there are stopppers which will prevent the requested
    // permit status change from happening    

    public Boolean isStatusChangeAllowed(){
        if (processFound() == false) return true;

        for(AVO_Process_State_Transition__c processStateTransition: processStateTransitions) {
            // only check the to be state, no need to check on the orignial state
            if (processStateTransition.Avo_To_State__c == permit.MUSW__Status__c){
                system.debug('Matching state transition found:' + processStateTransition);
                if (StopperConditionsMet(processStateTransition) == false){
                    // if one of the defined transitions doesn't allow the state transition to happen,
                    // the transition should not be allowed

                    // in other words, if there are multiple transition matched, the system will check
                    // to ensure all conditions are met
                    return false;
                }
            }
        }
        // return true if all conditions are met.
        return true;
    }

    // 
    public void createPostTransitionActions(){

        system.debug('starting creating post transition actions');
        if (processFound() == true){
            for(AVO_Process_State_Transition__c processStateTransition: processStateTransitions) {
                // check the to be state and orignial state
                if (processStateTransition.Avo_To_State__c == permit.MUSW__Status__c){
                    system.debug('Matching state transition found:' + processStateTransition);
                    createPostActions(processStateTransition);
                }
            }
        }
    }
}