public with sharing class BB_ReviewTriggerHandler {
    /**
     * handles the milestone triggers
     *
     */
    public class ReviewBluebeam implements BGCM.ITriggerHandler {
        public void onBeforeUpdate() {}
        public void onBeforeDelete() {}
        public void onBeforeInsert() {}
        public void onBeforeUndelete() {}
        public void onAfterInsert() {
            BluebeamReviewHelper();
        }
        public void onAfterUpdate() {
            BluebeamReviewHelper();
        }
        public void onAfterDelete() {}
        public void onAfterUndelete() {}

        /**
         * launches a method to add the milestone owner to the parent
         * Bluebeam projectId
         */
        private void BluebeamReviewHelper() {
            if(Trigger.isInsert || Trigger.isUpdate && Trigger.isAfter) {
                List<SObject> recs2AddOwner = new List<SObject>();
                if(Trigger.oldMap == null) {
                    recs2AddOwner.addAll(Trigger.New);
                } else {
                    for (SObject newRec : Trigger.New){
                        SObject oldRec = Trigger.oldMap.get(newRec.Id);
                        if(oldRec.get('OwnerId') != newRec.get('OwnerId')) {
                            recs2AddOwner.add(newRec);
                        }
                    }
                }

                if(recs2AddOwner.size() > 0) {
                    // examine each object and fetch data...
                    Set<Id> ownerIds = new Set<Id>();
                    Set<Id> reviewIds = new Set<id>();
                    
                    // milestone Id : user Id
                    Map<Id, Id> ms_review_ownerMap = new Map<Id, Id>();

                    // get the parent Ids, use metadata...
                    String objectLabel = BGCM.UtilitySObject.getObjectNameFromId(recs2AddOwner[0].Id);
                    String parentAPILookupField;
                    String parentAPIObject;
                    MUSW__Bluebeam_Relationship_Setting__mdt[] parentMapMdts = getRelationshipMetadata(objectLabel, 'Review');
                    
                    // find the relationship field use first found value...
                    for(MUSW__Bluebeam_Relationship_Setting__mdt parentMapMdt : parentMapMdts) {
                        if(recs2AddOwner[0].get(parentMapMdt.MUSW__Parent_Lookup_API_Name__c) != null) {
                            parentAPILookupField = (String)parentMapMdt.MUSW__Parent_Lookup_API_Name__c;
                            parentAPIObject = (String)parentMapMdt.MUSW__Parent_Object_API_Name__c;
                        }
                    }
                    
                    // get the project id and current owner email address then call
                    for (SObject record : recs2AddOwner){
                        reviewIds.add(record.Id);
                        ownerIds.add((Id)record.get('OwnerId'));
                        ms_review_ownerMap.put((Id)record.get(parentAPILookupField), (Id)record.get('OwnerId'));
                    }
                    
                    // get the Bluebeam User Emails...
                    Map<Id, String> emailMap = new Map<Id, String>();
                    if (ownerIds.size() > 0){
                        Map<Id, User> usersMap = new Map<Id, User>([SELECT MUSW__BG_BlueBeam_Email_Address__c FROM User WHERE Id=:ownerIds]);
                        for (Id userId : usersMap.keySet()){
                            User u = usersMap.get(userId);
                            if (String.isNotBlank((String)u.MUSW__BG_BlueBeam_Email_Address__c)){
                                emailMap.put(userId, u.MUSW__BG_BlueBeam_Email_Address__c);
                            }
                        }
                    
                        Map<String, List<String>> projectEmailMap = new Map<String, List<String>>();
                        for (Id parentId : ms_review_ownerMap.keyset()){
                            String projectId = getProjectIdfromSessionRecord(parentId);
                            if (String.isNotBlank(projectId)){
                                
                                String userEmail = (String)emailMap.get(ms_review_ownerMap.get(parentId));
                                if (String.isNotBlank(userEmail) && !Test.isRunningTest()){
                                    MUSW.BluebeamProjectService.addBluebeamuser(projectId, userEmail);                                                    
                                }
                            }
                        }
                    }
                }
            }
        } 
 
        /**
          ******************************************************************
          * Helpers to get metadata relationships...
          ******************************************************************
          */
        
        /**
         * Get bluebeam parent-child metadata
         * @param String child object label
         * @param String bluebeam api type
         * @return MUSW__Bluebeam_Relationship_Setting__mdt bluebeam parent-child metadata
         */
        private MUSW__Bluebeam_Relationship_Setting__mdt[] getRelationshipMetadata(String childObjectLabel, String apiType) {
            if(String.isBlank(childObjectLabel) || String.isBlank(apiType)) {
                return null;
            }
    
            MUSW__Bluebeam_Relationship_Setting__mdt[] parentMapMdts = new List<MUSW__Bluebeam_Relationship_Setting__mdt>();
            String queryFields = BGCM.UtilitySObject.getFieldsFor_Str('MUSW__Bluebeam_Relationship_Setting__mdt', false);
            String queryString = 'SELECT ' + queryFields + ' FROM MUSW__Bluebeam_Relationship_Setting__mdt WHERE  MUSW__Child_Object_API_Name__c=\''+childObjectLabel+'\' AND MUSW__Type__c=\''+apiType+'\'';
            parentMapMdts = Database.query( queryString );
    
            if(parentMapMdts.size() > 0) {
                return parentMapMdts;
            } else {
                return null;
            }
        } 
        
        /**
         * Get bluebeam project metadata
         * @param String object label
         * @return MUSW__BlueBleam_Project_Setting__mdt bluebeam project metadata
         */
        private MUSW__BlueBleam_Project_Setting__mdt getProjectMetadata(String objectLabel) {
            if(String.isBlank(objectLabel)) {
                return null;
            }
    
            MUSW__BlueBleam_Project_Setting__mdt[] projectMdts = new List<MUSW__BlueBleam_Project_Setting__mdt>();
            String queryFields = BGCM.UtilitySObject.getFieldsFor_Str('MUSW__BlueBleam_Project_Setting__mdt', false);
            String queryString = 'SELECT ' + queryFields + ' FROM MUSW__BlueBleam_Project_Setting__mdt WHERE MUSW__Object_API_Name__c =\''+objectLabel+'\' LIMIT 1';
            projectMdts = Database.query( queryString );
    
            if(projectMdts.size() > 0) {
                return projectMdts[0];
            } else {
                return null;
            }
        } 
        
        /**
         * Retrieve project Id from session record's parent
         * 
         * @param String record Id
         * @return String bluebeam project Id from parent record
         */
        private String getProjectIdfromSessionRecord(String recordId) {
            if(String.isBlank(recordId)) {
                return null;
            }
            String objectLabel = BGCM.UtilitySObject.getObjectNameFromId(recordId);
            //get parent-child metadata for session record
            MUSW__Bluebeam_Relationship_Setting__mdt[] parentMapMdts = getRelationshipMetadata(objectLabel, 'Session');
            if(parentMapMdts == null) {
                throw new BGCM.BGException('There is no Bluebeam Parent Map Settingss for object type: '+objectLabel+'.');
            }
    
            List<String> parentLookupAPIFields = new List<String>();
            if(parentMapMdts.size() > 0) {
                for(MUSW__Bluebeam_Relationship_Setting__mdt parentMapMdt : parentMapMdts) {
                    parentLookupAPIFields.add(parentMapMdt.MUSW__Parent_Lookup_API_Name__c);
                }
            }
    
            String sessionRecordQuery = 'SELECT '+String.join(parentLookupAPIFields, ',')+' FROM '+objectLabel+' WHERE Id=\''+recordId+'\'';
            SObject[] sessionRecords = Database.query( sessionRecordQuery );
    
            if(sessionRecords.size() > 0) {
                String parentAPILookupField;
                String parentAPIObject;
                for(MUSW__Bluebeam_Relationship_Setting__mdt parentMapMdt : parentMapMdts) {
                    if(sessionRecords[0].get(parentMapMdt.MUSW__Parent_Lookup_API_Name__c) != null) {
                        parentAPILookupField = (String)parentMapMdt.MUSW__Parent_Lookup_API_Name__c;
                        parentAPIObject = (String)parentMapMdt.MUSW__Parent_Object_API_Name__c;
                    }
                }
    
                //get project metadata
                MUSW__BlueBleam_Project_Setting__mdt projectMdt = getProjectMetadata(parentAPIObject);
                if(projectMdt == null) {
                    throw new BGCM.BGException('There is no Bluebeam Projects Settingss for object type: '+parentAPIObject+'.');
                }
    
                String projectRecordQuery = 'SELECT '+projectMdt.MUSW__BlueBeam_Project_Id_API_Name__c+' FROM '+parentAPIObject+' WHERE Id=\''+sessionRecords[0].get(parentAPILookupField)+'\' LIMIT 1';
                SObject[] projectRecords = Database.query( projectRecordQuery );
    
                if(projectRecords.size() > 0) {
                    return (String)projectRecords[0].get(projectMdt.MUSW__BlueBeam_Project_Id_API_Name__c);
                } else {
                    return null;
                }
            }
            else {
                return null;
            }
        }    
    }
}