public class AVOContentDocumentLinkHandler extends AvoTriggerHandler {
    /*public override void afterInsert() {
        List<ContentDocumentLink> links = (List<ContentDocumentLink>) Trigger.new;

        Set<Id> contentDocIds = new Set<Id>();

        for (ContentDocumentLink cdl : links) {
            contentDocIds.add(cdl.ContentDocumentId);
        }

        System.debug('Collected ContentDocumentIds: ' + contentDocIds);

        // Get latest ContentVersions to access AVO_DataFrom__c
        Map<Id, ContentVersion> docIdToVersion = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, AVO_DataFrom__c
            FROM ContentVersion
            WHERE IsLatest = true AND ContentDocumentId IN :contentDocIds
        ]) {
            docIdToVersion.put(cv.ContentDocumentId, cv); 
        }

        System.debug('Fetched ContentVersions: ' + docIdToVersion);

        // Collect Permit and Compliance IDs
        Set<Id> permitIds = new Set<Id>();
        Set<Id> complianceIds = new Set<Id>();

        for (ContentDocumentLink cdl : links) {
            ContentVersion version = docIdToVersion.get(cdl.ContentDocumentId);
            System.debug('Processing ContentDocumentLink: ' + cdl.ContentDocumentId);
            System.debug('Related ContentVersion: ' + version);

            if (version == null || String.isBlank(version.AVO_DataFrom__c)) {
                System.debug('Skipping due to missing or blank AVO_DataFrom__c');
                continue;
            }

            if (version.AVO_DataFrom__c == 'Permit') {
                permitIds.add(cdl.LinkedEntityId);
                System.debug('Added Permit ID: ' + cdl.LinkedEntityId);
            } else if (version.AVO_DataFrom__c == 'Compliance') {
                complianceIds.add(cdl.LinkedEntityId);
                System.debug('Added Compliance ID: ' + cdl.LinkedEntityId);
            }
        }

        // Query Permit statuses
        Map<Id, MUSW__Permit2__c> permits = new Map<Id, MUSW__Permit2__c>(
            [SELECT Id, MUSW__Status__c FROM MUSW__Permit2__c WHERE Id IN :permitIds]
        );
        System.debug('Fetched Permits: ' + permits);

        // Query Compliance statuses
        Map<Id, AVO_Compliance__c> compliances = new Map<Id, AVO_Compliance__c>(
            [SELECT Id, AVO_CompStatus__c FROM AVO_Compliance__c WHERE Id IN :complianceIds]
        );
        System.debug('Fetched Compliances: ' + compliances);

        // Execute logic based on status
        for (ContentDocumentLink cdl : links) {
            ContentVersion version = docIdToVersion.get(cdl.ContentDocumentId);
            if (version == null || String.isBlank(version.AVO_DataFrom__c)) continue;

            if (version.AVO_DataFrom__c == 'Permit') {
                MUSW__Permit2__c permit = permits.get(cdl.LinkedEntityId);
                System.debug('Permit for ID ' + cdl.LinkedEntityId + ': ' + permit);

                if (permit != null && 
                    (permit.MUSW__Status__c == 'Permit Issued' || permit.MUSW__Status__c == 'Permit Denied' || 
                     permit.MUSW__Status__c == 'Cancelled Undocumented Source' || permit.MUSW__Status__c == 'Undocumented Under Permitting Threshold' || 
                     permit.MUSW__Status__c == 'Cancelled' || permit.MUSW__Status__c == 'Consolidated')) {
                         System.debug('Triggering SharePoint transfer for id '+cdl.Id + ' LinkedEntityId '+cdl.LinkedEntityId + ' ContentDocumentId:'+cdl.ContentDocumentId);
                         System.enqueueJob(new AVO_SharePointQueueable(cdl.ContentDocumentId, cdl.LinkedEntityId));
                }
            } else if (version.AVO_DataFrom__c == 'Compliance') {
                AVO_Compliance__c compliance = compliances.get(cdl.LinkedEntityId);
                System.debug('Compliance for ID ' + cdl.LinkedEntityId + ': ' + compliance);

                if (compliance != null && 
                    (compliance.AVO_CompStatus__c == 'Resolved')) {
                        System.debug('Triggering SharePoint transfer for Compliance');
                        System.enqueueJob(new AVO_SharePointQueueable(cdl.ContentDocumentId, cdl.LinkedEntityId));
                }
            }
        }
    }*/
}