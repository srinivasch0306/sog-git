public with sharing class InspectionRequestController
{
    public String parentName { get; private set; }
    public MUSW__Inspection__c[] ins { get; set; }
    public Boolean hasBalance { get; private set; }
    public Integer insSelectIndex { get; set; }
    private Id pid;
    
    public void initSetIEMode()
    {
        ApexPages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=10');
    }
    
    public InspectionRequestController()
    {
        insSelectIndex = null;
        pid = System.currentPageReference().getParameters().get('pid');
        
        String parcelId, rtName;
        if (String.valueOf(pid.getSobjectType()) == 'MUSW__Permit2__c')
        {
            MUSW__Permit2__c p = database.query('select Id, Name, MUSW__Parcel__c, RecordType.Name, MUSW__Total_Balance__c, (select ' + MUSW.UtilityDb.getFieldsFor_Str('MUSW__Inspection__c', false) + ' from MUSW__Inspections__r where Requested_DateTime__c = null and IsClosed__c = \'No\') from MUSW__Permit2__c where Id = :pid');
            parcelId = p.MUSW__Parcel__c;
            rtName = p.RecordType.Name;
            parentName = 'Permit: ' + p.Name;
            hasBalance = p.MUSW__Total_Balance__c > 0;
            ins = p.MUSW__Inspections__r;
        }
        else
        {
            Account a = database.query('select Id, Name, (select ' + MUSW.UtilityDb.getFieldsFor_Str('MUSW__Inspection__c', false) + ' from Inspections__r where Requested_DateTime__c = null and IsClosed__c = \'No\') from Account where Id = :pid');
            parcelId = null;
            rtName = '';
            parentName = 'Account: ' + a.Name;
            hasBalance = false;
            ins = a.Inspections__r;
        }
        
        RecordType[] rt = [select Id from RecordType where Name = :rtName and SobjectType = 'MUSW__Inspection__c'];
        
        MUSW__Inspection__c newIns = new MUSW__Inspection__c(MUSW__Parcel__c=parcelId);
        if (rt.size() > 0) newIns.RecordTypeId = rt[0].Id;
        if (String.valueOf(pid.getSobjectType()) == 'MUSW__Permit2__c') newIns.MUSW__Permit__c = pid;
        else newIns.Account__c = pid;
        
        ins.add(newIns);
    }
    
    public pageReference save()
    {
        try
        {
            if(insSelectIndex != null)
            {
                ins[insSelectIndex].Requested_DateTime__c = system.now();
                upsert ins[insSelectIndex];
            } else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select Inspections first.'));
                return null;
            }
        }
        catch (Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
            return null;
        }
        return cancel();
    }
    
    public pageReference cancel()
    {
        pageReference pr = new pageReference('/'+ pid);
        pr.setredirect(true);
        return pr;  
    }

}