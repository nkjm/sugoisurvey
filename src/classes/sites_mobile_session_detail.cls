public with sharing class sites_mobile_session_detail {
    public id session_id {get;set;}

    public sites_mobile_session_detail(){
    }
    
    public session__c getSession_detail(){
        session__c s = jr_session.get_session(this.session_id);
        return s;
    }
    
    private static testmethod void validate_getSession_detail(){
    	sites_mobile_session_detail smsd = new sites_mobile_session_detail();
    	session__c session = validate_session.createDummySession('irjffiejdjhjkf', 'Eメールの入力が必要', 'アンケートの入力が必要');
    	smsd.session_id = session.id;
    	system.assertEquals('http://hoge.com', smsd.getSession_detail().handout_url__c);
    }
}