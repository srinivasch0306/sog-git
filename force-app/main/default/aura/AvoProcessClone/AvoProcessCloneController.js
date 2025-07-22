/**
 * Controller for AvoProcessClone.cmp.
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/21/2021
 * 
 */

 ({
    // Function called on initial page loading to get data from server
     /*
    doInit : function(component, event, helper) {
        
    },
    */
     
    // Handles creation of Inspection on the Permit on click
    handleClone : function(component, event, helper) {
        
        var recordId = component.get('v.recordId');
        var objectName = component.get('v.sObjectName');
        var processName = component.get('v.processName');
        
        var cloneProcessAction = component.get('c.cloneProcess');
		
        cloneProcessAction.setParams({
            recordId: recordId,
            objectName: objectName,
            processName: processName
        });
        
        
        cloneProcessAction.setCallback(this, function(response) {
        	// Getting the state of response to check it was successfull or not
            var state = response.getState();
            if(state === 'SUCCESS') {
                window.location.href = `/${response.getReturnValue()}`;
            } else {
                // Displaying the alert when call to apex was not successfull
                alert('Unable to create Inspections. Please contact Avocette for technical support.');
            }
        });
        
        // Enqueued it as the global action
        $A.enqueueAction(cloneProcessAction);
    }
    
})