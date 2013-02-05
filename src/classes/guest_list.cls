public with sharing class guest_list {
	public string search_by {get;set;}
	public id option_id {get;set;}
	public id session_id {get;set;}
	public integer rate {get;set;}
	public id answer_id {get;set;}
	
    public guest_list(ApexPages.StandardController controller) {
    	this.search_by = ApexPages.currentPage().getParameters().get('search_by');
    	if(this.search_by == null){
    		return;
    	}
    	
    	this.session_id = ApexPages.currentPage().getParameters().get('session_id');
    	
    	if(this.search_by == 'option_id'){
    		this.option_id = ApexPages.currentPage().getParameters().get('option_id');
    	}
    	
    	if(this.search_by == 'answer_id'){
    		this.answer_id = ApexPages.currentPage().getParameters().get('answer_id');
    	}
    	
    	if(this.search_by == 'rate'){
	    	string rate = ApexPages.currentPage().getParameters().get('rate');
	    	if (rate != null){
	    		this.rate = integer.valueOf(rate);
	    	}
    	}
    }
    
    public list<guest__c> getGuests(){
    	list<guest__c> guests = new list<guest__c>();
    	if (this.session_id == null){
    		return null;
    	}
    	if (this.search_by == 'option_id'){
    		guests = getGuestsByOptionId();
    	} else if (this.search_by == 'rate'){
    		guests = getGuestsByRate();
    	} else if (this.search_by == 'answer_id'){
    		guests = getGuestsByAnswerId();
    	} else {
    		return null;
    	}
    	return guests;
    }
    
    private list<guest__c> getGuestsByRate(){
    	if (this.rate == null){
    		return null;
    	}
    	list<survey__c> surveys = [select guest__r.id, guest__r.name__c, guest__r.email__c, guest__r.title__c, guest__r.company__c from survey__c where session__c = :this.session_id and rate__c = :this.rate];
    	list<guest__c> guests = new list<guest__c>();
    	for (survey__c survey : surveys){
    		guests.add(survey.guest__r);
    	}
    	return guests;
    }
    
    private list<guest__c> getGuestsByAnswerId(){
    	if (this.answer_id == null){
    		return null;
    	}
    	list<custom_survey_answer__c> csas = [select guest__r.id, guest__r.name__c, guest__r.email__c, guest__r.title__c, guest__r.company__c from custom_survey_answer__c where session__c = :this.session_id and id = :this.answer_id];
    	list<guest__c> guests = new list<guest__c>();
    	for (custom_survey_answer__c csa : csas){
    		guests.add(csa.guest__r);
    	}
    	return guests;
    }
    
    private list<guest__c> getGuestsByOptionId(){
    	if (this.option_id == null){
    		return null;
    	}
    	list<custom_survey_answer__c> csas = [select guest__r.id, guest__r.name__c, guest__r.email__c, guest__r.title__c, guest__r.company__c from custom_survey_answer__c where session__c = :this.session_id and custom_survey_option__r.id = :this.option_id order by guest__r.company__c];
    	list<guest__c> guests = new list<guest__c>();
    	for (custom_survey_answer__c csa : csas){
    		guests.add(csa.guest__r);
    	}
    	return guests;
    }
    
    private static testmethod void validateGetGuests(){
    	session__c s = validate_session.createDummySession('igjfnfjeidjfd', 'Eメールの入力が必要', 'アンケートの入力が必要');
    	
    	guest_list gl = new guest_list(new ApexPages.StandardController(s));
    	
    	//// search_by = null
    	// set nothing
    	system.assertEquals(null, gl.getGuests());
    	
    	// set session_id but not set search_by nor key
    	ApexPages.currentPage().getParameters().put('session_id', s.id);
    	gl = new guest_list(new ApexPages.StandardController(s));
    	system.assertEquals(null, gl.getGuests());
    	
    	//// search_by = option_id
    	// set search_by but not set key
    	ApexPages.currentPage().getParameters().put('search_by', 'option_id');
    	gl = new guest_list(new ApexPages.StandardController(s));
    	system.assertEquals(null, gl.getGuests());
    	
    	// set search_by and session_id but not set key

    	gl = new guest_list(new ApexPages.StandardController(s));
    	system.assertEquals(null, gl.getGuests());
    	
    	// set all parameters
    	list<custom_survey_option__c> csos = [select id from custom_survey_option__c where session__c = :s.id];
    	gl.option_id = csos[0].id;
    	system.assertEquals(2, gl.getGuests().size());
    	
    	//// search_by = answer_id
    	// set search_by but not set key
    	ApexPages.currentPage().getParameters().put('search_by', 'answer_id');
    	gl = new guest_list(new ApexPages.StandardController(s));
    	system.assertEquals(null, gl.getGuests());
    	
    	// set all parameters
    	list<custom_survey_answer__c> csas = [select id from custom_survey_answer__c where session__c = :s.id];
    	gl.answer_id = csas[0].id;
    	system.assertEquals(1, gl.getGuests().size());
    	
    	//// search_by = rate
    	// set search_by but not set key
    	ApexPages.currentPage().getParameters().put('search_by', 'rate');
    	gl = new guest_list(new ApexPages.StandardController(s));
    	system.assertEquals(null, gl.getGuests());
    	
    	// set all parameters
    	gl.rate = 5;
    	system.assertEquals(1, gl.getGuests().size());
    }
}