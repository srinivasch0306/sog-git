/**
 *  Test Cases Object for testing cart controller. 
 *   
 *  @author     Tahsin Zulkarnine
 *  @version    1.0
 *  @since      2014-12-05
 *
 */
@isTest
private class CartControllerTest {
private static Integer randomNum;

    @testSetup
    private static void setupTestData()
    {
        new BGBK.TestMock();
        insert new BGBK__CartSettings__c(Name='Default');
    }

    @isTest
    private static void testFromPermit()
    {
        BGBK.RulesEngineState.setLock();
                
        Contact c = new Contact(Lastname='TestUser123', Email='test@test.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__C=20, MUSW__Permit2__c=perm.Id);
        MUSW__Fee__c f2 = new MUSW__Fee__c(MUSW__Amount__C=120, MUSW__Permit2__c=perm.Id);
        MUSW__Fee__c[] fees = new MUSW__Fee__c[]{f1,f2};
        insert fees;
        
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('id', perm.Id);
        Test.setCurrentPage(fp);
        
        // pass fees as selections to controller
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(fees);
        ssc.setSelected(fees);
        CartController fc = new CartController(ssc);
        fc.initOrder();
        List<SelectOption> accs = fc.accounts;
        system.assert(fc.rs[0].MUSW__Receipt_Paid_by__c == c.Id);
        fc.cart.BGBK__Contact__c = c.Id;
        fc.rs[0].MUSW__Payment_Method__c = 'Check';
        fc.accountSelected = cq.AccountId;
        fc.checkout();
        fc.review();
        
        BGBK.RulesEngineState.releaseLock();
        
        fc.process();
        fc.sendPdf();
        fc.cancel();
        //fc.accountChanged();
    }

    @isTest
    private static void testFromInvoice()
    {
        // BGBK.RulesEngineState.setLock();                
        Account account = new Account(Name='Test Account');
        insert account;
                     
        Contact c = new Contact(LastName='Test Contact',FirstName='BasicGov', Email='test@basicgov.com', AccountId = account.id ,Account=account,MUSW__Account_Relationship__c='Owner');
        insert c;
       
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        BGBK__Cart__c testCart = new BGBK__Cart__c(BGBK__Account__c= cq.AccountId, BGBK__Contact__c= cq.Id, BGBK__Expiration_DateTime__c=system.now().addDays(1));
        insert testCart;
        
        // add fees to cart
        
        randomNum = Math.round(Math.random()*100000);
        String InvoiceNum1 = 'BGT-'+randomNum.format();
                
        BGBK__Bill__c inv1 = new BGBK__Bill__c(BGBK__Tracking_Number__c=InvoiceNum1,BGBK__Total_Fees__c=25,BGBK__Total_Payments__c=0);
        insert inv1;
                
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__c=25, MUSW__Permit2__c=perm.Id, BGBK__Cart__c = testCart.Id,BGBK__Invoice__c=inv1.Id);
        insert f1;
       
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('invoiceId', inv1.Id);
        Test.setCurrentPage(fp);
        
        CartController fc = new CartController(null);
        fc.initOrder();
        //system.assert(fc.cart.BGBK__Total_Amount__c== 140);
        List<SelectOption> accs = fc.accounts;
        fc.rs[0].MUSW__Payment_Method__c = 'Credit Card';
        fc.accountSelected = cq.AccountId ;
        fc.Checkout();
        fc.review();
        
        // BGBK.RulesEngineState.releaseLock();
        
        fc.process();
        system.assert(fc.cart.BGBK__Process_DateTime__c!= null);
        try { fc.sendPdf(); }
        catch (EmailException e) { if (e.getMessage().contains('Single email must be enabled')) {} }
        fc.cancel();
        //fc.accountChanged();
    }

    @isTest
    private static void testFromCart()
    {
        BGBK.RulesEngineState.setLock();                
        
        Contact c = new Contact(Lastname='TestUser123', Email='test@test.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        BGBK__Cart__c testCart = new BGBK__Cart__c(BGBK__Account__c= cq.AccountId, BGBK__Contact__c= cq.Id, BGBK__Expiration_DateTime__c=system.now().addDays(1));
        insert testCart;
        
        // add fees to cart
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__c=20, MUSW__Permit2__c=perm.Id, BGBK__Cart__c = testCart.Id);
        MUSW__Fee__c f2 = new MUSW__Fee__c(MUSW__Amount__c=120, MUSW__Permit2__c=perm.Id, BGBK__Cart__c = testCart.Id);
        MUSW__Fee__c[] fees = new MUSW__Fee__c[]{f1,f2};
        insert fees;
        
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('cartId', testCart.Id);
        Test.setCurrentPage(fp);
        
        CartController fc = new CartController(null);
        fc.initOrder();
        //system.assert(fc.cart.BGBK__Total_Amount__c== 140);
        List<SelectOption> accs = fc.accounts;
        fc.rs[0].MUSW__Payment_Method__c = 'Credit Card';
        fc.accountSelected = cq.AccountId ;
        fc.Checkout();
        fc.review();
        
        BGBK.RulesEngineState.releaseLock();
        
        fc.process();
        system.assert(fc.cart.BGBK__Process_DateTime__c!= null);
        try { fc.sendPdf(); }
        catch (EmailException e) { if (e.getMessage().contains('Single email must be enabled')) {} }
        fc.cancel();
        //fc.accountChanged();
    }
    
    @isTest
    private static void testManyPermitsPayments()
    {
        BGBK.RulesEngineState.setLock();                
        
        Contact c = new Contact(Lastname='TestUser123', Email='test@test.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        BGBK__Cart__c testCart = new BGBK__Cart__c(BGBK__Account__c= cq.AccountId, BGBK__Contact__c= cq.Id, BGBK__Expiration_DateTime__c=system.now().addDays(1));
        insert testCart;
        
        MUSW__Permit2__c[] perms = new MUSW__Permit2__c[]{};
        for (Integer i=0; i<9; i++)
        {
            MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
            perms.add(perm);
        }
        insert perms;
        
        // add fees to cart
        MUSW__Fee__c[] fees = new MUSW__Fee__c[]{};
        for (MUSW__Permit2__c p : perms)
        {
            MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__c=20, MUSW__Permit2__c=p.Id, BGBK__Cart__c = testCart.Id);
            fees.add(f1);
        }
        insert fees;
        
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('cartId',  testCart.Id );
        Test.setCurrentPage(fp);
        
        CartController fc = new CartController(null);
        fc.initOrder();
        //system.assert(fc.cart.BGBK__Total_Amount__c== 180);
        List<SelectOption> accs = fc.accounts;
        //add another receipt for multiple payments
        fc.addReceipt();
        fc.rs[0].MUSW__Payment_Method__c = 'Cash';
        fc.rs[1].MUSW__Payment_Method__c = 'Credit Card';
        fc.rs[0].MUSW__Amount_Tendered__c = 300;
        fc.rs[1].MUSW__Amount_Tendered__c = 100;
        fc.accountSelected = cq.AccountId;
        fc.Checkout();
        fc.review();
        fc.processResult = 'process_transaction_action_successful';
        
        BGBK.RulesEngineState.releaseLock();
        
        fc.process();
        system.assert(fc.cart.BGBK__Process_DateTime__c!= null);
        MUSW__Receipt__c[] rec = [select Id, Name from MUSW__Receipt__c where BGBK__Cart__c =: testCart.Id];
        Map<Id, MUSW__Receipt__c> recMap = new Map<Id, MUSW__Receipt__c>(rec);
        BGBK__Payment__c[] paym = [select Name from BGBK__Payment__c where BGBK__Receipt__c in : recMap.keySet()];
        //system.assert(paym.size() > 0);
    }

    private static Id setupData()
    {
        BGBK.RulesEngineState.setLock();                
    
        Contact c = new Contact(Lastname='TestUser123', Email='test@test.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        BGBK__Cart__c testCart = new BGBK__Cart__c(BGBK__Account__c= cq.AccountId, BGBK__Contact__c= cq.Id, BGBK__Expiration_DateTime__c=system.now().addDays(1));
        insert testCart;
        
        // add fees to cart
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__c=20, MUSW__Permit2__c=perm.Id, MUSW__Fee_Paid__c=false, BGBK__Cart__c = testCart.Id);
        MUSW__Fee__c f2 = new MUSW__Fee__c(MUSW__Amount__c=120, MUSW__Permit2__c=perm.Id, MUSW__Fee_Paid__c=false, BGBK__Cart__c = testCart.Id);
        MUSW__Fee__c[] fees = new MUSW__Fee__c[]{f1,f2};
        insert fees;

        BGBK.RulesEngineState.releaseLock();
        
        return testCart.id;
    }

    @isTest
    private static void testMisc()
    {
        Test.startTest();
        Id cartId = setupData();
        
        MUSW__Fee__c[] fees = [select id from MUSW__Fee__c where BGBK__Cart__c = :cartId];
        
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('cartId', cartId );
        Test.setCurrentPage(fp);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(fees);
        ssc.setSelected(fees);
        CartController fc = new CartController(ssc);
        fc.initOrder();
        // System.debug('==============> fee size ===>'+fc.fees.size());
        System.assert(fc.pmtMethods!=null && fc.pmtMethods.size()>0);
        System.assert(fc.totalPayment == 0);
        
        fc.accountChanged();
        
        Contact c1 = new Contact(Lastname='newTestUser123', Email='test1@test1.com');
        insert c1;
        fc.cart.BGBK__Contact__c = c1.id;
        fc.contactChanged();
        fc.cancelReconcile();
        
        fc.itemsUnselected = '';
        fc.refreshTotalAndCheckout();
        Test.stopTest();
    }
    
    @isTest
    private static void testAbandon()
    {
        Test.startTest();
        Id cartId = setupData();
        
        MUSW__Fee__c[] fees = [select id from MUSW__Fee__c where BGBK__Cart__c = :cartId];
        
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('cartId', cartId );
        Test.setCurrentPage(fp);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(fees);
        ssc.setSelected(fees);
        CartController fc = new CartController(ssc);
        fc.initOrder();
        System.assert(fc.abandon()!=null);
        fc.cancel();
        Test.stopTest();
    }
    
    @isTest
    private static void testReconcile()
    {
        Test.startTest();
        
        BGBK.RulesEngineState.setLock();                
    
        Contact c = new Contact(Lastname='reconcileUser', Email='test1@test1.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='reconcileParcel');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        BGBK__Cart__c testCart = new BGBK__Cart__c(BGBK__Account__c= cq.AccountId, BGBK__Contact__c= cq.Id, BGBK__Expiration_DateTime__c=system.now().addDays(1));
        insert testCart;
        
        // add fees to cart
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__c=20, MUSW__Permit2__c=perm.Id, MUSW__Fee_Paid__c=false, BGBK__Cart__c = testCart.Id);
        MUSW__Fee__c f2 = new MUSW__Fee__c(MUSW__Amount__c=120, MUSW__Permit2__c=perm.Id, MUSW__Fee_Paid__c=false, BGBK__Cart__c = testCart.Id);
        MUSW__Fee__c[] fees = new MUSW__Fee__c[]{f1,f2};
        insert fees;

        BGBK.RulesEngineState.releaseLock();
        
        Id cartId = setupData();
        
        MUSW__Fee__c[] fees1 = [select id from MUSW__Fee__c where BGBK__Cart__c = :cartId];
        
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('cartId', cartId );
        Test.setCurrentPage(fp);
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(fees1);
        ssc.setSelected(fees1);
        CartController fc = new CartController(ssc);
        fc.initOrder();
        
        fc.cart.BGBK__Contact__c = cq.id;
        fc.contactChanged();
        fc.doReconcile();
        Test.stopTest();
    }
    
    @isTest
    private static void testPaymentMethods()
    {
        BGBK__Payment_Method__mdt[] methods = [select DeveloperName, Label, BGBK__isPortal_Accessible__c, BGBK__isGateway_Required__c from BGBK__Payment_Method__mdt WHERE BGBK__isActive__c = true];
        pageReference fp = Page.Cart;
        
        CartController fc = new CartController(null);
        System.assertEquals(methods.size(),fc.pmtMethods.size());
        System.assertNotEquals(null,fc.receiptFields);
        
    }

    @isTest 
    private static void testPmtMethods() {
        BGBK.RulesEngineState.setLock();
                
        Contact c = new Contact(Lastname='TestUser123', Email='test@test.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__C=20, MUSW__Permit2__c=perm.Id);
        MUSW__Fee__c f2 = new MUSW__Fee__c(MUSW__Amount__C=120, MUSW__Permit2__c=perm.Id);
        MUSW__Fee__c[] fees = new MUSW__Fee__c[]{f1,f2};
        insert fees;

        MUSW__Receipt__c rec = new MUSW__Receipt__c();
        insert rec;
        
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('id', perm.Id);
        Test.setCurrentPage(fp);
        
        // pass fees as selections to controller
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(fees);
        ssc.setSelected(fees);
        CartController cc = new CartController(ssc);
        cc.initOrder();

        Selectoption[] pmtMethods1 = cc.pmtMethods;
        Boolean depositExists = false;
        for(SelectOption method : pmtMethods1) {
            if(method.getValue() == 'Deposit')
                depositExists = true;
        }
        System.assertEquals(false, depositExists);

        CartController.ReceiptVO newReceipt = new CartController.ReceiptVO(rec, 1.0, null);
        cc.receiptVOs.add(newReceipt);
        depositExists = false;
        cc.receiptVOs[0].pmtMethodSelected = 'Cheque';
        Selectoption[] pmtMethods2 = cc.pmtMethods;
        for(SelectOption method : pmtMethods2) {
            if(method.getValue() == 'Deposit')
                depositExists = true;
        }
        System.assertEquals(false, depositExists);
    }

    @isTest
    private static void testUseDeposit() {
        Contact c = new Contact(Lastname='TestUser123', Email='test@test.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__C=10,MUSW__Amount_Waived__c =0,MUSW__Amount_Paid__c =0,MUSW__Amended_Amount__c =0, MUSW__Permit2__c=perm.Id);
        insert f1;

        MUSW__Deposit__c deposit = new MUSW__Deposit__c(MUSW__Amount__c=50, MUSW__Permit2__c = perm.Id);
        insert deposit;

        MUSW__Receipt__c receipt = new MUSW__Receipt__c(MUSW__Amount_Tendered__c=50);
        insert receipt;

        MUSW__Payable_Receipt__c pReceipt = new MUSW__Payable_Receipt__c(MUSW__Receipt__c=receipt.Id, MUSW__Deposit__c=deposit.Id, MUSW__Amount__c=50);
        insert pReceipt;

        deposit = [SELECT Id, MUSW__Available_Amount__c FROM MUSW__Deposit__c WHERE Id = :deposit.Id];
        
        // set page 
        pageReference fp = Page.Cart;
        //fp.getParameters().put('id', perm.Id);
        fp.getParameters().put('feeId', f1.Id);
        fp.getParameters().put('depositId', deposit.Id);
        Test.setCurrentPage(fp);

        CartController cc = new CartController(null);
        cc.con = c;
        cc.initOrder();
        cc.rs[0].MUSW__Payment_Method__c = 'Deposit';
        cc.currentRowIndex = 0;
        cc.checkout();
        cc.receiptVOs[0].pmtMethodSelected = 'Deposit';
        cc.receiptVOs[0].payableReceipt.MUSW__Deposit__c = deposit.Id;
        cc.useDeposit();
        cc.currentRowIndex = 1;
        cc.validateAmount();
        cc.process();

        MUSW__Deposit__c usedDep = [SELECT MUSW__Amount__c,MUSW__Used_Amount__c,MUSW__Available_Amount__c FROM MUSW__Deposit__c WHERE Id=:deposit.Id];
        System.assertEquals(50, usedDep.MUSW__Amount__c);
        //System.assertEquals(10, usedDep.MUSW__Used_Amount__c);
        //System.assertEquals(40, usedDep.MUSW__Available_Amount__c);
    }

    @isTest
    private static void testInitFromDepositAccount() {
        Contact c = new Contact(Lastname='TestUser123', Email='test@test.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__C=10,MUSW__Amount_Waived__c =0,MUSW__Amount_Paid__c =0,MUSW__Amended_Amount__c =0, MUSW__Permit2__c=perm.Id);
        insert f1;

        MUSW__Deposit__c deposit = new MUSW__Deposit__c(MUSW__Amount__c=50, MUSW__Permit2__c = perm.Id, MUSW__Account__c=cq.AccountId);
        insert deposit;

        MUSW__Receipt__c rec = new MUSW__Receipt__c();
        insert rec;

        // set page 
        pageReference fp = Page.Cart;

        fp.getParameters().put('depositId', deposit.Id);
        fp.getParameters().put('depositAccountId', cq.AccountId);
        Test.setCurrentPage(fp);
        CartController cc = new CartController(null);

        List<SelectOption> acc = cc.accounts;
        if(acc != null && acc.size()>0){
            System.assertEquals(acc[0].getValue(), cq.AccountId);
        }
        System.assertEquals(null, cc.confirmMsg);
        System.assertEquals(null, cc.parentLabel);
        System.assertEquals(null, cc.processStatus);
        System.assertEquals(null, cc.cardMasked);
        System.assertEquals(null, cc.feeSelected);
        System.assertEquals(null, cc.delRecIndex);
        System.assertEquals(null, cc.feeIdsStr);
        System.assertEquals(null, cc.keepPolling);
        System.assertEquals(null, cc.jobId);
        System.assertEquals(null, cc.depositjobId);
        System.assertEquals(null, cc.currentReceiptIndex);

        // test if the vo and some methods are working, when coming from CarService constructor with account
        CartController.ReceiptVO newReceipt = new CartController.ReceiptVO(rec, 50.0, null);
        cc.receiptVOs.add(newReceipt);
        CartController.DepositVO newDeposit = new CartController.DepositVO(deposit,true);
        cc.depositVOs.add(newDeposit); 

        cc.keepPolling = false;

        cc.refreshFeesTab();
        cc.accountChanged();
        cc.checkout();
    }

 /*   @isTest
    private static void testBatchJobPoll() {  
        BGBK.RulesEngineState.setLock();                
        MUSW.TriggerBlocker.blockAllTriggers = true;

        Account acc = new Account(Name='TestUser6788');
        insert acc;
        Contact c = new Contact(Lastname='TestUser6788', Email='test21212@test.com', AccountId=acc.Id);
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id);
        insert perm;
        BGBK__Cart__c testCart = new BGBK__Cart__c(BGBK__Account__c= cq.AccountId, BGBK__Contact__c= cq.Id, BGBK__Expiration_DateTime__c=system.now().addDays(1));
        insert testCart;
        
        // add fees to cart
        List<MUSW__Fee__c> fees = new List<MUSW__Fee__c>();
        //create over 150 fees in order to be a batch job
        for(Integer feeCounter=0; feeCounter<=150; feeCounter++) {
            fees.add(new MUSW__Fee__c(MUSW__Amount__c=10, MUSW__Permit2__c=perm.Id, MUSW__Fee_Paid__c=false, BGBK__Cart__c=testCart.Id, MUSW__Amended_Amount__c=0, MUSW__Amount_Waived__c=0));
        }
        insert fees;     

        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('cartId', testCart.Id);
        Test.setCurrentPage(fp);
        
        CartController fc = new CartController(null);
        fc.initOrder();
        //set amount to be used to pay fees
        fc.rs[0].MUSW__Amount_Tendered__c = 2000;
        fc.accountSelected = cq.AccountId;
        fc.Checkout();
        fc.review();  
        MUSW.TriggerBlocker.blockAllTriggers = false;
        BGBK.RulesEngineState.releaseLock();

        Test.startTest();
        //create batch job to pay fees
        fc.process();
        Test.stopTest();

        //fc.batchJobPoll();

        List<MUSW__Fee__c> bulkPaidFees = [SELECT MUSW__Fee_Paid__c FROM MUSW__Fee__c WHERE BGBK__Cart__c=:testCart.Id];
        for(MUSW__Fee__c fee : bulkPaidFees) {
            //check that all fees were paid
            //System.assertEquals(true, fee.MUSW__Fee_Paid__c);
        }
    }*/

    @isTest
    private static void testUseInvoice() {
        Account account = new Account(Name='Test Account');
        insert account;
                     
        Contact c = new Contact(LastName='Test Contact',FirstName='BasicGov', Email='test@basicgov.com',Account=account,MUSW__Account_Relationship__c='Owner', AccountId = account.Id);
        insert c;
       
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        BGBK__Cart__c testCart = new BGBK__Cart__c(BGBK__Account__c= cq.AccountId, BGBK__Contact__c= cq.Id, BGBK__Expiration_DateTime__c=system.now().addDays(1));
        insert testCart;
        
        // add fees to cart
        
        randomNum = Math.round(Math.random()*100000);
        String InvoiceNum1 = 'BGT-'+randomNum.format();
                
        BGBK__Bill__c inv1 = new BGBK__Bill__c(BGBK__Tracking_Number__c=InvoiceNum1,BGBK__Total_Fees__c=25,BGBK__Total_Payments__c=0);
        insert inv1;
                
        MUSW__Fee__c f1 = new MUSW__Fee__c(MUSW__Amount__c=25, MUSW__Permit2__c=perm.Id, BGBK__Cart__c = testCart.Id,BGBK__Invoice__c=inv1.Id);
        insert f1;
       
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('feeId', f1.Id);
        fp.getParameters().put('invoiceId', inv1.Id);
        Test.setCurrentPage(fp);
        
        CartController fc = new CartController(null);
        fc.initOrder();
        List<SelectOption> accs = fc.accounts;
        fc.rs[0].MUSW__Payment_Method__c = 'Credit Card';
        fc.accountSelected = cq.AccountId ;
        fc.Checkout();
        fc.review();

        fc.process();

        BGBK__Bill__c inv2 = [SELECT BGBK__Total_Fees__c,BGBK__Total_Payments__c FROM BGBK__Bill__c WHERE Id=:inv1.Id];
        MUSW__Fee__c f2 = [SELECT MUSW__Amount__c,MUSW__Amount_Paid__c,MUSW__Fee_Paid__c FROM MUSW__Fee__c WHERE Id=:f1.Id];

        //System.assertEquals(25, inv2.BGBK__Total_Payments__c);
        //System.assertEquals(true, f2.MUSW__Fee_Paid__c);
    }

    @isTest 
    private static void testReceiptCleaningAfterFailure() {
       BGBK.RulesEngineState.setLock();                
        
        Contact c = new Contact(Lastname='TestUser123', Email='test@test.com');
        insert c;
        Contact cq = [select AccountId from Contact where Id=:c.Id];
        
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='xyz123abc');
        insert par;
        BGBK__Cart__c testCart = new BGBK__Cart__c(BGBK__Account__c= cq.AccountId, BGBK__Contact__c= cq.Id, BGBK__Expiration_DateTime__c=system.now().addDays(-2));
        insert testCart;
        
        MUSW__Permit2__c perm = new MUSW__Permit2__c(MUSW__Type__c='Building', MUSW__Parcel__c=par.id, MUSW__Applicant__c=c.Id, AVO_Permitted_Acres__c = 10);
        insert perm;
        
        // add fee to cart
        MUSW__Fee__c fee = new MUSW__Fee__c(MUSW__Amount__c=20, MUSW__Permit2__c=perm.Id, BGBK__Cart__c = testCart.Id);
        insert fee;
        
        // set page 
        pageReference fp = Page.Cart;
        fp.getParameters().put('cartId',  testCart.Id );
        Test.setCurrentPage(fp);
        
        CartController fc = new CartController(null);
        fc.initOrder();
        List<SelectOption> accs = fc.accounts;
        fc.addReceipt();
        fc.rs[0].MUSW__Payment_Method__c = 'Cash';
        fc.rs[0].MUSW__Amount_Tendered__c = 300;
        fc.accountSelected = cq.AccountId;
        fc.Checkout();
        fc.review();
        
        BGBK.RulesEngineState.releaseLock();
        
        fc.process();
        MUSW__Receipt__c[] rec = [select Id, Name from MUSW__Receipt__c where BGBK__Cart__c =: testCart.Id];
        System.assertEquals(0,rec.size());
    }
}