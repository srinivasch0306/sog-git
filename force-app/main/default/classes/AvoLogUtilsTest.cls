@isTest
public class AvoLogUtilsTest {
    @isTest
    static void test_AvoLogUtils() {
        // Test Case 1
        // here are see my changes.
        AvoLogUtils.logError('Error message', 'Error details');
        
        List<MUSW__EventLog__c> myLog;
        myLog = [
            select id
            from MUSW__EventLog__c
        ];
        assert.areEqual(1, myLog.size(), 'there should be only one event created');
    }
}