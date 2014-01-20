global with sharing class inputPicklist {
    global string p_object_name {get;set;}
    global string p_field_name {get;set;}
    
    global class pm {
        string label {get;set;}
        string value {get;set;}
        
        global string getValue(){
            return value;
        }
        global string getLabel(){
            return label;
        }
    }
    
    global list<pm> getPicklist_map(){
        list<pm> pms = new list<pm>();
        
        // retrive all objects in this org
        map<string, schema.sobjectType> gdm = Schema.getGlobalDescribe();
        
        // get target object
        schema.sobjectType sot = gdm.get(p_object_name);
        
        // get describe result of the object
        schema.describeSObjectResult dor = sot.getDescribe();
        
        // get fields map
        map<string, schema.sobjectField> ofm = dor.fields.getMap();
        
        // get target field
        schema.sobjectField f = ofm.get(p_field_name);
        
        // get describe result of the field
        schema.describeFieldResult dfr = f.getDescribe();
        
        // get picklist entry
        list<picklistEntry> ples = dfr.getPicklistValues();
        
        // set piclist to return value
        for (schema.picklistEntry ple : ples){
            pm pm = new pm();
            pm.label = ple.getLabel();
            pm.value = ple.getValue();
            pms.add(pm);
        }
        
        return pms;
    }
    
}