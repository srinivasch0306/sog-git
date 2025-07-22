/**
 * Description of class
 * a sub clas from AvoProcessEngineBase for tasks
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoProcessEngineTask extends AvoProcessEngineBase{
    public AvoProcessEngineTask(Task task) {
        this.task = task;
        triggerFrom = TriggerFromObjectEnum.TASK;
    }
}