public class AvoUploadContentDocumentLinkHandler extends AvoTriggerHandler {
    public override void beforeInsert() {
        List<ContentDocumentLink> docLinks = (List<ContentDocumentLink>) Trigger.new;

        Set<Id> submissionIds = new Set<Id>();
        for (ContentDocumentLink doc : docLinks) {
            if (doc != null && doc.LinkedEntityId != null && 
                doc.LinkedEntityId.getSObjectType() == MUSW__Submission__c.SObjectType) {
                submissionIds.add(doc.LinkedEntityId);
            }
        }

        if (submissionIds.isEmpty()) return;

        // Query submissions and related permits
        Map<Id, MUSW__Submission__c> submissionMap = new Map<Id, MUSW__Submission__c>(
            [SELECT Id, Name, MUSW__Permit2__r.Name, MUSW__Permit2__r.OwnerId, 
                    MUSW__Submission_DateTime__c, MUSW__Status__c
             FROM MUSW__Submission__c
             WHERE Id IN :submissionIds]
        );

        List<MUSW__Submission__c> submissionsToUpdate = new List<MUSW__Submission__c>();
        List<Messaging.CustomNotification> notifications = new List<Messaging.CustomNotification>();

        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        Boolean isPortalUser = profileName != null && profileName.containsIgnoreCase('Community');

        Id notificationTypeId;
        try {
            notificationTypeId = [SELECT Id FROM CustomNotificationType 
                                  WHERE DeveloperName = 'Portal_Document_Uploaded' 
                                  LIMIT 1].Id;
        } catch (Exception e) {
            System.debug('Custom Notification Type not found: ' + e.getMessage());
        }

        for (ContentDocumentLink doc : docLinks) {
            if (doc == null || doc.LinkedEntityId == null) continue;
            if (doc.LinkedEntityId.getSObjectType() != MUSW__Submission__c.SObjectType) continue;

            MUSW__Submission__c submission = submissionMap.get(doc.LinkedEntityId);
            if (submission == null) continue;

            // Update submission fields
            submission.MUSW__Submission_DateTime__c = DateTime.now();
            submission.MUSW__Status__c = 'In Review';
            submissionsToUpdate.add(submission);

            // Check for portal user and send notification
            if (isPortalUser) {
                String notificationBody = 'A document has been uploaded by a portal user for ' + 
                                          doc.LinkedEntityId.getSObjectType().getDescribe().getLabel() + 
                                          ' ' + submission.Name;

                if (submission.MUSW__Permit2__r != null) {
                    notificationBody += ' on Permit ' + submission.MUSW__Permit2__r.Name;
                    String permitOwnerId = submission.MUSW__Permit2__r.OwnerId;
                    notificationBody += permitOwnerId != null && permitOwnerId.startsWith('00G') 
                                        ? ' for Queue' : ' for User';

                    if (notificationTypeId != null) {
                        Messaging.CustomNotification notify = new Messaging.CustomNotification();
                        notify.setTitle('Document Uploaded By Portal User');
                        notify.setBody(notificationBody);
                        notify.setNotificationTypeId(notificationTypeId);
                        notify.setTargetId(doc.LinkedEntityId);
                        notify.send(new Set<String>{permitOwnerId});
                    }
                }
            }
        }

        if (!submissionsToUpdate.isEmpty()) {
            update submissionsToUpdate;
        }
    }
}