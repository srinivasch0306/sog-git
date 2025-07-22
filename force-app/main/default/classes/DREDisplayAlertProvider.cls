global with sharing class DREDisplayAlertProvider extends MUSW.AbstractAlertDataProvider{
    global override List<MUSW.Alert> getAppliedAlertsForRecord(SObject record, List<MUSW.Alert.Type> types){
        Map<SObject, List<MUSW.Alert>> result = getDREAlerts(
            new List<SObject>{record},
            record.getSObjectType()
        );

        return result.get(record);
    }
    
    global override List<MUSW.Alert> getAlertsForRecord(SObject record, List<MUSW.Alert.Type> types){
        throw new NotImplementedException('getAllAlertsForRecord is not implemented for this external data service!');
    }

    global override Map<SObject, List<MUSW.Alert>> getAppliedAlertsForRecords(List<SObject> records, Schema.SObjectType sobjectType, List<MUSW.Alert.Type> types){
        throw new NotImplementedException('getAppliedHoldAlertsForRecords is not implemented for this external data service!');
    }

    private Map<SObject, List<MUSW.Alert>> getDREAlerts(List<SObject> records, SObjectType sobjectType){
        Map<SObject, List<MUSW.Alert>> result  = new Map<SObject, List<MUSW.Alert>>();
        Map<Id, SObject> recordMap = new Map<Id, SObject>(records);

        //query records 
        Set<Id> relatedRecordIds = recordMap.keySet();
        String objectName = sobjectType.getDescribe().getName();
        String querableFields = BGCM.UtilitySObject.getFieldsFor_Str(objectName, true);
        List<SObject> relatedObjects = Database.query('Select ' + String.escapeSingleQuotes(querableFields)
                                                         + ' From '+ String.escapeSingleQuotes(objectName) + ' Where Id=:relatedRecordIds WITH SECURITY_ENFORCED');

        if(records.size() >0){
            DRE.DREOutput output = DRE.DREManager.runView(relatedObjects);
            if(output != null){
                Set<DRE.DRECommandVO> commands = output.getCommands();
                for(DRE.DRECommandVO command : commands){
                    SObject record = recordMap.get(command.getRecordId());
                    if(result.get(record) == null){
                        result.put(record, new List<MUSW.Alert>());
                    }
                    MUSW.Alert myAlert = createAlert(command);
                    result.get(record).add(myAlert);
                }
            }
        }
        return result;
    }

    private MUSW.Alert createAlert(DRE.DRECommandVO command){ 
        MUSW.Alert alert = new MUSW.Alert();  
        alert.type = MUSW.Alert.Type.NOTICE;
        alert.message = command.getCommand();
        alert.relatedRecordId = command.getRecordId();
        return alert;
    }


    public class NotImplementedException extends Exception {}
}