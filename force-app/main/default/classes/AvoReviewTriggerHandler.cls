/**
 * Description of class
 * trigger proxy for reviews
 * @author Jason Li
 * last modified by Yao Li
 * @date 07/19/2021
 *  
 */
public class AvoReviewTriggerHandler extends AvoTriggerHandler { 
    public override void afterUpdate() {
        for(MUSW__Review__c review : (List<MUSW__Review__c>) Trigger.new) { 

            if (review.MUSW__Status__c != null && review.AVO_Meter_Transaction__c == null){
                System.debug('justin was here');
                AvoProcessEngineReview avoProcessEngineReview = new AvoProcessEngineReview(review);
                avoProcessEngineReview.run(); 
            }
        }
    }     
    public override void beforeUpdate() {
        // Use map to avoid SOQL in loop
        /*
        for(MUSW__Review__c review : (List<MUSW__Review__c>) Trigger.new) { 
            String errorMessage = '';
            Boolean errorFound = false;
            if (review.MUSW__Type__c == 'Final Evaluation Review' && review.MUSW__Status__c == 'Completed' && review.MUSW__Permit2__c != null){
                Date triggerDate = Date.newInstance(2012, 7, 30);
                MUSW__Permit2__c permit = [SELECT Id, MUSW__Type__c, Permit_History__c, AVO_Permit_Type__c, AVO_Undocumented__c, AVO_Is_Conservation_Plan_required__c, AVO_Coastal_24__c, AVO_Suspension_Areas__c, AVO_Purpose_of_Water_Use__c, CreatedDate, SystemModStamp FROM MUSW__Permit2__c 
                                           WHERE Id = :review.MUSW__Permit2__c AND (MUSW__Type__c = 'Agricultural Water Withdrawal Application' OR MUSW__Type__c = 'Agricultural Water Withdrawal Permit' OR MUSW__Type__c = 'Revision')];
                
                List<AVO_Withdrawals__c> withdrawalList = [SELECT Id, Name, AVO_Type__c, 
                                                            AVO_Depth_ft__c, 
                                                            AVO_Casing_ft__c, 
                                                            AVO_Diameter_in__c, 
                                                            AVO_Permit_gpm__c,
                                                            AVO_Aquifer_ID__c,
                                                            AVO_Well_Location__c, 
                                                            AVO_Pump_Test__c,
                                                            AVO_Lithology__c, 
                                                            AVO_Well_Closed__c, 
                                                            AVO_Well_Data_On_File__c, 
                                                            AVO_Status__c,
                                                            AVO_WTP_Well__c, 
                                                            AVO_Critical_LOC__c, 
                                                            AVO_Well_Pad__c,
                                                            AVO_Installer_ID__c, 
                                                            AVO_Date_Installed__c, 
                                                            AVO_SourceType__c,
                                                            AVO_Well_to_Pond_Pump__c, 
                                                            AVO_Surface_Water_Source__c, 
                                                            AVO_Withdrawal_Location__c,
                                                            AVO_Refill__c,
                                                            AVO_Wells_Refilling__c,
                                                            AVO_SW_Pumps_Refilling__c, 
                                                            AVO_Low_Flow_cfs__c, 
                                                            AVO_SwAppliedDt__c,
                                                            AVO_Low_Flow_gpm__c,
                                                            AVO_Low_Flow_Information__c,
                                                            CreatedDate, 
                                                            SystemModStamp
                                                            FROM AVO_Withdrawals__c 
                                                            WHERE AVO_Permit__c = :review.MUSW__Permit2__c AND 
                                                            (AVO_Type__c = 'Ground Water Withdrawal Application' OR AVO_Type__c = 'Surface Water Withdrawal Application' OR AVO_Type__c = 'Ground Water Withdrawal' OR AVO_Type__c = 'Surface Water Withdrawal')];  
                
                for (AVO_Withdrawals__c withdrawal : withdrawalList) {
                    if (withdrawal.AVO_Type__c == 'Ground Water Withdrawal Application') {
                        if (permit.AVO_Permit_Type__c == 'Groundwater' || permit.AVO_Permit_Type__c == 'Well to Pond') {
                            Boolean groundWaterFieldMissing = false;
                            String missingFieldNames = '';
                            if (withdrawal.AVO_Depth_ft__c == null) {
                                missingFieldNames += 'Depth (ft), ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_Casing_ft__c == null) {
                                missingFieldNames += 'Casing (ft), ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_Diameter_in__c == null) {
                                missingFieldNames += 'Diameter (in), ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_Permit_gpm__c == null) {
                                missingFieldNames += 'Permit gpm, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Aquifer_ID__c)) {
                                missingFieldNames += 'Aquifer ID, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_Well_Location__c == null) {
                                missingFieldNames += 'Well Location, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Pump_Test__c)) {
                                missingFieldNames += 'Pump Test, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Lithology__c)) {
                                missingFieldNames += 'Lithology, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Well_Closed__c)) {
                                missingFieldNames += 'Well Closed, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Well_Data_On_File__c)) {
                                missingFieldNames += 'Well Data On File, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Status__c)) {
                                missingFieldNames += 'Status, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_WTP_Well__c)) {
                                missingFieldNames += 'WTP Well, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Critical_LOC__c)) {
                                missingFieldNames += 'Critical LOC, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Well_Pad__c)) {
                                missingFieldNames += 'Well Pad, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Installer_ID__c)) {
                                missingFieldNames += 'Installer ID, ';
                                errorFound = true;
                                groundWaterFieldMissing = true;
                            }
                            if (groundWaterFieldMissing) {
                                errorMessage = errorMessage + 'Please fill out these missing Fields: ' + missingFieldNames + 'on Withdrawal ' + withdrawal.Name + '. ';
                            }
                        }
                        
                    // Else it's a Surface Water Withdrawal Application
                    } 
                    else if (withdrawal.AVO_Type__c == 'Surface Water Withdrawal Application') {
                        if (permit.AVO_Permit_Type__c == 'Surface Water' || permit.AVO_Permit_Type__c == 'Well to Pond') {
                            Boolean surfaceWaterFieldMissing = false;
                            String missingFieldNames = '';
                            if (withdrawal.AVO_Date_Installed__c == null) {
                                missingFieldNames += 'Date Installed, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_SourceType__c)) {
                                missingFieldNames += 'SourceType, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_Permit_gpm__c == null) {
                                missingFieldNames += 'Permit gpm, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Well_to_Pond_Pump__c)) {
                                missingFieldNames += 'Well to Pond Pump, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Surface_Water_Source__c)) {
                                missingFieldNames += 'Surface Water Source, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_Withdrawal_Location__c == null) {
                                missingFieldNames += 'Withdrawal Location, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (String.isBlank(withdrawal.AVO_Refill__c)) {
                                missingFieldNames += 'Refill, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_Wells_Refilling__c == null) {
                                missingFieldNames += 'Wells Refilling, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_SW_Pumps_Refilling__c == null) {
                                missingFieldNames += 'SW Pumps Refilling, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_Low_Flow_cfs__c == null) {
                                missingFieldNames += 'Low Flow cfs, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (withdrawal.AVO_SwAppliedDt__c == null) {
                                missingFieldNames += 'SwAppliedDt, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }  
                            if (String.isBlank(withdrawal.AVO_Status__c)) {
                                missingFieldNames += 'Status, ';
                                errorFound = true;
                                surfaceWaterFieldMissing = true;
                            }
                            if (surfaceWaterFieldMissing) {
                                errorMessage = errorMessage + 'Please fill out these missing Fields: ' + missingFieldNames + 'on Withdrawal ' + withdrawal.Name + '. ';
                            }
                        }                           
                    }
                        
                    if (permit.AVO_Permit_Type__c == 'Surface Water' && withdrawal.AVO_Type__c == 'Surface Water Withdrawal Application') {
                        if ((withdrawal.AVO_Low_Flow_cfs__c > 0 || withdrawal.AVO_Low_Flow_gpm__c > 0) && String.isBlank(withdrawal.AVO_Low_Flow_Information__c)) {
                            MUSW__Submission__c lowFlowInformationSubmission = [SELECT Id, MUSW__Submission_DateTime__c FROM MUSW__Submission__c WHERE MUSW__Permit2__c = :permit.Id AND Name = 'Low Flow Guidance' LIMIT 1];
                            if (lowFlowInformationSubmission.MUSW__Submission_DateTime__c != null) {
                                errorFound = true;
                                errorMessage = errorMessage + 'Low Flow Information cannot be blank on Withdrawal ' + withdrawal.Name + '. ';
                            }
                        }
                    }
                        
                    if (withdrawal.AVO_Type__c == 'Surface Water Withdrawal Application' || withdrawal.AVO_Type__c == 'Surface Water Withdrawal') {
                        if (!String.isBlank(withdrawal.AVO_Surface_Water_Source__c)) {
                            String surfaceWaterSource = withdrawal.AVO_Surface_Water_Source__c;
                            surfaceWaterSource = surfaceWaterSource.toLowerCase();
                            if (surfaceWaterSource == 'unknown' || surfaceWaterSource == 'unnamed' || surfaceWaterSource == 'un-named' || surfaceWaterSource == 'unspecified') {
                                errorFound = true;
                                errorMessage = errorMessage + 'You must correct Surface Water Source name with known or standard name.  Standard Source names include given name on file or Pond 1, Pond 2, etc. on Withdrawal ' + withdrawal.Name + '. ';
                            }    
                        }
                       
                    }
                    
                    if ((withdrawal.AVO_Type__c == 'Surface Water Withdrawal Application' || withdrawal.AVO_Type__c == 'Surface Water Withdrawal') && 
                        withdrawal.AVO_SourceType__c == 'Flowing Stream or Canal to such' && withdrawal.AVO_Wells_Refilling__c > 0 && withdrawal.AVO_Status__c == 'Active') {
                        errorFound = true;
                        errorMessage = errorMessage + 'Remove Pond Refill Source on Withdrawal ' + withdrawal.Name + '. ';
                    }
                
                    if (!String.isBlank(withdrawal.AVO_Surface_Water_Source__c)) {
                        if ((withdrawal.AVO_Type__c == 'Surface Water Withdrawal Application' || withdrawal.AVO_Type__c == 'Surface Water Withdrawal') && 
                            withdrawal.AVO_SourceType__c == 'Flowing Stream or Canal to such' && withdrawal.AVO_Surface_Water_Source__c.containsIgnoreCase('pond') && withdrawal.AVO_Status__c == 'Active') {
                            errorFound = true;
                            errorMessage = errorMessage + 'Enter Correct Source Name on Withdrawal ' + withdrawal.Name + '. ';
                        }
                        
                    }
                  
                    
                    if ((withdrawal.AVO_Type__c == 'Surface Water Withdrawal Application' || withdrawal.AVO_Type__c == 'Surface Water Withdrawal') && 
                        withdrawal.AVO_Status__c == 'Active' && (withdrawal.AVO_Low_Flow_cfs__c == null || withdrawal.AVO_Low_Flow_gpm__c == null)) {
                        errorFound = true;
                        errorMessage = errorMessage + 'Data Entry Error, LF CFS, and/or LF gpm is Null on Withdrawal ' + withdrawal.Name + '. ';
                    }
                    
                   
                    if (!String.isBlank(withdrawal.AVO_Surface_Water_Source__c)) {
                        if ((withdrawal.AVO_Type__c == 'Surface Water Withdrawal Application' || withdrawal.AVO_Type__c == 'Surface Water Withdrawal') && 
                            (withdrawal.AVO_SourceType__c == 'Springs' || withdrawal.AVO_SourceType__c == 'Flowing Stream or Canal to such') && 
                            (withdrawal.AVO_Surface_Water_Source__c.containsIgnoreCase('pond') || withdrawal.AVO_Surface_Water_Source__c.containsIgnoreCase('lake'))) {
                            errorFound = true;
                            errorMessage = errorMessage + 'Source Type is Pond and Source Name not matching correctly on Withdrawal ' + withdrawal.Name + '. ';
                        }
                    }
                    
                    
                    //!!!!
                    if (!String.isBlank(permit.AVO_Suspension_Areas__c)) {
                        if ((withdrawal.AVO_Type__c == 'Ground Water Withdrawal Application' || withdrawal.AVO_Type__c == 'Ground Water Withdrawal') && 
                            withdrawal.AVO_Aquifer_ID__c == 'Floridan' && withdrawal.AVO_Status__c == 'Active' && permit.AVO_Suspension_Areas__c.toLowerCase() == 'gw & sw' &&
                            (withdrawal.CreatedDate.date() >= triggerDate || withdrawal.SystemModStamp.date() >= triggerDate)) {
                            errorFound = true;
                            errorMessage = errorMessage + '2012 Post-Suspension New or Modified Floridan Well Permit in the Suspension Areas on Withdrawal ' + withdrawal.Name + '. ';
                        }    
                    }
                    
                    
                    
                        
                }
                
                if (!String.isBlank(permit.AVO_Suspension_Areas__c)) {
                    if (permit.AVO_Suspension_Areas__c.toLowerCase() == 'gw & sw' || permit.AVO_Suspension_Areas__c.toLowerCase() == 'sw only') {
                        List<MUSW__Submission__c> irrigationEfficiencyForms = [SELECT Id, Name, MUSW__Submission_DateTime__c FROM MUSW__Submission__c WHERE MUSW__Permit2__c = :permit.Id AND Name = 'Irrigation Efficiency Certification Form'];
                        if (!irrigationEfficiencyForms.isEmpty()) {
                            MUSW__Submission__c irrigationEfficiencyForm = irrigationEfficiencyForms[0];
                            if (irrigationEfficiencyForm.MUSW__Submission_DateTime__c == null) {
                                errorFound = true;
                                errorMessage = errorMessage + 'Need Irrigation Efficiency Certification Form on file for this permit. ';
                            }
                        }
                    }    
                }
                
                if (!String.isBlank(permit.AVO_Coastal_24__c)) {
                    if (permit.AVO_Coastal_24__c.startsWithIgnoreCase('c') || permit.AVO_Coastal_24__c.startsWithIgnoreCase('r')) {
                        if (permit.AVO_Purpose_of_Water_Use__c != null) {
                            List<String> purposeSelections = permit.AVO_Purpose_of_Water_Use__c.split(';');
                            if (purposeSelections.contains('Irrigation Golf Course')) {
                                List<MUSW__Submission__c> feasibilityStudies = [SELECT Id, Name, MUSW__Submission_DateTime__c FROM MUSW__Submission__c WHERE MUSW__Permit2__c = :permit.Id AND Name = 'Water Reuse Feasibility Study'];
                                if (!feasibilityStudies.isEmpty()) {
                                    MUSW__Submission__c feasibilityStudy = feasibilityStudies[0];
                                    if (feasibilityStudy.MUSW__Submission_DateTime__c == null) {
                                        errorFound = true;
                                        errorMessage = errorMessage + 'Need Reuse Water Fesibility Study on file. ';
                                    }
                                }
                            }
                        }
                    }
                    
                }
                
              
                
                if (permit.MUSW__Type__c == 'Agricultural Water Withdrawal Permit') {
                    Task gisPermitMappingTask = [SELECT Id, Status FROM Task WHERE WhatId = :permit.Id AND Subject = 'GIS Permit Mapping' LIMIT 1];
                    if (permit.Permit_History__c == 'Relinquish Permit') {
                        Task ownershipTask = [SELECT Id, Status FROM Task WHERE WhatId = :permit.Id AND Subject = 'Ownership Validation and Update' LIMIT 1];
                        if (gisPermitMappingTask.Status != 'Completed' || ownershipTask.Status != 'Completed') {
                            errorFound = true;
                            errorMessage = errorMessage + 'Please complete the GIS Permit Mapping and Ownership Validation and Update Tasks on the permit. ';
                        }
                    } else {
                        if (gisPermitMappingTask.Status != 'Completed') {
                            errorFound = true;
                            errorMessage = errorMessage + 'Please complete the GIS Permit Mapping Task on the permit. ';
                        }
                    }
                }
                 
            }
            else if (review.MUSW__Type__c == 'Form Assessment Review' && review.MUSW__Status__c == 'Completed' && review.MUSW__Permit2__c != null) {
                MUSW__Permit2__c permit = [SELECT Id, MUSW__Type__c  FROM MUSW__Permit2__c 
                                           WHERE Id = :review.MUSW__Permit2__c AND (MUSW__Type__c = 'Agricultural Water Withdrawal Application' OR MUSW__Type__c = 'Agricultural Water Withdrawal Permit' OR MUSW__Type__c = 'Revision')];
                if (permit.MUSW__Type__c == 'Revision') {
                    Task gisPermitMappingTask = [SELECT Id, Status FROM Task WHERE WhatId = :permit.Id AND Subject = 'GIS Permit Mapping' LIMIT 1];
                    if (gisPermitMappingTask.Status != 'Completed') {
                        errorFound = true;
                        errorMessage = errorMessage + 'Please complete the GIS Permit Mapping Task on the permit. ';
                    }
                }
            }
            if (errorFound) {
                review.addError(errorMessage);
            }
        }
*/
    }  
}