trigger AvoComplianceSequenceNumber on AVO_Compliance__c (before insert) {
    new AvoComplianceSequenceNumberHandler().run();
}