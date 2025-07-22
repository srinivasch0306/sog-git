public with sharing class BB_ApplicationTriggerHandler {
    /**
     * Handles the Application triggers
     *
     */
    public class ApplicationCreateBluebeamProject implements BGCM.ITriggerHandler {
        public void onBeforeUpdate() {} public void onBeforeDelete() {} public void onBeforeInsert() {} public void onBeforeUndelete() {} public void onAfterUpdate() {} public void onAfterDelete() {} public void onAfterUndelete() {}    
        
        /*
         * When we create a new Applicatiom record trigger creation of a new
         * Blue Beam Project
         */
        public void onAfterInsert() {
            if(Trigger.isInsert && Trigger.isAfter) {
                if(!Test.isRunningTest()) MUSW.BluebeamProjectService.createProjects(Trigger.new);
            }
        }
    }
}