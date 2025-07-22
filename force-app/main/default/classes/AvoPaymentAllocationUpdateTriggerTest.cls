@isTest
public class AvoPaymentAllocationUpdateTriggerTest {

    @isTest
    static void testPaymentAllocationTrigger() {
         AVO_Compliance__c compliance = new AVO_Compliance__c(Name = 'Compliance Doc');
    insert compliance;
        // Step 1: Create a test MUSW__Fee__c record
        MUSW__Fee__c testFee = new MUSW__Fee__c(
            MUSW__Amount__c = 10 ,
            AVO_Compliance__c = compliance.id
        );
        insert testFee;
        
        clariti__Payment__c  payment = new clariti__Payment__c(
            clariti__PaymentAmount__c = 10
        );
        insert payment;

        // Step 2: Create a test clariti__PaymentAllocation__c record linked to the fee
        clariti__PaymentAllocation__c testPA = new clariti__PaymentAllocation__c(
         //   Name = 'Test PA',
            clariti__Fee__c = testFee.Id,
            AVO_Compliance__c = compliance.id,
            clariti__Payment__c = payment.id
        );

        Test.startTest();
        insert testPA;
        Test.stopTest();

        // Step 3: Query and assert that AVO_Compliance__c was updated correctly
        clariti__PaymentAllocation__c insertedPA = [
            SELECT Id, AVO_Compliance__c, clariti__Fee__c 
            FROM clariti__PaymentAllocation__c 
            WHERE Id = :testPA.Id
        ];
        
    }
}