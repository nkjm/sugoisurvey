public with sharing class jr_session {

    public jr_session(ApexPages.StandardController controller) {
    }

    private class sexception extends exception {}
    
    @remoteAction 
    public static void start_init(string current_url){
        config__c config = config__c.getOrgDefaults();
        
        // Quit if app has been initialized.
        if (config.initialized__c == true && config.need_re_initialization__c == false){
            sexception se = new sexception();
            se.setMessage(system.label.already_initialized);
            throw se;
        }
        
        // Quit if sites has not been activated yet.
        list<site> sites = [select status, subdomain from site where urlPathPrefix = 'sugoisurvey'];
        if (sites.size() == 0 || sites[0].subdomain == null || sites[0].status != 'Active'){
            sexception se = new sexception();
            se.setMessage(system.label.sites_not_activated);
            throw se;
        }
        
        // Identify the Edition of this Org
        string edition = [select OrganizationType from organization].OrganizationType;
        
        // Identify whether this org is production or sandbox
        string hostname = current_url.split('/',0)[2];
        config.sandbox__c = (Pattern.matches('(.*\\.)?cs[0-9]*(-api)?\\..*force.com',hostname));
        
        // Identify if my domain is set
        config.my_domain_enabled__c = hostname.contains('--');
        if (config.my_domain_enabled__c == true){
            config.my_domain__c = hostname.split('--', 0)[0];
        }

        // Set Domain and Survey Site URL
        if (config.sandbox__c == true){
            // Sandbox Org
            config.instance__c = hostname.split('\\.', 0)[1];
            if (config.my_domain_enabled__c == true){
                // My Domain is set
                config.sandbox_name__c = hostname.split('\\.', 0)[0].split('--', 0)[1];
                config.survey_sites_domain__c = sites[0].subdomain + '.' + config.sandbox_name__c + '.' + config.instance__c + '.force.com';
                config.survey_sites_url__c = 'https://' + config.survey_sites_domain__c + '/sugoisurvey/';
                config.sites_username__c = 'sugoisurvey@' + sites[0].subdomain + '.force.com.' + config.sandbox_name__c;
            } else {
                // My Domain is NOT set
                /* Following method to identify sandbox_name is un-reliable. Should be replaced by proper api-call once it's released */
                list<string> divided_username = UserInfo.getUsername().split('\\.',0);
                config.sandbox_name__c = divided_username[divided_username.size() - 1];
                config.survey_sites_domain__c = sites[0].subdomain + '.' + config.sandbox_name__c + '.' + config.instance__c + '.force.com';
                config.survey_sites_url__c = 'https://' + config.survey_sites_domain__c + '/sugoisurvey/';
                config.sites_username__c = 'sugoisurvey@' + config.survey_sites_domain__c;
            }
        } else if(edition == 'Team Edition' || edition == 'Professional Edition' || edition == 'Enterprise Edition' || edition == 'Unlimited Edition'){
            // Production Org
            config.survey_sites_domain__c = sites[0].subdomain + '.force.com';
            config.survey_sites_url__c = 'https://' + sites[0].subdomain + '.secure.force.com/sugoisurvey/';
            config.sites_username__c = 'sugoisurvey@' + config.survey_sites_domain__c;
        } else {
            // Non-Production Org
            config.instance__c = hostname.split('\\.', 0)[1];
            //config.instance__c = hostname.replace('sugoisurvey4','').replace('visual.force.com','').replace('salesforce.com','').replace('.','').replace(sites[0].subdomain + '--', '');
            config.survey_sites_domain__c = sites[0].subdomain + '.' + config.instance__c + '.force.com';
            config.survey_sites_url__c = 'https://' + config.survey_sites_domain__c + '/sugoisurvey/';
            config.sites_username__c = 'sugoisurvey@' + config.survey_sites_domain__c;
        }
        
        upsert config;
    }
    
    
    @remoteAction 
    public static void assign_permission_set(){
        config__c config = config__c.getOrgDefaults();
        
        // Quit if site has not been activated
        if (config.survey_sites_domain__c == null){
            sexception se = new sexception();
            se.setMessage(system.label.sites_not_activated);
            throw se;
        }
        
        // retreive id of user for sites
        string sites_user_id;
        try {
            sites_user_id = [select id from user where username = :config.sites_username__c].id;
        } catch(Exception e) {
        	try {
        		list<user> site_users = [select id from user where username like 'sugoisurvey@%'];
        		if (site_users.size() == 1){
        			sites_user_id = site_users[0].id;
        		} else {
                    sexception se = new sexception();
                    se.setMessage(system.label.sites_user_not_found);
                    throw se;
        		}
        	} catch (Exception ee){
                sexception se = new sexception();
                se.setMessage(system.label.sites_user_not_found);
                throw se;
        	}
        }
        
        // retrieve id of permission set for sites
        string sites_permission_set_id;
        try {
            sites_permission_set_id = [select id from permissionSet where name = 'Sugoi_Survey_Sites_for_Any_License'].id;
        } catch(Exception e){
            sexception se = new sexception();
            se.setMessage(system.label.sites_permission_set_not_found);
            throw se;
        }
        
        if ([select id from permissionSetAssignment where assigneeId = :sites_user_id and permissionSetId = :sites_permission_set_id].size() == 0){
            permissionSetAssignment psa = new permissionSetAssignment(assigneeId = sites_user_id, permissionSetId = sites_permission_set_id);
            insert psa;
        }
    }
    
    
    @remoteAction 
    public static void finish_init(){
        config__c config = config__c.getOrgDefaults();

        // Quit if app has been initialized.
        if (config.initialized__c == true && config.need_re_initialization__c == false){
            sexception se = new sexception();
            se.setMessage(system.label.already_initialized);
            throw se;
        }
        
        // Start cron job for universal purpose. As of v4 1.13, chatter_notification.notify_guest_registration_for_pending_guest is the only method to invoke.
        Datetime next = Datetime.now().addMinutes(1);
        string sch = string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?';
        id cron_trigger_id;
        if (!Test.isRunningTest()){
            cron_trigger_id = system.schedule('Cron Trigger v1.13 - ' + sch, sch, new cron_trigger());
        }

        // update config
        config.cron_trigger_id__c = cron_trigger_id;
        config.initialized__c = true;
        config.need_re_initialization__c = false;
        upsert config;
    }

	// Deprecated
	/*
    @remoteAction
    public static r close_survey(id session_id){
        r r = new r();
        
        if (session_id == null){
            return null;
        }

        try {
            session__c session = [select id, open__c from session__c where id = :session_id];   
            session.open__c = false;
            scrud.supdate(session);
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
    */
    
    @remoteAction
    public static void copy_comment_to_feedItem(id session_id){
        list<comment__c> comments_to_copy;
        
        // Define fields
        list<string> comment_flds = new list<string>{'Id','sugoisurvey4__Comment__c','sugoisurvey4__Session__c'};
        list<string> guest_flds = new list<string>{'Id','sugoisurvey4__Last_Name__c','sugoisurvey4__First_Name__c','sugoisurvey4__Title__c','sugoisurvey4__Company__c'};
        
        // check FLS
        scrud.requireAccessible('sugoisurvey4__Comment__c', comment_flds);
        scrud.requireAccessible('sugoisurvey4__Guest__c', guest_flds);

        //// Dynamic SOQL
        // fields for comment__c
        string soql_comment_flds = '';
        for (string comment_fld : comment_flds){
            soql_comment_flds += comment_fld + ',';
        }
        soql_comment_flds = soql_comment_flds.removeEnd(',');
        // fields for guest__c
        string soql_guest_flds = '';
        for (string guest_fld : guest_flds){
            soql_guest_flds += 'guest__r.' + guest_fld + ',';
        }
        soql_guest_flds = soql_guest_flds.removeEnd(',');
        string soql_flds = soql_comment_flds + ',' + soql_guest_flds;
        string soql;
        if (session_id == null){
            soql = 'select ' + soql_flds + ' from comment__c where session__r.post_comment_to_session_record_feed__c = true and session__r.open__c = true and copied_to_feedItem__c = false';
        } else {
            soql = 'select ' + soql_flds + ' from comment__c where session__c = :session_id and session__r.post_comment_to_session_record_feed__c = true and copied_to_feedItem__c = false';
        }
        comments_to_copy = Database.query(soql);
        
        for (comment__c c : comments_to_copy){
            create_feedItem_from_comment(c.session__c, c.comment__c, c.guest__r);
            c.copied_to_feedItem__c = true;
        }

        if (comments_to_copy != null && comments_to_copy.size() > 0){
            scrud.supdate(comments_to_copy);
        }
    }
    
    public static void create_feedItem_from_comment(id parent_id, string body, guest__c guest){
        string url = '/' + guest.id;
        string title = '';
        if (guest == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }
        if (guest.company__c != null && guest.company__c != ''){
            title += guest.company__c + ' ';
        }
        if (guest.title__c != null && guest.title__c != ''){
            title += guest.title__c + ' ';
        }
        if ([select languageLocaleKey from user where id = :Userinfo.getUserId()].languageLocaleKey == 'ja'){
            if (guest.last_name__c != null && guest.last_name__c != ''){
                title += guest.last_name__c + ' ';
            }
            if (guest.first_name__c != null && guest.first_name__c != ''){
                title += guest.first_name__c;
            }
        } else {
            if (guest.first_name__c != null && guest.first_name__c != ''){
                title += guest.first_name__c + ' ';
            }
            if (guest.last_name__c != null && guest.last_name__c != ''){
                title += guest.last_name__c;
            }
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
        insert fi;
    }
    
    @remoteAction
    public static void submit_survey(survey__c survey, comment__c comment, list<custom_survey_answer__c> csas, string guest_email){
        list<string> fls_flds;
        
        if (survey.session__c == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;   
        }
        
        session__c session;

        // Define fields which is required for later logic
        list<string> session_flds = new list<string>{'Id','sugoisurvey4__Enable_Rate__c','sugoisurvey4__Label_For_Rate__c','sugoisurvey4__Who_Can_Submit_Survey__c','sugoisurvey4__Mail_Handout_Subject__c','sugoisurvey4__Mail_Handout_To__c','sugoisurvey4__Mail_Handout_Body_L__c','sugoisurvey4__Mail_Handout_Sender__c','sugoisurvey4__Mail_Handout_Send_On_Submission__c'};
        list<string> csq_flds = new list<string>{'Id','sugoisurvey4__Required__c'};

        // check FLS
        scrud.requireAccessible('sugoisurvey4__Session__c', session_flds);
        scrud.requireAccessible('sugoisurvey4__Custom_Survey_Question__c', csq_flds);

        // Dynamic SOQL
        string soql_session_flds = '';
        for (string session_fld : session_flds){
            soql_session_flds += session_fld + ',';
        }
        soql_session_flds = soql_session_flds.removeEnd(',');

        string soql_csq_flds = '(select ';
        for (string csq_fld : csq_flds){
            soql_csq_flds += csq_fld + ',';
        }
        soql_csq_flds = soql_csq_flds.removeEnd(',');
        soql_csq_flds += ' from custom_survey_question__r)';

        string soql_flds = soql_session_flds + ',' + soql_csq_flds;
        id session_id = survey.session__c;
        string soql = 'select ' + soql_flds + ' from session__c where id = :session_id';
        session = Database.query(soql);
        
        // check value of rate 
        if (session.enable_rate__c == true){
            if (survey.rate__c == null || !(1 <= survey.rate__c) || !(survey.rate__c <= 5)){
                string label_for_rate;
                if (session.label_for_rate__c == null){
                    label_for_rate = system.label.xPointScale;
                } else {
                    label_for_rate = session.label_for_rate__c;
                }
                sexception se = new sexception();
                se.setMessage(system.label.pls_enter_required_field + ' ' + label_for_rate);
                throw se;        
            }
        } else {
            survey.rate__c = null;
        }
        
        //// check if the guest fills required questions
        // defince fileds
        csq_flds = new list<string>{'Id','sugoisurvey4__Question__c'};

        // check FLS
        scrud.requireAccessible('sugoisurvey4__Custom_Survey_Question__c', csq_flds);

        // dynamic SOQL
        soql_csq_flds = '';
        for (string csq_fld: csq_flds){
            soql_csq_flds += csq_fld + ',';
        }
        soql_csq_flds = soql_csq_flds.removeEnd(',');
        soql_flds = soql_csq_flds + ',' + '(select id from custom_survey_option__r)';
        soql = 'select ' + soql_flds + ' from custom_survey_question__c where session__c = :session_id and required__c = true order by sort_order__c';

        for (custom_survey_question__c csq : Database.query(soql)){
        	set<string> opt_ids = new set<string>();
        	for (custom_survey_option__c opt : csq.custom_survey_option__r){
        		opt_ids.add(string.valueOf(opt.id));
        	}
    		boolean required_answer_found = false;
    		for (custom_survey_answer__c csa : csas){
    			if (opt_ids.contains(csa.custom_survey_option__c)){
    				required_answer_found = true;
    			}
    		}
    		if (!required_answer_found){
                sexception se = new sexception();
                se.setMessage(system.label.pls_enter_required_field + ' ' + csq.question__c);
                throw se;      
    		}
        }
        
        // - check if user is entitled to submit survey
        // - identify guest by email if user is registered guest
        // - insert guest__c if user is unregistered guest and if condition is not registered only
        guest__c guest;
        if (session.who_can_submit_survey__c == '無条件' || 
            session.who_can_submit_survey__c == 'Anyone'){
            guest = identifyGuest(session.id, guest_email);
            if (guest == null){
                guest = createAnonymousGuest(session.id, guest_email);
            }
        } else if (session.who_can_submit_survey__c == 'Eメールの入力が必要' ||
                   session.who_can_submit_survey__c == 'Require Email'){
            if (guest_email == '' || guest_email == null){
                sexception se = new sexception();
                se.setMessage(system.label.pls_input_email);
                throw se;  
            }
            guest = identifyGuest(session.id, guest_email);
            if (guest == null){
                guest = createAnonymousGuest(session.id, guest_email);
            }
        } else if (session.who_can_submit_survey__c == '事前登録者のみ' || 
                   session.who_can_submit_survey__c == 'Registered Guests Only') {
            if (guest_email == '' || guest_email == null){
                sexception se = new sexception();
                se.setMessage(system.label.pls_input_email);
                throw se;  
            }
            guest = identifyGuest(session.id, guest_email);
            if (guest == null){
                sexception se = new sexception();
                se.setMessage(system.label.email_not_registered);
                throw se;  
            }
        } else {
            sexception se = new sexception();
            se.setMessage(system.label.session_is_not_configured_correctly);
            throw se;
        }
   
        // prevent duplicated submit
        List<Survey__c> existing_surveys = [select id from survey__c where session__c = :session.id and guest__c = :guest.id];
        if (!existing_surveys.isEmpty()){
            sexception se = new sexception();
            se.setMessage(system.label.already_submitted);
            throw se;
        }
        
        // insert survey
        survey.guest__c = guest.id;
        scrud.screate(survey);
        
        // insert comment__c and feedItem
        if (comment.comment__c != null && comment.comment__c != ''){
            // insert comment__c
            scrud.screate(new comment__c(session__c = session.id, guest__c = guest.id, comment__c = comment.comment__c));
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
                csa.free_form__c = csa.free_form__c;
            }
            csas_to_add.add(csa);
        }
        
        // insert custom_survey_asnwers
        if (csas_to_add.size() > 0){
            scrud.screate(csas_to_add);
        }
        
        // update guest status to "submitted"
        guest.status__c = 'submitted';
        scrud.supdate(guest);
        
        // send mail
        if (session.mail_handout_send_on_submission__c == true && !String.isEmpty(guest.email__c) && guest.handout_delivered__c == false){
        	list<guest__c> guests = new list<guest__c>();
        	guests.add(guest);
        	send_mail(session.id, 'handout', session.mail_handout_to__c, session.mail_handout_subject__c, session.mail_handout_body_l__c, session.mail_handout_sender__c, guests);
        }
    }
    
    private static guest__c identifyGuest(id session_id, string guest_email){
        guest__c guest;
        if (String.isEmpty(guest_email)){
            return guest;
        }
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey4__Guest__c');
        string soql = 'select ' + soql_flds + ' from guest__c where session__c = :session_id and email__c = :guest_email';
        try {
            guest = Database.query(soql);
        } catch (Exception e){
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
            scrud.screate(guest);
        } catch (DmlException de){
            if (de.getMessage().contains('INVALID_EMAIL_ADDRESS')){
                sexception se = new sexception();
                se.setMessage(system.label.invalid_email);
                throw se;
            } else {
                throw de;
            }
        }
       
        // reload guest since guest might be updated by link_to_contact trigger
        guest = (guest__c)scrud.sread('sugoisurvey4__Guest__c', guest.id);

        return guest;
    }
    
    @remoteAction
    public static session__c get_session(id session_id){
        session__c session;
        
        if (session_id == null){
            return null;
        }
        
        string soql_session_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey4__Session__c');
        string soql_csq_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey4__Custom_Survey_Question__c') + ' from custom_survey_question__r order by sort_order__c, name)';
        string soql_cso_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey4__Custom_Survey_Option__c') + ' from custom_survey_option__r order by name)';
        string soql_guest_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey4__Guest__c') + ' from guest__r order by name)';
        string soql_presenter_flds = '';
        list<string> presenter_flds = scrud.getAccessibleFields('sugoisurvey4__Presenter__c');
        for (string presenter_fld : presenter_flds){
            soql_presenter_flds += 'presenter__r.' + presenter_fld + ',';
        }
        soql_presenter_flds = soql_presenter_flds.removeEnd(',');

        string soql_flds = soql_session_flds + ',' + soql_csq_flds + ',' + soql_cso_flds + ',' + soql_guest_flds + ',' + soql_presenter_flds;
        string soql = 'select ' + soql_flds + ' from session__c where id = :session_id';
        session = Database.query(soql);

        return session;
    }

    @remoteAction
    public static list<session__c> get_sessions(){
        list<session__c> sessions;
        
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey4__Session__c');
        string soql = 'select ' + soql_flds + ' from session__c order by open__c desc, date__c desc, createdDate desc';
        sessions = Database.query(soql);
        
        return sessions;
    }
    
    @remoteAction
    public static list<session__c> get_open_sessions(){
        list<session__c> sessions = new list<session__c>();
        for (session__c s : get_sessions()){
            if (s.open__c == true){
                sessions.add(s);
            }
        }
        return sessions;
    }

    @remoteAction
    public static void reorder_question(id session_id, list<id> question_ids){
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }
        
        if (question_ids.size() < 2){
            sexception se = new sexception();
            se.setMessage(system.label.there_are_not_enough_number_of_question_to_sort);
            throw se;
        }
        
        // check FLS
        list<string> csq_flds = new list<string>{'Id','sugoisurvey4__Sort_Order__c'};
        scrud.requireAccessible('sugoisurvey4__Custom_Survey_Question__c', csq_flds);

        list<custom_survey_question__c> csqs = [select id, sort_order__c from custom_survey_question__c where session__c = :session_id];

        if (csqs.size() < 2){
            sexception se = new sexception();
            se.setMessage(system.label.there_are_not_enough_number_of_question_to_sort);
            throw se;
        }
        
        if (csqs.size() != question_ids.size()){
            sexception se = new sexception();
            se.setMessage(system.label.requested_number_of_question_is_not_valid);
            throw se;
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
                sexception se = new sexception();
                se.setMessage(system.label.specified_question_not_found);
                throw se;
            }
            sort_order++;
            found = false;
        }
        
        scrud.supdate(csqs);
    }
    
    @remoteAction
    public static id clone_session(id session_id){
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }
        
        // clone session record
        string session_fields = scrud.getCreateableFieldsInCSV('sugoisurvey4__Session__c');
        string csq_fields = '(select ' + scrud.getCreateableFieldsInCSV('sugoisurvey4__Custom_Survey_Question__c') + ' from custom_survey_question__r order by sort_order__c, name)';
        string cso_fields = '(select ' + scrud.getCreateableFieldsInCSV('sugoisurvey4__Custom_Survey_Option__c') + ' from custom_survey_option__r order by name)';

        string soql_fields = session_fields + ',' + csq_fields + ',' + cso_fields + ',' + '(select id, name from attachments)';
        string soql = 'select ' + soql_fields + ' from session__c where id = :session_id';
        session__c old_session = Database.query(soql);
        old_session.date__c = null;

        session__c new_session = old_session.clone(false, true, false, false);
        scrud.screate(new_session);
        
        // retrieve question records and clone
        list<custom_survey_question__c> old_csqs = old_session.custom_survey_question__r;
        list<custom_survey_question__c> new_csqs = old_csqs.deepclone();
        for (custom_survey_question__c new_csq : new_csqs){
            new_csq.session__c = new_session.id;
        }
        scrud.screate(new_csqs);
        
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
        scrud.screate(new_csos);
        
        return new_session.Id;
    }

    @remoteAction
    public static list<custom_survey_answer__c> get_free_answers(id csq_id){
        list<custom_survey_answer__c> free_answers;
        
        if (csq_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }
        
        string survey_type;
        survey_type = [select survey_type__c from custom_survey_question__c where id = :csq_id].survey_type__c;
        
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey4__Custom_Survey_Answer__c');
        string soql;
        if (survey_type == 'checkbox' || survey_type == 'radio'){
        	soql = 'select ' + soql_flds + ' from custom_survey_answer__c where custom_survey_option__r.custom_survey_question__c = :csq_id AND custom_survey_option__r.enable_free_form__c = true AND free_form__c != null order by name desc';
        } else {
        	soql = 'select ' + soql_flds + ' from custom_survey_answer__c where custom_survey_option__r.custom_survey_question__c = :csq_id AND custom_survey_option__r.dummy__c = true AND free_form__c != null order by name desc';
        }
        
        try {
        	free_answers = Database.query(soql);
        } catch (Exception e){
            return null;
        }
        
        if (free_answers.size() == 0){
            return null;
        }
        
        return free_answers;
    }

    @remoteAction
    public static id create_survey(custom_survey_question__c csq, list<custom_survey_option__c> csos){
        // Check if session id is set
        if (csq.session__c == null){
            sexception e = new sexception();
            e.setMessage(system.label.session_id_is_not_set);
            throw e;        
        }

        // Check if session exists
        try {
            string session_id_for_test = [select id from session__c where id = :csq.session__c].id;
        } catch (Exception e){
            sexception se = new sexception();
            se.setMessage(system.label.specified_session_does_not_exist);
            throw se;   
        }
        
        // Check if question is set
        if (csq.question__c == null || csq.question__c == '') {
            sexception se = new sexception();
            se.setMessage(system.label.pls_enter_question);
            throw se;  
        }
        
        if (csq.survey_type__c == 'free'){
            csq.enable_free_form__c = false;
        }
        
        // add sort order if it has been set in existing questions
        list<custom_survey_question__c> existing_csqs;
        integer sort_order;

        // check FLS
        scrud.requireAccessible('sugoisurvey4__Custom_Survey_Question__c', new list<string>{'sugoisurvey4__Sort_Order__c'});

        existing_csqs = [select sort_order__c from custom_survey_question__c where session__c = :csq.session__c and sort_order__c != null order by sort_order__c desc];
        if(existing_csqs.size() > 0){
            csq.sort_order__c = existing_csqs[0].sort_order__c + 1;
        }
        scrud.screate(csq);
        
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
        
        scrud.screate(csos_to_add);
        return csq.id;
    }

    @remoteAction
    public static void edit_survey(custom_survey_question__c csq, list<custom_survey_option__c> csos){
        // Check if custom_survey_question__c.session__c is not empty.
        if (csq.session__c == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }
        
        // Check if custom_survey_question__c.id is not empty.
        if (csq.id == null){
            sexception se = new sexception();
            se.setMessage(system.label.survey_id_is_not_set);
            throw se;
        }
        
        // Check if custom_survey_question__c.question__c is not empty.
        if (csq.question__c == null || csq.question__c == ''){
            sexception se = new sexception();
            se.setMessage(system.label.pls_enter_question);
            throw se;
        }

        // Check if session exists.
        try {
            string session_id_for_test = [select id from session__c where id = :csq.session__c].id;
        } catch (Exception e){
            sexception se = new sexception();
            se.setMessage(system.label.specified_session_does_not_exist);
            throw se;
        }
        
        //// Check if custom_survey_question__c exists.
        custom_survey_question__c existing_csq;
        // define fields
        list<string> csq_flds = new list<string>{'Id','sugoisurvey4__Question__c','sugoisurvey4__Survey_Type__c','sugoisurvey4__Required__c','sugoisurvey4__Enable_Free_Form__c','sugoisurvey4__Session__c'};
        // check FLS
        scrud.requireAccessible('sugoisurvey4__Custom_Survey_Question__c', csq_flds);
        // dynamic SOQL
        string soql_flds = '';
        for (string csq_fld : csq_flds){
            soql_flds += csq_fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        id csq_id = csq.id;
        id session_id = csq.session__c;
        string soql = 'select ' + soql_flds + ' from custom_survey_question__c where id = :csq_id AND session__c = :session_id';
        try {
            existing_csq = Database.query(soql);
        } catch (Exception e){
            sexception se = new sexception();
            se.setMessage(system.label.specified_survey_does_not_exist);
            throw se;
        }
        
        // Check if enable_free_form should be enabled/disabled.
        string action_for_enable_free_form = 'stay';
        if (existing_csq.enable_free_form__c == false && csq.enable_free_form__c == true){
            action_for_enable_free_form = 'enable';
        } else if (existing_csq.enable_free_form__c == true && csq.enable_free_form__c == false){
            action_for_enable_free_form = 'disable';
        }
        
        // Check if survey_type changes between free and others
        string action_for_survey_type = 'stay';
        if (existing_csq.survey_type__c == 'free' && csq.survey_type__c != 'free'){
            action_for_survey_type = 'fromfree';
        } else if (existing_csq.survey_type__c != 'free' && csq.survey_type__c == 'free'){
            action_for_survey_type = 'tofree';
        }
        
        // Update custom_survey_question if question__c is updated.
        if (existing_csq.question__c != csq.question__c || 
        	existing_csq.survey_type__c != csq.survey_type__c || 
        	existing_csq.enable_free_form__c != csq.enable_free_form__c ||
        	existing_csq.required__c != csq.required__c){
            existing_csq.question__c = csq.question__c;
            existing_csq.survey_type__c = csq.survey_type__c;
            if (action_for_survey_type == 'tofree'){
            	existing_csq.enable_free_form__c = false;
            } else {
            	existing_csq.enable_free_form__c = csq.enable_free_form__c;
            }
            existing_csq.required__c = csq.required__c;
            scrud.supdate(existing_csq);
        }
        
        // return if survey is non-selectable since there should be no option
        /*
        if (existing_csq.survey_type__c == 'free'){
            r.status = true;
            r.message = existing_csq.id;
            return r;
        }
        */
        
        //// Retrieve existing list of custom_survey_option__c
        // define fields
        list<string> cso_flds = new list<string>{'Id','sugoisurvey4__Option__c','sugoisurvey4__Custom_Survey_Question__c','sugoisurvey4__Enable_Free_Form__c','sugoisurvey4__Dummy__c','sugoisurvey4__Session__c'};
        // check FLS
        scrud.requireAccessible('sugoisurvey4__Custom_Survey_Option__c', cso_flds);
        // dynamic SOQL
        soql_flds = '';
        for (string cso_fld : cso_flds){
            soql_flds += cso_fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        soql = 'select ' + soql_flds + ' from custom_survey_option__c where custom_survey_question__c = :csq_id';
        list<custom_survey_option__c> existing_csos = Database.query(soql);
        
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
        
        // add dummy option
        if (action_for_survey_type == 'tofree'){
        	csos_to_add.add(new custom_survey_option__c(
                session__c = existing_csq.session__c,
                custom_survey_question__c = existing_csq.id,
                option__c = system.label.dummy,
                enable_free_form__c = false,
                dummy__c = true
            ));
        }
        
        // add options
        if (csos_to_add.size() > 0){
        	scrud.screate(csos_to_add);
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
            scrud.supdate(csos_to_update);
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
            if (found == false && cso_tmp.enable_free_form__c == false && cso_tmp.dummy__c == false){
                csos_to_delete.add(cso_tmp);
            }
            found = false;
        }
        
        // delete options
        scrud.sdelete(csos_to_delete);

        // delete option for enable free form
        if (action_for_enable_free_form == 'disable'){
            try {
                scrud.sdelete([select id from custom_survey_option__c where session__c = :existing_csq.session__c AND custom_survey_question__c = :existing_csq.id AND enable_free_form__c = true]);
            } catch (Exception e){
            }
        }
        
        // delete option
        if (action_for_survey_type == 'tofree'){
        	try {
                scrud.sdelete([select id from custom_survey_option__c where session__c = :existing_csq.session__c AND custom_survey_question__c = :existing_csq.id AND dummy__c != true]);
            } catch (Exception e){
            }
        }
        if (action_for_survey_type == 'fromfree'){
        	try {
                scrud.sdelete([select id from custom_survey_option__c where session__c = :existing_csq.session__c AND custom_survey_question__c = :existing_csq.id AND dummy__c = true]);
            } catch (Exception e){
            }
        }
    }
    
    @remoteAction
    public static integer send_mail(id session_id, string template, string to, string subject, string body, string sender, list<guest__c> guests){
        session__c session;
        
        // Check for session id
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }

        // Define fields
        list<string> session_flds = new list<string>{'Id','Name','Date__c'};

        // Check FLS
        scrud.requireAccessible('sugoisurvey4__Session__c', session_flds);

        // Dynamic SOQL
        string soql_session_flds = '';
        for (string session_fld : session_flds){
            soql_session_flds += session_fld + ',';
        }
        soql_session_flds = soql_session_flds.removeEnd(',');
        string soql_flds = soql_session_flds + ',' + '(select id, name from attachments)';
        string soql = 'select ' + soql_flds + ' from session__c where id = :session_id';
        session = Database.query(soql);
        
        // Check for template value
        if (String.isEmpty(template)){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing + ' : template');
            throw se;
        }
        set<string> templates = new set<string>{'free', 'guest_pass', 'survey_link', 'handout'};
        if (!templates.contains(template)){
            sexception se = new sexception();
            se.setMessage(system.label.invalid_value + ' : ' + template + ' for template');
            throw se;
        }
        
        // Check for to value
        if (String.isEmpty(to)){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing + ' : to');
            throw se;
        }
        set<string> tos = new set<string>{'anyone', 'attendees', 'who_have_submitted_survey'};
        if (!tos.contains(to)){
            sexception se = new sexception();
            se.setMessage(system.label.invalid_value + ' : ' + to + ' for to');
            throw se;
        }

        // retrive guest list to be delivered
        if (guests == null){
        	guests = retrieve_guests_to_be_delivered(session.id, template, to);
        }
        
        // retrieve attachment:
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
           
        // reserve mail resource.
        Messaging.reserveSingleEmailCapacity(guests.size());
        
        List<Messaging.singleEmailMessage> mails = new List<Messaging.singleEmailMessage>();
        for (guest__c g : guests){
        	
            //Initialize Messaging Object.
            Messaging.singleEmailMessage mail = new Messaging.singleEmailMessage();
                
            //Set To:
            list<string> to_addresses = new list<string>();
            to_addresses.add(g.email__c);
            mail.setToAddresses(to_addresses);
                
            //Set Sender:
            mail.setSenderDisplayName(sender);
                
            //Set Reply-To:
            mail.setReplyTo(sender);
            
            //Set Subject:
            subject = String.isEmpty(subject) ? '' : subject;
            mail.setSubject(subject);
            
            //Set Message Body:
            if (template == 'free'){
            	mail.setPlainTextBody(body);
            } else if (template == 'guest_pass'){
            	string g_date = session.date__c == null ? '' : session.date__c.format();
            	string g_name = g.name__c == null ? '' : g.name__c;
            	string g_company = g.company__c == null ? '' : g.company__c;
            	body = '<div style="text-align:center;"><img src="https://chart.googleapis.com/chart?cht=qr&chs=150x150&chl=' + g.id + '"></img></div><div>' + system.label.event + ': ' + session.name + '</div><div>' + system.label.event_date + ': ' + g_date + '</div><div>' + system.label.your_company + ': ' + g_company + '</div><div>' + system.label.your_name + ': ' + g_name + '</div>';
            	mail.setHtmlBody(body);
            } else if (template == 'survey_link'){
            	config__c config = config__c.getOrgDefaults();
            	body = '<p>' + system.label.survey + ' : ' + session.name + '</p><a href="' + config.survey_sites_url__c + '?id=' + session.Id + '">' + config.survey_sites_url__c + '?id=' + session.Id + '</a>';
            	mail.setHtmlBody(body);
            } else if (template == 'handout'){
            	body = String.isEmpty(body) ? '' : body;
            	mail.setPlainTextBody(body);
            }
                
            //Set Attachment:
            if (efas.size() >= 1){
                mail.setFileAttachments(efas);
            }
                
            //Add to list
            mails.add(mail);
        }
                
        if (mails.size() > 0){
        	// send
            Messaging.SendEmailResult[] sers = Messaging.sendEmail(mails);
            for (Messaging.SendEmailResult ser : sers){
                if (!ser.isSuccess()){
                    sexception se = new sexception();
                    Messaging.SendEmailError[] sees = ser.getErrors();
                    for (Messaging.SendEmailError see : sees){
                        se.setMessage(see.getMessage() + ' ');
                    }
                    throw se;
                }
            }
            
	        // mark guest as delivered
	        for (guest__c g : guests){
	        	if (template == 'free'){
	        		g.mail_delivered__c = true;
	        	} else if (template == 'guest_pass'){
	        		g.guest_pass_delivered__c = true;
	        	} else if (template == 'survey_link'){
	        		g.survey_link_delivered__c = true;
	        	} else if (template == 'handout'){
	        		g.handout_delivered__c = true;
	        	}
	        }
	        scrud.supdate(guests);
        }
        
        return mails.size();
    }
    
    @remoteAction
    public static list<guest__c> retrieve_guests_to_be_delivered(id session_id, string template, string to){
    	list<guest__c> guests = new list<guest__c>();
    	
    	if (session_id == null || String.isEmpty(template) || String.isEmpty(to)){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
    	}
    	
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey4__Guest__c');
        string soql = 'select ' + soql_flds + ' from guest__c where session__c = :session_id and email__c <> null and email__c <> \'\'';
        for (guest__c g : Database.query(soql)){
        	if (template == 'free'){
        		if (to == 'anyone'){
        			if (g.mail_delivered__c == false){
        				guests.add(g);
        			}
        		} else if (to == 'attendees'){
        			if (g.mail_delivered__c == false && g.checkin__c == true){
        				guests.add(g);
        			}
        		} else if (to == 'who_have_submitted_survey'){
        			if (g.mail_delivered__c == false && g.status__c == 'submitted'){
        				guests.add(g);
        			}
        		}
        	} else if (template == 'guest_pass'){
        		if (to == 'anyone'){
        			if (g.guest_pass_delivered__c == false){
        				guests.add(g);
        			}
        		} else if (to == 'attendees'){
        			if (g.guest_pass_delivered__c == false && g.checkin__c == true){
        				guests.add(g);
        			}
        		} else if (to == 'who_have_submitted_survey'){
        			if (g.guest_pass_delivered__c == false && g.status__c == 'submitted'){
        				guests.add(g);
        			}
        		}
        	} else if (template == 'survey_link'){
        		if (to == 'anyone'){
        			if (g.survey_link_delivered__c == false){
        				guests.add(g);
        			}
        		} else if (to == 'attendees'){
        			if (g.survey_link_delivered__c == false && g.checkin__c == true){
        				guests.add(g);
        			}
        		} else if (to == 'who_have_submitted_survey'){
        			if (g.survey_link_delivered__c == false && g.status__c == 'submitted'){
        				guests.add(g);
        			}
        		}
        	} else if (template == 'handout'){
    			if (to == 'anyone'){
        			if (g.handout_delivered__c == false){
        				guests.add(g);
        			}
        		} else if (to == 'attendees'){
        			if (g.handout_delivered__c == false && g.checkin__c == true){
        				guests.add(g);
        			}
        		} else if (to == 'who_have_submitted_survey'){
        			if (g.handout_delivered__c == false && g.status__c == 'submitted'){
        				guests.add(g);
        			}
        		}
        	}
        }
        return guests;
    }
    
    @remoteAction 
    public static void clear_delivered_flag(id session_id, string template){
		list<guest__c> guests;
		
        if (session_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.session_id_is_not_set);
            throw se;
        }
        
        // retrieve all guest related to the session
        guests = [select id from guest__c where session__c = :session_id];
        
        if (guests.size() == 0){
        	return;
        }
        
        for (guest__c g : guests){
	        if (template == 'free'){
	        	g.mail_delivered__c = false;
	        } else if (template == 'guest_pass'){
	        	g.guest_pass_delivered__c = false;
	        } else if (template == 'survey_link'){
	        	g.survey_link_delivered__c = false;
	        } else if (template == 'handout'){
	        	g.handout_delivered__c = false;
	        } else {
                sexception se = new sexception();
                se.setMessage(system.label.invalid_value + ' : ' + template + ' for template');
                throw se;
	        }
        }
        scrud.supdate(guests);
    }

    @remoteAction
    public static list<guest__c> get_guests_by_condition(id session_id, string search_by, string search_value){
        list<guest__c> guests;

        if (session_id == null || String.isEmpty(search_by) || String.isEmpty(search_value)){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        if (search_by == 'rate'){
            guests = get_guests_by_rate(session_id, Integer.valueOf(search_value));
        } else if (search_by == 'cso_id') {
            guests = get_guests_by_cso_id(session_id, Id.valueOf(search_value));
        } else if (search_by == 'guest_id') {
            guests = get_guests_by_guest_id(session_id, Id.valueOf(search_value));
        } else {
            sexception se = new sexception();
            se.setMessage('Invalid value for search_by');
            throw se;
        }

        return guests;
    }

    private static list<guest__c> get_guests_by_rate(id session_id, integer rate){
        list<guest__c> guests = new list<guest__c>();

        if (session_id == null || rate == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }
        
        // Check FLS
        list<string> flds = scrud.getAccessibleFields('sugoisurvey4__Guest__c');

        // Dynamic SOQL
        string soql_flds = '';
        for (string fld : flds){
            soql_flds += 'guest__r.' + fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        string soql = 'select ' + soql_flds + ' from survey__c where session__c = :session_id and rate__c = :rate order by guest__r.company__c';
        list<survey__c> surveys = Database.query(soql);
        
        // Generate guests
        for (survey__c survey : surveys){
            guests.add(survey.guest__r);
        }

        return guests;
    }

    private static list<guest__c> get_guests_by_cso_id(id session_id, id cso_id){
        list<guest__c> guests = new list<guest__c>();

        if (session_id == null || cso_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        // Check FLS
        list<string> flds = scrud.getAccessibleFields('sugoisurvey4__Guest__c');

        // Dynamic SOQL
        string soql_flds = '';
        for (string fld : flds){
            soql_flds += 'guest__r.' + fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        string soql = 'select ' + soql_flds + ' from custom_survey_answer__c where session__c = :session_id and custom_survey_option__r.id = :cso_id order by guest__r.company__c';
        list<custom_survey_answer__c> csas = Database.query(soql);
        
        // Generate guests
        for (custom_survey_answer__c csa : csas){
            guests.add(csa.guest__r);
        }

        return guests;
    }

    /*
    private static list<guest__c> get_guests_by_csa_id(id session_id, id csa_id){
        list<guest__c> guests = new list<guest__c>();

        if (session_id == null || csa_id == null){
            sexception e = new sexception();
            e.setMessage(system.label.required_parameter_is_missing);
            throw e;
        }

        // Check FLS
        list<string> flds = scrud.getAccessibleFields('sugoisurvey4__Guest__c');

        // Dynamic SOQL
        string soql_flds = '';
        for (string fld : flds){
            soql_flds += 'guest__r.' + fld + ',';
        }
        soql_flds = soql_flds.removeEnd(',');
        string soql = 'select ' + soql_flds + ' from custom_survey_answer__c where session__c = :session_id and id = :csa_id order by guest__r.company__c';
        list<custom_survey_answer__c> csas = Database.query(soql);

        // Generate guests
        for (custom_survey_answer__c csa : csas){
            guests.add(csa.guest__r);
        }

        return guests;
    }
    */

    private static list<guest__c> get_guests_by_guest_id(id session_id, id guest_id){
        list<guest__c> guests = new list<guest__c>();

        if (session_id == null || guest_id == null){
            sexception se = new sexception();
            se.setMessage(system.label.required_parameter_is_missing);
            throw se;
        }

        // Check FLS
        string soql_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey4__Guest__c');
        string soql = 'select ' + soql_flds + ' from guest__c where session__c = :session_id and id = :guest_id';
        guests = Database.query(soql);

        return guests;
    }
}