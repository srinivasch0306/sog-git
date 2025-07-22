public class AvoComplianceSequenceNumberHandler extends AvoTriggerHandler {
    public override void beforeInsert() {
        MUSW.SequenceNumber.updateNumbers(Trigger.new, Trigger.old);
    }
}