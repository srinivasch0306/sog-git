@isTest
public class AvoCommonTest {

    @isTest
    static void testAddBusinessDaysPositive() {
        Date startDate = Date.newInstance(2025, 6, 12); // Thursday
        Date resultDate = AvoCommon.AddBusinessDays(startDate, 3); // Should skip the weekend
        // Thursday + 3 business days = Tuesday
        System.assertEquals(Date.newInstance(2025, 6, 17), resultDate);
    }

    @isTest
    static void testAddBusinessDaysNegative() {
        Date startDate = Date.newInstance(2025, 6, 17); // Tuesday
        Date resultDate = AvoCommon.AddBusinessDays(startDate, -3); // Should skip the weekend
        // Tuesday - 3 business days = Thursday
        System.assertEquals(Date.newInstance(2025, 6, 12), resultDate);
    }

    @isTest
    static void testAddBusinessDaysZero() {
        Date startDate = Date.newInstance(2025, 6, 12); // Thursday
        Date resultDate = AvoCommon.AddBusinessDays(startDate, 0);
        System.assertEquals(startDate, resultDate);
    }

    @isTest
    static void testIsWeekendTrue() {
        Date saturday = Date.newInstance(2025, 6, 14); // Saturday
        Date sunday = Date.newInstance(2025, 6, 15);   // Sunday
        System.assertEquals(true, AvoCommon.IsWeekend(saturday));
        System.assertEquals(true, AvoCommon.IsWeekend(sunday));
    }

    @isTest
    static void testIsWeekendFalse() {
        Date monday = Date.newInstance(2025, 6, 16); // Monday
        System.assertEquals(false, AvoCommon.IsWeekend(monday));
    }
}