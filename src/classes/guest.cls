public with sharing class guest {
    public guest__c guest {get;set;}

    public guest(ApexPages.StandardController controller) {
        guest__c guest_tmp = (guest__c)controller.getRecord();
        if (guest_tmp.id != null){
            this.guest = (guest__c)scrud.sread('sugoisurvey4__Guest__c', guest_tmp.id);
        }
    }

    public static string getLanguage_locale_key(){
        return [select languageLocaleKey from user where id = :Userinfo.getUserId()].languageLocaleKey;
    }

    public list<custom_survey_question__c> getCustom_Survey_Questions(){
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey4__Custom_Survey_Question__c');
        id session_id = this.guest.session__c;
        string soql = 'select ' + soql_flds + ' from custom_survey_question__c where session__c = :session_id order by name';

        list<custom_survey_question__c> csqs = Database.query(soql);
        return csqs;
    }

}