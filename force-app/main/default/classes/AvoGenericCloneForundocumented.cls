public without sharing class AvoGenericCloneForundocumented {


    @InvocableMethod(label='Clone Records with Output')
    public static List<CloneResponse> cloneRecords(List<CloneRequest> requests) {
        List<CloneResponse> responses = new List<CloneResponse>();

        for (CloneRequest request : requests) {
            List<SObject> clonedRecords = new List<SObject>();
            Map<Id, Id> oldToNewIdMap = new Map<Id, Id>();

            // Clone records and set new parent reference
            for (SObject record : request.records) {
                SObject cloned = record.clone(false, true, false, false);
                cloned.put(request.parentApiName, request.newParentValue);
                clonedRecords.add(cloned);
            }

            insert clonedRecords;

            // Map original IDs to new cloned IDs
            for (Integer i = 0; i < request.records.size(); i++) {
                oldToNewIdMap.put(request.records[i].Id, clonedRecords[i].Id);
                System.debug('Cloned Record ID: ' + clonedRecords[i].Id);
            }

            // Optionally copy attachments
            if (request.includeAttachments) {
                copyAttachments(oldToNewIdMap);
            }

            // Build response with cloned record IDs
            CloneResponse response = new CloneResponse();
            response.output = new List<Id>(oldToNewIdMap.values());
            responses.add(response);
        }

        return responses;
    }

    private static void copyAttachments(Map<Id, Id> oldToNewIdMap) {
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :oldToNewIdMap.keySet()
        ];

        Map<Id, Id> contentDocToOldRecord = new Map<Id, Id>();
        for (ContentDocumentLink link : links) {
            contentDocToOldRecord.put(link.ContentDocumentId, link.LinkedEntityId);
        }

        List<ContentVersion> oldVersions = [
            SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocToOldRecord.keySet()
            AND IsLatest = true
        ];

        List<ContentVersion> newVersions = new List<ContentVersion>();

        for (ContentVersion oldVersion : oldVersions) {
            Id oldRecordId = contentDocToOldRecord.get(oldVersion.ContentDocumentId);
            Id newRecordId = oldToNewIdMap.get(oldRecordId);
            if (newRecordId != null) {
                ContentVersion newVersion = new ContentVersion(
                    Title = oldVersion.Title,
                    PathOnClient = oldVersion.PathOnClient,
                    VersionData = oldVersion.VersionData,
                    FirstPublishLocationId = newRecordId
                );
                newVersions.add(newVersion);
            }
        }

        if (!newVersions.isEmpty()) {
            insert newVersions;
        }
    }

    public class CloneRequest {
        @InvocableVariable(required=true)
        public List<SObject> records;

        @InvocableVariable(required=true)
        public String parentApiName;

        @InvocableVariable(required=true)
        public Id newParentValue;

        @InvocableVariable
        public Boolean includeAttachments;
    }

    public class CloneResponse {
        @InvocableVariable
        public List<Id> output;
    }
}