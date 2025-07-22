public with sharing class ApproveWorkItems {
    @InvocableMethod
    public static void approveWorkItems(List<Id> workItemIds) {
        if (workItemIds == null || workItemIds.isEmpty()) {
            return;
        }

        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for (Id workItemId : workItemIds) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItemId);
            req.setAction('Approve'); // You can use 'Reject' for rejection if needed
            requests.add(req);
        }

        try {
            Approval.ProcessResult[] results = Approval.process(requests);
            for (Approval.ProcessResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Failed to approve work item: ' + result.getInstanceStatus());
                }
            }
        } catch (Exception ex) {
            System.debug('Error while approving work items: ' + ex.getMessage());
            throw ex;
        }
    }
}