import { wire, LightningElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { publish, subscribe, MessageContext } from "lightning/messageService";
import messageChannel from "@salesforce/messageChannel/clariti__PaymentMessageChannel__c";
import initiatePurchase from "@salesforce/apex/CybersourcePaymentGateway.initiatePurchase";
import getPayment from "@salesforce/apex/CybersourcePaymentGateway.getPayment";
import getCyberSourceTransaction from "@salesforce/apex/CybersourcePaymentGateway.getCyberSourceTransaction";
import getPostUrl from "@salesforce/apex/CybersourcePaymentGateway.getPostUrl";
import PAYMENT_STATUS_FIELD from "@salesforce/schema/clariti__Payment__c.clariti__Status__c";
const STATUS = PAYMENT_STATUS_FIELD.fieldApiName;


// check payment status from the Payment and CyberSource Transaction Object
const checkPurchaseStatus = async (merchRefNumber) => {
    const result = {
        refNumber: merchRefNumber,
        message: undefined,
        succeeded: true,
        completed: false
    };

    const payment = await getPayment({ merchRefNumber: merchRefNumber });

    if (payment[STATUS] !== "Initiated") {
        if (payment[STATUS] === "Failed") {
            result.succeeded = false;
            result.completed = true;
            result.message = "ERROR";
        }
        else {
            result.completed = true;
        }
    } else {
        const transactionResult = await getCyberSourceTransaction({ merchRefNumber: merchRefNumber });  
        console.log(transactionResult);      
    }

    return result;
};


export default class CybersourcePaymentGateway extends NavigationMixin(LightningElement) {
    @wire(MessageContext)
    messageContext;
    cardId;
    paymentMethods;
    recordId;
    amount;
    accountId;
    account = {};
    subscription = null;
    
    // the following is called when the current LWC is appended into the hosting page
    connectedCallback() {
        this.subscribeToThePaymentMessageChannel();
    }

    subscribeToThePaymentMessageChannel() {
        const self = this;
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext,
            messageChannel,
            (message) => { self.processPaymentChannelMessage(message); }
        );
    }

    processPaymentChannelMessage(message) {
        console.log('message received from the payment channel:' + JSON.stringify(message));      
        if (!message || message.status !== "processPayment") {
            return;
        }

        this.paymentMethods = message.paymentMethods;
        this.cardId = message.cardId;
        this.recordId = message.recordId;
        this.amount = message.amount;
        this.accountId = message.accountId;

        const parsedPaymentMethods = JSON.parse(this.paymentMethods);
        if (!parsedPaymentMethods.length || !parsedPaymentMethods[0].paymentGatewayEventName) {
            return;
        }

        const paymentMethod = parsedPaymentMethods[0].paymentGatewayEventName;
        // the CardCaybersource value shoul match the Custom Metadata Types > Payment Method >  Payment Gateway Event field
        if (paymentMethod === "CardCybersource") {
            this.processPurchase();
        }
    }

    publishFailedMessage(errorMessage) {
        this.publishMessage("failed", errorMessage);
    }

    publishSuccessMessage(paymentResult) {
        this.publishMessage("success", undefined, paymentResult);
    }

    publishDialogClosedMessage() {
        this.publishMessage("dialog_closed", undefined, undefined);
    }

    publishMessage(status, errorMessage, paymentResult) {
        publish(
            this.messageContext,
            messageChannel,
            {
                status: status,
                errorMessage: errorMessage,
                paymentResult: paymentResult
            }
        );
    }    

    async processPurchase() {
        const self = this;

        try {
            const initiateResponse = await initiatePurchase({
                cartId: this.cardId,
                paymentMethods: this.paymentMethods,
                amount: this.amount
            });
            
            //   baseUrl = 'http://ebparks--dev0630.sandbox.my.salesforce-sites.com/CyberSourcePayment';
            const baseUrl = await getPostUrl();
            const paymentUrl = `${baseUrl}` + '?amt=' + this.amount + '&ref=' + initiateResponse.merchantId;	            
            Object.assign(document.createElement('a'), { target: '_blank', href: paymentUrl }).click();
            
            this.waitUntilPurchaseIsCompleted(initiateResponse.merchantId)
                .then(function () {
                    self.publishSuccessMessage(initiateResponse.paymentResult);
                })
                .catch(function (err) {
                    console.log(err);
                    self.publishFailedMessage(JSON.stringify(err));
                });
        } catch (e) {
            console.error(e);
            self.publishFailedMessage(JSON.stringify(e));
        }
    }

    openPaypalForm(url) {
        Object.assign(document.createElement('a'), { target: '_blank', href: url }).click();
    }

    setTimeoutRef;
    
    // the payment cart will timeout in 20 minutes
    waitUntilPurchaseIsCompleted(merchantRefNumber) {
        const self = this;
        return new Promise((resolve, reject) => {
            self.verifyPurchaseIsCompleted(merchantRefNumber, resolve, reject);
            const timeoutInMinutes = 20;
            setTimeout(() => {
                // eslint-disable-next-line no-unused-expressions
                self.setTimeoutRef && clearTimeout(self.setTimeoutRef);
                reject('PurchaseTimeout');
            }, timeoutInMinutes * 60000);
        });
    }

    // check the payment status in every 2 seconds
    verifyPurchaseIsCompleted(merchantRefNumber, resolve, reject) {
        const self = this;
        this.setTimeoutRef = setTimeout(() => {
            checkPurchaseStatus(merchantRefNumber)
                .then((statusCheck) => {
                    if (!statusCheck.succeeded) {
                        reject(statusCheck.message);
                    } else if (statusCheck.completed) {
                        resolve(true);
                    } else {
                        self.verifyPurchaseIsCompleted(merchantRefNumber, resolve, reject);
                    }
                })
                .catch(reject);            
        }, 2000);
    }
}