public class AvoWithdrawalTriggerHandler extends AvoTriggerHandler { 
  
    public override void beforeUpdate() {
        // Use map to avoid SOQL in loop
        for(AVO_Withdrawals__c withdrawal : (List<AVO_Withdrawals__c>) Trigger.new) { 
            String errorMessage = '';
            Boolean errorFound = false;
        	if ((withdrawal.AVO_Type__c == 'Surface Water Withdrawal Application' || withdrawal.AVO_Type__c == 'Surface Water Withdrawal') && withdrawal.AVO_Permit__c != null 
                && !String.isBlank(withdrawal.AVO_GIS_UNIQUE__c) && withdrawal.AVO_Low_Flow_cfs__c > 0 && withdrawal.AVO_Low_Flow_gpm__c > 0){
                List<MUSW__Submission__c> lowFlowPlans = [SELECT Id, Name, MUSW__Submission_DateTime__c FROM MUSW__Submission__c WHERE MUSW__Permit2__c = :withdrawal.AVO_Permit__c AND Name = 'Low Flow Guidance'];
                if (!lowFlowPlans.isEmpty()) {
                    MUSW__Submission__c lowFlowPlan = lowFlowPlans[0];
                    if (lowFlowPlan.MUSW__Submission_DateTime__c != null) {
                        withdrawal.addError('LF cfs and/or LF gpm >0 and LF Plan not marked as on file.');
                    }
                }
            }
        }
    }  

}