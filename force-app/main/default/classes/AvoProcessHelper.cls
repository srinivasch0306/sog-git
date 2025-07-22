/**
 * Description of class
 * a class to work with process lightning components to display Process Summary
 * this process lightning component can be adde to multipe layouts
 * used by lightning component AvoProcessEngine
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/24/2021
 *  
 */
public class AvoProcessHelper {

    public AvoProcessHelper() {
        // there is no programming here
    }

    // recordId is the ID of the current Process record
    @AuraEnabled    
    public static List<item> GetProcessSummary(Id recordId, string objectName)
    {   
        if (objectName == 'AVO_Process_State_Transition__c'){
            AVO_Process_State_Transition__c stateTransition =
                [
                    SELECT Avo_Process__c
                    FROM AVO_Process_State_Transition__c
                    WHERE ID =:recordId];
            recordId = stateTransition.Avo_Process__c;
        }
        
        integer sequence = 0;
        Avo_Process__c currentProcess = [
            SELECT 
                ID,
                Avo_Process_Type__c,
                Avo_Permit_Type__c,
                Avo_Planning_Application_Type__c            
            FROM Avo_Process__c 
            WHERE ID=: recordId];
            
        // get all state transitions for the current Process
        List<item> items = new List<item>();              
        List<AVO_Process_State_Transition__c> processStateTransitions = [SELECT
            ID,
            Avo_From_State__c, 
            Avo_To_State__c,
            Avo_Auto_State_Transition__c    
            FROM AVO_Process_State_Transition__c 
            WHERE Avo_Process__c = :recordId
            ORDER BY Avo_Display_Order__c ASC];
        
        for(AVO_Process_State_Transition__c processStateTransition: processStateTransitions){
            // for each state transition, get the trigger conditions of the current state transition
            
            List<item> transitionTriggers = getTransitionTriggers(processStateTransition);
            sequence = sequence +1;

            List<item> transitionSubCategories = new list<item>();

            if (transitionTriggers.size() > 0 ) {
                transitionSubCategories.add(new item(
                    'Transition Triggers (' +transitionTriggers.size() + ')',
                    'Transition Triggers (' +transitionTriggers.size() + ')', 
                    false,transitionTriggers));
            }


            // for each state transition, get the stopper conditions of the current state transition
                        
            List<item> transitionStopperPoints = getTransitionStoppers(processStateTransition);

            if (transitionStopperPoints.size() > 0) {
                transitionSubCategories.add(new item(
                    'Transition Must Met Condtions (' +transitionStopperPoints.size() + ')',
                    'Transition Must Met Condtions (' +transitionStopperPoints.size() + ')',
                    false,transitionStopperPoints));
            }

            // for each state transition, get the stopper conditions of the current state transition
                        
            List<item> postTransitionActions = getPostTransitionActions(processStateTransition);

            if (postTransitionActions.size() > 0) {
                transitionSubCategories.add(new item(
                    'Post Transition Actions (' +postTransitionActions.size() + ')',
                    'Post Transition Actions (' +postTransitionActions.size() + ')',
                    false,postTransitionActions));
            }

            items.add(new item(sequence + '.Transition: ' + processStateTransition.Avo_Auto_State_Transition__c, processStateTransition.ID, false, transitionSubCategories));
        }
        items.add(new item('Activities','Activities', false,getAllowedChildActivities(currentProcess)));
                
        return items;        
    }

    private static List<item> getAllowedChildActivities(Avo_Process__c process)
    {
        String permitType = process.Avo_Permit_Type__c;
        String applicationType = process.Avo_Planning_Application_Type__c;
       
        List<item> results = new List<item>();

        List<item> reviewTypesAllowed = new List<item>();
        System.Debug('permit: ' + permitType);
        System.Debug('application: ' + applicationType);
        

        // get all allowed review types
        List<Master_Review_List__c> reviewTypes = new List<Master_Review_List__c>();
        
        if (permitType != null) {
            reviewTypes = [
                SELECT Id,
                    Name,
                    Description__c
                FROM Master_Review_List__c 
                WHERE  Avo_Permit_Type__c includes (:permitType)
                   AND Active__c = true
                   AND Manual_Creation_Allowed__c = true 
                ORDER BY Name ASC];
        }

        if (applicationType != null) {
            reviewTypes = [
                SELECT Id,
                    Name,
                    Description__c
                FROM Master_Review_List__c 
                WHERE  Avo_Planning_Application_Type__c includes (:applicationType)
                    AND Active__c = true
                    AND Manual_Creation_Allowed__c = true 
                ORDER BY Name ASC];
        }

        for(Master_Review_List__c reviewType: reviewTypes){
            reviewTypesAllowed.add(new item(reviewType.Name + (String.isBlank(reviewType.Description__c) ? '' : ' : '+ reviewType.Description__c),
                reviewType.Id, false, null));
        }    

        if (reviewTypesAllowed.size() > 0)
            results.add(new item('Review Types (' + reviewTypesAllowed.size() +')','Review Types', false,reviewTypesAllowed));

        // get all allowed fee types
        List<item> feeTypesAllowed = new List<item>();
        List<MUSW__Master_Fee_List__c> feeTypes = new List<MUSW__Master_Fee_List__c>();

        if (permitType != null) {
            feeTypes = [
            SELECT Id,
                Name, Avo_Description__c,
                Fee_Calculation_Type__c
            FROM MUSW__Master_Fee_List__c
            WHERE Avo_Permit_Type__c includes (:permitType)];
        }

        if (applicationType != null) {
            feeTypes = [
            SELECT Id,
                Name, Avo_Description__c,
                Fee_Calculation_Type__c
            FROM MUSW__Master_Fee_List__c 
            WHERE Avo_Planning_Application_Type__c includes (:applicationType)];
        }    

        for(MUSW__Master_Fee_List__c feeType: feeTypes){

            String displayName = feeType.Name + ' ('+ feeType.Fee_Calculation_Type__c + ')'
             + (String.isBlank(feeType.Avo_Description__c) ? '' : ' : '+ feeType.Avo_Description__c);


            feeTypesAllowed.add(new item(displayName,feeType.Id, false, null));
        }    

        if (feeTypesAllowed.size() > 0)
            results.add(new item('Fee Types (' + feeTypesAllowed.size() +')', 'Fee Types',false,feeTypesAllowed));

        // get all allowed submission types
        List<item> feeSubmissionsAllowed = new List<item>();
        List<MUSW__Master_Submission_List__c> submissionTypes = new List<MUSW__Master_Submission_List__c>();

        if (permitType != null) {
            submissionTypes = [
            SELECT 
                Id,
                Name,
                Description__c
            FROM MUSW__Master_Submission_List__c
            WHERE Avo_Permit_Type__c includes (:permitType)];
        }

        if (applicationType != null) {
            submissionTypes = [
            SELECT 
                Id,
                Name,
                Description__c
            FROM MUSW__Master_Submission_List__c 
            WHERE Avo_Planning_Application_Type__c includes (:applicationType)];
        }    

        for(MUSW__Master_Submission_List__c submissionType: submissionTypes){
            feeSubmissionsAllowed.add(new item(submissionType.Name + (String.isBlank(submissionType.Description__c) ? '' : ' : '+ submissionType.Description__c),
                submissionType.Id, false, null));
        }    

        if (feeSubmissionsAllowed.size() > 0)
            results.add(new item('Submission Types (' + feeSubmissionsAllowed.size() +')', 'Submission Types',false,feeSubmissionsAllowed));


        // get all allowed inspection types
        List<item> feeInspectionsAllowed = new List<item>();
        List<MUSW__Master_Inspection_List__c> inspectionTypes = new List<MUSW__Master_Inspection_List__c>();

        if (permitType != null) {
            inspectionTypes = [
            SELECT Name, Id,Description__c
            FROM MUSW__Master_Inspection_List__c
            WHERE Avo_Permit_Type__c includes (:permitType)];
        }

        if (applicationType != null) {
            inspectionTypes = [
            SELECT Name, Id,Description__c
            FROM MUSW__Master_Inspection_List__c 
            WHERE Avo_Planning_Application_Type__c includes (:applicationType)];
        }    
    

        for(MUSW__Master_Inspection_List__c inspectionType: inspectionTypes){

            String displayName = inspectionType.Name + (String.isBlank(inspectionType.Description__c) ? '' : ' : '+ inspectionType.Description__c);

            feeInspectionsAllowed.add(new item(displayName,inspectionType.id, false, null));
        }    

        if (feeInspectionsAllowed.size() > 0)
            results.add(new item('Inspection Types (' + feeInspectionsAllowed.size() +')', 'Inspection Types',false,feeInspectionsAllowed));
        

        // get all allowed task types
        List<item> tasksAllowed = new List<item>();
        List<Master_Task_List__c> taskTypes = new List<Master_Task_List__c>();

        if (applicationType != null) {
            taskTypes = [
            SELECT Name, Id, Description__c
            FROM Master_Task_List__c 
            WHERE Avo_Planning_Application_Type__c includes (:applicationType)];
        }    


        for(Master_Task_List__c taskType: taskTypes){
            String displayName = taskType.Name + (String.isBlank(taskType.Description__c) ? '' : ' : '+ taskType.Description__c);

            tasksAllowed.add(new item(taskType.Name,taskType.id, false, null));
        }    

        if (tasksAllowed.size() > 0)
            results.add(new item('Task Types (' + tasksAllowed.size() +')', 'Task Types',false,tasksAllowed));
        
        // get all allowed event types
        List<item> eventsAllowed = new List<item>();
        List<Master_Event_List__c> eventTypes = new List<Master_Event_List__c>();

        if (applicationType != null) {
            eventTypes = [
            SELECT Name, Id, Description__c
            FROM Master_Event_List__c 
            WHERE Avo_Planning_Application_Type__c includes (:applicationType)];
        }    


        for(Master_Event_List__c eventType: eventTypes){
            String displayName = eventType.Name + (String.isBlank(eventType.Description__c) ? '' : ' : '+ eventType.Description__c);

            eventsAllowed.add(new item(displayName,eventType.id, false, null));
        }    

        if (tasksAllowed.size() > 0) 
            results.add(new item('Event Types (' + eventsAllowed.size() +')', 'Event Types',false,eventsAllowed));


        return results;   
    }

    // get transition triggers
    private static List<item> getTransitionTriggers(Avo_Process_State_Transition__c processStateTransition){
        List<item> transitionTriggers = new List<item>();
            
        List<AVO_Process_State_Transition_Trigger__c> processStateTransitionTriggers = [SELECT 
            Avo_Fee_Type__c,
            Avo_Review_Type__c,
            Avo_Review_Status__c, 
            Avo_Inspection_Type__c,
            Avo_Inspection_Result__c, 
            RecordTypeId
        FROM AVO_Process_State_Transition_Trigger__c
           WHERE Avo_Process_State_Transition__c = :processStateTransition.ID];
        
        // a state transition may have zero trigger condition defined
        if (processStateTransitionTriggers != null ){
            for(AVO_Process_State_Transition_Trigger__c processStateTransitionTrigger: processStateTransitionTriggers){
                item transitionCondition;
                If (processStateTransitionTrigger.Avo_Review_Type__c != NULL){
                    List<item> reviewStatusConditions = new List<item>(); 
                    If (processStateTransitionTrigger.Avo_Review_Status__c !=NULL){
                        List<String> values = processStateTransitionTrigger.Avo_Review_Status__c.split(';');
                        // convert a string value such as 'Approved;Approved with Condtion' to a list of string values
                        for(Integer i = 0; i < values.size(); i++){
                            if (i < values.size()-1){
                                // apppend 'or' to all statuses except the last one
                                reviewStatusConditions.add(new item(values[i] + ' or', processStateTransitionTrigger.ID + values[i], true, null));
                            }else{
                                reviewStatusConditions.add(new item(values[i] , processStateTransitionTrigger.ID + values[i], true, null));
                            }
                        }
                    }
                    transitionCondition = new item(
                        processStateTransitionTrigger.Avo_Review_Type__c +' in the status of', 
                        String.valueOf(processStateTransitionTrigger.Id), 
                        false, 
                        reviewStatusConditions);
                } else if (processStateTransitionTrigger.Avo_Fee_Type__c != NULL){
                    transitionCondition = new item(processStateTransitionTrigger.Avo_Fee_Type__c + ' has been paid', String.valueOf(processStateTransitionTrigger.Id), false, null);
                } else if (processStateTransitionTrigger.Avo_Inspection_Type__c != NULL){
                    List<item> inspectionStatusConditions = new List<item>(); 
                    If (processStateTransitionTrigger.Avo_Inspection_Result__c !=NULL){
                        List<String> values = processStateTransitionTrigger.Avo_Inspection_Result__c.split(';');
                        // convert a string value such as 'Approved;Approved with Condtion' to a list of string values
                        for(Integer i = 0; i < values.size(); i++){
                            if (i < values.size()-1){
                                // apppend 'or' to all statuses except the last one
                                inspectionStatusConditions.add(new item(values[i] + ' or', processStateTransitionTrigger.ID + values[i], true, null));
                            }else{
                                inspectionStatusConditions.add(new item(values[i] , processStateTransitionTrigger.ID + values[i], true, null));
                            }
                        }
                    }
                    transitionCondition = new item(
                         processStateTransitionTrigger.Avo_Inspection_Type__c +' in the status of', 
                         String.valueOf(processStateTransitionTrigger.Id), 
                         false, 
                         inspectionStatusConditions);
                }
                transitionTriggers.add(transitionCondition);
            }
        }   
        return transitionTriggers;
    }

    // get transition stoppers
    private static List<item> getTransitionStoppers(Avo_Process_State_Transition__c processStateTransition){
        List<item> transitionStoppers = new List<item>();
            
        List<AVO_Process_State_Transition_Stopper__c> processStateTransitionStoppers = [SELECT 
             Avo_Fee_Type__c,
             Avo_Review_Type__c,
             Avo_Review_Status__c, 
             Avo_Inspection_Type__c,
             Avo_Inspection_Result__c, 
             RecordTypeId
        FROM AVO_Process_State_Transition_Stopper__c
           WHERE Avo_Process_State_Transition__c = :processStateTransition.ID];
        
        // a state transition may have zero trigger stopper defined
        if (processStateTransitionStoppers != null ){
            for(AVO_Process_State_Transition_Stopper__c processStateTransitionStopper: processStateTransitionStoppers){
                item stopperCondition;
                If (processStateTransitionStopper.Avo_Review_Type__c != NULL){
                    List<item> reviewStatusConditions = new List<item>(); 
                    If (processStateTransitionStopper.Avo_Review_Status__c !=NULL){
                        List<String> values = processStateTransitionStopper.Avo_Review_Status__c.split(';');
                        // convert a string value such as 'Approved;Approved with Condtion' to a list of string values
                        for(Integer i = 0; i < values.size(); i++){
                            if (i < values.size()-1){
                                // apppend 'or' to all statuses except the last one
                                reviewStatusConditions.add(new item(values[i] + ' or', processStateTransitionStopper.ID + values[i], true, null));
                            }else{
                                reviewStatusConditions.add(new item(values[i] , processStateTransitionStopper.ID + values[i], true, null));
                            }
                        }
                    }
                    stopperCondition = new item(
                        processStateTransitionStopper.Avo_Review_Type__c +' in the status of', 
                        String.valueOf(processStateTransitionStopper.Id), 
                        false, 
                        reviewStatusConditions);
                } else if (processStateTransitionStopper.Avo_Fee_Type__c != NULL){
                    stopperCondition = new item(processStateTransitionStopper.Avo_Fee_Type__c + ' has been paid', String.valueOf(processStateTransitionStopper.Id), false, null);
                } else if (processStateTransitionStopper.Avo_Inspection_Type__c != NULL){
                    List<item> inspectionStatusConditions = new List<item>(); 
                    If (processStateTransitionStopper.Avo_Inspection_Result__c !=NULL){
                        List<String> values = processStateTransitionStopper.Avo_Inspection_Result__c.split(';');
                        // convert a string value such as 'Approved;Approved with Condtion' to a list of string values
                        for(Integer i = 0; i < values.size(); i++){
                            if (i < values.size()-1){
                                // apppend 'or' to all statuses except the last one
                                inspectionStatusConditions.add(new item(values[i] + ' or', processStateTransitionStopper.ID + values[i], true, null));
                            }else{
                                inspectionStatusConditions.add(new item(values[i] , processStateTransitionStopper.ID + values[i], true, null));
                            }
                        }
                    }
                    stopperCondition = new item(
                        processStateTransitionStopper.Avo_Inspection_Type__c +' in the status of', 
                         String.valueOf(processStateTransitionStopper.Id), 
                         false, 
                         inspectionStatusConditions);
                }
                transitionStoppers.add(stopperCondition);
            }
        }   
        return transitionStoppers;
    }

    // get post transition actions
    private static List<item> getPostTransitionActions(Avo_Process_State_Transition__c processStateTransition){
        List<item> transitionActions = new List<item>();
        String actionName;
           
        List<AVO_Process_State_Post_Actions__c> postActions = [SELECT 
            Avo_Event_Type__c,
            Avo_Fee_Type__c,
            Avo_Inspection_Type__c,
            Avo_Review_Type__c, 
            Avo_Submission_Type__c, 
            Avo_Task_Type__c,
            Avo_Notes__c,
            Avo_Formula_Condition__c
        FROM AVO_Process_State_Post_Actions__c
           WHERE Avo_Process_State_Transition__c = :processStateTransition.ID];
        
        // a state transition may have zero post actions defined
        if (postActions != null ){
            for(AVO_Process_State_Post_Actions__c postAction: postActions){
                actionName =
                    (postAction.Avo_Event_Type__c == null ? '' : postAction.Avo_Event_Type__c) +
                    (postAction.Avo_Fee_Type__c == null ? '' : postAction.Avo_Fee_Type__c) +
                    (postAction.Avo_Inspection_Type__c == null ? '' : postAction.Avo_Inspection_Type__c) +
                    (postAction.Avo_Review_Type__c == null ? '' : postAction.Avo_Review_Type__c) +
                    (postAction.Avo_Submission_Type__c == null ? '' : postAction.Avo_Submission_Type__c) +
                    (postAction.Avo_Task_Type__c == null ? '' : postAction.Avo_Task_Type__c);
                if (String.isBlank(postAction.Avo_Formula_Condition__c) == TRUE){
                    transitionActions.add( new item(actionName,actionName,false, null));                   
                }else{
                    List<item> businessRule = new List<item>();
                    businessRule.add(new item(
                        postAction.Avo_Formula_Condition__c,
                        'adb', false, null));

                    transitionActions.add(new item(actionName + ' if','adb',false,businessRule));                   
                }
            }
        }   
        return transitionActions;
    }

    //Item Wrapper Class
    public class item{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public Boolean expanded {get; set;}
        @AuraEnabled
        public List<item> items {get; set;}
        
        public item(String label, String name, Boolean expanded, List<item> items){
            this.label = label;
            this.name = name;
            this.expanded = expanded;
            this.items = items;
        }
    }

    public static List<item> getReviews(string permitType)
    {
        List<Master_Review_List__c> reviewList = [
            SELECT 
                Name,
                Avo_Permit_Type__c,
                Avo_Review_Type__c, 
                Avo_Review_Status__c 
            FROM Master_Review_List__c 
            WHERE Avo_Permit_Type__c INCLUDES (:permitType)
            ORDER BY Name];
    
        List<item> reviews = new List<item>();
        for (Master_Review_List__c reviewType: reviewList)
        {
            reviews.add(new item(reviewType.name,reviewType.name, false, null));
        }
        return reviews;        
    }

     @AuraEnabled
    public static string cloneProcess(Id recordId, String objectName, String processName){
        // step 1 
        // copy the Process record from the AVO_Process__c object
                
        AVO_Process__c process = [
            SELECT 
                Name,
                RecordTypeId,
                Avo_Permit_Type__c,
                Avo_Planning_Application_Type__c,
                Avo_Process_Type__c,
                Avo_Notes__c,
                Avo_Effective_Start_Date__c,
                Avo_Effective_End_Date__c
            FROM AVO_Process__c
            WHERE ID = :recordId];
        
        AVO_Process__c clonedProcess = new AVO_Process__c();
        
        clonedProcess.Name = processName;
        clonedProcess.RecordTypeId = process.RecordTypeId;
        clonedProcess.Avo_Permit_Type__c = process.Avo_Permit_Type__c;
        clonedProcess.Avo_Planning_Application_Type__c = process.Avo_Planning_Application_Type__c;
        clonedProcess.Avo_Process_Type__c = process.Avo_Process_Type__c;
        clonedProcess.Avo_Notes__c = process.Avo_Notes__c;
        clonedProcess.Avo_Effective_Start_Date__c = process.Avo_Effective_Start_Date__c;
        clonedProcess.Avo_Effective_End_Date__c = process.Avo_Effective_End_Date__c;
               
        insert clonedProcess;   

        // step 2 
        // copy all Process State Transitions from the AVO_Process_State_Transition__c object

        List<AVO_Process_State_Transition__c> processStateTransitions = [
            SELECT 
                ID,
                Avo_Display_Order__c,
                Avo_From_State__c,
                Avo_To_State__c,
                Avo_Notes__c,
                Avo_Process__c
            FROM AVO_Process_State_Transition__c
            WHERE Avo_Process__c = :recordId];

        Map<string, string> processStateTransitionMapping = new Map<String, String>();
        for (AVO_Process_State_Transition__c processStateTransition:processStateTransitions){
            // for each state transition, copy the state transition
            AVO_Process_State_Transition__c clonedProcessStateTransition;
            clonedProcessStateTransition =  new AVO_Process_State_Transition__c(
                    Avo_Display_Order__c = processStateTransition.Avo_Display_Order__c,
                    Avo_From_State__c = processStateTransition.Avo_From_State__c,
                    Avo_To_State__c = processStateTransition.Avo_To_State__c,
                    Avo_Notes__c = processStateTransition.Avo_Notes__c,
                    Avo_Process__c = clonedProcess.id
            );            
            insert clonedProcessStateTransition;
            processStateTransitionMapping.put(processStateTransition.ID,clonedProcessStateTransition.ID);
        }
        
        // step 3 copy all Process State Transitions Triggers
        
        List<AVO_Process_State_Transition_Trigger__c> clonedProcessStateTransitionTriggers  = new List<AVO_Process_State_Transition_Trigger__c> ();
        for (String processStateTransition : processStateTransitionMapping.keySet()){
            String clondProcessStateTransition = processStateTransitionMapping.get(processStateTransition);
            
            List<AVO_Process_State_Transition_Trigger__c> processStateTransitionTriggers  = [
                SELECT 
                    Avo_Fee_Type__c,
                    Avo_Fee_Status__c,
                    Avo_Inspection_Type__c,
                    Avo_Inspection_Result__c,
                    Avo_Review_Status__c,
                    Avo_Review_Type__c,
                    Avo_Notes__c,
                    Avo_Formula_Condition__c,
                    RecordTypeId
                FROM AVO_Process_State_Transition_Trigger__c
                WHERE Avo_Process_State_Transition__c = :processStateTransition];

            for(AVO_Process_State_Transition_Trigger__c processStateTransitionTrigger:processStateTransitionTriggers){
                clonedProcessStateTransitionTriggers.add(
                    new AVO_Process_State_Transition_Trigger__c(
                        Avo_Fee_Type__c = processStateTransitionTrigger.Avo_Fee_Type__c,
                        Avo_Fee_Status__c = processStateTransitionTrigger.Avo_Fee_Status__c,
                        Avo_Inspection_Type__c = processStateTransitionTrigger.Avo_Inspection_Type__c,
                        Avo_Inspection_Result__c = processStateTransitionTrigger.Avo_Inspection_Result__c,
                        Avo_Review_Status__c = processStateTransitionTrigger.Avo_Review_Status__c,
                        Avo_Process_State_Transition__c = clondProcessStateTransition,
                        Avo_Review_Type__c = processStateTransitionTrigger.Avo_Review_Type__c,
                        Avo_Notes__c = processStateTransitionTrigger.Avo_Notes__c,
                        RecordTypeId = processStateTransitionTrigger.RecordTypeId,
                        Avo_Formula_Condition__c = processStateTransitionTrigger.Avo_Formula_Condition__c                 
                ));
            }
        }
       
        insert clonedProcessStateTransitionTriggers;
        
        // step 3 copy all Process State Transitions stoppers
        List<AVO_Process_State_Transition_Stopper__c> clonedProcessStateTransitionStopper  = new List<AVO_Process_State_Transition_Stopper__c> ();
        for (String processStateTransition : processStateTransitionMapping.keySet()){
            String clondProcessStateTransition = processStateTransitionMapping.get(processStateTransition);
            
            List<AVO_Process_State_Transition_Stopper__c> processStateTransitionStoppers  = [
                SELECT 
                    Avo_Fee_Type__c,
                    Avo_Fee_Status__c,
                    Avo_Inspection_Type__c,
                    Avo_Inspection_Result__c,
                    Avo_Review_Status__c,
                    Avo_Review_Type__c,
                    Avo_Notes__c,
                    RecordTypeId
                FROM AVO_Process_State_Transition_Stopper__c
                WHERE Avo_Process_State_Transition__c = :processStateTransition];

            for(AVO_Process_State_Transition_Stopper__c processStateTransitionStopper:processStateTransitionStoppers){

                    clonedProcessStateTransitionStopper.add(
                        new AVO_Process_State_Transition_Stopper__c(
                            Avo_Fee_Type__c = processStateTransitionStopper.Avo_Fee_Type__c,
                            Avo_Fee_Status__c = processStateTransitionStopper.Avo_Fee_Status__c,
                            Avo_Inspection_Type__c = processStateTransitionStopper.Avo_Inspection_Type__c,
                            Avo_Inspection_Result__c = processStateTransitionStopper.Avo_Inspection_Result__c,
                            Avo_Review_Status__c = processStateTransitionStopper.Avo_Review_Status__c,
                            Avo_Process_State_Transition__c = clondProcessStateTransition,
                            Avo_Review_Type__c = processStateTransitionStopper.Avo_Review_Type__c,
                            Avo_Notes__c = processStateTransitionStopper.Avo_Notes__c,
                            RecordTypeId = processStateTransitionStopper.RecordTypeId                     
                    ));
                
            }
        }
        System.debug(clonedProcessStateTransitionStopper);
       
        insert clonedProcessStateTransitionStopper;

        // step 3 copy all Process State Transitions actions
        List<AVO_Process_State_Post_Actions__c> clonedProcessStatePostActions  = new List<AVO_Process_State_Post_Actions__c> ();
        for (String processStateTransition : processStateTransitionMapping.keySet()){
            String clondProcessStateTransition = processStateTransitionMapping.get(processStateTransition);
            
            List<AVO_Process_State_Post_Actions__c> processStatePostActions;
            processStatePostActions = [
                SELECT 
                    Avo_Event_Type__c,
                    Avo_Fee_Type__c,
                    Avo_Inspection_Type__c,
                    Avo_Submission_Type__c,
                    Avo_Review_Type__c,
                    Avo_Notes__c,
                    Avo_Active__c,
                    Avo_Offset__c,
                    Avo_Task_Type__c,
                    RecordTypeId,
                    Avo_Formula_Condition__c,
                    Avo_Fee_Quantity__c,
                    Avo_Email_Template__c
                FROM AVO_Process_State_Post_Actions__c
                WHERE Avo_Process_State_Transition__c = :processStateTransition];

            for(AVO_Process_State_Post_Actions__c processStatePostAction:processStatePostActions){
                clonedProcessStatePostActions.add(
                    new AVO_Process_State_Post_Actions__c(
                        Avo_Event_Type__c = processStatePostAction.Avo_Event_Type__c,
                        Avo_Fee_Type__c = processStatePostAction.Avo_Fee_Type__c,
                        Avo_Inspection_Type__c = processStatePostAction.Avo_Inspection_Type__c,
                        Avo_Submission_Type__c = processStatePostAction.Avo_Submission_Type__c,
                        Avo_Process_State_Transition__c = clondProcessStateTransition,
                        Avo_Review_Type__c = processStatePostAction.Avo_Review_Type__c,
                        Avo_Notes__c = processStatePostAction.Avo_Notes__c,
                        Avo_Active__c = processStatePostAction.Avo_Active__c,                     
                        Avo_Offset__c = processStatePostAction.Avo_Offset__c,         
                        Avo_Task_Type__c = processStatePostAction.Avo_Task_Type__c,    
                        RecordTypeId = processStatePostAction.RecordTypeId,
                        Avo_Formula_Condition__c = processStatePostAction.Avo_Formula_Condition__c,
                        Avo_Fee_Quantity__c = processStatePostAction.Avo_Fee_Quantity__c,
                        Avo_Email_Template__c = processStatePostAction.Avo_Email_Template__c

                ));
            }
        }
       
        insert clonedProcessStatePostActions;
        
        return clonedProcess.id;
    }
}