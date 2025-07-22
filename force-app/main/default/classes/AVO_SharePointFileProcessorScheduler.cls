global class AVO_SharePointFileProcessorScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.debug('Scheduler triggered — enqueuing SharePoint processor from folder index 0, file index 0');
        System.enqueueJob(new AVO_SharePointFileProcessorQueue(0, 0));
    }
}