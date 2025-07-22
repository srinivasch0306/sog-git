trigger AvoMeterTransactionSequenceNumber on AVO_Meter_Transaction__c (before insert, before update) {
    new AvoMeterTransactionSequenceNumberHandler().run();
}