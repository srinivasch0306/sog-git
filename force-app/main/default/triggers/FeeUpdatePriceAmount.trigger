/*
* Trigger to update Price per Unit and Amount on Fee insert or update when the Product field is entered or changed
*/
trigger FeeUpdatePriceAmount on MUSW__Fee__c (before insert, before update) {
    
    //Check if there is an active Default Price book
    Fee_Schedule_Settings__c setting = Fee_Schedule_Settings__c.getValues('Default');
    String pricebookName = '';
    Pricebook2[] pbs = new Pricebook2[]{}; 

    if(setting != null && setting.isActive__c)
    {
        pricebookName = String.valueOf(setting.get('Default_Pricebook__c'));
        
        //Check whether the pricebook exists
        pbs = [SELECT Id From Pricebook2 
                WHERE Name =:pricebookName
                AND IsActive = true];
    }
        
    if(pbs.size()>0 || Test.isRunningTest())
    {
        Id pbId = Test.isRunningTest() ? Test.getStandardPricebookId() : pbs[0].Id;
        //Updating Fee's Price per Unit and Amount when a Fee record with Product and no Amount is inserted
        if(trigger.isinsert){
            for(MUSW__Fee__c fee:trigger.new){
                if(fee.Product__c != null && fee.MUSW__Amount__c == null){
                    setFeePriceAndAmount(fee,pbId);
                }
            }
        }
        
        //Updating Fee's Price per Unit and Amount when a Fee record's Product value is changed
        if(trigger.isupdate){
            for(MUSW__Fee__c fee:trigger.new){
                if(fee.Product__c != null){
                    if(fee.Product__c!=trigger.oldmap.get(fee.id).Product__c){
                        setFeePriceAndAmount(fee, pbId);
                    }
                }
            }
        }
    } 
    else
    {
        if(trigger.isupdate) {
            for(MUSW__Fee__c fee:trigger.new){
                if(fee.Product__c != null){
                    resetFeePriceAndAmount(fee);
                }
            }
        }
    }
    

    /* 
    * Retrieve the Unit Price from the Pricebook Entry for the product related to the fee and update the
    * Price per unit and Amount on the Fee record
    */
    void setFeePriceAndAmount(MUSW__Fee__c fee, Id pricebookId) {
        Pricebookentry[] pbes = [SELECT UnitPrice 
                        FROM Pricebookentry 
                        WHERE PriceBook2Id=:pricebookId 
                        AND Product2Id=:fee.Product__c
                        AND IsActive = true];
        if(pbes.size() > 0 && fee.MUSW__Quantity__c != null)
        {
            fee.MUSW__Price_Per_Unit__c = pbes[0].UnitPrice;
            fee.MUSW__Amount__c = fee.MUSW__Quantity__c * fee.MUSW__Price_Per_Unit__c;
        }
        else
        {
            if(trigger.isupdate) {
                resetFeePriceAndAmount(fee);
            }
        }
    }
    
    /* 
    * Reset the Price per unit and Amount on the Fee record 
    * if the product does not have a pricebook entry, or 
    * there is no pricebook as provided in the custom settings
    */
    void resetFeePriceAndAmount(MUSW__Fee__c fee) {
        fee.MUSW__Price_Per_Unit__c = null;
        fee.MUSW__Amount__c = null;
    }
}