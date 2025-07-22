/**
 * Description of trigger
 * a trigger to fullfill permit related process logic
 * @author Jason Li
 * last modified by Yao Li
 * @date 07/19/2021
 *  
 */
trigger AvoPermit on MUSW__Permit2__c(before insert, before update, after insert, after update) 
{
   new AvoPermitTriggerHandler().run();    
}