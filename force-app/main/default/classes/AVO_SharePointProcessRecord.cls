public with sharing class AVO_SharePointProcessRecord {
    // Retrieve settings from a custom setting for SharePoint integration
    static AVO_Rest_API_Settings__c settings = AVO_Rest_API_Settings__c.getOrgDefaults();
    
    // Static variables to hold the SharePoint configuration details    
    static string clientId = settings.AVO_Client_ID__c;
    static string clientSecret = settings.AVO_Client_Secret__c;
    static string grantType = settings.AVO_Grant_Type__c;
    static string resource = settings.AVO_Resource__c;
    static string siteUrl = settings.AVO_Site_Url__c;
    // static string siteBaseUrl = settings.AVO_Site_Base_Url__c;
    static string tokenEndPoint = settings.AVO_Token_End_Point__c;
    static string accessToken = '';
    static string Directory = settings.AVO_Base_Directory__c;
    static string salesforceURL = settings.AVO_Salesforce_URL__c;
    static Boolean  IsSharePointIntegration = settings.AVO_SharePoint_Integration__c;
    
    
    @InvocableMethod
    public static void processRecord(List<Id> recordIds) {
        if (!recordIds.isEmpty()) {
            Id recordId = recordIds[0];
            System.debug('Debug: ' + recordId);
            getFilesInfo( 'Permit',recordId);
        }
    }
    
     
    
    // @AuraEnabled(cacheable=true)
   /* public static void getFilesInfo(String inputValue, String recordId) {
        System.debug('Debug: ' + recordId);
        List<FileInfo> files = new List<FileInfo>();
        
        ParentRecordType rt = stringToRecordType(inputValue);
        if (rt == null) {
            System.debug('Unknown Record Type');
            return;
        }
        
        Set<Id> excludedContentDocumentIds = new Set<Id>();
        for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Permit__c = :recordId]) {
            excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
        }
        
        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId AND ContentDocumentId NOT IN :excludedContentDocumentIds
        ];
        
        if (cdls.isEmpty()) return;
        
        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdls) {
            documentIds.add(cdl.ContentDocumentId);
        }
        
        Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdl : cdls) {
            cdlMap.put(cdl.ContentDocumentId, cdl);
        }
        
        for (ContentVersion cv : [
            SELECT ContentDocumentId FROM ContentVersion
            WHERE ContentDocumentId IN :documentIds AND IsLatest = true
        ]) {
            ContentDocumentLink cdl = cdlMap.get(cv.ContentDocumentId);
            if (cdl != null) {
                files.add(new FileInfo(cdl, cv));
            }
        }
        for (FileInfo file : files) {
            System.debug('Debug: ' + file.contentDocumentId);
            sendFileDetails(file.contentDocumentId, file.linkingId);
            System.debug('Debug: ' + file.linkingId);
        }
    }*/
   public static Map<String, Object> getFilesInfo(String inputValue, String recordId) {
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
                    
                   
                    
                }
                when Application {
                    //Application
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Application__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
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
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_License__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
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
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Complaint__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
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
                    
                    for (AVO_SharePoint_File__c file : [SELECT AVO_ContentDocumentId__c FROM AVO_SharePoint_File__c WHERE AVO_Violation__c = :recordId]) {
                        excludedContentDocumentIds.add(file.AVO_ContentDocumentId__c);
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
                when Meter {
                    // Step 1: Query ContentDocumentId from AVO_SharePoint_File__c
                    System.debug('Object: Meter');
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
                     System.debug('Object: Meter_Transaction');
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
                }
                
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
                Set<Id> userIds = new Set<Id>();
                for (ContentVersion cv : [SELECT CreatedById FROM ContentVersion WHERE ContentDocumentId IN :documentIds AND IsLatest = true]) {
                    userIds.add(cv.CreatedById);
                }
                Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :userIds]);
                
                List<ContentVersion> cvs = [
                    SELECT ContentDocumentId, Title, CreatedById, CreatedDate, FileExtension 
                    FROM ContentVersion WHERE ContentDocumentId IN :documentIds AND IsLatest = true
                ];
                
                Map<Id, ContentDocumentLink> cdlMap = new Map<Id, ContentDocumentLink>();
                for (ContentDocumentLink cdl : cdls) {
                    cdlMap.put(cdl.ContentDocumentId, cdl);
                }
                
                for (ContentVersion cv : cvs) {
                    ContentDocumentLink cdl = cdlMap.get(cv.ContentDocumentId);
                    if (cdl != null) {
                        String uploadedByName = userMap.containsKey(cv.CreatedById) ? userMap.get(cv.CreatedById).Name : 'Unknown User';
                        FileInfo fileInfo = new FileInfo(cdl, cv);
                        files.add(fileInfo);
                        
                        sendFileDetails(fileInfo.contentDocumentId, fileInfo.linkingId);
                    }
                }
            }
        }
   
            
            return new Map<String, Object>{
                'numberOfFiles' => files.size(),
                    'files' => files
                    };
                        }


    //@AuraEnabled(cacheable=false)
    public static void sendFileDetails(String contentDocumentId, String linkingId) {
        if (String.isEmpty(contentDocumentId) || String.isEmpty(linkingId)) return;
        try {
            for (ContentDocumentLink document : [
                SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink
                WHERE LinkedEntityId = :linkingId AND ContentDocumentId = :contentDocumentId
            ]) {
                transferBegin(document);
                System.debug('Debug: Transferred' );
            }
        } catch (Exception e) {
            AvoLogUtils.log(e.getMessage(), e.getStackTraceString(), 'ERROR', null);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class FileInfo {
        @AuraEnabled public String linkingId;
        @AuraEnabled public String contentDocumentId;
        
        public FileInfo(ContentDocumentLink cdl, ContentVersion cv) {
            this.linkingId = cdl.LinkedEntityId;
            this.contentDocumentId = cv.ContentDocumentId;
        }
    }
    
    public enum ParentRecordType { Permit, Application, Contact, Account, Comment, Complaint, Violation, License, Withdrawal, Meter, Meter_Transaction }
    
    public static ParentRecordType stringToRecordType(String str) {
        for (ParentRecordType rt : ParentRecordType.values()) {
            if (rt.name().equalsIgnoreCase(str)) return rt;
        }
        return null;
    }
    public static void transferBegin(ContentDocumentLink doc)
    {
        try	
        {
            // Process begins here for different Salesforce object types (e.g., Account, Contact, etc.).
            // Each block checks the type of linked entity and prepares data for transferring to SharePoint.
            // For example, if the linked entity is an Account, set specific flags, query related records, 
            // and call the transferFile method for each file version associated with the document.
            // This process is repeated for each supported Salesforce object type.
            
            
            System.debug('transferBegin');
            //System.debug('ContentDocumentId'+doc.ContentDocumentId); 
            //System.debug('Object-Type: ' + doc.LinkedEntityId.getSobjectType());
            //System.debug('LinkedEntityId'+doc.LinkedEntityId); 
            //Parent Directory >> Parent Directory Name >> Sub Directory >> Directory name >> Files
            boolean IsSubDirectory = true;
            //Parent Directory >> Parent Directory Name >> Files Directory >> Files
            boolean IsFilesFolder = false;
            
            string childDirectory = '';
            List<ContentVersion> contentVersionList = new List<ContentVersion>();
            //transfer files for account
            if(doc != null && doc.LinkedEntityId.getSobjectType() == Account.SobjectType) {
                //IsSubDirectory = false;
                // childDirectory = 'Account';
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related Account
                Account account = [SELECT Id,Name FROM Account WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,account.Id, account.Id,account.Name,String.valueOf(ParentObjectType.Account),String.valueOf(ObjectType.Account),childDirectory,doc.ContentDocumentId);
                    //after moving the file delete the files from salesforce
                    // System.debug('deleteFiles Start '+doc.ContentDocumentId); 
                    // deleteFiles(doc.ContentDocumentId);
                    // System.debug('deleteFiles End'); 
                }
            }  
            //transfer files for contact
            if(doc != null && doc.LinkedEntityId.getSobjectType() == Contact.SobjectType) {
                //IsSubDirectory = false;
                //childDirectory = 'Contact';
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related contact
                Contact contact = [SELECT Id,Name FROM Contact WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, contact.Id, contact.Id,contact.Name,String.valueOf(ParentObjectType.Contact),String.valueOf(ObjectType.Contact),childDirectory,doc.ContentDocumentId);
                    
                }
            }  
            //transfer files for Withdrawals
            if(doc != null && doc.LinkedEntityId.getSobjectType() == AVO_Withdrawals__c.SobjectType) {
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related Withdrawals
                AVO_Withdrawals__c withdrawals = [SELECT Id,Name FROM AVO_Withdrawals__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, withdrawals.Id, withdrawals.Id,withdrawals.Name,String.valueOf(ParentObjectType.Withdrawal),String.valueOf(ObjectType.Withdrawal),childDirectory,doc.ContentDocumentId);
                }
            } 
            //transfer files for permit
           if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Permit2__c.SobjectType) {
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related Permit
                MUSW__Permit2__c permit = [SELECT Id,Name FROM MUSW__Permit2__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, permit.Id, permit.Id,permit.Name,String.valueOf(ParentObjectType.Permit),String.valueOf(ObjectType.Permit),childDirectory,doc.ContentDocumentId);
                }
            } 
            //transfer files for Application
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Application2__c.SobjectType) {
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related Application
                MUSW__Application2__c application = [SELECT Id,Name FROM MUSW__Application2__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, application.Id, application.Id,application.Name,String.valueOf(ParentObjectType.Application),String.valueOf(ObjectType.Application),childDirectory,doc.ContentDocumentId);
                }
            } 
            //transfer files for License
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__License2__c.SobjectType) {
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related Application
                MUSW__License2__c License = [SELECT Id,Name FROM MUSW__License2__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, License.Id, License.Id,License.Name,String.valueOf(ParentObjectType.License),String.valueOf(ObjectType.License),childDirectory,doc.ContentDocumentId);
                }
            } 
            //transfer files for Complaint
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Complaint2__c.SobjectType) {
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                
                // Get related Complaint
                MUSW__Complaint2__c complaint = [SELECT Id,Name FROM MUSW__Complaint2__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, complaint.Id, complaint.Id,complaint.Name,String.valueOf(ParentObjectType.Complaint),String.valueOf(ObjectType.Complaint),childDirectory,doc.ContentDocumentId);
                    
                }
            }  
            //transfer files for Violation
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Violation__c.SobjectType) {
                // Get related Violation
                MUSW__Violation__c violation = [SELECT Id,Name,MUSW__Complaint2__c FROM MUSW__Violation__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                if(String.isBlank(violation.MUSW__Complaint2__c))
                {
                    
                    IsFilesFolder = true;
                    childDirectory = 'Files';
                }
                else	
                {
                    
                    childDirectory = 'Violation';
                }
                
                
                
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    if(String.isBlank(violation.MUSW__Complaint2__c))
                    {
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, violation.Id, violation.Id,violation.Name,String.valueOf(ParentObjectType.Violation),String.valueOf(ObjectType.Violation),childDirectory,doc.ContentDocumentId);
                    }
                    else
                    {
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, violation.MUSW__Complaint2__c, violation.Id,violation.Name,String.valueOf(ParentObjectType.Complaint),String.valueOf(ObjectType.Violation),childDirectory,doc.ContentDocumentId);
                    }
                    
                    
                }
            }  
            //transfer files for submission
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Submission__c.SobjectType) {
                
                childDirectory = 'Submissions';
                //String ObjectTypeName = doc.LinkedEntityId.getSobjectType();
                //System.Debug('Submission Object Type: ' + MUSW__Submission__c.SobjectType);
                
                // Get related Submission
                MUSW__Submission__c submission = [SELECT Id,Name,MUSW__Application2__c,MUSW__Permit2__c,MUSW__License2__c  FROM MUSW__Submission__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    System.debug('Iterate transferFile'+fileName);
                    
                    
                    // Determine the record type based on the submission fields
                    if (submission.MUSW__Application2__c != null) {
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,submission.MUSW__Application2__c, submission.Id,submission.Name,String.valueOf(ParentObjectType.Application),String.valueOf(ObjectType.Submission) ,childDirectory,doc.ContentDocumentId);
                        
                        
                        
                    } else if (submission.MUSW__Permit2__c != null) {
                        
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,submission.MUSW__Permit2__c, submission.Id,submission.Name,String.valueOf(ParentObjectType.Permit),String.valueOf(ObjectType.Submission) ,childDirectory,doc.ContentDocumentId);
                    } else if (submission.MUSW__License2__c != null) {
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,submission.MUSW__License2__c, submission.Id,submission.Name,String.valueOf(ParentObjectType.License),String.valueOf(ObjectType.Submission) ,childDirectory,doc.ContentDocumentId);
                    }                    
                    
                    
                }
            }  
            //transfer files for Inspection
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Inspection__c.SobjectType) {
                childDirectory = 'Inspections';	
                
                // Get related Inspection
                MUSW__Inspection__c inspection = [SELECT AVO_Application__c,Id,MUSW__Permit__c,Name,MUSW__License2__c,MUSW__Complaint2__c  FROM MUSW__Inspection__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    if (inspection.AVO_Application__c != null) {
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,inspection.AVO_Application__c, inspection.Id,inspection.Name,String.valueOf(ParentObjectType.Application),String.valueOf(ObjectType.Inspection),childDirectory,doc.ContentDocumentId); 
                        
                    } else if (inspection.MUSW__Permit__c != null) {
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,inspection.MUSW__Permit__c, inspection.Id,inspection.Name,String.valueOf(ParentObjectType.Permit),String.valueOf(ObjectType.Inspection),childDirectory,doc.ContentDocumentId);
                    } else if (inspection.MUSW__License2__c != null) {
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,inspection.MUSW__License2__c, inspection.Id,inspection.Name,String.valueOf(ParentObjectType.License),String.valueOf(ObjectType.Inspection),childDirectory,doc.ContentDocumentId);
                    }   
                    else if (inspection.MUSW__Complaint2__c != null) {
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,inspection.MUSW__Complaint2__c, inspection.Id,inspection.Name,String.valueOf(ParentObjectType.Complaint),String.valueOf(ObjectType.Inspection),childDirectory,doc.ContentDocumentId);
                    }   
                    
                }
            } 
            //transfer files for Milestone
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Milestone__c.SobjectType) {
                childDirectory = 'Milestones';	
                
                // Get related Milestone
                MUSW__Milestone__c milestone = [SELECT Id,MUSW__Permit2__c,Name,MUSW__Application2__c,MUSW__License2__c  FROM MUSW__Milestone__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    if (milestone.MUSW__Application2__c != null) {
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,milestone.MUSW__Application2__c, milestone.Id,milestone.Name,String.valueOf(ParentObjectType.Application),String.valueOf(ObjectType.Milestone),childDirectory,doc.ContentDocumentId);
                        
                    } else if (milestone.MUSW__Permit2__c != null) {
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,milestone.MUSW__Permit2__c, milestone.Id,milestone.Name,String.valueOf(ParentObjectType.Permit),String.valueOf(ObjectType.Milestone),childDirectory,doc.ContentDocumentId);
                    } else if (milestone.MUSW__License2__c != null) {
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,milestone.MUSW__License2__c, milestone.Id,milestone.Name,String.valueOf(ParentObjectType.License),String.valueOf(ObjectType.Milestone),childDirectory,doc.ContentDocumentId);
                    }   
                    
                }
            } 
            //transfer files for Review
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Review__c.SobjectType) {
                childDirectory = 'Reviews';	
                
                // Get related Review
                MUSW__Review__c review = [SELECT Id,MUSW__Permit2__c,Name,MUSW__Application2__c,MUSW__License2__c  FROM MUSW__Review__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    if (review.MUSW__Application2__c != null) {
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,review.MUSW__Application2__c, review.Id,review.Name,String.valueOf(ParentObjectType.Application),String.valueOf(ObjectType.Review),childDirectory,doc.ContentDocumentId);
                        
                    } else if (review.MUSW__Permit2__c != null) {
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,review.MUSW__Permit2__c, review.Id,review.Name,String.valueOf(ParentObjectType.Permit),String.valueOf(ObjectType.Review),childDirectory,doc.ContentDocumentId);
                    } else if (review.MUSW__License2__c != null) {
                        
                        transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,review.MUSW__License2__c, review.Id,review.Name,String.valueOf(ParentObjectType.License),String.valueOf(ObjectType.Review),childDirectory,doc.ContentDocumentId);
                    }   
                    
                }
            }
            //transfer files for comment
            if(doc != null && doc.LinkedEntityId.getSobjectType() == MUSW__Comment__c.SobjectType) {
                //IsSubDirectory = false;
                //childDirectory = 'Contact';
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related contact
                MUSW__Comment__c comment = [SELECT Id,Name FROM MUSW__Comment__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension, comment.Id, comment.Id,comment.Name,String.valueOf(ParentObjectType.Comment),String.valueOf(ObjectType.Comment),childDirectory,doc.ContentDocumentId);
                    
                }
            }  
            //05-06-2025
             // Transfer files for Meter
            if(doc != null && doc.LinkedEntityId.getSobjectType() == AVO_Meter__c.SObjectType) {
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related Meter
                AVO_Meter__c meter = [SELECT Id, Name FROM AVO_Meter__c WHERE Id = :doc.LinkedEntityId LIMIT 1];
                
                contentVersionList = [SELECT VersionData, Title, FileExtension 
                                      FROM ContentVersion 
                                      WHERE ContentDocumentId = :doc.ContentDocumentId AND IsLatest = true];
                
                for(ContentVersion content : contentVersionList) {
                    String fileName = content.Title + '.' + content.FileExtension;
                    transferFile(IsFilesFolder, IsSubDirectory, content.VersionData, content.Title, 
                                 '.' + content.FileExtension, meter.Id, meter.Id, meter.Name, 
                                 String.valueOf(ParentObjectType.Meter), String.valueOf(ObjectType.Meter), childDirectory, doc.ContentDocumentId);
                    
                    
                }
            }
             // Transfer files for Meter Transaction
            if(doc != null && doc.LinkedEntityId.getSobjectType() == AVO_Meter_Transaction__c.SObjectType) {
              
                childDirectory = 'MeterTransaction';
                
                 // Get related Submission
                AVO_Meter_Transaction__c meterTransaction = [SELECT Id,Name,AVO_Meter_ID__c  FROM AVO_Meter_Transaction__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                
               
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    System.debug('Iterate transferFile'+fileName);
                    
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,meterTransaction.AVO_Meter_ID__c, meterTransaction.Id,meterTransaction.Name,String.valueOf(ParentObjectType.Meter),String.valueOf(ObjectType.Meter_Transaction) ,childDirectory,doc.ContentDocumentId);                
                    
                    
                }
                
               
            }
            
            // Transfer files for AVO_Meter_Withdrawal__c
            if(doc != null && doc.LinkedEntityId.getSobjectType() == AVO_Meter_Withdrawal__c.SObjectType) {
              
                childDirectory = 'MeterWithdrawal';
                
                 // Get related Submission
                AVO_Meter_Withdrawal__c meterWithdrawal = [SELECT Id,Name,AVO_Meter_ID__c  FROM AVO_Meter_Withdrawal__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                
                
               
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    System.debug('Iterate transferFile'+fileName);
                    
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,meterWithdrawal.AVO_Meter_ID__c, meterWithdrawal.Id,meterWithdrawal.Name,String.valueOf(ParentObjectType.Meter),String.valueOf(ObjectType.Meter_Withdrawal) ,childDirectory,doc.ContentDocumentId);                
                    
                    
                }
                
               
            }
            // Transfer files for Meter Codeset
            if(doc != null && doc.LinkedEntityId.getSobjectType() == AVO_Meter_Codeset__c.SObjectType) {
                childDirectory = 'MeterCodeset';
                
                // Get related Submission
                AVO_Meter_Codeset__c meterCodeset = [SELECT Id,Name  FROM AVO_Meter_Codeset__c WHERE id = : doc.LinkedEntityId LIMIT 1];
                AVO_Meter__c meterRecord = [
                    SELECT Id, Name 
                    FROM AVO_Meter__c 
                    WHERE (AVO_Make__c = :doc.LinkedEntityId OR AVO_Model__c = :doc.LinkedEntityId) 
                    LIMIT 1
                ];

                
                
                //file.TestFileObject__c = tfo.Id;
                contentVersionList =[select VersionData, Title, FileExtension from ContentVersion where ContentDocumentId = :doc.ContentDocumentId and IsLatest=true];
                for(ContentVersion content : contentVersionList){
                    String fileName = content.Title +'.' +content.FileExtension;
                    System.debug('Iterate transferFile'+fileName);
                    
                    transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title, '.' +content.FileExtension,meterRecord.Id, meterCodeset.Id,meterCodeset.Name,String.valueOf(ParentObjectType.Meter),String.valueOf(ObjectType.Meter_Codeset) ,childDirectory,doc.ContentDocumentId);                
                   
                    
                }
            }
            
             if(doc != null && doc.LinkedEntityId.getSobjectType() == AVO_Compliance__c.SObjectType) {
                IsFilesFolder = true;
                childDirectory = 'Files';
                
                // Get related Compliance
                AVO_Compliance__c compliance = [SELECT Id, Name FROM AVO_Compliance__c WHERE Id = :doc.LinkedEntityId LIMIT 1];
                
                contentVersionList = [SELECT VersionData, Title, FileExtension 
                                      FROM ContentVersion 
                                      WHERE ContentDocumentId = :doc.ContentDocumentId AND IsLatest = true];
                
                for(ContentVersion content : contentVersionList) {
                    String fileName = content.Title + '.' + content.FileExtension;
                    
                    
                      transferFile(IsFilesFolder,IsSubDirectory,content.VersionData,content.Title,
                                   '.' +content.FileExtension, compliance.Id, compliance.Id,compliance.Name,
                                   String.valueOf(ParentObjectType.Compliance),String.valueOf(ObjectType.Compliance),
                                   childDirectory,doc.ContentDocumentId);
                   
                    
                }
            }
            
        }
        catch(Exception e) {
            
            String errorMessage =  e.getMessage(); // Get the error message
            String errorDetails = e.getStackTraceString(); // Get error details
            
            // Call the existing log method to log the error
            AvoLogUtils.log(errorMessage, errorDetails, 'ERROR', null);
        }
    }
    
    
    @future(callout=true)
    public static void transferFile(boolean IsFilesFolder,boolean IsSubDirectory,Blob fileBlob, string fName, string fileExtension,ID parentObjectId, ID objectId,string objectName,String ParentObjectTypeStr, String ObjectTypeStr, String childDirectory, ID contentDocumentId)
    {
         
        AVO_SharePointProcessRecord.ParentObjectType parentObjectType = AVO_SharePointProcessRecord.getParentObjectType(ParentObjectTypeStr);
AVO_SharePointProcessRecord.ObjectType objectType = AVO_SharePointProcessRecord.getObjectType(ObjectTypeStr);

        
        try {
            System.debug('transferFile Starts');
            String targetfolderDirectory =  Directory ;
            String folderName = '';
            
            if(IsSubDirectory)
            {
                switch on parentObjectType {
                    when Permit {
                        // Attempt to retrieve the permit using the provided permitID
                        MUSW__Permit2__c permit = [SELECT Id, Name FROM MUSW__Permit2__c WHERE Id = :parentObjectId LIMIT 1];
                        
                        // Append 'Permit/' to the Directory if a permit has been found
                        if (permit != null) {
                            Directory=Directory+'Permit/';
                            folderName = EncodingUtil.urlEncode(permit.Name	,'UTF-8');
                            targetfolderDirectory =  targetfolderDirectory + permit.Name;
                        }
                        
                    }
                    when Application {
                        
                        // Attempt to retrieve the Application using the provided permitID
                        MUSW__Application2__c application = [SELECT Id, Name FROM MUSW__Application2__c WHERE Id = :parentObjectId LIMIT 1];
                        
                        // Append 'application/' to the Directory if a permit has been found
                        if (application != null) {
                            Directory=Directory+'Application/';
                            folderName = EncodingUtil.urlEncode(application.Name	,'UTF-8');
                            targetfolderDirectory =  targetfolderDirectory + application.Name;
                        }
                        
                    }
                    when Contact {
                        Directory=Directory+'Contact/';
                        folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
                        targetfolderDirectory =  targetfolderDirectory + objectName;
                    }
                    when Account {
                        Directory=Directory+'Account/';
                        folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
                        targetfolderDirectory =  targetfolderDirectory + objectName;
                    }
                    when Comment {
                        Directory=Directory+'Account/';
                        folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
                        targetfolderDirectory =  targetfolderDirectory + objectName;
                    }
                    when Complaint {
                        
                        
                        // Attempt to retrieve the complaint using the provided permitID
                        MUSW__Complaint2__c  complaint = [SELECT Id, Name FROM MUSW__Complaint2__c  WHERE Id = :parentObjectId LIMIT 1];
                        
                        // Append 'complaint/' to the Directory if a permit has been found
                        if (complaint != null) {
                            Directory=Directory+'Complaint/';
                            folderName = EncodingUtil.urlEncode(complaint.Name	,'UTF-8');
                            targetfolderDirectory =  targetfolderDirectory + complaint.Name;
                        }
                    }
                    when Violation {
                        
                        
                        // Attempt to retrieve the violation using the provided permitID
                        MUSW__Violation__c  violation = [SELECT Id, Name FROM MUSW__Violation__c  WHERE Id = :parentObjectId LIMIT 1];
                        
                        // Append 'violation/' to the Directory if a permit has been found
                        if (violation != null) {
                            Directory=Directory+'Violation/';
                            folderName = EncodingUtil.urlEncode(violation.Name	,'UTF-8');
                            targetfolderDirectory =  targetfolderDirectory + violation.Name;
                        }
                    }
                    when License {
                        
                        
                        // Attempt to retrieve the Application using the provided permitID
                        MUSW__License2__c  license = [SELECT Id, Name FROM MUSW__License2__c  WHERE Id = :parentObjectId LIMIT 1];
                        
                        // Append 'license/' to the Directory if a permit has been found
                        if (license != null) {
                            Directory=Directory+'License/';
                            folderName = EncodingUtil.urlEncode(license.Name	,'UTF-8');
                            targetfolderDirectory =  targetfolderDirectory + license.Name;
                        }
                    }
                    when Withdrawal {
                        Directory=Directory+'Withdrawals/';
                        folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
                        targetfolderDirectory =  targetfolderDirectory + objectName;
                    }
                    when Meter {
                        Directory=Directory+'Meter/';
                        folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
                        targetfolderDirectory =  targetfolderDirectory + objectName;
                    }
                    when Meter_Transaction {
                        Directory=Directory+'MeterTransaction/';
                        folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
                        targetfolderDirectory =  targetfolderDirectory + objectName;
                    }
                     when Compliance {
                        Directory=Directory+'Compliance/';
                        folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
                        targetfolderDirectory =  targetfolderDirectory + objectName;
                    }
                    when else {
                        folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
                        targetfolderDirectory =  targetfolderDirectory + objectName;
                    }}
                
                System.debug('test Directory:'+ Directory);
                System.debug('test folderName:'+ folderName);
                System.debug('test targetfolderDirectory:'+ targetfolderDirectory);
            }
            else
            {
                targetfolderDirectory =  targetfolderDirectory+childDirectory+'/' + EncodingUtil.urlEncode(objectName,'UTF-8').replace('+', '%20');
                Directory=Directory+childDirectory+'/';
                
                folderName = EncodingUtil.urlEncode(objectName,'UTF-8');
            }
            objectName = EncodingUtil.urlEncode(objectName,'UTF-8');
            objectName = objectName.replace('+', '%20');
            
            String targetDirectory = '';
            
            string fileName = fName + fileExtension;
            Http http = new Http();
            HttpRequest httpRequestToken = new HttpRequest();
            
            httpRequestToken.setEndpoint(tokenEndpoint);
            httpRequestToken.setMethod('POST');
            httpRequestToken.setHeader('Content-Type','application/x-www-form-urlencoded');
            
            String payload = 'client_id='+EncodingUtil.urlEncode(clientId,'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(clientSecret,'UTF-8')+'&grant_Type='+EncodingUtil.urlEncode(grantType,'UTF-8')+'&resource='
                +EncodingUtil.urlEncode(resource,'UTF-8');
            
            httpRequestToken.setBody(payload);
            HttpResponse response = http.send(httpRequestToken);
            System.debug('payload '+payload);
            
            if (response.getStatusCode() != 200) {
                // non 200 http codes are something other than success
                String errorMessage = 'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getBody();
                System.debug(errorMessage);
            } 
            else {
                Map<String, Object > results = (Map<String, Object>)Json.deserializeUntyped(response.getBody());
                accessToken = (string)results.get('access_token');
                System.debug('accessToken'+accessToken);
            }
            // Directory=Directory + childDirectory +'/';
            //Create folder(s)
            HttpRequest httpRequestCreateParentDirectory = new HttpRequest();  
            
            
            // objectName=childDirectory +'/'+objectName;
            //String baseDirectory = '/sites/SalesforceIntegrationTesting/Shared%20Documents/SalesforceFiles/Permit/\'';
            // String permitDirectory = '/sites/SalesforceIntegrationTesting/Shared%20Documents/SalesforceFiles/Permit/' + folderName + '\'';
            //String subDirectory = '/sites/SalesforceIntegrationTesting/Shared%20Documents/SalesforceFiles/Permit/' + folderName + '/' + submission.Name +  '\'';
            //String createPermitDirectory = 'https://avocettetech.sharepoint.com/sites/SalesforceIntegrationTesting/_api/web/getfolderbyserverrelativeurl(\'' + baseDirectory + ')/folders/add(\'' + folderName +  '\')';
            String baseDirectory = Directory + '\'';
            String parentDirectory = Directory + folderName + '\'';
            String subDirectory = '';
            String createParentDirectory = siteurl+	 '/_api/web/getfolderbyserverrelativeurl(\'' + baseDirectory + ')/folders/add(\'' + folderName +  '\')';
            //Create parent name directory under parent
            httpRequestCreateParentDirectory.setEndpoint(createParentDirectory);
            httpRequestCreateParentDirectory.setMethod('POST');
            httpRequestCreateParentDirectory.setHeader('Authorization', 'Bearer ' + accessToken);
            httpRequestCreateParentDirectory.setHeader('Content-Type','application/json;odata=verbose');
            httpRequestCreateParentDirectory.setHeader('Content-Length','0');
            String resp = 'The folder response endpoint' + createParentDirectory;
            HttpResponse ResponseCreateParentDirectory = http.send(httpRequestCreateParentDirectory); 
            resp = 'The folder response status code: ' + ResponseCreateParentDirectory.getStatusCode() + ' ' + ResponseCreateParentDirectory.getBody();
            
            System.debug(resp);
            System.debug('Instance folder: ' + ResponseCreateParentDirectory.getStatusCode());
            
            if(ResponseCreateParentDirectory.getStatusCode() == 200){
                if(IsSubDirectory)
                {
                    //Create Child directory under parent
                    HttpRequest httpRequestCreateChildDirectory = new HttpRequest();  
                    
                    
                    String creatChildDirectory = siteurl+ '_api/web/getfolderbyserverrelativeurl(\'' + parentDirectory + ')/folders/add(\'' + childDirectory +  '\')';
                    
                    httpRequestCreateChildDirectory.setEndpoint(creatChildDirectory);
                    httpRequestCreateChildDirectory.setMethod('POST');
                    httpRequestCreateChildDirectory.setHeader('Authorization', 'Bearer ' + accessToken);
                    httpRequestCreateChildDirectory.setHeader('Content-Type','application/json;odata=verbose');
                    httpRequestCreateChildDirectory.setHeader('Content-Length','0');
                    resp = 'The sub folder response endpoint' + creatChildDirectory;
                    // System.debug(resp);
                    HttpResponse ResponseCreateChildDirectory = http.send(httpRequestCreateChildDirectory);          
                    resp = 'The sub folder response status code: ' + ResponseCreateChildDirectory.getStatusCode() + ' ' + ResponseCreateChildDirectory.getBody();
                    //Update Parent Directory
                    parentDirectory = Directory + folderName + '/' +childDirectory + '\'';
                    
                    if(!IsFilesFolder)
                    {
                        //Create child name directory under Child directory 
                        HttpRequest httpRequestCreateChildNameDirectory = new HttpRequest();  
                        
                        
                        String createChildNameDirectory = siteurl+ '_api/web/getfolderbyserverrelativeurl(\'' + parentDirectory  + ')/folders/add(\'' + objectName +  '\')';
                        
                        httpRequestCreateChildNameDirectory.setEndpoint(createChildNameDirectory);
                        httpRequestCreateChildNameDirectory.setMethod('POST');
                        httpRequestCreateChildNameDirectory.setHeader('Authorization', 'Bearer ' + accessToken);
                        httpRequestCreateChildNameDirectory.setHeader('Content-Type','application/json;odata=verbose');
                        httpRequestCreateChildNameDirectory.setHeader('Content-Length','0');
                        resp = 'The sub folder response endpoint' + createChildNameDirectory;
                        // System.debug(resp);
                        HttpResponse ResponseCreateChildNameDirectory = http.send(httpRequestCreateChildNameDirectory);          
                        resp = 'The sub folder response status code: ' + ResponseCreateChildNameDirectory.getStatusCode() + ' ' + ResponseCreateChildNameDirectory.getBody();
                        
                        //Update SubDirectory
                        targetDirectory = Directory + folderName+ '/' +childDirectory + '/' + objectName;
                        // subDirectory = Directory + folderName+ '/' +childDirectory + '/' + objectName +  '\'';
                        subDirectory = targetDirectory +  '\'';
                        
                        targetfolderDirectory =  targetfolderDirectory + '/' +childDirectory + '/' + objectName;
                    }
                    else	
                    {
                        //For permit and Application files
                        //Update SubDirectory
                        targetDirectory = Directory + folderName+ '/' +childDirectory ;
                        subDirectory = targetDirectory +  '\'';
                        
                        targetfolderDirectory =  targetfolderDirectory + '/' +childDirectory ;
                    }
                    
                }
                else
                {
                    //Update SubDirectory
                    targetDirectory = Directory +  '/' + folderName;
                    subDirectory = targetDirectory +  '\'';
                }
                
            }
            
            
            
            HttpRequest httpRequestCheckFiles = new HttpRequest();  
            // String directory = '/sites/SalesforceIntegrationTesting/Shared%20Documents\'' + folderName + '/' + submission.Name + '\'';
            
            
            
            String endpointCheckFile = siteurl+ '_api/web/getfolderbyserverrelativeurl(\'' + subDirectory + ')/files?$select=Name';
            
            // System.debug('Directory: ' + directory);
            //System.debug('endpointCheckFile: ' + endpointCheckFile);
            
            
            httpRequestCheckFiles.setEndpoint(endpointCheckFile);
            httpRequestCheckFiles.setMethod('POST');
            httpRequestCheckFiles.setHeader('Authorization', 'Bearer ' + accessToken);
            httpRequestCheckFiles.setHeader('Content-Type','application/json;odata=verbose');
            httpRequestCheckFiles.setHeader('Content-Length','0');
            
            HttpResponse responseCheckFileRequest = http.send(httpRequestCheckFiles);  
            if (responseCheckFileRequest.getStatusCode() != 200) {
                String errorMessage = 'The status code returned was not expected: ' + responseCheckFileRequest.getStatusCode() + ' ' + responseCheckFileRequest.getBody();
                // System.debug(responseCheckFileRequest.getBody());
                // System.debug(errorMessage);
            } else{
                Dom.Document docF = new Dom.Document();
                docF.load(responseCheckFileRequest.getBody());
                Integer fileCount = getFileMatchCount(docF.getRootElement(), fileName);
                // System.debug('file count match: ' +fileCount);
                if(fileCount>0){
                    fileName = fName + '(' + fileCount + ')' + fileExtension;
                }
                
                HttpRequest httpRequestToSend = new HttpRequest();  
                String endpoint = siteurl +	 '_api/web/getfolderbyserverrelativeurl(\'' + subDirectory + ')/files/add(overwrite=false,url=\'' +EncodingUtil.urlEncode(fileName,'UTF-8').replaceAll('\\+','%20')+'\')' + '?$expand=ListItemAllFields';
                
                httpRequestToSend.setEndpoint(endpoint);
                httpRequestToSend.setMethod('POST');
                httpRequestToSend.setHeader('Authorization', 'Bearer ' + accessToken);
                httpRequestToSend.setHeader('Content-Type','application/json;odata=verbose');
                
                
                httpRequestToSend.setBodyAsBlob(fileBlob);
                
                System.debug('File '+endpoint); 
                
                HttpResponse responseFileRequest = http.send(httpRequestToSend);  
                if (responseFileRequest.getStatusCode() != 200) {
                    String errorMessage = 'The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getBody();
                    // System.debug(errorMessage);
                    System.debug('Error File Transfer '+endpoint); 
                } 
                else {
                    System.debug('fileName '+fileName); 
                    System.debug('Success File Transfer '+endpoint); 
                    Dom.Document doc = new Dom.Document();
                    doc.load(responseFileRequest.getBody());
                    //System.debug('responseFileRequest'+ responseFileRequest.getBody());
                    Integer fileId = getIdFromXMLNode(doc.getRootElement());
                    
                    Dom.XmlNode node = doc.getRootElement();
                    String resultFile = '';
                    resultFile = 'Root Element: '+node.getName();
                    if(node.getAttributeCount() > 0) {
                        for(integer i=0; i< node.getAttributeCount() ;i++) {
                            resultFile += '\nAttribute Name: '+node.getAttributeKeyAt(i)+'\nAttribute Value: '+node.getAttributeValue(node.getAttributeKeyAt(i), null);
                            System.debug('\nAttribute Name: '+node.getAttributeKeyAt(i)+'\nAttribute Value: '+node.getAttributeValue(node.getAttributeKeyAt(i), null));
                        }
                    }
                    
                    for(Dom.XmlNode xnode : node.getChildElements()) {
                        // resultFile +='\n aElement Name:'+xnode.getName()+(String.isBlank(xnode.getText()) ? '' :'\nElement Value:'+xnode.getText());
                        String elementName = xnode.getName();
                        resultFile += '\n ' + elementName;
                        if(xnode.getAttributeCount() > 0) {
                            for(integer i=0; i< xnode.getAttributeCount() ;i++) {   
                                String attributeName = xnode.getAttributeKeyAt(i);     
                                resultFile +=  '\nAttribute Name: '+xnode.getAttributeKeyAt(i)+'\nAttribute Value: '+xnode.getAttributeValue(xnode.getAttributeKeyAt(i), null);
                                System.debug('\nAttribute Name: '+xnode.getAttributeKeyAt(i)+'\nAttribute Value: '+xnode.getAttributeValue(xnode.getAttributeKeyAt(i), null));
                            }
                        }
                        for(Dom.XmlNode axnode : xnode.getChildElements()) {
                            resultFile +='\n bElement Name:'+axnode.getName()+(String.isBlank(axnode.getText()) ? '' :'\nElement Value:'+axnode.getText());
                            if(String.isNotBlank(axnode.getNamespace()))
                                resultFile += '\nName Space: '+axnode.getNamespace();
                            if(axnode.getAttributeCount() > 0) {
                                for(integer i=0; i< axnode.getAttributeCount() ;i++) {               
                                    resultFile += '\nAttribute Name: '+axnode.getAttributeKeyAt(i)+'\nAttribute Value: '+axnode.getAttributeValue(axnode.getAttributeKeyAt(i), null);
                                    System.debug('\nAttribute Name: '+axnode.getAttributeKeyAt(i)+'\nAttribute Value: '+axnode.getAttributeValue(axnode.getAttributeKeyAt(i), null));
                                }
                            }
                        }
                    }
                    
                    
                    
                    
                    if(fileId == -1){
                        String errorMessage = 'Filed Id not found';
                        //System.debug(errorMessage);
                    }
                    else{
                        
                        // InsertSharePointFileInfo(fileId,folderName, parentId, objectName, accessToken, http, fileName, contentDocumentId);
                        //System.debug('InsertSharePointFileInfo');
                        //System.debug('childDirectory: ' + childDirectory);
                        //System.debug('fileId: ' + fileId);
                        //System.debug('targetDirectory: ' + targetDirectory);
                        //System.debug('parentId: ' + parentId);
                        //System.debug('objectName: ' + objectName);
                        //System.debug('accessToken: ' + accessToken);
                        //System.debug('http: ' + http);
                        //System.debug('fileName: ' + fileName);
                        //System.debug('contentDocumentId: ' + contentDocumentId);
                        System.debug('Iterate InsertSharePointFileInfo'+fileId);
                        InsertSharePointFileInfo(childDirectory,fileId,targetDirectory, objectId, objectName, accessToken, http, fileName, contentDocumentId,objectType);
                        
                    }
                }
            }
            
        } catch(Exception e) {
            
            String errorMessage =  e.getMessage(); // Get the error message
            String errorDetails = e.getStackTraceString(); // Get error details
            
            // Call the existing log method to log the error
            AvoLogUtils.log(errorMessage, errorDetails, 'ERROR', null);
        }
        
        
    }
    public static void InsertSharePointFileInfo(String childDirectory,Integer fileId, String folderName, Id parentId,String objectName, String accessToken, Http http, String fileName, String contentDocumentId,ObjectType objectType) 
    {
        try {
            // Now, check the number of DML statements executed
            System.debug('Iterate Number of DML statements executed: ' + Limits.getDMLStatements());
            String externalLink = '';
            string encodedFile = EncodingUtil.urlEncode(fileName,'ASCII').replaceAll('\\+','%20');
            //String url = 'https://avocettetech.sharepoint.com/sites/SalesforceIntegrationTesting/Shared%20Documents/Forms/AllItems.aspx?id=' + accountDirectory.substring(0,accountDirectory.length()-1) + '/' +encodedFile + '&parent=/sites/SalesforceIntegrationTesting/Shared%20Document';
            
            AVO_SharePoint_File__c file = new AVO_SharePoint_File__c();
            
            
            
            file.Name = fileName;
            switch on objectType {
                when Permit {
                    
                    file.AVO_Permit__c = parentId;
                }
                when Application {
                    file.AVO_Application__c = parentId;
                }
                when Contact {
                    file.AVO_Contact__c = parentId;
                }
                when Account {
                    file.AVO_Account__c = parentId;
                }
                when Comment {
                    file.AVO_Comment__c = parentId;
                }
                
                when Violation {
                    file.AVO_Violation__c = parentId;
                }
                when License {
                    file.AVO_License__c = parentId;
                }
                when Complaint {
                    file.AVO_Complaint__c = parentId;
                }
                when Inspection
                {
                    file.AVO_Inspection__c = parentId;
                }
                when Submission
                {
                    file.AVO_Submission__c = parentId;
                }
                when Milestone
                {
                    file.AVO_Milestone__c = parentId;
                }
                when Review
                {
                    file.AVO_Review__c = parentId;
                }
                 when Compliance
                {
                    file.AVO_Compliance__c = parentId;
				}
                when Meter
                {
                    file.AVO_Meter__c = parentId;
				}
                when Meter_Withdrawal
                {
                    file.AVO_Meter_Withdrawal__c = parentId;
                }
                when Meter_Transaction
                {
                    file.AVO_Meter_Transaction__c = parentId;
                }
                when Meter_Codeset
                {
                    file.AVO_Meter_Codeset__c = parentId;
                }
                when else {
                    System.debug('Unknown record type.');
                }}
            
            
            externalLink = getAccessLink(folderName, objectName, encodedFile, accessToken, http, false);
            
            System.debug('externalLink '+externalLink);
            String fileIdString = String.valueOf(fileId);
            // string SharePointURLLink = createSharePointLink(accessToken,fileIdString);
            // externalLink = createSharePointLink(accessToken,fileIdString);
            string SharePointURLLink = externalLink;
            //System.debug('SharePointLink '+targetfolderDirectory);
            //System.debug('SharePointLink '+fileName);
            System.debug('SharePointURLLink '+SharePointURLLink);
            file.AVO_SharePoint_URL_Text__c = SharePointURLLink;
            file.AVO_SharePoint_URL__c = SharePointURLLink;
            file.AVO_SharePoint_External_Link__c = SharePointURLLink;
            //file.SharePoint_URL__c = externalLink;
            //file.SharePoint_External_Link__c = externalLink;
            file.AVO_ContentDocumentId__c = contentDocumentId;
            file.AVO_SharePoint_Item_Id__c = String.valueOf(fileId);
            insert file;
            
            // Delete data from Salesforce ContentDocument object
            //  When you delete a ContentDocument, Salesforce also deletes all associated ContentVersion records 
            //  because of the master-detail relationship between ContentDocument and ContentVersion.
            delete [SELECT Id
                    FROM ContentDocument
                    WHERE Id =:contentDocumentId];
            
            System.debug('Iterate delete ContentDocument'); 
            // Delete data from Salesforce ContentDocumentLink object
            delete [SELECT Id
                    FROM ContentDocumentLink
                    WHERE ContentDocumentId = :contentDocumentId];
            System.debug('Iterate delete ContentDocumentLink');
            // Now, check the number of DML statements executed
            System.debug('Iterate Number of DML statements executed: ' + Limits.getDMLStatements());
            
        } catch(Exception e) {
            
            String errorMessage = e.getMessage(); // Get the error message
            String errorDetails = e.getStackTraceString(); // Get error details
            
            // Call the existing log method to log the error
            AvoLogUtils.log(errorMessage, errorDetails, 'ERROR', null);
        }
        
        
    } 
    // Enum to represent the different types of object involved in file transfers
    public enum ParentObjectType {
        Permit, Application, Contact, Account, Comment, Complaint, Violation, License,Withdrawal,Meter,Meter_Transaction,Meter_Codeset,Meter_Withdrawal,Compliance   
    }
     // Enum to represent the different types of object involved in file transfers
    public enum ObjectType {
        Permit, Application, Contact, Account, Comment, Complaint, Violation, License, Inspection, Submission, Milestone, Review,Withdrawal,Meter,Meter_Transaction,Meter_Codeset,Meter_Withdrawal,Compliance 
    }
    
    
  
    public static ParentObjectType getParentObjectType(String value) {
        try {
            return ParentObjectType.valueOf(value);
        } catch (Exception e) {
            System.debug('Invalid ParentObjectType: ' + value);
            return null;
        }
    }

    public static ObjectType getObjectType(String value) {
        try {
            return ObjectType.valueOf(value);
        } catch (Exception e) {
            System.debug('Invalid ObjectType: ' + value);
            return null;
        }
    }
    public static Integer getIdFromXMLNode(Dom.XmlNode root){
        for(Dom.XmlNode entryChildNodes: root.getChildElements()) {
            if(entryChildNodes.getName() == 'link' && entryChildNodes.getAttributeValue('title', null) == 'ListItemAllFields' ){
                for(Dom.XmlNode mNode: entryChildNodes.getChildElements()) {
                    for(Dom.XmlNode entryNode: mNode.getChildElements()) {
                        for(Dom.XmlNode entryChildNode: entryNode.getChildElements()) {
                            for(Dom.XmlNode propertyNode: entryChildNode.getChildElements()) {
                                for(Dom.XmlNode idNode: propertyNode.getChildElements()) {
                                    if(idNode.getName()=='Id'){
                                        Integer idVal = integer.valueOf(idNode.getText());
                                        return idVal;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return -1;        
    }
    public static Integer getFileMatchCount(Dom.XmlNode root, string fileName){
        string fileBase = fileNameWithoutExtension(fileName);
        fileBase+= '(';
        string extensionMatch = fileExtensionMatch(fileName);
        
        integer count = 0;
        for(Dom.XmlNode entryNode: root.getChildElements()) {
            if(entryNode.getName() == 'entry' ){
                for(Dom.XmlNode contentNode: entryNode.getChildElements()) {
                    if(contentNode.getName() == 'content' ){
                        for(Dom.XmlNode propertyNode: contentNode.getChildElements()) {
                            for(Dom.XmlNode propertyValueNode: propertyNode.getChildElements()) {
                                string fName = propertyValueNode.getText();
                                string fNameNoExt = fileNameWithoutExtension(fileName);
                                if(fName == filename || (fName.contains(fileBase) && fName.contains(extensionMatch))){
                                    count ++;
                                }
                            }
                        }
                    }
                }
                
                
            }
            
        }
        return count;        
    }
    public static string fileNameWithoutExtension(string fileName){     
        for(integer i = fileName.length() - 1; i >= 0; i--){
            string c = fileName.substring(i,i+1);
            if(c == '.'){
                return fileName.substring(0,i);
            }
        }
        return fileName;
    }
    
    public static string fileExtensionMatch(string fileName){
        for(integer i = fileName.length() - 1; i >= 0; i--){
            string c = fileName.substring(i,i+1);
            if(c == '.'){
                string retString = ')';
                retString += fileName.substring(i,fileName.length());
                return retString;
            }
        }
        return fileName;
    }
    
    public static String getAccessLink(String folderName, string submissionName, String fileName, String accessToken, 
                                       Http http, Boolean allowAnonymousAccess) {
                                           String url = '';
                                           
                                           HttpRequest httpRequestToSend = new HttpRequest();  
                                           // String endpoint = 'https://avocettetech.sharepoint.com/sites/SalesforceIntegrationTesting/_api/web/' +
                                           // 'GetFileByServerRelativePath(decodedurl=\'' + 
                                           // '/sites/SalesforceIntegrationTesting/Shared%20Documents/SalesforceFiles/Permit/' 
                                           // + permitName + '/' + submissionName + '/' + fileName + '\')/ListItemAllFields/ShareLink';
                                           
                                           // String endpoint = siteurl+'_api/web/' +
                                           //'GetFileByServerRelativePath(decodedurl=\'' + 
                                           //'/sites/SalesforceIntegrationTesting/Shared%20Documents/SalesforceFiles/Permit/' 
                                           // + permitName + '/' + submissionName + '/' + fileName + '\')/ListItemAllFields/ShareLink';
                                           
                                           // String endpoint = siteurl+'_api/web/' +
                                           // 'GetFileByServerRelativePath(decodedurl=\'' + 
                                           // Directory 
                                           // + permitName + '/' + submissionName + '/' + fileName + '\')/ListItemAllFields/ShareLink';
                                           
                                           String endpoint = siteurl+'_api/web/' +
                                               'GetFileByServerRelativePath(decodedurl=\'' + 
                                               folderName + '/' + fileName + '\')/ListItemAllFields/ShareLink';
                                           
                                           System.Debug('Access link endpoint: '+endpoint);
                                           
                                           httpRequestToSend.setEndpoint(endpoint);
                                           httpRequestToSend.setMethod('POST');
                                           httpRequestToSend.setHeader('Accept', 'application/json;odata=verbose');
                                           httpRequestToSend.setHeader('Authorization', 'Bearer ' + accessToken);
                                           httpRequestToSend.setHeader('Content-Type','application/json;odata=verbose');
                                           String body;
                                           if (allowAnonymousAccess) {
                                               body = '{"request":{"createLink":true,"settings":{"allowAnonymousAccess":true,"trackLinkUsers":false,"linkKind":4,"expiration":null,"role":1,"restrictShareMembership":false,"updatePassword":false,"password":"","scope":0}}}';
                                           } else {
                                               // body = '{"request":{"createLink":true,"settings":{"allowAnonymousAccess":false,"trackLinkUsers":false,"linkKind":4,"expiration":null,"role":1,"restrictShareMembership":false,"updatePassword":false,"password":"","scope":0}}}';
                                               body = '{"request":{"createLink":true,"settings":{"allowAnonymousAccess":false,"trackLinkUsers":false,"linkKind":3,"expiration":null,"role":1,"restrictShareMembership":false,"updatePassword":false,"password":"","scope":0}}}';
                                               
                                               
                                           }
                                           
                                           
                                           httpRequestToSend.setBody(body);
                                           System.Debug('Access link body: '+body);
                                           
                                           HttpResponse responseFileRequest = http.send(httpRequestToSend); 
                                           if (responseFileRequest.getStatusCode() != 200) {
                                               String errorMessage = 'The status code returned was not expected: ' + responseFileRequest.getStatusCode() + ' ' + responseFileRequest.getBody();
                                               System.Debug('Access link Error: '+errorMessage);
                                               url = errorMessage;
                                           } 
                                           else {
                                               
                                               LinkResponse linkResponse = (LinkResponse)JSON.deserialize(responseFileRequest.getBody(), LinkResponse.class);
                                               
                                               //System.debug('Anonymous Access Link Response: ' + linkResponse);
                                               
                                               url = linkResponse.d.ShareLink.sharingLinkInfo.Url;
                                               
                                               System.Debug('Access link: '+url);
                                               //System.debug('Anonymous Access Link url: ' + url);
                                               
                                           }
                                           
                                           
                                           return url;
                                       }
    
    
     public class LinkResponse {
        public d d;
    }
     public class d {
        public ShareLink ShareLink;
    }
    
    public class ShareLink {
        public sharingLinkInfo sharingLinkInfo;
    }
    
    public class sharingLinkInfo {
        public string Url;
    }
    
}