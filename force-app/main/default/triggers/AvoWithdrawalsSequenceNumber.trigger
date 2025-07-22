trigger AvoWithdrawalsSequenceNumber on AVO_Withdrawals__c (before insert, before update) {
    new AvoWithdrawalsSequenceNumberHandler().run();
}