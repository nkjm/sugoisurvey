public with sharing class session_v2 {

    private session__c session;
    public boolean email_required {get;set;}
 
    public session_v2(ApexPages.StandardController controller) {
        session__c session = (session__c)controller.getRecord();
        if (session.id != null) {
            this.session = jr_session.get_session(session.id);
            if (this.session.who_can_submit_survey__c != '無条件' && this.session.who_can_submit_survey__c != 'Anyone'){
            	this.email_required = true;
            } else {
            	this.email_required = false;
            }
        }
    }

    public session__c getSession(){
        return this.session;
    }
    
    public string getSession_json(){
        return JSON.serialize(this.session).replaceAll('\\<.*?\\>', '');
    }

    public list<session__c> getSessions(){
        return [
            select 
                id,
                name,
                date__c,
                rate_avg__c,
                open__c,
                presenter__r.name,
                presenter__r.title__c,
                presenter__r.company__c
            from session__c order by date__c desc, createdDate desc
        ];
    }
    
    public static config__c config = config__c.getOrgDefaults();

    // Get method for retrieving custom setting
    public static config__c getConfig(){
        return config;
    }
    
    private static testmethod void validate_getConfig(){
        config.initialized__c = true;
        upsert config;
        system.assertEquals(true, getConfig().initialized__c);
    }
    
    public list<guest__c> getDeliveryDestinations(){
        list<guest__c> deliveryDestinations = new list<guest__c>();
        if (this.session.who_can_get_handout__c == '全員' ||
            this.session.who_can_get_handout__c == 'Anyone'){
            deliveryDestinations = [
            	select name__c, email__c, title__c, company__c, handout_delivered__c, checkin__c, status__c 
            	from guest__c 
            	where session__c = :this.session.id and email__c <> null and email__c <> ''
        	];
        } else if (this.session.who_can_get_handout__c == '出席者' ||
                   this.session.who_can_get_handout__c == 'Attendees'){
            deliveryDestinations = [
            	select name__c, email__c, title__c, company__c, handout_delivered__c, checkin__c, status__c 
            	from guest__c 
            	where session__c = :this.session.id and checkin__c = true and email__c <> null and email__c <> ''
        	];
        } else if (this.session.who_can_get_handout__c == 'アンケートの入力が必要' ||
                   this.session.who_can_get_handout__c == 'Require Survey Submission'){
            deliveryDestinations = [
            	select name__c, email__c, title__c, company__c, handout_delivered__c, checkin__c, status__c 
            	from guest__c 
            	where session__c = :this.session.id and status__c = 'submitted' and email__c <> null and email__c <> ''
        	];
        }
        return deliveryDestinations;
    }
    
    public string getMailBody(){
        string body = '';
        if (this.session.mass_mail_additional_body__c != null){
            body += '<p>' + this.session.mass_mail_additional_body__c + '</p>';
        }
        if (this.session.handout_url__c != null){
            body += '<p>';
            body += system.label.handout_download_url + ' : <a href="' + this.session.handout_url__c + '">' + this.session.handout_url__c + '</a>';
            if (this.session.handout_password__c != null){
                body += '<br/>' + system.label.password + ' : ' + this.session.handout_password__c;
            }
            body += '</p>';
        }
        return body;
    }
}