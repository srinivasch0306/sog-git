/**
* Description of class
* a class extended from AvoCustomException
* @author Jason Li
* last modified by Jason Li
* @date 03/23/2021
*
*/
public class AvoLogException extends Exception {
    public String ModuleName {get; set;}
    public String StackTrace {get; set;}
    public String ClassName {get; set;}
    public String MethodName {get; set;}
    public String ExceptionCause {get; set;}
        
    public void log(Exception ex)
    {
    	try
        {
        	extractExceptionData(ex); 
            writeToObject(ex); 
        }
        catch(Exception e)
        {
         	new AvoLogException().Module('LogException').log(e);            
        }        	        
    }
    
    public AvoLogException Module(String Name)
    {
    	ModuleName = name;
        return this;
    }
    
    public AvoLogException ExceptionCause(String cause)
    {
    	ExceptionCause = cause;
        return this;
    }
    
    public void extractExceptionData(Exception ex)
    {
        try
        {
            stackTrace = ex.getStackTraceString().substringBefore('\n');
            className = stackTrace.substringAfter('.').substringBefore('.');	
            methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');    
        }
        catch(Exception e)
        {
        	new AvoLogException().Module('LogException').log(e); 
        }      	                        
    }
    
    public void writeToObject(Exception ex)
    {
    	try
        {
            AVO_Exception_Logger__c logger = new AVO_Exception_Logger__c();
            logger.Module_Name__c = ModuleName;
            logger.Stack_Trace__c = ex.getStackTraceString();
            logger.Class_Name__c = className;
            logger.Method_Name__c = methodName;
            logger.Line_Number__c = ex.getLineNumber();
            logger.Exception_Type__c = ex.getTypeName();
            logger.Exception_Cause_Override__c = ExceptionCause; 
            logger.Exception_Cause__c = String.valueOf(ex.getCause());
            
            logger.Exception_Message__c = ex.getMessage();
            
            insert logger;    
        }
        
        catch(Exception e)
        {
        	new AvoLogException().Module('LogException').log(e);     
        }   
    }    
}