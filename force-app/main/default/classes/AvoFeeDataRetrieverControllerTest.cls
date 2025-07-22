@isTest
public class AvoFeeDataRetrieverControllerTest {
    
    @TestSetup
    static void dataSetup() {
        account acc = new account();
        acc.name = 'testaccount';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'Inc.';
        con.AccountId = acc.id;
        insert con;
        
        MUSW__Permit2__c entity = new MUSW__Permit2__c();
        entity.MUSW__Type__c = 'Agricultural Water Withdrawal Application';
        entity.MUSW__Status__c = 'Submitted';
        entity.MUSW__Account__c = con.AccountId;
        entity.MUSW__Applicant__c = con.id;
        entity.AVO_Volumetric_Limits__c = 1;
        insert entity;
        
        MUSW__Work_Item__c wc = new MUSW__Work_Item__c();
        wc.MUSW__Type__c = 'Deck';
        wc.MUSW__Quantity2__c = 1;
        wc.MUSW__Unit__c = 'SQ FT';
        wc.MUSW__Quantity__c = 1;
        wc.MUSW__Permit2__c = entity.id;
        wc.MUSW__Value_Per_Unit__c = 20;
        insert wc;
        
        Id devRecordTypeId = Schema.SObjectType.MUSW__Master_Fee_List__c.getRecordTypeInfosByName().get('Permit').getRecordTypeId();
        
        List<MUSW__Master_Fee_List__c> mstrFeeList = new List<MUSW__Master_Fee_List__c>();
        
        List<String> feeNames = new List<String>{
            'TestMaster',
            'Preliminary Plat Lot Fee',
            'Inspection Costs for Water',
            'Final Plat Lot Fee',
            'Inspection Costs for Sanitary Sewer'
        };
        
        for (String name : feeNames) {
            MUSW__Master_Fee_List__c fee = new MUSW__Master_Fee_List__c();
            fee.Name = name;
            fee.RecordTypeId = devRecordTypeId;
            fee.Avo_Permit_Type__c = 'Agricultural Water Withdrawal Application';
            fee.Flat_Amount__c = 2;
            fee.Multiplier__c = 10;
            fee.Base__c = 10;
            fee.High_Tier_Limit__c = 500;
            fee.Low_Tier_Limit__c = 20;
            fee.Fee_Calculation_Type__c = (name == 'TestMaster') ? 'Flat' : 'Work Item Based';
            fee.Effective_Start_Date__c = system.today().addDays(-1);
            fee.Effective_End_Date__c = system.today().addDays(+5);
            fee.Manual_Creation_Allowed__c = true;
            fee.GL_Account__c = '101-5910-000-3694';
            mstrFeeList.add(fee);
        }
        
        insert mstrFeeList;
        
        BGBK__Cart__c cart = new BGBK__Cart__c();
        cart.Name = 'X-2022-03-28_09-02-12';
        insert cart;
        
        // ✅ Corrected RecordTypeId retrieval for MUSW__Fee__c
        Id recordTypeId;
        List<Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.MUSW__Fee__c.getRecordTypeInfos();
        for (Schema.RecordTypeInfo rtInfo : rtInfos) {
            if (rtInfo.isAvailable() && !rtInfo.isMaster()) {
                recordTypeId = rtInfo.getRecordTypeId();
                break;
            }
        }
        System.assertNotEquals(null, recordTypeId, 'No available record type found for MUSW__Fee__c');
        
        MUSW__Fee__c Fee = new MUSW__Fee__c();
        Fee.RecordTypeId = recordTypeId;
        Fee.MUSW__Type__c = 'Application';
        Fee.clariti__CashLedgerAccountName__c = 'Test1';
        Fee.BGBK__Cart__c = cart.Id;
        insert Fee;
        
        MUSW__Work_Item__c workItem = new MUSW__Work_Item__c();
        workItem.MUSW__Type__c = 'Living Space';
        workItem.MUSW__Quantity2__c = 2;
        workItem.MUSW__Unit__c = 'SQ FT';
        workItem.MUSW__Quantity__c = 3;
        workItem.MUSW__Description__c = 'Preliminary Plat Lot Fee';
        workItem.MUSW__Permit2__c = entity.Id;
        insert workItem;
    }
    
    @isTest
    public static void getAllowedFeeTypesTest() {
        MUSW__Permit2__c muswPermit = [SELECT id, name FROM MUSW__Permit2__c LIMIT 1];
        AvoFeeDataRetrieverController.getAllowedFeeTypes(muswPermit.id, 'MUSW__Permit2__c');
    }

    @isTest
    public static void testgetfeetypedata() {
        Id recordId = [SELECT id FROM MUSW__Master_Fee_List__c WHERE Name='Preliminary Plat Lot Fee' LIMIT 1].Id;
        List<MUSW__Master_Fee_List__c> Result = AvoFeeDataRetrieverController.getfeetypedata(recordId);
        System.assertNotEquals(null, Result);
    }

    @isTest
    public static void testgetFeeRecordTypeId() {
        String recordtypename = [SELECT RecordType.Name FROM MUSW__Fee__c WHERE clariti__CashLedgerAccountName__c ='Test1' LIMIT 1].RecordType.Name;
        Id Result = AvoFeeDataRetrieverController.getFeeRecordTypeId(recordtypename);
        System.assertNotEquals(null, Result);
    }

    @isTest 
    public static void testgetFeeListInformation() {
        MUSW__Master_Fee_List__c masterId = [SELECT id FROM MUSW__Master_Fee_List__c WHERE Name='Preliminary Plat Lot Fee' LIMIT 1];
        List<String> masterIds = new List<String>{ masterId.Id };
        List<MUSW__Master_Fee_List__c> Result = AvoFeeDataRetrieverController.getFeeListInformation(masterIds);
        System.assertNotEquals(null, Result);
    }

    @isTest
    public static void createFeeTest() {
        MUSW__Permit2__c entity = [SELECT Id FROM MUSW__Permit2__c LIMIT 1];
        Integer quantities = 3;
        String masterId = [SELECT Id FROM MUSW__Master_Fee_List__c WHERE Name='Preliminary Plat Lot Fee' LIMIT 1].Id;
        if (quantities != null && entity.Id != null && masterId != null) {
           // AvoFeeDataRetrieverController.createFee(quantities, String.valueOf(entity.Id), masterId, 'MUSW__Permit2__c');
        }
    }

    @isTest
    public static void matchTieredConditionTest() {
        MUSW__Master_Fee_List__c mFeeList = [SELECT id, Name, Low_Tier_Limit__c, High_Tier_Limit__c FROM MUSW__Master_Fee_List__c WHERE Name='Preliminary Plat Lot Fee' LIMIT 1];
        AvoFeeDataRetrieverController.matchTieredCondition('MUSW__Permit2__c', 10, mFeeList);
        AvoFeeDataRetrieverController.matchTieredCondition('MUSW__Application2__c', 10, mFeeList);
    }

    @isTest
    public static void calculateTieredFeeTest() {
        MUSW__Master_Fee_List__c mFeeList = [SELECT id, Name, Low_Tier_Limit__c, Multiplier__c, Flat_Amount__c FROM MUSW__Master_Fee_List__c WHERE Name='Preliminary Plat Lot Fee' LIMIT 1];
        mFeeList.Name = 'Fire Marshal Plan Review Submittal Fee';
        mFeeList.Low_Tier_Limit__c = 0;
        mFeeList.Multiplier__c = null;
        update mFeeList;
        AvoFeeDataRetrieverController.calculateTieredFee('MUSW__Permit2__c', null, mFeeList);
        AvoFeeDataRetrieverController.calculateTieredFee('MUSW__Application2__c', 10, mFeeList);
    }

    @isTest
    public static void createMultipleFeesTest(){
        account acc = [select id,name from account where name='testaccount' limit 1];
        Contact con = [select id,name,AccountId from Contact where LastName='Inc.' limit 1];
        
        MUSW__Permit2__c entity = new MUSW__Permit2__c();
        entity.MUSW__Type__c = 'Building';
        entity.MUSW__Status__c = 'Submitted';
        entity.MUSW__Account__c = con.AccountId;
        entity.MUSW__Applicant__c = con.id;
        entity.AVO_Permitted_Acres__c = 1;
        insert entity;
        /*
        MUSW__Work_Item__c wc = new MUSW__Work_Item__c();
        wc.MUSW__Type__c = 'Deck';
        wc.MUSW__Quantity2__c = 1;
        wc.MUSW__Unit__c = 'SQ FT';
        wc.MUSW__Quantity__c = 1;
        wc.MUSW__Permit2__c = entity.id;
        wc.MUSW__Value_Per_Unit__c =20; 
        insert wc;
        */       
        List<Integer> quantities = new List<Integer>{1,2};
        
        List<String> masterIds = new List<String>();
        masterIds.add([Select id from MUSW__Master_Fee_List__c Where Name='Preliminary Plat Lot Fee' Limit 1].Id); 
        
        AvoFeeDataRetrieverController.createMultipleFees(quantities, String.valueOf(entity.Id), masterIds, 'MUSW__Permit2__c'); 
    }

    @isTest
    public static void handlePermitFeeSpecialCasesTest() {
        Decimal amount = 20.00;
        MUSW__Permit2__c permit1 = [SELECT MUSW__Type__c, Avo_Estimated_Cost__c, Avo_Value_of_Sign__c, Avo_Type_Construction__c, Avo_Proposed_Occupancy__c, Avo_Fee_Calculation__c, L_F_Water_Main__c, L_F_Sanitary_Sewer_Main__c FROM MUSW__Permit2__c LIMIT 1];
        MUSW__Master_Fee_List__c mFeeList = [SELECT id, Name FROM MUSW__Master_Fee_List__c WHERE Name='Inspection Costs for Water' LIMIT 1];
        MUSW__Master_Fee_List__c mFeeList2 = [SELECT id, Name FROM MUSW__Master_Fee_List__c WHERE Name='Inspection Costs for Sanitary Sewer' LIMIT 1];
        AvoFeeDataRetrieverController.handlePermitFeeSpecialCases(permit1, mFeeList, amount);
        AvoFeeDataRetrieverController.handlePermitFeeSpecialCases(permit1, mFeeList2, amount);
    }

    @isTest
    public static void handleApplicationFeeSpecialCasesTest() {
        MUSW__Application2__c muswApp = new MUSW__Application2__c();
        muswApp.Name = 'TesApp';
        muswApp.Avo_Number_of_Lots__c = 10;
        muswApp.Avo_Number_of_New_Lots__c = 10;
        MUSW__Master_Fee_List__c mFeeList = [SELECT id, Name FROM MUSW__Master_Fee_List__c WHERE Name='Preliminary Plat Lot Fee' LIMIT 1];
        MUSW__Master_Fee_List__c mFeeList2 = [SELECT id, Name FROM MUSW__Master_Fee_List__c WHERE Name='Final Plat Lot Fee' LIMIT 1];
        AvoFeeDataRetrieverController.handleApplicationFeeSpecialCases(muswApp, mFeeList, 100);
        AvoFeeDataRetrieverController.handleApplicationFeeSpecialCases(muswApp, mFeeList2, 100);
    }
}