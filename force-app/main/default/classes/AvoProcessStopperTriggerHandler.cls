public class AvoProcessStopperTriggerHandler extends AvoTriggerHandler{
    public override void beforeUpdate() {
            for(AVO_Process_State_Transition_Stopper__c stoper : (List<AVO_Process_State_Transition_Stopper__c>) Trigger.new) { 
            recalculateAvoStatus(stoper);
        }
    }        

    public override void beforeInsert() {
        for(AVO_Process_State_Transition_Stopper__c stoper : (List<AVO_Process_State_Transition_Stopper__c>) Trigger.new) { 
            recalculateAvoStatus(stoper);
        }
    }      

    private void recalculateAvoStatus(AVO_Process_State_Transition_Stopper__c stoper)
    {
        stoper.Avo_Status__c = 
        (stoper.Avo_Submission_Type__c== null ? '' : stoper.Avo_Submission_Status__c) +
        (stoper.Avo_Milestone_Name__c== null ? '' : stoper.Avo_Milestone_Completed_Action__c) +
        (stoper.Avo_Review_Status__c == null ? '' : stoper.Avo_Review_Status__c) +
        (stoper.Avo_Inspection_Result__c == null ? '' : stoper.Avo_Inspection_Result__c) +
        (stoper.Avo_Fee_Status__c == null ? '' : stoper.Avo_Fee_Status__c) +
        (stoper.Avo_Deposit_Status__c == null ? '' : stoper.Avo_Deposit_Status__c);
    }
}