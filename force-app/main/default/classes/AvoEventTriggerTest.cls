@isTest
public class AvoEventTriggerTest {

    @testSetup
    static void setupData() {
        // Create a test timed Event (not an all-day event)
        Event ev = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now().addDays(1),
            EndDateTime = System.now().addDays(1).addHours(1),
            IsAllDayEvent = false
        );
        insert ev;
    }

    static testMethod void testEventAfterUpdate() {
        // Fetch the test event
        Event ev = [SELECT Id, Subject FROM Event LIMIT 1];
        ev.Subject = 'Updated Event Subject';

        Test.startTest();
        update ev;
        Test.stopTest();

        // Assertion to confirm the update
        Event updated = [SELECT Subject FROM Event WHERE Id = :ev.Id];
        System.assertEquals('Updated Event Subject', updated.Subject);
    }
}