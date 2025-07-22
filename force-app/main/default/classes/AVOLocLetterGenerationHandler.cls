public class AVOLocLetterGenerationHandler extends AvoTriggerHandler {
    public override void afterInsert() {
        System.debug('Enter AVOLocLetterGeneration');

        // Normalized, lowercase title values without suffixes
        Set<String> validTitles = new Set<String>{
    
            'Permit_Expiring_LOC' };
    
        Map<Id, Id> permitToDocMap = new Map<Id, Id>();
        Set<Id> docIds = new Set<Id>();
    
        // Collect related ContentDocument IDs where LinkedEntity is a Permit2 record
        for (ContentDocumentLink cdl : (List<ContentDocumentLink>) Trigger.new) {
            if (cdl.LinkedEntityId != null &&
                cdl.LinkedEntityId.getSObjectType() == MUSW__Permit2__c.SObjectType) {
                permitToDocMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
                docIds.add(cdl.ContentDocumentId);
            }
        }
    
        if (docIds.isEmpty()) return;
    
        // Query related document titles
        Map<Id, ContentDocument> docMap = new Map<Id, ContentDocument>(
            [SELECT Id, Title FROM ContentDocument WHERE Id IN :docIds]
        );
    
        System.debug('Queried documents: ' + docMap);
    
        List<MUSW__Permit2__c> permitsToUpdate = new List<MUSW__Permit2__c>();
    
        for (Id permitId : permitToDocMap.keySet()) {
            Id docId = permitToDocMap.get(permitId);
            ContentDocument doc = docMap.get(docId);
    
            if (doc != null && doc.Title != null) {
                String originalTitle = doc.Title;
                String cleanTitle = originalTitle;
    
                    cleanTitle = originalTitle.left(originalTitle.length() - 14).trim();
                    System.debug('Title: ' + cleanTitle);
    
                if (!validTitles.contains(cleanTitle) && cleanTitle.contains('LOC') ) {
                    System.debug('Matched clean title: ' + cleanTitle);
                    permitsToUpdate.add(new MUSW__Permit2__c(
                        Id = permitId,
                        AVO_Letter_of_Concurrence_Issuance__c = Date.today()
                    ));
                } else {
                    System.debug('No match for title: ' + originalTitle);
                }
            }
        }
    
        if (!permitsToUpdate.isEmpty()) {
            System.debug('Updating permits: ' + permitsToUpdate);
            update permitsToUpdate;
        }
    }
}