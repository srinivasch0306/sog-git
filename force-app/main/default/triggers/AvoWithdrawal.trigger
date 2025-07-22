trigger AvoWithdrawal on AVO_Withdrawals__c (before insert, before update,after insert, after update) {
	new AvoWithdrawalTriggerHandler().run();
}