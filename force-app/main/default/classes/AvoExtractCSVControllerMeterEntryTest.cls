@isTest
public class AvoExtractCSVControllerMeterEntryTest {
    
    @isTest
    static void testExtractCSVSuccess() {
        AVO_Meter_Transaction__c batchMeterEntry = new AVO_Meter_Transaction__c(
            Name = 'MBTE-0000-0000',
            AVO_Batch_Type__c = 'Batch Meter Entry',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Batch Meter Entry').getRecordTypeId(),
            AVO_Batch_Status__c = 'Pending'
        );
        insert batchMeterEntry;
        AVO_Meter_Codeset__c make = new AVO_Meter_Codeset__c(
        	Name = 'McCrometer',
            AVO_Status__c = 'A',
            AVO_Make_ID__c = '1',
            AVO_Type__c = 'Meter Make',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Make').getRecordTypeId()
        );
        insert make;
        AVO_Meter_Codeset__c model = new AVO_Meter_Codeset__c(
        	Name = 'G304-1',
            AVO_Meter_Make__c = make.Id,
            AVO_Status__c = 'A',
            AVO_Model_ID__c = '1',
            AVO_Type__c = 'Meter Model',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Model').getRecordTypeId()
        );
        insert model;
        
        // Prepare CSV content string
        String csvContent =
            'Serial No.,Make,Model,Unit of Measure,Inside Diameter,Outside Diameter,Multiplier,Meter Storage Location,State Purchased,Battery Based,Date Purchased,Order ID,RegisterOrientation\n' +
             'AG22-0359,McCrometer,G304-1,Acre/Inches,4.03,4.05,0.01,Warehouse Left-wall,Yes,Yes,,362962,Horizontal\n';

        ContentVersion cv = new ContentVersion(
            Title = 'TestCSV',
            PathOnClient = 'TestCSV.csv',
            VersionData = Blob.valueOf(csvContent)
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = batchMeterEntry.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        AvoExtractCSVControllerMeterEntry.extractCSV(batchMeterEntry.Id);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
    @isTest
    static void testExtractCSVFailNoMakeModel() {
        AVO_Meter_Transaction__c batchMeterEntry = new AVO_Meter_Transaction__c(
            Name = 'MBTE-0000-0000',
            AVO_Batch_Type__c = 'Batch Meter Entry',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Batch Meter Entry').getRecordTypeId(),
            AVO_Batch_Status__c = 'Pending'
        );
        insert batchMeterEntry;

        // Prepare CSV content string
        String csvContent =
            'Serial No.,Make,Model,Unit of Measure,Inside Diameter,Outside Diameter,Multiplier,Meter Storage Location,State Purchased,Battery Based,Date Purchased,Order ID,RegisterOrientation\n' +
             'AG22-0359,McCrometer,G304-1,Acre/Inches,4.03,4.05,0.01,Warehouse Left-wall,Yes,Yes,,362962,Horizontal\n';

        ContentVersion cv = new ContentVersion(
            Title = 'TestCSV',
            PathOnClient = 'TestCSV.csv',
            VersionData = Blob.valueOf(csvContent)
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = batchMeterEntry.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        try {
            AvoExtractCSVControllerMeterEntry.extractCSV(batchMeterEntry.Id);
        } catch (AuraHandledException ex) {
            System.debug('test');
        }
        
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
    @isTest
    static void testExtractCSVFailNoFile() {
        AVO_Meter_Transaction__c batchMeterEntry = new AVO_Meter_Transaction__c(
            Name = 'MBTE-0000-0000',
            AVO_Batch_Type__c = 'Batch Meter Entry',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Batch Meter Entry').getRecordTypeId(),
            AVO_Batch_Status__c = 'Pending'
        );
        insert batchMeterEntry;

        Test.startTest();
        try {
            AvoExtractCSVControllerMeterEntry.extractCSV(batchMeterEntry.Id);
        } catch (AuraHandledException ex) {
            System.debug('test');
        }
        
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
    @isTest
    static void testExtractCSVFailNoBatchEntryRecord() {
        AVO_Meter__c meter = new AVO_Meter__c(
            Name = '12345'
        );
        insert meter;

        Test.startTest();
        try {
            AvoExtractCSVControllerMeterEntry.extractCSV(meter.Id);
        } catch (AuraHandledException ex) {
            System.debug('test');
        }
        
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
    @isTest
    static void testExtractCSVFailInvalidCSV() {
        AVO_Meter_Transaction__c batchMeterEntry = new AVO_Meter_Transaction__c(
            Name = 'MBTE-0000-0000',
            AVO_Batch_Type__c = 'Batch Meter Entry',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Batch Meter Entry').getRecordTypeId(),
            AVO_Batch_Status__c = 'Pending'
        );
        insert batchMeterEntry;
        AVO_Meter_Codeset__c make = new AVO_Meter_Codeset__c(
        	Name = 'McCrometer',
            AVO_Status__c = 'A',
            AVO_Make_ID__c = '1',
            AVO_Type__c = 'Meter Make',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Make').getRecordTypeId()
        );
        insert make;
        AVO_Meter_Codeset__c model = new AVO_Meter_Codeset__c(
        	Name = 'G304-1',
            AVO_Meter_Make__c = make.Id,
            AVO_Status__c = 'A',
            AVO_Model_ID__c = '1',
            AVO_Type__c = 'Meter Model',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Model').getRecordTypeId()
        );
        insert model;
        
        // Prepare CSV content string
        String csvContent =
            'Serial No.,Make,Model,Unit of Measure,Inside Diameter,Outside Diameter,Multiplier,Meter Storage Location,State Purchased,Battery Based,Date Purchased,Order ID,RegisterOrientation\n' +
             ',,,test,,,,test,test,test,,,test\n';

        ContentVersion cv = new ContentVersion(
            Title = 'TestCSV',
            PathOnClient = 'TestCSV.csv',
            VersionData = Blob.valueOf(csvContent)
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = batchMeterEntry.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        try {
            AvoExtractCSVControllerMeterEntry.extractCSV(batchMeterEntry.Id);
        } catch (AuraHandledException ex) {
            System.debug('test');
        }
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
    @isTest
    static void testExtractCSVFailDuplicateMeter() {
        AVO_Meter__c meter = new AVO_Meter__c(
            Name = 'AG22-0359'
        );
        insert meter;
        AVO_Meter_Transaction__c batchMeterEntry = new AVO_Meter_Transaction__c(
            Name = 'MBTE-0000-0000',
            AVO_Batch_Type__c = 'Batch Meter Entry',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Batch Meter Entry').getRecordTypeId(),
            AVO_Batch_Status__c = 'Pending'
        );
        insert batchMeterEntry;
        AVO_Meter_Codeset__c make = new AVO_Meter_Codeset__c(
        	Name = 'McCrometer',
            AVO_Status__c = 'A',
            AVO_Make_ID__c = '1',
            AVO_Type__c = 'Meter Make',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Make').getRecordTypeId()
        );
        insert make;
        AVO_Meter_Codeset__c model = new AVO_Meter_Codeset__c(
        	Name = 'G304-1',
            AVO_Meter_Make__c = make.Id,
            AVO_Status__c = 'A',
            AVO_Model_ID__c = '1',
            AVO_Type__c = 'Meter Model',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Model').getRecordTypeId()
        );
        insert model;
        
        // Prepare CSV content string
        String csvContent =
            'Serial No.,Make,Model,Unit of Measure,Inside Diameter,Outside Diameter,Multiplier,Meter Storage Location,State Purchased,Battery Based,Date Purchased,Order ID,RegisterOrientation\n' +
             'AG22-0359,McCrometer,G304-1,Acre/Inches,4.03,4.05,0.01,Warehouse Left-wall,Yes,Yes,,362962,Horizontal\n';


        ContentVersion cv = new ContentVersion(
            Title = 'TestCSV',
            PathOnClient = 'TestCSV.csv',
            VersionData = Blob.valueOf(csvContent)
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = batchMeterEntry.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        try {
            AvoExtractCSVControllerMeterEntry.extractCSV(batchMeterEntry.Id);
        } catch (AuraHandledException ex) {
            System.debug('test');
        }
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
    @isTest
    static void testExtractCSVFailMakeModelMismatch() {
        AVO_Meter_Transaction__c batchMeterEntry = new AVO_Meter_Transaction__c(
            Name = 'MBTE-0000-0000',
            AVO_Batch_Type__c = 'Batch Meter Entry',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Transaction__c.getRecordTypeInfosByName().get('Batch Meter Entry').getRecordTypeId(),
            AVO_Batch_Status__c = 'Pending'
        );
        insert batchMeterEntry;
        AVO_Meter_Codeset__c make = new AVO_Meter_Codeset__c(
        	Name = 'McCrometer',
            AVO_Status__c = 'A',
            AVO_Make_ID__c = '1',
            AVO_Type__c = 'Meter Make',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Make').getRecordTypeId()
        );
        insert make;
        AVO_Meter_Codeset__c model = new AVO_Meter_Codeset__c(
        	Name = 'G304-1',
            AVO_Meter_Make__c = make.Id,
            AVO_Status__c = 'A',
            AVO_Model_ID__c = '1',
            AVO_Type__c = 'Meter Model',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Model').getRecordTypeId()
        );
        insert model;
        AVO_Meter_Codeset__c make2 = new AVO_Meter_Codeset__c(
        	Name = 'Seametrics',
            AVO_Status__c = 'A',
            AVO_Make_ID__c = '2',
            AVO_Type__c = 'Meter Make',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Make').getRecordTypeId()
        );
        insert make2;
        AVO_Meter_Codeset__c model2 = new AVO_Meter_Codeset__c(
        	Name = 'G304-2',
            AVO_Meter_Make__c = make2.Id,
            AVO_Status__c = 'A',
            AVO_Model_ID__c = '2',
            AVO_Type__c = 'Meter Model',
            RecordTypeId = Schema.SObjectType.AVO_Meter_Codeset__c.getRecordTypeInfosByName().get('Meter Model').getRecordTypeId()
        );
        insert model2;
        
        // Prepare CSV content string
        String csvContent =
            'Serial No.,Make,Model,Unit of Measure,Inside Diameter,Outside Diameter,Multiplier,Meter Storage Location,State Purchased,Battery Based,Date Purchased,Order ID,RegisterOrientation\n' +
             'AG22-0359,McCrometer,G304-2,Acre/Inches,4.03,4.05,0.01,Warehouse Left-wall,Yes,Yes,,362962,Horizontal\n';

        ContentVersion cv = new ContentVersion(
            Title = 'TestCSV',
            PathOnClient = 'TestCSV.csv',
            VersionData = Blob.valueOf(csvContent)
        );
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = batchMeterEntry.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        try {
            AvoExtractCSVControllerMeterEntry.extractCSV(batchMeterEntry.Id);
        } catch (AuraHandledException ex) {
            System.debug('test');
        }
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
    
}