@isTest
public class InspectionRequestControllerTest {
	@isTest(SeeAllData=true)
    private static void testCon_withParent()
    {
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='zsdfsf');
        insert par;
        MUSW__Permit2__c p = new MUSW__Permit2__c(name = 'testluc', MUSW__Parcel__c=par.Id, AVO_Volumetric_Limits__c= 10);
        insert p;
        
        pageReference pr = Page.InspectionRequest;
        pr.getParameters().put('pid', p.id );
        Test.setCurrentPage( pr );
        
        InspectionRequestController c = new InspectionRequestController();
        c.insSelectIndex = 0;
        c.save();
    }
    
    @isTest(SeeAllData=true)
    private static void testCon_withoutParent()
    {
        MUSW__Parcel__c par = new MUSW__Parcel__c(Name='zsdfsf');
        insert par;
        Account a = new Account(Name = 'Test Class');
        insert a;
        
        pageReference pr = Page.InspectionRequest;
        pr.getParameters().put('pid', a.id );
        Test.setCurrentPage( pr );
        
        InspectionRequestController c = new InspectionRequestController();
        c.insSelectIndex = 0;
        c.save();
    }
    
}