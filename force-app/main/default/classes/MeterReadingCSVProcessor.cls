public with sharing class MeterReadingCSVProcessor {
    @AuraEnabled
    public static void processMeterReadingCSV(Id batchMeterReadingId) {
        System.debug('RecordId IS: '+ batchMeterReadingId);
        AVO_Meter_Transaction__c batchMeterReading;
        try {
            batchMeterReading = [SELECT Id, (SELECT Id,FileExtension FROM CombinedAttachments WHERE FileExtension = 'csv')
                                 FROM AVO_Meter_Transaction__c
                                 WHERE Id = :batchMeterReadingId
                                 LIMIT 1];
        } catch (Exception e) {
            System.debug('Error occurred while querying Batch Meter Entry: ' + e.getMessage());
            return;
        }
        
        if (batchMeterReading != null) {
            List<CombinedAttachment> combinedAttachments = batchMeterReading.CombinedAttachments;
            
            for (CombinedAttachment combinedAttachment : combinedAttachments) {
                system.debug('show' + combinedAttachment);
                
                if (combinedAttachment.FileExtension == 'csv') {
                    ContentVersion contentVersion = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :combinedAttachment.Id];
    
                            
                            
                          
if (contentVersion != null) {
                        // Parse the CSV data
                        String csvData = contentVersion.VersionData.toString();
                        List<String> rows = csvData.split('\n');
                        Id meterEntryRecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Meter Entry').getRecordTypeId();

                        // Update Meter Reading records for each row
                        List<AVO_Meter_Transaction__c> meterReadings = new List<AVO_Meter_Transaction__c>();
                        for (Integer i = 1; i < rows.size(); i++) {
                            List<String> rowData = rows[i].split(',');
       
                            AVO_Meter_Transaction__c MeterReadingRecords = [ SELECT Read_Meter__c, AVO_Reading_Comment__c,AVO_Batch_Status__c , AVO_Meter_Reading_Type__c , AVO_Meter_Geolocation__Longitude__s ,AVO_Meter_Geolocation__Latitude__s , AVO_Meter_Serial_Number_MSN__c , AVO_Reading__c
                                                                            FROM AVO_Meter_Transaction__c  
                                                                            WHERE Read_Meter__c = 'true'AND AVO_Reading_Comment__c =''AND AVO_Batch_Status__c ='Pending'AND AVO_Meter_Reading_Type__c ='Yearly Reading' AND AVO_Batch_ID__c =: batchMeterReadingId];                 
                            
                            
                            
                            
                            // Updating a new Meter Entry record
                            AVO_Meter_Transaction__c meterReading = new AVO_Meter_Transaction__c();
                            
                            meterReading.RecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Batch Meter Reading').getRecordTypeId();
                            meterReading.AVO_Type__c = 'Batch Meter Reading';
                            meterReading.AVO_Batch_ID__c = batchMeterReading.Id;

                                 
                                
                       if(MeterReadingRecords.AVO_Meter_Serial_Number_MSN__c == rowData[0] && MeterReadingRecords.AVO_Meter_Geolocation__Latitude__s == Decimal.valueOf(rowData[1]) && MeterReadingRecords.AVO_Meter_Geolocation__Longitude__s ==Decimal.valueOf(rowData[2])){
                                 meterReading.AVO_Batch_Status__c = 'Approved';  
                                 meterReadings.add(meterReading);
                                }
                            }  
    
    update meterReadings;
                            
                        }
                    }
                }
            }
        }
    }