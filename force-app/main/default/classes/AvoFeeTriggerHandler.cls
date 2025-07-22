/**
 * Description of class
 * trigger proxy for fees
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoFeeTriggerHandler extends AvoTriggerHandler { 
    
    public override void afterUpdate() {
        system.debug('fee trigger after update');

        for(MUSW__Fee__c fee : (List<MUSW__Fee__c>) Trigger.new) { 
            MUSW__Fee__c oldfee = (MUSW__Fee__c)Trigger.oldMap.get(fee.Id);
            system.debug('old fee:' + oldfee.MUSW__Outstanding_Fee__c);
            system.debug('new fee:' + fee.MUSW__Outstanding_Fee__c);
            system.debug('old MUSW__Fee_Paid__c:' + oldfee.MUSW__Fee_Paid__c);
            system.debug('new MUSW__Fee_Paid__c:' + fee.MUSW__Fee_Paid__c);
            if (oldfee.MUSW__Outstanding_Fee__c != 0 && fee.MUSW__Outstanding_Fee__c == 0  && fee.MUSW__Fee_Paid__c ==true ){
                system.debug('fee:' + fee);
                system.debug('a fee with zero outstanding fee dectected');
            	AvoProcessEngineFee avoProcessEngineFee = new AvoProcessEngineFee(fee);
            	avoProcessEngineFee.run(); 
            }
        }
    }

    public override void afterInsert() {

        // System.debug('recalcuating fee trigger');
        // for(MUSW__Fee__c fee : (List<MUSW__Fee__c>) Trigger.new) { 
        //     AvoFeeManager.recalcuatedCombinedWorkItem(fee);
        // }
    }
}