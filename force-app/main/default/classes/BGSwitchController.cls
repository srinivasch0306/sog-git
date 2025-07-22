public class BGSwitchController {
    final String MSG_WELCOME = 'Welcome to BG Switch.';
    final String MSG_SYSTEM_TEST_TOGGLE = 'Smoke Test Mode now ';
    final String MSG_BG_DELETE = 'Conversion to provisioning org complete.';
    final String MSG_NOT_FOUND = 'No records found for ';
    final String TEST_DATA_PREFIX = 'TD-%';
    final String SYSTEM_TEST_PREFIX = 'SYSTEM TEST%';
    final String SYSTEM_TEST_TOGGLE_ON = 'on.';
    final String SYSTEM_TEST_TOGGLE_OFF = 'off.';
    final String MENU_SYSTEM_TEST_DEACTIVATE = 'Deactivate Smoke Test Mode';
    final String MENU_SYSTEM_TEST_ACTIVATE = 'Activate Smoke Test Mode';
    final String MENU_BECOME_PROVISIONING = 'Convert to Provisioning Org';
    final String MENU_ALREADY_PROVISIONING = 'Already a Provisioning Org';
 
    public Boolean isDRESystemTestActive;
    public Boolean isProvisioningOrg;
    public String alert {get; set;}
    public String toggleDRESystemTestCaption {get; set;}
    public String toggleDRESystemTestIcon {get; set;}
    public String toggleProvisioningCaption {get; set;}
    public String toggleProvisioningIcon {get; set;}
    public String toggleProvisioningClickAction {get; set;}
    
    public PageReference becomeProvisioningOrg() {
        if (!isProvisioningOrg) {
            isProvisioningOrg = !isProvisioningOrg;
            // Method to delete all BG training data.
            //clearBGTrainingData();
            
            // UI
            this.alert = MSG_BG_DELETE;
            updateConvertProvisioningDisplay(isProvisioningOrg);
        }
        
        return null;
    }
    
    public PageReference toggleDRESystemTest() {        
        // Flip the switch and updates rule status
        isDRESystemTestActive = !isDRESystemTestActive;
        DRE__DRE_Rule__c[] rs = [SELECT name, DRE__IsActive__c FROM DRE__DRE_Rule__c WHERE Name LIKE :SYSTEM_TEST_PREFIX];
        for (DRE__DRE_Rule__c r : rs) {
            r.DRE__IsActive__c = isDRESystemTestActive;
        }
        update rs;
        
        // Creates Master Object records for use by DRE2 as global tables
        if (isDRESystemTestActive) {addMasterObjectRecords();}
        // Deletes Master Object records when SYSTEM TEST rules are deactivated
        else {deleteMasterObjectRecords();}
        
        // UI
        String wordify = (isDRESystemTestActive) ? SYSTEM_TEST_TOGGLE_ON : SYSTEM_TEST_TOGGLE_OFF;
        this.alert = MSG_SYSTEM_TEST_TOGGLE + wordify;
        updateDRESystemTestDisplay(isDRESystemTestActive);
        
        return null;
    }    
    
    private void queryDRESystemTestState() {
        // Used to determine initial toggle state
        List<AggregateResult> result  = [SELECT count(id) total FROM DRE__DRE_Rule__c WHERE Name LIKE :SYSTEM_TEST_PREFIX AND DRE__IsActive__c = false];
        isDRESystemTestActive = (result[0].get('total') == 0) ? true : false;
        updateDRESystemTestDisplay(isDRESystemTestActive);
    }
    
    private void queryTrainingDataExist() {
        // Used to determine initial toggle state
        List<AggregateResult> parcel = [SELECT count(id) total FROM MUSW__Parcel__c];
        List<AggregateResult> ordinance = [SELECT count(id) total FROM MUSW__Violation_Type__c];
        isProvisioningOrg = (parcel[0].get('total') == 0) ? true : false;
        isProvisioningOrg |= (ordinance[0].get('total') ==0) ? true : false;
        updateConvertProvisioningDisplay(isProvisioningOrg);
    }
    
    private void updateDRESystemTestDisplay(Boolean state) {
        // UI
        this.toggleDRESystemTestCaption = (state) ? MENU_SYSTEM_TEST_DEACTIVATE : MENU_SYSTEM_TEST_ACTIVATE;
        this.toggleDRESystemTestIcon = (state) ? 'fa-toggle-on' : 'fa-toggle-off';        
    }
    
    private void updateConvertProvisioningDisplay(Boolean state) {
        // UI
        this.toggleProvisioningCaption = (state) ? MENU_ALREADY_PROVISIONING : MENU_BECOME_PROVISIONING;
        this.toggleProvisioningIcon = (state) ? 'fa-handshake-o' : 'fa-list-ul';
        this.toggleProvisioningClickAction = (state) ? '' : 'if (confirmConversion()) return clearBGTrainingData();';
    }
    
    public void setInitialValues() {
        // Main init method
        this.alert = MSG_WELCOME;
        queryDRESystemTestState();
        queryTrainingDataExist();
    }
    
    private void clearBGTrainingData() {
        // Delete Parcel records
        delete [SELECT id FROM MUSW__Parcel__c];
        
        // Delete Ordinance records
        delete [SELECT id FROM MUSW__Violation_Type__c];
    }
    
    private void deleteMasterObjectRecords() {
        delete [SELECT id FROM MUSW__Master_Distribution_List__c WHERE Name LIKE :TEST_DATA_PREFIX];
        delete [SELECT id FROM MUSW__Master_Fee_List__c WHERE Name LIKE :TEST_DATA_PREFIX];
        delete [SELECT id FROM MUSW__Master_Inspection_List__c WHERE Name LIKE :TEST_DATA_PREFIX];
        delete [SELECT id FROM MUSW__Master_Submission_list__c WHERE Name LIKE :TEST_DATA_PREFIX];
        delete [SELECT id FROM MUSW__Master_Valuation_List__c WHERE Name LIKE :TEST_DATA_PREFIX];
    }
    
    private void addMasterObjectRecords() {
        addMasterDistributionListRecords();
        addMasterFeeListRecords();
        addMasterInspectionLists();
        addMasterSubmissionLists();
        addMasterValuationLists();
    }
    
    private void addMasterDistributionListRecords() {
        MUSW__Master_Distribution_List__c[] mdls = new MUSW__Master_Distribution_List__c[]{};
        
        // DR-00000
        MUSW__Master_Distribution_List__c mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00000',
                                                   Amount__c = '{!MUSW__Fee_Payment__c.MUSW__Payment_Amount__c}',
                                                   Business_Event__c = 'Fee Payment Created',
                                                   Credit_Code__c = '{!MUSW__Fee_Payment__c.Fee_AR_Code__c}',
                                                   Debit_Code__c = '{!MUSW__Fee_Payment__c.Fee_Cash_Code__c}',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Fee Payment',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Fee_Payment__c.MUSW__Receipt__r.MUSW__Paid_By__c}',
                                                   Transaction_Type__c = 'Payment Allocation'
                                                  );
        mdls.add(mdl);
        
        // DR-00001
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00001',
                                                   Amount__c = '{!MUSW__Fee__c.MUSW__Outstanding_Fee__c}',
                                                   Business_Event__c = 'Fee Waived',
                                                   Credit_Code__c = '=CONCAT("Rev_",{!MUSW__Fee__c.MUSW__Type__c})',
                                                   Debit_Code__c = '=CONCAT("AR_",{!MUSW__Fee__c.MUSW__Type__c})',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Fee',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Fee__c.Related_Account__c}',
                                                   Transaction_Type__c = 'Revenue Adjustment'
                                                  );
        mdls.add(mdl);

        // DR-00002
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00002',
                                                   Amount__c = '{!MUSW__Receipt__c.MUSW__Amount_Tendered__c}',
                                                   Business_Event__c = 'Receipt Created',
                                                   Credit_Code__c = 'AP_GL',
                                                   Debit_Code__c = 'OverpaymentCash_GL',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Receipt',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Receipt__c.MUSW__Paid_By__c}',
                                                   Transaction_Type__c = 'Payment Received'
                                                  );
        mdls.add(mdl);

        // DR-00003
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00003',
                                                   Amount__c = '=SUB({!MUSW__Receipt__c.MUSW__Amount_Used__c},{!^MUSW__Receipt__c.MUSW__Amount_Used__c})',
                                                   Business_Event__c = 'Receipt Allocation / Unallocation',
                                                   Credit_Code__c = 'OverpaymentCash_GL',
                                                   Debit_Code__c = 'AP_GL',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Receipt',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Receipt__c.MUSW__Paid_By__c}',
                                                   Transaction_Type__c = 'Payment Allocation / Unallocation'
                                                  );
        mdls.add(mdl);

        // DR-00004
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00004',
                                                   Amount__c = '=SUB({!MUSW__Receipt__c.musw__amount_refunded__c}, {!^MUSW__Receipt__c.musw__amount_refunded__c})',
                                                   Business_Event__c = 'Receipt Refunded',
                                                   Credit_Code__c = 'OverpaymentCash_GL',
                                                   Debit_Code__c = 'AP_GL',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Receipt',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Receipt__c.MUSW__Paid_By__c}',
                                                   Transaction_Type__c = 'Payment Refunded'
                                                  );
        mdls.add(mdl);

        // DR-00005
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00005',
                                                   Amount__c = '{!MUSW__Receipt__c.MUSW__Amount_Tendered__c}',
                                                   Business_Event__c = 'Receipt Rejected',
                                                   Credit_Code__c = 'OverpaymentCash_GL',
                                                   Debit_Code__c = 'AP_GL',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Receipt',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Receipt__c.MUSW__Paid_By__c}',
                                                   Transaction_Type__c = 'Payment Rejected'
                                                  );
        mdls.add(mdl);

        // DR-00006
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00006',
                                                   Amount__c = '{!MUSW__Fee_Payment__c.MUSW__Payment_Amount__c}',
                                                   Business_Event__c = 'Fee Payment Adjusted',
                                                   Credit_Code__c = '{!MUSW__Fee_Payment__c.Fee_AR_Code__c}',
                                                   Debit_Code__c = '{!MUSW__Fee_Payment__c.Fee_Cash_Code__c}',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Fee Payment',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Fee_Payment__c.MUSW__Receipt__r.MUSW__Paid_By__c}',
                                                   Transaction_Type__c = 'Payment Unallocation'
                                                  );
        mdls.add(mdl);

        // DR-00007
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00007',
                                                   Amount__c = '{!MUSW__Fee__c.MUSW__Outstanding_Fee__c}',
                                                   Business_Event__c = 'Fee Created',
                                                   Credit_Code__c = '=CONCAT("Rev_",{!MUSW__Fee__c.MUSW__Type__c})',
                                                   Debit_Code__c = '=CONCAT("AR_",{!MUSW__Fee__c.MUSW__Type__c})',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Fee',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Fee__c.Related_Account__c}',
                                                   Transaction_Type__c = 'Revenue Recognition'
                                                  );
        mdls.add(mdl);

        // DR-00008
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00008',
                                                   Amount__c = '{!MUSW__Receipt__c.MUSW__Amount_Available__c}',
                                                   Business_Event__c = 'Receipt Allocation Adjusted',
                                                   Credit_Code__c = 'OverpaymentCash_GL',
                                                   Debit_Code__c = 'AP_GL',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Receipt',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = null,
                                                   Transaction_Type__c = 'Payment Unallocation'
                                                  );
        mdls.add(mdl);

        // DR-00009
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00009',
                                                   Amount__c = '{!MUSW__Fee__c.MUSW__Outstanding_Fee__c}',
                                                   Business_Event__c = 'Fee Corrected',
                                                   Credit_Code__c = '=CONCAT("Rev_",{!MUSW__Fee__c.MUSW__Type__c})',
                                                   Debit_Code__c = '=CONCAT("AR_",{!MUSW__Fee__c.MUSW__Type__c})',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Fee',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Fee__c.Related_Account__c}',
                                                   Transaction_Type__c = 'Revenue Adjustment'
                                                  );
        mdls.add(mdl);

        // DR-00010
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00010',
                                                   Amount__c = '=SUB({!MUSW__Deposit__c.musw__paid_amount__c},{!^MUSW__Deposit__c.musw__paid_amount__c})',
                                                   Business_Event__c = 'Deposit Collection',
                                                   Credit_Code__c = '{!MUSW__Deposit__c.Deposit_AP__c}',
                                                   Debit_Code__c = '{!MUSW__Deposit__c.Deposit_Cash__c}',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Deposit',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Deposit__c.MUSW__Account__c}',
                                                   Transaction_Type__c = 'Deposit Collection'
                                                  );
        mdls.add(mdl);

        // DR-00011
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00011',
                                                   Amount__c = '=SUB({!MUSW__Deposit__c.MUSW__Refunded_Amount__c},{!^MUSW__Deposit__c.MUSW__Refunded_Amount__c})',
                                                   Business_Event__c = 'Deposit Refunded',
                                                   Credit_Code__c = '{!MUSW__Deposit__c.Deposit_Cash__c}',
                                                   Debit_Code__c = '{!MUSW__Deposit__c.Deposit_AP__c}',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Deposit',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Deposit__c.MUSW__Account__c}',
                                                   Transaction_Type__c = 'Deposit Refunded'
                                                  );
        mdls.add(mdl);

        // DR-00012
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00012',
                                                   Amount__c = '=SUB({!MUSW__Deposit__c.MUSW__Used_Amount__c},{!^MUSW__Deposit__c.MUSW__Used_Amount__c})',
                                                   Business_Event__c = 'Deposit Allocation / Unallocation',
                                                   Credit_Code__c = '{!MUSW__Deposit__c.Deposit_Cash__c}',
                                                   Debit_Code__c = '{!MUSW__Deposit__c.Deposit_AP__c}',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Deposit',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Deposit__c.MUSW__Account__c}',
                                                   Transaction_Type__c = 'Deposit Allocation / Unallocation'
                                                  );
        mdls.add(mdl);

        // DR-00013
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00013',
                                                   Amount__c = '=SUB({!MUSW__Deposit__c.MUSW__Transfered_In_Amount__c},{!^MUSW__Deposit__c.MUSW__Transfered_In_Amount__c})',
                                                   Business_Event__c = 'Deposit Transfer In',
                                                   Credit_Code__c = '{!MUSW__Deposit__c.Deposit_AP__c}',
                                                   Debit_Code__c = '{!MUSW__Deposit__c.Deposit_Cash__c}',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Deposit',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Deposit__c.MUSW__Account__c}',
                                                   Transaction_Type__c = 'Deposit Transfer In'
                                                  );
        mdls.add(mdl);

        // DR-00014
        mdl =
            new MUSW__Master_Distribution_List__c (Name = 'TD-00014',
                                                   Amount__c = '=SUB({!MUSW__Deposit__c.MUSW__Transfered_Out_Amount__c},{!^MUSW__Deposit__c.MUSW__Transfered_Out_Amount__c})',
                                                   Business_Event__c = 'Deposit Transfer Out',
                                                   Credit_Code__c = '{!MUSW__Deposit__c.Deposit_Cash__c}',
                                                   Debit_Code__c = '{!MUSW__Deposit__c.Deposit_AP__c}',
                                                   Description__c = null,
                                                   Effective_Date__c = '=TODAY()',
                                                   Object_Name__c = 'Deposit',
                                                   Old_Amount__c = null,
                                                   Transaction_Account__c = '{!MUSW__Deposit__c.MUSW__Account__c}',
                                                   Transaction_Type__c = 'Deposit Transfer Out'
                                                  );
        mdls.add(mdl);

        insert mdls;
    }
    
    private void addMasterFeeListRecords() {
        MUSW__Master_Fee_List__c mfl = 
            new MUSW__Master_Fee_List__c(Name = 'TD-Construction Charges',
                                         Use_Group__c = 'R-1;R-2;R-3;R-4',
                                         Work_Type__c = 'New;Addition',
                                         Fee_Type__c = 'Building Fees',
                                         Permit_Type__c = null,
                                         Effective_Start_Date__c = Date.parse('1/1/2017'),
                                         Flat_Amount__c = 125,
                                         GL_Account__c = '0123456789', 
                                         Fee_Formula_Amount__c = '=MULT({!$MUSW__Master_Fee_List__c.Flat_Amount__c},{!MUSW__Permit2__c.MUSW__Construction_Area__c},0.25)',
                                         Subtype__c = null,
                                         Effective_End_Date__c = null,
                                         License_Type__c = null
                                        );
        insert mfl;
    }
    
    private void addMasterInspectionLists() {
        MUSW__Master_Inspection_List__c mil = 
            new MUSW__Master_Inspection_List__c (Name = 'TD-BLD - Preliminary',
                                                 Use_Group__c = 'R-1;R-2;R-3;R-4',
                                                 Work_Type__c = 'New;Addition;Alteration',
                                                 Record_Type__c = 'Building',
                                                 Permit_Type__c = null,
                                                 Effective_Start_Date__c = Date.parse('1/1/2017'),
                                                 Owner_Queue_User__c = 'Building',
                                                 Due_Date__c = '=ADDBUSDAYS(TODAY(),60)',
                                                 Checklist_Type__c = null,
                                                 Owner_Queue_ID__c = null,
                                                 Effective_End_Date__c = null
                                                );
        insert mil;
    }
    
    private void addMasterSubmissionLists() {
        MUSW__Master_Submission_List__c[] msls = new MUSW__Master_Submission_List__c[]{};

        // Building Plans
        MUSW__Master_Submission_List__c msl = 
            new MUSW__Master_Submission_List__c (Name = 'TD-Building Plans',
                                                 Due_Date__c = '=TODAY()',
                                                 Effective_End_Date__c = null,
                                                 Effective_Start_Date__c = Date.parse('1/1/2017'),
                                                 License_Type__c = null,
                                                 Permit_Type__c = null,
                                                 Required__c = true,
                                                 Subtype__c = 'Single Family Home;Multi Family Dwelling',
                                                 Title__c = 'Building Plans (Blue Prints)',
                                                 Use_Group__c = 'R-1;R-2;R-3;R-4',
                                                 Work_Type__c = 'New;Addition;Alteration'
                                                );
        msls.add(msl);

        // Site Plan
        msl =
            new MUSW__Master_Submission_list__c (Name = 'TD-Site Plan',
                                                 Due_Date__c = '=ADDDAYS(TODAY(),5)',
                                                 Effective_End_Date__c = null,
                                                 Effective_Start_Date__c = Date.parse('1/1/2017'),
                                                 License_Type__c = null,
                                                 Permit_Type__c = null,
                                                 Required__c = true,
                                                 Subtype__c = 'Single Family Home;Multi Family Dwelling',
                                                 Title__c = 'Site Plans (Blue Prints)',
                                                 Use_Group__c = 'R-1;R-2;R-3;R-4',
                                                 Work_Type__c = 'Demolition;Repair'
                                                );
        msls.add(msl);
        
        // Proof of Insurance
        msl =
            new MUSW__Master_Submission_list__c (Name = 'TD-Proof of Insurance',
                                                 Due_Date__c = '=ADDBUSDAYS(TODAY(),5)',
                                                 Effective_End_Date__c = null,
                                                 Effective_Start_Date__c = Date.parse('1/1/2017'),
                                                 License_Type__c = null,
                                                 Permit_Type__c = null,
                                                 Required__c = true,
                                                 Subtype__c = 'Single Family Home;Multi Family Dwelling',
                                                 Title__c = 'Proof of Insurance',
                                                 Use_Group__c = 'R-1;R-2;R-3;R-4',
                                                 Work_Type__c = 'New;Addition;Alteration;Demolition;Repair'
                                                );
        msls.add(msl);

        // Submission 1
        msl =
            new MUSW__Master_Submission_list__c (Name = 'TD-Business',
                                                 Due_Date__c = null,
                                                 Effective_End_Date__c = null,
                                                 Effective_Start_Date__c = null,
                                                 License_Type__c = null,
                                                 Permit_Type__c = null,
                                                 Required__c = false,
                                                 Subtype__c = null,
                                                 Title__c = 'Submission 1',
                                                 Use_Group__c = null,
                                                 Work_Type__c = null
                                                );
        msls.add(msl);
        
        // Submission 2
        msl =
            new MUSW__Master_Submission_list__c (Name = 'TD-Business',
                                                 Due_Date__c = null,
                                                 Effective_End_Date__c = null,
                                                 Effective_Start_Date__c = null,
                                                 License_Type__c = null,
                                                 Permit_Type__c = null,
                                                 Required__c = false,
                                                 Subtype__c = null,
                                                 Title__c = 'Submission 2',
                                                 Use_Group__c = null,
                                                 Work_Type__c = null
                                                );
        msls.add(msl);

        insert msls;
    }
    
    private void addMasterValuationLists() {
        // Currently blank
        // MUSW__Master_Valuation_List__c
    }
        
}