public class AvoFieldsExport {
	public static void exportFields()
    {    
        String userName = UserInfo.getUserName();
        User activeUser = [Select Email From User where Username = : userName limit 1];
        String userEmail = activeUser.Email;
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        //message.toAddresses = new String[] { userEmail };
        message.toAddresses = new String[] {'justin.liman@avocette.com'};
        message.subject = 'Describe of fields on page layouts';
        message.plainTextBody = 'Save the attachments and open in excel. Fieldnames and types should be properly formated.';
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        list<Messaging.EmailFileAttachment> attachments = new list<Messaging.EmailFileAttachment>();
        
        string valueString = 'Label, API Name, Type \r\n';

        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get('AVO_Compliance__c');
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        System.debug(MapofField);
        
        for(String fieldName : MapofField.keySet()) {
            Schema.SObjectField field = MapofField.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            valueString+= F.getLabel() +',' + F.getName() + ',' +  F.getType() +'\r\n';
        }
        
        
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName('permit-fields.csv');
        efa.setBody(Blob.valueOf(valueString));
        attachments.add(efa);
                    
        
        message.setFileAttachments( attachments );
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
         
        if (results[0].success) 
        {
            System.debug('The email was sent successfully.');
        } 
        else 
        {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }

    }
}