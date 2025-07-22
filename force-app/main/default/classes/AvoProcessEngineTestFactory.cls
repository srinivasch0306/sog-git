@isTest
public class AvoProcessEngineTestFactory {

    public static AVO_Process__c SetUpProcess(String permitType, String applicationType) {
        AVO_Process__c entity = new AVO_Process__c(
            Name = 'Unit Test',
            Avo_Effective_End_Date__c = Date.newInstance(2021, 1, 1),
            Avo_Permit_Type__c = permitType,
            Avo_Planning_Application_Type__c = (!String.isblank(applicationType)) ? applicationType : ' '
        );

        if (!String.isblank(permitType)) {
            //entity.RecordTypeId = '012050000004SgXAAU';
            ID PermitProcessRecordTypeID = Schema.SObjectType.AVO_Process__c.getRecordTypeInfosByName().get('Permit Process').getRecordTypeId();
            entity.RecordTypeId = PermitProcessRecordTypeID;
            entity.Avo_Process_Type__c = 'Permit Process';
        }

        if (!string.isblank(applicationType)) {
            ID PlanningApplicationProcessRecordTypeID = Schema.SObjectType.AVO_Process__c.getRecordTypeInfosByName().get('Planning Application Process').getRecordTypeId();
            entity.RecordTypeId = PlanningApplicationProcessRecordTypeID;
            //entity.RecordTypeId = '012050000004SgcAAE';
            entity.Avo_Process_Type__c = 'Planning Application Process';
        }

        insert entity;

        return entity;
    }

    public static AVO_Process_State_Transition__c SetUpTransition(Id processId, String fromState, String toState) {

        AVO_Process_State_Transition__c entity = new AVO_Process_State_Transition__c(
            Avo_Process__c = processId,
            Avo_From_State__c = fromState,
            Avo_To_State__c = toState
        );

        insert entity;

        return entity;
    }

    public static AVO_Process_State_Transition_Trigger__c SetUpTrigger(Id transitionId, String reviewType, String feeType, String inspectionType) {

        AVO_Process_State_Transition_Trigger__c entity = new AVO_Process_State_Transition_Trigger__c(
            AVO_Process_State_Transition__c = transitionId,
            Avo_Review_Type__c = reviewType,
            Avo_Fee_Type__c = feeType,
            Avo_Inspection_Type__c = inspectionType
        );

        insert entity;

        return entity;
    }

    public static AVO_Process_State_Transition_Stopper__c SetUpCondition(String reviewType, String feeType, String inspectionType, 
    Id transitionId, String expectedResult) {

        AVO_Process_State_Transition_Stopper__c entity = new AVO_Process_State_Transition_Stopper__c(
            Avo_Process_State_Transition__c = transitionId
        );

        if (!String.isblank(reviewType)) {
            Id ReviewConditionRecordTypeID = Schema.SObjectType.AVO_Process_State_Transition_Stopper__c.getRecordTypeInfosByName().get('Review Condition').getRecordTypeId();
            entity.RecordTypeId = ReviewConditionRecordTypeID;
            //entity.RecordTypeId = '012050000004SnnAAE';
            entity.Avo_Review_Type__c = reviewType;
            entity.Avo_Review_Status__c = expectedResult;
        }

        if (!String.isblank(feeType)) {
            Id FeeConditionRecordTypeID = Schema.SObjectType.AVO_Process_State_Transition_Stopper__c.getRecordTypeInfosByName().get('Fee Condition').getRecordTypeId();
            entity.RecordTypeId = FeeConditionRecordTypeID;
            //entity.RecordTypeId = '012050000004SnoAAE';
            entity.Avo_Fee_Type__c = feeType;
            entity.Avo_Fee_Status__c = expectedResult;
        }

        if (!String.isblank(inspectionType)) {
            Id InspectionConditionRecordTypeID = Schema.SObjectType.AVO_Process_State_Transition_Stopper__c.getRecordTypeInfosByName().get('Inspection Condition').getRecordTypeId();
            //entity.RecordTypeId = '012050000004SnpAAE';
            entity.RecordTypeId = InspectionConditionRecordTypeID;
            entity.Avo_Inspection_Type__c = inspectionType;
            entity.Avo_Inspection_Result__c = expectedResult;
        }

        insert entity;

        return entity;
    }

    
// Code Changes Made By Shalini 22-06-22
    public static MUSW__Permit2__c SetUpPermit(String type, String status, String lastName, String accountId) {
        Contact contact = new Contact(
            LastName = lastName,
            AccountId = (id) accountId
        );
        insert contact;
        
        
        MUSW__Permit2__c entity = new MUSW__Permit2__c(
            MUSW__Type__c = type,
            MUSW__Status__c = status,
            MUSW__Account__c = contact.AccountId,
            MUSW__Applicant__c = contact.id
        );

        insert entity;

        return entity;
    }

    public static MUSW__Permit2__c SetUpPermit() {
        MUSW__Permit2__c entity = new MUSW__Permit2__c();
			entity.AVO_Volumetric_Limits__c = 8.0;
        insert entity;

        return entity;
    }    

    public static MUSW__Application2__c SetUpApplication(String type, String recordTypeId) {
        MUSW__Application2__c entity = new MUSW__Application2__c(
            MUSW__Type__c = type
            //RecordTypeId = recordTypeId

        );

        insert entity;

        return entity;
    }

    public static MUSW__Review__c SetUpReview(Id permitId, Id applicationId, String type, String status) {

        MUSW__Review__c entity = new MUSW__Review__c(
            MUSW__Type__c = type,
            MUSW__Status__c = status
        );

        if (permitId != null)
        {
            entity.MUSW__Permit2__c = permitId;
        }

        if (applicationId != null) {
            entity.MUSW__Application2__c = applicationId;
        }

        insert entity;

        return entity;
    }

    public static MUSW__Inspection__c SetUpInspection(Id permitId, Id applicationId, String type, String status) {

        MUSW__Inspection__c entity = new MUSW__Inspection__c(
            MUSW__Type__c = type,
            MUSW__Status__c= status
        );

        if (permitId != null)
        {
            entity.MUSW__Permit__c = permitId;
        }

        if (applicationId != null) {
            entity.Avo_Application__c = applicationId;
        }

        insert entity;

        return entity;
    }

    public static MUSW__Fee__c SetUpFee(Id permitId, Id applicationId, String type, Decimal amount, Decimal amountPaid) {

        MUSW__Fee__c entity = new MUSW__Fee__c(
            MUSW__Type__c = type,
            MUSW__Amount__c = amount,
            MUSW__Amount_Paid__c = amountPaid
        );

        if (permitId != null)
        {
            entity.MUSW__Permit2__c = permitId;
        }

        if (applicationId != null) {
            entity.MUSW__Application2__c = applicationId;
        }

        insert entity;

        return entity;
    }

    public static MUSW__Submission__c SetUpSubmission(Id permitId, Id applicationId, String type, String status) {

        MUSW__Submission__c entity = new MUSW__Submission__c(
        );

        if (permitId != null)
        {
            entity.MUSW__Permit2__c = permitId;
        }

        if (applicationId != null) {
            entity.MUSW__Application2__c = applicationId;
        }

        insert entity;

        return entity;
    }

    public static Master_Event_List__c SetUpMasterEvent(String name, String type, String recordType) {

        Master_Event_List__c entity = new Master_Event_List__c(
            Name = name,
            Avo_Planning_Application_Type__c = type,
            Record_Type__c = recordType,
            Effective_Start_Date__c = Date.today().addDays(-1)
        );

        insert entity;

        return entity;
    }

    public static Master_Review_List__c SetUpMasterReview(String name, string permitType, String applicationType, String recordType) {

        Master_Review_List__c entity = new Master_Review_List__c(
            Name = name,
            Avo_Planning_Application_Type__c = applicationType,
            Avo_Permit_Type__c = permitType,
            Record_Type__c = recordType,
            Effective_Start_Date__c = Date.today().addDays(-1)
        );

        insert entity;

        return entity;
    }

    public static MUSW__Master_Fee_List__c SetUpMasterFee(String name, string permitType, String applicationType, String recordType) {

        MUSW__Master_Fee_List__c entity = new MUSW__Master_Fee_List__c(
            Name = name,
            Avo_Planning_Application_Type__c = applicationType,
            Avo_Permit_Type__c = permitType,
            Record_Type__c = recordType,
            Effective_Start_Date__c = Date.today().addDays(-1)
        );

        insert entity;

        return entity;
    }

    public static MUSW__Master_Inspection_List__c SetUpMasterInspection(String name, string permitType, String applicationType, String recordType) {

        MUSW__Master_Inspection_List__c entity = new MUSW__Master_Inspection_List__c(
            Name = name,
            Avo_Planning_Application_Type__c = applicationType,
            Avo_Permit_Type__c = permitType,
            Record_Type__c = recordType,
            Effective_Start_Date__c = Date.today().addDays(-1)
        );

        insert entity;

        return entity;
    }

    public static MUSW__Master_Submission_List__c SetUpMasterSubmission(String name, string permitType, String applicationType, String recordType) {

        MUSW__Master_Submission_List__c entity = new MUSW__Master_Submission_List__c(
            Name = name,
            Avo_Planning_Application_Type__c = applicationType,
            Avo_Permit_Type__c = permitType,
            Record_Type__c = recordType,
            Effective_Start_Date__c = Date.today().addDays(-1)
        );

        insert entity;

        return entity;
    }

  

    public static Contact SetUpContact(String name, String email) {

        Contact entity = new Contact(
            FirstName = name,
            LastName = name,
            Email = email
        );

        insert entity;

        return entity;
    }


}