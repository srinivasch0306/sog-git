@isTest
public class AvoProcessHelperTest {

    @isTest
    static void GetProcessSummary_FromProcess_Permit() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Permit Relinquishment', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Trigger__c transitionTrigger = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, 'Completeness Review', '', '');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('All Reviews', '', '', transition.Id, 'Approved');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Event_Type__c = '30 Day Planning Commission Meeting',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = 'Avo_90_Day_Planning_Commission_Mtg_Date__c',
            Avo_Offset__c = 0,
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        Master_Review_List__c review1 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', 'Permit Relinquishment', '', 'Avo Review Default');
        review1.Manual_Creation_Allowed__c = true;
        update review1;

        MUSW__Master_Fee_List__c fee1 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', 'Permit Relinquishment', '', 'Avo Fee Default');
        MUSW__Master_Submission_List__c submisison1 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', 'Permit Relinquishment', '', 'Avo Submission Default');
        MUSW__Master_Inspection_List__c inspection1 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', 'Permit Relinquishment', '', 'Avo Inspection Default');
      

        List<AvoProcessHelper.item> result = AvoProcessHelper.GetProcessSummary(process.Id, '');

        System.assertEquals(2, result.size());
    }


    @isTest
    static void GetProcessSummary_FromTransition_Permit() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Permit Relinquishment', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Trigger__c transitionTrigger = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, 'Completeness Review', '', '');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('All Reviews', '', '', transition.Id, 'Approved');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Event_Type__c = '30 Day Planning Commission Meeting',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = 'Avo_90_Day_Planning_Commission_Mtg_Date__c',
            Avo_Offset__c = 0,
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        List<AvoProcessHelper.item> result = AvoProcessHelper.GetProcessSummary(transition.Id, 'AVO_Process_State_Transition__c');

        System.assertEquals(2, result.size());
    }


    @isTest
    static void GetProcessSummary_FromProcess_Application() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('', 'Development Permit');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Trigger__c transitionTrigger = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, 'Completeness Review', '', '');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('All Reviews', '', '', transition.Id, 'Approved');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Event_Type__c = '30 Day Planning Commission Meeting',
            Avo_Formula_Condition__c = 'a = b',
            Avo_Date_Field__c = 'Avo_90_Day_Planning_Commission_Mtg_Date__c',
            Avo_Offset__c = 0,
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        String eventName = '30 Day Planning Commission Meeting';
        String applicationType = 'Development Permit';
        String recordType = 'Default';
        
        Master_Event_List__c event =  AvoProcessEngineTestFactory.SetUpMasterEvent(eventName, applicationType, recordType);

        Master_Task_List__c task = new Master_Task_List__c(
            Avo_Planning_Application_Type__c = applicationType,
            Name = 'Agenda Update'
        );

        insert task;

        List<AvoProcessHelper.item> result = AvoProcessHelper.GetProcessSummary(process.Id, '');

        System.assertEquals(2, result.size());
    }

    @isTest
    static void GetProcessSummary_FromProcess_Permit_Multiple() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Permit Relinquishment', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        
        AVO_Process_State_Transition_Trigger__c transitionTrigger1 = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, 'Completeness Review', '', '');
        transitionTrigger1.Avo_Review_Status__c = 'Approved';
        update transitionTrigger1;

        AVO_Process_State_Transition_Trigger__c transitionTrigger2 = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, 'Completeness Review', '', '');
        transitionTrigger2.Avo_Review_Status__c = 'Approved';
        update transitionTrigger2;
       
        AVO_Process_State_Transition_Trigger__c transitionTrigger3 = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, '', '', 'TPA Final Inspection');
        transitionTrigger3.Avo_Inspection_Result__c = 'Completed';
        update transitionTrigger3;

        AVO_Process_State_Transition_Trigger__c transitionTrigger4 = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, '', 'Any Fee', '');
        
        
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('All Reviews', '', '', transition.Id, 'Approved');
        AVO_Process_State_Transition_Stopper__c stopper1 = AvoProcessEngineTestFactory.SetUpCondition('', 'Any Fee', '', transition.Id, 'fully paid');
        AVO_Process_State_Transition_Stopper__c stopper2 = AvoProcessEngineTestFactory.SetUpCondition('', '', 'TPA Final Inspection', transition.Id, 'Completed');
        AVO_Process_State_Transition_Stopper__c stopper3 = AvoProcessEngineTestFactory.SetUpCondition('', '', 'TPA Final Inspection', transition.Id, 'Completed');


        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Event_Type__c = '30 Day Planning Commission Meeting',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = 'Avo_90_Day_Planning_Commission_Mtg_Date__c',
            Avo_Offset__c = 0,
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        Master_Review_List__c review1 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', 'Permit Relinquishment', '', 'Avo Review Default');
        review1.Manual_Creation_Allowed__c = true;
        update review1;

        MUSW__Master_Fee_List__c fee1 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', 'Permit Relinquishment', '', 'Avo Fee Default');
        MUSW__Master_Submission_List__c submisison1 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', 'Permit Relinquishment', '', 'Avo Submission Default');
        MUSW__Master_Inspection_List__c inspection1 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', 'Permit Relinquishment', '', 'Avo Inspection Default');
      

        List<AvoProcessHelper.item> result = AvoProcessHelper.GetProcessSummary(process.Id, '');

        System.assertEquals(2, result.size());
    }



    @isTest
    static void getReviews() {
        Master_Review_List__c review1 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', 'Agricultural Water Withdrawal Application', '', 'Avo Review Default');
        List<AvoProcessHelper.item> result = AvoProcessHelper.getReviews('Agricultural Water Withdrawal Application');

        System.assertEquals(1, result.size());

    }

    @isTest
    static void cloneProcess() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Agricultural Water Withdrawal Application', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        
        AVO_Process_State_Transition_Trigger__c transitionTrigger1 = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, 'All Reviews', '', '');
        transitionTrigger1.Avo_Review_Status__c = 'Approved';
        update transitionTrigger1;

        AVO_Process_State_Transition_Trigger__c transitionTrigger2 = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, 'All Reviews', '', '');
        transitionTrigger2.Avo_Review_Status__c = 'Approved';
        update transitionTrigger2;
       
        AVO_Process_State_Transition_Trigger__c transitionTrigger3 = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, '', '', 'TPA Final Inspection');
        transitionTrigger3.Avo_Inspection_Result__c = 'Completed';
        update transitionTrigger3;

        AVO_Process_State_Transition_Trigger__c transitionTrigger4 = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, '', 'Any Fee', '');
        
        
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('All Reviews', '', '', transition.Id, 'Approved');
        AVO_Process_State_Transition_Stopper__c stopper1 = AvoProcessEngineTestFactory.SetUpCondition('', 'Any Fee', '', transition.Id, 'fully paid');
        AVO_Process_State_Transition_Stopper__c stopper2 = AvoProcessEngineTestFactory.SetUpCondition('', '', 'All Inspections', transition.Id, 'Completed');
        AVO_Process_State_Transition_Stopper__c stopper3 = AvoProcessEngineTestFactory.SetUpCondition('', '', 'All Inspections', transition.Id, 'Completed');


        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Event_Type__c = '30 Day Planning Commission Meeting',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = 'Avo_90_Day_Planning_Commission_Mtg_Date__c',
            Avo_Offset__c = 0,
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        Master_Review_List__c review1 = AvoProcessEngineTestFactory.SetUpMasterReview('Revision', 'Agricultural Water Withdrawal Application', '', 'Agricultural Water Withdrawal Permit');
        review1.Manual_Creation_Allowed__c = true;
        update review1;

        MUSW__Master_Fee_List__c fee1 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', 'Permit Relinquishment', '', 'Avo Fee Default');
        MUSW__Master_Submission_List__c submisison1 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', 'Permit Relinquishment', '', 'Avo Submission Default');
        MUSW__Master_Inspection_List__c inspection1 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', 'Permit Relinquishment', '', 'Avo Inspection Default');
      

        String result = AvoProcessHelper.cloneProcess(process.Id, '', '');

        System.assertNotEquals(null, result);
    }


}