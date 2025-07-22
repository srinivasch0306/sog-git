global with sharing class CybersourcePaymentGatewayProcessor extends clariti.PaymentProcessor {

    public static final String CART_IN_PROGRESS = 'In Progress';
    public static final String PAYMENT_INITIATED = 'Initiated';

    global override clariti.PaymentService.PaymentResult processInitiatedPayment(
        String cartId,
        List<clariti.PaymentService.PaymentMethod> paymentMethods,
        String paymentDetails
    ) {
        clariti.PaymentService.PaymentResult paymentResult = new clariti.PaymentService.PaymentResult();
        paymentResult.success = true;

        try {
            clariti__Cart__c cart = new clariti.CartSelector().getCartAndItemsById(cartId, new Set<String>());
            cart.clariti__Status__c = CART_IN_PROGRESS;

            clariti__Payment__c payment = new clariti__Payment__c(
                clariti__Cart__c = cart.Id,
                clariti__Account__c = cart.clariti__Account__c,
                clariti__Status__c = PAYMENT_INITIATED,
                clariti__PaymentMethod__c = paymentMethods[0].name,
                clariti__MerchantId__c = paymentDetails
            );
            insert payment;

            paymentResult.paymentName = payment.Name;
            paymentResult.paymentId = payment.Id;
            paymentResult.paymentMethod = paymentMethods[0].name;

        } catch (DmlException e) {
            System.debug(e.getStackTraceString());
            paymentResult.failureReason = e.getMessage();
            paymentResult.success = false;
        }

        return paymentResult;
    }    
}