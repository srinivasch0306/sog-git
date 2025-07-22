trigger FeeUpdateCart on MUSW__Fee__c(before insert, after insert, after update)
{
    // only process unpaid fees
    MUSW__Fee__c[] fees = new MUSW__Fee__c[]{};
    for (MUSW__Fee__c f : Trigger.new) if (!f.MUSW__Fee_Paid__c && f.MUSW__Outstanding_Fee__c > 0) fees.add(f);
    if (fees.size() == 0) return;
    
    Boolean bulkDataload = fees.size() > 100;
    if (trigger.isAfter)
    {
        Set<Id> cartIds = new Set<Id>();
        for (MUSW__Fee__c f : fees)
        {
            if (Trigger.isInsert || (Trigger.isUpdate && (f.MUSW__Outstanding_Fee__c != trigger.oldMap.get(f.Id).MUSW__Outstanding_Fee__c || f.MUSW__Amount_Waived__c != trigger.oldMap.get(f.Id).MUSW__Amount_Waived__c )))//|| f.Waived_Interest_Amount__c != trigger.oldMap.get(f.Id).Waived_Interest_Amount__c || f.Waived_Penalty_Amount__c !=  trigger.oldMap.get(f.Id).Waived_Penalty_Amount__c || f.Waived_Fee_Amount__c !=  trigger.oldMap.get(f.Id).Waived_Fee_Amount__c
            {
                if (f.BGBK__Cart__c != null && !cartIds.contains(f.BGBK__Cart__c)) cartIds.add(f.BGBK__Cart__c);
            }
        }
        
        BGBK__Cart__c[] carts = [select BGBK__Total_Amount__c, (select MUSW__Outstanding_Fee__c from BGBK__Fees__r where MUSW__Outstanding_Fee__c > 0) from BGBK__Cart__c where Id in :cartIds];
        
        if (carts.size() > 0)
        {
            for (BGBK__Cart__c cart : carts)
            {
                Decimal totalAmount = 0;
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
            //for (MUSW__Fee__c f : fees) f.SysGen__c = true;
            
            // on before-update directly update fees by reference (if within max size)
            // Note: while addFeesToCart can handle 200+ fees within the CPU time limit, triggers are chunked in records of 200
            // so with a bulk dataload (e.g. 1000 fees) this trigger runs many times. Calling addFeesToCart this way puts CPU
            // in overdrive, therefore we don't want to run this for bulk dataloads
            if (!bulkDataload)
            {
                BGBK.CartManager.addFeesToCart(fees);
            }
        }
    }
}