/**
 * Description of trigger
 * a trigger to fullfill Process State Transition Trigger related logic
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/23/2021
 *  
 */
trigger AvoProcessStateTransitionTrigger on AVO_Process_State_Transition_Trigger__c(before insert, before update) 
{
    new AvoProcessStateTransitionTriggerHandler().run();
}