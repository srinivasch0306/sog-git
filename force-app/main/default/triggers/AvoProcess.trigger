/**
 * Description of trigger
 * a trigger to fullfill process related logic, which includes auto state transition
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/20/2021
 *  
 */
trigger AvoProcess on AVO_Process__c(before insert, before update) 
{
    new AvoProcessTriggerHandler().run();    
}