public class AVOComplianceLockTriggerHandler extends AvoTriggerHandler {
    public override void beforeUpdate() {
        List<AVO_Compliance__c> records = (List<AVO_Compliance__c>) Trigger.new;
        Id currentUserId = UserInfo.getUserId();

        for (AVO_Compliance__c record : records) {
            AVO_Compliance__c oldRecord = (AVO_Compliance__c) Trigger.oldMap.get(record.Id);
            Boolean oldLockedStatus = oldRecord.AVO_Locked__c;
            Id recordOwnerId = oldRecord.OwnerId;

            if (record.AVO_Locked__c == true && oldLockedStatus == true && recordOwnerId != currentUserId) {
                Boolean isAnyOtherFieldChanged = false;

                for (SObjectField field : record.getSObjectType().getDescribe().fields.getMap().values()) {
                    if (field != AVO_Compliance__c.AVO_Locked__c) {
                        if (record.get(field) != oldRecord.get(field)) {
                            isAnyOtherFieldChanged = true;
                            break;
                        }
                    }
                }

                if (isAnyOtherFieldChanged) {
                    record.addError('You cannot modify this record because it is locked and you are not the owner.');
                }
            }
        }
    }
}