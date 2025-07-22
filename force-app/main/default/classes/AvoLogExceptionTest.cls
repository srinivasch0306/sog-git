@isTest
private class AvoLogExceptionTest {
    
    @isTest
static void testLoggingCreatesExceptionLoggerRecord() {
    Test.startTest();

    try {
        Integer x = 1 / 0;
    } catch (Exception ex) {
        new AvoLogException()
            .Module('UnitTest')
            .ExceptionCause('Testing divide by zero')
            .log(ex);
    }

    Test.stopTest();

    List<AVO_Exception_Logger__c> logs = [
        SELECT Module_Name__c, Exception_Message__c, Exception_Type__c,
               Class_Name__c, Method_Name__c, Line_Number__c
        FROM AVO_Exception_Logger__c
        WHERE Module_Name__c = 'UnitTest'
    ];

    System.assertEquals(1, logs.size(), 'One exception log should be created');
    AVO_Exception_Logger__c log = logs[0];

    System.assertEquals('UnitTest', log.Module_Name__c);

    System.debug('Logged Exception Message: ' + log.Exception_Message__c);

    System.assert(
        log.Exception_Message__c != null && log.Exception_Message__c.trim().length() > 0,
        'Exception message should not be empty'
    );

    System.assertEquals('System.MathException', log.Exception_Type__c);
    System.assertNotEquals(null, log.Class_Name__c, 'Class name should be populated');
    System.assertNotEquals(null, log.Method_Name__c, 'Method name should be populated');
    System.assertNotEquals(null, log.Line_Number__c, 'Line number should be populated');
}

}