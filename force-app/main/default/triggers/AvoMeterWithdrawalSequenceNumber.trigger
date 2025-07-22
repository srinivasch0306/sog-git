trigger AvoMeterWithdrawalSequenceNumber on AVO_Meter_Withdrawal__c (before insert, before update) {
    new AvoMeterWithdrawalSequenceNumberHandler().run();
}