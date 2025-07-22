public with sharing class AvoExtractCSVControllerMeterEntry {
    @AuraEnabled
    public static void extractCSV(Id recordId) {
        System.debug('RecordId IS: '+ recordId);
        AVO_Meter_Transaction__c batchMeterEntry;
        try {
            batchMeterEntry = [SELECT Id, (SELECT Id,FileExtension FROM CombinedAttachments WHERE FileExtension = 'csv')
                               FROM AVO_Meter_Transaction__c
                               WHERE Id = :recordId
                               LIMIT 1];
        } catch (Exception e) {
            System.debug('Error occurred while querying Batch Meter Entry: ' + e.getMessage());
            return;
        }
        
        if (batchMeterEntry != null) {
            List<CombinedAttachment> combinedAttachments = batchMeterEntry.CombinedAttachments;
            if (combinedAttachments.size() == 0) {
                throw new AuraHandledException('No uploaded CSV files found. Please upload a CSV file.');
            }
            Set<String> existingMSNSet = new Set<String>();
            
            for (AVO_Meter__c existingMeter : [SELECT Id, Name FROM AVO_Meter__c]) {
                existingMSNSet.add(existingMeter.Name);
            }
            
            Set<String> unitMeasurePlVals = new Set<String>();
            for (Schema.PicklistEntry ple : AVO_Meter_Transaction__c.AVO_Unit_Of_Measure__c.getDescribe().getPicklistValues()) {
                unitMeasurePlVals.add(ple.getValue().toLowerCase());
            }
            
            Set<String> storageLocationPlVals = new Set<String>();
            for (Schema.PicklistEntry ple : AVO_Meter_Transaction__c.AVO_Storage_Location__c.getDescribe().getPicklistValues()) {
                storageLocationPlVals.add(ple.getValue().toLowerCase());
            }
            
            Set<String> meterOrientationPlVals = new Set<String>();
            for (Schema.PicklistEntry ple : AVO_Meter_Transaction__c.AVO_Meter_Orientation__c.getDescribe().getPicklistValues()) {
                meterOrientationPlVals.add(ple.getValue().toLowerCase());
            }
            System.debug(meterOrientationPlVals);
            
            for (CombinedAttachment combinedAttachment : combinedAttachments) {
                system.debug('show' + combinedAttachment);
                
                if (combinedAttachment.FileExtension == 'csv') {
                    ContentVersion contentVersion = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :combinedAttachment.Id];
                    if (contentVersion != null) {
                        // Parse the CSV data
                        String csvData = contentVersion.VersionData.toString();
                        List<String> rows = csvData.split('\n');
                        Id meterEntryRecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Meter Entry').getRecordTypeId();
                        // Check CSV data
                        Boolean isMissingMakeModel = false;
                        String errorMessage = '';
                        
                        Set<String> meterMakeNames = new Set<String>();
                        Set<String> meterModelNames = new Set<String>();
                        
                        for (Integer i = 1; i < rows.size(); i++) {
                            List<String> rowData = rows[i].split(',');
                            if (String.isBlank(rowData[0])) {
                                errorMessage = errorMessage + 'Row ' + i + ': Meter Serial Number Missing\n';
                                isMissingMakeModel = true;
                            } else if (existingMSNSet.contains(rowData[0].trim())) {
                                errorMessage = errorMessage + 'Row ' + i + ': Meter Serial Number ' + rowData[0] + ' already exists in the system\n';
                                isMissingMakeModel = true;
                            }
                            if (String.isBlank(rowData[1]) || String.isBlank(rowData[2])) {
                                errorMessage = errorMessage + 'Row ' + i + ': Make/Model missing\n';
                                isMissingMakeModel = true;
                            }
                            if (!String.isBlank(rowData[3]) && !unitMeasurePlVals.contains(rowData[3].trim().toLowerCase())) {
                                errorMessage = errorMessage + 'Row ' + i + ': Invalid value for Unit of Measure\n';
                                isMissingMakeModel = true;
                            }
                            if (!String.isBlank(rowData[7]) && !storageLocationPlVals.contains(rowData[7].trim().toLowerCase())) {
                                errorMessage = errorMessage + 'Row ' + i + ': Invalid value for Storage Location\n';
                                isMissingMakeModel = true;
                            }
                            if (!String.isBlank(rowData[12]) && !meterOrientationPlVals.contains(rowData[12].trim().toLowerCase())) {
                                System.debug(rowData[12].toLowerCase());
                                errorMessage = errorMessage + 'Row ' + i + ': Invalid value for Meter Orientation\n';
                                isMissingMakeModel = true;
                            }
                            //Below code has been added as part of 29859 (till Line 96)
                            if(!String.isBlank(rowData[8])){
                                if(rowData[8] != 'yes' && rowData[8] != 'no'){
                                    errorMessage = errorMessage + 'Row ' + i + ': Invalid value for State Purchased\n';
                                    isMissingMakeModel = true;
                                }
                            }
                            if(!String.isBlank(rowData[9])){
                                if(rowData[9] != 'yes' && rowData[9] != 'no'){
                                    errorMessage = errorMessage + 'Row ' + i + ': Invalid value for Battery\n';
                                    isMissingMakeModel = true;
                                }
                            }
                            
                            if (!String.isBlank(rowData[1])) {
                                meterMakeNames.add(rowData[1]);
                            }
                            
                            if (!String.isBlank(rowData[2])) {
                                meterModelNames.add(rowData[2]);
                            }
                        }
                        
                        if (isMissingMakeModel) {
                            errorMessage = 'Errors for the following rows, please review and revise the document:\n' + errorMessage;
                            throw new AuraHandledException(errorMessage);
                        }
                        
                        List<AVO_Meter_Codeset__c> makeList = [SELECT Id, Name FROM AVO_Meter_Codeset__c WHERE Name IN :meterMakeNames AND AVO_Type__c = 'Meter Make'];
                        List<AVO_Meter_Codeset__c> modelList = [SELECT Id, Name, AVO_Meter_Make__r.Name FROM AVO_Meter_Codeset__c WHERE Name IN :meterModelNames AND AVO_Type__c = 'Meter Model'];
                        Map<String, AVO_Meter_Codeset__c> makeMap = new Map<String, AVO_Meter_Codeset__c>();
                        Map<String, List<AVO_Meter_Codeset__c>> modelMap = new Map<String, List<AVO_Meter_Codeset__c>>();
                        
                        for (AVO_Meter_Codeset__c codeset : makeList) {
                            makeMap.put(codeset.Name, codeset);
                        }
                        for (AVO_Meter_Codeset__c codeset : modelList) {
                            if (modelMap.get(codeset.Name) == null) {
                                modelMap.put(codeset.Name, new List<AVO_Meter_Codeset__c>());
                                modelMap.get(codeset.Name).add(codeset);
                            } else {
                                modelMap.get(codeset.Name).add(codeset);
                            }
                        }
                        
                        for (Integer i = 1; i < rows.size(); i++) {
                            System.debug('TEST ' + i);
                            List<String> rowData = rows[i].split(',');
                            AVO_Meter_Codeset__c currentMake = makeMap.get(rowData[1]);
                            List<AVO_Meter_Codeset__c> currentModels = modelMap.get(rowData[2]);
                            if (currentMake == null) {
                                errorMessage = errorMessage + 'Row ' + i + ': Make not in system\n';
                                isMissingMakeModel = true; 
                            }
                            if (currentModels == null) {
                                errorMessage = errorMessage + 'Row ' + i + ': Model not in system\n';
                                isMissingMakeModel = true; 
                            }
                            if (currentMake != null && currentModels != null) {
                                Boolean modelMakeMatch = false;
                                for (AVO_Meter_Codeset__c currentModel : currentModels) {
                                    System.debug(currentModel);
                                    if (currentModel.AVO_Meter_Make__r.Name == currentMake.Name) {
                                        modelMakeMatch = true;
                                        break;
                                    }
                                }
                                if (!modelMakeMatch) {
                                    errorMessage = errorMessage + 'Row ' + i + ': Model is under incorrect Make\n';
                                	isMissingMakeModel = true; 
                                }
                            }
                        }
                        
                        if (isMissingMakeModel) {
                            errorMessage = 'Errors for the following rows, please review and revise the document:\n' + errorMessage;
                            throw new AuraHandledException(errorMessage);
                        }
                        
                        
                        // Create Meter Entry records for each row
                        List<AVO_Meter_Transaction__c> meterEntries = new List<AVO_Meter_Transaction__c>();
                        for (Integer i = 1; i < rows.size(); i++) {
                            List<String> rowData = rows[i].split(',');
                            
                            
                            
                            // Creating a new Meter Entry record
                            AVO_Meter_Transaction__c meterEntry = new AVO_Meter_Transaction__c();
                            meterEntry.RecordTypeId = meterEntryRecordTypeId; 
                            meterEntry.AVO_Type__c = 'Meter Entry'; 
                            meterEntry.AVO_Batch_ID__c = batchMeterEntry.Id;
                            
                            AVO_Meter_Codeset__c currentMake = makeMap.get(rowData[1]);
                            List<AVO_Meter_Codeset__c> currentModels = modelMap.get(rowData[2]);
                            
                            for (AVO_Meter_Codeset__c currentModel : currentModels) {
                                if (currentModel.AVO_Meter_Make__r.Name == currentMake.Name) {
                                    meterEntry.AVO_Make__c = currentMake.Id;
                            		meterEntry.AVO_Model__c = currentModel.Id;
                                    break;
                                }
                            }
                            
                            meterEntry.AVO_Meter_Serial_Number_MSN__c = rowData[0];
                            
                            meterEntry.AVO_Unit_Of_Measure__c = rowData[3];
                            meterEntry.AVO_Inside_Pipe_Diam_In__c = String.isNotBlank(rowData[4]) ? Decimal.valueOf(rowData[4]) : null;
                            meterEntry.AVO_Outside_Pipe_Diam_In__c = String.isNotBlank(rowData[5]) ? Decimal.valueOf(rowData[5]) : null;
                            meterEntry.AVO_Storage_Location__c = rowData[7];
                            meterEntry.AVO_State_Purchased__c = rowData[8];
                            meterEntry.AVO_Battery__c = rowData[9];
                            meterEntry.AVO_Purchase_Date__c = String.isNotBlank(rowData[10]) ? date.parse(rowData[10]) : null;
                            meterEntry.AVO_Meter_Order_ID__c = rowData[11];
                            meterEntry.AVO_Meter_Orientation__c = rowData[12];
                            
                            meterEntries.add(meterEntry);
                        }
                        
                        // Insert the Meter Entry records
                        try {
                            insert meterEntries;
                            batchMeterEntry.AVO_Date_Uploaded__c = System.today();
                            batchMeterEntry.AVO_CSV_Read__c = true;
                            batchMeterEntry.AVO_Batch_Status__c = 'Pending Approval';
                            update batchMeterEntry;
                            System.debug('Meter Entry records created successfully.');
                        } catch (Exception e) {
                            System.debug('Error creating Meter Entry records: ' + e.getMessage());
                        }
                    }
                }
                else {
                    throw new AuraHandledException('The uploaded file is not a CSV file.');
                }
            }
        } else {
            System.debug('No Batch Meter Entry record found with the specified ID: ' + recordId);
        }
    }
}