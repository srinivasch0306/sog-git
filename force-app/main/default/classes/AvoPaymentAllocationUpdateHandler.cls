public class AvoPaymentAllocationUpdateHandler extends AvoTriggerHandler {
    public override void afterInsert() {
        List<clariti__PaymentAllocation__c> newRecords = (List<clariti__PaymentAllocation__c>) Trigger.new;

        if (newRecords.isEmpty()) return;

        // Query with related Fee and Fee.AVO_Compliance__c
        List<clariti__PaymentAllocation__c> paymentAllocationsToUpdate = [
            SELECT Id, AVO_Compliance__c, clariti__Fee__c, clariti__Fee__r.AVO_Compliance__c
            FROM clariti__PaymentAllocation__c
            WHERE Id IN :newRecords
        ];

        Boolean needsUpdate = false;

        for (clariti__PaymentAllocation__c pa : paymentAllocationsToUpdate) {
            if (pa.clariti__Fee__r != null && pa.clariti__Fee__r.AVO_Compliance__c != null) {
                pa.AVO_Compliance__c = pa.clariti__Fee__r.AVO_Compliance__c;
                needsUpdate = true;
            }
        }

        if (needsUpdate) {
            update paymentAllocationsToUpdate;
        }
    }
}