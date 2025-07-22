/**
 * Description of trigger
 * a trigger to fullfill process related logic on inspection status change
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
trigger AvoInspection on MUSW__Inspection__c(after update) 
{
    new AvoInspectionTriggerHandler().run();    
}