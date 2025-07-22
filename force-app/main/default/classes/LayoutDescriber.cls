public class LayoutDescriber
{
    /**
    *@Description gets all the fields for the provided page layouts and emails the current user a csv document for each. It
                  also gets related field data and provides suggested mapping configuration for import. Ooptionally can get picklist values for objects.
    *@Param pageLayoutNames a list of page layout names. Format is [obectName]-[namespace]__[Page layout name]. 
            Omit namespace and underscores if layout is not part of a managed package.
            EX: Account-SkienceFinSln__Address 
            OR
            EX: Account-Account Layout
    @Param getPicklistValues flag that controls whether picklist values for described objects should be included.
    **/
    public static void sendLayoutInfo(list<string> pageLayoutNames, boolean getPicklistValues)
    { 
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, pageLayoutNames);
        for(string layOutName : pageLayoutNames)
        {
            boolean layoutFound = false;
            for(integer i = 0; i < layouts.size(); i++)
            {
                Metadata.Layout layoutMd = (Metadata.Layout) layouts.get(i);
                if(layoutMd.fullName == layOutName)
                {
                    layoutFound = true;
                }
            }
            if(layoutFound == false)
            {
                throw new applicationException('No layout with name' + layoutName + ' could be found. Please check and make sure namespace is included if needed');
            }
        }
        map<string,map<string,list<string>>> objectPicklistValuesMap = new map<string,map<string,list<string>>>();
        
        map<string,list<string>> objectFieldsMap = new map<string,list<string>>();
        map<string,list<string>> layoutFieldsMap = new map<string,list<string>>();
        map<string,map<string,list<string>>> layoutSectionFieldsMap = new map<string,map<string,list<string>>>();
        for(integer i = 0; i < layouts.size(); i++)
        {
            Metadata.Layout layoutMd = (Metadata.Layout) layouts.get(i);
        
            list<string> objectFields = new list<string>();
            map<string,list<string>> objectSectionFields = new map<string,list<string>>();
            for (Metadata.LayoutSection section : layoutMd.layoutSections) 
            {        
                //System.debug('JUSTIN SECTION: ' + section.label);
                list<string> innerObjectFields = new list<string>();
                for (Metadata.LayoutColumn column : section.layoutColumns) 
                {
                    if (column.layoutItems != null) 
                    {
                        for (Metadata.LayoutItem item : column.layoutItems) 
                        {
                            System.debug(item.field);
                            if(item.field == null) continue;
                            objectFields.add(item.field);
                            innerObjectFields.add(item.field);
                        }
                    }
                }
                objectSectionFields.put(section.label, innerObjectFields);
            }
            objectFields.sort();
            objectFieldsMap.put(pageLayoutNames[i].split('-')[0],objectFields);
            layoutFieldsMap.put(pageLayoutNames[i],objectFields);
            layoutSectionFieldsMap.put(pageLayoutNames[i],objectSectionFields);
        }
        
        //system.debug(objectFieldsMap);
        //system.debug(layoutFieldsMap);
        system.debug(layoutSectionFieldsMap);
        
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        system.debug(globalDescribe);
        
        Map<String, Map<String, Schema.SObjectField>> objectDescribeCache = new Map<String, Map<String, Schema.SObjectField>>();
        
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
        
        integer counter = 0;    
        for(string thisLayoutPage : layoutFieldsMap.keySet())
        {
            String thisObjectType = thisLayoutPage.split('-')[0];
            list<string> fields = layoutFieldsMap.get(thisLayoutPage);
            
            Map<String, Schema.SObjectField> objectDescribeData;
            if(objectDescribeCache.containsKey(thisObjectType))
            {
                objectDescribeData = objectDescribeCache.get(thisObjectType);
            }
            else
            {
                objectDescribeData = globalDescribe.get(thisObjectType).getDescribe().fields.getMap();
                System.debug(objectDescribeData);
                objectDescribeCache.put(thisObjectType,objectDescribeData);
            }
        	
            string valueString = 'Source Field Name, Source Field Label, Source Field Type, Source Required, Source Size, Is Custom, Controlling Field, Target Field Name, Target Field Type, Target Required, Transformation \r\n';
            
            map<string,list<string>> sectionFields = layoutSectionFieldsMap.get(thisLayoutPage);
            
            for (string thisSection : sectionFields.keySet()) {
                list<string> fieldsInSection = sectionFields.get(thisSection);
                valueString+= 'SECTION: ' + thisSection + '\r\n';
                for (string thisField : fieldsInSection) {
                    if(thisField == null || !objectDescribeData.containsKey(thisField))
                    {
                        system.debug('\n\n\n--- Missing field! ' + thisField);
                        if(thisField != null) valueString+= thisField + ', Field Data Not Found \r\n';
                        continue;
                    }
                    
                    Schema.DescribeFieldResult dfr = objectDescribeData.get(thisField).getDescribe();
                    
                    if( (dfr.getType() == Schema.DisplayType.picklist || dfr.getType() == Schema.DisplayType.MultiPicklist) && getPicklistValues)
                    {
                        List<String> pickListValuesList= new List<String>();
                        List<Schema.PicklistEntry> ple = dfr.getPicklistValues();
                        for( Schema.PicklistEntry pickListVal : ple)
                        {
                            pickListValuesList.add(pickListVal.getLabel());
                        }     
            
                        map<string,list<string>> objectFields = objectPicklistValuesMap.containsKey(thisObjectType) ? objectPicklistValuesMap.get(thisObjectType) : new map<string,list<string>>();
                        objectFields.put(thisField,pickListValuesList);
                        objectPicklistValuesMap.put(thisObjectType,objectFields);
                    }
                    boolean isRequired = !dfr.isNillable() && string.valueOf(dfr.getType()) != 'boolean' ? true : false;
                    string targetFieldName = dfr.isCustom() ? '' : thisField;
                    string targetFieldType = dfr.isCustom() ? '' : dfr.getType().Name();
                    string defaultTransform = '';
                    
                    if(dfr.getType() == Schema.DisplayType.Reference)
                    {
                        defaultTransform = 'Update with Id of related: ';
                        for(Schema.sObjectType thisType : dfr.getReferenceTo())
                        {
                            defaultTransform+= string.valueOf(thisType) + '/';
                        }
                        defaultTransform.removeEnd('/');
                    }    
                    if(thisField == 'LastModifiedById') defaultTransform = 'Do not import';
                    valueString+= thisField +',' + dfr.getLabel() + ',' +  dfr.getType() + ',' + isRequired + ',' +dfr.getLength()+ ',' +dfr.isCustom()+ ',' +dfr.getController() + ','+ 
                                  targetFieldName + ',' + targetFieldType +',' + isRequired + ',' + defaultTransform +'\r\n';
                }
            }
        
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(pageLayoutNames[counter]+'.csv');
            efa.setBody(Blob.valueOf(valueString));
            attachments.add(efa);
            
            counter++;
        }
        //if we are getting picklist values we will now build a document for each object. One column per picklist, with it's rows being the values of the picklist
        if(getPicklistValues)
        {
            //loop over the object types
            for(string objectType : objectPicklistValuesMap.keySet())
            {
                //get all picklist fields for this object
                map<string,list<string>> objectFields = objectPicklistValuesMap.get(objectType);
                
                //each row of data will be stored as a string element in this list
                list<string> dataLines = new list<string>();
                integer rowIndex = 0;
                
                //string to contains the header row (field names)
                string headerString = '';
                
                //due to how the data is structured (column by column) but needs to be built (row by row) we need to find the column with the maximum amount of values
                //so our other columns can insert a correct number of empty space placeholders if they don't have values for that row.
                integer numRows = 0;
                for(string fieldName : objectFields.keySet())
                {
                    if(objectFields.get(fieldName).size() > numRows) numRows = objectFields.get(fieldName).size();
                }
                
                //loop over every field now. This is going to get tricky because the data is structured as a field with all its values contained but we need to build
                //our spreadsheet row by row. So we will loop over the values and create one entry in the dataLines list for each value. Each additional field will then add to the string
                //as required. Once we have constructed all the rows of data we can append them together into one big text blob and that will be our CSV file.
                for(string fieldName : objectFields.keySet())
                {
                    headerString += fieldName +',';
                    rowIndex = 0;
                    list<string> picklistVals = objectFields.get(fieldName);
                    for(integer i = 0; i<numRows; i++ )
                    {
                        string thisVal = i >= picklistVals.size() ? ' ' : picklistVals[i]; 
                        if(dataLines.size() <= rowIndex) dataLines.add('');
                        dataLines[rowIndex] += thisVal + ', ';
                        rowIndex++;        
                    }
                }
                headerString += '\r\n';
                
                //now that our rows are constructed, add newline chars to the end of each
                string valueString = headerString;
                for(string thisRow : dataLines)
                {            
                    thisRow += '\r\n';
                    valueString += thisRow;
                }
                
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName('Picklist values for ' + objectType +'.csv');
                efa.setBody(Blob.valueOf(valueString));
                attachments.add(efa);        
            }
        }
        
        
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
    public class applicationException extends Exception {}
    
    public static void sendLayoutInfo()
    {
        list<string> pageLayoutNames = new List<String>();
        pageLayoutNames.add('AVO_Compliance__c-Compliance Case');
        sendLayoutInfo(pageLayoutNames, true);
    }
}