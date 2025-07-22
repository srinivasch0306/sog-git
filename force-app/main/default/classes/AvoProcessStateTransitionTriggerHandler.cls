/**
 * Description of class
 * trigger proxy for Process State Transition Trigger
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/20/2021
 *  
 */
public class AvoProcessStateTransitionTriggerHandler extends AvoTriggerHandler { 
    public override void beforeUpdate() {
        for(AVO_Process_State_Transition_Trigger__c transitionTrigger : (List<AVO_Process_State_Transition_Trigger__c>) Trigger.new) { 
            recalculateAvoStatus(transitionTrigger);
        }
    }        

    public override void beforeInsert() {
        for(AVO_Process_State_Transition_Trigger__c transitionTrigger : (List<AVO_Process_State_Transition_Trigger__c>) Trigger.new) { 
            recalculateAvoStatus(transitionTrigger);
        }
    }      
    
    private void recalculateAvoStatus(AVO_Process_State_Transition_Trigger__c transitionTrigger)
    {
        transitionTrigger.Avo_Status__c = 
        (transitionTrigger.Avo_Submission_Type__c== null ? '' : transitionTrigger.Avo_Submission_Status__c) +
        (transitionTrigger.Avo_Milestone_Name__c== null ? '' : transitionTrigger.Avo_Milestone_Completed_Action__c) +
        (transitionTrigger.Avo_Review_Status__c == null ? '' : transitionTrigger.Avo_Review_Status__c) +
        (transitionTrigger.Avo_Inspection_Result__c == null ? '' : transitionTrigger.Avo_Inspection_Result__c) +
        (transitionTrigger.Avo_Fee_Status__c == null ? '' : transitionTrigger.Avo_Fee_Status__c) +
        (transitionTrigger.Avo_Deposit_Status__c == null ? '' : transitionTrigger.Avo_Deposit_Status__c) ;  
        
        system.debug('Test Status Submission ' + transitionTrigger.Avo_Submission_Status__c);
        system.debug('Test Status Milestone ' + transitionTrigger.Avo_Milestone_Completed_Action__c);
        system.debug('Test Status Review ' + transitionTrigger.Avo_Review_Status__c);
        system.debug('Test Status Inspection type' + transitionTrigger.Avo_Inspection_Type__c);
        system.debug('Test Status Inspection ' + transitionTrigger.Avo_Inspection_Result__c);
        system.debug('Test Status Fee ' + transitionTrigger.Avo_Fee_Status__c);
        system.debug('Test Status Deposit ' + transitionTrigger.Avo_Deposit_Status__c);
    }

}