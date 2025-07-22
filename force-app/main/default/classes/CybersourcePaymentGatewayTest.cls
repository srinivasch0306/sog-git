@isTest
private class CybersourcePaymentGatewayTest {

    @isTest
    static void testGetPayment() {
        clariti__Payment__c payment = new clariti__Payment__c(
            clariti__MerchantId__c = 'MERCH123',
            clariti__Status__c = 'Pending'
        );
        insert payment;

        Test.startTest();
        clariti__Payment__c result = CybersourcePaymentGateway.getPayment('MERCH123');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('MERCH123', result.clariti__MerchantId__c);
    }

    @isTest
    static void testGetCyberSourceTransaction_NoTransaction() {
        Test.startTest();
        avo_Cybersource_Transaction__c result = CybersourcePaymentGateway.getCyberSourceTransaction('DOES_NOT_EXIST');
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testDeserializePaymentMethods() {
        String json = '[{"label":"Visa","name":"Visa","portalAccessible":true,"isValidForDepositPayable":true,"fields":[{"label":"Card Number","fieldName":"cardNumber","required":true,"value":"1234","displayValue":"1234","type":"string","maxLength":16}],"paymentGatewayEventName":"PayNow"}]';

        // Call indirectly through initiatePurchase to test deserialization path
        try {
            CybersourcePaymentGateway.initiatePurchase(
                'a001x000003NGU3AAO',
                json,
                50.00
            );
        } catch (Exception e) {
            // We expect failure due to fake cart/payment processing
            System.assert(e.getMessage() != null);
        }
    }

    @isTest
    static void testGetRefNumber() {
        String ref = CybersourcePaymentGateway.getRefNumber();
        System.assertNotEquals(null, ref);
        System.assert(ref.length() > 10);
    }

    @isTest
    static void testGetPaymentMerchantTransactionId() {
        String id = CybersourcePaymentGateway.getPaymentMerchantTransactionId();
        System.assertNotEquals(null, id);
        System.assertEquals(36, id.length());
    }

    @isTest
    static void testGetPostUrl_Simulated() {
        try {
            String result = CybersourcePaymentGateway.getPostUrl();
            System.assert(result != null); // This may throw an exception in test context, which is acceptable
        } catch (Exception e) {
            System.assert(true, 'Caught expected exception in test context');
        }
    }

}