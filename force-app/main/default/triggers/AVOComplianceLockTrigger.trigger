trigger AVOComplianceLockTrigger on AVO_Compliance__c (before update) {
    new AVOComplianceLockTriggerHandler().run();
}