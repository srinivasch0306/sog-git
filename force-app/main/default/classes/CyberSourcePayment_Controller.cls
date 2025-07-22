public with sharing class CyberSourcePayment_Controller {
	public String amount {get;set;}
    //public String Secret_Key {get;set;} 
    public Map<string,string> oPassedParams = new Map<String,String>();
    public String csSettingName ='Cybersource'; 

    //public static String tid()  {
    //    return Apexpages.currentPage().getParameters().get('tid');
    //}
    
    public static String signParams(Map<string, string> paramsArray, string csSettingName)  {
        String Secret_Key = CyberSourceSettings__c.getValues(csSettingName).Secret_Key_1__c + CyberSourceSettings__c.getValues(csSettingName).Secret_Key_2__c;
        String result = sign(buildDataToSign(paramsArray), Secret_Key);
        return result;
    }
    
    public String getPaymentURL(){
        return CyberSourceSettings__c.getValues(csSettingName).BusinessCenter__c;
    } 

    public String getUUID(){
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        String guid = h.substring(0,8) + '-' + h.substring(8,12) + '-' + h.substring(12,16) + '-' + h.substring(16,20) + '-' + h.substring(20);       
        return guid;        
     }

    public String getRefNumber(){
        return ApexPages.currentPage().getParameters().get('ref');
    }
    
    public String getUTCDateTime(){
        DateTime oUTSDateTime = System.now().addHours(0);
        String strUTCDateTime = oUTSDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return strUTCDateTime;
    }

     
    public String getAmount(){
        return ApexPages.currentPage().getParameters().get('amt');
    }

    //TODO
    public String getParametersValues(){
       String result = '';
       String access_key = CyberSourceSettings__c.getValues(csSettingName).Access_key__c;
       String profile_id = CyberSourceSettings__c.getValues(csSettingName).Profile_ID__c; 

       oPassedParams.put('access_key',access_key);
       oPassedParams.put('profile_id',profile_id);
       oPassedParams.put('transaction_uuid',getUUID());
       oPassedParams.put('signed_field_names','access_key,profile_id,transaction_uuid,signed_field_names,unsigned_field_names,signed_date_time,locale,transaction_type,reference_number,amount,currency');        
       oPassedParams.put('unsigned_field_names','');
       oPassedParams.put('signed_date_time',getUTCDateTime());
       oPassedParams.put('locale','en');
       oPassedParams.put('transaction_type','sale');
       oPassedParams.put('reference_number',getRefNumber());
       oPassedParams.put('amount',getAmount());
       oPassedParams.put('currency', 'USD');
        
       for (String oKey : oPassedParams.KeySet()){ 
            result += '<div>';
            result += '<input type="hidden" id="' + oKey + '" name="' + oKey + '" value="' + oPassedParams.get(oKey) + '"/>';
            result += '</div>';
        }
        system.debug('--ParametersValues' +result);
        return result;
    }
    
    public String getSignedData(){
        String result = '';
        result += '<input type="hidden" id="signature" name="signature" value="' + CyberSourcePayment_Controller.signParams(oPassedParams, csSettingName) + '"/>';
        system.debug('-- getSignedData' + result);
        return result;
    }         

    private static String commaSeparate(List<string> dataToSign) {
        String result = '';
        for(String Str : dataToSign) {
            result += (result==''?'':',')+Str;
        }
        return result;                         
    }

    private static String buildDataToSign(Map<string,string> paramsArray) {
        String[] signedFieldNames = paramsArray.get('signed_field_names').Split(',');
        List<string> dataToSign = new List<string>();

        for (String oSignedFieldName : signedFieldNames){
             dataToSign.Add(oSignedFieldName + '=' + paramsArray.get(oSignedFieldName));
        }
        return commaSeparate(dataToSign);
    }
    
     private static String sign(String data, String secretKey) {
         system.debug('--Sign data: ' +data);
        String result = EncodingUtil.base64Encode(Crypto.generateMac('hmacSHA256', Blob.valueOf(data), Blob.valueOf(secretKey)));
        return result;
    }
}