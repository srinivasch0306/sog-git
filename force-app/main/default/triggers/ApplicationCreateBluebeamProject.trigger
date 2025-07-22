trigger ApplicationCreateBluebeamProject on MUSW__Application2__c (after insert) {
    BGCM.ITriggerHandler handler = new BB_ApplicationTriggerHandler.ApplicationCreateBluebeamProject();
    BGCM.TriggerManager.execute('ApplicationCreateBluebeamProject', handler);
}