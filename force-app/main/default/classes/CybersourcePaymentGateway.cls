public with sharing class CybersourcePaymentGateway {
    public static final String CYBER_SOURCE_PAYMENT_PROXY_NAME = 'CyberSourcePayment';

    @AuraEnabled
    public static clariti__Payment__c getPayment(String merchRefNumber) {
        clariti__Payment__c payment = [
            SELECT Name, clariti__MerchantId__c, clariti__Status__c, clariti__Cart__r.clariti__FailureReason__c
            FROM clariti__Payment__c
            WHERE clariti__MerchantId__c = :merchRefNumber
            LIMIT 1
        ];

        return payment;
    }

    @AuraEnabled
    public static avo_Cybersource_Transaction__c getCyberSourceTransaction(String merchRefNumber) {
        
        // check the cybersource transaction table to see if there is a completed transaction for the current payment
        List<avo_Cybersource_Transaction__c> transactions = [
            SELECT iD, Merchant_ID__c,Status__c, Message__c,Processor_Transaction_Id__c	
            FROM avo_Cybersource_Transaction__c
            WHERE Merchant_ID__c = :merchRefNumber
        ];
        if (transactions.size() >0)
        {
            List<clariti__Payment__c> payments= [
                SELECT  Name, clariti__MerchantId__c, clariti__Status__c, clariti__Cart__r.clariti__FailureReason__c,
                        Processor_Transaction_Id__c,clariti__PaymentMethod__c
                FROM clariti__Payment__c
                WHERE clariti__MerchantId__c = :merchRefNumber];
            
            if (payments.size() >0)
            {

                 // this is how clariti handles payment, block start here.
                clariti__Payment__c payment;
                payment = payments[0];
                                        
                if (transactions[0].Status__c!='Success') {
                    clariti__Cart__c cart = new clariti.CartSelector().getCartAndItemsById(payment.clariti__Cart__c, new Set<String>());
                    cart.clariti__Status__c = 'Failed';
                    cart.clariti__FailureReason__c = transactions[0].Message__c;        
                    payment.clariti__Status__c = 'Failed';
                    payment.Processor_Transaction_Id__c = transactions[0].Processor_Transaction_Id__c;
                    update new List<SObject> { payment, cart };
                }
                
                //TODO Processor_Transaction_Id__c should store a value returned by Cyber Source
                payment.Processor_Transaction_Id__c = transactions[0].Processor_Transaction_Id__c;  
                update new List<SObject> { payment };
                clariti__PaymentMethod__mdt paymentMethodSetting = new clariti.PaymentMethodSelector().getSettingByNameOrLabel(
                    payment.clariti__PaymentMethod__c
                );
       
                List<clariti.PaymentService.PaymentMethod> paymentMethods = clariti.PaymentService.buildPaymentMethods(
                    new List<clariti__PaymentMethod__mdt>{ paymentMethodSetting },
                    payment
                );
        		
                if (transactions[0].Status__c =='Success') {
                	clariti.PaymentProcessorService.handlePaymentProcess(payment.clariti__Cart__c, paymentMethods, payment);
                }
                // block end here.
            }
            return transactions[0];
        }
        return null;
    }

    @AuraEnabled
    public static InitiatePurchaseResult initiatePurchase(String cartId, String paymentMethods, Decimal amount) {
        String merchRefNumber = getRefNumber(); //getPaymentMerchantTransactionId();

        List<clariti.PaymentService.PaymentMethod> deserializedPaymentMethods = deserializePaymentMethods(paymentMethods);

        clariti.PaymentService.PaymentResult paymentResult = clariti.PaymentProcessorService.processInitiatedPayment(
            cartId,
            deserializedPaymentMethods,
            merchRefNumber
        );

        if (!paymentResult.success) {
            throw new AuraHandledException(paymentResult.failureReason);
        }

        return new InitiatePurchaseResult(paymentResult, merchRefNumber);
    }

    public static String getRefNumber(){
        DateTime oUTSDateTime = System.now();
        String oUTSRefNum = oUTSDateTime.format('yyyyMMddHHmmssSSS') + String.valueOf(Integer.valueof((Math.random() * 10000000)));      
        return oUTSRefNum;
    }

    public static String getPaymentMerchantTransactionId() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        String guid = h.substring(0,8) + '-' + h.substring(8,12) + '-' + h.substring(12,16) + '-' + h.substring(16,20) + '-' + h.substring(20);       
        return guid;
    }
    
    @AuraEnabled
    public static String getPostUrl() {
        Site serviceSite = [SELECT Id FROM Site WHERE Name = :CYBER_SOURCE_PAYMENT_PROXY_NAME];
        SiteDetail serviceSiteDetail = [SELECT SecureUrl FROM SiteDetail WHERE DurableId = :serviceSite.Id];

        return serviceSiteDetail.SecureUrl;
    }

    private static List<clariti.PaymentService.PaymentMethod> deserializePaymentMethods(String data) {
        List<CustomPaymentMethod> deserializedPaymentMethods = (List<CustomPaymentMethod>) JSON.deserialize(
            data,
            List<CustomPaymentMethod>.class
        );

        List<clariti.PaymentService.PaymentMethod> result = new List<clariti.PaymentService.PaymentMethod>();

        for (CustomPaymentMethod m : deserializedPaymentMethods) {
            clariti.PaymentService.PaymentMethod pm = new clariti.PaymentService.PaymentMethod();

            pm.label = m.label;
            pm.name = m.name;
            pm.portalAccessible = m.portalAccessible;
            pm.isValidForDepositPayable = m.isValidForDepositPayable;
            pm.paymentGatewayEventName = m.paymentGatewayEventName;
            pm.fields = new List<clariti.PaymentService.PaymentField>();

            if (m.fields != null) {
                for (CustomPaymentField f : m.fields) {
                    clariti.PaymentService.PaymentField pf = new clariti.PaymentService.PaymentField();

                    pf.label = f.label;
                    pf.fieldName = f.fieldName;
                    pf.required = f.required;
                    pf.value = f.value;
                    pf.displayValue = f.displayValue;
                    pf.type = f.type;
                    pf.maxLength = f.maxLength;

                    pm.fields.add(pf);
                }
            }

            result.add(pm);
        }

        return result;
    }

    public class InitiatePurchaseResult {
        @AuraEnabled
        public String paymentResult;
        @AuraEnabled
        public String merchantId;

        public InitiatePurchaseResult(clariti.PaymentService.PaymentResult paymentResult, String merchantId) {
            this.paymentResult = JSON.serialize(new CustomPaymentResult(paymentResult));
            this.merchantId = merchantId;
        }
    }

    public class CustomPaymentMethod {
        public String label { get; set; }
        public String name { get; set; }
        public Boolean portalAccessible { get; set; }
        public Boolean isValidForDepositPayable { get; set; }
        public List<CustomPaymentField> fields { get; set; }
        public String paymentGatewayEventName { get; set; }

        public CustomPaymentMethod() {
            this.portalAccessible = false;
            this.fields = new List<CustomPaymentField>();
        }
    }

    public class CustomPaymentField {
        public String label { get; set; }
        public String fieldName { get; set; }
        public Boolean required { get; set; }
        public String value { get; set; }
        public String displayValue { get; set; }
        public String type { get; set; }
        public Integer maxLength { get; set; }
    }

    public class CustomPaymentResult {
        public Boolean success;
        public Id paymentId;
        public String paymentName;
        public String paymentMethod;
        public Decimal paymentAmount;
        public String failureReason;

        public CustomPaymentResult(clariti.PaymentService.PaymentResult pr) {
            this.success = pr.success;
            this.paymentId = pr.paymentId;
            this.paymentName = pr.paymentName;
            this.paymentMethod = pr.paymentMethod;
            this.paymentAmount = pr.paymentAmount;
            this.failureReason = pr.failureReason;
        }
    }
}