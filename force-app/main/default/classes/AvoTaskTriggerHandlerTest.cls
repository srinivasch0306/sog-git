@isTest
public class AvoTaskTriggerHandlerTest {
    
    @isTest
    static void setupSettings() {
        insert new AVO_Process_Engine_Settings__c(AVO_Process_Engine_Enabled__c = true);
    }
    
    @isTest
    static void testAfterUpdate_TaskStatusChanged() {
        // Get a user to assign the task
        User u = [SELECT Id FROM User WHERE Profile.Name != 'Automated Process' LIMIT 1];
        
        // Create task with initial status
        Task t = new Task(
            Subject = 'Test Trigger Task',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = u.Id
        );
        insert t;
        
        // Change the status to trigger the logic
        t.Status = 'Completed';
        
        Test.startTest();
        update t;
        Test.stopTest();
        
        // Confirm status was updated
        Task updated = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', updated.Status);
    }
    
    @isTest
    static void testAfterUpdate_TaskStatusNotChanged() {
        // Get a user to assign the task
        User u = [SELECT Id FROM User WHERE Profile.Name != 'Automated Process' LIMIT 1];
        
        // Create task
        Task t = new Task(
            Subject = 'Test Trigger Task',
            Status = 'In Progress',
            Priority = 'Normal',
            OwnerId = u.Id
        );
        insert t;
        
        // Update another field, but leave status the same
        t.Priority = 'High';
        
        Test.startTest();
        update t;
        Test.stopTest();
        
        // Still In Progress
        Task updated = [SELECT Status, Priority FROM Task WHERE Id = :t.Id];
        System.assertEquals('In Progress', updated.Status);
        System.assertEquals('High', updated.Priority);
    }
}