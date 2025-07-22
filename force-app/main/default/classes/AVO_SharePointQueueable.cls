public class AVO_SharePointQueueable implements Queueable {
    Id contentDocumentId;
    Id linkedEntityId;

    public AVO_SharePointQueueable(Id contentDocId, Id entityId) {
        this.contentDocumentId = contentDocId;
        this.linkedEntityId = entityId;
    }

    public void execute(QueueableContext context) {
        ContentDocumentLink cdl = [SELECT Id, ContentDocumentId, LinkedEntityId 
                                   FROM ContentDocumentLink 
                                   WHERE ContentDocumentId = :contentDocumentId 
                                   AND LinkedEntityId = :linkedEntityId
                                   LIMIT 1];
        AVO_SharePointProcessRecord.transferBegin(cdl);
    }
}