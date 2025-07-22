@isTest
private class DepositAddControllerTest
{
  private static MUSW__Deposit__c dep;
  private static MUSW__Deposit__c dep2;

  @isTest
  private static void testDepositAddTest()
  {
    setupTestData();

    // set page 
    PageReference depositAddPage = Page.DepositAdd;
    depositAddPage.getParameters().put('depositIds', dep.Id + ',' + dep2.Id);
    Test.setCurrentPage(depositAddPage);
    ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<MUSW__Deposit__c>{dep,dep2});
    DepositAddController dtc = new DepositAddController(ssc);
    System.assertNotEquals(null,dtc.initOrder());
    System.assertNotEquals(null,dtc);
  }

  /**
    *   Preparation of the test data
    */
    @testSetup
    private static void setupTestData() {
        try{

           MUSW__Permit2__c testPermit = new MUSW__Permit2__c(MUSW__Type__c='Building',MUSW__Work_Type__c='New', AVO_Volumetric_Limits__c = 10);
          insert testPermit;

          MUSW__Deposit__c deposit = new MUSW__Deposit__c(MUSW__Amount__c=5000, MUSW__Permit2__c = testPermit.Id);
          insert deposit;

          MUSW__Deposit__c deposit2 = new MUSW__Deposit__c(MUSW__Amount__c=5000, MUSW__Permit2__c = testPermit.Id,MUSW__Transfered_In_Amount__c=4000);
          insert deposit2;

          dep = deposit;
          dep2 = deposit2;
        }
        catch(Exception ex){
            throw ex;
        }
    }
}