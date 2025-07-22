public class AvoAppendWithdrawalFromRevision {
    
    @InvocableMethod(label='Copies Revision Record Withdrawal From Child To Parent' description='Copies revision record withdrawal to permit parent record with duplicate check and replacement')
    public static void syncFilesFromChildToParentFlow(List<SyncRequest> requests) {
        for (SyncRequest request : requests) {
            copyWithdrawalFromChildToParent(request.childRecordId, request.parentRecordId);
        }
    }
    
    public class SyncRequest {
        @InvocableVariable(label='Child Record Id' required=true)
        public Id childRecordId;
        
        @InvocableVariable(label='Parent Record Id' required=true)
        public Id parentRecordId;
    }
    
    public static void copyWithdrawalFromChildToParent(Id childId, Id parentId){
        
        List<String> editableFields = getEditableFields('AVO_Withdrawals__c');
        
        String fieldList = String.join(editableFields, ', ');
        String childQuery = 'SELECT ' + fieldList + ' FROM ' + 'AVO_Withdrawals__c' + ' WHERE AVO_Permit__c = :childId';
        System.debug(childQuery);
        
        String parentQuery = 'SELECT ' + fieldList + ' FROM ' + 'AVO_Withdrawals__c' + ' WHERE AVO_Permit__c = :parentId';
        System.debug(parentQuery);
        List<AVO_Withdrawals__c> childWithdrawal = database.query(childQuery);
        List<AVO_Withdrawals__c> parentWithdrawal = database.query(parentQuery);

		set<String> parentWithdrawalName = new set<String>();
        for(AVO_Withdrawals__c withdrawal : parentWithdrawal) parentWithdrawalName.add(withdrawal.Name);         
        
        List<AVO_Withdrawals__c> recordInsertList = new List<AVO_Withdrawals__c>();
        
        for(AVO_Withdrawals__c withdrawal : childWithdrawal){
            if(!parentWithdrawalName.contains(withdrawal.Name)){
            AVO_Withdrawals__c newWithdrawalToParent = withdrawal;
            newWithdrawalToParent.Id = Null;
            newWithdrawalToParent.AVO_Permit__c =  parentId;
            newWithdrawalToParent.AVO_From_Revision__c = True;
            recordInsertList.add(newWithdrawalToParent);
            }
        }
        
        if(recordInsertList.Size() > 0){
            Insert recordInsertList;
        }
    }
    
    
    public static List<String> getEditableFields(String objectApiName) {
        List<String> editableFields = new List<String>();
        
        try {
            // Describe the SObject
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            
            if (sObjectType == null) {
                throw new IllegalArgumentException('Invalid object API name: ' + objectApiName);
            }
            
            Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();
            
            for (String fieldName : fieldsMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
                
                if (fieldDescribe.isUpdateable() && !fieldDescribe.isCalculated()) {
                    editableFields.add(fieldName);
                }
            }
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getMessage());
        }
        
        return editableFields;
    }
}