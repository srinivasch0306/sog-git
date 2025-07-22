/**
 * Description of class
 * a base process for the Avocette reusable engine
 * @author Jason Li
 * last modified by Yao Li
 * @date 07/19/2021
 *  
 */
public virtual class AvoProcessEngineBase {

    public class AvoProcessException extends Exception {}

    // objects in context
    protected AVO_Process__c process;

    protected MUSW__Permit2__c permit { get; set; }
    protected MUSW__Application2__c application { get; set; }

    protected MUSW__Review__c review;
    protected MUSW__Fee__c fee;
    protected MUSW__Inspection__c inspection;
    protected MUSW__Submission__c submission;
    protected MUSW__Deposit__c deposit;
    protected MUSW__Milestone__c milestone;
    protected Task task;
    protected Event event;   
    protected string results;
    protected string errorMessage = '';

    // the current attempted transition or transition will be trigger
    protected AVO_Process_State_Transition__c stateTransition{ private get; set; }   

    // all transition for the current process
    protected List<AVO_Process_State_Transition__c> processStateTransitions;

    public enum FormulaOperator {
        EQUAL,
        NOTEQUAL,
        INSIDE,
        GREATERTHAN,
        LESSTHAN
    }


    public enum TriggerFromObjectEnum {
        PERMIT,
        APPLICATION,
        REVIEW, 
        FEE, 
        DEPOSIT,
        INSPECTION, 
        SUBMISSION, 
        TASK,
        EVENT,
        MILESTONE
    }
    protected TriggerFromObjectEnum triggerFrom; 
    public enum ProcessTypeEnum {
        PERMIT,
        APPLICATION
    }            
    protected ProcessTypeEnum processType;    
    private string fromState;

    public Boolean StopperConditionsMet(AVO_Process_State_Transition__c processStateTransition)
    { 
        boolean conditionMet = true;

        List<AVO_Process_State_Transition_Stopper__c> stoppers = [
            SELECT ID,
            Avo_Fee_Type__c,
            Avo_Fee_Status__c,
            Avo_Inspection_Type__c,
            Avo_Inspection_Result__c,
            Avo_Review_Type__c,
            Avo_Review_Status__c,
            Avo_Milestone_Name__c,
            Avo_Milestone_Completed_Action__c,
            Avo_Submission_Type__c,
            Avo_Submission_Status__c,
            Avo_Deposit_Type__c,
            Avo_Deposit_Status__c            
        FROM AVO_Process_State_Transition_Stopper__c
        WHERE Avo_Process_State_Transition__c =: processStateTransition.ID];

        if (stoppers.size() ==0) {
            system.debug('0 stoppers found');
            return true;
        }
        else {
            system.debug(stoppers.size() + ' stoppers found');
            for(AVO_Process_State_Transition_Stopper__c stopper: stoppers) {
                if (conditionMet == false){
                    // if the last condition is unmet, there is no need to check further conditions
                    return false;
                }
                if (stopper.Avo_Review_Type__c !=null){
                    conditionMet =  checkReviewCondition(stopper.Avo_Review_Type__c,stopper.Avo_Review_Status__c);
                } else if (stopper.Avo_Fee_Type__c !=null){
                    conditionMet = checkFeeCondition(stopper.Avo_Fee_Type__c);
                } else if (stopper.Avo_Inspection_Type__c !=null){
                    conditionMet = checkInspectionCondition(stopper.Avo_Inspection_Type__c,stopper.Avo_Inspection_Result__c);
               // } else if (stopper.Avo_Milestone_Name__c != null) {
                    //conditionMet = checkMilestoneCondition(stopper.Avo_Milestone_Name__c,stopper.Avo_Milestone_Completed_Action__c);
                //} else if (stopper.Avo_Submission_Type__c != null) {
                 //   conditionMet = checkSubmissionCondition(stopper.Avo_Submission_Type__c,stopper.Avo_Submission_Status__c);
                //} else if (stopper.Avo_Deposit_Type__c != null) {
                  //  conditionMet = checkDepositCondition(stopper.Avo_Deposit_Type__c);
                }else {
                    throw new AvoProcessException('unsupported logic in StopperConditionsMet');
                }
            }
        }    
        
        System.debug('condition met result ' + conditionMet);
        return conditionMet;        
    }

  /*  private boolean  checkSubmissionCondition(string submissionType, string submissionStatuses){
        system.debug('assessing submission condition:' + submissionType + ' ' + submissionStatuses );
        List<String> submissionStatuList = submissionStatuses.split(';');
        List<MUSW__Submission__c> submissions;
        
        system.debug('Submission TEST ' + submissionType);
        
        if (permit != null) {
            if (submissionType  == 'All Submissions'){
                submissions = [SELECT 
                    ID, 
                    Name,
                    MUSW__Status__c
                    FROM MUSW__Submission__c
                    WHERE MUSW__Status__c not in :submissionStatuList AND
                    Name != 'Optional Documents – Project Plans/Drawings' AND
                    MUSW__Permit2__c = :permit.ID];  
            } else
            submissions = [SELECT 
                    ID, 
                    Name,
                    MUSW__Status__c 
                    FROM MUSW__Submission__c
                    WHERE Name = :submissionType AND
                    MUSW__Status__c not in :submissionStatuList AND
                    MUSW__Permit2__c = :permit.ID];  
        } else if (application != null) {
            if (submissionType  == 'All Submission'){
                submissions = [SELECT 
                ID, 
                Name,
                MUSW__Status__c 
                FROM MUSW__Submission__c
                WHERE MUSW__Status__c not in :submissionStatuList AND
                MUSW__Application2__c = :application.ID]; 
            }  else{
                submissions = [SELECT 
                    ID, 
                    Name,
                    MUSW__Status__c 
                    FROM MUSW__Submission__c
                    WHERE Name = :submissionType AND
                    MUSW__Status__c not in :submissionStatuList AND
                    MUSW__Application2__c = :application.ID]; 
            }              
        }
            
        if (submissions.size()>0 ) {
            string error = 'There are submissions not meeting the transition conditions. Submission Number:';
            system.debug(submissions);
            for(MUSW__Submission__c entity: submissions){
                error = error +  ' '+ entity.name;
            }
            System.debug('submissions not meeting conditions' + submissions);
            reportError(error);
            return false;
        } 
        return true;
    } */

    private boolean  checkReviewCondition(string reviewType, string reviewStatuses){
        system.debug('assessing review condition:' + reviewType + ' ' + reviewStatuses );
        List<String> reviewStatuList = reviewStatuses.split(';');
        List<MUSW__Review__c> reviews;
        
        if (permit != null) {
            if (reviewType  == 'All Reviews'){
                reviews = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c, 
                    MUSW__Status__c
                    FROM MUSW__Review__c
                    WHERE MUSW__Status__c not in :reviewStatuList AND
                    MUSW__Permit2__c = :permit.ID];  
            } else
                reviews = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c, 
                    MUSW__Status__c 
                    FROM MUSW__Review__c
                    WHERE MUSW__Type__c = :reviewType AND
                    MUSW__Status__c not in :reviewStatuList AND
                    MUSW__Permit2__c = :permit.ID];  
        } else if (application != null) {
            if (reviewType  == 'All Reviews'){
                reviews = [SELECT 
                ID, 
                Name,
                MUSW__Type__c, 
                MUSW__Status__c 
                FROM MUSW__Review__c
                WHERE MUSW__Status__c not in :reviewStatuList AND
                MUSW__Application2__c = :application.ID]; 
            }  else{
                reviews = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c, 
                    MUSW__Status__c 
                    FROM MUSW__Review__c
                    WHERE MUSW__Type__c = :reviewType AND
                    MUSW__Status__c not in :reviewStatuList AND
                    MUSW__Application2__c = :application.ID]; 
            }              
        }
            
        if (reviews.size()>0 ) {
            string error = 'There are reviews not meeting the transition conditions. Review Number:';
            system.debug(reviews);
            for(MUSW__Review__c review: reviews){
                error = error +  ' '+ review.name;
            }
            System.debug('reviews not meeting conditions' + reviews);
            reportError(error);
            return false;
        } 
        return true;
    }

  /*  private boolean  checkMilestoneCondition(string milestoneName, string completedAction){
        system.debug('assessing milestone condition:' + milestoneName + ' ' + completedAction);
        List<String> actions = new List<String>();
        actions.add(completedAction);
        List<MUSW__Milestone__c> milestones;
        
        if (permit != null) {
            if (milestoneName  == 'All Milestones'){
                milestones = [SELECT 
                    ID, 
                    Name,
                    MUSW__Completed_Action__c
                    FROM MUSW__Milestone__c
                    WHERE MUSW__Completed_Action__c not in :actions AND
                    MUSW__Permit2__c = :permit.ID];  
            } else
                milestones = [SELECT 
                    ID, 
                    Name,
                    MUSW__Completed_Action__c
                    FROM MUSW__Milestone__c
                    WHERE Name = :milestoneName AND
                    MUSW__Completed_Action__c not in :actions AND
                    MUSW__Permit2__c = :permit.ID];  
        } else if (application != null) {
            system.debug('Application Id ' + application.id);
            if (milestoneName  == 'All Milestones'){
                milestones = [SELECT 
                ID, 
                Name,
                MUSW__Completed_Action__c
                FROM MUSW__Milestone__c
                WHERE MUSW__Completed_Action__c not in :actions AND
                MUSW__Application2__c = :application.ID]; 
            }  else{
                milestones = [SELECT 
                ID, 
                Name,
                MUSW__Completed_Action__c
                FROM MUSW__Milestone__c
                WHERE Name = :milestoneName AND
                MUSW__Completed_Action__c not in :actions AND
                MUSW__Application2__c = :application.ID]; 
            }              
        }
            
        if (milestones.size()>0 ) {
            string error = 'There are milestones not meeting the transition conditions. Milestone:';
            system.debug(milestones);
            for(MUSW__Milestone__c milestone: milestones){
                error = error +  ' '+ milestone.name;
            }
            System.debug('milestones not meeting conditions' + milestones);
            reportError(error);
            return false;
        } 
        return true;
    } */

    private boolean  checkFeeCondition(string feeType){
        system.debug('assessing fee condition:' + feeType + ' must be fully paid.' );
        List<MUSW__Fee__c> fees;
        

        if (permit != null) {
            if (feeType  == 'All Fees'){
                fees = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c
                    FROM MUSW__Fee__c
                    WHERE MUSW__Outstanding_Fee__c != 0 AND
                    MUSW__Permit2__c = :permit.ID];  
            }else{
                fees = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c
                    FROM MUSW__Fee__c
                    WHERE MUSW__Type__c = :feeType AND
                    MUSW__Outstanding_Fee__c != 0 AND
                    MUSW__Permit2__c = :permit.ID];
            }

        } else if (application != null) {
            if (feeType  == 'All Fees'){
                fees = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c
                    FROM MUSW__Fee__c
                    WHERE MUSW__Outstanding_Fee__c != 0 AND
                    MUSW__Application2__c = :application.ID];  
            }else{
                fees = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c
                    FROM MUSW__Fee__c
                    WHERE MUSW__Type__c = :feeType AND
                    MUSW__Outstanding_Fee__c != 0 AND
                    MUSW__Application2__c = :application.ID];
            }
        }
            
        
        if (fees.size()>0 ) {
            string error ='There are fees not meeting the transition conditions. Fee ID:';
            for(MUSW__Fee__c fee: fees){
                error = error +  ' ' + fee.name;
            }
            System.debug('fees not meeting conditions' + fees);
            system.debug('report error:'  + error);
            system.debug(error);

            reportError(error);
            return false;
        } 
        return true;
    }

  /*  private boolean  checkDepositCondition(string depositType){
        system.debug('assessing deposit condition:' + depositType + ' must be fully paid.' );
        List<MUSW__Deposit__c> deposits;
        

        if (permit != null) {
            if (depositType  == 'All Desposits'){
                deposits = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c
                    FROM MUSW__Deposit__c
                    WHERE MUSW__Unpaid_Amount__c != 0 AND
                    MUSW__Permit2__c = :permit.ID];  
            }else{
                deposits = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c
                    FROM MUSW__Deposit__c
                    WHERE MUSW__Type__c = :depositType AND
                    MUSW__Unpaid_Amount__c != 0 AND
                    MUSW__Permit2__c = :permit.ID];
            }

        } 
            
        
        if (deposits.size()>0 ) {
            string error ='There are deposits not meeting the transition conditions. Deposit ID:';
            for(MUSW__Deposit__c deposit: deposits){
                error = error +  ' ' + deposit.name;
            }
            System.debug('deposits not meeting conditions' + deposits);
            system.debug('report error:'  + error);
            system.debug(error);

            reportError(error);
            return false;
        } 
        return true;
    }   */ 
    
    private boolean  checkInspectionCondition(string inspecitonType, string inspectionResults){
        system.debug('assessing inspection condition:' + inspecitonType + ' ' + inspectionResults );
        List<String> inspectionResultList = inspectionResults.split(';');
        List<MUSW__Inspection__c> inspections;
        
        if (permit != null) {
            if (inspecitonType  == 'All Inspections'){
                inspections = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c, 
                    MUSW__Status__c 
                    FROM MUSW__Inspection__c
                    WHERE MUSW__Status__c not in :inspectionResultList AND
                    MUSW__Permit__c = :permit.ID];  
            }else
            inspections = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c, 
                    MUSW__Status__c 
                    FROM MUSW__Inspection__c
                    WHERE MUSW__Type__c = :inspecitonType AND
                    MUSW__Status__c not in :inspectionResultList AND
                    MUSW__Permit__c = :permit.ID]; 
        } else if (application != null) {
            if (inspecitonType  == 'All Inspections'){
                inspections = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c, 
                    MUSW__Status__c 
                    FROM MUSW__Inspection__c
                    WHERE MUSW__Status__c not in :inspectionResultList AND
                    Avo_Application__c = :application.ID]; 
            }
            else{
                inspections = [SELECT 
                    ID, 
                    Name,
                    MUSW__Type__c, 
                    MUSW__Status__c 
                    FROM MUSW__Inspection__c
                    WHERE MUSW__Type__c = :inspecitonType AND
                    MUSW__Status__c not in :inspectionResultList AND
                    Avo_Application__c = :application.ID]; 
            }          
        }
            
        if (inspections.size()>0 ) {
            string error = 'There are inspections not meeting the transition conditions. Inspection Number:';
            system.debug(inspections);
            for(MUSW__Inspection__c inspection: inspections){
                error = error +  ' '+ inspection.name;
            }
            System.debug('inspections not meeting conditions' + inspections);
            reportError(error);
            return false;
        } 
        return true;
    }

    protected void initialize(){

        // local variables required to find the matching active process 
        
        List<AVO_Process__c> processes;
        ID permitID;
        ID applicationID;
		ID inspectionID;
        System.debug('triggerFrom:' + triggerFrom);
        system.debug('fee' + fee);

        // prepare the objects in context 
        switch on triggerFrom{
            when PERMIT {
                permitID = permit.ID;
            }
            when APPLICATION {
                applicationId = application.ID;                
            }
            when REVIEW{
                permitID = review.MUSW__Permit2__c;
                applicationId = review.MUSW__Application2__c;
                inspectionId = review.AVO_Inspection__c;
            }
            when FEE{
                permitID = fee.MUSW__Permit2__c;
                applicationId = fee.MUSW__Application2__c;
            }
            when INSPECTION{
                permitID = inspection.MUSW__Permit__c;
                applicationId = inspection.Avo_Application__c;
                inspectionId = inspection.Id;
            }
            when SUBMISSION{
                permitID = submission.MUSW__Permit2__c;
                applicationId = submission.MUSW__Application2__c;       
            }
          /*  when DEPOSIT{
                permitID = deposit.MUSW__Permit2__c;      
            }     */       
          /*  when EVENT{

                List<Event> eventInstance = [
                    SELECT ID, what.type, what.id
                    FROM Event
                    WHERE ID =:event.Id];

                if (eventInstance.size() > 0) {

                    if (eventInstance[0].what.type == 'MUSW__Application2__c') {
                        applicationId = event.WhatId;   
                    }

                    if (eventInstance[0].what.type == 'MUSW__Permit2__c') {
                        permitID = event.WhatId; 
                    }
                }     
            } */
          /*  when TASK{

                List<Task> taskInstance = [
                    SELECT ID, what.type, what.id
                    FROM Task
                    WHERE ID =:task.Id];

                if (taskInstance.size() > 0) {

                    if (taskInstance[0].what.type == 'MUSW__Application2__c') {
                        applicationId = task.WhatId;  
                    }

                    if (taskInstance[0].what.type == 'MUSW__Permit2__c') {
                        permitID = task.WhatId;  
                    }
                }
            } */
          /*  when MILESTONE {
                permitID = milestone.MUSW__Permit2__c;
                applicationId = milestone.MUSW__Application2__c;  
            } */
            when else {
                throw new AvoProcessException('unsupported logic in initialize');
            }
        }
        
        if (permitID != null){
            if (triggerFrom != TriggerFromObjectEnum.PERMIT){
                permit = [
                    SELECT ID,
                        MUSW__Type__c,
                        MUSW__Status__c,
                        MUSW__Applicant__c,
                        Avo_Residential_Contact__c,
                        Name
                    FROM MUSW__Permit2__c
                    WHERE ID =:permitID];
                
            }
            fromState = permit.MUSW__Status__c;
            processType = ProcessTypeEnum.PERMIT;
            processes = [
                SELECT ID
                FROM Avo_Process__c
                WHERE Avo_Active__c = TRUE AND 
                    Avo_Permit_Type__c = :permit.MUSW__Type__c
                ORDER BY LastModifiedDate DESC];
        } else if (applicationId != null){
            if (triggerFrom != TriggerFromObjectEnum.APPLICATION){
                application = [
                    SELECT ID,
                           MUSW__Type__c,
                           MUSW__Status__c,
                        MUSW__Applicant__c,
                        Name
                    FROM MUSW__Application2__c
                    WHERE ID =: applicationId ];
            }
            fromState = application.MUSW__Status__c;
            processType = ProcessTypeEnum.APPLICATION;
            processes = [
                SELECT ID
                FROM Avo_Process__c
                WHERE Avo_Active__c = TRUE AND 
                    Avo_Planning_Application_Type__c = :application.MUSW__Type__c
                ORDER BY LastModifiedDate DESC];
        } else if (inspectionId != null) {

            processes = new List<Avo_Process__c>();
        } 
        else {
            processes = new List<Avo_Process__c>();
            //throw new AvoProcessException('unsupported logic in initialize');
        }
            
        If (processes.size() == 0){
            // exit this function call if there is no process defined
            System.debug('No active process found');                
            process = null;
            processStateTransitions = null;
        }else {
            // if there are multiple processes returned, get the one with the most recent last modified date
            process = processes[0];            
            System.debug('process' + process);
            // step #2 - find if there are matching possible auto process state transitions which may be triggered by review status changes
            processStateTransitions = [
                SELECT ID,
                    Avo_From_State__c, 
                    Avo_To_State__c
                FROM AVO_Process_State_Transition__c 
                WHERE Avo_Process__c = :process.Id] ;     
        }
        
        
    }

    // determine if an active process exists 
    // before calling this function, initialize() should be called
    protected Boolean processFound(){
        If (processStateTransitions == null || processStateTransitions.size() == 0){
            // No auto process state transitions found
            System.debug('There is no active process with state transitions defined for the current object');
            return false;
        } else {     
            return true;      
        }
    }
    public void createPostActions(AVO_Process_State_Transition__c processStateTransition){
        List<AVO_Process_State_Post_Actions__c> actions = [
            SELECT Id,
                Avo_Event_Type__c,
                Avo_Task_Type__c,
                Avo_Review_Type__c,
                Avo_Fee_Type__c,
                Avo_Inspection_Type__c,
                Avo_Submission_Type__c,
                Avo_Process_State_Transition__c,
                Avo_Date_Field__c,
                Avo_Offset__c,
                Avo_Formula_Condition__c,
                Avo_Email_Template__c,
                Avo_Fee_Quantity__c,
                Avo_Check_Duplicate__c,
                Avo_Field_to_Update__c,
                Avo_Update_Field_Type__c,
                Avo_Field_Value__c,
                Avo_Queue_Assignment__c,
                Avo_Is_Required__c,
                Milestone_Type__c
            FROM AVO_Process_State_Post_Actions__c 
            WHERE Avo_Active__c = true AND
                Avo_Process_State_Transition__c =:processStateTransition.ID];
        system.debug('post transiton actions:' + actions.size());
        system.debug(actions);

        Boolean shouldBatchCreate = false;
        List<String> reviewActions = new List<String>();
        List<AVO_Process_State_Post_Actions__c> feeActions = new List<AVO_Process_State_Post_Actions__c>();
        List<String> milestoneActions = new List<String>();
        List<String> inspectionTypes = new List<String>();

        for(AVO_Process_State_Post_Actions__c action:actions){
            if (action.Avo_Event_Type__c !=null) {
                if (checkFormulaCondition(action.Avo_Formula_Condition__c)) {
                    createEvent(action);
                }
            }
            else if (action.Avo_Task_Type__c !=null) {
                if (checkFormulaCondition(action.Avo_Formula_Condition__c)) {
                    createTask(action);
                }
            }
            else if (action.Avo_Review_Type__c !=null) {
                if (checkFormulaCondition(action.Avo_Formula_Condition__c)) {
                    //createReview(action.Avo_Review_Type__c);
                    reviewActions.add(action.Avo_Review_Type__c);
                }              
            }
            /*else if (action.Milestone_Type__c !=null) {
                if (checkFormulaCondition(action.Avo_Formula_Condition__c)) {
                    //createReview(action.Avo_Review_Type__c);
                    milestoneActions.add(action.Milestone_Type__c);
                }              
            } */
            else if (action.Avo_Fee_Type__c !=null) {
                if (checkFormulaCondition(action.Avo_Formula_Condition__c))  {
                    //createFee(action);
                    feeActions.add(action);
                }
            }
            else if (action.Avo_Inspection_Type__c !=null) {
                if (checkFormulaCondition(action.Avo_Formula_Condition__c))  {
                    inspectionTypes.add(action.Avo_Inspection_Type__c);
                } 
            }
            else if (action.Avo_Submission_Type__c !=null) {
                if (checkFormulaCondition(action.Avo_Formula_Condition__c))  {
                    createSubmission(action);
                } 
            //} else if (action.Avo_Email_Template__c != null) {
               // sendEmail(action.Avo_Email_Template__c);
            }
           // } else if (action.Avo_Update_Field_Type__c != null) {
               // updateInstance(action);
            
            else throw new AvoProcessException('unsupported logic in createPostActions');
        }

        if (reviewActions.size() > 0) {
            createReview(reviewActions);
        }

        if (feeActions.size() > 0) {
            createFee(feeActions);
        }

       /* if (milestoneActions.size() > 0) {
            createMilestones(milestoneActions);
        } */

        if (inspectionTypes.size() > 0) {
            createInspections(inspectionTypes);
        }
    }

    public Datetime toGMTDateTime(Date inputDate) {
        TimeZone tz = UserInfo.getTimeZone();
        System.debug('Display name: ' + tz.getDisplayName());
        System.debug('ID: ' + tz.getID());

        Integer offset = tz.getOffset(DateTime.newInstance(inputDate.year(), inputDate.month(), inputDate.day(), 0,0,0));
        Datetime result = Datetime.newInstanceGMT(inputDate.year(), inputDate.month(), inputDate.day(), 9, 0, 0);
        result = result.addSeconds(offset / 1000 * -1);

        return result;
    }


    public void createEvent(AVO_Process_State_Post_Actions__c eventDetails){
        Event event = new Event();
        Date activityDate ;        
        system.debug('eventDetails.Avo_Date_Field__c:' + eventDetails.Avo_Date_Field__c );
      
        if (string.isblank(eventDetails.Avo_Date_Field__c) == false){            
            try {
                if (application != null) {
                    activityDate = (Date) application.get(eventDetails.Avo_Date_Field__c); 
                }
               
                if (eventDetails.Avo_Offset__c != null) {
                    activityDate = AddBusinessDays(activityDate, (Integer)eventDetails.Avo_Offset__c);
                }
            }
            catch (Exception e) {
                system.debug('calculation of activity data has failed');
                activityDate = null;           
            }

            if (activityDate != null) {
                Datetime dueDate = toGMTDateTime(activityDate);

                System.debug('due date:' + dueDate);
                System.debug('activity ' + date.newInstance(dueDate.year(), dueDate.month(), dueDate.day() + 1));
    
                event.WhatId  = application.ID; 
                event.Subject = eventDetails.Avo_Event_Type__c;
                event.DurationInMinutes = 30;
                event.activityDate = date.newInstance(dueDate.year(), dueDate.month(), dueDate.day());
                event.ActivityDateTime = dueDate;
               // event.RecordTypeId =  getEventRecordTypeId(eventDetails.Avo_Event_Type__c,application.MUSW__Type__c);
                
                Insert event;
            }
          
        }
       
    }   

  /*  public ID getEventRecordTypeId(string evenTypeName, string planningApplicationType)
    {
        List<Master_Event_List__c> events= [
            SELECT Record_Type__c 
            FROM Master_Event_List__c 
            WHERE Name =:evenTypeName   //'30 Day Planning Commission Meeting' 
            AND Avo_Planning_Application_Type__c includes (:planningApplicationType) ] ; //  'Planned Development Application'

        If (events.size() == 1 && !String.isblank(events[0].Record_Type__c) && events[0].Record_Type__c != 'None') {

            System.Debug('event type: ' + events[0].Record_Type__c);
            Id recordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get(events[0].Record_Type__c).getRecordTypeId();
            
            System.Debug('event type Id: ' + recordTypeId);
            
            return recordTypeId;    
        } else return Schema.SObjectType.Event.getRecordTypeInfosByName().get('Default').getRecordTypeId();
    } */

    public ID getMilestoneRecordTypeId(string milestoneType)
    {
        try {
            Id recordTypeId = Schema.SObjectType.MUSW__Milestone__c.getRecordTypeInfosByName().get(milestoneType).getRecordTypeId();
        
            return recordTypeId;  
        } catch (Exception ex) {
            return Schema.SObjectType.MUSW__Milestone__c.getRecordTypeInfosByName().get('Admin Review Milestone').getRecordTypeId();
        }
      
    }

    public void createTask(AVO_Process_State_Post_Actions__c taskDetails){
       
        Task task = new Task();
        Date activityDate;        
        system.debug('taskDetails.Avo_Date_Field__c:' + taskDetails.Avo_Date_Field__c );
        if (string.isblank(taskDetails.Avo_Date_Field__c) == false){            
            try {
                switch on triggerFrom{
                    when PERMIT{
                        activityDate = (Date) permit.get(taskDetails.Avo_Date_Field__c);                    
                    }
                    when APPLICATION{
                        activityDate = (Date) application.get(taskDetails.Avo_Date_Field__c); 
                    }
                }
                if (taskDetails.Avo_Offset__c != null) {
                    activityDate = AddBusinessDays(activityDate, (Integer)taskDetails.Avo_Offset__c);
                }
            }
            catch (Exception e) {
                system.debug('calculation of activity data has failed');
                activityDate = null;           
            }
        }

        switch on triggerFrom{
            when PERMIT{
                task.WhatId  = permit.ID;                      
            }
            when APPLICATION{
                task.WhatId  = application.ID; 
            }
        }
        task.Subject = taskDetails.Avo_Task_Type__c;
        if (activityDate == null) {
            activityDate = AddBusinessDays(Date.today(), 1);
        }

        List<Master_Task_List__c> masterTask = [SELECT ID, Name, Owner_Queue_User__c
         from Master_Task_List__c
        where Name = :taskDetails.Avo_Task_Type__c];

        if (masterTask.size() > 0) {
            String queueName = masterTask[0].Owner_Queue_User__c;
            if (queueName != null) {
                List<Group> queues = [select Id, Name from Group where Type = 'Queue' and Name =:queueName];
    
                if (queues.size() > 0) {
                    
                            task.OwnerId = queues[0].Id;
                      
                }
            }
        }
        

        Datetime dueDate = toGMTDateTime(activityDate);

        task.activityDate = activityDate;
        Insert task;       
        System.debug('inserted task ' + task);
    }   

   /* public void createMilestones(List<String> milestones){
       
        MUSW__Milestone__c milestone = new MUSW__Milestone__c();
        
        List<MUSW__Milestone_Template__c> templates;
        switch on triggerFrom{
            when PERMIT{
                templates = [
                    SELECT Id, 
                        Active__c, 
                        Name, 
                        MUSW__Milestone_Name__c,
                        MUSW__Due_in_Days__c,
                        MUSW__Milestone_Record_Type__c
                    FROM MUSW__Milestone_Template__c
                    WHERE Name =:milestones AND 
                    Active__c = true AND Avo_Permit_Type__c includes (:permit.MUSW__Type__c)];
            }
            when APPLICATION{
                templates = [
                    SELECT Id, 
                        Active__c, 
                        Name, 
                        MUSW__Milestone_Name__c,
                        MUSW__Due_in_Days__c,
                        MUSW__Milestone_Record_Type__c
                    FROM MUSW__Milestone_Template__c
                    WHERE Name =:milestones AND 
                    Active__c = true AND  Avo_Planning_Application_Type__c 
                    includes (:application.MUSW__Type__c)];
            }
        }
        
        List<MUSW__Milestone__c> itemsToAdd = new List<MUSW__Milestone__c>();
        if (templates.size() > 0) {
            
            for(MUSW__Milestone_Template__c item : templates) {
                MUSW__Milestone__c entityToAdd = new MUSW__Milestone__c(
                    Name = item.MUSW__Milestone_Name__c,
                    RecordTypeId = getMilestoneRecordTypeId(item.MUSW__Milestone_Record_Type__c)
                );

                switch on triggerFrom{
                    when PERMIT{
                        entityToAdd.MUSW__Permit2__c = permit.id;
                    }
                    when APPLICATION{
                        entityToAdd.MUSW__Application2__c = application.id;
                    }
                }

                Integer dueInDays = 0;
                if (item.MUSW__Due_in_Days__c != null) {
                    dueInDays = Integer.valueOf(item.MUSW__Due_in_Days__c);
                }
              
                entityToAdd.MUSW__Due_Date__c =  AddBusinessDays(Date.today(), dueInDays);

                itemsToAdd.add(entityToAdd);
            }
            
        } else {
            reportError('review creation faild.' + milestones);
        }

        Insert itemsToAdd;        
    } */

    public void createReview(List<String> reviewTypes){ 
        List<Master_Review_List__c> reviews;
        switch on triggerFrom{
            when PERMIT{
                reviews = [
                    SELECT Id, 
                        Active__c, 
                        Name, 
                        Avo_Review_Type__c
                    FROM Master_Review_List__c
                    WHERE Name =:reviewTypes AND 
                    Active__c = true];
            }
            when APPLICATION{
                reviews = [
                    SELECT Id, 
                        Active__c, 
                        Name, 
                        Avo_Review_Type__c
                    FROM Master_Review_List__c
                    WHERE Name =:reviewTypes AND 
                    Active__c = true AND Avo_Planning_Application_Type__c 
                    includes (:application.MUSW__Type__c)];
            }
        }
        System.debug('Trigger From; ' + triggerFrom);
        system.debug('creating review ' + reviewTypes);
        
        List<String> idsToCreate = new List<String>();
        if (reviews.size() > 0) {
            
            for(Master_Review_List__c selectedReview : reviews) {
                idsToCreate.add(selectedReview.id);
            }
            System.Debug(idsToCreate);
            AvoReviewDataRetrieverController.createReviews(getRecordId(), idsToCreate, getsObjectName());
        } else {
            reportError('review creation faild.' + reviewTypes);
        }

    }   
    public void createFee(List<AVO_Process_State_Post_Actions__c> feeDetails){

        List<String> feeTypes = new List<String>();
        List<String> feeTypesToCheckDuplicates = new List<String>();

        for(AVO_Process_State_Post_Actions__c feeAction : feeDetails) {
            feeTypes.add(feeAction.Avo_Fee_Type__c);
            if (feeAction.Avo_Check_Duplicate__c) {
                feeTypesToCheckDuplicates.add(feeAction.Avo_Fee_Type__c);
            }
        }
      
        List<MUSW__Master_Fee_List__c> fees;
        List<MUSW__Fee__c> existingFees;
        List <MUSW__Work_Item__c> relatedWorkItems;
        switch on triggerFrom{
            when PERMIT{
                fees = [
                    SELECT Id, 
                        Active__c, 
                        Name, 
                        Avo_Permit_Type__c,
                        Fee_Calculation_Type__c,
                        Related_Work_Item__r.Name
                    FROM MUSW__Master_Fee_List__c
                    WHERE Name =:feeTypes AND 
                    Active__c = true AND Avo_Permit_Type__c includes (:permit.MUSW__Type__c) 
                    Order by ID];
                
                existingFees = [
                    SELECT Id, Name, MUSW__Type__c
                    FROM MUSW__Fee__c
                    WHERE MUSW__Permit2__c = :permit.id AND 
                    MUSW__Type__c in :feeTypesToCheckDuplicates
                ];

                relatedWorkItems = [
                    SELECT Id, MUSW__Description__c, MUSW__Quantity__c
                    FROM MUSW__Work_Item__c
                    WHERE MUSW__Permit2__c = :permit.id
                ];
            }
            when APPLICATION{
                fees = [
                    SELECT Id, 
                        Active__c, 
                        Name, 
                        Avo_Planning_Application_Type__c,
                        Fee_Calculation_Type__c,
                        Related_Work_Item__r.Name
                    FROM MUSW__Master_Fee_List__c
                    WHERE Name =:feeTypes AND 
                    Active__c = true AND Avo_Planning_Application_Type__c 
                    includes (:application.MUSW__Type__c)]
                   ;
                
                existingFees = [
                    SELECT Id, Name, MUSW__Type__c
                    FROM MUSW__Fee__c
                    WHERE MUSW__Application2__c = :application.id AND 
                    MUSW__Type__c in :feeTypesToCheckDuplicates
                ];
            }
        }

        system.debug('creating fee ' + feeTypes);

        if (fees.size() > 0) {

            List<Integer> quantities = new List<Integer>();
            List<String> idsToCreate = new List<String>();
            for(MUSW__Master_Fee_List__c fee : fees) {

                boolean feeExists = false;
                for(MUSW__Fee__c existingFee : existingFees) {
                    if (existingFee.MUSW__Type__c == fee.Name)
                    {
                        feeExists = true;
                        break;
                    }
                }

                if (feeExists)
                {
                    continue;
                }
              
               for (AVO_Process_State_Post_Actions__c feeAction : feeDetails) {
                    if (feeAction.Avo_Fee_Type__c == fee.Name)
                    {
                        if (feeAction.Avo_Fee_Quantity__c!=null)
                        {
                            if (feeAction.Avo_Fee_Quantity__c.isNumeric()) {
                                quantities.add(Integer.valueof(feeAction.Avo_Fee_Quantity__c));
                            }else{
                                if (permit.get(feeAction.Avo_Fee_Quantity__c) != null)
                                {
                                    quantities.add(Integer.valueof(permit.get(feeAction.Avo_Fee_Quantity__c)));
                                }else{
                                    quantities.add(0);
                                }
                            }
                        }else{
                            quantities.add(1);
                        }
                    }
               }
               idsToCreate.add(fee.id);
            }
            AvoFeeDataRetrieverController.createMultipleFees(quantities,  getRecordId(), idsToCreate, getsObjectName());
        } else {
            reportError('fee creation faild.' + feeTypes);
        }
    }   
    public Boolean hasError(){
        if (errorMessage != '') return true;
        else return false;
    }
    public string getError(){
        return errorMessage;
    }

    public void createInspections(List<string> inspectionTypes){
        List<MUSW__Master_Inspection_List__c> inspections;
        switch on triggerFrom{
            when PERMIT{
                inspections = [
                    SELECT Id, 
                       // Active__c, todo
                        Name, 
                        Avo_Inspection_Type__c
                    FROM MUSW__Master_Inspection_List__c
                    WHERE Name =:inspectionTypes 
                    //AND                     Active__c = true  todo
                    AND Avo_Permit_Type__c includes (:permit.MUSW__Type__c)];
            }
            when APPLICATION{
                inspections = [
                    SELECT Id, 
                      //  Active__c, todo
                        Name, 
                        Avo_Inspection_Type__c
                    FROM MUSW__Master_Inspection_List__c
                    WHERE Name =:inspectionTypes 
                    //AND 
                    //Active__c = true  todo
                    AND Avo_Planning_Application_Type__c 
                    includes (:application.MUSW__Type__c)];
            }
        }
       
        if (inspections.size() > 0){
           
            List<String> idsToCreate = new List<String>();
            for(MUSW__Master_Inspection_List__c item: inspections) {
                idsToCreate.add(item.id);
            }
            AvoInspectionDataRetrieverController.createInspections(getRecordId(), idsToCreate, getsObjectName());
        }

       
    }   
    public void createSubmission(AVO_Process_State_Post_Actions__c submissionDetails){
        
        string submissionType =  submissionDetails.Avo_Submission_Type__c;
        List<MUSW__Master_Submission_List__c> submissions;
        boolean hasExistingSubmission = false;    

        switch on triggerFrom{
            when PERMIT{
                submissions = [
                    SELECT Id, 
                        Active__c, 
                        Name, 
                        Avo_Submission_Type__c
                    FROM MUSW__Master_Submission_List__c
                    WHERE Name =:submissionType AND 
                    Active__c = true AND Avo_Permit_Type__c includes (:permit.MUSW__Type__c)];
               
                List<MUSW__Submission__c> existingSubmissions = [
                    SELECT Id, Name 
                    FROM MUSW__Submission__c
                    WHERE Type__c = :submissionType
                    AND MUSW__Permit2__c = :permit.id
                ];

                if (existingSubmissions.size() > 0) {
                    hasExistingSubmission = true;
                }
            }
            when APPLICATION{
                submissions = [
                    SELECT Id, 
                        Active__c, 
                        Name, 
                        Avo_Submission_Type__c
                    FROM MUSW__Master_Submission_List__c
                    WHERE Name =:submissionType AND 
                    Active__c = true AND Avo_Planning_Application_Type__c 
                    includes (:application.MUSW__Type__c)];

                List<MUSW__Submission__c> existingSubmissions = [
                    SELECT Id, Name 
                    FROM MUSW__Submission__c
                    WHERE Type__c = :submissionType
                    AND MUSW__Application2__c = :application.id
                ];

                System.debug('existing submissions: ' + existingSubmissions.size());

                if (existingSubmissions.size() > 0) {
                    hasExistingSubmission = true;
                }
            }
        }
        system.debug('creating submission ' + submissionType);
        if (submissions.size() != 1){
            reportError('submission creation faild.' + submissionType);
        } else {           
            Map<String, boolean> idConfig = new Map<String, boolean>();
            idConfig.put(submissions[0].id, submissionDetails.Avo_Is_Required__c);

            if (!submissionDetails.Avo_Check_Duplicate__c 
            || (submissionDetails.Avo_Check_Duplicate__c && !hasExistingSubmission)) {
                AvoSubmissionDataRetrieverController.createSubmissionsWithConfig(getRecordId(), idConfig, getsObjectName());
            }
        }
    }   

    public string getRecordId(){
        switch on triggerFrom{
            when PERMIT{
                return permit.ID;
            }
            when APPLICATION{
                return application.Id;
            }
        }
        return '';
    }

    public string getsObjectName(){
        switch on triggerFrom{
            when PERMIT{
                return 'MUSW__Permit2__c';
            }
            when APPLICATION{
                return 'MUSW__Application2__c';
            } 
        }
        return '';
    }

    private void reportError(string additionalError){
        errorMessage = errorMessage + additionalError;
    }

    // this is the entry point of the Process Engine
    // this method will try to transition the Review or Application in context from its current state to a future state
    
    public boolean isSupportedByEngine() {
        boolean isSupported = true;

        if (triggerFrom == TriggerFromObjectEnum.inspection && (
             inspection.MUSW__Complaint2__c != null ||  inspection.Avo_Violation__c != null) ) {
            isSupported = false;        
        }

        return isSupported;
    }


    public void run(){
        // if there are multiple possible transitions, this method will try to complete the first transition 
        boolean autoTransitionFinished  = false;
        // setup all required objects and variables

        if (isSupportedByEngine()) {
            initialize();
            system.debug('running');
            if (processFound() == true){
                // continue the rest only if there is an active and valid process 
                For(AVO_Process_State_Transition__c processStateTransition: processStateTransitions) {
                    // the system checks the "from state" trying to locate a match
                    if (autoTransitionFinished == false  &&  processStateTransition.Avo_From_State__c == fromState) {
                        // try to complete the state transtion for the next match if the current doesn't complete
                        autoTransitionFinished = tryToAutoStateTransiton(processStateTransition);
                    }
                }
            }     
        }
         
    }

    private boolean tryToAutoStateTransiton(AVO_Process_State_Transition__c processStateTransition){
        System.Debug('Auto transit');
        if (validTrigger(processStateTransition) ==true){
            switch on triggerFrom{
                when PERMIT, APPLICATION {
                    reportError('unsupported logic in AvoProcessEngineBase.tryToCompleteStateTransiton()');
                }
                when REVIEW, FEE, INSPECTION, SUBMISSION, EVENT, MILESTONE{
                    switch on processType {
                        when PERMIT {
                            permit.MUSW__Status__c = processStateTransition.Avo_To_State__c;
                            system.debug('trigger piont is matched and trying to transition permit to ' + processStateTransition.Avo_To_State__c);
                            update permit;                            
                            return true;
                        }
                        when APPLICATION{
                            application.MUSW__Status__c = processStateTransition.Avo_To_State__c;
                            update application;                            
                            return true;
                        }
                        when else {
                            reportError('unsupported logic in AvoProcessEngineBase.tryToCompleteStateTransiton()');
                        }
                    }
                }
            }   
        }
        return false;
    }    
    // check all triggers for the passed in transition 
    // determine if the current trigger is one of the allowed triggers
    public boolean validTrigger(AVO_Process_State_Transition__c processStateTransition) {
        
        boolean isValid = false;
        //  get all conditions (either reviews or fees)
        List<AVO_Process_State_Transition_Trigger__c>  transitionTriggers =
            [SELECT 
                Avo_Fee_Type__c,
                Avo_Review_Type__c,
                Avo_Review_Status__c, 
                Avo_Inspection_Type__c,
                Avo_Inspection_Result__c, 
                Avo_Formula_Condition__c,
                Avo_Milestone_Name__c,
                Avo_Milestone_Completed_Action__c,
                Avo_Submission_Status__c,
                Avo_Submission_Type__c,
                Avo_Deposit_Type__c,             
                RecordType.Name 
            FROM AVO_Process_State_Transition_Trigger__c
            WHERE AVO_Process_State_Transition__c= :processStateTransition.ID];
        if (transitionTriggers.size() ==0) {
            system.debug('0 trigger found');
            return false;
        }
        else {
            system.debug(transitionTriggers.size() + ' triggers found');
            //system.debug(transitionTriggers);
            for (AVO_Process_State_Transition_Trigger__c transitionTrigger: transitionTriggers ){
                //system.debug('transitionTrigger:' + transitionTrigger);
                System.Debug('Trigger Id ' + transitionTrigger.Id);
                System.debug('Review ' + transitionTrigger.Avo_Review_Type__c);
                System.debug('Trigger From ' + triggerFrom);
                System.debug('Milestone ' + transitionTrigger.Avo_Milestone_Name__c);
                System.debug('Submission ' + transitionTrigger.Avo_Submission_Type__c);
                System.debug('Deposit ' + transitionTrigger.Avo_Deposit_Type__c);
                
                if (transitionTrigger.Avo_Review_Type__c !=null && triggerFrom == TriggerFromObjectEnum.REVIEW){
                    if (transitionTrigger.Avo_Review_Type__c == 'Any Review' || transitionTrigger.Avo_Review_Type__c == review.MUSW__Type__c) {
                        isValid = checkFormulaCondition(transitionTrigger.Avo_Formula_Condition__c) 
                        && StatusMatch(review.MUSW__Status__c,transitionTrigger.Avo_Review_Status__c)
                        && StopperConditionsMet(processStateTransition);

                        System.debug('Review ' + isValid);
                    }
                } else if (transitionTrigger.Avo_Fee_Type__c !=null && triggerFrom == TriggerFromObjectEnum.FEE){
                    if (transitionTrigger.Avo_Fee_Type__c == 'Any Fee' || transitionTrigger.Avo_Fee_Type__c == fee.MUSW__Type__c) {
                        isValid = checkFormulaCondition(transitionTrigger.Avo_Formula_Condition__c) 
                        &&  true
                        && StopperConditionsMet(processStateTransition);

                        System.debug('Fee ' + isValid);
                    }
                } else if (transitionTrigger.Avo_Inspection_Type__c !=null && triggerFrom == TriggerFromObjectEnum.INSPECTION){
                    if (transitionTrigger.Avo_Inspection_Type__c == 'Any Inspection' || transitionTrigger.Avo_Inspection_Type__c == inspection.MUSW__Type__c) {
                        isValid =checkFormulaCondition(transitionTrigger.Avo_Formula_Condition__c) 
                        &&  StatusMatch(inspection.MUSW__Status__c, transitionTrigger.Avo_Inspection_Result__c)
                        && StopperConditionsMet(processStateTransition);

                        System.debug('Inspection ' + isValid);
                    }
                } /*else  if (transitionTrigger.Avo_Milestone_Name__c != null && triggerFrom == TriggerFromObjectEnum.MILESTONE){
                    if (transitionTrigger.Avo_Milestone_Name__c == 'Any Milestone' || transitionTrigger.Avo_Milestone_Name__c == milestone.Name) {
                        isValid = checkFormulaCondition(transitionTrigger.Avo_Formula_Condition__c) 
                        && StatusMatch(milestone.MUSW__Completed_Action__c,transitionTrigger.Avo_Milestone_Completed_Action__c)
                        && StopperConditionsMet(processStateTransition);

                        System.debug('Milestone ' + isValid);
                    }
                } */else   if (transitionTrigger.Avo_Submission_Type__c !=null && triggerFrom == TriggerFromObjectEnum.SUBMISSION){
                    if (transitionTrigger.Avo_Submission_Type__c == 'Any Submission' || transitionTrigger.Avo_Submission_Type__c == submission.Name) {
                        isValid = checkFormulaCondition(transitionTrigger.Avo_Formula_Condition__c) 
                        && StatusMatch(submission.MUSW__Status__c,transitionTrigger.Avo_Submission_Status__c)
                        && StopperConditionsMet(processStateTransition);

                        System.debug('Submission ' + isValid);
                    }
                }else if (transitionTrigger.Avo_Deposit_Type__c !=null && triggerFrom == TriggerFromObjectEnum.DEPOSIT){
                    if (transitionTrigger.Avo_Deposit_Type__c == 'Any Deposit' || transitionTrigger.Avo_Deposit_Type__c == deposit.MUSW__Type__c) {
                        isValid = checkFormulaCondition(transitionTrigger.Avo_Formula_Condition__c) 
                        &&  true
                        && StopperConditionsMet(processStateTransition);

                        System.debug('Deposit ' + isValid);
                    }
                }else {
                    //return false;
                    //throw new AvoProcessException('unsupported logic in AvoProcessEngineBase.validTrigger()');
                }
            }
        }
        return isValid;        
    }

    // try to compare the trigger status and the status of the current triggerfromobject
    public boolean StatusMatch(string status, string statuses){
        List<String> statusList = statuses.split(';');
        if (statusList.contains(status)) return true;
        return false;
    }

    //
    //Add business days to a date
    public static Date AddBusinessDays(Date startDate, Integer businessDaysToAdd )
    {
        //Add or decrease business days
        Date finalDate = startDate;
        Integer direction = businessDaysToAdd < 0 ? -1 : 1;
        while(businessDaysToAdd != 0)
        {
            finalDate = finalDate.addDays(direction);
            if (!IsWeekend(finalDate))
            {
                businessDaysToAdd -= direction;
            }
        }
        return finalDate;
    }
    
    // Check if a date is a weekend day
    public static Boolean IsWeekend(Date myDate)
    {
        String myDateString = Datetime.newInstance(myDate.year(), myDate.month(),myDate.day()).format('EEE');
        return 'Sat'.equals(myDateString) || 'Sun'.equals(myDateString);
    }

   /* public void sendEmail(string templatename){
        EmailTemplate template = [SELECT Id, Subject, HtmlValue  FROM EmailTemplate 
        WHERE Name =:templatename
        ORDER BY LastModifiedDate DESC
        Limit 1];

        String bodyText = template.HtmlValue;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(template.Id);
        mail.setSubject(template.Subject);
        mail.setSaveAsActivity(true);
        mail.setUseSignature(false);

        List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
        owea = [SELECT Id, Address, DisplayName FROM 
        OrgWideEmailAddress WHERE DisplayName='Do Not Reply'];

if ( owea.size() > 0) {
    mail.setOrgWideEmailAddressId(owea[0].Id);
    }
       
        if (permit != null) {
            if (permit.MUSW__Applicant__c != null) {
                mail.setTargetObjectId(permit.MUSW__Applicant__c);       
                mail.setWhatId(permit.Id);
    
                Contact contact = [SELECT Id, Name, FirstName from Contact Where ID = :permit.MUSW__Applicant__c];
    
                bodyText = bodyText.replace('{{{Recipient.FirstName}}}', 
                String.isblank(contact.FirstName) ? contact.Name : contact.FirstName );
                bodyText = bodyText.replace('{{{MUSW__Permit2__c.Name}}}', permit.Name);
            } else if (permit.MUSW__Type__c == 'Parking Permit' && permit.Avo_Residential_Contact__c != null) {
                mail.setTargetObjectId(permit.Avo_Residential_Contact__c);       
                mail.setWhatId(permit.Id);
    
                Contact contact = [SELECT Id, Name, FirstName from Contact Where ID = :permit.Avo_Residential_Contact__c];
    
                bodyText = bodyText.replace('{{{Recipient.FirstName}}}', 
                String.isblank(contact.FirstName) ? contact.Name : contact.FirstName );
                bodyText = bodyText.replace('{{{MUSW__Permit2__c.Name}}}', permit.Name);
            }
        } else if (application != null) {
            if (application.MUSW__Applicant__c != null) {
                mail.setTargetObjectId(application.MUSW__Applicant__c);
                mail.setWhatId(application.Id);
    
                Contact contact = [SELECT Id, Name, FirstName from Contact Where ID = :application.MUSW__Applicant__c];
    
                bodyText = bodyText.replace('{{{Recipient.FirstName}}}', 
                String.isblank(contact.FirstName) ? contact.Name : contact.FirstName );
                bodyText = bodyText.replace('{{{MUSW__Application2__c.Name}}}', application.Name);
            }
        }
           
        mail.setHtmlBody(bodyText);

        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        allmsg.add(mail);

        try {
            Messaging.sendEmail(allmsg,false);
            return;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    } */

   /* public void updateInstance(AVO_Process_State_Post_Actions__c action) {

        if (action.Avo_Field_to_Update__c != null) {
            switch on triggerFrom{
                when PERMIT{
                    permit.put(action.Avo_Field_to_Update__c, action.Avo_Field_Value__c);
                }
                when APPLICATION{
                    application.put(action.Avo_Field_to_Update__c, action.Avo_Field_Value__c);
                }
            }
        }

        String queueName = action.Avo_Queue_Assignment__c;
        if (queueName != null) {
            List<Group> queues = [select Id, Name from Group where Type = 'Queue' and Name =:queueName];

            if (queues.size() > 0) {
                switch on triggerFrom{
                    when PERMIT{
                        permit.OwnerId = queues[0].Id;
                    }
                    when APPLICATION{
                        application.OwnerId = queues[0].Id;
                    }
                }

            }
        }
    } */

    public boolean checkFormulaCondition(String formula){
        system.debug('assessing post action formula condition:' + formula );
           
        if (string.isblank(formula) == false){ 
            
            try {

                Boolean result = processFormula(formula);

                System.Debug('Formula End Result: ' + result);
                return result;
            }
            catch (Exception e) {
                system.debug('assessing of activity formula data has failed');
                system.debug(e.getMessage());     
            }
        }
      
        return true;
    }

    public boolean processFormula(String formula) {
        formula = formula.replace('\r\n', ' ');
        formula = formula.replace('\n', ' ');
        formula = formula.replace('\r', ' ');

        if (!formula.contains('&&') && !formula.contains('||')) 
        {
            System.Debug('Processing Single ');
            return processSingleStatement(formula);
        } 
        else
        {
            Integer lastIndex = 0;
            Integer index = findFirstOperator(formula);
            Boolean shouldStop = false;
            Boolean result = true;
            while (!shouldStop) 
            {
                if (index == -1) 
                {
                    shouldStop = true;
                }
                
                Integer offset = lastIndex == 0? 0 : 2;

                String temp = index != -1? formula.substring(lastIndex + offset, lastIndex + offset + index) :
                formula.substring(lastIndex + offset);

                Boolean nextResult = processSingleStatement(temp);

                if (lastIndex == 0)
                {
                    result = result && nextResult;
                }
                else 
                {
                    String nextOperator = formula.substring(lastIndex, lastIndex + 2);

                    if (nextOperator == '&&')
                    {
                        result = result && nextResult;
                    }

                    if (nextOperator == '||') 
                    {
                        result = result || nextResult;
                    }
                }

                lastIndex = lastIndex + index + offset;
                index = findFirstOperator(formula.substring(lastIndex + 2));
            }

            return result;
        }
    }

    public Integer findFirstOperator(string formula) {
        Integer firstAnd = formula.indexOf('&&');
        Integer firstOr = formula.indexOf('||');

        if (firstAnd == -1 && firstOr == -1)
        {
            return -1;
        }

        if (firstAnd == -1 && firstOr != -1) 
        {
            return firstOr;
        }

        if (firstAnd != -1 && firstOr == -1) 
        {
            return firstAnd;
        }

        return firstAnd < firstOr ? firstAnd : firstOr;
    }

    public boolean compareValue(Object  fieldValue, String valueToCheck, FormulaOperator operator) {

        boolean result = true;

        if (operator == FormulaOperator.INSIDE) {
            result = valueToCheck.contains((String)fieldValue);
        } else if (operator == FormulaOperator.GREATERTHAN) {
            result = (Decimal) fieldValue > Decimal.valueOf(valueToCheck);
        } else if (operator == FormulaOperator.LESSTHAN) {
            result = (Decimal) fieldValue < Decimal.valueOf(valueToCheck);
        }
        else {
            
            if (valueToCheck == 'true' ) {
                System.debug('-- else block "true":' + fieldValue);
    
                result = (Boolean) fieldValue ;
            } else  if (valueToCheck == 'false') {
                System.debug('-- else block "false":' + fieldValue);
                result = !(Boolean) fieldValue;
            } else {
                Boolean isMultiplePickListValue = ((String)fieldValue).contains(';');
    
                if (isMultiplePickListValue) {
                    result = ((String)fieldValue).contains(valueToCheck);
                } else {
                    result =  ((String)fieldValue == valueToCheck);
                }
            }
    
        }
        System.debug('field value: ' + fieldValue);
        System.debug('value: ' + valueToCheck);

        return operator == FormulaOperator.NOTEQUAL ? !result : result; 
    }

    public boolean processSingleStatement(string equation) {

        FormulaOperator operator;
        List<String> formulaElements = new List<String>();

        if (equation.indexOf('!=') > 0) {
            formulaElements = equation.split('!=');
            operator = FormulaOperator.NOTEQUAL;
        } else if (equation.indexOf('=') > 0) {
            formulaElements = equation.split('=');
            operator = FormulaOperator.EQUAL;
        } else if (equation.indexOf(' IN ') > 0) {
            formulaElements = equation.split(' IN ');
            operator = FormulaOperator.INSIDE;
        } else if (equation.indexOf('>') > 0) {
            formulaElements = equation.split('>');
            operator = FormulaOperator.GREATERTHAN;
        } else if (equation.indexOf('<') > 0) {
            formulaElements = equation.split('<');
            operator = FormulaOperator.LESSTHAN;
        }

        if (formulaElements.size() == 0)
        {
            return true;
        }
        
        System.debug('operator: ' + operator);
        system.debug('formula elements ' + formulaElements );

        String fieldToCheck = formulaElements[0].trim();
        String valueToCheck = formulaElements[1].trim();

        valueToCheck = valueToCheck.replace('\'', '').replace('"', '');
        
        try {

            boolean result = false;
            switch on triggerFrom{
                when PERMIT{
                    //result = compareValue(permit.get(fieldToCheck) , valueToCheck, operator);  
                    result = compareValue((permit.get(fieldToCheck) == null ? '' : permit.get(fieldToCheck)) , valueToCheck, operator);
                }
                when APPLICATION{
                    result = compareValue(application.get(fieldToCheck), valueToCheck, operator);   
                }
                when else {

                    if (permit != null) {
                        String fieldQuery = 'SELECT ' + fieldToCheck +
                         ' FROM MUSW__Permit2__c WHERE ID = \'' + permit.Id + '\' LIMIT 1';
                       
                        SObject fieldValue = Database.query(fieldQuery);
                        
                        result = compareValue(fieldValue.get(fieldToCheck), valueToCheck, operator);       
                      
                    } else if (application != null) {
                        String fieldQuery = 'SELECT ' + fieldToCheck +
                         ' FROM MUSW__Application2__c WHERE ID = \'' + application.Id + '\' LIMIT 1';
                        
                        SObject fieldValue = Database.query(fieldQuery);

                        result = compareValue(fieldValue.get(fieldToCheck), valueToCheck, operator);       
                    }

                }
            }

            return result;

        }
        catch (Exception e) {
            system.debug('assessing of activity formula data has failed ' + equation);
            system.debug(e.getMessage());     
        }



        return false;
    }

    
    
}