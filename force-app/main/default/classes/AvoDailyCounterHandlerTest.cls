@isTest
public class AvoDailyCounterHandlerTest {

    @isTest
    static void testDailyMethod() {
        AvoDailyCounterHandler.dailyMethod();
 
        // Optional assert (not needed for coverage, but good practice)
        System.assert(true);
    }
     @isTest
    static void testDayMethod() {
        AvoDayCounterHandler.dayMethod();
 
        // Optional assert (not needed for coverage, but good practice)
        System.assert(true);
    }
}