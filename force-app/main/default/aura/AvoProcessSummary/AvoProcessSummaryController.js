({
    doInit: function (component, event, helper) {
        
        let btnlabel = event.getSource().get("v.label");
        
        if (btnlabel == "Refresh"){
			component.set("v.loaded",true);            
        }
        var sObjectName = component.get('v.sObjectName');
        var recordId = component.get('v.recordId');
        
        var fetchData = component.get('c.GetProcessSummary');

        fetchData.setParams({
            recordId: recordId,
            objectName: sObjectName
        });
        fetchData.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS') {
                component.set("v.items",response.getReturnValue());
                component.set("v.loaded",false)
            } else {
                alert('Unable to fetch data from server, contact Avocette for technical support.');
            } 
        });        
        
        // Enqueued it as the global action
        $A.enqueueAction(fetchData);
    },
     doRefresh : function(component, event, helper) {
      component.set("v.loaded",true);
      window.setTimeout(
     	$A.getCallback(function() {
          	component.set("v.loaded",false)
     	}), 500);
    	// component.set("v.loaded",false);
    }
});