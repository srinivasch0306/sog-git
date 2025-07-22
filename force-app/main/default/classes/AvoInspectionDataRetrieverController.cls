/// pre-requisites
/// MUSW__Master_Inspection_List__c should have the following fields:
/// Avo_Permit_Type__c
/// Avo_Active__c
/// Avo_Manual_Creation_Allowed__c

/// Avo_Planning_Application_Type__c
/// Avo_Complaint_Type__c
/// version 1.0
public class AvoInspectionDataRetrieverController {
    // Method that returns the supported inspection types for a specific Record ID.
    // The return value should be in a CSV format for multiple inspection types

    static boolean InspectionAllowedForPermit  = false;
    static boolean InspectionAllowedForApplication = false;
    static boolean InspectionAllowedForComplaint = false;
    static boolean InspectionAllowedForViolation = false;

    private static void getSettingsFromMetedata()
    {
        List<Avocette_Settings__mdt> avocetteSettings = Avocette_Settings__mdt.getAll().values();

        For(Avocette_Settings__mdt mdt:avocetteSettings)
        {
            if (mdt.label == 'InspectionForPermit' && mdt.Boolean_Value__c == true)
                InspectionAllowedForPermit = true;
            if (mdt.label == 'InspectionForApplication' && mdt.Boolean_Value__c == true)
                InspectionAllowedForApplication = true;
            if (mdt.label == 'InspectionForComplaint' && mdt.Boolean_Value__c == true)
                InspectionAllowedForComplaint = true;
            if (mdt.label == 'InspectionForViolation' && mdt.Boolean_Value__c == true)
                InspectionAllowedForViolation = true;
    }

    }

    @AuraEnabled
    public static String getAllowedInspectionTypes(Id recordId, String sObjectName) {   
        getSettingsFromMetedata();
        
        String response = '';
        ResponseJSONWrapper wrapper = new ResponseJSONWrapper();
        List<MUSW__Master_Inspection_List__c> inspectionTypes;

        // step 1 - get a list of allowed inspection types
        if(sObjectName == 'MUSW__Permit2__c') {
            if (InspectionAllowedForPermit == true) {
                // get the Permit Type and Id
                MUSW__Permit2__c permit = [
                    SELECT Id, MUSW__Type__c
                    FROM MUSW__Permit2__c
                    WHERE Id = :recordId
                ];
                String permitType = permit.MUSW__Type__c;
                // Get the Master Inspection List items that include the Permit Type
                inspectionTypes = [
                    SELECT Name, Id 
                    FROM MUSW__Master_Inspection_List__c 
                    WHERE Avo_Permit_Type__c includes (:permitType)
                        AND Avo_Active__c = true 
                        AND Avo_Manual_Creation_Allowed__c = true 
                    ORDER BY Name ASC 
                ];
            } else {
                string error = 'Inspection creation for Permit is not allowed. Check metadata setup "Avocette Settings"';
                System.debug(error);
                throw new AuraHandledException(error);
            }
        } else if (sObjectName == 'MUSW__Violation__c' ) {
            if (InspectionAllowedForViolation == true) {
                // Get the Master Inspection List items that include the Application Type
                inspectionTypes = [
                    SELECT Name, Id 
                    FROM MUSW__Master_Inspection_List__c 
                    WHERE  Avo_Active__c = true
                    AND Avo_Manual_Creation_Allowed__c = true
                    AND Avo_Violation_Type__c != null
                    ORDER BY Name ASC 
                ];
            }
            else {
                string error = 'Inspection creation for Viloation is not allowed. Check metadata setup "Avocette Settings"';
                System.debug(error);
                throw new AuraHandledException(error);
            }
        }

        wrapper.id = recordId;
        wrapper.inspectionTypeList = new List<Option>();

        for(MUSW__Master_Inspection_List__c inspectionType:inspectionTypes)
        {
            Option option = new Option();

            option.label = inspectionType.Name;
            option.value = inspectionType.Id;
            
            // Adding Option objects (label & value) into the inspectionTypeList
            wrapper.inspectionTypeList.Add(option);
        }
        system.debug('get'+JSON.serialize(wrapper));
        response = JSON.serialize(wrapper);

        return response;
    }   

    @AuraEnabled
    // Helper function used to determine the record type of the inspection being created. The return record type will determine a different layout and dropdown listbox values for the inspection to be created
    public static Id getInspectionRecordTypeId(String masterInspectionListId) {
    
        try {
            List<MUSW__Master_Inspection_List__c> results = [
                SELECT Record_Type__c 
                FROM MUSW__Master_Inspection_List__c 
                WHERE Id = :masterInspectionListId 	 
                LIMIT 1] ; 
            
            If (results.size() == 1) {
                Id recordTypeId = Schema.SObjectType.MUSW__Inspection__c.getRecordTypeInfosByName().get(results[0].Record_Type__c).getRecordTypeId();
                return recordTypeId;    
            } else {
                return Schema.SObjectType.MUSW__Inspection__c.getRecordTypeInfosByName().get('eb Inspection Default').getRecordTypeId();
            } 
        } catch (Exception ex) {
            System.Debug('Failed to retrieve fee record type: ' + masterInspectionListId);
            return Schema.SObjectType.MUSW__Inspection__c.getRecordTypeInfosByName().get('eb Inspection Default').getRecordTypeId();
        }
    }

    @AuraEnabled
    // Helper function used to get the Master Inspection List item's name based off of the Master Inspection List ID
    public static String getInspectionName(String masterInspectionListId) {
        List<MUSW__Master_Inspection_List__c> recordTypeId = [
            SELECT Name
            FROM MUSW__Master_Inspection_List__c
            WHERE Id = :masterInspectionListId
        ];
        return recordTypeId[0].Name;
    }

    @AuraEnabled
    // Helper function used to get the Master Fee List item's Amount Value and convert it to an Integer
    public static List<MUSW__Master_Inspection_List__c> getInspectionInformation(List<String> masterListIds) {
        List<MUSW__Master_Inspection_List__c> results = [
            SELECT Name, Id
            FROM MUSW__Master_Inspection_List__c
            WHERE Id = :masterListIds
        ];
        return results;
    }

    @AuraEnabled
    // Helper function used to determine the record type of the inspection being created. The return record type will determine a different layout and dropdown listbox values for the inspection to be created
    public static Map<Id, Id> getInspectionRecordTypeIds(List<String> masterListIds) {
        Id defaultRecordTypeId = [
            SELECT Id
            FROM   RecordType
            WHERE  SObjectType = 'MUSW__Inspection__c'
            AND    Name = 'Site Visit Request'
            LIMIT  1
        ].Id;
        Map<Id, Id> results = new Map<Id, Id>();
      
        List<MUSW__Master_Inspection_List__c> inspections = [
            SELECT Record_Type__c 
            FROM MUSW__Master_Inspection_List__c 
            WHERE Id = :masterListIds ] ; 
        If (inspections.size() > 0) {
            for(MUSW__Master_Inspection_List__c item: inspections) {
                try {
                    Id recordTypeId = Schema.SObjectType.MUSW__Inspection__c.getRecordTypeInfosByName().get(item.Record_Type__c).getRecordTypeId();
                    results.put(item.id, recordTypeId);
                } catch (Exception ex) {
                    System.Debug('Failed to retrieve fee record type: ' + item.id);
                    results.put(item.id, defaultRecordTypeId);
                }
            }
        } 
        return results;        
    }
    
    @AuraEnabled
    // Method used to create 1 or more Inspections
    public static Id createInspections(String recordId, List<String> masterInspectionListIds, String sObjectName) {
        List<MUSW__Inspection__c> inspections = new List<MUSW__Inspection__c>();
        Id convertedId = Id.valueOf(recordId);

        List<MUSW__Master_Inspection_List__c> selectedInspections = getInspectionInformation(masterInspectionListIds);
        Map<Id, Id> recordTypeIds = getInspectionRecordTypeIds(masterInspectionListIds);

        
        for(MUSW__Master_Inspection_List__c item : selectedInspections) {

            Id recordTypeId = recordTypeIds.get(item.id);
            MUSW__Inspection__c inspection = new MUSW__Inspection__c(
                RecordTypeId       = recordTypeId,
                MUSW__Type__c      = item.Name
            );

            if(sObjectName == 'MUSW__Permit2__c') {
                MUSW__Permit2__c permit = [
                    SELECT MUSW__Type__c , MUSW__Parcel__c, MUSW__Address__c
                    FROM MUSW__Permit2__c 
                    WHERE Id = :recordId
                ];
                inspection.MUSW__Permit__c = convertedId;
                inspection.MUSW__Parcel__c = permit.MUSW__Parcel__c;
                inspection.MUSW__Address__c = permit.MUSW__Address__c;                
            }

            if(sObjectName == 'MUSW__Violation__c') {
                inspection.Avo_Violation__c  = convertedId;
            }
            inspections.add(inspection);
        }

        insert inspections;
        // Return the first ID in the inspections. This works if 1 or more inspections are added.
        return inspections[0].id;
    }
    
    // Response JSON Wrapper Class
    public class ResponseJSONWrapper {
        public Id id;
        public List<Option> inspectionTypeList;
    }

    // Object used to hold label and Id value for the inspections.
    public class Option {
        public String label;
        public String value;
    }
}