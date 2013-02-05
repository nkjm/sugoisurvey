public with sharing class session_v2 {
    private session__c session;
 
    public session_v2(ApexPages.StandardController controller) {
        session__c session = (session__c)controller.getRecord();
        if (session.id != null) {
        	this.session = jr_session.get_session(session.id);
        }
    }

    public class sugoiSurveyResult {
        public boolean status {get; set;}
        public string message {get; set;}
        public id record_id {get; set;}
    }

    public session__c getSession(){
        return this.session;
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
        if (this.session.who_can_get_handout__c == '全員' || this.session.who_can_get_handout__c == 'Everyone'){
            for (Guest__c guest : this.session.guest__r){
                if (guest.email__c != '' && guest.email__c != null){
					deliveryDestinations.add(guest);
                }
            }
        } else if (this.session.who_can_get_handout__c == 'アンケートの入力が必要' || this.session.who_can_get_handout__c == 'Survey Required'){
            List<id> guest_ids_submitted_survey = new List<id>();
            for (Survey__c survey : this.session.survey__r){
                guest_ids_submitted_survey.add(survey.guest__c);
            }
            if (guest_ids_submitted_survey.size() >= 1){
                try {
                	deliveryDestinations = [select name__c, email__c, company__c, title__c, handout_delivered__c from guest__c where id in :guest_ids_submitted_survey and email__c != '' order by handout_delivered__c, company__c];
                } catch (Exception e){
                }
            }
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