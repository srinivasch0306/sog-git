public with sharing class CartDepositsController {

    public Decimal depositAmount { get; set; }
    public MUSW__Deposit__c currentDeposit { get; set; }

    public CartDepositsController() {
        Id depositId = System.currentPageReference().getParameters().get('depositId');
        currentDeposit = [SELECT Id, MUSW__Amount__c,MUSW__Unpaid_Amount__c,MUSW__Transfered_In_Amount__c,MUSW__Used_Amount__c,MUSW__Available_Amount__c,MUSW__Transfered_Out_Amount__c FROM MUSW__Deposit__c WHERE Id = :depositId];
        depositAmount = currentDeposit.MUSW__Amount__c;
    }

    public PageReference processDepositAmount(){

        if(depositAmount == 0) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter an amount.'));
          return null;
        }

        if(currentDeposit.MUSW__Transfered_In_Amount__c != null && currentDeposit.MUSW__Transfered_In_Amount__c > 0) {
            Decimal transfout = currentDeposit.MUSW__Transfered_Out_Amount__c==null?0:currentDeposit.MUSW__Transfered_Out_Amount__c;
            Decimal usedAmount = currentDeposit.MUSW__Used_Amount__c==null?0:currentDeposit.MUSW__Used_Amount__c;
            if(depositAmount > (currentDeposit.MUSW__Amount__c - (currentDeposit.MUSW__Available_Amount__c + transfout + usedAmount))) {
                currentDeposit.MUSW__Amount__c = depositAmount + currentDeposit.MUSW__Available_Amount__c + transfout + usedAmount;
                update currentDeposit;
            }
        } else {
            if(depositAmount > currentDeposit.MUSW__Unpaid_Amount__c) {
                currentDeposit.MUSW__Amount__c = currentDeposit.MUSW__Amount__c + (depositAmount - currentDeposit.MUSW__Unpaid_Amount__c);
                update currentDeposit;
            }
        }

        PageReference ret = Page.Cart;
        ret.setRedirect(true);
        ret.getParameters().put('depositId', currentDeposit.Id);
        ret.getParameters().put('retURL', System.currentPageReference().getParameters().get('retURL'));
        ret.getParameters().put('depositAccountId', System.currentPageReference().getParameters().get('depositAccountId'));
        ret.getParameters().put('id', System.currentPageReference().getParameters().get('id'));

        return ret;
    }
    
      /*
      * Go back to the deposit page
      */
      public PageReference goBack() {
        pageReference  pr = new pageReference('/'+currentDeposit.Id);
        pr.setredirect(true);
        return pr;  
      }
}