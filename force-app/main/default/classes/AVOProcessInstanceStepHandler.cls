public with sharing class AVOProcessInstanceStepHandler {

    @InvocableMethod(label='Update Permit with Step Name' description='Fetch the latest ProcessInstanceStep and update AVO_Approval_Step__c in Permit.')
    public static void updatePermitWithStepName(List<Id> permitIds) {
        System.debug('Permit Ids passed to the method: ' + permitIds);

        if (permitIds == null || permitIds.isEmpty()) {
            System.debug('No Permit IDs provided. Exiting.');
            return;
        }

        // Query ProcessInstance related to the Permit(s)
        List<ProcessInstance> processInstances = [
            SELECT Id, TargetObjectId, ProcessDefinition.Name 
            FROM ProcessInstance 
            WHERE TargetObjectId IN :permitIds
        ];
        System.debug('Queried ProcessInstances: ' + processInstances);

        if (processInstances.isEmpty()) {
            System.debug('No ProcessInstances found. Exiting.');
            return;
        }

        // Get ProcessInstance IDs
        Set<Id> processInstanceIds = new Set<Id>();
        for (ProcessInstance pi : processInstances) {
            processInstanceIds.add(pi.Id);
        }
        System.debug('ProcessInstance IDs: ' + processInstanceIds);

        // Query the latest ProcessInstanceStep for each ProcessInstance
        Map<Id, ProcessInstanceStep> latestStepsMap = new Map<Id, ProcessInstanceStep>();
        for (ProcessInstanceStep step : [
            SELECT Id, ProcessInstanceId, CreatedDate 
            FROM ProcessInstanceStep
            WHERE ProcessInstanceId IN :processInstanceIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!latestStepsMap.containsKey(step.ProcessInstanceId)) {
                latestStepsMap.put(step.ProcessInstanceId, step);
            }
        }
        System.debug('Latest Steps Map: ' + latestStepsMap);

        // Update the Permit records with the Process Definition Name (approval process name)
        List<MUSW__Permit2__c> permitsToUpdate = new List<MUSW__Permit2__c>();
        for (ProcessInstance pi : processInstances) {
            if (latestStepsMap.containsKey(pi.Id)) {
                ProcessInstanceStep latestStep = latestStepsMap.get(pi.Id);
                String approvalProcessName = pi.ProcessDefinition != null ? pi.ProcessDefinition.Name : 'Unknown Process';
                System.debug('Updating Permit ID: ' + pi.TargetObjectId + ' with Approval Process Name: ' + approvalProcessName);
                permitsToUpdate.add(new MUSW__Permit2__c(
                    Id = pi.TargetObjectId,
                    AVO_Approval_Step__c = approvalProcessName
                ));
            }
        }

        if (!permitsToUpdate.isEmpty()) {
            System.debug('Permits to update: ' + permitsToUpdate);
            update permitsToUpdate;
        } else {
            System.debug('No permits to update.');
        }
    }
}