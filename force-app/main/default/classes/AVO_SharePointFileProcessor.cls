public with sharing class AVO_SharePointFileProcessor {

    private static AVO_Rest_API_Settings__c settings = AVO_Rest_API_Settings__c.getOrgDefaults();
    private static final String SITE_URL = settings.AVO_Site_Url__c.endsWith('/') ? settings.AVO_Site_Url__c : settings.AVO_Site_Url__c + '/';
    private static final Integer DEFAULT_TIMEOUT = 120000;
    static string siteUrl = settings.AVO_Site_Url__c;
    static string Directory = settings.AVO_Base_Directory__c;
    
    // Add class variables to track state
    private List<String> stagingFolders;
    private Integer currentFolderIndex = 0;
    private List<Map<String, Object>> stagingFiles;
    private Integer currentFileIndex = 0;
    private String accessToken;
     private static final Integer MAX_FILES_PER_BATCH = 20;
  
    // Lists to hold records for DML
    private List<AVO_SharePoint_File_Log__c> logsToInsert = new List<AVO_SharePoint_File_Log__c>();
    private List<AVO_SharePoint_File__c> filesToInsert = new List<AVO_SharePoint_File__c>();
    private List<AVO_SharePoint_File__c> filesToUpdate = new List<AVO_SharePoint_File__c>();
    public static Boolean isTestMode = false;

    // Constructor
   /* public AVO_SharePointFileProcessor() {
        // Initialize the list of folders to process
       this.stagingFolders = new List<String>{ 'Application Staging Maps','Permit Staging Maps' };
      //Change Folder  this.stagingFolders = new List<String>{ 'Application Maps','Permit Maps' };
            this.accessToken = getAccessToken();
        if (String.isBlank(this.accessToken)) {
            System.debug('Access token is null — SharePoint processor will not proceed.');
        } else {
            System.debug('Access token initialized successfully.');
        }
    }*/
    public void run(Integer currentFolderIndex, Integer currentFileIndex) {
    System.debug('Starting run: FolderIndex = ' + currentFolderIndex + ', FileIndex = ' + currentFileIndex);

    this.stagingFolders = new List<String>{ 'Application Staging Maps', 'Permit Staging Maps' };
    this.logsToInsert = new List<AVO_SharePoint_File_Log__c>();
    this.filesToInsert = new List<AVO_SharePoint_File__c>();
    this.filesToUpdate = new List<AVO_SharePoint_File__c>();

    accessToken = getAccessToken();
    if (String.isBlank(accessToken)) {
        System.debug('Access token is null. Aborting.');
        return;
    }

    if (currentFolderIndex >= stagingFolders.size()) {
        System.debug('All folders processed. Exiting.');
        finalizeDML(); 
        return;
    }

    String currentFolder = stagingFolders[currentFolderIndex];
    List<Map<String, Object>> files = getFilesFromFolder(accessToken, currentFolder);
    List<String> allErrors = new List<String>();

    if (files == null || files.isEmpty()) {
        System.debug('Folder empty: ' + currentFolder);
        // Queue next folder if possible
        if (!isTestMode && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new AVO_SharePointFileProcessorQueue(currentFolderIndex + 1, 0));
        }
        return;
    }

    Integer filesProcessed = 0;
    Integer i = currentFileIndex;

    for (; i < files.size() && filesProcessed < MAX_FILES_PER_BATCH; i++) {
        Map<String, Object> file = files[i];
        System.debug('Processing file: ' + file.get('Name'));

        List<String> errors = processFile(file, currentFolder);
        if (!errors.isEmpty()) {
            allErrors.addAll(errors);
        }

        filesProcessed++;
    }

    finalizeDML();

    if (!allErrors.isEmpty()) {
        sendNotificationEmail(allErrors);
    }

    // Only enqueue next batch if job depth allows
    if (i < files.size()) {
        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new AVO_SharePointFileProcessorQueue(currentFolderIndex, i));
        } else {
            System.debug('Queueable job limit reached. Stopping at Folder ' + currentFolderIndex + ' File ' + i);
        }
    } else if (currentFolderIndex + 1 < stagingFolders.size()) {
        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new AVO_SharePointFileProcessorQueue(currentFolderIndex + 1, 0));
        } else {
            System.debug('Queueable job limit reached. Stopping before processing next folder.');
        }
    }
}

   /* public void run(Integer currentFolderIndex, Integer currentFileIndex) {
    System.debug('Starting run: FolderIndex = ' + currentFolderIndex + ', FileIndex = ' + currentFileIndex);

    this.stagingFolders = new List<String>{ 'Application Staging Maps', 'Permit Staging Maps' };
    this.logsToInsert = new List<AVO_SharePoint_File_Log__c>();
    this.filesToInsert = new List<AVO_SharePoint_File__c>();
    this.filesToUpdate = new List<AVO_SharePoint_File__c>();

    accessToken = getAccessToken();
    if (String.isBlank(accessToken)) {
        System.debug('Access token is null. Aborting.');
        return;
    }

    if (currentFolderIndex >= stagingFolders.size()) {
        System.debug('All folders processed. Exiting.');
        finalizeDML(); 
        return;
    }

    String currentFolder = stagingFolders[currentFolderIndex];
    List<Map<String, Object>> files = getFilesFromFolder(accessToken, currentFolder);
    List<String> allErrors = new List<String>(); // 🔹 Collect all file-level errors

    if (files == null || files.isEmpty()) {
        System.debug('Folder empty: ' + currentFolder);
       
        System.enqueueJob(new AVO_SharePointFileProcessorQueue(currentFolderIndex + 1, 0));
        return;
    }

    Integer filesProcessed = 0;
    Integer i = currentFileIndex;
    for (; i < files.size() && filesProcessed < MAX_FILES_PER_BATCH; i++) {
        Map<String, Object> file = files[i];
        System.debug('Processing file: ' + file.get('Name'));
        List<String> errors = processFile(file, currentFolder);
        if (!errors.isEmpty()) {
            allErrors.addAll(errors);
        }
        filesProcessed++;
    }

    finalizeDML(); // Apply DML

    // Send notification for all errors after processing the batch
    if (!allErrors.isEmpty()) {
        sendNotificationEmail(allErrors);
    }

    if (i < files.size()) {
        System.enqueueJob(new AVO_SharePointFileProcessorQueue(currentFolderIndex, i));
    } else {
        System.enqueueJob(new AVO_SharePointFileProcessorQueue(currentFolderIndex + 1, 0));
    }
}

  */

    // For manual testing: Process one file from the first folder without using Queueable
    public static void testProcessSingleFile() {
        System.debug('--- Running testProcessSingleFile ---');
        
        AVO_Rest_API_Settings__c settings = AVO_Rest_API_Settings__c.getOrgDefaults();
        String accessToken = getAccessToken();
        System.debug('Access token: ' + accessToken);
        String siteUrl = settings.AVO_Site_Url__c;
        String directory = settings.AVO_Base_Directory__c;
        
        if (String.isBlank(accessToken)) {
            System.debug('Access token is null. Exiting.');
            return;
        }
        
        String testFolder = 'Application Staging Maps'; // Or 'Application Staging Maps'
        List<Map<String, Object>> files = getFilesFromFolder(accessToken, testFolder);
        
        if (files == null || files.isEmpty()) {
            System.debug('No files found in folder: ' + testFolder);
            return;
        }
        
        Map<String, Object> file = files[0];
        AVO_SharePointFileProcessor processor = new AVO_SharePointFileProcessor();
        processor.accessToken = accessToken;
        
        try {
            processor.processFile(file, testFolder);
            processor.finalizeDML(); // Save logs and files
        } catch (Exception ex) {
            System.debug('Error processing file: ' + ex.getMessage());
        }
        
        System.debug('--- testProcessSingleFile completed ---');
    }
    
    // This method is called when the job is executed
    public void execute(QueueableContext context) {
        System.debug('--- Starting SharePoint File Processing ---');
        
        // 1. Check governor limits first
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            System.debug('Queueable jobs limit reached. Pausing processing.');
            return;
        }
        
        // 2. Initialize batch processing control
        Integer filesProcessedInThisBatch = 0;
        final Integer MAX_FILES_PER_BATCH = 20; // Safe number within governor limits
        
        try {
            // 3. Main processing loop
            while (filesProcessedInThisBatch < MAX_FILES_PER_BATCH) {
                // If we need to load a new folder
                if (stagingFiles == null || stagingFiles.isEmpty()) {
                    if (currentFolderIndex >= stagingFolders.size()) {
                        // All folders processed
                        finalizeDML();
                        return;
                    }
                    
                    // Load next folder
                    String currentFolder = stagingFolders[currentFolderIndex];
                    System.debug('Loading files from folder: ' + currentFolder);
                    stagingFiles = getFilesFromFolder(accessToken, currentFolder);
                    currentFileIndex = 0;
                    
                    if (stagingFiles == null || stagingFiles.isEmpty()) {
                        // Empty folder - move to next
                        currentFolderIndex++;
                        continue;
                    }
                }
                
                // Process current file
                if (currentFileIndex < stagingFiles.size()) {
                    Map<String, Object> file = stagingFiles[currentFileIndex];
                    String stagingFolder = stagingFolders[currentFolderIndex];
                    
                    try {
                        processFile(file, stagingFolder);
                        filesProcessedInThisBatch++;
                    } catch (Exception ex) {
                        logsToInsert.add(logError((String)file.get('Name'), ex.getMessage()));
                    }
                    
                    currentFileIndex++;
                } else {
                    // Finished current folder - move to next
                    currentFolderIndex++;
                    stagingFiles = null;
                }
            }
            
            // 4. Determine if we need to continue processing
            if (currentFolderIndex < stagingFolders.size() || 
                (stagingFiles != null && currentFileIndex < stagingFiles.size())) {
                    System.debug('Enqueuing next batch with state: ' +
                                 'Folder ' + currentFolderIndex + '/' + stagingFolders.size() + 
                                 ', File ' + currentFileIndex + '/' + 
                                 (stagingFiles != null ? stagingFiles.size() : 0));
                   // System.enqueueJob(this);
                } else {
                    System.debug('Processing complete - finalizing DML');
                    finalizeDML();
                }
        } catch (Exception e) {
            System.debug('Error in execute: ' + e.getMessage() + '\n' + e.getStackTraceString());
            // Ensure we don't lose progress on error
            if (!logsToInsert.isEmpty() || !filesToInsert.isEmpty() || !filesToUpdate.isEmpty()) {
                finalizeDML();
            }
        }
    }
  public static String getAppIdFromFileName(String fileName) {
    try {
        if (String.isBlank(fileName)) {
            return null;
        }

        // Step 1: Remove the extension (e.g., .jpg)
        String baseName = fileName.substringBefore('.');

        // Step 2: Find first underscore (separating county name and App ID)
        Integer firstUnderscore = baseName.indexOf('_');
        if (firstUnderscore == -1 || firstUnderscore + 1 >= baseName.length()) {
            return null;
        }

        // Step 3: Get the portion after county name
        String remaining = baseName.substring(firstUnderscore + 1);

        // Step 4: Trim off optional trailing part like _G1, _G2, etc.
        Integer secondUnderscore = remaining.indexOf('_');
        String appId = (secondUnderscore != -1) ? remaining.substring(0, secondUnderscore) : remaining;

        return appId;
    } catch (Exception e) {
        System.debug('Error extracting App ID: ' + e.getMessage());
        return null;
    }
}

  /*  public static String getAppIdFromFileName(String fileName) {
        if (String.isBlank(fileName)) {
            return null;
        }
        
        // Step 1: Remove the extension (e.g., .jpg)
        String baseName = fileName.substringBefore('.');
        
        // Step 2: Find first underscore (separating county name and App ID)
        Integer firstUnderscore = baseName.indexOf('_');
        if (firstUnderscore == -1 || firstUnderscore + 1 >= baseName.length()) {
            return null;
        }
        
        // Step 3: Get the portion after county name
        String remaining = baseName.substring(firstUnderscore + 1);
        
        // Step 4: Trim off optional trailing part like _G1, _G2, etc.
        Integer secondUnderscore = remaining.indexOf('_');
        String appId = (secondUnderscore != -1) ? remaining.substring(0, secondUnderscore) : remaining;
        
        return appId;
    }*/
    // Method to process a single file
  public List<String> processFile(Map<String, Object> file, String stagingFolder) {
    List<String> errorMessages = new List<String>();
    String fileName = (String)file.get('Name');
    System.debug('Starting file processing for: ' + fileName);

    try {
        String[] nameParts = fileName.split('_');
        System.debug('Split nameParts: ' + nameParts);

        if (nameParts.size() < 2) {
            String error = 'Invalid file name format: ' + fileName;
            System.debug(error);
            errorMessages.add(error);
            logsToInsert.add(logError(fileName, error));
            return errorMessages;
        }

        String countyName = nameParts[0];
        String appId = getAppIdFromFileName(fileName);
        System.debug('Parsed county: ' + countyName + ', App ID: ' + appId);

        if (String.isBlank(appId)) {
            String error = 'Unable to extract App ID from file name: ' + fileName;
            System.debug(error);
            errorMessages.add(error);
            logsToInsert.add(logError(fileName, error));
            return errorMessages;
        }

        AVO_SharePoint_File_Log__c log = new AVO_SharePoint_File_Log__c(
            AVO_File_Name__c = fileName,
            AVO_Status__c = 'New',
            AVO_Application_Name__c = stagingFolder.contains('Application') ? appId : null,
            AVO_Permit_Name__c = stagingFolder.contains('Permit') ? appId : null
        );

        Id parentId = null;
        List<AVO_SharePoint_File__c> existing = new List<AVO_SharePoint_File__c>();
        String mainFolder = stagingFolder.contains('Application') ? 'Application Maps' : 'Permit Maps';
        System.debug('Main folder determined: ' + mainFolder);

        if (mainFolder == 'Permit Maps' || mainFolder == 'Application Maps') {
            List<MUSW__Permit2__c> permits = [SELECT Id FROM MUSW__Permit2__c WHERE Name = :appId LIMIT 1];
            System.debug('Permit query result size: ' + permits.size());
            if (!permits.isEmpty()) {
                parentId = permits[0].Id;
                System.debug('Matched permit ID: ' + parentId);
                existing = [SELECT Id FROM AVO_SharePoint_File__c WHERE Name = :fileName AND AVO_Permit__c = :parentId LIMIT 1];
            }
        }

        if (parentId == null) {
            String error = 'No matching Permit found for AppID: ' + appId + ' from file: ' + fileName;
            System.debug(error);
            log.AVO_Status__c = 'Error';
            log.AVO_Comment__c = error;
            logsToInsert.add(log);
            errorMessages.add(error);
            return errorMessages;
        }

        String sourcePath = Directory + stagingFolder.replace(' ', '%20') + '/' + fileName;
        String destPath = Directory + mainFolder.replace(' ', '%20') + '/' + fileName;
        System.debug('Source path: ' + sourcePath);
        System.debug('Destination path: ' + destPath);

        String moveResult = moveFileRaw(sourcePath, destPath, true, accessToken);
        System.debug('Move result: ' + moveResult);

        if (!moveResult.startsWith('File moved')) {
            String error = 'Move failed for file: ' + fileName + ' → ' + moveResult;
            System.debug(error);
            log.AVO_Status__c = 'Error';
            log.AVO_Comment__c = error;
            logsToInsert.add(log);
            errorMessages.add(error);
            return errorMessages;
        }

        log.AVO_Status__c = 'Moved';
        log.AVO_Comment__c = 'File moved successfully from staging to main folder.';

        String folderPath = Directory + mainFolder.replace(' ', '%20') + '/';
        Http http = new Http();
        SharePointFileInfo linkInfo = getAccessLink(folderPath, fileName, accessToken, http, false);
        System.debug('Access link: ' + linkInfo.url + ', Item ID: ' + linkInfo.itemId);

        Boolean exists = !existing.isEmpty();
        System.debug('Does file already exist? ' + exists);

        if (!exists) {
            AVO_SharePoint_File__c spFile = new AVO_SharePoint_File__c(
                Name = fileName,
                AVO_Permit__c = parentId,
                AVO_SharePoint_URL_Text__c = linkInfo.url,
                AVO_SharePoint_URL__c = linkInfo.url,
                AVO_SharePoint_External_Link__c = linkInfo.url,
                AVO_ContentDocumentId__c = null,
                AVO_SharePoint_Item_Id__c = linkInfo.itemId
            );

            filesToInsert.add(spFile);
            log.AVO_Status__c = 'Link Generated';
            log.AVO_Comment__c = 'SharePoint link generated and metadata record created.';
        } else {
            AVO_SharePoint_File__c updateSPFile = existing[0];
            updateSPFile.AVO_SharePoint_URL_Text__c = linkInfo.url;
            updateSPFile.AVO_SharePoint_URL__c = linkInfo.url;
            updateSPFile.AVO_SharePoint_External_Link__c = linkInfo.url;
            updateSPFile.AVO_SharePoint_Item_Id__c = linkInfo.itemId;

            filesToUpdate.add(updateSPFile);
            log.AVO_Status__c = 'Duplicate Found';
            log.AVO_Comment__c = 'File already exists. Link updated.';
        }

        logsToInsert.add(log);

    } catch (Exception ex) {
        String error = 'Unexpected error for file "' + fileName + '": ' + ex.getMessage();
        System.debug(error);
        errorMessages.add(error);
    }

    return errorMessages;
}



  /*  public void processFile(Map<String, Object> file, String stagingFolder) {
        String fileName = (String)file.get('Name');
        String[] nameParts = fileName.split('_');
        
        if (nameParts.size() < 2) {
            logsToInsert.add(logError(fileName, 'Invalid file name format'));
            return;
        }
       
        String countyName = nameParts[0];
        // Integer lastUnderscoreIndex = fileName.lastIndexOf('_');
        // String appId = fileName.substring(lastUnderscoreIndex + 1, fileName.lastIndexOf('.'));
        String appId = getAppIdFromFileName(fileName);
        System.debug('Processing file: ' + fileName);
        System.debug('Parsed county: ' + countyName + ', App ID: ' + appId);
        
       
        //Change Folder String mainFolder = stagingFolder.contains('Application') ? 'Application Staging Maps' : 'Permit Staging Maps';
        AVO_SharePoint_File_Log__c log = new AVO_SharePoint_File_Log__c(
            AVO_File_Name__c = fileName,
            AVO_Status__c = 'New',
            AVO_Application_Name__c = stagingFolder.contains('Application') ? appId : null,
            AVO_Permit_Name__c = stagingFolder.contains('Permit') ? appId : null
        );
         Id parentId = null;
        List<AVO_SharePoint_File__c> existing = new List<AVO_SharePoint_File__c>();
         String mainFolder = stagingFolder.contains('Application') ? 'Application Maps' : 'Permit Maps';
        if (mainFolder == 'Permit Maps' || mainFolder == 'Application Maps') {
            List<MUSW__Permit2__c> permits = [SELECT Id FROM MUSW__Permit2__c WHERE Name = :appId LIMIT 1];
            if (!permits.isEmpty()) {
                parentId = permits[0].Id;
                existing = [SELECT Id FROM AVO_SharePoint_File__c WHERE Name = :fileName AND AVO_Permit__c = :parentId LIMIT 1];
            }
        } 
        
        
        if (parentId == null) {
            log.AVO_Status__c = 'Invalid Permit Name';
            log.AVO_Comment__c = 'No matching record found for AppID: ' + appId;
            logsToInsert.add(log);
            System.debug('No parent record found for AppID: ' + appId);
            return;
        }
        
        
        String sourcePath = Directory + stagingFolder.replace(' ', '%20') + '/' + fileName;
        String destPath = Directory + mainFolder.replace(' ', '%20') + '/' + fileName;
        String moveResult = moveFileRaw(sourcePath, destPath, true, accessToken);
        
        System.debug('Source path: ' + sourcePath);
        System.debug('Destination path: ' + destPath);
        System.debug('Move result: ' + moveResult);
        
        if (!moveResult.startsWith('File moved')) {
            log.AVO_Status__c = 'Error';
            log.AVO_Comment__c = 'File move failed: ' + moveResult;
            logsToInsert.add(log);
            return;
        }
        
        log.AVO_Status__c = 'Moved';
        log.AVO_Comment__c = 'File moved successfully from staging to main folder.';
        
        // Generate SharePoint access link and file ID
        String folderPath = Directory + mainFolder.replace(' ', '%20') + '/';
        Http http = new Http();
        SharePointFileInfo linkInfo = getAccessLink(folderPath, fileName, accessToken, http, false);
        
        System.debug('SharePoint Access URL: ' + linkInfo.url);
        System.debug('SharePoint File ID: ' + linkInfo.itemId);
        
        
        
        Boolean exists = !existing.isEmpty();
        
        if (!exists) {
            AVO_SharePoint_File__c spFile = new AVO_SharePoint_File__c();
            spFile.Name = fileName;
            
            // Set correct parent reference
            if (mainFolder == 'Permit Maps') {
                spFile.AVO_Permit__c = parentId;
            } else if (mainFolder == 'Application Maps') {
                //Initially Permit is Application and once Application has been issued then it become permit
                //spFile.AVO_Application__c = parentId;
                spFile.AVO_Permit__c = parentId;
            }
            
            // Assign values to spFile
            spFile.AVO_SharePoint_URL_Text__c = linkInfo.url;
            spFile.AVO_SharePoint_URL__c = linkInfo.url;
            spFile.AVO_SharePoint_External_Link__c = linkInfo.url;
            spFile.AVO_ContentDocumentId__c = null;
            spFile.AVO_SharePoint_Item_Id__c = linkInfo.itemId;
            
            filesToInsert.add(spFile);
            
            log.AVO_Status__c = 'Link Generated';
            log.AVO_Comment__c = 'SharePoint link generated and metadata record created.';
        } else {
            AVO_SharePoint_File__c updateSPFile = existing[0];
            
            updateSPFile.AVO_SharePoint_URL_Text__c = linkInfo.url;
            updateSPFile.AVO_SharePoint_URL__c = linkInfo.url;
            updateSPFile.AVO_SharePoint_External_Link__c = linkInfo.url;
            updateSPFile.AVO_SharePoint_Item_Id__c = linkInfo.itemId;
            
            filesToUpdate.add(updateSPFile);
            
            log.AVO_Status__c = 'Duplicate Found';
            log.AVO_Comment__c = 'File already exists in AVO_SharePoint_File__c. Link updated for the existing record.';
        }
        
        logsToInsert.add(log);
        System.debug('--- Processing completed for file: ' + fileName + ' ---');
    }*/
    
    // Method to perform all DML operations at the end
    public void finalizeDML() {
        System.debug('Finalizing DML operations');
        
        if (!filesToInsert.isEmpty()) insert filesToInsert;
        if (!filesToUpdate.isEmpty()) update filesToUpdate;
        if (!logsToInsert.isEmpty()) insert logsToInsert;
        
        System.debug('--- SharePoint File Processing Completed ---');
    }
   

   
    
    // All the other methods remain the same
    public static List<Map<String, Object>> getFilesFromFolder(String accessToken, String folderName) {
        // Original implementation
        List<Map<String, Object>> items = new List<Map<String, Object>>();
        try {
            Http http = new Http();
            if (String.isBlank(accessToken)) return items;
            
            String folderPath = Directory + folderName.replace(' ', '%20') + '/';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(SITE_URL + '_api/web/GetFolderByServerRelativeUrl(\'' + folderPath + '\')/Files?$select=Name,ServerRelativeUrl,TimeCreated,TimeLastModified');
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Accept', 'application/json;odata=verbose');
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                Map<String, Object> d = (Map<String, Object>)responseMap.get('d');
                List<Object> files = (List<Object>)((Map<String, Object>)d).get('results');
                
                for (Object fileObj : files) {
                    Map<String, Object> file = (Map<String, Object>)fileObj;
                    String fileName = (String)file.get('Name');
                    String fileUrl = (String)file.get('ServerRelativeUrl');
                    String timeCreated = (String)file.get('TimeCreated');
                    String timeModified = (String)file.get('TimeLastModified');
                    
                    Map<String, Object> fileInfo = new Map<String, Object>{
                        'Type' => 'File',
                            'Name' => fileName,
                            'Url' => fileUrl,
                            'TimeCreated' => timeCreated,
                            'TimeLastModified' => timeModified
                            };
                                items.add(fileInfo);
                    System.debug('fileName: ' + fileName);
                    
                }
            } else {
                System.debug('Error fetching folder data: ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        return items;
    }
    
    // The rest of your methods remain the same
    public static SharePointFileInfo getAccessLink(String folderName, String fileName, String accessToken, 
                                                   Http http, Boolean allowAnonymousAccess) 
    {
        // Original implementation
        SharePointFileInfo result = new SharePointFileInfo();
        try {
            String url = '';
            
            HttpRequest httpRequestToSend = new HttpRequest();  
            
            String endpoint = siteUrl+'_api/web/' +
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
                body = '{"request":{"createLink":true,"settings":{"allowAnonymousAccess":false,"trackLinkUsers":false,"linkKind":3,"expiration":null,"role":1,"restrictShareMembership":false,"updatePassword":false,"password":"","scope":0}}}';
            }
            
            httpRequestToSend.setBody(body);
            System.Debug('Access link body: '+body);
            
            HttpResponse responseFileRequest = http.send(httpRequestToSend); 
            if (responseFileRequest.getStatusCode() != 200) {
                String errorMessage = 'The status code returned was not expected: ' + responseFileRequest.getStatusCode() + ' ' + responseFileRequest.getBody();
                System.Debug('Access link Error: '+errorMessage);
                url = errorMessage;
                result.url = url;
            } 
            else {
                LinkResponse linkResponse = (LinkResponse)JSON.deserialize(responseFileRequest.getBody(), LinkResponse.class);
                
                System.debug('Anonymous Access Link Response: ' + linkResponse);
                
                url = linkResponse.d.ShareLink.sharingLinkInfo.Url;
                
                System.Debug('Access link: '+url);
                result.url = url;
            }
            String fileId = getFileItemId(folderName, fileName, http, accessToken);
            System.debug('File Item ID: ' + fileId);
            result.itemId = fileId;
        } catch (Exception e) {
            System.debug('Exception in getAccessLink: ' + e.getMessage());
            result.url = null;
            result.itemId = null;
        }
        
        return result;
    }
    
    private static AVO_SharePoint_File_Log__c logError(String fileName, String errorMsg) {
        return new AVO_SharePoint_File_Log__c(
            AVO_File_Name__c = fileName,
            AVO_Status__c = 'Error',
            AVO_Comment__c = errorMsg
        );
    }
    
    public static String moveFileRaw(String sourceFilePath, String destFilePath, Boolean overwrite, String accessToken) {
        try {
            if (accessToken == null) return 'Failed to obtain access token.';
            
            Integer flagValue = overwrite ? 1 : 0;
            String endpoint = SITE_URL + '_api/web/GetFileByServerRelativeUrl(\'' + sourceFilePath + '\')/moveto(newurl=\'' + destFilePath + '\',flags=' + flagValue + ')';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Accept', 'application/json;odata=verbose');
            req.setHeader('Content-Length', '0');
            req.setTimeout(DEFAULT_TIMEOUT);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) return 'File moved successfully using raw method.';
            return 'Error (raw method): ' + res.getStatusCode() + ' ' + res.getStatus() + '\n' + res.getBody();
            
        } catch (Exception e) {
            return 'Exception (raw method): ' + e.getMessage();
        }
    }
    public static String getAccessToken() {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(settings.AVO_Token_End_Point__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String payload = 'client_id=' + EncodingUtil.urlEncode(settings.AVO_Client_ID__c, 'UTF-8') +
            '&client_secret=' + EncodingUtil.urlEncode(settings.AVO_Client_Secret__c, 'UTF-8') +
            '&grant_type=' + EncodingUtil.urlEncode(settings.AVO_Grant_Type__c, 'UTF-8') +
            '&resource=' + EncodingUtil.urlEncode(settings.AVO_Resource__c, 'UTF-8');

        req.setBody(payload);
        req.setTimeout(DEFAULT_TIMEOUT);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Token Response Status Code: ' + res.getStatusCode());
        System.debug('Token Response Body: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) result.get('access_token');
        } else {
            System.debug('Failed to get token. HTTP Status: ' + res.getStatusCode());
            return null;
        }

    } catch (Exception e) {
        System.debug('Exception in getAccessToken: ' + e.getMessage());
        return null;
    }
}

  
    
    public static String getFileItemId(String folderPath, String fileName, Http http, String accessToken) {
        try {
            String endpoint = siteUrl + '_api/web/GetFileByServerRelativePath(decodedurl=\'' + folderPath + '/' + fileName + '\')/ListItemAllFields';
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Accept', 'application/json;odata=verbose');
            
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> d = (Map<String, Object>) jsonMap.get('d');
                return String.valueOf(d.get('Id'));
            } else {
                System.debug('Error fetching file metadata: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception fetching File ID: ' + e.getMessage());
        }
        return null;
    }
    public static void sendNotificationEmail(List<String> errors) {
    try {
        // Step 1: Get the UserRoleId for 'GIS Specialist'
        /*Id gisRoleId;
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE Name = 'GIS Specialist' LIMIT 1];
        if (!roles.isEmpty()) {
            gisRoleId = roles[0].Id;
        }

        // Step 2: Get active users with that role
        List<User> users = new List<User>();
        if (gisRoleId != null) {
            users = [SELECT Email FROM User WHERE UserRoleId = :gisRoleId AND IsActive = true];
        }*/

        // Step 3: Build email
        List<String> toEmails = new List<String>();
        /*for (User u : users) {
            if (String.isNotBlank(u.Email)) {
                toEmails.add(u.Email);
            }
        }*/

        // If no emails found, use fallback
        if (toEmails.isEmpty()) {
            toEmails.add('raj.ahuja@avocette.com'); // fallback email
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toEmails);
        //email.setBccAddresses(new List<String>{'raj.ahuja@avocette.com'});
        email.setSubject('Application / Permit Maps Processing Errors');
        email.setPlainTextBody('The following errors occurred during processing of files:\n' + String.join(errors, '\n'));

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        System.debug('Email sent to: ' + toEmails);
    } catch (Exception e) {
        System.debug('Failed to send error notification email: ' + e.getMessage());
    }
}

   /* public static void sendNotificationEmail(List<String> errors) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
       // email.setToAddresses(new List<String>{'sp-clariti@avocette.com'});
        email.setToAddresses(new List<String>{'swathi.prayaga@dnr.ga.gov'});
        email.setBccAddresses(new List<String>{'raj.ahuja@avocette.com'});
        email.setSubject('Application / Permit Maps Processing Errors');
        email.setPlainTextBody('The following errors occurred during Processing of files:\n' + String.join(errors, '\n'));
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('Email Sent');
        } catch (Exception e) {
            System.debug('Failed to send error notification email: ' + e.getMessage());
        }
    }*/
    
    
    // Inner classes remain the same
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
    
    public class SharePointFileInfo {
        public String url;
        public String itemId;
    }
}