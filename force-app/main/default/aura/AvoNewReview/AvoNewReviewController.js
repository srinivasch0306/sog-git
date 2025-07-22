/**
 * Controller for AvoNewReview.cmp.
 * @author Michael Chung
 * last modified by Michael Chung
 * @date 05/13/2021
 * 
 */

 ({
    // Function called on initial page loading to get data from server
    doInit : function(component, event, helper) {
        // Helper function to fetch account and related objects data
		// Setting the name of method in apex controller which we need to call
        var fetchData = component.get('c.getAllowedReviewTypes');
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
                
        		for (var i = 0; i < responseObj.reviewTypeList.length; i++) {
                    // Adding the label to display.
                    // The value (review Id) is also added to the Review Checkbox group item tag in the Lightning Component
                    items.push({
                        'label': responseObj.reviewTypeList[i].label, 
                        'value': responseObj.reviewTypeList[i].value
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
    // Handles creation of Review on the Permit on click
    handleCreation : function(component, event, helper) {
        component.set('v.loaded', !component.get('v.loaded'));
        var recordId = component.get('v.recordId');
        var sObjectName = component.get('v.sObjectName');
        var reviewTypeValues = component.get('v.reviewValues');    
        var createReviewAction = component.get('c.createReviews');

        let selectedMasterReviewListIds = [];

        // Looping through reviewTypeValues to put all the selected Review Ids into a new variable.
        reviewTypeValues.map((id) => {
            selectedMasterReviewListIds.push(id);
        });

        createReviewAction.setParams({
            recordId: recordId,
            masterReviewListIds: selectedMasterReviewListIds,
            sObjectName: sObjectName
        });
        
        createReviewAction.setCallback(this, function(response) {
        	// Getting the state of response to check it was successfull or not
            var state = response.getState();
            if(state === 'SUCCESS') {
                let allReviewsUrl = '';
                if(sObjectName === 'MUSW__Permit2__c') {
                    allReviewsUrl = `/lightning/r/MUSW__Review__c/${recordId}/related/MUSW__Reviews__r/view`;
                } else if(sObjectName === 'MUSW__Application2__c') {
                    allReviewsUrl = `/lightning/r/${recordId}/related/MUSW__Reviews1__r/view`
                } else {
                    alert('Unsupported Record Type to add Reviews. Please contact Avocette for technical support.');    
                }
                // If multiple Reviews are being created, redirect to All Reviews Page.
                // If single Review is being created, redirect to the new Review page.
                window.location.href = reviewTypeValues.length > 1 ? allReviewsUrl : `/${response.getReturnValue()}`;
            } else {
                // Displaying the alert when call to apex was not successfull
                alert('Unable to create Reviews. Please contact Avocette for technical support.');
            }
        });
        
        // Enqueued it as the global action
        $A.enqueueAction(createReviewAction);
    }
    
})