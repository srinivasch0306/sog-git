/**
 * Description of trigger
 * a trigger to fullfill process related logic on submissions status change
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
trigger AvoSubmission on MUSW__Submission__c(after update, after insert, before insert, before update) 
{
    new AvoSubmissionTriggerHandler().run();    
}