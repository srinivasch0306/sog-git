trigger ReviewAddBluebeamUser on MUSW__Review__c (after insert, after update) {
    BGCM.ITriggerHandler handler = new BB_ReviewTriggerHandler.ReviewBluebeam();
    BGCM.TriggerManager.execute('ReviewBluebeam', handler);
}