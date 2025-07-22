public class AvoMeterController {
	
    @InvocableMethod(label='Set Meter MOSID' description='Set the MOSID of the Meter from the input.')
    public static List<Integer> setMOSID(List<AVO_Meter__c> meters){
        List<AVO_Meter__c> meterWithLargestMOSID = [SELECT Id, AVO_Meter_On_Site_ID__c FROM AVO_Meter__c WHERE AVO_Meter_On_Site_ID__c != null ORDER BY AVO_Meter_On_Site_ID__c DESC NULLS LAST LIMIT 1];
        List<Integer> mosidList = new List<Integer>();
        integer largestMosid;
        if (meterWithLargestMOSID.isEmpty()) {
            largestMosid = 0;
        } else {
            largestMosid = (Integer) meterWithLargestMOSID[0].AVO_Meter_On_Site_ID__c;
        }
        for(AVO_Meter__c meter : meters) {
            largestMosid++;
            meter.AVO_Meter_On_Site_ID__c = largestMosid;   
            mosidList.add(largestMosid);
        }
        update meters;
        return mosidList;
    }
}