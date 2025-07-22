// This is the one being used
public with sharing class AvoExtractCSVControllerMeterReading {
    @AuraEnabled
    public static void extractCSV(Id recordId) {
        System.debug('RecordId IS: ' + recordId);
        AVO_Meter_Transaction__c batchMeterReading;

        try {
            batchMeterReading = [
                SELECT Id,
                    (SELECT Id, FileExtension FROM CombinedAttachments WHERE FileExtension = 'csv')
                FROM AVO_Meter_Transaction__c
                WHERE Id = :recordId
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Error occurred while querying Batch Meter Reading: ' + e.getMessage());
            return;
        }

        if (batchMeterReading != null) {
            List<CombinedAttachment> combinedAttachments = batchMeterReading.CombinedAttachments;
            if (combinedAttachments.size() == 0) {
                throw new AuraHandledException('No uploaded CSV files found. Please upload a CSV file.');
            }
            for (CombinedAttachment combinedAttachment : combinedAttachments) {
                System.debug('show' + combinedAttachment);

                if (combinedAttachment.FileExtension == 'csv') {
                    ContentVersion contentVersion = [
                        SELECT VersionData
                        FROM ContentVersion
                        WHERE ContentDocumentId = :combinedAttachment.Id
                    ];
                          system.debug('notes id ' + combinedAttachment.Id);
                    if (contentVersion != null) {
                        
                        Set<String> existingMSNSet = new Set<String>();
            
                        for (AVO_Meter__c existingMeter : [SELECT Id, Name FROM AVO_Meter__c]) {
                            existingMSNSet.add(existingMeter.Name);
                        }
                        
                        // Parse the CSV data
                        String csvData = contentVersion.VersionData.toString();
                        List<String> rows = csvData.split('\n');
						Id meterReadingRecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Meter Reading').getRecordTypeId();
                        
                        // Extract field names from the first row
                        List<String> fieldNames = rows[0].split(',');

                        Set<String> msnSet = new Set<String>();
                        // Check CSV data
                        Boolean isMissingFields = false;
                        String errorMessage = '';
                        for (Integer i = 1; i < rows.size(); i++) {
                            List<String> rowData = rows[i].split(',');
                            if (String.isBlank(rowData[0])) {
                                errorMessage = errorMessage + 'Row ' + i + ': Meter Serial Number Missing\n';
                                isMissingFields = true;
                            } else { 
                                msnSet.add(rowData[0]);
                                if (!existingMSNSet.contains(rowData[0].trim())) {
                                    errorMessage = errorMessage + 'Row ' + i + ': Meter Serial Number ' + rowData[0] + ' is not in the system\n';
                                    isMissingFields = true;
                                }
                            }
                        }

                        if (isMissingFields) {
                            errorMessage = 'Required data fields are missing for the following rows\n' + errorMessage;
                            throw new AuraHandledException(errorMessage);
                        }
                        
                        List<AVO_Meter__c> existingMeters = [SELECT Id, Name FROM AVO_Meter__c WHERE Name IN :msnSet];
                        Map<String, AVO_Meter__c> msnMeterMap = new Map<String, AVO_Meter__c>();
                        for (AVO_Meter__c existingMeter : existingMeters) {
                            if (!msnMeterMap.containsKey(existingMeter.Name)) {
                                msnMeterMap.put(existingMeter.Name, existingMeter);
                            }
                        }
                        
                        // Process the CSV data and create new meterReadingRecords
                        List<AVO_Meter_Transaction__c> meterReadings = new List<AVO_Meter_Transaction__c>();

                        for (Integer i = 1; i < rows.size(); i++) {
                            List<String> rowData = rows[i].split(',');
							AVO_Meter_Transaction__c meterReading = new AVO_Meter_Transaction__c();
                            
                            meterReading.RecordTypeId = meterReadingRecordTypeId;
                            meterReading.AVO_Type__c = 'Meter Reading'; 
                            meterReading.AVO_Batch_ID__c = batchMeterReading.Id;
                            meterReading.AVO_Meter_ID__c = msnMeterMap.get(rowData[0]).Id;
                            meterReading.AVO_Reading__c = String.isNotBlank(rowData[19]) ? Decimal.valueOf(rowData[19]) : null;
                            meterReading.AVO_Reading_Date__c = Date.today();
                            meterReading.AVO_Meter_Serial_Number_MSN__c = msnMeterMap.get(rowData[0]).Name;
                            
                            meterReadings.add(meterReading);
                                                              
                        }
                        // Update the meterReadingRecordList
                        if (!meterReadings.isEmpty()) {
                            System.debug('inserting meter readings...');
                            insert meterReadings;
                        }
                        batchMeterReading.AVO_CSV_Read__c = true;
                        batchMeterReading.AVO_Date_Uploaded__c = System.today();
                        batchMeterReading.AVO_Batch_Status__c = 'Pending Approval';
                        update batchMeterReading;
                    }
                }
                else {
                    throw new AuraHandledException('The uploaded file is not a CSV file.');
                }
            }
        }
    }
}