public with sharing class PermitViewController
{
    private Id m_pid;
    
    public PermitViewController(ApexPages.StandardController con)
    {
        m_pid = con.getRecord().Id;
    }
    
    /** Fill in Total Fees on Permit **/
    public void init()
    {
        if(m_pid != null)
        {
            Decimal oldTotalFees = 0;
            Decimal totalFees = 0;
            
            MUSW__Permit2__c per  = [select Id, MUSW__Total_Fees__c from MUSW__Permit2__c where Id=:m_pid];
            
            if(per.MUSW__Total_Fees__c != null)
            {
                oldTotalFees = per.MUSW__Total_Fees__c;
            }
            
            MUSW__Fee__c[] fees = [select Id, MUSW__Amount__c, MUSW__Amount_Waived__c, MUSW__Amended_Amount__c from MUSW__Fee__c where MUSW__Permit2__c =: m_pid];
                        
            for(MUSW__Fee__c fee: fees)
            {                
                if(fee.MUSW__Amount__c != null){
                    Decimal otherAmount = 0;
                    if (fee.MUSW__Amount_Waived__c != null) otherAmount -= fee.MUSW__Amount_Waived__c;
                    if (fee.MUSW__Amended_Amount__c != null) otherAmount -= fee.MUSW__Amended_Amount__c;
                    
                    totalFees += fee.MUSW__Amount__c + otherAmount; 
                }
            }
                        
            if(totalFees != oldTotalFees)
            {
                per.MUSW__Total_Fees__c = totalFees;
                try{
                    update per;
                } catch (DmlException e)
                {
                    if(!e.getMessage().contains('ENTITY_IS_LOCKED')) throw e;
                }
            }
        }
    }
}