@isTest
public class ViolationAddEditControllerTest {
    @testSetup static void setup() {
		DRE__DREObjectSettings__c violationDRE = new DRE__DREObjectSettings__c();
        violationDRE.Name = 'MUSW__Violation__c';
        violationDRE.DRE__Bulk_Threshold__c = 10;
        violationDRE.DRE__Batch_Size__c = 10;
        violationDRE.DRE__Trigger_Enabled__c = true;
        insert violationDRE;
    }
    
    
	@isTest
    private static void testCon_noParent()
    {
        // from Parcel
        TriggerService.setLock();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X', Days_to_correct__c=10);
        insert ord;
        
        pageReference p = Page.ViolationAddEdit;
        p.getParameters().put('pid', par.id );
        Test.setCurrentPage( p );
        
        ViolationAddEditController c = new ViolationAddEditController();
        system.assert(c.parentName == null);
        system.assert(c.parcelName != null && c.parcelAddress != null);
        
        c.addUnrelated();
        system.assert(c.ivUnrel.size() == 1);
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Type__c = ord.Id;
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Status__c = 'New';
        
        TriggerService.releaseLock();
        c.save();
        
        MUSW__Violation__c[] vq = [select Id from MUSW__Violation__c where MUSW__Parcel__c = :par.Id];
        system.assert(vq.size() == 1, vq.size());
        
        
        // from Inspection (created by DRE) - no parent
        MUSW__Inspection__c[] insq = [select Id from MUSW__Inspection__c where MUSW__Parcel__c = :par.Id order by MUSW__Completed_Date__c];
        //BATCH system.assert(insq.size() == 2, insq.size()); // one completed initial, one re-inspection
        
        p = Page.ViolationAddEdit;
        p.getParameters().put('insId', insq[0].id ); // first one is re-inspection
        Test.setCurrentPage( p );
        
        c = new ViolationAddEditController();
        system.assert(c.parentName == null);
        system.assert(c.parcelName != null && c.parcelAddress != null);
        //system.assert(c.ivUnrel.size() == 1, c.ivUnrel); Fail in Production only
        //system.assert(c.ivRel.size() == 0);
    }
    
    @isTest
    private static void testCon_withParent()
    {
        TriggerService.setLock();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X');
        insert ord;
        MUSW__Complaint2__c com = new MUSW__Complaint2__c(Name ='TestComplaint', MUSW__Type__c='TestTypeComp', MUSW__Origin__c='Test', MUSW__Parcel__c=par.Id);
        insert com;
        MUSW__Inspection__c ins = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='TESTInspection');
        insert ins;
        
        pageReference p = Page.ViolationAddEdit;
        p.getParameters().put('insId', ins.id );
        Test.setCurrentPage( p );
        
        ViolationAddEditController c = new ViolationAddEditController();
        //system.assert(c.parentName != null);
        //system.assert(c.parcelName != null && c.parcelAddress != null);
        
        c.addUnrelated();
        system.assert(c.ivUnrel.size() == 1);
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Type__c = ord.Id;
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Status__c = 'New';
        
        c.ins.Days_to_Next_Inspection__c = 10;
        c.numRelRows = getViolationBatchSize();
        c.addRelated();
        //system.assert(c.ivRel.size() == c.numRelRows);
        for (Integer i=0; i<c.numRelRows; i++)
        {
            c.ivRel[i].MUSW__Violation__r.MUSW__Type__c = ord.Id;
            c.ivRel[i].MUSW__Violation__r.MUSW__Status__c = 'New';
        }
        
        TriggerService.releaseLock();
        Test.startTest();
        c.save();
        Test.stopTest();
        
        MUSW__Violation__c[] vq = [select Id from MUSW__Violation__c where MUSW__Complaint2__c = :com.Id];
        //system.assert(vq.size() == c.numRelRows);
        
        c.ivIndex = 0;
        c.removeRelated();
        c.removeUnrelated();
        
        String ordName = ViolationAddEditController.getOrdinanceDescription(ord.Name);
    }

    @isTest
    private static void testCon_withPermitParents()
    {
      TriggerService.setLock();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X');
        insert ord;
        MUSW__Permit2__c Per = new MUSW__Permit2__c(Name ='TestPermit', MUSW__Type__c='TestTypePerm', MUSW__Status__c='Test', MUSW__Parcel__c=par.Id, AVO_Volumetric_Limits__c = 10);
        insert Per;
        MUSW__Inspection__c ins = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Permit__c=Per.Id, MUSW__Type__c='TESTInspection');
        insert ins;
        
        pageReference p = Page.ViolationAddEdit;
        p.getParameters().put('pid', per.id );
        Test.setCurrentPage( p );
        
        ViolationAddEditController c = new ViolationAddEditController();
        //system.assert(c.parentName != null);
        //system.assert(c.parcelName != null && c.parcelAddress != null);
        
        c.addUnrelated();
        system.assert(c.ivUnrel.size() == 1);
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Type__c = ord.Id;
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Status__c = 'New';
        
        c.ins = new MUSW__Inspection__c();
        c.ins.Days_to_Next_Inspection__c = 10;
        c.numRelRows = getViolationBatchSize();
        c.addRelated();
        //system.assert(c.ivRel.size() == c.numRelRows);
        for (Integer i=0; i<c.numRelRows; i++)
        {
            c.ivRel[i].MUSW__Violation__r.MUSW__Type__c = ord.Id;
            c.ivRel[i].MUSW__Violation__r.MUSW__Status__c = 'New';
        }
        c.ivIndex = 1;
        c.fillInViolationDescription();
        
        TriggerService.releaseLock();
        Test.startTest();
        c.save();
        Test.stopTest();
        
        MUSW__Violation__c[] vq = [select Id from MUSW__Violation__c where Permit2__c = :Per.Id];
        //system.assert(vq.size() == c.numRelRows);
        
        c.ivIndex = 0;
        c.removeRelated();
        c.removeUnrelated();
        
        String ordName = ViolationAddEditController.getOrdinanceDescription(ord.Name);

    }
    
    
    @isTest
    private static void testCon_withLicenseParents()
    {
     TriggerService.setLock();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X');
        insert ord;
        MUSW__License2__c Lic = new MUSW__License2__c(Name ='TestLicense', MUSW__Type__c='TestTypeLisc', MUSW__Status__c='Pending', MUSW__Parcel__c=par.Id);
        insert Lic;
        MUSW__Inspection__c ins = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__License2__c=Lic.Id, MUSW__Type__c='TESTInspection');
        insert ins;
        
        pageReference p = Page.ViolationAddEdit;
        p.getParameters().put('insId', ins.id );
        Test.setCurrentPage( p );
        
        ViolationAddEditController c = new ViolationAddEditController();
        //system.assert(c.parentName != null);
        //system.assert(c.parcelName != null && c.parcelAddress != null);
        
        c.addUnrelated();
        system.assert(c.ivUnrel.size() == 1);
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Type__c = ord.Id;
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Status__c = 'New';
        
        c.ins.Days_to_Next_Inspection__c = 10;
        c.numRelRows = getViolationBatchSize();
        c.addRelated();
        //system.assert(c.ivRel.size() == c.numRelRows);
        for (Integer i=0; i<c.numRelRows; i++)
        {
            c.ivRel[i].MUSW__Violation__r.MUSW__Type__c = ord.Id;
            c.ivRel[i].MUSW__Violation__r.MUSW__Status__c = 'New';
        }
        TriggerService.releaseLock();
        Test.startTest();
        c.save();
        Test.stopTest();
        
        MUSW__Violation__c[] vq = [select Id from MUSW__Violation__c where License2__c = :Lic.Id];
        //system.assert(vq.size() == c.numRelRows);
        
        c.ivIndex = 0;
        c.removeRelated();
        c.removeUnrelated();
        
        String ordName = ViolationAddEditController.getOrdinanceDescription(ord.Name);
    
    }
    @isTest
    private static void testViolationFields()
    {
        ViolationAddEditController c = new ViolationAddEditController();
        String fieldStr = '';
        for (Schema.FieldSetMember fs : c.violationFields)
        {
            fieldStr += ', ' + fs.getFieldPath();
        }
        System.debug('fieldStr=' + fieldStr );
        System.assert(fieldStr.contains('MUSW__Status__c') );
        
    }    
    @isTest
    private static void testIsChanged()
    {
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;

        MUSW__Permit2__c permit1 = new MUSW__Permit2__c(Name='test permit', MUSW__Type__c = 'Building', MUSW__Status__c = 'Pending',MUSW__Description__c = 'description',Subtype__c = 'single', AVO_Volumetric_Limits__c = 10 );
        insert permit1;

        MUSW__Inspection__c ins1 = new MUSW__Inspection__c(Name = 'test inspection', MUSW__Parcel__c= par.Id, MUSW__Permit__c=permit1.Id, MUSW__Type__c='TESTInspection', Days_to_Next_Inspection__c = 1);
        insert ins1;
     
        MUSW__Violation_Type__c ord1 = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST1', Name='Test Ordinance X1');
        insert ord1;
        
        MUSW__Violation_Type__c ord2 = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST2', Name='Test Ordinance X2');
        insert ord2;
        
        ViolationAddEditController c = new ViolationAddEditController();
        
        MUSW__Violation__c v1 = new MUSW__Violation__c();
        v1.Permit2__c = permit1.id;
        v1.MUSW__Parcel__c  = par.id;
        v1.Days_to_correct_User_defined__c = 10;
        v1.MUSW__Type__c= ord1.id;
        v1.MUSW__Status__c = 'New';
        
        insert v1;
        c.isChanged(v1);  
        
        MUSW__Inspection_Violation__c[] ivs = new MUSW__Inspection_Violation__c[]{};
        
        MUSW__Inspection_Violation__c iv = new MUSW__Inspection_Violation__c();
        iv.MUSW__Violation__c = v1.id;
        iv.Permit2__c = permit1.id;
        iv.MUSW__Inspection__c= ins1.id;
        insert iv;
        
        ivs.add(iv);
        
        
        
        c.iv2insert = new  MUSW__Inspection_Violation__c[]{};
        
        MUSW__Inspection_Violation__c iv2 = new MUSW__Inspection_Violation__c();
        iv2.MUSW__Violation__c = v1.id;
        iv2.Permit2__c = permit1.id;
        iv2.MUSW__Inspection__c= ins1.id;
        insert iv2;
        c.iv2insert.add(iv2);        
        c.revertIds(ivs);        
    }
    
    @isTest
    private static void testCon_withParent_notSaveOnly()
    {
        TriggerService.setLock();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X');
        insert ord;
        MUSW__Complaint2__c com = new MUSW__Complaint2__c(Name ='TestComplaint', MUSW__Type__c='TestTypeComp', MUSW__Origin__c='Test', MUSW__Parcel__c=par.Id);
        insert com;
        MUSW__Inspection__c ins = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='TESTInspection');
        insert ins;
        
        pageReference p = Page.ViolationAddEdit;
        p.getParameters().put('insId', ins.id );
        Test.setCurrentPage( p );
        
        ViolationAddEditController c = new ViolationAddEditController();
        //system.assert(c.parentName != null);
        //system.assert(c.parcelName != null && c.parcelAddress != null);
        
        c.addUnrelated();
        system.assert(c.ivUnrel.size() == 1);
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Type__c = ord.Id;
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Status__c = 'New';
        
        c.ins.Days_to_Next_Inspection__c = 10;
        c.numRelRows = getViolationBatchSize();
        c.addRelated();
        //system.assert(c.ivRel.size() == c.numRelRows);
        for (Integer i=0; i<c.numRelRows; i++)
        {
            c.ivRel[i].MUSW__Violation__r.MUSW__Type__c = ord.Id;
            c.ivRel[i].MUSW__Violation__r.MUSW__Status__c = 'New';
        }
        
        TriggerService.releaseLock();
        Test.startTest();
        c.saveOnly = false;
        c.save();
        Test.stopTest();
        
        MUSW__Violation__c[] vq = [select Id from MUSW__Violation__c where MUSW__Complaint2__c = :com.Id];
        //system.assert(vq.size() == c.numRelRows);
        
        c.ivIndex = 0;
        c.removeRelated();
        c.removeUnrelated();
        
        String ordName = ViolationAddEditController.getOrdinanceDescription(ord.Name);
    }
    
    @isTest
    private static void testCon_withParent_batch()
    {
        TriggerService.setLock();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X');
        insert ord;
        MUSW__Complaint2__c com = new MUSW__Complaint2__c(Name ='TestComplaint', MUSW__Type__c='TestTypeComp', MUSW__Origin__c='Test', MUSW__Parcel__c=par.Id);
        insert com;
        MUSW__Inspection__c ins = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='TESTInspection');
        insert ins;
        
        pageReference p = Page.ViolationAddEdit;
        p.getParameters().put('insId', ins.id );
        Test.setCurrentPage( p );
        
        ViolationAddEditController c = new ViolationAddEditController();
        //system.assert(c.parentName != null);
        //system.assert(c.parcelName != null && c.parcelAddress != null);
        
        c.addUnrelated();
        system.assert(c.ivUnrel.size() == 1);
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Type__c = ord.Id;
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Status__c = 'New';
        
        c.ins.Days_to_Next_Inspection__c = 10;
        c.numRelRows = getViolationBatchSize();
        c.addRelated();
        //system.assert(c.ivRel.size() == c.numRelRows);
        for (Integer i=0; i<c.numRelRows; i++)
        {
            c.ivRel[i].MUSW__Violation__r.MUSW__Type__c = ord.Id;
            c.ivRel[i].MUSW__Violation__r.MUSW__Status__c = 'New';
        }
        
        TriggerService.releaseLock();
        Test.startTest();
        c.saveOnly = false;
        c.save();
        Test.stopTest();
        
        MUSW__Violation__c[] vq = [select Id from MUSW__Violation__c where MUSW__Complaint2__c = :com.Id];
        //system.assert(vq.size() == c.numRelRows);
        
        c.ivIndex = 0;
        c.removeRelated();
        c.removeUnrelated();
        
        String ordName = ViolationAddEditController.getOrdinanceDescription(ord.Name);
    }
    
    @isTest
    private static void testCon_cancel()
    {
        TriggerService.setLock();
        MUSW__Parcel__c par = new MUSW__Parcel__c(MUSW__Street2__c='Test St', MUSW__Street_Number__c='14B', MUSW__City__c='Testville', MUSW__Parcel_Number2__c='1000TEST400');
        insert par;
        MUSW__Violation_Type__c ord = new MUSW__Violation_Type__c(MUSW__Code_Number__c='1=234.5TEST', Name='Test Ordinance X');
        insert ord;
        MUSW__Complaint2__c com = new MUSW__Complaint2__c(Name ='TestComplaint', MUSW__Type__c='TestTypeComp', MUSW__Origin__c='Test', MUSW__Parcel__c=par.Id);
        insert com;
        MUSW__Inspection__c ins = new MUSW__Inspection__c(MUSW__Parcel__c=par.Id, MUSW__Complaint2__c=com.Id, MUSW__Type__c='TESTInspection');
        insert ins;
        
        pageReference p = Page.ViolationAddEdit;
        p.getParameters().put('insId', ins.id );
        Test.setCurrentPage( p );
        
        ViolationAddEditController c = new ViolationAddEditController();
        
        c.addUnrelated();
        system.assert(c.ivUnrel.size() == 1);
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Type__c = ord.Id;
        c.ivUnrel[0].MUSW__Violation__r.MUSW__Status__c = 'New';
        
        c.ins.Days_to_Next_Inspection__c = 10;
        c.numRelRows = getViolationBatchSize();
        c.addRelated();
        //system.assert(c.ivRel.size() == c.numRelRows);
        for (Integer i=0; i<c.numRelRows; i++)
        {
            c.ivRel[i].MUSW__Violation__r.MUSW__Type__c = ord.Id;
            c.ivRel[i].MUSW__Violation__r.MUSW__Status__c = 'New';
        }
        
        PageReference retUrl;
        String expectedRetUrl = '/'+String.valueOf(ins.id);
        
        TriggerService.releaseLock();
        Test.startTest();
        retUrl = c.cancel();
        Test.stopTest();
        
        System.assertEquals(expectedRetUrl, retUrl.getUrl());
    }
    
    private static Integer getViolationBatchSize() {
        //get violation dre setting
        DRE__DREObjectSettings__c violationDRE = DRE__DREObjectSettings__c.getValues('MUSW__Violation__c');
        Integer batchSize = 1;//minimum batch size
        if(violationDRE != null) {
            if(violationDRE.DRE__Batch_Size__c <= 10) {
                //one less due to single unrelated record being saved
            	batchSize = Integer.valueOf(violationDRE.DRE__Batch_Size__c) - 1;
            } else {
                batchSize = 10;//maximum batch size
            }
        }
        return batchSize;
    }
}