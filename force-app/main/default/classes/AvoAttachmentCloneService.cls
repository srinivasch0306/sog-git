public without sharing class AvoAttachmentCloneService {
    @InvocableMethod(label='AVO Clone Attachments' description='Copies attachments from source record to target record')
    public static void AVOCloneAttachments(List<AVOAttachmentCloneRequest> requests) {
        Map<Id, Id> oldToNewRecordIds = new Map<Id, Id>();
        for (AVOAttachmentCloneRequest request : requests) {
            oldToNewRecordIds.put(request.sourceRecordId, request.targetRecordId);
        }
        if (!oldToNewRecordIds.isEmpty()) {
            copyAttachments(oldToNewRecordIds);
        }
    }

    private static void copyAttachments(Map<Id, Id> oldToNewRecordIds) {
        // Step 1: Get all ContentDocument Ids linked to source records
        List<ContentDocumentLink> oldLinks = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :oldToNewRecordIds.keySet()
        ];

        if (oldLinks.isEmpty()) return;

        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink oldLink : oldLinks) {
            contentDocIds.add(oldLink.ContentDocumentId);
        }

        // Step 2: Retrieve ContentVersion records for these documents
        List<ContentVersion> oldVersions = [
            SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocIds
            AND IsLatest = TRUE
        ];

        List<ContentVersion> newVersions = new List<ContentVersion>();

        // Step 3: Clone ContentVersion for the new record
        for (ContentVersion oldVersion : oldVersions) {
            for (ContentDocumentLink oldLink : oldLinks) {
                if (oldLink.ContentDocumentId == oldVersion.ContentDocumentId) {
                    Id newRecordId = oldToNewRecordIds.get(oldLink.LinkedEntityId);
                    if (newRecordId != null) {
                        newVersions.add(new ContentVersion(
                            Title = oldVersion.Title,
                            PathOnClient = oldVersion.PathOnClient,
                            VersionData = oldVersion.VersionData,
                            FirstPublishLocationId = newRecordId
                        ));
                    }
                }
            }
        }

        if (!newVersions.isEmpty()) {
            insert newVersions;
        }
    }

    public class AVOAttachmentCloneRequest {
        @InvocableVariable(required=true)
        public Id sourceRecordId;

        @InvocableVariable(required=true)
        public Id targetRecordId;
    }
}