/**
* Apex Controller used in accnewReviewController.js. Makes calls to GET and POST data for Review Objects.
* @author Michael Chung
* last modified by Michael Chung
* @date 05/13/2021
* 
*/
public class AvoReviewDataRetrieverController {
    // Method that returns the supported review types for a specific Record ID.
    // The return value should be in a CSV format for multiple review types
    @AuraEnabled
    public static String getAllowedReviewTypes(Id recordId, String sObjectName) {   
        String response = '';
        ResponseJSONWrapper wrapper = new ResponseJSONWrapper();
        List<Master_Review_List__c> reviewTypes;
 
        // step 1 - get a list of allowed review types
        if(sObjectName == 'MUSW__Permit2__c') {
            // get the Permit Type and Id
            MUSW__Permit2__c permit = [
                SELECT Id, MUSW__Type__c
                FROM MUSW__Permit2__c
                WHERE Id = :recordId
            ];
 
            String permitType = permit.MUSW__Type__c;
 
            // Get the Master Review List items that include the Permit Type
            reviewTypes = [
               SELECT Name, Id 
                FROM Master_Review_List__c 
                WHERE Avo_Permit_Type__c includes (:permitType)
                AND Active__c = true
                AND Manual_Creation_Allowed__c = true 
                ORDER BY Name ASC 
            ];
        }
 
        wrapper.id = recordId;
        wrapper.reviewTypeList = new List<Option>();
 
        for(Master_Review_List__c reviewType:reviewTypes)
        {
            Option option = new Option();
 
            option.label = reviewType.Name;
            option.value = reviewType.Id;
            // Adding Option objects (label & value) into the reviewTypeList
            wrapper.reviewTypeList.Add(option);
        }
        system.debug('get>>'+JSON.serialize(wrapper));
        response = JSON.serialize(wrapper);

 
        return response;
    }   
 
    @AuraEnabled
    // Helper function used to determine the record type of the review being created. The return record type will determine a different layout and dropdown listbox values for the review to be created
    public static Id getReviewRecordTypeId(String recordType) {
 
        try {
            Id recordTypeId = Schema.SObjectType.MUSW__Review__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
            return recordTypeId;    
        } catch (Exception ex) {
            return  Schema.SObjectType.MUSW__Review__c.getRecordTypeInfosByName().get('AVO Review Default').getRecordTypeId();
        }
    }
 
 
    @AuraEnabled
    // Helper function used to get the Master Review List item's name based off of the Master Review List ID
    public static List<Master_Review_List__c> getMasterListInfo(List<String> ids) {
        List<Master_Review_List__c> result = [
            SELECT Name,Record_Type_ID__c,Record_Type__c, Owner_Queue_User__c, Avo_Offset__c, Avo_Offset_Type__c
            FROM Master_Review_List__c
            WHERE Id = :ids
        ];
   system.debug('re' +result);
        return result;
    }
 
    @AuraEnabled
    // Method used to create 1 or more Reviews
    public static Id createReviews(String recordId, List<String> masterReviewListIds, String sObjectName) {
        List<MUSW__Review__c> reviews = new List<MUSW__Review__c>();
        Id convertedId = Id.valueOf(recordId);
 
        List<Master_Review_List__c> selectedReviews = getMasterListInfo(masterReviewListIds);
 
        if(sObjectName == 'MUSW__Permit2__c') {
            MUSW__Permit2__c permit = [
                SELECT MUSW__Type__c, MUSW__Applicant__c
                FROM MUSW__Permit2__c 
                WHERE Id = :recordId
            ];
            // Create review object(s) to then insert it into the DB
            for(Master_Review_List__c selectedReview : selectedReviews) {
              Id recordTypeId =                 getReviewRecordTypeId(selectedReview.Record_Type__c);
              Date dueDate = Date.today();
              Integer offset =  selectedReview.Avo_Offset__c == null? 0 :  Integer.valueOf(selectedReview.Avo_Offset__c);
 
              if (selectedReview.Avo_Offset_Type__c == 'Business Days') {
                  dueDate = AvoCommon.AddBusinessDays(date.today(), offset);
              } else {
                  dueDate = dueDate.addDays( offset);
              }
 
                MUSW__Review__c review = new MUSW__Review__c(
                   RecordTypeId        = recordTypeId,
                    MUSW__Type__c  = selectedReview.Name,
                    MUSW__Permit2__c    = convertedId,
                    MUSW__Due_Date__c = dueDate
                );
                System.Debug('Start Creating Reviews1');
                AssignQueueOwner(selectedReview, review);
                reviews.add(review);
            }
            insert reviews;
        }
		
        if (sObjectName == 'MUSW__Application2__c') {
            MUSW__Application2__c application = [
                SELECT MUSW__Type__c 
                FROM MUSW__Application2__c 
                WHERE Id = :recordId
            ];
 
 
            // Create review object(s) to then insert it into the DB
            for(Master_Review_List__c selectedReview : selectedReviews) {
                Id recordTypeId =
                getReviewRecordTypeId(selectedReview.Record_Type__c) ;
                Date dueDate = Date.today();
                Integer offset =  selectedReview.Avo_Offset__c == null? 0 :  Integer.valueOf(selectedReview.Avo_Offset__c);
 
                if (selectedReview.Avo_Offset_Type__c == 'Business Days') {
                    dueDate = AvoCommon.AddBusinessDays(date.today(), offset);
                } else {
                    dueDate = dueDate.addDays( offset);
                }
 
 
                MUSW__Review__c review = new MUSW__Review__c(
                    RecordTypeId        = recordTypeId,
                    MUSW__Type__c  = selectedReview.Name,
                    MUSW__Application2__c    = convertedId,
                    MUSW__Due_Date__c = dueDate
                );
 
                
                if (selectedReview.Owner_Queue_User__c != null) {
                    List<Group> queues = [select Id, Name from Group where Type = 'Queue' and Name =:selectedReview.Owner_Queue_User__c];
                    if (queues.size() > 0) {
                        review.OwnerId = queues[0].Id;
                    }
                }
 
 
                reviews.add(review);
            }
            insert reviews;
        }
		
        // Return the first ID in the reviews. This works if 1 or more reviews are added.
        return reviews[0].id;   
    }
 
    @AuraEnabled
    public static void AssignQueueOwner(Master_Review_List__c selectedReview, MUSW__Review__c review) {
        System.Debug('Owner Queue---- ' + selectedReview.Owner_Queue_User__c);
        if (selectedReview.Owner_Queue_User__c != null) {
            List<Group> queues = [select Id, Name from Group where Type = 'Queue' and Name =:selectedReview.Owner_Queue_User__c];
 
            System.Debug('Finding Queue');
            if (queues.size() > 0) {
                System.Debug('Assign Queue');
                review.OwnerId = queues[0].Id;
            }
    	}
    }
    // Response JSON Wrapper Class
    public class ResponseJSONWrapper {
        public Id id;
        public List<Option> reviewTypeList;
    }
 
    // Object used to hold label and Id value for the reviews.
    public class Option {
        public String label;
        public String value;
    }
}