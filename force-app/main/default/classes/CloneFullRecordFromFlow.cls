public class CloneFullRecordFromFlow {

    // Input structure expected from Flow (pass the record, at least with Id)
    public class Input {
        @InvocableVariable(required=true)
        public SObject originalRecord;
    }

    // Output structure returned to Flow
    public class Output {
        @InvocableVariable
        public Id newRecordId;
    }

    @InvocableMethod(label='Clone Full Record with All Fields')
    public static List<Output> cloneAllFields(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input input : inputs) {
            SObject inputRecord = input.originalRecord;
            Id recordId = (Id) inputRecord.get('Id');

            if (recordId == null) {
                continue; // Skip if ID is missing
            }

            // Get object name (e.g., My_Object__c) from ID
            String objectType = recordId.getSObjectType().getDescribe().getName();
            Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(objectType);
            Map<String, Schema.SObjectField> fieldMap = sobjectType.getDescribe().fields.getMap();

            // Collect cloneable fields
            List<String> fieldsToQuery = new List<String>();
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();

                if (
                    fieldDesc.isAccessible() &&
                    fieldDesc.isCreateable() &&
                    !fieldDesc.isCalculated() &&  // skip formula fields
                    !fieldDesc.isAutoNumber() &&  // skip auto-number
                    fieldName != 'Id'
                ) {
                    fieldsToQuery.add(fieldName);
                }
            }

            // Build dynamic SOQL to fetch full record
            String soql = 'SELECT ' + String.join(fieldsToQuery, ',') +
                          ' FROM ' + objectType + ' WHERE Id = :recordId';
            SObject original = Database.query(soql);

            // Create a clone record and copy all field values
            SObject clone = sobjectType.newSObject();
            for (String field : fieldsToQuery) {
                clone.put(field, original.get(field));
            }

            // Insert and return new record ID
            insert clone;

            Output result = new Output();
            result.newRecordId = clone.Id;
            results.add(result);
        }

        return results;
    }
}