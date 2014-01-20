public with sharing class session_report {
    public id c_session_id {get;set;}
    public id c_csq_id {get;set;}
    
    /*
    public session__c getSession() {
        return jr_session.get_session(this.c_session_id);
    }

    public String getSession_json() {
        return JSON.serialize(jr_session.get_session(this.c_session_id));
    }
    */
    
    public list<custom_survey_answer__c> getFree_answers(){
        return jr_session.get_free_answers(c_csq_id);
    }
}