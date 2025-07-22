@isTest(SeeAllData = true)
public class InspectionUpdateParentTriggerTest{


    public static testMethod void testCreateReinspectionFromIV(){
    
        MUSW__Inspection__c preIns = new MUSW__Inspection__c();
                
        preIns.Name = 'asfsdafsda';
        preIns.MUSW__Type__c = 'Mechanical';
        preIns.MUSW__Priority__c= '2 Normal';
        preIns.MUSW__Status__c = 'failed';
        preIns.Close_Inspection__c = false;
        preIns.MUSW__On_Itinerary__c = false;
        preIns.Letter_Generated__c = false;
        preIns.MUSW__Scheduled_Start_Date__c = date.today();
        preIns.Requested_DateTime__c = date.today();
        preIns.Completed_DateTime__c = date.today();
        preIns.MUSW__Completed_Date__c = date.today();
        preIns.MUSW__Closed_DateTime__c = date.today();
        preIns.Inspection_Chain_Closed__c = false;
        preIns.MUSW__Previous_Inspection__c = null;
        insert preIns;   
        
             

        MUSW__Inspection__c ins = new MUSW__Inspection__c();
                
        ins.Name = 'hot123';
        ins.MUSW__Type__c = 'Mechanical';
        ins.MUSW__Priority__c= '2 Normal';
        ins.MUSW__Status__c = 'failed';
        ins.Close_Inspection__c = false;
        ins.MUSW__On_Itinerary__c = false;
        ins.Letter_Generated__c = false;
        ins.MUSW__Scheduled_Start_Date__c = null;
        ins.Requested_DateTime__c = date.today();
        ins.Completed_DateTime__c = date.today();
        ins.MUSW__Completed_Date__c = date.today();
        ins.MUSW__Closed_DateTime__c = date.today();
        ins.Inspection_Chain_Closed__c = false;
        ins.MUSW__Previous_Inspection__c = preIns.id;
        
        
        insert ins;


        MUSW__Inspection__c nextIns = new MUSW__Inspection__c();
                
        nextIns.Name = 'tgrahgdsadfsdg';
        nextIns.MUSW__Type__c = 'Mechanical';
        nextIns.MUSW__Priority__c= '2 Normal';
        nextIns.MUSW__Status__c = 'Pending';
        nextIns.Close_Inspection__c = false;
        nextIns.MUSW__On_Itinerary__c = false;
        nextIns.Letter_Generated__c = false;
        nextIns.MUSW__Scheduled_Start_Date__c = null;
        nextIns.Requested_DateTime__c = null;
        nextIns.Completed_DateTime__c = null;
        nextIns.MUSW__Completed_Date__c = null;
        nextIns.MUSW__Closed_DateTime__c = null;
        nextIns.Inspection_Chain_Closed__c = false;
        nextIns.MUSW__Previous_Inspection__c = ins.id;
        //ins.Pass_Fail__c == 'Passed';
        
        insert nextIns;
        nextIns.MUSW__Status__c = 'passed';
        nextIns.Inspection_Chain_Closed__c = true;
        update nextIns;
        
        ins.Inspection_Chain_Closed__c = true;
        
        update ins;
        
        preIns.Inspection_Chain_Closed__c = true;
        
        update preIns;
        
        
        /*
        

        MUSW__Inspection__c updateIns = [select id, Name, MUSW__Type__c, MUSW__Priority__c, MUSW__Status__c, Close_Inspection__c, 
                                            MUSW__On_Itinerary__c, Letter_Generated__c, MUSW__Scheduled_Start_Date__c, Requested_DateTime__c , 
                                            Completed_DateTime__c, MUSW__Closed_DateTime__c,  Inspection_Chain_Closed__c, MUSW__Previous_Inspection__c  from MUSW__Inspection__c  where Name ='hot123' limit 1 ];


        updateIns.Name = 'abc';
        nextIns.MUSW__Status__c = 'Passed';
        update updateIns ;
       
       MUSW__Inspection__c updatePreIns = [select id, Name, MUSW__Type__c, MUSW__Priority__c, MUSW__Status__c, Close_Inspection__c, 
                                            MUSW__On_Itinerary__c, Letter_Generated__c, MUSW__Scheduled_Start_Date__c, Requested_DateTime__c , 
                                            Completed_DateTime__c, MUSW__Closed_DateTime__c,  Inspection_Chain_Closed__c, MUSW__Previous_Inspection__c  from MUSW__Inspection__c  where Name ='asfsdafsda' limit 1 ];

        
        
        update updatePreIns ;
        
    */
    }  


}