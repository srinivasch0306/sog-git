/**
 * Controller for AvoNewSubmission.cmp.
 * @author Michael Chung
 * last modified by Yao Li
 * @date 05/19/2021
 * 
 */

 ({
    // Function called on initial page loading to get data from server
    doInit : function(component, event, helper) {
        // Helper function to fetch account and related objects data
		// Setting the name of method in apex controller which we need to call
        var fetchData = component.get('c.getAllowedSubmissionTypes');
        // Getting the accountId from component
        var recordId = component.get('v.recordId');        
        var sObjectName = component.get('v.sObjectName');

        fetchData.setParams({
            recordId: recordId,
            sObjectName: sObjectName
        });
                
        fetchData.setCallback(this, function(response) {
            // Getting the state of response to check it was successfull or not
            var state = response.getState();
            if(state === 'SUCCESS') {
                // Parsing JSON string into js object
                var responseObj = JSON.parse(response.getReturnValue());
                var items = [];
                
        		for (var i = 0; i < responseObj.submissionTypeList.length; i++) {
                    // Adding the label to display.
                    // The value (submission Id) is also added to the Submission Checkbox group item tag in the Lightning Component
                    items.push({
                        'label': responseObj.submissionTypeList[i].label, 
                        'value': responseObj.submissionTypeList[i].value
                    });
        		}

                // Set the Items into the Checkbox group.
       			component.set("v.options", items);
            } else {
                // Displaying the alert when call to apex was not successfull
                alert('Unable to fetch data from server, contact Avocette for technical support.');
            }
        });
        
        // Enqueued it as the global action
        $A.enqueueAction(fetchData);
    },
    // Handles creation of Submission on the Permit on click
    handleCreation : function(component, event, helper) {
        component.set('v.loaded', !component.get('v.loaded'));
        var recordId = component.get('v.recordId');
        var sObjectName = component.get('v.sObjectName');
        var submissionTypeValues = component.get('v.submissionValues');    
        var createSubmissionAction = component.get('c.createSubmissions');

        let selectedMasterSubmissionListIds = [];

        // Looping through submissionTypeValues to put all the selected Submission Ids into a new variable.
        submissionTypeValues.map((id) => {
            selectedMasterSubmissionListIds.push(id);
        });

        console.group('js parameters');
        console.log(recordId );
        console.log(selectedMasterSubmissionListIds );
        console.log(sObjectName );
        console.groupEnd();
        

        createSubmissionAction.setParams({
            recordId: recordId,
            masterSubmissionListIds: selectedMasterSubmissionListIds,
            sObjectName: sObjectName
        });
        
        createSubmissionAction.setCallback(this, function(response) {
        	// Getting the state of response to check it was successfull or not
            var state = response.getState();
            if(state === 'SUCCESS') {
                let allSubmissionsUrl = '';
                if(sObjectName === 'MUSW__Permit2__c') {
                    allSubmissionsUrl = `/lightning/r/MUSW__Submission__c/${recordId}/related/MUSW__Submissions__r/view`;
                } else if(sObjectName === 'MUSW__Application2__c') {
                    allSubmissionsUrl = `/lightning/r/MUSW__Application2__c/${recordId}/related/MUSW__Submissions__r/view`;
                } else if(sObjectName === 'AVO_Compliance__c') {
                    allSubmissionsUrl = `/lightning/r/AVO_Compliance__c/${recordId}/related/Submissions__r/view`;
                } else {
                    alert('Unsupported Record Type to add Submissions. Please contact Avocette for technical support.');    
                }
                // If multiple Submissions are being created, redirect to All Submissions Page.
                // If single Submission is being created, redirect to the new Submission page.
                window.location.href = submissionTypeValues.length > 1 ? allSubmissionsUrl : `/${response.getReturnValue()}`;
            } else {
                console.log(response);
                // Displaying the alert when call to apex was not successfull
                alert('Unable to create Submissions. Please contact Avocette for technical support.');
            }
        });
        
        // Enqueued it as the global action
        $A.enqueueAction(createSubmissionAction);
    }
    
})