public class AvoFeeDataRetrieverController {
 // Method that returns the supported fee types for a specific Record ID.
    // The return value should be in a CSV format for multiple fee types
    @AuraEnabled
    public static String getAllowedFeeTypes(Id recordId, String sObjectName) {   
        String response = '';
        ResponseJSONWrapper wrapper = new ResponseJSONWrapper();
        List<MUSW__Master_Fee_List__c> feeTypes;
       
        Decimal criteria = 0;

        // step 1 - get a list of allowed fee types
        if(sObjectName == 'MUSW__Permit2__c') {
            // get the Permit Type and Id
            MUSW__Permit2__c permit = [
                SELECT Id, MUSW__Type__c,
                Avo_Estimated_Cost__c,
                Avo_Value_of_Sign__c,
                Avo_Type_Construction__c,
                Avo_Proposed_Occupancy__c,
                Avo_Fee_Calculation__c
                FROM MUSW__Permit2__c
                WHERE Id = :recordId
            ];

            String permitType = permit.MUSW__Type__c;
         
            criteria =  getCriteriaForTieredCalculation(sObjectName, permit, null);
           // system.debug('first'+criteria);

            // Get the Master Fee List items that include the Permit Type
            feeTypes = [
                SELECT Name, Id,
                Flat_Amount__c,
                High_Tier_Limit__c,
                Low_Tier_Limit__c,
                Fee_Calculation_Type__c
                FROM MUSW__Master_Fee_List__c 
                WHERE Avo_Permit_Type__c includes (:permitType)
                AND Active__c = true
                AND Manual_Creation_Allowed__c = true 
                AND Fee_Calculation_Type__c != 'Work Item Based'
                ORDER BY Name ASC 
            ];
        } 
        
       /* else if (sObjectName == 'MUSW__Application2__c') {
            // get the Application Type and Id
            MUSW__Application2__c application = [
                SELECT Id, MUSW__Type__c, Avo_Gross_Sq_Ft_of_Building_Construction__c
                FROM MUSW__Application2__c
                WHERE Id = :recordId
            ];

            String applicationType = application.MUSW__Type__c;

            criteria =  getCriteriaForTieredCalculation(sObjectName, null, application);

            // Get the Master Fee List items that include the Application Type
            feeTypes = [
                SELECT Name, Id,
                Flat_Amount__c,
                High_Tier_Limit__c, 
                Low_Tier_Limit__c,
                Fee_Calculation_Type__c
                FROM MUSW__Master_Fee_List__c 
                WHERE Avo_Planning_Application_Type__c includes (:applicationType)
                AND Active__c = true
                AND Manual_Creation_Allowed__c = true                
                AND Fee_Calculation_Type__c != 'Work Item Based'
                ORDER BY Name ASC 
            ];
        } */
        

        wrapper.id = recordId;
        wrapper.feeTypeList = new List<Option>();

        for(MUSW__Master_Fee_List__c feeType:feeTypes)
        {
            Option option = new Option();

            option.label = feeType.Name;
            option.value = feeType.Id;
            //Code updated by Siri due to facing issuess on 31-03-22
              option.flatamount=0;
           option.higeramount=0;
            option.lowamount=0;
            if (feeType.Flat_Amount__c!=null)
            {
                option.flatamount=feeType.Flat_Amount__c;
            }
            if (feeType.High_Tier_Limit__c!=null)
            {
                option.flatamount=feeType.High_Tier_Limit__c;
            }
            if (feeType.Low_Tier_Limit__c!=null)
            {
                option.flatamount=feeType.Low_Tier_Limit__c;
            }
          
            //end changes.
             //comented by siri for tiered free calculation type on 02-04-22(for avoiding estimated cost)
          /* if (feeType.Fee_Calculation_Type__c == 'Tiered') {

                system.debug('criteria12'+matchTieredCondition(sObjectName, criteria, feeType));
                if (matchTieredCondition(sObjectName, criteria, feeType)) {
                    wrapper.feeTypeList.Add(option);
                }
           } else {
               wrapper.feeTypeList.Add(option);   
           }*/
            //end
               wrapper.feeTypeList.Add(option);  
        }
        response = JSON.serialize(wrapper);

        return response;
    }  
   //Code updated by Siri due to facing issuess on 31-03-22
    @AuraEnabled
    public static  List<MUSW__Master_Fee_List__c> getfeetypedata(Id recordId)
    {
        List<MUSW__Master_Fee_List__c> feeTypes1;
        feeTypes1 = [
                SELECT Name, Id,
                Fee_Calculation_Type__c,
                Flat_Amount__c,
                High_Tier_Limit__c,
                Low_Tier_Limit__c
                FROM MUSW__Master_Fee_List__c 
                WHERE Id=:recordId
            ];
        return feeTypes1;
    }
    //end changes.

    @AuraEnabled
    // Helper function used to determine the record type of the fee being created. The return record type will determine a different layout and dropdown listbox values for the fee to be created
    public static Id getFeeRecordTypeId(String recordType) {

      
        try {
            Id recordTypeId = Schema.SObjectType.MUSW__Fee__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
                
            return recordTypeId;
        } catch (Exception ex) {
            System.Debug('Failed to retrieve fee record type: ' + recordType);
            return Schema.SObjectType.MUSW__Fee__c.getRecordTypeInfosByName().get('Avo Fee Default').getRecordTypeId();
        }
    }

    @AuraEnabled
    // Helper function used to get the Master Fee List item's Amount Value and convert it to an Integer
    public static List<MUSW__Master_Fee_List__c> getFeeListInformation(List<String> masterFeeListIds) {
        
        List<MUSW__Master_Fee_List__c> fees = [
            SELECT Base__c, 
            High_Tier_Limit__c,
            Low_Tier_Limit__c,
            Fee_Calculation_Type__c,
            Multiplier__c,
            Flat_Amount__c,
            Name,
            Record_Type__c,
            Related_Work_Item__r.Name,
            RecordTypeId,
            GL_Account__c
            FROM MUSW__Master_Fee_List__c
            WHERE Id = :masterFeeListIds
        ];
        return fees;
    }
    
    @AuraEnabled
    // Method used to create the selected Fee record
    public static Id createFee(Integer quantity, String recordId, String masterFeeListId, String sObjectName) {
        System.debug('quantity' +quantity);
        System.debug('recordId' +recordId);
        System.debug('masterFeeListId' +masterFeeListId);
        System.debug('sObjectName' +sObjectName);
        MUSW__Fee__c fee = new MUSW__Fee__c();
        Id convertedId = Id.valueOf(recordId);

        List<String> ids = new List<String>();
        ids.add(masterFeeListId);

        List<Integer> quantities = new List<Integer>();
        quantities.add(quantity);
        system.debug('quantities >>>' +quantities);
        system.debug('recordId >>>' +recordId);
        system.debug('ids >>>' +ids);
        system.debug('sObjectName >>>' +sObjectName);
        return createMultipleFees(quantities, recordId, ids, sObjectName);
    }

    @AuraEnabled
    // Method used to create the selected Fee record
    public static Id createMultipleFees(List<Integer> quantities, String recordId, List<String> masterFeeListIds, String sObjectName) {
        system.debug('Values are >>>> '+quantities+'-----'+recordId+'----'+masterFeeListIds+'-----'+sObjectName);
        Id returnId;
        List<MUSW__Fee__c> fees = new List<MUSW__Fee__c>();
        Id convertedId = Id.valueOf(recordId);
        system.debug('get record id'+recordId);
        system.debug('get id'+convertedId);

        List<MUSW__Master_Fee_List__c> selectedFees = getFeeListInformation(masterFeeListIds);
        List<MUSW__Work_Item__c> relatedWorkItems = new   List<MUSW__Work_Item__c>();
        system.debug('selectedFees'+selectedFees);
        if(sObjectName == 'MUSW__Permit2__c') { 
            relatedWorkItems = [
                SELECT Id, MUSW__Description__c, MUSW__Quantity__c, MUSW__Value_Per_Unit__c
                FROM MUSW__Work_Item__c
                WHERE MUSW__Permit2__c = :recordId
            ];
        system.debug('relatedWorkItems >>>>1' + relatedWorkItems);
        }
        system.debug('relatedWorkItems >>>>2' + relatedWorkItems);
       
        Integer index = 0;
        Integer quantity = 1;
        for(MUSW__Master_Fee_List__c fee : selectedFees) {
            quantity = quantities[index];
            System.debug('fee to create: ' + fee.Name + ' quantity: ' + quantity);
            
            index++;
            Decimal feeCalculation = 0; 
            //comented by siri for tiered free calculation type on 02-04-22(for avoiding estimated cost)
           /* if (fee.Fee_Calculation_Type__c == 'Tiered') {
                feeCalculation = 0;
            }*/
            //end
            
            if (fee.Fee_Calculation_Type__c == 'Work Item Based') {

                    system.debug('relatedWorkItems >>>> '+relatedWorkItems);
                    for(MUSW__Work_Item__c workItem: relatedWorkItems) {
                       if (fee.Related_Work_Item__r.Name == workItem.MUSW__Description__c) {
                            feeCalculation = workItem.MUSW__Value_Per_Unit__c * quantity;
                           
                       }else{
                           feeCalculation =0;
                       }
                    } 
              }
            else {

                if (fee.Flat_Amount__c != null) {
                    feeCalculation = fee.Flat_Amount__c * quantity;
                } else if (fee.Base__c != null) {
                    feeCalculation = fee.Base__c * quantity;
                }

            }

            if(sObjectName == 'MUSW__Permit2__c') {
                MUSW__Permit2__c permit = [
                    SELECT MUSW__Type__c,
                    Avo_Estimated_Cost__c,
                    Avo_Value_of_Sign__c,
                    Avo_Type_Construction__c,
                    Avo_Proposed_Occupancy__c,
                    Avo_Fee_Calculation__c,
                    L_F_Water_Main__c,
                    L_F_Sanitary_Sewer_Main__c
                    FROM MUSW__Permit2__c 
                    WHERE Id = :recordId
                ];

    //comented by siri for tiered free calculation type on 02-04-22(for avoiding estimated cost)
            /*    if (fee.Fee_Calculation_Type__c == 'Tiered') {

                    Decimal cost = getCriteriaForTieredCalculation(sObjectName, permit, null);

                    if (!matchTieredCondition(sObjectName, cost, fee)) {
                        continue;
                    }

                    feeCalculation = calculateTieredFee(sObjectName, cost, fee) * quantity;
                }*/ 
                //end
                //code add by siri for tiered free calculation as low tiered value
                if (fee.Fee_Calculation_Type__c == 'Tiered') {
                    
                     feeCalculation=(fee.Low_Tier_Limit__c) * quantity; 
                    
                }
                //end
               

                
                if (fee.Fee_Calculation_Type__c == 'Work Item Based') {
                    if (fee.Related_Work_Item__r.Name == null) {
                        feeCalculation = calculateCombinedWorkItemFee(permit, fee, relatedWorkItems);
                    } 
                }

                feeCalculation = handlePermitFeeSpecialCases(permit, fee, feeCalculation);
               Id recordTypeId = Schema.SObjectType.MUSW__Fee__c.getRecordTypeInfosByName().get('All').getRecordTypeId();
                MUSW__Fee__c newFee = new MUSW__Fee__c();
                   newFee.MUSW__Quantity__c         = quantity;
                    newFee.MUSW__Amount__c           = feeCalculation;
                    newFee.Master_Fee_List__c         = fee.Id;
                    newFee.RecordTypeId              = recordTypeId;
                    newFee.MUSW__Type__c             = fee.Name;
                    newFee.MUSW__Permit2__c          = convertedId;
                    newFee.Avo_GL_Account__c = fee.GL_Account__c;
                
                system.debug('newFee >>>>>' +newFee);
                fees.add(newFee);
                
            }
           //  return returnId;
          /*  if (sObjectName == 'MUSW__Application2__c') {
                MUSW__Application2__c application = [
                    SELECT MUSW__Type__c,
                    Avo_Number_of_Lots_in_Development__c,
                    Avo_Gross_Sq_Ft_of_Building_Construction__c,
                    Avo_Number_of_New_Lots__c,
                    Avo_Number_of_Lots__c
                    FROM MUSW__Application2__c 
                    WHERE Id = :recordId
                ];
                System.debug('name : ' + fee.Name);
               
               feeCalculation = handleApplicationFeeSpecialCases(application, fee, feeCalculation);
      //comented by siri for tiered free calculation type on 02-04-22(for avoiding estimated cost)           
             /*   if (fee.Fee_Calculation_Type__c == 'Tiered') {

                    Decimal cost = getCriteriaForTieredCalculation(sObjectName, null, application);

                    if (!matchTieredCondition(sObjectName, cost, fee)) {
                        continue;
                    }

                    feeCalculation = calculateTieredFee(sObjectName, cost, fee) * quantity;
                }
                //end
    
                MUSW__Fee__c newFee = new MUSW__Fee__c(
                    MUSW__Quantity__c        = quantity,
                    MUSW__Amount__c          = feeCalculation,
                  //  RecordTypeId             = fee.RecordTypeId,
                    MUSW__Type__c            = fee.Name,
                    MUSW__Application2__c    = convertedId,
                    Avo_GL_Account__c = fee.GL_Account__c
                );
                fees.add(newFee);
            } */
    
        }
       
       insert fees;
       
        // Return the selected Fee ID
        return fees.size() > 0 ? fees[0].id : recordId;
    }


    @AuraEnabled
    public static Decimal getCriteriaForTieredCalculation(String sObjectName, MUSW__Permit2__c permit, MUSW__Application2__c application) {
        if(sObjectName == 'MUSW__Permit2__c' ) {
            if (permit.MUSW__Type__c == 'Temporary Park Access Permit' ||
            (permit.MUSW__Type__c == 'Amendment or Extension of TPA' 
            && permit.Avo_Fee_Calculation__c == 'Estimated Value'
            || permit.Avo_Fee_Calculation__c == null
            ) ||
            (permit.MUSW__Type__c == 'Good Neighbor Access Permit' 
            && permit.Avo_Fee_Calculation__c == 'Estimated Value'
            || permit.Avo_Fee_Calculation__c == null
            )
            ) 
            {
                return  permit.Avo_Estimated_Cost__c;
            } 
    
          /*  if (permit.MUSW__Type__c == 'Sign Permit') {
                return permit.Avo_Value_of_Sign__c;
            }*/

         /*  if ((permit.MUSW__Type__c == 'Manufactured Home Permit' 
            || permit.MUSW__Type__c == 'Residential Building Permit') && permit.Avo_Fee_Calculation__c == 'Valuation') {

                List<string> applicableItems = new List<string>();

                if (permit.MUSW__Type__c == 'Manufactured Home Permit' ) {
                    applicableItems.add('Front Porch');
                    applicableItems.add('Landings/Porches/Decks - Front');
                    applicableItems.add('Landings/Porches/Decks - Rear');
                    applicableItems.add('Rear Porch');
                } else if (permit.MUSW__Type__c == 'Residential Building Permit') {
                    applicableItems.add('New/Proposed Carport/Garage');
                    applicableItems.add('New/Proposed Heated Areas');
                    applicableItems.add('New/Proposed Heated Basement');
                    applicableItems.add('New/Proposed Porch (Porch has a roof)');
                }
               
                System.debug('permit proposed occupancy: ' + permit.Avo_Proposed_Occupancy__c);
                System.debug('permit type of construction: ' + permit.Avo_Type_Construction__c);
                
                AggregateResult[] totalSqft = [
                    SELECT SUM(MUSW__Quantity__c)totalSqft
                    FROM MUSW__Work_Item__c
                    WHERE MUSW__Permit2__c = :permit.id 
                    AND MUSW__Description__c in :applicableItems
                ];

                List<MUSW__Master_Valuation_List__c> factors = [
                    SELECT Id, Use_Group__c, IA__c,
                    IB__c,
                    IIA__c,
                    IIB__c,
                    IIIA__c,
                    IIIB__c,
                    IV__c,
                    VA__c,
                    VB__c
                    FROM MUSW__Master_Valuation_List__c
                    WHERE Use_Group__c = :permit.Avo_Proposed_Occupancy__c
                    AND Avo_Active__c = true
                ];

                if (factors.size() > 0 && totalSqft.size() > 0) {
                    
                    Decimal sumAmount = (Decimal) totalSqft[0].get('totalSqft');
                    Decimal valuationFactor = (Decimal) factors[0].get(permit.Avo_Type_Construction__c + '__c');
                    System.debug('total: ' + sumAmount );
                    System.debug(' factor ' + valuationFactor);

                    if (sumAmount == null || valuationFactor == null)
                    {
                        return 0;
                    }

                    return sumAmount * valuationFactor;
                } else {
                    return 0;
                }

            }*/


        } 

       /* if (sObjectName == 'MUSW__Application2__c') {
            if (application.MUSW__Type__c == 'Plans Review') 
            {
                return  application.Avo_Gross_Sq_Ft_of_Building_Construction__c;
            } 
        }*/

        return 0;
    }

    @AuraEnabled
    public static boolean matchTieredCondition(String sObjectName, Decimal criteria, MUSW__Master_Fee_List__c feeType){

        if (criteria == null)
            criteria = 1;

        if(sObjectName == 'MUSW__Permit2__c' &&
        criteria > feeType.Low_Tier_Limit__c && criteria <= feeType.High_Tier_Limit__c) {
            return true;
        } 

        if (sObjectName == 'MUSW__Application2__c' &&
        criteria > feeType.Low_Tier_Limit__c && criteria <= feeType.High_Tier_Limit__c) {
            return true;
        }

        return false;
    }

    @AuraEnabled
    public static Decimal calculateTieredFee(String sObjectName, Decimal criteria, MUSW__Master_Fee_List__c fee) {
        Decimal result = 0;
        Decimal base = 0;
        Decimal lowerLimit = fee.Low_Tier_Limit__c;
        Decimal multiplier = fee.Multiplier__c;
      //Code updated by Siri due to facing issuess on 24-03-22
        if(criteria== null)
        {
              criteria = 0;
        }
        if(multiplier== null)
        {
              multiplier = 0;
        }
        //end
 
        if (lowerLimit == 0) {
            base = fee.Flat_Amount__c == null ? 0 :  Integer.valueOf( fee.Flat_Amount__c);
            
        } else {
            base = fee.Base__c;
           
        }

        if(sObjectName == 'MUSW__Permit2__c') {
            Decimal overCost = (criteria - lowerLimit) / 1000;
            Long divisionResult = overCost.round(System.RoundingMode.UP);
            
            System.debug('criteria ' + criteria + ' lowerLimit ' + lowerLimit);

            System.debug('base ' + base + ' division result ' + divisionResult + ' multipe: ' + multiplier);
            if(base== null)
        {
              base = 0;
        }
        if(multiplier== null)
        {
              multiplier = 0;
        }
            result = base + divisionResult * multiplier;
        }

        if (sObjectName == 'MUSW__Application2__c') {
            if (fee.Name == 'Fire Marshal Plan Review Submittal Fee') {
                if (lowerLimit == 0) {
                    result = base;
                } else {
                    result = criteria * multiplier;
                }
            }           
        }

        return result;
    }

    @AuraEnabled
    public static Decimal calculateCombinedWorkItemFee(MUSW__Permit2__c permit, MUSW__Master_Fee_List__c masterFee, 
    List <MUSW__Work_Item__c> relatedWorkItems) {
        Decimal result = 0;
    
        Decimal totalQuantity = 0;
        Decimal flatAmount = 0;

        for(MUSW__Work_Item__c workItem: relatedWorkItems) {
            totalQuantity += workItem.MUSW__Quantity__c == null ? 1 : workItem.MUSW__Quantity__c;
        }
        
        flatAmount = masterFee.Flat_Amount__c == null ? 0 : masterFee.Flat_Amount__c;
        
        result = totalQuantity * flatAmount;
           
        return result;
    }

    @AuraEnabled
    public static Decimal handlePermitFeeSpecialCases(MUSW__Permit2__c permit, MUSW__Master_Fee_List__c fee, Decimal originAmount) {
        Decimal feeCalculation = 0;
        
        if(fee.Name == 'Inspection Costs for Water' || fee.Name == 'Inspection Costs for Sanitary Sewer'){
            System.debug('PUD Fee Special Case');

            Decimal waterMainCost = permit.L_F_Water_Main__c == null ? 0 : permit.L_F_Water_Main__c;
            Decimal sanitaryMainCost = permit.L_F_Sanitary_Sewer_Main__c == null ? 0 : permit.L_F_Sanitary_Sewer_Main__c;

            Decimal waterCost = waterMainCost * 0.8;
            Decimal mainCost =  sanitaryMainCost * 1.85;
            Decimal totalCost = waterCost + mainCost;
          
            if (totalCost < 250)
            {
                totalCost = 250;
                Decimal waterNumber = permit.L_F_Water_Main__c == null || permit.L_F_Water_Main__c == 0 ? 1 : permit.L_F_Water_Main__c;
                Decimal mainNumber = permit.L_F_Sanitary_Sewer_Main__c == null || permit.L_F_Sanitary_Sewer_Main__c == 0 ? 1 : permit.L_F_Sanitary_Sewer_Main__c;
                Decimal totalNumber = waterNumber + mainNumber;

                if (fee.Name == 'Inspection Costs for Water') {
                    Decimal prorateCost = (totalCost - waterCost - mainCost) * waterNumber / totalNumber;
                    feeCalculation = waterCost + prorateCost.setScale(1, System.RoundingMode.CEILING);

                    System.debug('Rate cost: ' + prorateCost + ' cost ' + waterCost);
                }

                if (fee.Name == 'Inspection Costs for Sanitary Sewer') {
                    Decimal prorateCost = (totalCost - waterCost - mainCost) * mainNumber / totalNumber;
                    feeCalculation = mainCost + prorateCost.setScale(1, System.RoundingMode.FLOOR);

                    System.debug('Rate cost: ' + prorateCost + ' cost ' + mainCost);
                }

            } else {
                if (fee.Name == 'Inspection Costs for Water') {
                    feeCalculation = waterCost;
                }

                if (fee.Name == 'Inspection Costs for Sanitary Sewer') {
                    feeCalculation = mainCost;
                }
                
            }        
        } else {
            feeCalculation = originAmount;
        }

        return feeCalculation;
    }
    
    @AuraEnabled
    public static Decimal handleApplicationFeeSpecialCases(MUSW__Application2__c application, MUSW__Master_Fee_List__c fee, Decimal originAmount) {
        Decimal feeCalculation = 0;
        
        if(fee.Name == 'Preliminary Plat Lot Fee'){
            System.debug('Prelim Plat fee lot:' + application.Avo_Number_of_Lots__c);
            if(application.Avo_Number_of_Lots__c == null){
                feeCalculation = 0;
            }
            else{

                feeCalculation = 10 * application.Avo_Number_of_Lots__c;
            }
        } else if(fee.Name == 'Final Plat Lot Fee'){
            System.debug('Final Plat fee');
            if(application.Avo_Number_of_New_Lots__c == null){
                feeCalculation = 0;
            }
            else{

                feeCalculation = 30 * application.Avo_Number_of_New_Lots__c;

                if (feeCalculation >= 500) 
                {
                    feeCalculation = 500;
                }
            }
        } else {
            feeCalculation = originAmount;
        }

        return feeCalculation;
    }

    
    // Response JSON Wrapper Class
    public class ResponseJSONWrapper {
        public Id id;
        public List<Option> feeTypeList;
    }

    // Object used to hold label and Id value for the fees.
    public class Option {
        public String label;
        public String value;
        public Decimal flatamount;
        public Decimal higeramount;
        public Decimal lowamount;
        
    }
}