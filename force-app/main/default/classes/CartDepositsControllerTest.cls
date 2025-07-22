@isTest
private class CartDepositsControllerTest
{
  private static MUSW__Deposit__c dep;
  private static MUSW__Deposit__c dep2;

  @isTest
  private static void testTopupDepositAmount()
  {
    setupTestData();

    MUSW__Deposit__c deposit =  [SELECT Id, MUSW__Amount__c,MUSW__Unpaid_Amount__c,MUSW__Transfered_In_Amount__c,MUSW__Used_Amount__c,MUSW__Available_Amount__c,MUSW__Transfered_Out_Amount__c FROM MUSW__Deposit__c WHERE Id = :dep.Id];

    // set page 
    pageReference depositAmountPage = Page.CartDeposits;
    depositAmountPage.getParameters().put('depositId', deposit.Id);
    Test.setCurrentPage(depositAmountPage);
    CartDepositsController dtc = new CartDepositsController();

    dtc.depositAmount = 6000;
    dtc.processDepositAmount();

    deposit =  [SELECT Id, MUSW__Amount__c,MUSW__Available_Amount__c FROM MUSW__Deposit__c WHERE Id = :dep.Id];

    System.assertEquals(6000,deposit.MUSW__Amount__c);
    System.assertEquals(0,deposit.MUSW__Available_Amount__c);
  }

  @isTest
  private static void testTopupDepositAmountWithTransferIn()
  {
    setupTestData();

    MUSW__Deposit__c deposit =  [SELECT Id, MUSW__Amount__c,MUSW__Unpaid_Amount__c,MUSW__Transfered_In_Amount__c,MUSW__Used_Amount__c,MUSW__Available_Amount__c,MUSW__Transfered_Out_Amount__c FROM MUSW__Deposit__c WHERE Id = :dep2.Id];

    // set page 
    pageReference depositAmountPage = Page.CartDeposits;
    depositAmountPage.getParameters().put('depositId', deposit.Id);
    Test.setCurrentPage(depositAmountPage);
    CartDepositsController dtc = new CartDepositsController();

    dtc.depositAmount = 3000;
    dtc.processDepositAmount();

    deposit =  [SELECT Id, MUSW__Amount__c,MUSW__Available_Amount__c FROM MUSW__Deposit__c WHERE Id = :dep2.Id];

    System.assertEquals(7000,deposit.MUSW__Amount__c);
    System.assertEquals(4000,deposit.MUSW__Available_Amount__c);
  }

  @isTest
  private static void testTopupDepositAWithoutAmount()
  {
    setupTestData();

    MUSW__Deposit__c deposit =  [SELECT Id, MUSW__Amount__c,MUSW__Unpaid_Amount__c,MUSW__Transfered_In_Amount__c,MUSW__Used_Amount__c,MUSW__Available_Amount__c,MUSW__Transfered_Out_Amount__c FROM MUSW__Deposit__c WHERE Id = :dep2.Id];

    // set page 
    pageReference depositAmountPage = Page.CartDeposits;
    depositAmountPage.getParameters().put('depositId', deposit.Id);
    Test.setCurrentPage(depositAmountPage);
    CartDepositsController dtc = new CartDepositsController();

    dtc.depositAmount = 0;
    dtc.processDepositAmount();

    ApexPages.Message[] pageMessages = ApexPages.getMessages();
    System.assertNotEquals(0, pageMessages.size());
    System.assert(pageMessages[0].getDetail().contains('Please enter an amount.'));
    dtc.goBack();
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