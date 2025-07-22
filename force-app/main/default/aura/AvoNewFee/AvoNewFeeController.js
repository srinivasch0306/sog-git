/**
 * Controller for AvoNewFee.cmp.
 * @author Michael Chung
 * last modified by Michael Chung
 * @date 05/21/2021
 * 
 */

 ({
    // Function called on initial page loading to get data from server
    doInit : function(component, event, helper) {
        // Helper function to fetch account and related objects data
		// Setting the name of method in apex controller which we need to call
        var fetchData = component.get('c.getAllowedFeeTypes');
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
                
        		for (var i = 0; i < responseObj.feeTypeList.length; i++) {
                    // Adding the label to display.
                    // The value (fee Id) is also added to the Fee Checkbox group item tag in the Lightning Component
                    items.push({
                        'label': responseObj.feeTypeList[i].label, 
                        'value': responseObj.feeTypeList[i].value
                    });
        		}

                // Set the Items into the Select Drop Down group.
       			component.set("v.options", items);
                // Set the first item as the default selected Fee
                component.find("select").set("v.value", items[0].value);
            } else {
                // Displaying the alert when call to apex was not successfull
                alert('Unable to fetch data from server, contact Avocette for technical support.');
            }
        });
        
        // Enqueued it as the global action
        $A.enqueueAction(fetchData);
    },
    // Handles creation of Fee on the Permit/Application on click
    handleCreation : function(component, event, helper) {
        component.set('v.loaded', !component.get('v.loaded'));
        var recordId = component.get('v.recordId');
        var sObjectName = component.get('v.sObjectName'); 
        var createFeeAction = component.get('c.createFee');

        // get the ID and quantity from the dropdown and text field
        let masterFeeListId = component.find("select").get('v.value');
        let quantityString = component.find("quantity").get("v.value");

        if (isNaN(quantityString) || !Number.isInteger(parseFloat(quantityString))) {
            component.set('v.loaded', !component.get('v.loaded'));
            alert('Invalid quantity value.');
            return;
        }

        let quantity = parseInt(component.find("quantity").get("v.value"));

        createFeeAction.setParams({
            quantity: quantity,
            recordId: recordId,
            masterFeeListId: masterFeeListId,
            sObjectName: sObjectName
        });
        
        createFeeAction.setCallback(this, function(response) {
        	// Getting the state of response to check it was successfull or not
            var state = response.getState();
            if(state === 'SUCCESS') {
                window.location.href = `/${response.getReturnValue()}`;
            } else {
                // Displaying the alert when call to apex was not successfull
                alert('Unable to create Fees. Please contact Avocette for technical support.');
            }
        });
        
        // Enqueued it as the global action
        $A.enqueueAction(createFeeAction);
    }
    
})