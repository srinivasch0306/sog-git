@isTest
public class DRE2_AttachmentTriggerTest {

    @isTest
    static void testAttachmentTriggerAllContexts() {
        // Step 1: Create a parent record to attach the file to
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Step 2: Prepare the attachment
        Attachment att = new Attachment(
            Name = 'TestFile.txt',
            Body = Blob.valueOf('Sample Content'),
            ParentId = acc.Id,
            ContentType = 'text/plain'
        );

        Test.startTest();

        // INSERT - after insert
        insert att;

        // UPDATE - before update
        att.Name = 'UpdatedTestFile.txt';
        update att;

        // DELETE - before delete
        delete att;

        // UNDELETE - after undelete
        undelete att;

        Test.stopTest();

        // Optional: Assertion
        Attachment reFetched = [SELECT Name FROM Attachment WHERE Id = :att.Id];
        System.assertEquals('UpdatedTestFile.txt', reFetched.Name);
    }
}