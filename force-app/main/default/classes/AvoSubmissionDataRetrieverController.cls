/**
 * Apex Controller used in AvoNewSubmissionController.js. Makes calls to GET and POST data for Submission Objects.
 * @author Michael Chung
 * last modified by Michael Chung
 * @date 05/13/2021
 * 
 */

public class AvoSubmissionDataRetrieverController {
// Method that returns the supported submission types for a specific Record ID.
    // The return value should be in a CSV format for multiple submission types
    @AuraEnabled
    public static String getAllowedSubmissionTypes(Id recordId, String sObjectName) {   
        String response = '';
        ResponseJSONWrapper wrapper = new ResponseJSONWrapper();
        List<MUSW__Master_Submission_List__c> submissionTypes;

        // step 1 - get a list of allowed submission types
        if(sObjectName == 'MUSW__Permit2__c') {
            // get the Permit Type and Id
            MUSW__Permit2__c permit = [
                SELECT Id, MUSW__Type__c
                FROM MUSW__Permit2__c
                WHERE Id = :recordId
            ];

            String permitType = permit.MUSW__Type__c;

            // Get the Master Submission List items that include the Permit Type
            submissionTypes = [
                SELECT Name, Id 
                FROM MUSW__Master_Submission_List__c 
                WHERE Avo_Permit_Type__c includes (:permitType)
                AND Active__c = true
                AND Manual_Creation_Allowed__c = true 
                ORDER BY Name ASC 
            ];
        }
        // step 2 - get a list of allowed submission types
        if(sObjectName == 'AVO_Compliance__c') {
            // get the Permit Type and Id
            AVO_Compliance__c Compliance = [
                SELECT Id,
                	   AVO_Type__c ,
                       AVO_CaseClass__c
                FROM AVO_Compliance__c
                WHERE Id = :recordId
            ];

            String complianceType = Compliance.AVO_Type__c;
			String caseClass = Compliance.AVO_CaseClass__c;

            // Get the Master Submission List items that include the Permit Type
            submissionTypes = [
                SELECT Name, Id 
                FROM MUSW__Master_Submission_List__c 
                WHERE Avo_Compliance_Type__c includes (:complianceType)
				AND AVO_Case_Class__c includes (:caseClass)  
                AND Active__c = true
                AND Manual_Creation_Allowed__c = true 
                ORDER BY Name ASC 
            ];
        }
        else{}

        wrapper.id = recordId;
        wrapper.submissionTypeList = new List<Option>();
    system.debug('only'+submissionTypes);
        for(MUSW__Master_Submission_List__c submissionType:submissionTypes)
        {
            Option option = new Option();

            option.label = submissionType.Name;
            option.value = submissionType.Id;
            
            // Adding Option objects (label & value) into the submissionTypeList
            wrapper.submissionTypeList.Add(option);
        }
        
        response = JSON.serialize(wrapper);
        system.debug('response'+response);

        return response;
    }   

    @AuraEnabled
    // Helper function used to determine the record type of the submission being created. The return record type will determine a different layout and dropdown listbox values for the submission to be created
    public static Id getSubmissionRecordTypeId(String masterSubmissionListId) {
        system.debug('Test'+ masterSubmissionListId);
            List<MUSW__Master_Submission_List__c> results = [
                SELECT Record_Type__c,RecordTypeId,RecordType.Name 
                FROM MUSW__Master_Submission_List__c
                WHERE Id =:masterSubmissionListId 	 
                LIMIT 1] ; 
            If (results.size() == 1) {
                
                Id recordTypeId = Schema.SObjectType.MUSW__Master_Submission_List__c.getRecordTypeInfosByName().get(results[0].RecordType.Name).getRecordTypeId();
                // MUSW__Submission__c to MUSW__Master_Submission_List__c
                 system.debug('Test'+recordTypeId);
                return recordTypeId;    
            } else {
                return Schema.SObjectType.MUSW__Master_Submission_List__c.getRecordTypeInfosByName().get('eb Submission Default').getRecordTypeId();
            } 
        //} catch (Exception ex) {
         //   return Schema.SObjectType.MUSW__Master_Submission_List__c.getRecordTypeInfosByName().get('Avo Submission Default').getRecordTypeId();
        //}
    }

    @AuraEnabled
    // Helper function used to get the Master Submission List item's name based off of the Master Submission List ID
    public static MUSW__Master_Submission_List__c getSubmissionInformation(String masterSubmissionListId) {
        system.debug('masterSubmissionListId>>>'+masterSubmissionListId);
        List<MUSW__Master_Submission_List__c> recordTypeId = [
            SELECT Name, Avo_Offset__c, Avo_Offset_Type__c,Required__c
            FROM MUSW__Master_Submission_List__c
            WHERE Id = :masterSubmissionListId
        ];

        return recordTypeId[0];
    }

    @AuraEnabled
    public static date CalculateDueDate(MUSW__Master_Submission_List__c item) {
        Date dueDate = Date.today();
        Integer offset =  item.Avo_Offset__c  == null? 0 :  Integer.valueOf(item.Avo_Offset__c);

        if (item.Avo_Offset_Type__c == 'Business Days') {
            dueDate = AvoCommon.AddBusinessDays(date.today(), offset);
        } else {
            dueDate = dueDate.addDays( offset);
        }

        return dueDate;
    }

 
    
    @AuraEnabled
    // Method used to create 1 or more Submissions
    public static Id createSubmissions(String recordId, List<String> masterSubmissionListIds, String sObjectName) {
        List<MUSW__Submission__c> submissions = new List<MUSW__Submission__c>();
        Id convertedId = Id.valueOf(recordId);
   system.debug('get'+recordId);
            system.debug('get1'+masterSubmissionListIds);

        if(sObjectName == 'MUSW__Permit2__c') {
            MUSW__Permit2__c permit = [
                SELECT MUSW__Type__c 
                FROM MUSW__Permit2__c 
                WHERE Id = :recordId
            ];
            //system.debug('get'+recordId);
           // system.debug('get1'+masterSubmissionListIds);
            // Create submission object(s) to then insert it into the DB
            for(String masterSubmissionListId : masterSubmissionListIds) {

                MUSW__Master_Submission_List__c item = getSubmissionInformation(masterSubmissionListId);
                
                MUSW__Submission__c submission = new MUSW__Submission__c(
                  //  Avo_Type__c  = item.Name,
                    MUSW__Permit2__c = convertedId,
                    Name = item.Name,
                    MUSW__Submission_Template__c = masterSubmissionListId,
                    MUSW__Requested_DateTime__c = DateTime.now(),
                    MUSW__Due_Date__c =  CalculateDueDate(item),
                    MUSW__Required__c = item.Required__c
                );
                submissions.add(submission);
            }
            insert submissions;
        }
 
  //For Compliance     
       if(sObjectName == 'AVO_Compliance__c') {
            AVO_Compliance__c permit = [
                SELECT AVO_Type__c 
                FROM AVO_Compliance__c 
                WHERE Id = :recordId
            ];
            //system.debug('get'+recordId);
           // system.debug('get1'+masterSubmissionListIds);
            // Create submission object(s) to then insert it into the DB
            for(String masterSubmissionListId : masterSubmissionListIds) {

                MUSW__Master_Submission_List__c item = getSubmissionInformation(masterSubmissionListId);
                
                MUSW__Submission__c submission = new MUSW__Submission__c(
                  //  Avo_Type__c  = item.Name,
                    AVO_Compliance__c = convertedId,
                    Name = item.Name,
                    MUSW__Submission_Template__c = masterSubmissionListId,
                    MUSW__Requested_DateTime__c = DateTime.now(),
                    MUSW__Due_Date__c =  CalculateDueDate(item),
                    MUSW__Required__c = item.Required__c
                );
                submissions.add(submission);
            }
            insert submissions;
        }

       /* if (sObjectName == 'MUSW__Application2__c') {
            MUSW__Application2__c application = [
                SELECT MUSW__Type__c 
                FROM MUSW__Application2__c 
                WHERE Id = :recordId
            ];
            // Create submission object(s) to then insert it into the DB
            for(String masterSubmissionListId : masterSubmissionListIds) {

                MUSW__Master_Submission_List__c item = getSubmissionInformation(masterSubmissionListId);

                MUSW__Submission__c submission = new MUSW__Submission__c(
                  //  Avo_Type__c       = item.Name,
                    MUSW__Application2__c        = convertedId,
                    Name = item.Name,
                    MUSW__Submission_Template__c = masterSubmissionListId,
                    MUSW__Requested_DateTime__c = DateTime.now(),
                    MUSW__Due_Date__c =  CalculateDueDate(item)
                );
                submissions.add(submission);
            }
            insert submissions;
        }*/
        // Return the first ID in the submissions. This works if 1 or more submissions are added.
        return submissions[0].id;
    }
 
    // Method used to create 1 or more Submissions
 	@AuraEnabled
    public static Id createSubmissionsWithConfig(String recordId, Map<String, boolean> masterListIdConfig, String sObjectName) {
        List<MUSW__Submission__c> submissions = new List<MUSW__Submission__c>();
        Id convertedId = Id.valueOf(recordId);
 

        if(sObjectName == 'MUSW__Permit2__c') {
            MUSW__Permit2__c permit = [
                SELECT MUSW__Type__c 
                FROM MUSW__Permit2__c 
                WHERE Id = :recordId
            ];
            // Create submission object(s) to then insert it into the DB
            for(String masterSubmissionListId : masterListIdConfig.keySet()) {

                MUSW__Master_Submission_List__c item = getSubmissionInformation(masterSubmissionListId);

                MUSW__Submission__c submission = new MUSW__Submission__c(
                 //   Avo_Type__c  = item.Name,
                    MUSW__Permit2__c        = convertedId,
                    Name = item.Name,
                    MUSW__Required__c = masterListIdConfig.get(masterSubmissionListId),
                    MUSW__Submission_Template__c = masterSubmissionListId,
                    MUSW__Requested_DateTime__c = DateTime.now(),
                    MUSW__Due_Date__c =CalculateDueDate(item)
                );
                submissions.add(submission);
            }
            insert submissions;
        }
        
  //For Compliance     
        if(sObjectName == 'AVO_Compliance__c') {
            AVO_Compliance__c permit = [
                SELECT AVO_Type__c 
                FROM AVO_Compliance__c 
                WHERE Id = :recordId
            ];
            // Create submission object(s) to then insert it into the DB
            for(String masterSubmissionListId : masterListIdConfig.keySet()) {

                MUSW__Master_Submission_List__c item = getSubmissionInformation(masterSubmissionListId);

                MUSW__Submission__c submission = new MUSW__Submission__c(
                 //   Avo_Type__c  = item.Name,
                    AVO_Compliance__c = convertedId,
                    Name = item.Name,
                    MUSW__Required__c = masterListIdConfig.get(masterSubmissionListId),
                    MUSW__Submission_Template__c = masterSubmissionListId,
                    MUSW__Requested_DateTime__c = DateTime.now(),
                    MUSW__Due_Date__c =CalculateDueDate(item)
                );
                submissions.add(submission);
            }
            insert submissions;
        }


      /*  if (sObjectName == 'MUSW__Application2__c') {
            MUSW__Application2__c application = [
                SELECT MUSW__Type__c 
                FROM MUSW__Application2__c 
                WHERE Id = :recordId
            ];
            // Create submission object(s) to then insert it into the DB
            for(String masterSubmissionListId : masterListIdConfig.keySet()) {

                MUSW__Master_Submission_List__c item = getSubmissionInformation(masterSubmissionListId);

                MUSW__Submission__c submission = new MUSW__Submission__c(
                    Avo_Type__c       = item.Name,
                    MUSW__Application2__c        = convertedId,
                    Name = item.Name,
                    MUSW__Required__c = masterListIdConfig.get(masterSubmissionListId),
                    MUSW__Submission_Template__c = masterSubmissionListId,
                    MUSW__Requested_DateTime__c = DateTime.now(),
                    MUSW__Due_Date__c =  CalculateDueDate(item)
                );
                submissions.add(submission);
            }
            insert submissions;
        } */
        // Return the first ID in the submissions. This works if 1 or more submissions are added.
        return submissions[0].id;
    }
    
    // Response JSON Wrapper Class
    public class ResponseJSONWrapper {
        public Id id;
        public List<Option> submissionTypeList;
    }

    // Object used to hold label and Id value for the submissions.
    public class Option {
        public String label;
        public String value;
    }
}