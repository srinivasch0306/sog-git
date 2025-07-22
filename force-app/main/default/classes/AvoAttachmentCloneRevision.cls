public without sharing class AvoAttachmentCloneRevision {

    // Flow-Invocable version of syncFilesFromChildToParent
    @InvocableMethod(label='Sync Files From Child To Parent' description='Copies files from revision record to permit parent record with duplicate check and replacement')
    public static void syncFilesFromChildToParentFlow(List<SyncRequest> requests) {
        for (SyncRequest request : requests) {
            syncFilesFromChildToParent(request.childRecordId, request.parentRecordId);
            syncSharePointFilesFromChildToParent(request.childRecordId, request.parentRecordId);
        }
    }

    // Flow Input Wrapper
    public class SyncRequest {
        @InvocableVariable(label='Child Record Id' required=true)
        public Id childRecordId;

        @InvocableVariable(label='Parent Record Id' required=true)
        public Id parentRecordId;
    }

   public static void syncFilesFromChildToParent(Id childId, Id parentId) {
        List<ContentDocumentLink> childLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :childId
        ];
        List<ContentDocumentLink> parentLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentId
        ];

        Set<Id> childDocIds = new Set<Id>();
        Set<Id> parentDocIds = new Set<Id>();
        for (ContentDocumentLink link : childLinks) childDocIds.add(link.ContentDocumentId);
        for (ContentDocumentLink link : parentLinks) parentDocIds.add(link.ContentDocumentId);

        Set<Id> allDocIds = new Set<Id>();
        allDocIds.addAll(childDocIds);
        allDocIds.addAll(parentDocIds);

        List<ContentVersion> allVersions = [
            SELECT Id, Title, PathOnClient, VersionData, ContentDocumentId, CreatedDate
            FROM ContentVersion
            WHERE IsLatest = TRUE AND ContentDocumentId IN :allDocIds
        ];

        Map<Id, ContentVersion> childVersions = new Map<Id, ContentVersion>();
        Map<Id, ContentVersion> parentVersions = new Map<Id, ContentVersion>();
        for (ContentVersion ver : allVersions) {
            if (childDocIds.contains(ver.ContentDocumentId)) {
                childVersions.put(ver.ContentDocumentId, ver);
            } else if (parentDocIds.contains(ver.ContentDocumentId)) {
                parentVersions.put(ver.ContentDocumentId, ver);
            }
        }

        Map<String, ContentVersion> parentTitleMap = new Map<String, ContentVersion>();
        Map<String, Id> parentDocByTitle = new Map<String, Id>();
        for (ContentVersion pv : parentVersions.values()) {
            parentTitleMap.put(pv.Title, pv);
            parentDocByTitle.put(pv.Title, pv.ContentDocumentId);
        }

        List<ContentVersion> toInsert = new List<ContentVersion>();
        List<ContentDocument> toDelete = new List<ContentDocument>();

        for (ContentVersion childVer : childVersions.values()) {
            ContentVersion parentVer = parentTitleMap.get(childVer.Title);
            if (parentVer == null) {
                toInsert.add(new ContentVersion(
                    Title = childVer.Title,
                    PathOnClient = childVer.PathOnClient,
                    VersionData = childVer.VersionData,
                    FirstPublishLocationId = parentId
                ));
            } else if (childVer.CreatedDate > parentVer.CreatedDate) {
                toInsert.add(new ContentVersion(
                    Title = childVer.Title,
                    PathOnClient = childVer.PathOnClient,
                    VersionData = childVer.VersionData,
                    FirstPublishLocationId = parentId
                ));
                toDelete.add(new ContentDocument(Id = parentDocByTitle.get(childVer.Title)));
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
    
     public static void syncSharePointFilesFromChildToParent(Id childId, Id parentId) {
        // Step 1: Get existing SharePoint files from both
		List<AVO_SharePoint_File__c> childRecords = [
            SELECT Id, Name, AVO_Account__c, AVO_Application__c, AVO_Comment__c, AVO_Complaint__c, AVO_Compliance__c, AVO_Contact__c, AVO_ContentDocumentId__c, CreatedById,
            AVO_Inspection__c, LastModifiedById, AVO_License__c, AVO_Meter__c, AVO_Meter_Codeset__c, AVO_Meter_Transaction__c, AVO_Meter_Withdrawal__c, AVO_Milestone__c,
            OwnerId, AVO_Permit__c, AVO_Review__c, AVO_SharePoint_External_Link__c, AVO_SharePoint_Item_Id__c, AVO_SharePoint_URL__c, AVO_SharePoint_URL_Text__c, AVO_Submission__c,
            AVO_Violation__c, AVO_Withdrawal__c
            FROM AVO_SharePoint_File__c
            WHERE AVO_Permit__c = :childId
        ]; 

         List<AVO_SharePoint_File__c> ParentRecords = [SELECT Name FROM AVO_SharePoint_File__c WHERE AVO_Permit__c = :parentId];
         Set<String> parentSharePointRecordNames = new Set<String>();
         
         for(AVO_SharePoint_File__c sharePointRecordName : ParentRecords){ parentSharePointRecordNames.add(sharePointRecordName.Name); }
         List<AVO_SharePoint_File__c> recordToInsert = new List<AVO_SharePoint_File__c>();
         
         for(AVO_SharePoint_File__c ChildRecord : childRecords){
             if(!parentSharePointRecordNames.contains(ChildRecord.Name)){
                 AVO_SharePoint_File__c cloneFile = ChildRecord.clone(false, true, false, false);
                 cloneFile.AVO_Permit__c = parentId;
                 recordToInsert.add(cloneFile);
             }
             
             if(recordToInsert.Size() > 0){
                 Insert recordToInsert;
             }
             
         }
         
     }
}