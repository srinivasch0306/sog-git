@isTest
private class AvoTriggerHandlerTest {

    private class TestHandler extends AvoTriggerHandler {
        public Boolean beforeInsertCalled = false;
        public Boolean afterInsertCalled = false;

        public TestHandler(String ctx) {
            super.setTriggerContext(ctx, true);
        }

        override protected void beforeInsert() {
            beforeInsertCalled = true;
        }

        override protected void afterInsert() {
            afterInsertCalled = true;
        }
    }

    @isTest
    static void testRunWithContextBeforeInsert() {
        TestHandler handler = new TestHandler('before insert');
        handler.run();
        System.assert(handler.beforeInsertCalled, 'beforeInsert was not called');
    }

    @isTest
    static void testRunWithContextAfterInsert() {
        TestHandler handler = new TestHandler('after insert');
        handler.run();
        System.assert(handler.afterInsertCalled, 'afterInsert was not called');
    }

    @isTest
static void testBypassMethods() {
    String handlerName = 'TestHandler';

    // Should not be bypassed initially
    System.assertEquals(false, AvoTriggerHandler.isBypassed(handlerName), 'Handler should NOT be bypassed yet');

    // Bypass it
    AvoTriggerHandler.bypass(handlerName);
    System.assertEquals(true, AvoTriggerHandler.isBypassed(handlerName), 'Handler should now be bypassed');

    // Clear the bypass
    AvoTriggerHandler.clearBypass(handlerName);
    System.assertEquals(false, AvoTriggerHandler.isBypassed(handlerName), 'Handler should no longer be bypassed');
}


    @isTest
    static void testLoopCountExceeded() {
        TestHandler handler = new TestHandler('before insert');
        handler.setMaxLoopCount(2);
        handler.run(); // 1
        handler.run(); // 2

        Boolean exceptionThrown = false;
        try {
            handler.run(); // 3, should exceed
        } catch (AvoTriggerHandler.AvoTriggerHandlerException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception on loop count exceeded');
    }

    @isTest
    static void testOrgDefaultsCreatedIfMissing() {
        // Ensure no settings exist
        delete [SELECT Id FROM AVO_Process_Engine_Settings__c];

        TestHandler handler = new TestHandler('before insert');
        handler.run(); // Should create default settings

        List<AVO_Process_Engine_Settings__c> results = [SELECT Id FROM AVO_Process_Engine_Settings__c];
        System.assert(!results.isEmpty(), 'Expected default settings to be created');
    }
}