@isTest
public with sharing class validate_guest {
    private static testMethod void validate_getLanguage_locale_key(){
        system.assertEquals([select languageLocaleKey from user where id = :Userinfo.getUserId()].languageLocaleKey, guest.getLanguage_locale_key());
    }
    
    /*
    private static testMethod void validate_getGuest(){
        session__c session = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        guest__c guest = new guest__c(last_name__c = 'Nakajima for validate', session__c = session.id);
        insert guest;
        ApexPages.StandardController sc = new ApexPages.StandardController(guest);
        guest sfg = new guest(sc);
        
        guest__c g = sfg.getGuest();
        system.assertEquals(session.id, g.session__c);
    }
    */
    
    private static testmethod void validate_getCustom_Survey_Questions(){
        session__c session = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        guest__c guest = new guest__c(last_name__c = 'Nakajima for validate', session__c = session.id);
        insert guest;
        ApexPages.StandardController sc = new ApexPages.StandardController(guest);
        guest sfg = new guest(sc);
        
        list<custom_survey_question__c> csqs = sfg.getCustom_Survey_Questions();
        system.assertEquals(1, csqs.size());
    }
}