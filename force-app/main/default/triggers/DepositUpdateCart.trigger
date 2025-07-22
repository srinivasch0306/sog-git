trigger DepositUpdateCart on MUSW__Deposit__c (before insert, after insert, after update)
{
    // only process unpaid deposits
    MUSW__Deposit__c[] deposits = new MUSW__Deposit__c[]{};
    for (MUSW__Deposit__c f : Trigger.new) if (f.MUSW__Unpaid_Amount__c > 0) deposits.add(f);
    if (deposits.size() == 0) return;
    
    Boolean bulkDataload = deposits.size() > 100;
    if (trigger.isAfter)
    {
        Set<Id> cartIds = new Set<Id>();
        for (MUSW__Deposit__c d : deposits)
        {
            if (Trigger.isInsert || (Trigger.isUpdate && (d.MUSW__Unpaid_Amount__c != trigger.oldMap.get(d.Id).MUSW__Unpaid_Amount__c )))
            {
                if (d.BGBK__Cart__c != null && !cartIds.contains(d.BGBK__Cart__c)) cartIds.add(d.BGBK__Cart__c);
            }
        }
        
        BGBK__Cart__c[] carts = [select BGBK__Total_Amount__c, (select MUSW__Unpaid_Amount__c from BGBK__Deposits__r where MUSW__Unpaid_Amount__c > 0), (select MUSW__Outstanding_Fee__c from BGBK__Fees__r where MUSW__Outstanding_Fee__c > 0) from BGBK__Cart__c where Id in :cartIds];
        
        if (carts.size() > 0)
        {
            for (BGBK__Cart__c cart : carts)
            {
                Decimal totalAmount = 0;
                for (MUSW__Deposit__c d : cart.BGBK__Deposits__r) totalAmount += d.MUSW__Unpaid_Amount__c;
                for (MUSW__Fee__c f : cart.BGBK__Fees__r) totalAmount += f.MUSW__Outstanding_Fee__c;
                cart.BGBK__Total_Amount__c = totalAmount;
            }
            update carts;
        }
        
        if (Trigger.isInsert && bulkDataload)
        {
            // large data loads are only allowed through the API (e.g. BillingLineItemService)
        }
    }
    else
    {
        if (Trigger.isInsert)
        {
            //for (MUSW__Deposit__c f : deposits) f.SysGen__c = true;
            
            // on before-update directly update deposits by reference (if within max size)
            // Note: while addFeesToCart can handle 200+ deposits within the CPU time limit, triggers are chunked in records of 200
            // so with a bulk dataload (e.g. 1000 deposits) this trigger runs many times. Calling addFeesToCart this way puts CPU
            // in overdrive, therefore we don't want to run this for bulk dataloads
            if (!bulkDataload)
            {
                BGBK.CartManager.addDepositsToCart(deposits);
            }
        }
    }
}