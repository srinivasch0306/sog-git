@isTest
private class BB_TriggerHandlerTest {
    @testSetup
    static void setup() {
        String SERVICE_ACCOUNT = 'Bluebeam';
        String USER_EMAIL = 'bb@bbemail.com';
        String USER_ACCOUNT = 'Bluebeam_'+USER_EMAIL;
        
        //service oauth property
        MUSW__OAuth_Properties__c serviceOAuth = new MUSW__OAuth_Properties__c();
        serviceOAuth.Name = SERVICE_ACCOUNT;
        serviceOAuth.MUSW__Authentication_URL__c = 'authentication_url/';
        serviceOAuth.MUSW__Base_URL__c = 'baseurl/v1/';
        serviceOAuth.MUSW__Client_Id__c = 'clientid';
        serviceOAuth.MUSW__Client_Secret__c = BGCM.UtilityCrypto.encrypt('clientsecret');
        serviceOAuth.MUSW__Redirect_URL__c = 'redirecturl/';
        serviceOAuth.MUSW__Access_Expires__c = Datetime.now().addMinutes(60); // 60 minutes
        serviceOAuth.MUSW__Refresh_Expires__c = Datetime.now().addMinutes(60*24*60); // 60 days
        serviceOAuth.MUSW__Part01__c = BGCM.UtilityCrypto.encrypt('hd78wseroggsdhf');
        serviceOAuth.MUSW__Part02__c = BGCM.UtilityCrypto.encrypt('hdgf534twrmmmhd');
        serviceOAuth.MUSW__Part03__c = BGCM.UtilityCrypto.encrypt('3w589ngfgdfdghs');
        serviceOAuth.MUSW__IsRefreshingAccessToken__c = false;
        insert serviceOAuth;

        //user oauth property
        MUSW__OAuth_Properties__c userOAuth = new MUSW__OAuth_Properties__c();
        userOAuth.Name = USER_ACCOUNT;
        userOAuth.MUSW__Authentication_URL__c = 'authentication_url/';
        userOAuth.MUSW__Base_URL__c = 'baseurl/v1/';
        userOAuth.MUSW__Client_Id__c = 'clientid';
        userOAuth.MUSW__Client_Secret__c = BGCM.UtilityCrypto.encrypt('clientsecret');
        userOAuth.MUSW__Redirect_URL__c = 'redirecturl/';
        userOAuth.MUSW__Access_Expires__c = Datetime.now().addMinutes(60); // 60 minutes
        userOAuth.MUSW__Refresh_Expires__c = Datetime.now().addMinutes(60*24*60); // 60 days
        userOAuth.MUSW__Part01__c = BGCM.UtilityCrypto.encrypt('hd78wseroggsdhf');
        userOAuth.MUSW__Part02__c = BGCM.UtilityCrypto.encrypt('hdgf534twrmmmhd');
        userOAuth.MUSW__Part03__c = BGCM.UtilityCrypto.encrypt('3w589ngfgdfdghs');
        userOAuth.MUSW__IsRefreshingAccessToken__c = false;
        insert userOAuth;
    }

    @isTest
    static void createApplication() {
        Test.setMock(HttpCalloutMock.class, new MUSW.BluebeamMockHttpResponseGenerator());

        MUSW__Application2__c app = new MUSW__Application2__c();
        app.Name = 'test_app_2';

        Test.startTest();
            insert app;
        Test.stopTest();
    }
    
    @isTest
    static void createPermit() {
        Test.setMock(HttpCalloutMock.class, new MUSW.BluebeamMockHttpResponseGenerator());

        MUSW__Permit2__c perm = new MUSW__Permit2__c();
        perm.Name = 'test_perm_2';
        perm.AVO_Volumetric_Limits__c = 10;

        Test.startTest();
            insert perm;
            perm.Name = 'test_perm_3';
            perm.MUSW__Type__c = 'testType'; 
            update perm;
        Test.stopTest();
    }

    @isTest 
    static void addReviewOwner() {
        Test.setMock(HttpCalloutMock.class, new MUSW.BluebeamMockHttpResponseGenerator());

        MUSW__Application2__c app = new MUSW__Application2__c();
        app.Name = 'test_app_1';
        app.MUSW__BG_Bluebeam_Project_Id__c = '123-123-123';
        insert app;

        MUSW__Milestone__c mile = new MUSW__Milestone__c();
        mile.Name = 'test_mile_1';
        mile.MUSW__Application2__c = app.Id;
        insert mile;

        MUSW__Review__c rev = new MUSW__Review__c();
        rev.Name = 'test_rev_1';
        rev.MUSW__Milestone__c = mile.Id;

        String profileName = 'System Administrator';
        String lastName = 'JOHNSMITH';
        String email = 'bb@bbemail.com';

        String query = 'SELECT Id FROM Profile WHERE Name = \'' + profileName + '\'';
        Profile profile =  Database.query(query);

        User user1 = new User(
            ProfileId = profile.Id,
            LastName = lastName,
            Email = email,
            Username = email + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US');

        user1.MUSW__BG_Bluebeam_Email_Address__c = email;
        Database.insert(user1);

        System.runAs(user1){      
            Test.startTest(); 
                insert rev;
            Test.stopTest();
        }
    }
}