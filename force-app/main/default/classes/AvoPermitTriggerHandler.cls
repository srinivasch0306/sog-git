/**
 * Description of class
 * trigger proxy for reviews
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/24/2021
 *  
 */
public class AvoPermitTriggerHandler extends AvoTriggerHandler { 

    public override void beforeInsert() {
        for(MUSW__Permit2__c permit : (List<MUSW__Permit2__c>) Trigger.new) { 
           System.debug('before');
           System.debug(permit);
           //moveToSubmittedOnBackofficeCreation(permit);
           //setParkingPermitApplicant(permit);
           setInstanceAccountForPayment(permit);
        }
    }

    public override void afterInsert() {
        for(MUSW__Permit2__c permit : (List<MUSW__Permit2__c>) Trigger.new) { 
            if (permit.Avo_Skip_Process_Engine__c == false) {
                AvoProcessEnginePermit avoProcessPermitEngine = new AvoProcessEnginePermit(permit);
                avoProcessPermitEngine.createPostTransitionActions();
                if (avoProcessPermitEngine.hasError() == true){
                    permit.addError(avoProcessPermitEngine.getError());
                }
            }
          
            System.Debug('trigger from after insert');                  
            handlePermitSubmittedStatusAutoTransition(permit);
        }
    }

    public override void beforeUpdate() {
        for(MUSW__Permit2__c permit : (List<MUSW__Permit2__c>) Trigger.new) { 
            MUSW__Permit2__c oldPermit = (MUSW__Permit2__c)Trigger.oldMap.get(permit.Id);
            string oldPermitStatus =  oldPermit.MUSW__Status__c;
            string newPermitStatus =  permit.MUSW__Status__c;
            //setParkingPermitApplicant(permit);
            System.debug('From ' + oldPermit.MUSW__Status__c + ' ' + permit.MUSW__Status__c);
            if (permit.MUSW__Status__c <> oldPermit.MUSW__Status__c){
                handlePendingStatusSubmissions(permit);
                // permit status has changed
                AvoProcessEnginePermit avoProcessPermitEngine = new AvoProcessEnginePermit(permit);

                system.debug('started the process engine from a permit');
                if (avoProcessPermitEngine.isStatusChangeAllowed() == false){
                     permit.addError('Change from [' + oldPermitStatus + '] to [' + newPermitStatus + '] is not allowed.' + avoProcessPermitEngine.getError());
                }else {
                    system.debug('all conditions are met, starting creating post transition actions');
                    avoProcessPermitEngine.createPostTransitionActions();
                }

            }  
        }
    }   

    public override void afterUpdate() {
        for(MUSW__Permit2__c permit : (List<MUSW__Permit2__c>) Trigger.new) { 
            MUSW__Permit2__c oldPermit = (MUSW__Permit2__c)Trigger.oldMap.get(permit.Id);
           
            if (permit.MUSW__Parcel__c != null && permit.MUSW__Parcel__c != oldPermit.MUSW__Parcel__c) {
                Id parcelId = permit.MUSW__Parcel__c;

                System.debug('parcelId '+ permit.MUSW__Parcel__c);
                
                if (parcelId != null) {
                    try {
                        // get the parcel for lookup in the GIS system
                        System.debug('inside try parcelId ' + parcelId);
                        MUSW__Parcel__c parcel = [
                            SELECT Id, Name, MUSW__Parcel_Number2__c, External_Parcel__c, UNIQUEID__c
                            FROM MUSW__Parcel__C 
                            WHERE Id = :parcelId
                        ];
                        // get the info from the gis system and add it to the permit
                        //AvoAccGis.addGisDataToPermit(parcel.MUSW__Parcel_Number2__c, permit.Id);
    
                    }  catch(Exception e){ 
                        // there is likely no parcel that exists in the parcels yet.
                        //new AvoLogException().Log(new AvoCustomException(e));
                    }
                }
            }

            if (permit.MUSW__Status__c <> oldPermit.MUSW__Status__c){
                handlePermitSubmittedStatusAutoTransition(permit);
                //handlePUDFees(permit);
            }
        }
    }
    

    public void moveToSubmittedOnBackofficeCreation(MUSW__Permit2__c permit) {
        System.debug('Move status');
        System.debug(permit);
       
        //9526: Pending Status is not reelevant, move to submitted when creating from back office
        User userDetails =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id=:permit.OwnerId ];
        System.debug('Profile name: ' + userDetails.Profile.Name);
        System.debug('Profile name Index: ' + userDetails.Profile.Name.indexOf('Community'));
        
        if (!string.isBlank(userDetails.Profile.Name) && userDetails.Profile.Name.indexOf('Community') == -1 ) {

            if (permit.MUSW__Type__c == 'Land Disturbance' ||
            permit.MUSW__Type__c == 'Stormwater Management' ||
            permit.MUSW__Type__c == 'Right of Way Encroachment' ||
            permit.MUSW__Type__c == 'Roadway Construction' ||
            permit.MUSW__Type__c == 'Non-Residential Driveway' ||
            permit.MUSW__Type__c == 'Floodplain Construction') {
                permit.MUSW__Status__c = 'In Review';
            } else {
                permit.MUSW__Status__c = 'Submitted';
            }

        }
    }
    
    public void handlePendingStatusSubmissions(MUSW__Permit2__c permit) {
        if (permit.MUSW__Status__c == 'Pending') {
            List<MUSW__Submission__c> submissions = [
                SELECT Id, (SELECT Id, Title from CombinedAttachments) 
                from MUSW__Submission__c
                Where MUSW__Permit2__c = :permit.id
            ];

            if (submissions.size() > 0) {
                for(MUSW__Submission__c item: submissions) {
                    if (item.CombinedAttachments.size() == 0) {
                        delete item;
                    }
                }
            }
        }
    }

    public void setInstanceAccountForPayment(MUSW__Permit2__c permit) {
        if (permit.MUSW__Applicant__r.AccountId != null && permit.MUSW__Account__c == null) {
            permit.MUSW__Account__c = permit.MUSW__Applicant__r.AccountId;
        }
    }

    public void handlePermitSubmittedStatusAutoTransition(MUSW__Permit2__c permit) {

        MUSW__Permit2__c queryPermit = [SELECT MUSW__Status__c
        FROM MUSW__Permit2__c
        WHERE Id = :permit.id
        LIMIT 1];

        if (queryPermit != null) {

            String applicablePermitTypes = 'Building Relocation Permit;Manufactured Home Permit;Demolition Permit;Electrical Permit;Plumbing Permit;Gas Permit;HVAC Permit;Multi-Family Building Permit;' +
            'Commercial Building Permit;Residential Building Permit;Fireplace Stove;Water and Sewer Permit;Secured Structure Permit;Sign Permit;Swimming Pool Permit;' +
            'Temporary Fire Hydrant;Temporary Secured Structure Permit;Temporary Tent;Multi-Permit Application;PUD Utility Extension;Small Cell;Residential Driveway';

            System.Debug('Passed in: ' + permit.MUSW__Type__c + ' ' + applicablePermitTypes.contains(permit.MUSW__Type__c));
            
            if (applicablePermitTypes.contains(permit.MUSW__Type__c) && permit.MUSW__Status__c == 'Submitted') {
                queryPermit.MUSW__Status__c = 'Initial Review';
                update queryPermit;
            }
        }
    }

        
    }