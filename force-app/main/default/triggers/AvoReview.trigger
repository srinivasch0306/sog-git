/**
 * Description of trigger
 * a trigger to fullfill process related logic on review status changes
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/20/2021
 *  
 */
trigger AvoReview on MUSW__Review__c(before insert, before update,after insert, after update)
{
    new AvoReviewTriggerHandler().run();
}