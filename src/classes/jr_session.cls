public with sharing class jr_session {

    public jr_session(ApexPages.StandardController controller) {
    }
    
    public class r {
        public boolean status {get;set;}
        public string message {get;set;}
    }
    
    @remoteAction 
    public static r finish_init(){
    	r r = new r();
    	config__c config = config__c.getOrgDefaults();

        // Quit if app has been initialized.
        if (config.initialized__c == true){
            r.status = false;
            r.message = system.label.already_initialized;
            return r;
        }
        
    	config.initialized__c = true;
    	upsert config;
    	
    	// Start copying comment to feedItem
        Datetime next = Datetime.now().addMinutes(1);
        string sch = string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?';
        if (!Test.isRunningTest()){
            system.schedule('Copy comment to feedItem - ' + string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?', sch, new schedule_copy_comment_to_feedItem());
        }
        
    	r.status = true;
    	return r;
    }
    
    private static testmethod void validate_finish_init(){
        r r = new r();

        config__c config = config__c.getOrgDefaults();
        config.initialized__c = false;
        upsert config;
        
        r = finish_init();
        system.assertEquals(true, r.status);
        system.assertEquals(true, config__c.getOrgDefaults().initialized__c);
        
        r = finish_init();
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.already_initialized, r.message);
    }

    @remoteAction 
    public static r assign_permission_set(){
    	r r = new r();
   		config__c config = config__c.getOrgDefaults();
   		
        // Quit if site has not been activated
		if (config.survey_sites_domain__c == null){
			r.status = false;
			r.message = system.label.sites_not_activated;
			return r;
		}
		
        string sites_user_username = 'sugoisurvey@' + config.survey_sites_domain__c;
        
        // retreive id of user for sites
        string sites_user_id;
        try {
        	sites_user_id = [select id from user where username = :sites_user_username].id;
        } catch(Exception e) {
        	r.status = false;
        	r.message = system.label.sites_user_not_found;
        	return r;
        }
        
        // retrieve id of permission set for sites
        string sites_permission_set_id;
        try {
        	sites_permission_set_id = [select id from permissionSet where name = 'Sugoi_Survey_Sites_for_Any_License'].id;
        } catch(Exception e){
        	r.status = false;
        	r.message = system.label.sites_permission_set_not_found;
        	return r;
        }
        
        permissionSetAssignment psa = new permissionSetAssignment(assigneeId = sites_user_id, permissionSetId = sites_permission_set_id);
        insert psa;
        
        r.status = true;
        return r;
    }
    
    private static testmethod void validate_assign_permission_set(){
    	/*
    	r r = new r();
    	r = assign_permission_set();
    	system.assertEquals(true, r.status);
    	
    	string sites_user_username = 'sugoisurvey@sugoisurvey-developer-edition.na14.force.com';
    	id sites_user_id = [select id from user where username = :sites_user_username].id;
    	id sites_permission_set_id = [select id from permissionSet where name = 'Sugoi_Survey_Sites_for_Any_License'].id;
    	system.assertEquals(1, [select id from permissionSetAssignment where assigneeId = :sites_user_id and permissionSetId = :sites_permission_set_id].size());
    	*/
    }
    
    @remoteAction 
    public static r start_init(){
        r r = new r();
        config__c config = config__c.getOrgDefaults();
        
        // Quit if app has been initialized.
        if (config.initialized__c == true){
            r.status = false;
            r.message = system.label.already_initialized;
            return r;
        }
        
        // Quit if sites has not been activated yet.
        list<site> sites = [select status, subdomain from site where urlPathPrefix = 'sugoisurvey'];
		if (sites.size() == 0 || sites[0].subdomain == null || sites[0].status != 'Active'){
			r.status = false;
			r.message = system.label.sites_not_activated;
			return r;
		}
		
		// Identify the Edition of this Org
		string edition = [select OrganizationType from organization].OrganizationType;
        
        // Set Domain and Survey Site URL
        if (edition == 'Team Edition' || edition == 'Professional Edition' || edition == 'Enterprise Edition' || edition == 'Unlimited Edition'){
        	// Production Org
        	config.survey_sites_domain__c = sites[0].subdomain + '.force.com';
        	config.survey_sites_url__c = 'https://' + sites[0].subdomain + '.secure.force.com/sugoisurvey/';
        } else {
        	// Non-Production Org
        	string sites_instance = system.url.getSalesforceBaseUrl().getHost().replace('sugoisurvey4','').replace('visual.force.com','').replace('salesforce.com','').replace('.','').replace(sites[0].subdomain + '--', '');
        	config.survey_sites_domain__c = sites[0].subdomain + '.' + sites_instance + '.force.com';
        	config.survey_sites_url__c = 'https://' + config.survey_sites_domain__c + '/sugoisurvey/';
        }
        
        upsert config;

        r.status = true;
        return r;
    }
    
    private static testmethod void validate_start_init(){
    	r r = new r();
		
    	r = start_init();
    	system.assertEquals(true, r.status);
    	system.assertEquals('https://sugoisurvey4-developer-edition.na11.force.com/sugoisurvey/', config__c.getOrgDefaults().survey_sites_url__c);
    	system.assertEquals('sugoisurvey4-developer-edition.na11.force.com', config__c.getOrgDefaults().survey_sites_domain__c);
    	
    	config__c config = config__c.getOrgDefaults();
    	config.initialized__c = true;
    	upsert config;
    	r = start_init();
    	system.assertEquals(false, r.status);
    	system.assertEquals(system.label.already_initialized, r.message);
    }
    
    @remoteAction
    public static r close_survey(id session_id){
        r r = new r();
        
        if (session_id == null){
            return null;
        }

        try {
            session__c session = [select id, open__c from session__c where id = :session_id];   
            session.open__c = false;
            update session;
        } catch (Exception e){
            r.status = false;
            r.message = system.label.specified_session_does_not_exist;
            return r;
        }
        
        r = copy_comment_to_feedItem(session_id);
        if(!r.status){
            return r;
        }
        
        r.status = true;
        return r;
    }
    
    private static testmethod void validate_close_survey(){
        r r = new r();
        session__c session = validate_session.createDummySession('irjffiejdjhjkf', 'Eメールの入力が必要', 'アンケートの入力が必要');
        system.assertEquals(true, [select open__c from session__c where id = :session.id].open__c);
        
        close_survey(session.id);
        system.assertEquals(false, [select open__c from session__c where id = :session.id].open__c);
        system.assertEquals(2, [select id from feedItem where parentId = :session.id].size());
        
        delete session;
        r = close_survey(session.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
    }
    
    @remoteAction
    public static r copy_comment_to_feedItem(id session_id){
        r r = new r();
        list<comment__c> comments_to_copy;
        
        if (session_id == null){
            comments_to_copy = [select id, comment__c, guest__r.company__c, guest__r.title__c, guest__r.last_name__c, guest__r.first_name__c, guest__r.id, session__c, session__r.open__c from comment__c where session__r.open__c = true and copied_to_feedItem__c = false];
        } else {
            comments_to_copy = [select id, comment__c, guest__r.company__c, guest__r.title__c, guest__r.last_name__c, guest__r.first_name__c, guest__r.id, session__c from comment__c where session__c = :session_id and copied_to_feedItem__c = false];
        }
        
        for (comment__c c : comments_to_copy){
            if(create_feedItem_from_comment(c.session__c, c.comment__c, c.guest__r)){
                c.copied_to_feedItem__c = true;
            } else {
                r.status = false;
                r.message = system.label.failed_to_create_feedItem;
                return r;
            }
        }

		if (comments_to_copy != null && comments_to_copy.size() > 0){
        	update comments_to_copy;
		}
        
        r.status = true;
        return r;
    }
    
    private static testmethod void validate_copy_comment_to_feedItem(){
        // perform only for batch based copy since manual copy validation is implemented in validate_close_survey()
        r r = new r();
        session__c s1 = validate_session.createDummySession('irjffiejdjhjkf', 'Eメールの入力が必要', 'アンケートの入力が必要');
        session__c s2 = validate_session.createDummySession('afjrrhjgjjfjfjjf', 'Eメールの入力が必要', 'アンケートの入力が必要');
        session__c s3 = validate_session.createDummySession('brjffisdferdjhjkf', 'Eメールの入力が必要', 'アンケートの入力が必要');
        s3.open__c = false;
        update s3;
        
        r = copy_comment_to_feedItem(null);
        system.assertEquals(true, r.status);
        system.assertEquals(2, [select id from feedItem where parentId = :s1.id].size());
        system.assertEquals(2, [select id from feedItem where parentId = :s2.id].size());
        system.assertEquals(0, [select id from feedItem where parentId = :s3.id].size());
    }

    public static boolean create_feedItem_from_comment(id parent_id, string body, guest__c guest){
        string url = '/' + guest.id;
        string title = '';
        if (guest == null){
        	return false;
        }
        if (guest.company__c != null && guest.company__c != ''){
            title += guest.company__c + ' ';
        }
        if (guest.title__c != null && guest.title__c != ''){
            title += guest.title__c + ' ';
        }
        if (guest.last_name__c != null && guest.last_name__c != ''){
            title += guest.last_name__c + ' ';
        }
        if (guest.first_name__c != null && guest.first_name__c != ''){
            title += guest.first_name__c;
        }
        if (title == ''){
            title = system.label.unregistered_guest;
        }

        FeedItem fi = new FeedItem();
        fi.type = 'LinkPost';
        fi.parentId = parent_id;
        fi.body = body;
        fi.linkUrl = url;
        fi.title = title;
        try {
            insert fi;
        } catch (Exception e) {
            return false;
        }
        return true;
    }
    
    @remoteAction
    public static r submit_survey(survey__c survey, comment__c comment, list<custom_survey_answer__c> csas, string guest_email){
        r r = new r();
        SFDCEncoder enc = new SFDCEncoder();
        savepoint sp = Database.setSavepoint();
        
        if (survey.session__c == null){
            r.status = false;
            r.message = system.label.session_id_is_not_set;
            return r;
        }
        
        session__c session;
        try {
            session = [select enable_rate__c, label_for_rate__c, who_can_submit_survey__c from session__c where id = :survey.session__c];
        } catch (Exception e){
            r.status = false;
            r.message = system.label.specified_session_does_not_exist;
            return r;
        }
        
        // check value of rate 
        if (session.enable_rate__c == true){
		    if (survey.rate__c == null || !(1 <= survey.rate__c) || !(survey.rate__c <= 5)){
		        r.status = false;
		        string label_for_rate;
		        if (session.label_for_rate__c == null){
		            label_for_rate = system.label.xPointScale;
		        } else {
		            label_for_rate = session.label_for_rate__c;
		        }
		        r.message = system.label.pls_enter_required_field + ' ' + label_for_rate;
		        return r;         
		    }
        } else {
        	survey.rate__c = null;
        }
        
        // - check if user is entitled to submit survey
        // - identify guest by email if user is registered guest
        // - insert guest__c if user is unregistered guest and if condition is not registered only
        guest__c guest;
        if (session.who_can_submit_survey__c == '無条件' || session.who_can_submit_survey__c == 'Anyone'){
            guest = identifyGuest(session.id, guest_email);
            if (guest == null){
                guest = createAnonymousGuest(session.id, guest_email);
            }
            if (guest == null){
                r.status = false;
                r.message = system.label.invalid_email;
                return r;
            }
        } else if (session.who_can_submit_survey__c == 'Eメールの入力が必要' || session.who_can_submit_survey__c == 'Required Email'){
            if (guest_email == '' || guest_email == null){
                r.status = false;
                r.message = system.label.pls_input_email;
                return r;
            }
            guest = identifyGuest(session.id, guest_email);
            if (guest == null){
                guest = createAnonymousGuest(session.id, guest_email);
            }
            if (guest == null){
                r.status = false;
                r.message = system.label.invalid_email;
                return r;  
            }
        } else if (session.who_can_submit_survey__c == '事前登録者のみ' || session.who_can_submit_survey__c == 'Registered Guests Only') {
            if (guest_email == '' || guest_email == null){
                r.status = false;
                r.message = system.label.pls_input_email;
                return r;
            }
            guest = identifyGuest(session.id, guest_email);
            if (guest == null){
                r.status = false;
                r.message = system.label.email_not_registered;
                return r;
            }
        } else {
            r.status = false;
            r.message = system.label.session_is_not_configured_correctly;
            return r;
        }
   
        // prevent duplicated submit
        List<Survey__c> existing_surveys = [select id from survey__c where session__c = :session.id and guest__c = :guest.id];
        if (!existing_surveys.isEmpty()){
            r.status = false;
            r.message = system.label.already_submitted;
            return r;
        }
        
        // insert survey
        survey.guest__c = guest.id;
        insert survey;
        
        // insert comment__c and feedItem
        if (comment.comment__c != null && comment.comment__c != ''){
            // insert comment__c
            insert(new comment__c(session__c = session.id, guest__c = guest.id, comment__c = enc.SFDC_HTMLENCODE(comment.comment__c)));
            
            /*
            // set parameter for feedItem
            string url = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + guest.id;
            string url_name = '';
            if (guest.company__c != null && guest.company__c != ''){
                url_name += guest.company__c + ' ';
            }
            if (guest.title__c != null && guest.title__c != ''){
                url_name += guest.title__c + ' ';
            }
            if (guest.name__c != null && guest.name__c != ''){
                url_name += guest.name__c;
            }
            if (url_name == ''){
                url_name = system.label.unregistered_guest;
            }
            
            // insert feedItem
            if (!createLinkPost(session.id, comment.comment__c, url, url_name)){
                r.status = false;
                r.message = system.label.failed_to_create_linkpost;
                return r;
            }
            */
        }
        
        // prepare custom_survey_answers to insert
        List<Custom_Survey_Answer__c> csas_to_add = new List<Custom_Survey_Answer__c>();
        for (custom_survey_answer__c csa : csas){
            if (csa.custom_survey_option__c == null){
                continue;
            }
            csa.session__c = session.id;
            csa.guest__c = guest.id;
            if (csa.free_form__c != null && csa.free_form__c != ''){
                csa.free_form__c = enc.SFDC_HTMLENCODE(csa.free_form__c);
            }
            csas_to_add.add(csa);
        }
        
        // insert custom_survey_asnwers
        if (csas_to_add.size() > 0){
            insert csas_to_add;
        }

        r.status = true;
        return r;
    }
    
    private static guest__c identifyGuest(id session_id, string guest_email){
        guest__c guest;
        if (guest_email == '' || guest_email == null){
            return guest;
        }
        try {
            guest = [select id, name__c, last_name__c, first_name__c, title__c, company__c from guest__c where session__c = :session_id AND email__c = :guest_email];
        } catch (Exception e){
            return guest;
        }
        return guest;
    }
    
    private static guest__c createAnonymousGuest(id session_id, string guest_email){
        guest__c guest = new guest__c();
        guest.session__c = session_id;
        guest.last_name__c = system.label.unregistered_guest;
        guest.email__c = guest_email;
        guest.title__c = '';
        guest.company__c = '';
        try {
            insert guest;
        } catch(Exception e){
            guest = null;
        }
        return guest;
    }

/*
    public static boolean createLinkPost(id parent_id, string body, string url, string title){
        FeedItem fi = new FeedItem();
        fi.type = 'LinkPost';
        fi.parentId = parent_id;
        fi.body = body;
        fi.linkUrl = url;
        fi.title = title;
        try {
            insert fi;
        } catch (Exception e) {
            return false;
        }
        return true;
    }
*/
    
    private static testMethod void validate_submit_survey(){
        r r = new r();
        
        //create dummy session
        List<session__c> session_list = new List<session__c>();
        session_list.add(new Session__c(who_can_submit_survey__c='無条件'));
        session_list.add(new Session__c(who_can_submit_survey__c='Eメールの入力が必要'));
        session_list.add(new Session__c(who_can_submit_survey__c='事前登録者のみ'));
        insert session_list;
        
        for (session__c session : session_list){
            //create test data for guest
            Guest__c guest1 = new Guest__c(last_name__c = 'Test1 Name', session__c = session.id, email__c = 'test1@hoge.com', company__c = 'Test1 Inc.');
            insert guest1;
            
            //create test data for custom_survey_question
            Custom_survey_question__c custom_survey_question = new Custom_survey_question__c(session__c = session.id, question__c = 'test question1');
            insert custom_survey_question;
            
            //create test data for custom_survey_option
            Custom_survey_option__c custom_survey_option1 = new Custom_survey_option__c(session__c = session.id, custom_survey_question__c = custom_survey_question.id, option__c = 'test option1');
            Custom_survey_option__c custom_survey_option2 = new Custom_survey_option__c(session__c = session.id, custom_survey_question__c = custom_survey_question.id, option__c = 'test option2');
            insert custom_survey_option1;
            insert custom_survey_option2;
            
            //create answer of guest1 (Registered)
            list<custom_survey_answer__c> csas_of_guest1 = new list<custom_survey_answer__c>();
            csas_of_guest1.add(new custom_survey_answer__c(custom_survey_option__c = custom_survey_option1.id));
            csas_of_guest1.add(new custom_survey_answer__c(custom_survey_option__c = custom_survey_option2.id, free_form__c = 'value for free form'));
            
            
            // null session id
            r = submit_survey(
                new survey__c(),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(false, r.status);
            system.assertEquals(system.label.session_id_is_not_set, r.message);
            
            // null rate
            r = submit_survey(
                new survey__c(session__c = session.id),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(false, r.status);
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.xPointScale, r.message);
            
            // invalid rate
            r = submit_survey(
                new survey__c(session__c = session.id, rate__c = 101),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(false, r.status);
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.xPointScale, r.message);
            
            //correct submit
            r = submit_survey(
                new survey__c(session__c = session.id, rate__c = 5),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(true, r.status);
            
            //duplicated submit
            r = submit_survey(
                new survey__c(session__c = session.id, rate__c = 5),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(false, r.status);
            system.assertEquals(system.label.already_submitted, r.message);
            
            //create answer of guest2 (With Email)
            list<custom_survey_answer__c> csas_of_guest2 = new list<custom_survey_answer__c>();
            csas_of_guest2.add(new custom_survey_answer__c(custom_survey_option__c = custom_survey_option1.id));

            // invalid email
            r = submit_survey(
                new survey__c(session__c = session.id, rate__c = 4),
                new comment__c(comment__c = 'test comment2'),
                csas_of_guest2, 
                'guest2.hoge.com'
            );
            system.assertEquals(false, r.status);
            r = submit_survey(
                new survey__c(session__c = session.id, rate__c = 4),
                new comment__c(comment__c = 'test comment2'),
                csas_of_guest2, 
                'guest2@hoge.com'
            );
            
            //create answer of guest3 (Anonymous)
            list<custom_survey_answer__c> csas_of_guest3 = new list<custom_survey_answer__c>();
            csas_of_guest3.add(new custom_survey_answer__c(custom_survey_option__c = custom_survey_option2.id));
            
            r = submit_survey(
                new survey__c(session__c = session.id, rate__c = 3),
                new comment__c(comment__c = 'test comment3'),
                csas_of_guest3, 
                ''
            );
            
            //check avg.
            Session__c session_for_validate = [select rate_avg__c from session__c where id = :session.id];
            if (session.Who_Can_Submit_Survey__c == '無条件'){
                system.assertEquals(4, session_for_validate.rate_avg__c);
                Custom_survey_option__c custom_survey_option_for_validate1 = [select sum__c from custom_survey_option__c where id = :custom_survey_option1.id];
                Custom_survey_option__c custom_survey_option_for_validate2 = [select sum__c from custom_survey_option__c where id = :custom_survey_option2.id];
                system.assertEquals(2, custom_survey_option_for_validate1.sum__c);
                system.assertEquals(2, custom_survey_option_for_validate2.sum__c);
            } else if (session.Who_Can_Submit_Survey__c == 'Eメールの入力が必要'){
                system.assertEquals(4.5, session_for_validate.rate_avg__c);
                Custom_survey_option__c custom_survey_option_for_validate1 = [select sum__c from custom_survey_option__c where id = :custom_survey_option1.id];
                Custom_survey_option__c custom_survey_option_for_validate2 = [select sum__c from custom_survey_option__c where id = :custom_survey_option2.id];
                system.assertEquals(2, custom_survey_option_for_validate1.sum__c);
                system.assertEquals(1, custom_survey_option_for_validate2.sum__c);
            } else if (session.Who_Can_Submit_Survey__c == '事前登録者のみ'){
                system.assertEquals(5, session_for_validate.rate_avg__c);
                Custom_survey_option__c custom_survey_option_for_validate1 = [select sum__c from custom_survey_option__c where id = :custom_survey_option1.id];
                Custom_survey_option__c custom_survey_option_for_validate2 = [select sum__c from custom_survey_option__c where id = :custom_survey_option2.id];
                system.assertEquals(1, custom_survey_option_for_validate1.sum__c);
                system.assertEquals(1, custom_survey_option_for_validate2.sum__c);
            }
        }
        
        // validate enable_rate__c
        session__c session_rate_disabled = new session__c(name='rirjfnkeik', enable_rate__c=true, who_can_submit_survey__c='無条件');
        insert session_rate_disabled;
        r = submit_survey(new survey__c(session__c = session_rate_disabled.id), new comment__c(comment__c = ''), new list<custom_survey_answer__c>(), '');
        system.assertEquals(false, r.status);
        session_rate_disabled.enable_rate__c = false;
        update session_rate_disabled;
        r = submit_survey(new survey__c(session__c = session_rate_disabled.id), new comment__c(comment__c = ''), new list<custom_survey_answer__c>(), '');
        system.assertEquals(true, r.status);
    }
    
    @remoteAction
    public static session__c get_session(id session_id){
        session__c session;
        
        if (session_id == null){
            return null;
        }
        
        try {
            session = [
                select
                    id, 
                    name,
                    open__c, 
                    date__c,
                    hash_tag__c, 
                    rate_avg__c,
                    enable_rate__c,
                    label_for_rate__c,
                    survey_collection_rate__c,
                    survey_sum__c,
                    guest_sum__c,
                    who_can_get_handout__c,
                    who_can_submit_survey__c,
                    mass_mail_sender__c,
                    mass_mail_additional_body__c,
                    handout_url__c,
                    handout_password__c,
                    owner.email,
                    presenter__r.name,
                    presenter__r.title__c,
                    presenter__r.company__c,
                    (select id, name__c, email__c, title__c, company__c, handout_delivered__c from guest__r order by handout_delivered__c, company__c),
                    (select id, name, guest__c, rate__c from survey__r order by name),
                    (select id, name, comment__c from comment__r order by name desc),
                    (select id, name, question__c, survey_type__c, sort_order__c, enable_free_form__c, session__c from custom_survey_question__r order by sort_order__c, name),
                    (select id, name, option__c, enable_free_form__c, dummy__c, sum__c, session__c, custom_survey_question__c from custom_survey_option__r order by name),
                    (select id, free_form__c from custom_survey_answer__r order by name desc),
                    (select id from lead__r),
                    (select id, name from attachments)
                from Session__c where id = :session_id
            ];
        } catch (Exception e){
            return null;
        }
        
        return session;
    }

    private static testmethod void validate_get_session(){
        session__c session;
        session = validate_session.createDummySession('wpoeiru', 'Eメールの入力が必要', 'アンケートの入力が必要');
        
        /*
        Condition
        - session_id => null
        - open__c => true
        */
        system.assertEquals(null, get_session(null));
        
        /*
        Condition
        - session_id => set(exists)
        - open__c => true
        */
        system.assertEquals('wpoeiru', get_session(session.id).name);

        /*
        Condition
        - session_id => set(exists)
        - open__c => false
        */
        session.open__c = false;
        update session;
        system.assertEquals('wpoeiru', get_session(session.id).name);
        
        /*
        Condition
        - session_id => set(not exist)
        - open__c => n/a
        */
        delete session;
        system.assertEquals(null, get_session(session.id));
    }
    
    @remoteAction
    public static r reorder_question(id session_id, list<id> question_ids){
        r r = new r();
        
        if (session_id == null){
            r.status = false;
            r.message = system.label.session_id_is_not_set;
            return r;
        }
        
        if (question_ids.size() < 2){
            r.status = false;
            r.message = system.label.there_are_not_enough_number_of_question_to_sort;
            return r;
        }
        
        list<custom_survey_question__c> csqs = [select id, sort_order__c from custom_survey_question__c where session__c = :session_id];

        if (csqs.size() < 2){
            r.status = false;
            r.message = system.label.there_are_not_enough_number_of_question_to_sort;
            return r;
        }
        
        if (csqs.size() != question_ids.size()){
            r.status = false;
            r.message = system.label.requested_number_of_question_is_not_valid;
            return r;
        }
        
        integer sort_order = 1;
        boolean found = false;
        for (id question_id : question_ids){
            for (custom_survey_question__c csq : csqs){
                if (csq.id == question_id){
                    csq.sort_order__c = sort_order;
                    found = true;
                    break;
                }
            }
            if (found == false){
                r.status = false;
                r.message = system.label.specified_question_not_found;
                return r;
            }
            sort_order++;
            found = false;
        }
        
        update csqs;
        
        r.status = true;
        return r;
    }
    
    private static testmethod void validate_reorder_question(){
        r r = new r();
        
        session__c s = new session__c(name = 'curnfivdnbnef');
        insert s;
        
        custom_survey_question__c csq = new custom_survey_question__c(session__c = s.id, question__c = '#1');
        insert csq;
        
        list<id> question_ids = new list<id>();
        question_ids.add(csq.id);

        // session id is null       
        r = reorder_question(null, question_ids);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);

        // requested # of question < 2
        r = reorder_question(s.id, question_ids);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.there_are_not_enough_number_of_question_to_sort, r.message);

        // re-order and sort_order__c in 2 questions are updated
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#2');
        insert csq;
        question_ids.add(csq.id);
        r = reorder_question(s.id, question_ids);
        system.assertEquals(true, r.status);
        system.assertEquals(1, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#1'].sort_order__c);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#2'].sort_order__c);

        // reverse the order
        list<id> question_ids_reversed = question_ids.clone();
        question_ids_reversed[0] = question_ids[1];
        question_ids_reversed[1] = question_ids[0];
        r = reorder_question(s.id, question_ids_reversed);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#1'].sort_order__c);
        system.assertEquals(1, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#2'].sort_order__c);
        
        // # of question in database < 2
        delete csq;
        r = reorder_question(s.id, question_ids_reversed);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.there_are_not_enough_number_of_question_to_sort, r.message);

        // # of requested question < database
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#2');
        insert csq;
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#3');
        insert csq;
        list<custom_survey_question__c> csqs = [select id from custom_survey_question__c where session__c = :s.id];
        question_ids = new list<id>();
        for (custom_survey_question__c csq_qoiweuyr : csqs){
            question_ids.add(csq_qoiweuyr.id);
        }
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#4');
        insert csq;
        r = reorder_question(s.id, question_ids);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.requested_number_of_question_is_not_valid, r.message);

        // # of requested question > database
        csqs = [select id from custom_survey_question__c where session__c = :s.id];
        question_ids = new list<id>();
        for (custom_survey_question__c csq_ueryyruu : csqs){
            question_ids.add(csq_ueryyruu.id);
        }
        question_ids[0] = s.id;
        r = reorder_question(s.id, question_ids);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_question_not_found, r.message);
    }
    
    @remoteAction
    public static r clone_session(id session_id){
        r r = new r();
        
        if (session_id == null){
            r.status = false;
            r.message = system.label.session_id_is_not_set;
            return r;
        }
        
        // clone session record
        session__c old_session = get_session(session_id);
        session__c new_session = old_session.clone(false, true, false, false);
        new_session.date__c = null;
        new_session.hash_tag__c = null;
        insert new_session;
        
        // retrieve question records and clone
        list<custom_survey_question__c> old_csqs = old_session.custom_survey_question__r;
        list<custom_survey_question__c> new_csqs = old_csqs.deepclone();
        for (custom_survey_question__c new_csq : new_csqs){
            new_csq.session__c = new_session.id;
        }
        insert new_csqs;
        
        // create map between old question id and new question id
        map<string, string> csq_id_map = new map<string, string>();
        integer i = 0;
        for (custom_survey_question__c old_csq : old_csqs){
            csq_id_map.put(old_csq.id, new_csqs[i].id);
            i++;
        }
        
        // retrieve option records and clone
        list<custom_survey_option__c> old_csos = old_session.custom_survey_option__r;
        list<custom_survey_option__c> new_csos = old_csos.deepclone();
        for (custom_survey_option__c new_cso : new_csos){
            new_cso.session__c = new_session.id;
            new_cso.custom_survey_question__c = csq_id_map.get(new_cso.custom_survey_question__c);
        }
        insert new_csos;
        
        r.status = true;
        return r;
    }
    
    private static testmethod void validate_clone_session(){
        r r = new r();
        r = clone_session(null);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        session__c s = validate_session.createDummySession('woeiru34oriudf', 'Eメールの入力が必要', 'アンケートの入力が必要');
        r = clone_session(s.id);
        system.assertEquals(true, r.status);
        system.assertEquals(2, [select id from session__c where name = 'woeiru34oriudf'].size());
    }

    @remoteAction
    public static list<custom_survey_answer__c> get_free_answers(id csq_id){
        list<custom_survey_answer__c> free_answers;
        if (csq_id == null){
            return null;
        }
        
        string survey_type;
        try {
            survey_type = [select survey_type__c from custom_survey_question__c where id = :csq_id].survey_type__c;
        } catch (Exception e){
            return null;
        }
        
        if (survey_type == 'checkbox' || survey_type == 'radio'){
            // retrieve free answer in case of selectable survey
            try {
                free_answers =  [select id, name, session__c, guest__c, custom_survey_option__c, free_form__c from custom_survey_answer__c where custom_survey_option__r.custom_survey_question__c = :csq_id AND custom_survey_option__r.enable_free_form__c = true AND free_form__c != null order by name desc];
            } catch (Exception e){
                return null;
            }
        } else {
            // retrieve free answers in case of non-selectable survey
            try {
                free_answers =  [select id, name, session__c, guest__c, custom_survey_option__c, free_form__c from custom_survey_answer__c where custom_survey_option__r.custom_survey_question__c = :csq_id AND custom_survey_option__r.dummy__c = true AND free_form__c != null order by name desc];
            } catch (Exception e){
                return null;
            }
        }
        
        if (free_answers.size() == 0){
            return null;
        }
        return free_answers;
    }
    
    private static testmethod void validate_get_free_answers(){
        session__c s = new session__c(name = 'test session');
        insert s;
        
        custom_survey_question__c csq = new custom_survey_question__c(session__c = s.id, question__c = 'test question');
        insert csq;
        
        custom_survey_option__c cso1 = new custom_survey_option__c(session__c = s.id, custom_survey_question__c = csq.id, option__c = 'test option1', enable_free_form__c = true);
        custom_survey_option__c cso2 = new custom_survey_option__c(session__c = s.id, custom_survey_question__c = csq.id, option__c = 'test option2', enable_free_form__c = false);
        insert cso1;
        insert cso2;
        
        custom_survey_answer__c csa1 = new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso1.id, free_form__c = 'test answer1');
        custom_survey_answer__c csa2 = new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso1.id);
        custom_survey_answer__c csa3 = new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso2.id);
        insert csa1;
        insert csa2;
        insert csa3;

        /*
        Condition
        - csq_id => null
        */
        system.assertEquals(null, get_free_answers(null));

        /*
        Condition
        - csq_id => set(exists)
        */
        system.assertEquals(1, get_free_answers(csq.id).size());
        
        /*
        Condition
        - csq_id => set(not exist)
        */
        delete csq;
        system.assertEquals(null, get_free_answers(csq.id));
        
        // for non-selectable survey
        r r = new r();
        r = create_survey(new custom_survey_question__c(session__c = s.id, question__c = 'jfioirgjbiorfv', survey_type__c = 'free'), new list<custom_survey_option__c>());
        id cso_id = [select id from custom_survey_option__c where session__c = :s.id and custom_survey_question__c = :r.message].id;
        insert new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso_id, free_form__c = 'lkjhsdfoewiur');
        insert new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso_id, free_form__c = 'iefjvniefjjie');
        system.assertEquals(2, get_free_answers(r.message).size());
        system.assertEquals('iefjvniefjjie', get_free_answers(r.message)[0].free_form__c);
        system.assertEquals('lkjhsdfoewiur', get_free_answers(r.message)[1].free_form__c);  
    }

    @remoteAction
    public static r add_session(string session_name){
        r r = new r();
        
        if (session_name == null || session_name == ''){
            r.status = false;
            r.message = system.label.pls_enter_session_name;
            return r;
        }
        session__c new_session = new session__c();
        new_session.name = session_name;
        insert new_session;
        
        r.status = true;
        r.message = new_session.id;
        return r;
    }

    private static testmethod void validate_add_session(){
        r r = new r();
        r = add_session('');
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.pls_enter_session_name, r.message);
        
        r = add_session('session for validate');
        system.assertEquals(true, r.status);
    }
    
    @remoteAction
    public static r delete_session(id session_id){
        r r = new r();
        
        if (session_id == null){
            r.status = false;
            r.message = system.label.session_id_is_not_set;
            return r;
        }
        
        session__c session = get_session(session_id);
        if (session == null){
            r.status = false;
            r.message = system.label.specified_session_does_not_exist;
            return r;
        }

        delete session;

        // delete custom_survey_option__c
        try {
            delete session.custom_survey_option__r;
        } catch (Exception e){
        }
        
        // delete custom_survey_answer__s
        try {
            delete session.custom_survey_answer__r;
        } catch (Exception e){
        }
        
        // delete lead
        try {
            delete session.lead__r;
        } catch (Exception e){
        }
        
        r.status = true;
        r.message = session.id;
        return r;
    }
    
    private static testmethod void validate_delete_session(){
        r r = new r();
        r = delete_session(null);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        session__c s = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        delete s;
        r = delete_session(s.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
        
        s = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        r = delete_session(s.id);
        system.assertEquals(true, r.status);
    }
    
    @remoteAction
    public static r delete_survey(id survey_id){
        r r = new r();
        if (survey_id == null){
            r.status = false;
            r.message = system.label.survey_id_is_not_set;
            return r;           
        }
        
        custom_survey_question__c csq;
        try {
            csq = [select id from custom_survey_question__c where id = :survey_id];
        } catch (Exception e){
            r.status = false;
            r.message = system.label.specified_survey_does_not_exist;
            return r;
        }
        
        delete csq;
        
        r.status = true;
        r.message = survey_id;
        return r;
    }
    
    private static testmethod void validate_delete_survey(){
        r r = new r();
        
        r = delete_survey(null);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.survey_id_is_not_set, r.message);
        
        r = delete_survey('000000000000000000');
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_survey_does_not_exist, r.message);
            
        session__c s = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        custom_survey_question__c csq = [select id from custom_survey_question__c where session__c = :s.id];
        
        r = delete_survey(csq.id);
        system.assertEquals(true, r.status);
    }

    @remoteAction
    public static r create_survey(custom_survey_question__c csq, list<custom_survey_option__c> csos){
        r r = new r();
        
        if (csq.session__c == null){
            r.status = false;
            r.message = system.label.session_id_is_not_set;
            return r;           
        }
        try {
            string session_id_for_test = [select id from session__c where id = :csq.session__c].id;
        } catch (Exception e){
            r.status = false;
            r.message = system.label.specified_session_does_not_exist;
            return r;
        }
        
        if (csq.question__c == null || csq.question__c == '') {
            r.status = false;
            r.message = system.label.pls_enter_question;
            return r;
        }
        
        if (csq.survey_type__c == 'free'){
            csq.enable_free_form__c = false;
        }
        
        // add sort order if it has been set in existing questions
        list<custom_survey_question__c> existing_csqs;
        integer sort_order;
        existing_csqs = [select sort_order__c from custom_survey_question__c where session__c = :csq.session__c and sort_order__c != null order by sort_order__c desc];
        if(existing_csqs.size() > 0){
            csq.sort_order__c = existing_csqs[0].sort_order__c + 1;
        }
        insert csq;
        
        // prepare options to insert
        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        
        if (csq.survey_type__c == 'checkbox' || csq.survey_type__c == 'radio') {
        	// In case of selectable survey
            for (custom_survey_option__c cso : csos){
                if (cso.option__c != null && cso.option__c != ''){
                    csos_to_add.add(new custom_survey_option__c(
                        session__c = csq.session__c,
                        custom_survey_question__c = csq.id,
                        option__c = cso.option__c
                    ));
                }
            }
            
            if (csq.enable_free_form__c){
            	// add option for free form
                csos_to_add.add(new custom_survey_option__c(
                    session__c = csq.session__c,
                    custom_survey_question__c = csq.id,
                    option__c = system.label.other,
                    enable_free_form__c = true
                ));
            }
        } else {
        	// In case of non-selectable survey
            csos_to_add.add(new custom_survey_option__c(
                session__c = csq.session__c,
                custom_survey_question__c = csq.id,
                option__c = system.label.dummy,
                dummy__c = true
            ));
        }
        
        insert csos_to_add;
        
        r.message = csq.id;
        r.status = true;
        return r;
    }

    private static testmethod void validate_create_survey(){
        r r = new r();
        
        custom_survey_question__c csq = new custom_survey_question__c();
        list<custom_survey_option__c> csos = new list<custom_survey_option__c>();
        
        r = create_survey(csq, csos);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        // non-exist sesssion
        session__c s = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        delete s;
        csq.session__c = s.id;
        r = create_survey(csq, csos);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
        
        // empty question
        s = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        csq.session__c = s.id;
        r = create_survey(csq, csos);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.pls_enter_question, r.message);
        
        // valid survey in case of selectable survey
        csq.question__c = 'wqoeiurpqowiuer';
        csq.enable_free_form__c = true;
        csq.survey_type__c = 'checkbox';
        csq.sort_order__c = 1;
        csos.add(new custom_survey_option__c(option__c = 'option1 for validate'));
        csos.add(new custom_survey_option__c(option__c = 'option2 for validate'));
        r = create_survey(csq, csos);
        system.assertEquals(true, r.status);
        list<custom_survey_question__c> csqs = [select id from custom_survey_question__c where session__c = :s.id AND question__c = 'wqoeiurpqowiuer'];
        system.assertEquals(1, csqs.size());
        system.assertEquals(3, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // valid survey in case of selectable survey (adding 1 more survey and validate if sort_order is set incrementally)
        csq = new custom_survey_question__c();
        csq.session__c = s.id;
        csq.question__c = 'ifugjjrieijkdkf';
        csq.enable_free_form__c = true;
        csq.survey_type__c = 'checkbox';
        r = create_survey(csq, new list<custom_survey_option__c>());
        system.assertEquals(true, r.status);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id AND question__c = 'ifugjjrieijkdkf'].sort_order__c);
        
        // valid survey in free text
        csq = new custom_survey_question__c();
        csq.session__c = s.id;
        csq.question__c = 'poiuerwoieur';
        csq.survey_type__c = 'free';
        csos = new list<custom_survey_option__c>();
        r = create_survey(csq, csos);
        system.assertEquals(true, r.status);
        csqs = [select id from custom_survey_question__c where session__c = :s.id AND question__c = 'poiuerwoieur'];
        system.assertEquals(1, csqs.size());
        system.assertEquals(1, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
    }
    
    @remoteAction
    public static r edit_survey(custom_survey_question__c csq, list<custom_survey_option__c> csos){
        r r = new r();

        // Check if custom_survey_question__c.session__c is not empty.
        if (csq.session__c == null){
            r.status = false;
            r.message = system.label.session_id_is_not_set;
            return r;
        }
        
        // Check if custom_survey_question__c.id is not empty.
        if (csq.id == null){
            r.status = false;
            r.message = system.label.survey_id_is_not_set;
            return r;   
        }
        
        // Check if custom_survey_question__c.question__c is not empty.
        if (csq.question__c == null || csq.question__c == ''){
            r.status = false;
            r.message = system.label.pls_enter_question;
            return r;   
        }

        // Check if session exists.
        try {
            string session_id_for_test = [select id from session__c where id = :csq.session__c].id;
        } catch (Exception e){
            r.status = false;
            r.message = system.label.specified_session_does_not_exist;
            return r;
        }
        
        // Check if custom_survey_question__c exists.
        custom_survey_question__c existing_csq;
        try {
            existing_csq = [select id, question__c, survey_type__c, enable_free_form__c, session__c from custom_survey_question__c where id = :csq.id AND session__c = :csq.session__c];
        } catch (Exception e){
            r.status = false;
            r.message = system.label.specified_survey_does_not_exist;
            return r;
        }
        
        // Check if enable_free_form should be enabled/disabled.
        string action_for_enable_free_form = 'stay';
        if (existing_csq.enable_free_form__c == false && csq.enable_free_form__c == true){
            action_for_enable_free_form = 'enable';
        } else if (existing_csq.enable_free_form__c == true && csq.enable_free_form__c == false){
            action_for_enable_free_form = 'disable';
        }
        
        // Update custom_survey_question if question__c is updated.
        if (existing_csq.question__c != csq.question__c || existing_csq.survey_type__c != csq.survey_type__c || existing_csq.enable_free_form__c != csq.enable_free_form__c){
            existing_csq.question__c = csq.question__c;
            existing_csq.survey_type__c = csq.survey_type__c;
            existing_csq.enable_free_form__c = csq.enable_free_form__c;
            update existing_csq;
        }
        
        // return if survey is non-selectable since there should be no option
        if (existing_csq.survey_type__c == 'free'){
            r.status = true;
            r.message = existing_csq.id;
            return r;
        }
        
        // Retrieve existing list of custom_survey_option__c
        list<custom_survey_option__c> existing_csos = [select id, option__c, session__c, custom_survey_question__c, enable_free_form__c from custom_survey_option__c where custom_survey_question__c = :existing_csq.id];
        
        // Prepare options to be added.
        list<custom_survey_option__c> csos_to_add = new list<custom_survey_option__c>();
        for (custom_survey_option__c cso_tmp : csos){
            if ((cso_tmp.id == null) && (cso_tmp.option__c != null || cso_tmp.option__c != '')){
                cso_tmp.session__c = existing_csq.session__c;
                cso_tmp.custom_survey_question__c = existing_csq.id;
                csos_to_add.add(cso_tmp);
            }
        }
        
        // add option for free form
        if (action_for_enable_free_form == 'enable'){
            csos_to_add.add(new custom_survey_option__c(
                session__c = existing_csq.session__c,
                custom_survey_question__c = existing_csq.id,
                option__c = system.label.other,
                enable_free_form__c = true
            ));
        }
        
        // add options
        if (csos_to_add.size() > 0){
            insert csos_to_add;
        }
        
        // Prepare options to be updated.
        list<custom_survey_option__c> csos_to_update = new list<custom_survey_option__c>();
        for (custom_survey_option__c cso_tmp : csos){
            if ((cso_tmp.id != null || cso_tmp.id != '') && (cso_tmp.option__c != null || cso_tmp.option__c != '')){
                for (custom_survey_option__c existing_cso : existing_csos){
                    if (existing_cso.id == cso_tmp.id){
                        existing_cso.option__c = cso_tmp.option__c;
                        csos_to_update.add(existing_cso);
                    }
                }
            }
        }
        
        // update options
        if (csos_to_update.size() > 0){
            update csos_to_update;
        }
        
        // Prepare options to be deleted.
        list<custom_survey_option__c> csos_to_delete = new list<custom_survey_option__c>();
        boolean found = false;
        for (custom_survey_option__c cso_tmp : existing_csos){
            for (custom_survey_option__c cso_to_delete : csos){
                if (cso_to_delete.id == cso_tmp.id){
                    found = true;
                    if (cso_to_delete.option__c == null || cso_to_delete.option__c == ''){
                        csos_to_delete.add(cso_tmp);
                    }
                }
            }
            if (found == false && cso_tmp.enable_free_form__c == false){
                csos_to_delete.add(cso_tmp);
            }
            found = false;
        }
        
        // delete options
        delete csos_to_delete;

        // add option for enable free form
        if (action_for_enable_free_form == 'disable'){
            try {
                delete [select id from custom_survey_option__c where session__c = :existing_csq.session__c AND custom_survey_question__c = :existing_csq.id AND enable_free_form__c = true];
            } catch (Exception e){
            }
        }   
        
        r.status = true;
        r.message = existing_csq.id;
        return r;
    }
    
    private static testmethod void validate_edit_survey(){
        r r = new r();

        r = edit_survey(new custom_survey_question__c(), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        session__c s = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        
        r = edit_survey(new custom_survey_question__c(session__c = s.id), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.survey_id_is_not_set, r.message);
        
        list<custom_survey_question__c> csqs = [select id from custom_survey_question__c where session__c = :s.id];
        
        r = edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.pls_enter_question, r.message);
        
        delete s;
        
        r = edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
        
        s = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        
        r = edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_survey_does_not_exist, r.message);
        
        s = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        csqs = [select id from custom_survey_question__c where session__c = :s.id];
        list<custom_survey_option__c> csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        
        // validate updating custom_survey_question__c.question__c
        custom_survey_question__c csq_for_validate_updating_question = new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate');
        r = edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals('question for validate', [select question__c from custom_survey_question__c where id = :csqs[0].id].question__c);

        // validate enabling free form
        csq_for_validate_updating_question.enable_free_form__c = true;
        r = edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals(true, [select enable_free_form__c from custom_survey_question__c where id = :csqs[0].id].enable_free_form__c);
        system.assertEquals(1, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id AND enable_free_form__c = true].size());
        
        // validate disabling free form
        csq_for_validate_updating_question.enable_free_form__c = false;
        r = edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals(false, [select enable_free_form__c from custom_survey_question__c where id = :csqs[0].id].enable_free_form__c);
        system.assertEquals(0, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id AND enable_free_form__c = true].size());
        
        // validate adding custom_survey_option
        integer num_of_csos_before = csos.size();
        integer num_of_csos_after = num_of_csos_before + 1;
        csos.add(new custom_survey_option__c(option__c = 'added option for validate'));
        r = edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate updating custom_survey_option
        csos[0].option__c = 'editted option of validate';
        r = edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals('editted option of validate', [select option__c from custom_survey_option__c where id = :csos[0].id].option__c);
        
        // validate deleting custom_survey_option__c by passing blank custom_survey_option__c.option__c
        csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        num_of_csos_before = csos.size();
        num_of_csos_after = num_of_csos_before - 1;
        csos[0].option__c = '';
        r = edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate deleting custom_survey_option__c by not passing custom_survey_options
        csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        num_of_csos_before = csos.size();
        num_of_csos_after = num_of_csos_before - 1;
        csos.remove(0);
        r = edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate non-multi-choice survey
        custom_survey_question__c csq_free = new custom_survey_question__c(session__c = s.id, question__c = 'opiufoijpoij', enable_free_form__c = false, survey_type__c = 'free');
        insert csq_free;
        csq_free.question__c = 'uiouoewrfoi';
        r = edit_survey(csq_free, new list<custom_survey_option__c>());
        system.assertEquals('uiouoewrfoi', [select question__c from custom_survey_question__c where session__c = :s.id AND survey_type__c = 'free'].question__c);
    }
    
    @remoteAction
    public static r deliver_deck(id session_id){
        r r = new r();
        
        if (session_id == null){
            r.status = false;
            r.message = system.label.session_id_is_not_set;
            return r;
        }
        
        session__c session = get_session(session_id);
        if (session == null){
            r.status = false;
            r.message = system.label.specified_session_does_not_exist;
            return r;
        }
        
        ApexPages.StandardController sc = new ApexPages.StandardController(session);
        session_v2 i_session = new session_v2(sc);

        //Set common address for sender and reply-to.
        string sender_address;
        if (session.mass_mail_sender__c == null || session.mass_mail_sender__c == ''){
            sender_address = session.owner.email;
        } else {
            sender_address = session.mass_mail_sender__c;
        }
                
        //Generarte email list to be used for Bcc:
        List<List<String>> bcc_addresses_list = new List<List<String>>();
        List<String> bcc_addresses = new List<String>();
        if (session.who_can_get_handout__c == '全員' || session.who_can_get_handout__c == 'Anyone'){
            for (Guest__c guest : session.guest__r){
                if (guest.email__c != null && guest.email__c != '' && guest.handout_delivered__c == false){
                    if (bcc_addresses.size() <= 20) {
                        bcc_addresses.add(guest.email__c);
                        guest.handout_delivered__c = true;
                    } else {
                        bcc_addresses_list.add(bcc_addresses.clone());
                        bcc_addresses.clear();
                        bcc_addresses.add(guest.email__c);
                    }
                }
            }
        } else if (session.who_can_get_handout__c == 'アンケートの入力が必要' || session.who_can_get_handout__c == 'Require Survey Submission'){
            List<id> guest_ids_submitted_survey = new List<id>();
            for (Survey__c survey : session.survey__r){
                guest_ids_submitted_survey.add(survey.guest__c);
            }
            if (guest_ids_submitted_survey.size() >= 1){
                List<Guest__c> guests_submitted_survey = [select email__c, handout_delivered__c from guest__c where id in :guest_ids_submitted_survey and email__c != ''];
                for (Guest__c guest : guests_submitted_survey){
                    if (guest.email__c != null && guest.email__c != '' && guest.handout_delivered__c == false){
                        if (bcc_addresses.size() <= 20) {
                            bcc_addresses.add(guest.email__c);
                            guest.handout_delivered__c = true;
                        } else {
                            bcc_addresses_list.add(bcc_addresses.clone());
                            bcc_addresses.clear();
                            bcc_addresses.add(guest.email__c);
                        }
                    }
                }
            }
        } else {
            r.status = false;
            r.message = system.label.session_is_not_configured_correctly;
            return r;
        }
        if (bcc_addresses.size() > 0) {
            bcc_addresses_list.add(bcc_addresses.clone());
            bcc_addresses.clear();
        }
        
        //Retrieve Attachment:
        List<Messaging.emailFileAttachment> efas = new List<Messaging.emailFileAttachment>();
        for (attachment a : session.attachments){
            attachment aa = [select name, contenttype, body from attachment where id = :a.id];
            Messaging.emailFileAttachment efa = new Messaging.emailFileAttachment();
            efa.setBody(aa.body);
            efa.setContentType(aa.contenttype);
            efa.setFileName(aa.name);
            efa.setInline(false);
            efas.add(efa);
        }
                
        List<Messaging.singleEmailMessage> mails = new List<Messaging.singleEmailMessage>();
        for (List<String> bcc_addresses1 : bcc_addresses_list){
            //Reserve resource.
            Messaging.reserveSingleEmailCapacity(bcc_addresses1.size());

            //Initialize Messaging Object.
            Messaging.singleEmailMessage mail = new Messaging.singleEmailMessage();
                
            //Set Bcc:
            mail.setBccAddresses(bcc_addresses1);
                
            //Set Sender:
            mail.setSenderDisplayName(sender_address);
                
            //Set Reply-To:
            mail.setReplyTo(sender_address);
                
            //Set Subject:
            mail.setSubject(system.label.subject_of_deck_delivery_mail + ' : ' + session.name);
                
            //Set Message Body:
            mail.setHtmlBody(i_session.getMailBody());
                
            //Set Attachment:
            if (efas.size() >= 1){
                mail.setFileAttachments(efas);
            }
                
            //Add to list
            mails.add(mail);
        }
                
        //Send
        if (mails.size() >= 1){
            Messaging.SendEmailResult[] sers = Messaging.sendEmail(mails);
            for (Messaging.SendEmailResult ser : sers){
                if (!ser.isSuccess()){
                    r.status = false;
                    Messaging.SendEmailError[] sees = ser.getErrors();
                    for (Messaging.SendEmailError see : sees){
                        r.message += see.getMessage() + ' ';
                    }
                    return r;
                }
            }
        }
        
        // mark guest as delivered
        // count total number of mail
        integer sum_of_mail = 0;
        for (guest__c guest : session.guest__r){
            for (list<string> bcc_addresses_sent : bcc_addresses_list){
                for (string bcc_address_sent : bcc_addresses_sent){
                    if (bcc_address_sent == guest.email__c){
                        guest.handout_delivered__c = true;
                        sum_of_mail++;
                    }
                }
            }
        }
        update session.guest__r;
        r.status = true;
        r.message = string.valueOf(sum_of_mail);
        return r;
    }
    

    static testmethod void validate_deliver_deck(){
        r r = new r();
        
        session__c session;
        list<guest__c> guests;
        list<survey__c> surveys;
        
        // Condition
        // - session_id => null
        r = deliver_deck(null);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        // Condition
        // - session_id => set(not exist)
        session = validate_session.createDummySession('test session', 'Eメールの入力が必要', 'アンケートの入力が必要');
        delete session;
        r = deliver_deck(session.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
        
        // Condition
        // - mass_mail_sender__c => 'test@hoge.com'
        // - who_can_get_handout__c => 'アンケートの入力が必要'
        // - bcc address size <= 20
        //
        session = validate_session.createDummySession('test session', 'Eメールの入力が必要', 'アンケートの入力が必要');
        session.mass_mail_additional_body__c = 'additional text for validate';
        session.handout_password__c = 'pwoeiurqwer';
        update session;
        r = deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('5', r.message);
        system.assertEquals(5, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());
        
        
        // Condition
        // - mass_mail_sender__c => ''
        // - who_can_get_handout__c => 'アンケートの入力が必要'
        // - bcc address size <= 20
        //
        session.mass_mail_sender__c = '';
        update session;
        r = deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('0', r.message);
        system.assertEquals(5, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());
        
        // Condition
        // - mass_mail_sender__c => ''
        // - who_can_get_handout__c => 'アンケートの入力が必要'
        // - bcc address size > 20
        //
        guests = new list<guest__c>();
        for (integer num_of_guests = 11; num_of_guests <= 40; num_of_guests++){
            string email = 'hoge' + string.valueOf(num_of_guests) + '@hoge.com';
            string last_name = 'test guest ' + string.valueOf(num_of_guests);
            guests.add(new guest__c(session__c = session.id, last_name__c = last_name, email__c = email));
        }
        insert guests;
        surveys = new list<survey__c>();
        for (guest__c guest : guests){
            surveys.add(new survey__c(session__c = session.id, rate__c = 5, guest__c = guest.id));
        }
        insert surveys;
        r = deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('30', r.message);
        system.assertEquals(35, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());
        
        // Condition
        // - mass_mail_sender__c => 'test@hoge.com'
        // - who_can_get_handout__c => '全員'
        // - bcc address size <= 20
        //
        session = validate_session.createDummySession('test session', 'Eメールの入力が必要', '全員');
        r = deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('6', r.message);
        system.assertEquals(6, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());
        
        // Condition
        // - mass_mail_sender__c => 'test@hoge.com'
        // - who_can_get_handout__c => '全員'
        // - bcc address size > 20
        //
        guests = new list<guest__c>();
        for (integer num_of_guests = 11; num_of_guests <= 40; num_of_guests++){
            string email = 'hoge' + string.valueOf(num_of_guests) + '@hoge.com';
            string last_name = 'test guest ' + string.valueOf(num_of_guests);
            guests.add(new guest__c(session__c = session.id, last_name__c = last_name, email__c = email));
        }
        insert guests;
        r = deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('30', r.message);
        system.assertEquals(36, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());

        // Condition
        // - mass_mail_sender__c => 'test@hoge.com'
        // - who_can_get_handout__c => 'Invalid Setting'
        // - bcc address size <= 20
        //
        session = validate_session.createDummySession('test session', 'Eメールの入力が必要', 'Invalid Setting');
        r = deliver_deck(session.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_is_not_configured_correctly, r.message);
    }
}