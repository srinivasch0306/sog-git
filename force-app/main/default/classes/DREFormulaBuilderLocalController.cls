public class DREFormulaBuilderLocalController {
    public String selectedObject { get; set; }   
     
    public SelectOption[] getObjects() {
        List<SelectOption> objects = new List<SelectOption>();
        for (SObjectType sObjectType : Schema.getGlobalDescribe().values())
            objects.add(new SelectOption(
                String.valueOf(sObjectType.getDescribe().getName()),
                sObjectType.getDescribe().getName()
            ));
        objects.sort();
        return objects;
    }
}