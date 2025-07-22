global with sharing class CyberSourcePaymentResponseController {
    public clariti__Payment__c payment { get; set; }

    public CyberSourcePaymentResponseController() {
             
         
    }
    public void UpdatePayment()
    {
        
        string merchantid = ApexPages.currentPage().getParameters().get('req_reference_number');
        string decision = ApexPages.currentPage().getParameters().get('decision');
        string result = 'Failure';
        string message = ApexPages.currentPage().getParameters().get('message');
        string processorTransactionId = ApexPages.currentPage().getParameters().get('transaction_id');

        if (decision == 'ACCEPT')
            result= 'Success';
        
        avo_Cybersource_Transaction__c cybersourceTransaction = new avo_Cybersource_Transaction__c();
        cybersourceTransaction.Merchant_ID__c = merchantid;
        cybersourceTransaction.Status__c = result;
        cybersourceTransaction.Message__c = message;
        cybersourceTransaction.Processor_Transaction_Id__c = processorTransactionId;

        insert cybersourceTransaction; 
        
    }
}