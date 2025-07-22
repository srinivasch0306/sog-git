public class AvoMeterWithdrawalSequenceNumberHandler extends AvoTriggerHandler {
    public override void beforeInsert() {
        MUSW.SequenceNumber.updateNumbers(Trigger.new, Trigger.old);
    }

    public override void beforeUpdate() {
        MUSW.SequenceNumber.updateNumbers(Trigger.new, Trigger.old);
    }
}