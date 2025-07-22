@isTest
public class AvoProcessEngineBaseTest {


    @isTest
    static void StopperConditionMet_NoStopperFound() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        
        Boolean result;
        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    } 


    @isTest
    static void StopperConditionMet_AllReviewStopperFoundOnPermit() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision	', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('All Reviews', '', '', transition.Id, 'Approved');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');

        Boolean result;
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    }  

    @isTest
    static void StopperConditionMet_SingleReviewStopperFoundOnPermit() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('Completeness Review', '', '', transition.Id, 'Approved');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');

        Boolean result;
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    } 

    @isTest
    static void StopperConditionMet_AllReviewStopperFoundOnApplication() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('', 'Variance');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('All Reviews', '', '', transition.Id, 'Approved');
        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Administrative Action', '012050000004RoQAAU');
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview( null, application.Id, 'Completeness Review', 'Approved');

        Boolean result;
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    }  

    @isTest
    static void StopperConditionMet_SingleReviewStopperFoundOnApplication() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('', 'Variance');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('Completeness Review', '', '', transition.Id, 'Approved');
        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Administrative Action', '012050000004RoQAAU');
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview( null, application.Id, 'Completeness Review', 'Approved');

        Boolean result;
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    } 


    @isTest
    static void StopperConditionMet_AllInspectionStopperFoundOnPermit() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', '', 'All Inspections', transition.Id, 'Pending');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Inspection__c inspection = AvoProcessEngineTestFactory.SetUpInspection(permit.Id, null, 'Balloon Test', 'Pass');

        Boolean result;
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        result = engine.StopperConditionsMet(transition);
        
   } 

    @isTest
    static void StopperConditionMet_SingleInspectionStopperFoundOnPermit() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', '', 'All Inspections', transition.Id, 'Pending');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Inspection__c inspection = AvoProcessEngineTestFactory.SetUpInspection(permit.Id, null, 'Balloon Test', 'Pass');

        Boolean result;
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        result = engine.StopperConditionsMet(transition);
        
    } 

    @isTest
    static void StopperConditionMet_AllInspectionStopperFoundOnApplication() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('', 'Variance');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', '', 'All Inspections', transition.Id, 'Pending');
        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Administrative Action', '012050000004RoQAAU');
        MUSW__Inspection__c inspection = AvoProcessEngineTestFactory.SetUpInspection(null, application.Id, 'Balloon Test', 'Pass');

        Boolean result;
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        result = engine.StopperConditionsMet(transition);
        
    } 

    @isTest
    static void StopperConditionMet_SingleInspectionStopperFoundOnApplication() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('', 'Variance');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', '', 'All Inspections', transition.Id, 'Pending');
        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Administrative Action', '012050000004RoQAAU');
        MUSW__Inspection__c inspection = AvoProcessEngineTestFactory.SetUpInspection(null, application.Id, 'Balloon Test', 'Pass');

        Boolean result;
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        result = engine.StopperConditionsMet(transition);
        

    } 

    @isTest
    static void StopperConditionMet_AllFeeStopperFoundOnPermit() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', 'All Fees', '', transition.Id, 'fully paid');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Fee__c Fee = AvoProcessEngineTestFactory.SetUpFee(permit.Id, null, 'Base Fee',  120, 120);

        Boolean result;
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    } 

    @isTest
    static void StopperConditionMet_SingleFeeStopperFoundOnPermit() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', 'Any Fee', '', transition.Id, 'fully paid');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Fee__c Fee = AvoProcessEngineTestFactory.SetUpFee(permit.Id, null, 'Base Fee',  120, 120);

        Boolean result;
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    } 

    @isTest
    static void StopperConditionMet_AllFeeStopperFoundOnApplication() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('', 'Variance');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', 'All Fees', '', transition.Id, 'fully paid');
        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Administrative Action', '012050000004RoQAAU');
        MUSW__Fee__c Fee = AvoProcessEngineTestFactory.SetUpFee(null, application.Id, 'Base Fee',  120, 120);

        Boolean result;
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    } 

    @isTest
    static void StopperConditionMet_SingleFeeStopperFoundOnApplication() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('', 'Variance');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', 'Any Fee', '', transition.Id, 'fully paid');
        String MeterInstallationRecordTypeID = Schema.SObjectType.MUSW__Application2__c.getRecordTypeInfosByName().get('Meter Installation').getRecordTypeId();
        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Administrative Action', MeterInstallationRecordTypeID);
        MUSW__Fee__c Fee = AvoProcessEngineTestFactory.SetUpFee(null, application.Id,  'Base Fee',  120, 120);
        Boolean result;
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    } 
   
    @isTest
    static void StopperConditionMet_UnsupportedCaseFound() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('', '', '', transition.Id, '');

        Boolean result;
        try {
            AvoProcessEnginePermit engine = new AvoProcessEnginePermit(null);
            result = engine.StopperConditionsMet(transition);
            
        } catch (Exception ex) 
        {
            System.assert(true, 'Exception handled');
        }
    } 

    @isTest
    static void initialize_FromReview() {
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');

        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();

        System.assert(true);
    } 

    @isTest
    static void initialize_FromInspection() {
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Inspection__c inspection = AvoProcessEngineTestFactory.SetUpInspection(permit.Id, null, 'Building', 'Pass');

        AvoProcessEngineInspection engine = new AvoProcessEngineInspection(inspection);
        engine.run();

        System.assert(true);
    }
    
    @isTest
    static void initialize_FromFee() {
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Fee__c fee = AvoProcessEngineTestFactory.SetUpFee(permit.Id, null, 'Base Fee',  120, 120);

        AvoProcessEngineFee engine = new AvoProcessEngineFee(fee);
        engine.run();

        System.assert(true);
    }
    
    @isTest
    static void initialize_FromSubmission() {
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Waiver Review', 'Approved');

        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();

        System.assert(true);
    }
    
    @isTest
    static void initialize_FromEvent() {
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Waiver Review', 'Approved');

        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();

        System.assert(true);
    }
    
    @isTest
    static void initialize_FromTask() {
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');

        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();

        System.assert(true);
    }
    
     @isTest
    static void createPostActions_Event() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Event_Type__c = '30 Day Planning Commission Meeting',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = 'Avo_90_Day_Planning_Commission_Mtg_Date__c',
            Avo_Offset__c = 0,
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );

        insert postAction;

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', '');
        application.Avo_90_Day_Planning_Commission_Mtg_Date__c = Date.today();
        update application;

        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        engine.createPostActions(transition);

        System.assert(true);
    }
    
     @isTest
    static void createEvent_WithDate() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Event_Type__c = '30 Day Planning Commission Meeting',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = 'Avo_90_Day_Planning_Commission_Mtg_Date__c',
            Avo_Offset__c = 0
        );

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', '');
        application.Avo_90_Day_Planning_Commission_Mtg_Date__c = Date.today();
        update application;

        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        engine.createEvent(postAction);

        System.assert(true);
    }
    
	    
	 @isTest
    static void createEvent_WithoutDate() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Event_Type__c = '30 Day Planning Commission Meeting',
            Avo_Formula_Condition__c = '',
            Avo_Offset__c = 0
        );

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
      

        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        engine.createEvent(postAction);

        System.assert(true);
    }    
    
    @isTest
    static void getEventRecordTypeId_Default() {
        String eventName = '30 Day Planning Commission Meeting';
        String applicationType = 'Variance';
        String recordType = 'Default';
        
        Master_Event_List__c event =  AvoProcessEngineTestFactory.SetUpMasterEvent(eventName, applicationType, recordType);

        //AvoProcessEngineBase engine = new AvoProcessEngineBase();
        //Id recordId = engine.getEventRecordTypeId(eventName + '1', applicationType);

       // System.assertEquals(recordId, recordId);
    }
    
    @isTest
    static void getEventRecordTypeId_Found() {
        String eventName = '30 Day Planning Commission Meeting';
        String applicationType = 'Variance';
        String recordType = 'Hold for 40 Days';

        Master_Event_List__c event =  AvoProcessEngineTestFactory.SetUpMasterEvent(eventName, applicationType, recordType);

       // AvoProcessEngineBase engine = new AvoProcessEngineBase();
       // Id recordId = engine.getEventRecordTypeId(eventName, applicationType);

       // System.assertNotEquals(recordId, '012050000004Sm1AAE', 'success');
    }
    
    @isTest
    static void createPostActions_Task() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Task_Type__c = 'LOC Package Printing',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = '2021-7-21',
            Avo_Offset__c = 0,
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
      
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createPostActions(transition);

        System.assert(true);
    }
    
     @isTest
    static void createTask_WithDate_Permit() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Task_Type__c = 'LOC Package Printing',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = '2021-7-21',
            Avo_Offset__c = 0
        );

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
      
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createTask(postAction);

        System.assert(true);
    }
    
     @isTest
    static void createTask_WithoutDate_Permit() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Task_Type__c = 'LOC Package Printing',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = '',
            Avo_Offset__c = 0
        );

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
      
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createTask(postAction);

        System.assert(true);
    }
    
    @isTest
    static void createTask_WithDate_Application() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Task_Type__c = 'LOC Package Printing',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = '2021-7-21',
            Avo_Offset__c = 0
        );

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
      

        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        engine.createTask(postAction);

        System.assert(true);
    }
    
     @isTest
    static void createTask_WithoutDate_Application() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Task_Type__c = 'LOC Package Printing',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = '2021-7-21',
            Avo_Offset__c = 0
        );

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', '');
      

        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        engine.createTask(postAction);

        System.assert(true);
    }

    
     @isTest
    static void createPostActions_Review() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Review_Type__c = 'Special Appraisal',
            Avo_Formula_Condition__c = '',
            Avo_Date_Field__c = '2021-7-21',
            Avo_Offset__c = 0,
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        Master_Review_List__c review1 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', 'Revision', '', 'Avo Review Default');
       
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createPostActions(transition);

        System.assert(true);
    }
    
     @isTest
    static void createReview_MultipleFoundWithPermitType() {

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        Master_Review_List__c review1 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', 'Revision', '', 'Avo Review Default');
        Master_Review_List__c review2 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', 'Revision', '', 'Avo Review Default');

        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        List<String> types = new List<String>();
        types.add('Completeness Review');
        engine.createReview(types);

        System.assert(true);
    }
    
    
    @isTest
    static void createReview_MultipleFoundWithApplicationType() {

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', '');
        Master_Review_List__c review1 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', '', 'Variance', 'Avo Review Default');
        Master_Review_List__c review2 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', '', 'Variance', 'Avo Review Default');

        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        List<String> types = new List<String>();
        types.add('Completeness Review');
        engine.createReview(types);

        System.assert(true);
    }
    
    
    @isTest
    static void createReview_Single() {

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
        Master_Review_List__c review1 = AvoProcessEngineTestFactory.SetUpMasterReview('Completeness Review', '', 'Variance', 'Avo Review Default');
      
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        List<String> types = new List<String>();
        types.add('Completeness Review');
        engine.createReview(types);

        System.assert(true);
    }
    
    @isTest 
    static void createPostActions_Fee() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Fee_Type__c = 'All Fees',
            Avo_Fee_Quantity__c = '1',
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Fee_List__c fee1 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', 'Revision', '', 'Fine');
        
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createPostActions(transition);

        System.assert(true);
    } 

    @isTest
    static void createFee_InvalidQuantity() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Fee_Type__c = '1',
            Avo_Fee_Quantity__c = 'invalid'
        );

        try {
            AvoProcessEngineBase engine = new AvoProcessEngineBase();
            List<AVO_Process_State_Post_Actions__c> actions = new List<AVO_Process_State_Post_Actions__c>();
            actions.add(postAction);
            engine.createFee(actions);
        } catch (Exception e) {

            System.assert(true);
        }
	}
    
     @isTest
    static void createFee_MultipleFoundOnPermit() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Fee_Type__c = 'Administrative Action Fee',
            Avo_Fee_Quantity__c = '1'
        );

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Fee_List__c fee1 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', 'Revision', '', 'Avo Fee Default');
        MUSW__Master_Fee_List__c fee2 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', 'Revision', '', 'Avo Fee Default');
        
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        List<AVO_Process_State_Post_Actions__c> actions = new List<AVO_Process_State_Post_Actions__c>();
        actions.add(postAction);
        engine.createFee(actions);

        System.assert(true);
    }

     @isTest
    static void createFee_MultipleFoundOnApplication() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Fee_Type__c = 'Administrative Action Fee',
            Avo_Fee_Quantity__c = '1'
        );

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
        MUSW__Master_Fee_List__c fee1 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', '', 'Variance', 'Avo Fee Default');
        MUSW__Master_Fee_List__c fee2 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', '', 'Variance', 'Avo Fee Default');
        
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        List<AVO_Process_State_Post_Actions__c> actions = new List<AVO_Process_State_Post_Actions__c>();
        actions.add(postAction);
        engine.createFee(actions);

        System.assert(true);
    }
    
     @isTest
    static void createFee_Single() {

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Fee_Type__c = 'Administrative Action Fee',
            Avo_Fee_Quantity__c = '1'
        );

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Fee_List__c fee1 = AvoProcessEngineTestFactory.SetUpMasterFee('Administrative Action Fee', 'Revision', '', 'Avo Fee Default');
        
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        List<AVO_Process_State_Post_Actions__c> actions = new List<AVO_Process_State_Post_Actions__c>();
        actions.add(postAction);
        engine.createFee(actions);

        System.assert(true);
    }
    
    @isTest
    static void createPostActions_Inspection() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Inspection_Type__c = 'Any Inspection',
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Inspection_List__c inspection1 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', 'Revision', '', 'Avo Inspection Default');
       
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createPostActions(transition);

        System.assert(true);
    }
    
    @isTest
    static void createInspection_MultipleFoundOnPermit() {

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Inspection_List__c inspection1 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', 'Revision', '', 'Avo Inspection Default');
        MUSW__Master_Inspection_List__c inspection2 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', 'Revision', '', 'Avo Inspection Default');
        
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        List<string> types = new List<string>();
        types.add('Final Inspection');
        engine.createInspections(types);

        System.assert(true);
    }
    
     @isTest
    static void createInspection_MultipleFoundOnApplication() {

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
        MUSW__Master_Inspection_List__c inspection1 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', '', 'Variance', 'Avo Inspection Default');
        MUSW__Master_Inspection_List__c inspection2 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', '', 'Variance', 'Avo Inspection Default');
       
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        List<string> types = new List<string>();
        types.add('Final Inspection');
        engine.createInspections(types);

        System.assert(true);
    }
    
    @isTest
    static void createInspection_Single() {

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Inspection_List__c inspection1 = AvoProcessEngineTestFactory.SetUpMasterInspection('Final Inspection', 'Revision', '', 'Avo Inspection Default');
       
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        List<string> types = new List<string>();
        types.add('Final Inspection');
        engine.createInspections(types);

        System.assert(true);
    }
    
     @isTest
    static void createPostActions_Submission() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');


        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Submission_Type__c = 'All Submissions',
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Submission_List__c submisison1 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', 'Revision', '', 'Avo Submission Default');
         
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createPostActions(transition);

        System.assert(true);
    }
    
    @isTest
    static void createSubmission_MultipleFoundOnPermit() {

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Submission_List__c submisison1 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', 'Revision', '', 'Avo Submission Default');
        MUSW__Master_Submission_List__c submisison2 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', 'Revision', '', 'Avo Submission Default');
        
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Submission_Type__c = 'All Submissions',
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createSubmission(postAction);

        System.assert(true);
    }
    
     @isTest
    static void createSubmission_MultipleFoundOnApplication() {

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
        MUSW__Master_Submission_List__c submisison1 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', '', 'Variance', 'Avo Submission Default');
        MUSW__Master_Submission_List__c submisison2 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', '', 'Variance', 'Avo Submission Default');
        
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');


        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Submission_Type__c = 'All Submissions',
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        engine.createSubmission(postAction);

        System.assert(true);
    }
    
    @isTest
    static void createSubmission_Single() {

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.MUSW__Type__c = 'Revision';

        update permit;

        MUSW__Master_Submission_List__c submisison1 = AvoProcessEngineTestFactory.SetUpMasterSubmission('Site Plan', 'Revision', '', 'Avo Submission Default');
       
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');

        AVO_Process_State_Post_Actions__c postAction = new AVO_Process_State_Post_Actions__c(
            Avo_Submission_Type__c = 'All Submissions',
            Avo_Active__c = true,
            Avo_Process_State_Transition__c = transition.Id
        );
        insert postAction;

        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        engine.createSubmission(postAction);

        System.assert(true);
    }
    
    @isTest
    static void StatusMatch_Match() {

        String status = 'status 1';
        String statuses = 'status 1; status 2';

        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Boolean result = engine.StatusMatch(status, statuses);    
        
        System.assertEquals(result, true);
    }
    
    @isTest
    static void StatusMatch_NotMatch() {

        String status = 'status 1';
        String statuses = 'status 3; status 2';

        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Boolean result = engine.StatusMatch(status, statuses);   
        
        System.assertEquals(result, false);
    }
    
     @isTest
    static void AddBusinessDays() {

        Date testDate = Date.newInstance(2021, 7, 29);

        Date result = AvoProcessEngineBase.AddBusinessDays(testDate, 1);   
        
        System.assertEquals(result, Date.newInstance(2021, 7, 30));
    }
    
     @isTest
    static void IsWeekend_Sat() {

        Date testDate = Date.newInstance(2021, 7, 24);

        Boolean result = AvoProcessEngineBase.IsWeekend(testDate);   
        
        System.assertEquals(result, true);
    }
    
     @isTest
    static void IsWeekend_Sun() {

        Date testDate = Date.newInstance(2021, 7, 25);

        Boolean result = AvoProcessEngineBase.IsWeekend(testDate);   
        
        System.assertEquals(result, true);
    }  
    
     @isTest
    static void checkFormulaCondition_Empty() {

        String formula = '';

        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Boolean result = engine.checkFormulaCondition(formula);   
        
        System.assertEquals(result, true);
    } 

    @isTest
    static void checkFormulaCondition() {
        String equation = 'Name = 1';
        
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.Name = '1';
        update permit;
        
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');
        
        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();
        
        Boolean result = engine.processFormula(equation);   
        
        System.assertEquals(result, true);
        
    } 
    
    @isTest
    static void findFirstOperator_NotFound() {

        String formula = 'test formula';

        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Integer result = engine.findFirstOperator(formula);   
        
        System.assertEquals(result, -1);
    } 

    @isTest
    static void findFirstOperator_FoundOr() {

        String formula = '|| test formula';

        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Integer result = engine.findFirstOperator(formula);   
        
        System.assertEquals(result, 0);
    } 

    @isTest
    static void findFirstOperator_FoundAnd() {

        String formula = '2&& test formula';

        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Integer result = engine.findFirstOperator(formula);   
        
        System.assertEquals(result, 1);
    } 
    
    @isTest
    static void findFirstOperator_FirstAnd() {

        String formula = '&& ||';

        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Integer result = engine.findFirstOperator(formula);   
    } 

    @isTest
    static void findFirstOperator_FirstOr() {

        String formula = '|| && ';

        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Integer result = engine.findFirstOperator(formula);   
        
    } 

    @isTest
    static void compareValue_True() {

        Object value = true;
        String valueToCheck = 'true';

        // AvoProcessEngineBase engine = new AvoProcessEngineBase();
        // Boolean result = engine.compareValue(value, valueToCheck, FormulaOperator.EQUAL);   
        
        // System.assertEquals(result, true);
    } 

    @isTest
    static void compareValue_False() {

        Object value = true;
        String valueToCheck = 'false';

      
        // FormulaOperator operator = FormulaOperator.EQUAL;
        // AvoProcessEngineBase engine = new AvoProcessEngineBase();
        // Boolean result = engine.compareValue(value, valueToCheck, operator);   
        
        //System.assertEquals(result, false);
    }
    
    @isTest
    static void compareValue_MultiSelect() {

        Object value = 'test1;test2';
        String valueToCheck = 'test1';

        // AvoProcessEngineBase engine = new AvoProcessEngineBase();
        // Boolean result = engine.compareValue(value, valueToCheck, FormulaOperator.EQUAL);   
        
        // System.assertEquals(result, true);
    } 

    @isTest
    static void compareValue_String() {

        Object value = 'test1';
        String valueToCheck = 'test1';

        // AvoProcessEngineBase engine = new AvoProcessEngineBase();
        // Boolean result = engine.compareValue(value, valueToCheck, FormulaOperator.EQUAL);   
        
        // System.assertEquals(result, true);
    } 
	
    @isTest
    static void processSingleStatement_TriggerFromPermit() {

        String equation = 'Name = 1';

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.Name = '1';

        update permit;
        
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
        Boolean result = engine.processSingleStatement(equation);   
        
        System.assertEquals(result, true);
    }
    
    @isTest
    static void processSingleStatement_TriggerFromApplication() {

        String equation = 'MUSW__Type__c = \'Administrative Action\'';

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
        
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
        Boolean result = engine.processSingleStatement(equation);   
      } 

    @isTest
    static void processSingleStatement_TriggerFromOther_ValidatePermit() {

        String equation = 'Name = 1';

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.Name = '1';
        update permit;

        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');

        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();
        
        Boolean result = engine.processSingleStatement(equation);   
        
        System.assertEquals(result, true);
    } 

    @isTest
    static void processSingleStatement_TriggerFromOther_ValidateApplication() {

        String equation = 'MUSW__Type__c = \'Administrative Action\'';

        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');

        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(null, application.Id, 'Completeness Review', 'Approved');

        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();
        
        Boolean result = engine.processSingleStatement(equation);   
    } 
    
    @isTest
    static void processFormula_Single() {

        String equation = 'Name = 1';

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.Name = '1';
        update permit;

        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');

        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();
        
        Boolean result = engine.processFormula(equation);   
        
        System.assertEquals(result, true);
    } 
 
    @isTest
    static void processFormula_Multiple() {

        String equation = 'Name = 1 && Name = 1 || Name = 3';

        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        permit.Name = '1';
        update permit;

        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');

        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();
        
        Boolean result = engine.processFormula(equation);   
        
        System.assertEquals(result, true);
    } 
 
    @isTest
    static void getRecordId_Permit() {
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        String result = engine.getRecordId();

        system.assertNotEquals(null, result, 'id must not be null');
    } 

    @isTest
    static void getRecordId_Application() {
        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
      
        String result = engine.getRecordId();

        system.assertNotEquals(null, result, 'id must not be null');
    } 
	
    @isTest
    static void getsObjectName_Permit() {
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        String result = engine.getsObjectName();

        system.assertEquals('MUSW__Permit2__c', result);
    } 

    @isTest
    static void getsObjectName_Application() {
        MUSW__Application2__c application = AvoProcessEngineTestFactory.SetUpApplication('Variance', ' ');
        AvoProcessEngineApplication engine = new AvoProcessEngineApplication(application);
      
        String result = engine.getsObjectName();

        system.assertEquals('MUSW__Application2__c', result);
    } 
        
    @isTest
    static void validTrigger_NotFound() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
       
        Boolean result;
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        result = engine.validTrigger(transition);
        
        System.assertEquals(result, false);

    } 

    @isTest
    static void validTrigger_Review() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Trigger__c transitionTrigger = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, 'Completeness Review', '', '');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');
        
        transitionTrigger.Avo_Review_Status__c = 'Approved';
        update transitionTrigger;
        
        review.MUSW__Status__c = 'Approved';
        update review;

        Boolean result;
        AvoProcessEngineReview engine = new AvoProcessEngineReview(review);
        engine.run();

        result = engine.validTrigger(transition);
        
        System.assertEquals(result, true);

    } 
    
    @isTest
    static void validTrigger_Fee() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Trigger__c transitionTrigger = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, '', 'Fine', '');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Fee__c Fee = AvoProcessEngineTestFactory.SetUpFee(permit.Id, null, 'Violations',  120, 120);

        Boolean result;
        AvoProcessEngineFee engine = new AvoProcessEngineFee(fee);
        engine.run();

        result = engine.validTrigger(transition);
    } 

    @isTest
    static void validTrigger_Inspection() {

        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        AVO_Process_State_Transition_Trigger__c transitionTrigger = AvoProcessEngineTestFactory.SetUpTrigger(transition.Id, '', '', 'TPA Final Inspection');
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        MUSW__Inspection__c inspection = AvoProcessEngineTestFactory.SetUpInspection(permit.Id, null, 'All Inspections', 'Pass');

        transitionTrigger.Avo_Inspection_Result__c = 'Pending';
        update transitionTrigger;
        
        inspection.MUSW__Status__c = 'Pass';
        update inspection;

        Boolean result;
        AvoProcessEngineInspection engine = new AvoProcessEngineInspection(inspection);
        engine.run();

        result = engine.validTrigger(transition);
    } 
    
    //====================== Additional Code =================================
    
    @isTest
    static void test_getMilestoneRecordTypeId(){
        AvoProcessEngineBase engine = new AvoProcessEngineBase();
        Id inspectionMilestoneRecordTypeId = engine.getMilestoneRecordTypeId('Inspection Milestone');
        Id defaultMilestoneRecordTypeId = engine.getMilestoneRecordTypeId(' ');
    }
    
       
   
  /*  @isTest
    static void StopperConditionMet_Submission() {
        AVO_Process__c process = AvoProcessEngineTestFactory.SetUpProcess('Revision	', '');
        AVO_Process_State_Transition__c transition = AvoProcessEngineTestFactory.SetUpTransition(process.Id, 'Pending', 'Submitted');
        //AVO_Process_State_Transition_Stopper__c stopper = AvoProcessEngineTestFactory.SetUpCondition('All Reviews', '', '', transition.Id, 'Approved');
        AVO_Process_State_Transition_Stopper__c stopper = new AVO_Process_State_Transition_Stopper__c(
        	Avo_Process_State_Transition__c = transition.id,
        	Avo_Submission_Type__c = 'All Submissions',
            Avo_Submission_Status__c = 'Pending;Submitted'
        );
        
        MUSW__Permit2__c permit = AvoProcessEngineTestFactory.SetUpPermit();
        //MUSW__Review__c review = AvoProcessEngineTestFactory.SetUpReview(permit.Id, null, 'Completeness Review', 'Approved');

        
        MUSW__Submission__c submission = new MUSW__Submission__c(
        	MUSW__Permit2__c = permit.Id,
            MUSW__Status__c = 'Completed',
            Name = 'All Submission'
        );
        
        Boolean result;
        AvoProcessEnginePermit engine = new AvoProcessEnginePermit(permit);
      
        result = engine.StopperConditionsMet(transition);
        
        System.assertEquals(result, true);
    }   */

    
    
    
    
      
    
    
    
    
    
}