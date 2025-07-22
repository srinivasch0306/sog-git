({
    // Function called on initial page loading to get data from server
    doInit : function(component, event, helper) {
        // Helper function to fetch account and related objects data
		// Setting the name of method in apex controller which we need to call
        var fetchData = component.get('c.getAllowedInspectionTypes');
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
                
        		for (var i = 0; i < responseObj.inspectionTypeList.length; i++) {
                    // Adding the label to display.
                    // The value (inspection Id) is also added to the Inspection Checkbox group item tag in the Lightning Component
                    items.push({
                        'label': responseObj.inspectionTypeList[i].label, 
                        'value': responseObj.inspectionTypeList[i].value
                    });
        		}
                //console.log('data>>' +items);

                // Set the Items into the Checkbox group.
       			component.set("v.options", items);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + 
                                 errors[0].message);
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Something has gone wrong!",
                            "message": errors[0].message,
                            closeCallback: function() {
                               // alert('You closed the alert!');
                            }
                        });
                    }
                } else {
                    alert("Unknown error");
                }
            } else {
                console.log('state:' + state);
                // Displaying the alert when call to apex was not successfull
                alert('Unable to fetch data from server, contact Avocette for technical support.');
            }
        });
        
        // Enqueued it as the global action
        $A.enqueueAction(fetchData);
    },
    // Handles creation of Inspection on the Permit on click
    handleCreation : function(component, event, helper) {
        component.set('v.loaded', !component.get('v.loaded'));
        var recordId = component.get('v.recordId');
        var sObjectName = component.get('v.sObjectName');
        var inspectionTypeValues = component.get('v.inspectionValues');    
        var createInspectionAction = component.get('c.createInspections');

        let selectedMasterInspectionListIds = [];

        // Looping through inspectionTypeValues to put all the selected Inspection Ids into a new variable.
        inspectionTypeValues.map((id) => {
            selectedMasterInspectionListIds.push(id);
        });

        createInspectionAction.setParams({
            recordId: recordId,
            masterInspectionListIds: selectedMasterInspectionListIds,
            sObjectName: sObjectName
        });
        
        createInspectionAction.setCallback(this, function(response) {
        	// Getting the state of response to check it was successfull or not
            var state = response.getState();
            if(state === 'SUCCESS') {
                let allInspectionsUrl = '';
                if(sObjectName === 'MUSW__Permit2__c') {
                    allInspectionsUrl = `/lightning/r/MUSW__Inspection__c/${recordId}/related/MUSW__Inspections__r/view`;
                } else if(sObjectName === 'MUSW__Application2__c') {
                    allInspectionsUrl = `/lightning/r/MUSW__Application2__c/${recordId}/related/Inspections__r/view`;
                } else if (sObjectName === 'MUSW__Complaint2__c') {
                    allInspectionsUrl = `/lightning/r/MUSW__Inspection__c/${recordId}/related/MUSW__Inspections__r/view`;
                }else if (sObjectName === 'MUSW__Violation__c') {
                    allInspectionsUrl = `/lightning/r/MUSW__Violation__c/${recordId}/related/Inspections__r/view`;
                } 
                 else {
                    alert('Unsupported Record Type to add Inspections. Please contact Avocette for technical support.');    
                }
                // If multiple Inspections are being created, redirect to All Inspections Page.
                // If single Inspection is being created, redirect to the new Inspection page.
                window.location.href = inspectionTypeValues.length > 1 ? allInspectionsUrl : `/${response.getReturnValue()}`;
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // log the error passed in to AuraHandledException
                        console.log("Error message: " + 
                                 errors[0].message);
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Something has gone wrong!",
                            "message": errors[0].message,
                            closeCallback: function() {
                               // alert('You closed the alert!');
                            }
                        });
                    }
                } else {
                    alert("Unknown error");
                }
            }
            else {
                // Displaying the alert when call to apex was not successfull
                alert('Unable to create Inspections. Please contact Avocette for technical support.');
            }
        });
        
        // Enqueued it as the global action
        $A.enqueueAction(createInspectionAction);
    }
    
})