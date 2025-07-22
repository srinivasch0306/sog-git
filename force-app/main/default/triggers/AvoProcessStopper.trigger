/**
 * Description of trigger
 * a trigger to fullfill transition stopper related process logic
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/26/2021
 *  
 */
trigger AvoProcessStopper on AVO_Process_State_Transition_Stopper__c (before insert, before update) 
{
    new AvoProcessStopperTriggerHandler().run();    
}