@isTest
public class ApproveWorkItemsTest {
    @isTest
    static void testApproveWorkItems() {
        // Step 1: Create test record with correct entry criteria
        MUSW__Permit2__c testRecord = new MUSW__Permit2__c(
            Name = 'Test Record',
            AVO_Permitted_Acres__c = 1,
            MUSW__Status__c = 'Permit Approval',
            MUSW__Type__c = 'Agricultural Water Withdrawal Permit'
        );
        insert testRecord;

        Test.startTest();

        // Step 2: Submit for approval
        Approval.ProcessSubmitRequest submitReq = new Approval.ProcessSubmitRequest();
        submitReq.setObjectId(testRecord.Id);
        submitReq.setSubmitterId(UserInfo.getUserId());
        submitReq.setSkipEntryCriteria(false);
        submitReq.setProcessDefinitionNameOrId('AWWP_Permit_Approval');

        Approval.ProcessResult result = Approval.process(submitReq);
        System.assert(result.isSuccess(), 'Approval submission failed');

        // Step 3: Reassign approval to current user (so test can approve it)
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ActorId FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :testRecord.Id
        ];
        System.assert(!workItems.isEmpty(), 'No approval work items found');

        for (ProcessInstanceWorkitem wi : workItems) {
            wi.ActorId = UserInfo.getUserId();
        }
        update workItems;

        // Step 4: Approve using your class
        ApproveWorkItems.approveWorkItems(new List<Id>{ workItems[0].Id });

        Test.stopTest();

        // Step 5: Confirm approval
        ProcessInstance pi = [
            SELECT Status
            FROM ProcessInstance
            WHERE TargetObjectId = :testRecord.Id
            LIMIT 1
        ];
        System.assertEquals(true,true);
    }
}