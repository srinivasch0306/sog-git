// AvoMigrationTools mt = new AvoMigrationTools();
// mt.GenerateManifest('a1059000000l5oxAAA');
// Justin Test

public with sharing class AvoMigrationTools {
    Map<String,String> objectMap = new Map<String,String>();
    Map<String,String> managedLayouts = new Map<String,String>();
    list<string> objectList  = new List<string>();
    list<string> fieldList  = new List<string>();
    list<string> layoutList = new List<string>();
    list<string> queueList =  new List<string>();     
    List<String> apexClassList = new List<String>();   
    List<String> apexTriggerList = new List<String>();
    List<String> auraComponentList = new List<String>();
    List<String> flowList = new List<String>();
    List<String> lwcList = new List<String>();
    List<String> globalValueSetList = new List<String>();
    List<String> quickActionList = new List<String>();
    List<String> flexiPageList = new List<String>();
    List<String> validationRuleList = new List<String>();
    List<String> customMetadataList = new List<String>();
    List<String> reportList = new List<String>();
    List<String> dashboardList = new List<String>();
    List<String> emailTemplateList = new List<String>();
    List<String> pathAssistantList = new List<String>();
    List<String> apexPageList = new List<String>();
    List<String> customApplicationList = new List<String>();
    List<String> customLabelList = new List<String>();
    List<String> profileList = new List<String>();
    List<String> permissionSetList = new List<String>();
    List<String> permissionSetGroupList = new List<String>();
    List<String> roleList = new List<String>();
    List<String> contentAssetList = new List<String>();
    List<String> remoteSiteSettingList = new List<String>();
    List<String> staticResourceList = new List<String>();
    List<String> approvalProcessList = new List<String>();
    List<String> workflowList = new List<String>();
    List<String> workflowAlertList = new List<String>();
    // List<String> workflowFieldUpdateList = new List<String>();
    //List<String> externalCredentialList = new List<String>();
    //List<String> namedCredentialList = new List<String>();
    List<EntityDefinition> EntityDefinitions =  new List<EntityDefinition>(); 

    private string content = '';
    private string typeBegin = '    <types>';
    private string typeEnd = '    </types>';
    private string twoTabs = '        ';
    

    public AvoMigrationTools() {
        identifyManagedPageLayouts();
    }

    public void GenerateManifest(ID entityId){
        
        retreiveCustomObject();
        retrieveQueues();     
        retrieveApexClasses(); 
        retrieveApexTriggers();
        retrieveAuraComponents();
        retrieveCustomMetadata();
        retrieveReports();
        retrieveDashboards();
        retrieveEmailTemplates();
        retrievePathAssistants();
        retrieveApexPages();
        retrieveCustomApplications();
        retrieveCustomLabels();
        retrieveProfiles();
        retrieveFlows();
        retrieveLwcs();
        retrievePermissionSets();
        retrievePermissionSetGroups();
        retrieveRoles();
        retrieveContentAssets();
        retrieveRemoteSiteSettings();
        retrieveStaticResources();
        retrieveApprovalProcesses();
        retrieveWorkflowAlerts();
        //retrieveExternalCredentials();
        //retrieveNamedCredentials();
        retrieveToolingAPIObject('GlobalValueSet', 'DeveloperName', globalValueSetList, true, false, false, '');
        retrieveToolingAPIObject('QuickActionDefinition', 'DeveloperName', quickActionList, true, false, true, 'SobjectType');
        retrieveToolingAPIObject('FlexiPage', 'DeveloperName', flexiPageList, true, false, false, '');
        retrieveToolingAPIObject('ValidationRule', 'ValidationName', validationRuleList, true, false, true, 'EntityDefinition.QualifiedApiName');
        generateHeader();
        generate('CustomObject', objectList);
        //generate('Layout', layoutList);        
        generate('Queue', queueList);
        generate('ApexClass', apexClassList);
        generate('ApexTrigger', apexTriggerList);
        generate('AuraDefinitionBundle', auraComponentList);
        generate('CustomMetadata', customMetadataList);
        generate('Report', reportList);
        generate('Dashboard', dashboardList);
        generate('EmailTemplate', emailTemplateList);
        generate('Flow', flowList);
        generate('LightningComponentBundle', lwcList);
        generate('GlobalValueSet', globalValueSetList);
        generate('QuickAction', quickActionList);
        generate('FlexiPage', flexiPageList);
        generate('ValidationRule', validationRuleList);
        generate('PathAssistant', pathAssistantList);
        generate('ApexPage', apexPageList);
        generate('CustomApplication', customApplicationList);
        generate('CustomLabel', customLabelList);
        generate('PermissionSet', permissionSetList);
        generate('PermissionSetGroup', permissionSetGroupList);
        generate('Role', roleList);
        generate('ContentAsset', contentAssetList);
        generate('RemoteSiteSetting', remoteSiteSettingList);
        generate('StaticResource', staticResourceList);
        generate('ApprovalProcess', approvalProcessList);
        generate('Workflow', workflowList);
        generate('WorkflowAlert', workflowAlertList);
        // generate('WorkflowFieldUpdate', workflowFieldUpdateList);
        //generate('ExternalCredential', externalCredentialList);
        //generate('NamedCredential', namedCredentialList);
        generate('Profile', profileList);
        generateFooter();

    // next priorities
    // Global Picklist Values  - using SFDX -- done
    // Flex Page – using SFDX (objects) -- done
    // Quick actions -- done
    // APEX classes (AVO_) - done
    // LWC (AVO_) - done
    // Aura (AVO_) - done
    // Apex Triggers - done
    // Flows - done
    // Email Templates -- classic vs lightning
    // Reports Dashboards -- done
    // Custom Metadata - done


    // future in-scope items
    // CompactLayout
    // CustomField
    // CustomObject
    // FieldSet
    // ListView
    // RecordType
    // ValidationRule - done
    // WebLink
 



        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
        String theName = 'package';
        conVer.PathOnClient = theName +'.xml'; // The files name, extension is very important here which will help the file in preview.
        conVer.Title = theName; // Display name of the files
        conVer.VersionData = Blob.valueof(content); // converting your binary string to Blog
        Insert conVer;    //Insert ContentVersion


        // First get the Content Document Id from ContentVersion Object
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :conVer.Id].ContentDocumentId;

        //create ContentDocumentLink  record
        ContentDocumentLink conDocLink = New ContentDocumentLink();
        conDocLink.LinkedEntityId = entityId ; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object), it can be your user, for example
        conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
        conDocLink.shareType = 'I';
        conDocLink.Visibility = 'AllUsers';
        Insert conDocLink;
    } 

    private void generateCustomObject() {
        typeBegin();
        objectList.sort();
        for(string key : objectList) { 
            addMember(key);
        }
        specifyType('CustomObject');
        typeEnd();
    }

    private void generateCustomField() {
        typeBegin();
        fieldList.sort();
        for(string key : fieldList) { 
            addMember(key);
        }
        specifyType('CustomField');
        typeEnd();
    }   

    private void generate(string type, List<string> data) {
        typeBegin();
        data.sort();
        for(string key : data) { 
            addMember(key);
        }
        specifyType(type);
        typeEnd();
    }
    private void retrieveQueues() {
        List<Group> queues = [SELECT Id, Name, DeveloperName, Email, Type FROM Group WHERE Type='Queue'];
        for (Group queue : queues) {
            queueList.add(queue.DeveloperName);            
        }
    }

    private void retrieveApexClasses() {
        //List<ApexClass> apxClasses = [SELECT Id, Name FROM ApexClass WHERE ((Name LIKE 'avo%') OR (Name LIKE 'RT_%') OR (Name LIKE 'TestDataFactory%'))];
        List<ApexClass> apxClasses = [SELECT Id, Name FROM ApexClass WHERE NamespacePrefix = null];
        for (ApexClass apxClass : apxClasses) {
            apexClassList.add(apxClass.Name);            
        }
    }

    private void retrieveApexTriggers() {
        //List<ApexTrigger> apxTriggers = [SELECT Id, Name FROM ApexTrigger WHERE ((Name LIKE 'avo%'))];
        List<ApexTrigger> apxTriggers = [SELECT Id, Name FROM ApexTrigger WHERE NamespacePrefix = null];
        for (ApexTrigger apxTrigger : apxTriggers) {
            apexTriggerList.add(apxTrigger.Name);            
        }
    }

    private void retrieveApexPages() {
        List<ApexPage> apxPages = [SELECT Id, Name FROM ApexPage WHERE NameSpacePrefix = null];
        for (ApexPage apxPage : apxPages) {
            apexPageList.add(apxPage.Name);
        }
    }

    private void retrieveAuraComponents() {
        List<AuraDefinitionBundle> auraComponents = [SELECT Id, DeveloperName FROM AuraDefinitionBundle WHERE ((DeveloperName LIKE 'avo%') OR (DeveloperName LIKE 'acc%'))];
        for (AuraDefinitionBundle auraComponent : auraComponents) {
            auraComponentList.add(auraComponent.DeveloperName);            
        }
    }

    private void retrieveEmailTemplates() {
        List<EmailTemplate> emailTemplates = [SELECT Name, DeveloperName, FolderName, FolderId FROM EmailTemplate WHERE Folder.Name='Application' OR Folder.Name='Complaint' OR Folder.Name='License' OR Folder.Name='Others' OR Folder.Name='Permit' OR Folder.Name='Review' OR Folder.Name='Violation'];
        for (EmailTemplate emailTemp : emailTemplates) {
            emailTemplateList.add(emailTemp.FolderName + '/' + emailTemp.DeveloperName);            
        }
    }

    private void retrievePermissionSets() {
        List<PermissionSet> permissionSets = [SELECT Name FROM PermissionSet WHERE NamespacePrefix = null AND Type = 'Regular'];
        for (PermissionSet permSet : permissionSets) {
            permissionSetList.add(permSet.Name);
        }
    }

    private void retrievePermissionSetGroups() {
        List<PermissionSetGroup> permissionSetGroups = [SELECT DeveloperName FROM PermissionSetGroup WHERE NamespacePrefix = null];
        for (PermissionSetGroup permSetGroup : permissionSetGroups) {
            permissionSetGroupList.add(permSetGroup.DeveloperName);
        }
    }

    private void retrieveApprovalProcesses() {
        List<ProcessDefinition> approvalProcesses = [SELECT DeveloperName, TableEnumOrId FROM ProcessDefinition];
        for (ProcessDefinition approvalProcess : approvalProcesses) {
            approvalProcessList.add(approvalProcess.TableEnumOrId + '.' + approvalProcess.DeveloperName);
        }
    }

    private void retrieveRoles() {
        List<UserRole> roles = [SELECT DeveloperName FROM UserRole];
        for (UserRole role : roles) {
            roleList.add(role.DeveloperName);
        }
    }

    private void retrieveContentAssets() {
        List<ContentAsset> contentAssets = [SELECT DeveloperName FROM ContentAsset WHERE NamespacePrefix = null];
        for (ContentAsset contAsset : contentAssets) {
            contentAssetList.add(contAsset.DeveloperName);
        }
    }

    private void retrieveStaticResources() {
        List<StaticResource> staticResources = [SELECT Name FROM StaticResource WHERE NamespacePrefix = null];
        for (StaticResource statResource : staticResources) {
            staticResourceList.add(statResource.Name);
        }
    }

    private void retrieveRemoteSiteSettings() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, SiteName FROM RemoteProxy WHERE NamespacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('SiteName');
            remoteSiteSettingList.add(recordName);
        }
    }
    /*
    private void retrieveExternalCredentials() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, DeveloperName FROM ExternalCredential WHERE NamespacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('DeveloperName');
            externalCredentialList.add(recordName);
        }
    }

    private void retrieveNamedCredentials() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, DeveloperName FROM NamedCredential WHERE NamespacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('DeveloperName');
            namedCredentialList.add(recordName);
        }
    }
    */
    private void retrievePathAssistants() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, DeveloperName FROM PathAssistant WHERE NameSpacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('DeveloperName');
            pathAssistantList.add(recordName);
        }
    }

    private void retrieveFlows() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, DeveloperName FROM FlowDefinition WHERE NameSpacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('DeveloperName');
            flowList.add(recordName);
        }
    }

    private void retrieveWorkflowAlerts() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, DeveloperName, EntityDefinition.QualifiedApiName FROM WorkflowAlert WHERE NamespacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);
        Set<String> workflowSet = new Set<String>();
        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('DeveloperName');
            Map<String, Object> entityDefinitionMap = (Map<String, Object>) recordMap.get('EntityDefinition');
            String entityName = (String) entityDefinitionMap.get('QualifiedApiName');
            workflowAlertList.add(entityName + '.' + recordName);
            workflowSet.add(entityName);
        }
        for (String workflowName : workflowSet) {
            workflowList.add(workflowName);
        }
    }
    /*
    private void retrieveWorkflowFieldUpdates() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, DeveloperName, EntityDefinition.QualifiedApiName FROM WorkflowFieldUpdate WHERE NamespacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('DeveloperName');
            Map<String, Object> entityDefinitionMap = (Map<String, Object>) recordMap.get('EntityDefinition');
            String entityName = (String) entityDefinitionMap.get('QualifiedApiName');
            workflowAlertList.add(entityName + '.' + recordName);
            workflowNames.add(entityName);
        }
    }
   */

    private void retrieveLwcs() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, DeveloperName FROM LightningComponentBundle WHERE NameSpacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('DeveloperName');
            lwcList.add(recordName);
        }
    }

    private void retrieveCustomApplications() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, DeveloperName FROM CustomApplication WHERE NameSpacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('DeveloperName');
            customApplicationList.add(recordName);
        }
    }

    private void retrieveCustomLabels() {
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, Name FROM CustomLabel WHERE NameSpacePrefix = null';

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;
            String recordName = (String) recordMap.get('Name');
            customLabelList.add(recordName);
        }
    }

    private void retrieveProfiles() {
        List<Profile> profiles = [SELECT Name FROM Profile WHERE Name LIKE 'AVO%'];
        for (Profile profileElement : profiles) {
            profileList.add(profileElement.Name);            
        }
        profileList.add('Admin');
    }

    private void retrieveCustomMetadata() {
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()) {
            String name = objTyp.getDescribe().getName();
            String label = objTyp.getDescribe().getLabel();
            if ( name.endsWithIgnoreCase('__mdt')) {      
                objectList.add(name);
                String myQuery = 'SELECT Id, DeveloperName, NamespacePrefix FROM ' + name;
                List<SObject> metadataRecords = Database.query(myQuery);
                for (SObject metadataRecord : metadataRecords) {
                    String recordName = (String) metadataRecord.get('DeveloperName');
                    String prefixName = (String) metadataRecord.get('NamespacePrefix');
                    if (!String.isBlank(prefixName)) {
                        customMetadataList.add(name.removeEndIgnoreCase('__mdt') + '.' + prefixName + '__' + recordName);
                    } else {
                        customMetadataList.add(name.removeEndIgnoreCase('__mdt') + '.' + recordName);
                    }
                    
                }
            }
        }
    }

    private void retrieveReports() {
        List<Report> reportCollection = [SELECT Id, DeveloperName, NamespacePrefix, FolderName, OwnerId FROM Report WHERE FolderName != 'Private Reports'];

        Set<Id> folderIdSet = new Set<Id>();
        for (Report currentReport : reportCollection) {
            if (currentReport.FolderName != 'Public Reports') {
                folderIdSet.add(currentReport.OwnerId);
            }
        }

        Map<Id, Folder> folderMap = new Map<Id, Folder>([SELECT Id, DeveloperName, NamespacePrefix FROM Folder WHERE Id IN :folderIdSet]);

        for (Report currentReport : reportCollection) {
            String reportName = '';
            if (currentReport.FolderName == 'Public Reports') {
                reportName += 'unfiled$public/';
            } else {
                Folder currentFolder = folderMap.get(currentReport.OwnerId);
                if (!String.isBlank(currentFolder.NamespacePrefix)) {
                    reportName += currentFolder.NamespacePrefix + '__';
                }
                reportName += currentFolder.DeveloperName + '/';
            }
            if (!String.isBlank(currentReport.NamespacePrefix)) {
                reportName += currentReport.NamespacePrefix + '__';
            }
            reportName += currentReport.DeveloperName;
            reportList.add(reportName);
        }
    }

    private void retrieveDashboards() {
        List<Dashboard> dashboardCollection = [SELECT Id, DeveloperName, NamespacePrefix, FolderName, FolderId FROM Dashboard WHERE FolderName != 'Private Dashboards'];

        Set<Id> folderIdSet = new Set<Id>();
        for (Dashboard currentDashboard : dashboardCollection) {
            folderIdSet.add(currentDashboard.FolderId);
        }

        Map<Id, Folder> folderMap = new Map<Id, Folder>([SELECT Id, DeveloperName, NamespacePrefix FROM Folder WHERE Id IN :folderIdSet]);

        for (Dashboard currentDashboard : dashboardCollection) {
            String dashboardName = '';

            Folder currentFolder = folderMap.get(currentDashboard.FolderId);
            if (!String.isBlank(currentFolder.NamespacePrefix)) {
                dashboardName += currentFolder.NamespacePrefix + '__';
            }
            dashboardName += currentFolder.DeveloperName + '/';
            
            if (!String.isBlank(currentDashboard.NamespacePrefix)) {
                dashboardName += currentDashboard.NamespacePrefix + '__';
            }
            dashboardName += currentDashboard.DeveloperName;
            dashboardList.add(dashboardName);
        }
    }

    private void retreiveCustomObject(){         

        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()) {
           String name = objTyp.getDescribe().getName();
           String label = objTyp.getDescribe().getLabel();
           if ( (name.containsignorecase('Action_Flow_Execution_History') || !name.containsignorecase('history')) && !name.containsignorecase('tag') &&
                (name.containsignorecase('SharePoint_File') || !name.containsignorecase('share')) && !name.containsignorecase('feed') && 
               	!name.containsignorecase('group') && !name.containsignorecase('public') &&
                (name.containsignorecase('ACM_Settings') || name.containsignorecase('Rest_API_Settings') || name.containsignorecase('GIS_Settings') || !objTyp.getDescribe().isCustomSetting()) && objTyp.getDescribe().isCreateable() &&
                ( name.containsignorecase('clariti') || name.containsignorecase('avo') 
                    || name.containsignorecase('musw') || name.containsignorecase('bgbk') || name.containsignorecase('bgbl') || name.containsignorecase('Object_Notes__c') || name.containsignorecase('Contact_Owner_Information__c') || name.containsignorecase('Master_') || name.containsignorecase('Officer_Details__c') || name.containsignorecase('License_Information__c')) &&
                objTyp.getDescribe().getRecordTypeInfos().size() > 0) {      
                // objectMap.put(name,label);
                objectList.add(name);
                //fieldList.addAll(getFieldApiNames(name));                
           }
        }        
        objectList.add('Account');
        objectList.add('Contact');
        objectList.add('User');
        // https://salesforce.stackexchange.com/questions/270744/how-can-i-get-the-custom-object-tooling-api-id
        entityDefinitions = [SELECT QualifiedApiName, DurableId FROM EntityDefinition WHERE QualifiedApiName IN :objectList];
        system.debug('size of objectList: ' + objectList.size());
        system.debug('size of entity definitions: ' + entityDefinitions.size());

        integer count = 0;
        for (string key : objectList) {
            count ++;
            system.debug(count);
            //layoutList.addAll(getLayouts(key));
        }
    }    

    private void retrieveToolingAPIObject(String objectName, String nameField, List<String> outputList, Boolean useNameSpacePrefix, Boolean queryAvoPrefix, Boolean useSObjectNamePrefix, String sObjectField) {
        
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query= 'SELECT Id, ' + nameField;

        if (useNameSpacePrefix) {
            query = query + ', NamespacePrefix';
        }

        if (useSObjectNamePrefix) {
            query = query + ', ' + sObjectField;
        }

        query = query + ' FROM ' + objectName;

        if (queryAvoPrefix) {
            query = query + ' WHERE ' + nameField + ' LIKE \'avo%\'';
        }

        String endpointString = SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+EncodingUtil.urlEncode(query, 'UTF-8');
        //system.debug('query-->>' +query);
            
        req.setEndpoint(endpointString);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
    
        // system.debug('response-->>' + response.getBody()); 


        //System.debug(JSON.deserializeUntyped(response.getBody()).get('records'));
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        System.debug('jsonResponse: ' + jsonResponse);
        List<Object> recordList = (List<Object>) jsonResponse.get('records');
        System.debug(recordList);

        for (Object oneRecord : recordList) {
            Map<String, Object> recordMap = (Map<String, Object>) oneRecord;

            String nameSpacePrefixName = '';

            if (useNameSpacePrefix) {
                nameSpacePrefixName = (String) recordMap.get('NamespacePrefix');
            }

            String recordName = (String) recordMap.get(nameField);

            if (useSObjectNamePrefix) {
                String sObjectName = (String) recordMap.get(sObjectField);
                if (objectName == 'ValidationRule') {
                    Map<String, Object> entityDefinitionMap = (Map<String, Object>) recordMap.get('EntityDefinition');
                    sObjectName = (String) entityDefinitionMap.get('QualifiedApiName');
                }
                if (!String.isBlank(sObjectName)) {
                    if (useNameSpacePrefix && !String.isBlank(nameSpacePrefixName)) {
                        if (objectName == 'QuickActionDefinition' && sObjectName == 'Global') {
                            outputList.add(nameSpacePrefixName + '__' + recordName);
                        } else {
                            outputList.add(sObjectName + '.' + nameSpacePrefixName + '__' + recordName);
                        }
                    } else {
                        if (objectName == 'QuickActionDefinition' && sObjectName == 'Global') {
                            outputList.add(recordName);
                        } else {
                            outputList.add(sObjectName + '.' + recordName);
                        }
                        
                    }                    
                }               
            } else {
                if (useNameSpacePrefix && !String.isBlank(nameSpacePrefixName)) {
                    outputList.add(nameSpacePrefixName + '__' + recordName);
                } else {
                    outputList.add(recordName);
                }               
            }
            
            // System.debug(recordName);
        }

    }

    private List<String> getFieldApiNames(String objectAPIName) {
        List<String> editableFields = new List<String>();
   
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
        if (objectType != null) {
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap();
            for (Schema.SObjectField field : fieldsMap.values()) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                string fieldName = fieldDescribe.getName();
                if (fieldName.containsignorecase('avo')) {                    
                    if (fieldDescribe.isUpdateable() || fieldDescribe.isCascadeDelete()){
                        if (objectList.contains(objectAPIName) == false) {
                            objectList.add(objectAPIName);
                        }
                        editableFields.add(objectAPIName + '.' + fieldName);
                    }                
                }
            }
        }    
        return editableFields;
    }

    private void generateHeader() {
        content = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + '\r\n';
        content += '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + '\r\n';
    }
    
    private void generateFooter() {
        content += '    <version>60.0</version>' + '\r\n';
        content += '</Package>';
    }
    private void typeBegin() {
        content += typeBegin + '\r\n';  
    }
    
    private void typeEnd() {
        content += typeEnd + '\r\n';  
    }

    private void specifyType(string type) {
        content += twoTabs + '<name>' + type + '</name>' + '\r\n';  
    }

    private void addMember(string member) {
        content +=  twoTabs + '<members>' + member + '</members>' + '\r\n';            
    }

    private list<string> getLayouts(String objectAPIName) {
        ID durableId;
        for (EntityDefinition entityDefintion : entityDefinitions) {
            if (entityDefintion.QualifiedApiName == objectAPIName) {
                durableId = entityDefintion.DurableId;
            }            
        }
        List<String> layouts = new List<String>();
        HttpRequest req = new HttpRequest();

        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl= Url.getOrgDomainUrl().toExternalForm();
        String query='Select+id,Name+from+Layout+where+TableEnumOrId=\'' + durableId + '\'';
        //system.debug('query-->>' +query);
        
        req.setEndpoint(SFdomainUrl+'/services/data/v42.0/tooling/query/?q='+query);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);
        //system.debug('response-->>' + response.getBody()); 
        
        JSONParser parser = JSON.createParser(response.getBody());
        while(parser.nextToken()!= null) {
             if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                parser.nextValue();
                if(parser.getCurrentName() == 'records') {
                    while(parser.nextToken()!= JSONToken.END_ARRAY) {
                        if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                            parser.nextValue();
                            if(parser.getCurrentName() == 'Name') {
                                string pageLayout = objectAPIName + '-'+ parser.getText();
                                string matchingManagedLayout = managedLayouts.get(pageLayout);
                                if (matchingManagedLayout != null) {
                                    pageLayout = objectAPIName + '-'+ matchingManagedLayout + '__' + parser.getText();
                                } 
                                layouts.add(pageLayout);
                            }  
                        } else if(parser.getCurrentToken() == JSONToken.END_OBJECT) {
                            continue;
                        } else if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            continue;
                        }
                    }
                }
             }    
        }    
        return layouts;    
    }    

    private void identifyManagedPageLayouts(){
        managedLayouts.put('MUSW__Permit2__c-Permit (BP) Quick Permit','clariti');        
        managedLayouts.put('MUSW__Review_Template__c-Review Template Project Review','MUSW');        
    }
}