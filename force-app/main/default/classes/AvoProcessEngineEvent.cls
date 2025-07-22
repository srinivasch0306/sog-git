/**
 * Description of class
 * a sub clas from AvoProcessEngineBase for events
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoProcessEngineEvent extends AvoProcessEngineBase{
    public AvoProcessEngineEvent(Event event) {
        this.event  = event;
        triggerFrom = TriggerFromObjectEnum.EVENT;
    }
}