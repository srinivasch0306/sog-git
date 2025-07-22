public class ViolationAddEditBatch implements Database.Batchable<MUSW__Inspection_Violation__c>, Database.Stateful
{
    public String error;
    private MUSW__Inspection__c ins;
    private MUSW__Inspection__c[] fieldObservations;
    private MUSW__Inspection_Violation__c[] ivs;
    
    public ViolationAddEditBatch(MUSW__Inspection__c ins, MUSW__Inspection__c[] fos, MUSW__Inspection_Violation__c[] ivs)
    {
        this.ivs = ivs;
        this.ins = ins;
        this.fieldObservations = fos;
    }
    
    public Iterable<MUSW__Inspection_Violation__c> start(Database.BatchableContext bc)
    { 
        return ivs;
    }
    
    public void execute(Database.BatchableContext bc, List<MUSW__Inspection_Violation__c> scopedIvs)
    {
        system.debug('scopedIvs=' + scopedIvs);
        update scopedIvs;
    }
    
    public void finish(Database.BatchableContext bc)
    {
        // coming from Inspection
        // update to run DRE
        if (ins != null)
        {
            ins.Close_Inspection__c = true;
            update ins;
        }
        
        // coming from Permit/Parcel
        // update to run DRE (cannot do on insert because DRE is blocked & rules need IV's)
        if (fieldObservations.size() > 0)
        {
            for (MUSW__Inspection__c foins : fieldObservations)
            {
                foins.Close_Inspection__c = true;
                foins.MUSW__Status__c = 'Completed with open violations';
            }
            System.debug('fieldObservations=' +fieldObservations );
            update fieldObservations;
        }
    }
    

    
}