public with sharing class AvoConsolidate {
    @InvocableMethod(label= 'Consolidate' description = 'Consolidates a record into a retained record. Can be App to App, App to Perm, or Perm to Perm')
    public static List<ID> consolidateRecord(List<ConsolidationReq> reqs) {
        // Record Type IDs
        ID WITHDRAWAL_APP_REC_TYPE_ID = Schema.SObjectType.MUSW__Review__c.getRecordTypeInfosByDeveloperName()
            .get('AVO_Agricultural_Water_Withdrawal_Application')?.getRecordTypeId();
        if (WITHDRAWAL_APP_REC_TYPE_ID == null) {
            System.debug('Error: AVO_Agricultural_Water_Withdrawal_Application record type not found');
        }

        ID WITHDRAWAL_PERMIT_REC_TYPE_ID = Schema.SObjectType.MUSW__Review__c.getRecordTypeInfosByDeveloperName()
            .get('Agricultural_Water_Withdrawal_Permit')?.getRecordTypeId();
        if (WITHDRAWAL_PERMIT_REC_TYPE_ID == null) {
            System.debug('Error: Agricultural_Water_Withdrawal_Permit record type not found');
        }

        ID LOC_REVIEW_REC_TYPE_ID = Schema.SObjectType.MUSW__Review__c.getRecordTypeInfosByDeveloperName()
            .get('AVO_Review_Default_Withdrawal_LOC_Review_Only')?.getRecordTypeId();
        if (LOC_REVIEW_REC_TYPE_ID == null) {
            System.debug('Error: AVO_Review_Default_Withdrawal_LOC_Review_Only record type not found');
        }

        List<MUSW__Permit2__c> permitsToUpdate = new List<MUSW__Permit2__c>();
        List<AVO_Withdrawals__c> withdrawalsToUpdate = new List<AVO_Withdrawals__c>();
        List<AVO_Meter_Transaction__c> metersToUpdate = new List<AVO_Meter_Transaction__c>();
        List<MUSW__Review__c> reviewsToUpdate = new List<MUSW__Review__c>();
        List<Task> tasksToUpdate = new List<Task>();
        List<ID> keptIDs = new List<ID>();
        List<String> reviewTypes = new List<String>();

        for (ConsolidationReq request : reqs) {
            System.debug('Processing request: ' + request);
            
            if (request.recordIdToKeep == null || request.recordIdToConsolidate == null) {
                System.debug('Error: One of the record IDs is null. recordIdToKeep: ' + request.recordIdToKeep + ' recordIdToConsolidate: ' + request.recordIdToConsolidate);
                continue;
            }
            
            keptIDs.add(request.recordIdToKeep);
            String consolidateObjectName = request.recordIdToConsolidate.getSObjectType().getDescribe().getName();
            
            // Query permit records
            List<MUSW__Permit2__c> permitToKeepList = [SELECT ID, Name, recordTypeId, MUSW__Status__c, AVO_Transaction_Type__c, AVO_GIS_Unique_ID__c, MUSW__Type__c
                                                       FROM MUSW__Permit2__c WHERE ID IN (:request.recordIdToKeep)];
            List<MUSW__Permit2__c> permitToConsolidateList = [SELECT ID, Name, recordTypeId, AVO_Transaction_Type__c, AVO_Inactive_Reason__c, AVO_ActiveRefNo__c
                                                           FROM MUSW__Permit2__c WHERE ID IN (:request.recordIdToConsolidate)];

            if (permitToKeepList.isEmpty() || permitToConsolidateList.isEmpty()) {
                System.debug('Error: One of the permit records is missing. permitToKeepList: ' + permitToKeepList + ' permitToConsolidateList: ' + permitToConsolidateList);
                continue;
            }
            
            MUSW__Permit2__c permitToKeep = permitToKeepList[0];
            MUSW__Permit2__c permitToConsolidate = permitToConsolidateList[0];

            System.debug('Consolidating ' + permitToConsolidate + ' into ' + permitToKeep);

            // Logic for the permit to keep
            if (permitToKeep.recordTypeId == WITHDRAWAL_PERMIT_REC_TYPE_ID) {
                System.debug('Permit to keep is a permit');
                if (permitToKeep.MUSW__Status__c == 'Form Assesment' || permitToKeep.MUSW__Status__c == 'Final Evaluation') {
                    permitToKeep.MUSW__Status__c = 'In Review';
                    System.debug('in final eval if');
                }
                permitToKeep.MUSW__Status__c = 'In Review';
                permitToKeep.AVO_Transaction_Type__c = 'New Permit';
            }
            if (permitToKeep.recordTypeId == WITHDRAWAL_APP_REC_TYPE_ID) {
                System.debug('Permit to keep is an application');
                if (!(permitToKeep.MUSW__Status__c == 'Pending' || permitToKeep.MUSW__Status__c == 'Submitted')) {
                    if (permitToKeep.MUSW__Status__c == 'In Review') {
                        reviewTypes.add('Withdrawal LOC Review');
                    }
                    else {
                        permitToKeep.MUSW__Status__c = 'In Review';
                    }
                }
                
                permitToKeep.AVO_Transaction_Type__c = 'New Permit';
            }

            // Logic for the permit to consolidate
            if (permitToConsolidate.recordTypeId == WITHDRAWAL_PERMIT_REC_TYPE_ID) {
                System.debug('Permit to consolidate is a permit');
                permitToConsolidate.AVO_Transaction_Type__c = 'Consolidate Permit';
                permitToConsolidate.AVO_Transaction_Status__c = 'To Be Consolidated';
                permitToConsolidate.AVO_Inactive_Reason__c = 'Consolidated Permit';
                permitToConsolidate.AVO_ActiveRefNo__c = permitToKeep.Id;
                permitToConsolidate.MUSW__Status__c = 'Consolidated';
            }
            if (permitToConsolidate.recordTypeId == WITHDRAWAL_APP_REC_TYPE_ID) {
                System.debug('Permit to consolidate is an application');
                permitToConsolidate.AVO_Transaction_Type__c = 'New Permit';
                permitToConsolidate.AVO_Permit_Closed_Status__c = 'Cancelled Application';
                permitToConsolidate.AVO_Inactive_Reason__c = 'Merged to an existing application/permit';
                permitToConsolidate.AVO_ActiveRefNo__c = permitToKeep.Id;
                permitToConsolidate.MUSW__Status__c = 'Consolidated';
            }

            // Fail Back reviews 
            List<MUSW__Review__c> LOCReviews = [SELECT Name, ID, MUSW__Status__c FROM MUSW__Review__c WHERE MUSW__Permit2__c = :permitToKeep.Id
                                                 AND MUSW__Type__c IN ('Withdrawal LOC Review', 'Form Assessment Review', 'Final Evaluation Review', 'Metering Review', 'Waiver Review')];
            if (LOCReviews.isEmpty()) {
                System.debug('No reviews found for permitToKeep');
            } else {
                for (MUSW__Review__c review : LOCReviews) {
                    review.MUSW__Status__c = 'Fail Back';
                }
                reviewsToUpdate.addAll(LOCReviews);
            }

            // Create new reviews
            AvoProcessEnginePermit process = new AvoProcessEnginePermit(permitToKeep);
            System.debug('Creating reviews');
            process.createReview(reviewTypes);
            System.debug('Created ' + reviewTypes + ' reviews');

            // Set old GIS tasks to cancelled
            List<Task> oldTasks = [SELECT ID, Status, WhatId FROM Task WHERE WhatId = :permitToKeep.Id];
            for (Task t : oldTasks) {
                t.Status = 'Denied';
            }
            tasksToUpdate.addAll(oldTasks);

            // Create GIS Task
            process.createTask(new AVO_Process_State_Post_Actions__c(Avo_Task_Type__c = 'GIS Application Mapping'));
            System.debug('creating GIS Application Mapping');

			// 130 commented by Adithya 
            //withdrawalsToUpdate.addAll(consolidateWithdrawals(permitToConsolidate.Id, permitToKeep));
            metersToUpdate.addAll(consolidateMeterTransaction(permitToConsolidate.Id, permitToKeep));

            permitsToUpdate.add(permitToConsolidate);
            permitsToUpdate.add(permitToKeep);
        }

        // Final update operations
        try {
            update withdrawalsToUpdate;
            update metersToUpdate;
            update permitsToUpdate;
            update reviewsToUpdate;
            update tasksToUpdate;
        } catch (Exception e) {
            System.debug('Error during update operations: ' + e.getMessage());
        }

        return keptIDs;
    }
// 150 to 168 commented by Adithya 
  /*  public static List<AVO_Withdrawals__c> consolidateWithdrawals(ID oldPermitID, MUSW__Permit2__c newPermit) {
        List<AVO_Withdrawals__c> updatedWithdrawals = new List<AVO_Withdrawals__c>();
        List<AVO_Withdrawals__c> relatedWithdrawals = [SELECT ID, App_ID__c, AVO_Permit__c, AVO_Well_Number__c, AVO_GIS_UNIQUE__c, AVO_Well_Status__c, AVO_Pump_Activity_Use__c
            FROM AVO_Withdrawals__c WHERE AVO_Permit__c = :oldPermitID];
        
        if (relatedWithdrawals.isEmpty()) {
            System.debug('No related withdrawals found for old permit: ' + oldPermitID);
        }

        for (AVO_Withdrawals__c withdrawal : relatedWithdrawals) {
            withdrawal.App_ID__c = newPermit.ID;
            withdrawal.AVO_Permit__c = newPermit.ID;
            withdrawal.AVO_GIS_UNIQUE__c = newPermit.AVO_GIS_Unique_ID__c;
            withdrawal.AVO_Well_Status__c = 'Permit/App Consolidated';
            withdrawal.AVO_Pump_Activity_Use__c = 'Inactive';
            updatedWithdrawals.add(withdrawal);
        }
        return updatedWithdrawals;
    }*/

    public static List<AVO_Meter_Transaction__c> consolidateMeterTransaction(ID oldPermitID, MUSW__Permit2__c newPermit) {
        List<AVO_Meter_Transaction__c> updatedMeterTransaction = new List<AVO_Meter_Transaction__c>();
        List<AVO_Meter_Transaction__c> relatedMeterTransaction = [SELECT ID, AVO_Application_Number__c, AVO_Permit_Number__c
            FROM AVO_Meter_Transaction__c WHERE AVO_Application_Number__c = :oldPermitID OR AVO_Permit_Number__c = :oldPermitID];
        
        if (relatedMeterTransaction.isEmpty()) {
            System.debug('No related meter transactions found for old permit: ' + oldPermitID);
        }

        for (AVO_Meter_Transaction__c meter : relatedMeterTransaction) {
            if (meter.AVO_Application_Number__c == oldPermitID) {
                meter.AVO_Application_Number__c = newPermit.ID;
            }
            if (meter.AVO_Permit_Number__c == oldPermitID) {
                meter.AVO_Permit_Number__c = newPermit.ID;
            }
            updatedMeterTransaction.add(meter);
        }
        return updatedMeterTransaction;
    }

    public class ConsolidationReq {
        @InvocableVariable(label = 'RecordId To Keep' description = 'The ID of record that is being kept' required = true)
        public ID recordIdToKeep;

        @InvocableVariable(label = 'RecordId To Consolidate' description = 'The ID of record that is being consolidated' required = true)
        public ID recordIdToConsolidate;
    }
}