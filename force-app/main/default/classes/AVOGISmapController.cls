public class AVOGISmapController {

    public class PermitData {
        public String appId;
        public String county;
        public String dnrBasin;
    }

    public class WithdrawalData {
        public String gisUnique;
        public String pointX;
        public String pointY;
        public String SUBAREA4;
        public String COASTAL24;
        public String FRBPCONZON;
        public String Suspension;
        public String CritStrBuf;
        public String PrioZone;
        public String DarkGreenA;
    }

    @AuraEnabled
    public static String uploadFile(String base64) {
        String returnString = '';
        try {
            Blob fileBlob = EncodingUtil.base64Decode(base64);
            String csvData = fileBlob.toString();
            List<String> rows = csvData.split('\n');

            List<String> headers = rows[0].split(',');
            Map<String, Integer> headerIndexMap = new Map<String, Integer>();
            for (Integer i = 0; i < headers.size(); i++) {
                headerIndexMap.put(headers[i].trim(), i);
            }

            // Validate required columns
            List<String> requiredHeaders = new List<String>{
                'COUNTY', 'DNRBASINS', 'POINT_X', 'POINT_Y', 'GIS_unique', 'APP_ID',
                'SUBAREA4', 'COASTAL24', 'FRBPCONZON', 'Suspension', 'CritStrBuf', 'PrioZone', 'DarkGreenA'
            };

            for (String header : requiredHeaders) {
                if (!headerIndexMap.containsKey(header)) {
                    return 'Missing required column: ' + header;
                }
            }

            Map<String, PermitData> permitDataMap = new Map<String, PermitData>();
            Map<String, WithdrawalData> withdrawalDataMap = new Map<String, WithdrawalData>();
            Set<String> permitAppIDSet = new Set<String>();
            Set<String> withdrawalGISUniqueSet = new Set<String>();

            for (Integer i = 1; i < rows.size(); i++) {
                List<String> rowData = rows[i].split(',');
                if (rowData.size() < headers.size()) continue; // skip incomplete rows

                // Permit record
                PermitData permit = new PermitData();
                permit.appId = rowData[headerIndexMap.get('APP_ID')];
                permit.county = rowData[headerIndexMap.get('COUNTY')].toLowerCase();
                permit.dnrBasin = rowData[headerIndexMap.get('DNRBASINS')];
                permitDataMap.put(permit.appId, permit);
                permitAppIDSet.add(permit.appId);
                              
                // Withdrawal record
                WithdrawalData withdrawal = new WithdrawalData();
                withdrawal.gisUnique = rowData[headerIndexMap.get('GIS_unique')];
                withdrawal.pointX = rowData[headerIndexMap.get('POINT_X')];
                withdrawal.pointY = rowData[headerIndexMap.get('POINT_Y')];
                withdrawal.SUBAREA4 = rowData[headerIndexMap.get('SUBAREA4')];
                withdrawal.COASTAL24 = rowData[headerIndexMap.get('COASTAL24')];
                withdrawal.FRBPCONZON = rowData[headerIndexMap.get('FRBPCONZON')];
                withdrawal.Suspension = rowData[headerIndexMap.get('Suspension')];
                withdrawal.CritStrBuf = rowData[headerIndexMap.get('CritStrBuf')];
                withdrawal.PrioZone = rowData[headerIndexMap.get('PrioZone')];
                withdrawal.DarkGreenA = rowData[headerIndexMap.get('DarkGreenA')];
                withdrawalDataMap.put(withdrawal.gisUnique, withdrawal);
                withdrawalGISUniqueSet.add(withdrawal.gisUnique);
            }

            // Load supporting data
            Map<String, Id> countyMap = new Map<String, Id>();
            for (AVO_County__c county : [SELECT Id, Name FROM AVO_County__c]) {
                countyMap.put(county.Name.toLowerCase(), county.Id);
            }

            // Update Permit records
            List<MUSW__Permit2__c> permitUpdates = new List<MUSW__Permit2__c>();
            List<MUSW__Permit2__c> permitList = [SELECT Id, AVO_AppID__c FROM MUSW__Permit2__c WHERE AVO_AppID__c IN :permitAppIDSet];
            System.debug('permitAppIDSet : '+ permitAppIDSet);
            System.debug('permitList : '+ permitList.Size());
            System.debug('permitList : '+ permitList);
            for (MUSW__Permit2__c permit : [
                SELECT Id, AVO_AppID__c FROM MUSW__Permit2__c WHERE AVO_AppID__c IN :permitAppIDSet
            ]) {
                if (permitDataMap.containsKey(permit.AVO_AppID__c)) {
                    PermitData data = permitDataMap.get(permit.AVO_AppID__c);
                    permit.AVO_Basin__c = data.dnrBasin;
                    if (countyMap.containsKey(data.county.toLowerCase())) {
                        permit.AVO_County_Lookup__c = countyMap.get(data.county);
                    }
                    permitUpdates.add(permit);
                }
            }

            // Update Withdrawal records
            List<AVO_Withdrawals__c> withdrawalUpdates = new List<AVO_Withdrawals__c>();
            for (AVO_Withdrawals__c withdrawal : [
                SELECT Id, AVO_GIS_UNIQUE__c, RecordTypeId, RecordType.Name FROM AVO_Withdrawals__c
                WHERE AVO_GIS_UNIQUE__c IN :withdrawalGISUniqueSet
            ]) {
                if (withdrawalDataMap.containsKey(withdrawal.AVO_GIS_UNIQUE__c)) {
                    WithdrawalData data = withdrawalDataMap.get(withdrawal.AVO_GIS_UNIQUE__c);

                    withdrawal.AVO_Sub_Area_4__c = data.SUBAREA4;
                    withdrawal.Coastal_24__c = data.COASTAL24;
                    withdrawal.AVO_FRBP_Conservation_Area__c = data.FRBPCONZON;
                    withdrawal.AVO_2012_Suspension_Areas__c = data.Suspension;
                    withdrawal.AVO_Critical_Stream_Buffer__c = data.CritStrBuf;
                    withdrawal.AVO_Dark_Green_Area__c = data.DarkGreenA;
                    withdrawal.AVO_Priority_Zone__c = Decimal.valueOf(data.PrioZone);

                    if (withdrawal.RecordType.Name.contains('Ground Water')) {
                        withdrawal.AVO_Well_Long__c = Decimal.valueOf(data.pointX);
                        withdrawal.AVO_Well_Latitude__c = Decimal.valueOf(data.pointY);
                    } else if (withdrawal.RecordType.Name.contains('Surface Water')) {
                        withdrawal.Point_X__c = Decimal.valueOf(data.pointX);
                        withdrawal.Point_Y__c = Decimal.valueOf(data.pointY);
                    }

                    withdrawalUpdates.add(withdrawal);
                }
            }

            if (!permitUpdates.isEmpty()) update permitUpdates;
            if (!withdrawalUpdates.isEmpty()) update withdrawalUpdates;

            returnString = 'Updated ' + permitUpdates.size() + ' Permit records & ' + withdrawalUpdates.size() + ' Withdrawal records.';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
        return returnString;
    }
}