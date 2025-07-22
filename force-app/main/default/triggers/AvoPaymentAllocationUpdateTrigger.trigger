trigger AvoPaymentAllocationUpdateTrigger on clariti__PaymentAllocation__c (after insert) {
    new AvoPaymentAllocationUpdateHandler().run();
}