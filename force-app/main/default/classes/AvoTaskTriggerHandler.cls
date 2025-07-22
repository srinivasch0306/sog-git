/**
 * Description of class
 * trigger proxy for tasks
 * @author Jason Li
 * last modified by Jason Li
 * @date 06/28/2021
 *  
 */
public class AvoTaskTriggerHandler extends AvoTriggerHandler { 
    public override void afterUpdate() {
        for(Task task : (List<Task>) Trigger.new) { 
            Task oldTask = (Task)Trigger.oldMap.get(task.Id);
            string oldPermitStatus =  oldTask.Status;
            string newTaskStatus =  task.Status;
           if (oldPermitStatus <> newTaskStatus){
                // task status has changed
                AvoProcessEngineTask avoProcessEngineTask = new AvoProcessEngineTask(task);
                avoProcessEngineTask.run();
            }            
        }
    }
}