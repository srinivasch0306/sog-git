// Global class to get details of files uploaded 
global class AvoUploadedFileDetails {
    
    // Nested class to hold individual file information
    public class FileInfo {
        @AuraEnabled public String LinkingId; // ID linking the file to a Salesforce record
        @AuraEnabled public String ContentDocumentId; // Salesforce ID of the uploaded file
        @AuraEnabled public String name; // Name of the file
        @AuraEnabled public String objectType; // Type of Salesforce object the file is linked to
        @AuraEnabled public String uploadedBy; // Name of the user who uploaded the file
        @AuraEnabled public DateTime createdDate; // Date and time the file was created
        @AuraEnabled public Decimal fileSize; // Size of the file in bytes
        @AuraEnabled public String fileSizeWithUnit; // Human-readable file size (KB, MB, etc.)
        
        
        // Constructor for initializing FileInfo using Salesforce file-related objects
        public FileInfo(ContentDocumentLink cdl, ContentVersion cv, String uploadedByName) {
            this.LinkingId = cdl.LinkedEntityId;
            this.ContentDocumentId = cdl.ContentDocumentId;
            this.name = cv.Title + '.' + cv.FileExtension;
            Schema.SObjectType objectType = cdl.LinkedEntityId.getSObjectType();
            this.objectType = objectType.getDescribe().getLabel();
            //this.objectType = String.valueOf(cdl.LinkedEntityId.getSObjectType());
            this.uploadedBy = uploadedByName;
            this.createdDate = cv.CreatedDate;
            this.fileSize = cv.ContentSize; // Size in bytes
            this.fileSizeWithUnit = formatFileSize(cv.ContentSize); // Converts byte size to readable format
        }
    }
    
    // Utility method to format file size from bytes to a more readable format (KB, MB, GB)
    private static String formatFileSize(Decimal fileSizeBytes) {
        if (fileSizeBytes >= 1024 * 1024 * 1024) { // Greater than or equal to 1 GB
            Decimal fileSizeGB = fileSizeBytes / (1024.0 * 1024.0 * 1024.0);
            return fileSizeGB.setScale(2) + ' GB';
        } else if (fileSizeBytes >= 1024 * 1024) { // Greater than or equal to 1 MB
            Decimal fileSizeMB = fileSizeBytes / (1024 * 1024);
            return fileSizeMB.setScale(2) + ' MB';
        } else if (fileSizeBytes >= 1024) { // Greater than or equal to 1 KB
            Decimal fileSizeKB = fileSizeBytes / 1024.0;
            return fileSizeKB.setScale(2) + ' KB';
        } else { // Less than 1 KB
            return fileSizeBytes.setScale(2) + ' B';
        }
    }
    // Method to retrieve IDs of records that have been moved, based on a specific field and object
    public static Set<Id> fetchMovedRecordIds(String objectFieldName, String objectApiName) {
        String query = 'SELECT ' + objectFieldName + ' FROM AVO_SharePoint_File__c WHERE ' + objectFieldName + ' != null';
        List<SObject> records = Database.query(query);
        Set<Id> movedIds = new Set<Id>();
        for (SObject record : records) {
            movedIds.add((Id)record.get(objectFieldName));
        }
        return movedIds;
    }
    
    // Enum to represent types of parent records related to the files
    public enum ParentRecordType {
        Permit, Application, Contact, Account, Comment, Complaint, Violation, License,Withdrawal,Meter,Meter_Transaction,Meter_Codeset,Meter_Withdrawal,Compliance
            }
    
    // Method to convert string to corresponding enum value for ParentRecordType
    public static ParentRecordType stringToRecordType(String str) {
        for (ParentRecordType rt : ParentRecordType.values()) {
            if (rt.name().equalsIgnoreCase(str)) {
                return rt;
            }
        }
        return null; // Return null if no match is found
    }
    
    
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFilesInfo(String inputValue,String recordId) {
        Decimal totalFileSize = 0;
        String totalFileSizeWithUnit = '';
        
        // Prepare the result
        List<FileInfo> files = new List<FileInfo>();
        Set<Id> excludedContentDocumentIds = new Set<Id>();
        Set<Id> childIds = new Set<Id>();
        Set<Id> entityIds = new Set<Id>();
        ParentRecordType rt = stringToRecordType(inputValue);
        
        if (rt != null) {
            switch on rt {
                
                when Meter {
                    // Meter (Parent)
                    excludedContentDocumentIds = new Set<Id>();
                    for (AVO_SharePoint_File__c file : [
                        SELECT AVO_ContentDocumentId__c 
                        FROM AVO_SharePoint_File__c 
                        WHERE AVO_Meter__c = :recordId
                    ]) {
                        excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                    }
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId 
                        FROM ContentDocumentLink 
                        WHERE LinkedEntityId = :recordId 
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                    
                    // ===== Meter Transaction (Child) =====
                    excludedContentDocumentIds = new Set<Id>();
                    childIds = new Set<Id>();
                    
                    for (AVO_Meter_Transaction__c child : [
                        SELECT Id FROM AVO_Meter_Transaction__c 
                        WHERE AVO_Meter_ID__c = :recordId
                    ]) {
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) {
                        for (AVO_SharePoint_File__c file : [
                            SELECT AVO_ContentDocumentId__c 
                            FROM AVO_SharePoint_File__c 
                            WHERE AVO_Meter_Transaction__c IN :childIds
                        ]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId 
                            FROM ContentDocumentLink 
                            WHERE LinkedEntityId IN :childIds 
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    // ===== Meter Codeset (Child) =====
                    // 
                    // Step 1: Fetch meter record
                   excludedContentDocumentIds = new Set<Id>();
                    childIds = new Set<Id>();
                    AVO_Meter__c meter = [
                        SELECT AVO_Make__c, AVO_Model__c
                        FROM AVO_Meter__c
                        WHERE Id = :recordId
                        LIMIT 1
                    ];
                    
                    // Step 2: Determine valid Codeset ID
                    AVO_Meter_Codeset__c selectedCodeset;
                    
                    if (meter.AVO_Make__c != null) {
                        selectedCodeset = [
                            SELECT Id
                            FROM AVO_Meter_Codeset__c
                            WHERE Id = :meter.AVO_Make__c
                            LIMIT 1
                        ];
                    } else if (String.isNotBlank(meter.AVO_Model__c)) {
                        selectedCodeset = [
                            SELECT Id
                            FROM AVO_Meter_Codeset__c
                            WHERE Name = :meter.AVO_Model__c
                            LIMIT 1
                        ];
                    }
                    
                    // Step 3: Proceed if a valid codeset is found
                    if (selectedCodeset != null) {
                        childIds.add(selectedCodeset.Id);
                        
                        // Get AVO_SharePoint_File__c where AVO_Meter_Codeset__c in childIds
                        for (AVO_SharePoint_File__c file : [
                            SELECT AVO_ContentDocumentId__c 
                            FROM AVO_SharePoint_File__c 
                            WHERE AVO_Meter_Codeset__c IN :childIds
                        ]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        
                        // Get ContentDocumentLink records not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId 
                            FROM ContentDocumentLink 
                            WHERE LinkedEntityId IN :childIds 
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                  /*  excludedContentDocumentIds = new Set<Id>();
                    childIds = new Set<Id>();
                    
                    for (AVO_Meter_Codeset__c child : [
                        SELECT Id FROM AVO_Meter_Codeset__c 
                        WHERE AVO_Meter__c = :recordId
                    ]) {
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) {
                        for (AVO_SharePoint_File__c file : [
                            SELECT AVO_ContentDocumentId__c 
                            FROM AVO_SharePoint_File__c 
                            WHERE AVO_Meter_Codeset__c IN :childIds
                        ]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId 
                            FROM ContentDocumentLink 
                            WHERE LinkedEntityId IN :childIds 
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    */
                    // ===== Meter Withdrawal (Child) =====
                    excludedContentDocumentIds = new Set<Id>();
                    childIds = new Set<Id>();
                    
                    for (AVO_Meter_Withdrawal__c child : [
                        SELECT Id FROM AVO_Meter_Withdrawal__c 
                        WHERE AVO_Meter_ID__c = :recordId
                    ]) {
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) {
                        for (AVO_SharePoint_File__c file : [
                            SELECT AVO_ContentDocumentId__c 
                            FROM AVO_SharePoint_File__c 
                            WHERE AVO_Meter_Withdrawal__c IN :childIds
                        ]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId 
                            FROM ContentDocumentLink 
                            WHERE LinkedEntityId IN :childIds 
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                }
                
                
                when Permit {
                    //Permit
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Permit__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Permits and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId = :recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                    //Inspection
                    //Step 1: Reinitialize variable and find contentdocumentid which is alredy moved related to selected permit
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Inspection__c records linked to the specific MUSW__Permit__c record
                    for (MUSW__Inspection__c child : [
                        SELECT Id FROM MUSW__Inspection__c WHERE MUSW__Permit__c = :recordId
                    ]) {
                        // Add each found MUSW__Inspection__c record's ID to the 'childIds' set
                        // This collects all inspection IDs related to the specific permit for later use
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Inspection__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Inspection and not in excludedContentDocumentIds
                        
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    
                    
                    
                    //Review
                    //Step 1: Reinitialize variable and find contentdocumentid which is alredy moved related to selected permit
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Review__c records linked to the specific MUSW__Permit__c record
                    for (MUSW__Review__c child : [
                        SELECT Id FROM MUSW__Review__c WHERE MUSW__Permit2__c = :recordId
                    ]) {
                        // Add each found MUSW__Review__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Review__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Review and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    
                    //Submission
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Submission__c records linked to the specific MUSW__Permit__c record
                    for (MUSW__Submission__c child : [
                        SELECT Id FROM MUSW__Submission__c WHERE MUSW__Permit2__c = :recordId
                    ]) {
                        // Add each found MUSW__Submission__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Submission__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Submission and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    //Milestone
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Milestone__c records linked to the specific MUSW__Permit__c record
                    for (MUSW__Milestone__c child : [
                        SELECT Id FROM MUSW__Milestone__c WHERE MUSW__Permit2__c = :recordId
                    ]) {
                        // Add each found MUSW__Milestone__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Milestone__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Milestone and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    
                     //Milestone 12-06-2025
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    // Query all MUSW__Milestone__c records linked to the specific MUSW__Permit__c record
                    for (AVO_Withdrawals__c child : [
                        SELECT Id FROM AVO_Withdrawals__c WHERE AVO_Permit__c = :recordId
                    ]) {
                        // Add each found AVO_Withdrawals__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Withdrawal__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Milestone and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                }
                when Application {
                    //Application
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Application__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Application and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                    //Inspection
                    //Step 1: Reinitialize variable and find contentdocumentid which is alredy moved related to selected Application
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Inspection__c records linked to the specific Application record
                    for (MUSW__Inspection__c child : [
                        SELECT Id FROM MUSW__Inspection__c WHERE AVO_Application__c  = :recordId
                    ]) {
                        // Add each found MUSW__Inspection__c record's ID to the 'childIds' set
                        // This collects all inspection IDs related to the specific Application for later use
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Inspection__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Inspection and not in excludedContentDocumentIds
                        
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    //Review
                    //Step 1: Reinitialize variable and find contentdocumentid which is alredy moved related to selected Application
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Review__c records linked to the specific MUSW__Application__c record
                    for (MUSW__Review__c child : [
                        SELECT Id FROM MUSW__Review__c WHERE MUSW__Application2__c = :recordId
                    ]) {
                        // Add each found MUSW__Review__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Review__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Review and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    
                    //Submission
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Submission__c records linked to the specific MUSW__Application__c record
                    for (MUSW__Submission__c child : [
                        SELECT Id FROM MUSW__Submission__c WHERE MUSW__Application2__c = :recordId
                    ]) {
                        // Add each found MUSW__Submission__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Submission__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Submission and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    //Milestone
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Milestone__c records linked to the specific MUSW__Application__c record
                    for (MUSW__Milestone__c child : [
                        SELECT Id FROM MUSW__Milestone__c WHERE MUSW__Application2__c = :recordId
                    ]) {
                        // Add each found MUSW__Milestone__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Milestone__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Milestone and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                }
                when License {
                    //License
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_License__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to License and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                    //Inspection
                    //Step 1: Reinitialize variable and find contentdocumentid which is alredy moved related to selected License
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Inspection__c records linked to the specific License record
                    for (MUSW__Inspection__c child : [
                        SELECT Id FROM MUSW__Inspection__c WHERE MUSW__License2__c   = :recordId
                    ]) {
                        // Add each found MUSW__Inspection__c record's ID to the 'childIds' set
                        // This collects all inspection IDs related to the specific License for later use
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Inspection__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Inspection and not in excludedContentDocumentIds
                        
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    
                    //Review
                    //Step 1: Reinitialize variable and find contentdocumentid which is alredy moved related to selected License
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Review__c records linked to the specific MUSW__License__c record
                    for (MUSW__Review__c child : [
                        SELECT Id FROM MUSW__Review__c WHERE MUSW__License2__c = :recordId
                    ]) {
                        // Add each found MUSW__Review__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Review__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Review and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    
                    //Submission
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Submission__c records linked to the specific MUSW__License__c record
                    for (MUSW__Submission__c child : [
                        SELECT Id FROM MUSW__Submission__c WHERE MUSW__License2__c = :recordId
                    ]) {
                        // Add each found MUSW__Submission__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Submission__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Submission and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    //Milestone
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Milestone__c records linked to the specific MUSW__License__c record
                    for (MUSW__Milestone__c child : [
                        SELECT Id FROM MUSW__Milestone__c WHERE MUSW__License2__c = :recordId
                    ]) {
                        // Add each found MUSW__Milestone__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Milestone__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Milestone and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    
                    
                }
                when Complaint {
                    
                    //Complaint
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Complaint__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Complaint and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                    //Inspection
                    //Step 1: Reinitialize variable and find contentdocumentid which is alredy moved related to selected Complaint
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Inspection__c records linked to the specific Complaint record
                    for (MUSW__Inspection__c child : [
                        SELECT Id FROM MUSW__Inspection__c WHERE MUSW__Complaint2__c   = :recordId
                    ]) {
                        // Add each found MUSW__Inspection__c record's ID to the 'childIds' set
                        // This collects all inspection IDs related to the specific Complaint for later use
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Inspection__c IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Inspection and not in excludedContentDocumentIds
                        
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                    //Violations
                    //Step 1: Reinitialize variable and find contentdocumentid which is alredy moved related to selected Complaint
                    excludedContentDocumentIds = new Set<Id>(); // Reinitialize excludedContentDocumentIds 
                    childIds = new Set<Id>(); // Reinitialize childIds
                    
                    
                    // Query all MUSW__Violations__c records linked to the specific MUSW__Complaint__c record
                    for (MUSW__Violation__c   child : [
                        SELECT Id FROM MUSW__Violation__c   WHERE MUSW__Complaint2__c = :recordId
                    ]) {
                        // Add each found MUSW__Violations__c record's ID to the 'childIds' set
                        childIds.add(child.Id);
                    }
                    
                    if (!childIds.isEmpty()) { // Check to ensure there are IDs to query against
                        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Violation__c  IN :childIds]) {
                            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
                        }
                        // Step 2: Retrieve ContentDocumentLink records linked to Violations and not in excludedContentDocumentIds
                        for (ContentDocumentLink link : [
                            SELECT LinkedEntityId
                            FROM ContentDocumentLink
                            WHERE LinkedEntityId IN:childIds
                            AND ContentDocumentId NOT IN :excludedContentDocumentIds
                        ]) {
                            entityIds.add(link.LinkedEntityId);
                        }
                    }
                    
                }
                when Violation {
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Violation__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Complaint and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                    
                    
                    
                }
                when Contact {
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Contact__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Contacts and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                }
                when Account {
                    
                    
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Account__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Accounts and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                }
                when Comment {
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Comment__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Comment and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                }
                when Withdrawal {
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Withdrawal__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Contacts and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                }
                when Compliance {
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Compliance__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
                    }
                    
                    // Step 2: Retrieve ContentDocumentLink records linked to Contacts and not in excludedContentDocumentIds
                    
                    for (ContentDocumentLink link : [
                        SELECT LinkedEntityId
                        FROM ContentDocumentLink
                        WHERE LinkedEntityId =:recordId
                        AND ContentDocumentId NOT IN :excludedContentDocumentIds
                    ]) {
                        entityIds.add(link.LinkedEntityId);
                    }
                }
                /* when Meter {
// Step 1: Query ContentDocumentId from AVO_SharePoint_File__c

for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Meter__c = :recordId]) {
excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
}

// Step 2: Retrieve ContentDocumentLink records linked to Contacts and not in excludedContentDocumentIds

for (ContentDocumentLink link : [
SELECT LinkedEntityId
FROM ContentDocumentLink
WHERE LinkedEntityId =:recordId
AND ContentDocumentId NOT IN :excludedContentDocumentIds
]) {
entityIds.add(link.LinkedEntityId);
}
}
when Meter_Transaction {
// Step 1: Query ContentDocumentId from AVO_SharePoint_File__c

for (AVO_SharePoint_File__c file : [SELECT AVO_contentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Meter_Transaction__c = :recordId]) {
excludedContentDocumentIds.add(file.AVO_contentDocumentId__c);
}

// Step 2: Retrieve ContentDocumentLink records linked to Contacts and not in excludedContentDocumentIds

for (ContentDocumentLink link : [
SELECT LinkedEntityId
FROM ContentDocumentLink
WHERE LinkedEntityId =:recordId
AND ContentDocumentId NOT IN :excludedContentDocumentIds
]) {
entityIds.add(link.LinkedEntityId);
}
}*/
                
                when else {
                    // Handle the default case (this should technically never hit if all enum cases are covered)
                    System.debug('Handling default case');
                }
            }
        } else {
            // Handle the case where the string does not map to any enum value
            System.debug('Unknown Record Type');
        }
        
        
        System.debug('size:'+ entityIds.size());
        if (entityIds.size() > 0) {
            // Fetch ContentDocumentLink records linked to the fetched entities
            List<ContentDocumentLink> cdls = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :entityIds];
            
            // Collect the IDs of the documents linked to the specified entities
            Set<Id> documentIds = new Set<Id>();
            
            for (ContentDocumentLink cdl : cdls) {
                documentIds.add(cdl.ContentDocumentId);
            }
            
            
            if (!documentIds.isEmpty()) {
                
                // Pre-fetch the necessary users based on CreatedById from ContentVersions
                Set<Id> userIds = new Set<Id>();
                for (ContentVersion cv : [SELECT CreatedById FROM ContentVersion WHERE ContentDocumentId IN :documentIds AND IsLatest = true]) {
                    userIds.add(cv.CreatedById);
                }
                Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :userIds]);
                
                // Fetch the latest ContentVersion records
                List<ContentVersion> cvs = [SELECT ContentDocumentId, Title, CreatedById, CreatedDate, ContentSize,FileExtension  FROM ContentVersion WHERE ContentDocumentId IN :documentIds AND IsLatest = true];
                
                // Create a map from ContentDocumentId to ContentDocumentLink for faster lookup
                Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>();
                for (ContentDocumentLink cdl : cdls) {
                    cdlMap.put(cdl.ContentDocumentId, cdl);
                }
                
                // Iterate over ContentVersions and map them with ContentDocumentLinks
                for (ContentVersion cv : cvs) {
                    ContentDocumentLink cdl = cdlMap.get(cv.ContentDocumentId);
                    if (cdl != null) {
                        String uploadedByName = userMap.containsKey(cv.CreatedById) ? userMap.get(cv.CreatedById).Name : 'Unknown User';
                        FileInfo fileInfo = new FileInfo(cdl, cv, uploadedByName);
                        files.add(fileInfo);
                        
                        totalFileSize += fileInfo.filesize; // example modification
                    }
                }
                
            }
        }
        
        
        
        
        // Ensure there are IDs to search for to prevent SOQL injection
        if (files.isEmpty()) {
            return new Map<String, Object>{
                'numberOfFiles' => 0,
                    'totalFileSize' => 0,
                    'files' => new List<FileInfo>()
                    };
                        }
        if(totalFileSize > 0)
        {
            totalFileSizeWithUnit = formatFileSize(totalFileSize); // Call the function to format file size
        }
        // Return the results
        Map<String, Object> results = new Map<String, Object>();
        results.put('numberOfFiles', files.size());
        results.put('totalFileSize', totalFileSizeWithUnit); 
        results.put('files', files);
        return results;
        
        
    }
    @AuraEnabled(cacheable=false)
    public static void SendFileDetails(String linkingId,String contentDocumentId) {
        try {
            //String linkingId,String contentDocumentId
            // String linkingId ='0017700000JdcfVAAR';
            // String contentDocumentId='06977000000WLJIAA4';
            // Check if linkingId and contentDocumentId are not null
            if (linkingId != null && contentDocumentId != null) {
                //System.debug('linkingId'+linkingId+'ContentDocumentId'+contentDocumentId); 
                // Query ContentDocumentLink records based on linkingId and contentDocumentId
                List<ContentDocumentLink> documents = [
                    SELECT Id, ContentDocumentId, LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :linkingId
                    AND ContentDocumentId = :contentDocumentId
                ];
                // Iterate through each document and call the transferBegin function
                for (ContentDocumentLink document : documents) {
                    System.debug('Iterate transferBegin'+document.ContentDocumentId); 
                    AvoSharePointUtil.transferBegin(document); // transferBegin accepts a ContentDocumentLink object
                }
                
                
            } else {
                System.debug('linkingId and contentDocumentId cannot be null');
                
            }
            
        } catch(Exception e) {
            String errorMessage = e.getMessage(); // Get the error message
            String errorDetails = e.getStackTraceString(); // Get error details
            // Call the existing log method to log the error
            AvoLogUtils.log(errorMessage, errorDetails, 'ERROR', null);
            throw new AuraHandledException(errorMessage); // Rethrow the exception to display it in the UI
        }
    }
    
}