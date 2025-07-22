public class AvoGenericCloneQueueable implements Queueable, Database.AllowsCallouts {
    private List<AvoGenericCloneService.CloneRequest> requests;

    public AvoGenericCloneQueueable(List<AvoGenericCloneService.CloneRequest> requests) {
        this.requests = requests;
    }

    public void execute(QueueableContext context) {
        List<SObject> allClonedRecords = new List<SObject>();
        Map<Id, Id> oldToNewIdMap = new Map<Id, Id>();
        List<SObject> allOriginalRecords = new List<SObject>();
        Boolean includeAnyAttachments = false;

        for (AvoGenericCloneService.CloneRequest req : requests) {
            if (req.includeAttachments == true) {
                includeAnyAttachments = true;
            }
            for (SObject original : req.records) {
                SObject clone = original.clone(false, true);
                if (clone.getSObjectType().getDescribe().fields.getMap().containsKey(req.parentApiName)) {
                    clone.put(req.parentApiName, req.newParentValue);
                }
                allClonedRecords.add(clone);
                allOriginalRecords.add(original);
            }
        }

        if (!allClonedRecords.isEmpty()) {
            insert allClonedRecords;

            for (Integer i = 0; i < allOriginalRecords.size(); i++) {
                oldToNewIdMap.put(allOriginalRecords[i].Id, allClonedRecords[i].Id);
            }
        }

        if (includeAnyAttachments && !oldToNewIdMap.isEmpty()) {
            AvoGenericCloneService.copyAttachments(oldToNewIdMap);
        }
    }
}