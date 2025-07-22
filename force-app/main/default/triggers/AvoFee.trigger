/**
 * Description of trigger
 * a trigger to fullfill process related logic on fee change
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
trigger AvoFee on MUSW__Fee__c(after update, after insert) 
{
    new AvoFeeTriggerHandler().run();    
}