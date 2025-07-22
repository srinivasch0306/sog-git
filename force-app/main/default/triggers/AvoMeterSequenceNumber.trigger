trigger AvoMeterSequenceNumber on AVO_Meter__c (before insert, before update) {
    new AvoMeterSequenceNumberHandler().run();
}