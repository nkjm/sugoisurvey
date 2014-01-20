@isTest
public class validate_jr_session {
    private static testmethod void validate_start_init(){
        list<site> sites = [select status, subdomain from site where urlPathPrefix = 'sugoisurvey'];
        string subdomain = sites[0].subdomain;
        config__c config;

        /*
        initialized => true
        need re-initialization => false
        */
        config = config__c.getOrgDefaults();
        config.initialized__c = true;
        config.need_re_initialization__c = false;
        upsert config;
        try {
            jr_session.start_init('https://sugoisurvey4.na12.visual.force.com');
        } catch (Exception e){
            system.assertEquals(system.label.already_initialized, e.getMessage());
        }
        
        /*
        initialized => true
        need re-initialization => true
        */
        config = config__c.getOrgDefaults();
        config.initialized__c = true;
        config.need_re_initialization__c = true;
        upsert config;
        jr_session.start_init('https://sugoisurvey4.na12.visual.force.com');     

        /* Case #1
        Initialized => false
        Edition => DE
        Sandbox => false
        MyDomain => false
        */
        jr_session.start_init('https://sugoisurvey4.na12.visual.force.com/apex/init');
        system.assertEquals(false, config__c.getOrgDefaults().sandbox__c);
        system.assertEquals(null, config__c.getOrgDefaults().sandbox_name__c);
        system.assertEquals(false, config__c.getOrgDefaults().my_domain_enabled__c);
        system.assertEquals(null, config__c.getOrgDefaults().my_domain__c);
        system.assertEquals('na12', config__c.getOrgDefaults().instance__c);
        
        system.assertEquals(subdomain + '.' + config__c.getOrgDefaults().instance__c + '.force.com', config__c.getOrgDefaults().survey_sites_domain__c);
        system.assertEquals('https://' + config__c.getOrgDefaults().survey_sites_domain__c + '/sugoisurvey/', config__c.getOrgDefaults().survey_sites_url__c);
        system.assertEquals('sugoisurvey@' + config__c.getOrgDefaults().survey_sites_domain__c, config__c.getOrgDefaults().sites_username__c);
        
        
        /* Case #2
        Initialized => false
        Edition => DE
        Sandbox => true
        MyDomain => false
        */
        jr_session.start_init('https://sugoisurvey4.cs5.visual.force.com/apex/init');
        system.assertEquals(true, config__c.getOrgDefaults().sandbox__c);
        list<string> divided_username = UserInfo.getUsername().split('\\.',0);
        system.assertEquals(divided_username[divided_username.size() - 1], config__c.getOrgDefaults().sandbox_name__c);
        system.assertEquals(false, config__c.getOrgDefaults().my_domain_enabled__c);
        system.assertEquals(null, config__c.getOrgDefaults().my_domain__c);
        system.assertEquals('cs5', config__c.getOrgDefaults().instance__c);
        
        system.assertEquals(subdomain + '.' + config__c.getOrgDefaults().sandbox_name__c + '.' + config__c.getOrgDefaults().instance__c + '.force.com', config__c.getOrgDefaults().survey_sites_domain__c);
        system.assertEquals('https://' + config__c.getOrgDefaults().survey_sites_domain__c + '/sugoisurvey/', config__c.getOrgDefaults().survey_sites_url__c);
        system.assertEquals('sugoisurvey@' + config__c.getOrgDefaults().survey_sites_domain__c, config__c.getOrgDefaults().sites_username__c);
        
        
        /* Case #3
        Initialized => false
        Edition => DE
        Sandbox => true
        MyDomain => true
        */
        jr_session.start_init('https://japan-isv--japanisv--sugoisurvey4.cs6.visual.force.com/apex/init');
        system.assertEquals(true, config__c.getOrgDefaults().sandbox__c);
        system.assertEquals('japanisv', config__c.getOrgDefaults().sandbox_name__c);
        system.assertEquals(true, config__c.getOrgDefaults().my_domain_enabled__c);
        system.assertEquals('japan-isv', config__c.getOrgDefaults().my_domain__c);
        system.assertEquals('cs6', config__c.getOrgDefaults().instance__c);
        
        system.assertEquals(subdomain + '.' + config__c.getOrgDefaults().sandbox_name__c + '.' + config__c.getOrgDefaults().instance__c + '.force.com', config__c.getOrgDefaults().survey_sites_domain__c);
        system.assertEquals('https://' + config__c.getOrgDefaults().survey_sites_domain__c + '/sugoisurvey/', config__c.getOrgDefaults().survey_sites_url__c);
        system.assertEquals('sugoisurvey@' + subdomain + '.force.com.' + config__c.getOrgDefaults().sandbox_name__c, config__c.getOrgDefaults().sites_username__c);
    }

    private static testmethod void validate_assign_permission_set(){
        config__c config;
        /*
        Negative Case #1
        config.survey_sites_domain__c = null
        */
        try {
            jr_session.assign_permission_set();
        } catch (Exception e){
            system.assertEquals(system.label.sites_not_activated, e.getMessage());
        }
        
        /*
        Negative Case #2
        sites_user not found
        */
        config = config__c.getOrgDefaults();
        config.survey_sites_domain__c = 'sugoisurvey4-developer-edition.na11.force.com';
        upsert config;
        list<user> site_users = [select id, username from user where username like 'sugoisurvey@%'];
        
        try {
            jr_session.assign_permission_set();
        } catch (Exception e){
            system.assertEquals(system.label.sites_user_not_found, e.getMessage());
        }
        
        /*
        string sites_user_username = 'sugoisurvey@sugoisurvey-developer-edition.na14.force.com';
        id sites_user_id = [select id from user where username = :sites_user_username].id;
        id sites_permission_set_id = [select id from permissionSet where name = 'Sugoi_Survey_Sites_for_Any_License'].id;
        system.assertEquals(1, [select id from permissionSetAssignment where assigneeId = :sites_user_id and permissionSetId = :sites_permission_set_id].size());
        */
    }

    private static testmethod void validate_finish_init(){
        config__c config = config__c.getOrgDefaults();
        config.initialized__c = false;
        upsert config;
        
        /*
        Positive Case #1
        initialized = false
        */
        jr_session.finish_init();
        system.assertEquals(true, config__c.getOrgDefaults().initialized__c);
        
        /*
        Negative Case #1
        initialized = true
        */
        try {
            jr_session.finish_init();
        } catch (Exception e){
            system.assertEquals(system.label.already_initialized, e.getMessage());
        }
    }
    
    // Deprecated
    /*
    private static testmethod void validate_close_survey(){
        jr_session.r r = new jr_session.r();
        session__c session1 = validate_session.createDummySession('irjffiejdjhjkf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        session__c session2 = validate_session.createDummySession('au89ujoielfjf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        session1.post_comment_to_session_record_feed__c = true;
        session2.post_comment_to_session_record_feed__c = false;
        update session1;
        update session2;
        system.assertEquals(true, [select open__c from session__c where id = :session1.id].open__c);
        system.assertEquals(true, [select open__c from session__c where id = :session2.id].open__c);
        

        // Positive Case #1
        jr_session.close_survey(session1.id);
        system.assertEquals(false, [select open__c from session__c where id = :session1.id].open__c);
        system.assertEquals(2, [select id from feedItem where parentId = :session1.id].size());
        
        jr_session.close_survey(session2.id);
        system.assertEquals(false, [select open__c from session__c where id = :session2.id].open__c);
        system.assertEquals(0, [select id from feedItem where parentId = :session2.id].size());
        

        // Negative Case #1
        // Session does not exist
        delete session1;
        r = jr_session.close_survey(session1.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
    }
    */
    
    private static testmethod void validate_copy_comment_to_feedItem(){
        // perform only for batch based copy since manual copy validation is implemented in validate_close_survey()
        session__c s1 = validate_session.createDummySession('irjffiejdjhjkf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        session__c s2 = validate_session.createDummySession('afjrrhjgjjfjfjjf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        session__c s3 = validate_session.createDummySession('brjffisdferdjhjkf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        s1.post_comment_to_session_record_feed__c = true;
        s2.post_comment_to_session_record_feed__c = false;
        s3.post_comment_to_session_record_feed__c = true;
        s3.open__c = false;
        update s1;
        update s2;
        update s3;
        
        jr_session.copy_comment_to_feedItem(null);
        system.assertEquals(2, [select id from feedItem where parentId = :s1.id].size());
        system.assertEquals(0, [select id from feedItem where parentId = :s2.id].size());
        system.assertEquals(0, [select id from feedItem where parentId = :s3.id].size());
    }

    private static void submit_survey_in_various_condition(session__c session){
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
        try {
            jr_session.submit_survey(
                new survey__c(),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        // null rate
        try {
            jr_session.submit_survey(
                new survey__c(session__c = session.id),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.xPointScale, e.getMessage());
        }
        
        
        // invalid rate
        try {
            jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 101),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.xPointScale, e.getMessage());
        }
        
        //correct submit
        jr_session.submit_survey(
            new survey__c(session__c = session.id, rate__c = 5),
            new comment__c(comment__c = 'test comment1'),
            csas_of_guest1, 
            guest1.email__c
        );

        
        //duplicated submit
        try {
            jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 5),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
        } catch (Exception e){
            system.assertEquals(system.label.already_submitted, e.getMessage());
        }
        
        //create answer of guest2 (With Email)
        list<custom_survey_answer__c> csas_of_guest2 = new list<custom_survey_answer__c>();
        csas_of_guest2.add(new custom_survey_answer__c(custom_survey_option__c = custom_survey_option1.id));

        // invalid email
        try {
            jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 4),
                new comment__c(comment__c = 'test comment2'),
                csas_of_guest2, 
                'guest2.hoge.com'
            );
        } catch (Exception e){
            if (session.who_can_submit_survey__c != '事前登録者のみ' && session.who_can_submit_survey__c != 'Registered Guests Only') {
                system.assertEquals(system.label.invalid_email, e.getMessage());
            } else {
                system.assertEquals(system.label.email_not_registered, e.getMessage());
            }
        }


        try {
            jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 4),
                new comment__c(comment__c = 'test comment2'),
                csas_of_guest2, 
                'guest2@hoge.com'
            );
        } catch (Exception e){
            if (session.who_can_submit_survey__c == '事前登録者のみ' || session.who_can_submit_survey__c == 'Registered Guests Only'){
                system.assertEquals(system.label.email_not_registered, e.getMessage());
            }
        }
        
        //create answer of guest3 (Anonymous)
        list<custom_survey_answer__c> csas_of_guest3 = new list<custom_survey_answer__c>();
        csas_of_guest3.add(new custom_survey_answer__c(custom_survey_option__c = custom_survey_option2.id));
        try {
            jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 3),
                new comment__c(comment__c = 'test comment3'),
                csas_of_guest3, 
                ''
            );
        } catch (Exception e){
            if (session.who_can_submit_survey__c != '無条件' && session.who_can_submit_survey__c != 'Anyone'){
                system.assertEquals(system.label.pls_input_email, e.getMessage());
            }
        }
        
        //check avg.
        Session__c session_for_validate = [select rate_avg__c from session__c where id = :session.id];
        if (session.Who_Can_Submit_Survey__c == system.label.picklist_no_condition){
            system.assertEquals(4, session_for_validate.rate_avg__c);
            Custom_survey_option__c custom_survey_option_for_validate1 = [select sum__c from custom_survey_option__c where id = :custom_survey_option1.id];
            Custom_survey_option__c custom_survey_option_for_validate2 = [select sum__c from custom_survey_option__c where id = :custom_survey_option2.id];
            system.assertEquals(2, custom_survey_option_for_validate1.sum__c);
            system.assertEquals(2, custom_survey_option_for_validate2.sum__c);
        } else if (session.Who_Can_Submit_Survey__c == system.label.picklist_require_email){
            system.assertEquals(4.5, session_for_validate.rate_avg__c);
            Custom_survey_option__c custom_survey_option_for_validate1 = [select sum__c from custom_survey_option__c where id = :custom_survey_option1.id];
            Custom_survey_option__c custom_survey_option_for_validate2 = [select sum__c from custom_survey_option__c where id = :custom_survey_option2.id];
            system.assertEquals(2, custom_survey_option_for_validate1.sum__c);
            system.assertEquals(1, custom_survey_option_for_validate2.sum__c);
        } else if (session.Who_Can_Submit_Survey__c == system.label.picklist_registered_guests_only){
            system.assertEquals(5, session_for_validate.rate_avg__c);
            Custom_survey_option__c custom_survey_option_for_validate1 = [select sum__c from custom_survey_option__c where id = :custom_survey_option1.id];
            Custom_survey_option__c custom_survey_option_for_validate2 = [select sum__c from custom_survey_option__c where id = :custom_survey_option2.id];
            system.assertEquals(1, custom_survey_option_for_validate1.sum__c);
            system.assertEquals(1, custom_survey_option_for_validate2.sum__c);
        }
    }

    private static testMethod void validate_submit_survey_pre_condition_check(){
        /***
        Test if "Required" works.
        ***/
        session__c s = validate_session.createDummySessionIncludeRequiredQuestion();
        
        // submit without required answer
        try {
            jr_session.submit_survey(
                new survey__c(session__c = s.id, rate__c = 5),
                new comment__c(comment__c = ''),
                new list<custom_survey_answer__c>(), 
                '0ejfijoef@hoge.com'
            );
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' q2_oiuj0wfjoie', e.getMessage());
        }
        
        // submit with required answer
        list<custom_survey_answer__c> csas = new list<custom_survey_answer__c>();
        for (custom_survey_option__c cso : s.custom_survey_option__r){
            if (cso.option__c == 'o1_3rfjpofb'){
                csas.add(new custom_survey_answer__c(custom_survey_option__c = cso.id));
            }
        }
        jr_session.submit_survey(
            new survey__c(session__c = s.id, rate__c = 5),
            new comment__c(comment__c = ''),
            csas,
            '0ejfijoef@hoge.com'
        );

        // validate enable_rate__c
        session__c session_rate_disabled = new session__c(name='rirjfnkeik', enable_rate__c=true, who_can_submit_survey__c = system.label.picklist_no_condition);
        insert session_rate_disabled;
        try {
            jr_session.submit_survey(new survey__c(session__c = session_rate_disabled.id), new comment__c(comment__c = ''), new list<custom_survey_answer__c>(), '');
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.xPointScale, e.getMessage());
        }

        session_rate_disabled.enable_rate__c = false;
        update session_rate_disabled;
        jr_session.submit_survey(new survey__c(session__c = session_rate_disabled.id), new comment__c(comment__c = ''), new list<custom_survey_answer__c>(), '');
    }

    private static testmethod void validate_submit_survey_in_case_for_no_condition(){
        session__c s = new Session__c(who_can_submit_survey__c = system.label.picklist_no_condition);
        insert s;
        submit_survey_in_various_condition(s);
    }

    private static testmethod void validate_submit_survey_in_case_for_require_email(){
        session__c s = new Session__c(who_can_submit_survey__c = system.label.picklist_require_email);
        insert s;
        submit_survey_in_various_condition(s);
    }

    private static testmethod void validate_submit_survey_in_case_for_registered_guests_only(){
        session__c s = new Session__c(who_can_submit_survey__c = system.label.picklist_registered_guests_only);
        insert s;
        submit_survey_in_various_condition(s);
    }
    
    private static testmethod void validate_get_session(){
        session__c session;
        session = validate_session.createDummySession('wpoeiru', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        
        /*
        Condition
        - session_id => null
        - open__c => true
        */
        system.assertEquals(null, jr_session.get_session(null));
        
        /*
        Condition
        - session_id => set(exists)
        - open__c => true
        */
        system.assertEquals('wpoeiru', jr_session.get_session(session.id).name);

        /*
        Condition
        - session_id => set(exists)
        - open__c => false
        */
        session.open__c = false;
        update session;
        system.assertEquals('wpoeiru', jr_session.get_session(session.id).name);
        
        /*
        Condition
        - session_id => set(not exist)
        - open__c => n/a
        */
        delete session;
        try {
            jr_session.get_session(session.id);
        } catch (QueryException qe){
            system.assertEquals('List has no rows for assignment to SObject', qe.getMessage());
        }
    }

    private static testMethod void validate_get_sessions(){
        list<session__c> sessions = jr_session.get_sessions();
        system.assertEquals(0, sessions.size());
        insert new session__c(name = 'lkjsldkjflsdjf');
        system.assertEquals(1, jr_session.get_sessions().size());
    }

    private static testMethod void validate_get_open_sessions(){
        list<session__c> sessions = jr_session.get_open_sessions();
        system.assertEquals(0, sessions.size());
        insert new session__c(name = 'lkjsldkjflsdjf', open__c = true);
        insert new session__c(name = 'jfijerkjfdfkdj', open__c = false);
        system.assertEquals(1, jr_session.get_open_sessions().size());
    }
    
    private static testmethod void validate_reorder_question(){
        session__c s = new session__c(name = 'curnfivdnbnef');
        insert s;
        
        custom_survey_question__c csq = new custom_survey_question__c(session__c = s.id, question__c = '#1');
        insert csq;
        
        list<id> question_ids = new list<id>();
        question_ids.add(csq.id);

        // session id is null       
        try {
            jr_session.reorder_question(null, question_ids);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        // requested # of question < 2
        try {
            jr_session.reorder_question(s.id, question_ids);
        } catch (Exception e){
            system.assertEquals(system.label.there_are_not_enough_number_of_question_to_sort, e.getMessage());
        }
        
        // re-order and sort_order__c in 2 questions are updated
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#2');
        insert csq;
        question_ids.add(csq.id);
        jr_session.reorder_question(s.id, question_ids);
        system.assertEquals(1, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#1'].sort_order__c);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#2'].sort_order__c);

        // reverse the order
        list<id> question_ids_reversed = question_ids.clone();
        question_ids_reversed[0] = question_ids[1];
        question_ids_reversed[1] = question_ids[0];
        jr_session.reorder_question(s.id, question_ids_reversed);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#1'].sort_order__c);
        system.assertEquals(1, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#2'].sort_order__c);
        
        // # of question in database < 2
        delete csq;
        try {
            jr_session.reorder_question(s.id, question_ids_reversed);
        } catch (Exception e){
            system.assertEquals(system.label.there_are_not_enough_number_of_question_to_sort, e.getMessage());
        }

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
        try {
            jr_session.reorder_question(s.id, question_ids);
        } catch (Exception e){
            system.assertEquals(system.label.requested_number_of_question_is_not_valid, e.getMessage());
        }

        // # of requested question > database
        csqs = [select id from custom_survey_question__c where session__c = :s.id];
        question_ids = new list<id>();
        for (custom_survey_question__c csq_ueryyruu : csqs){
            question_ids.add(csq_ueryyruu.id);
        }
        question_ids[0] = s.id;
        try {
            jr_session.reorder_question(s.id, question_ids);
        } catch (Exception e){
            system.assertEquals(system.label.specified_question_not_found, e.getMessage());
        }
    }
    
    private static testmethod void validate_clone_session(){
        try {
            jr_session.clone_session(null);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        session__c s = validate_session.createDummySession('woeiru34oriudf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        jr_session.clone_session(s.id);
        system.assertEquals(2, [select id from session__c where name = 'woeiru34oriudf'].size());
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
        try {
            jr_session.get_free_answers(null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing, e.getMessage());
        }

        /*
        Condition
        - csq_id => set(exists)
        */
        system.assertEquals(1, jr_session.get_free_answers(csq.id).size());
        
        /*
        Condition
        - csq_id => set(not exist)
        */
        delete csq;
        try {
            jr_session.get_free_answers(csq.id);
        } catch (Exception e){
            // NEED TO MODIFY
            system.assertEquals('List has no rows for assignment to SObject', e.getMessage());
        }
        
        // for non-selectable survey
        id csq_id = jr_session.create_survey(new custom_survey_question__c(session__c = s.id, question__c = 'jfioirgjbiorfv', survey_type__c = 'free'), new list<custom_survey_option__c>());
        id cso_id = [select id from custom_survey_option__c where session__c = :s.id and custom_survey_question__c = :csq_id].id;
        insert new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso_id, free_form__c = 'lkjhsdfoewiur');
        insert new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso_id, free_form__c = 'iefjvniefjjie');
        system.assertEquals(2, jr_session.get_free_answers(csq_id).size());
        system.assertEquals('iefjvniefjjie', jr_session.get_free_answers(csq_id)[0].free_form__c);
        system.assertEquals('lkjhsdfoewiur', jr_session.get_free_answers(csq_id)[1].free_form__c);  
    }
    
    private static testmethod void validate_create_survey(){
        custom_survey_question__c csq = new custom_survey_question__c();
        list<custom_survey_option__c> csos = new list<custom_survey_option__c>();
        
        try {
            jr_session.create_survey(csq, csos);
        } catch (Exception e){     
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());       
        }

        // non-exist sesssion
        session__c s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        delete s;
        csq.session__c = s.id;
        try {
            jr_session.create_survey(csq, csos);
        } catch (Exception e){
            system.assertEquals(system.label.specified_session_does_not_exist, e.getMessage());
        }

        // empty question
        s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        csq.session__c = s.id;
        try {
            jr_session.create_survey(csq, csos);
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_question, e.getMessage());
        }
        
        // valid survey in case of selectable survey
        csq.question__c = 'wqoeiurpqowiuer';
        csq.enable_free_form__c = true;
        csq.survey_type__c = 'checkbox';
        csq.sort_order__c = 1;
        csos.add(new custom_survey_option__c(option__c = 'option1 for validate'));
        csos.add(new custom_survey_option__c(option__c = 'option2 for validate'));
        jr_session.create_survey(csq, csos);
        list<custom_survey_question__c> csqs = [select id from custom_survey_question__c where session__c = :s.id AND question__c = 'wqoeiurpqowiuer'];
        system.assertEquals(1, csqs.size());
        system.assertEquals(3, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // valid survey in case of selectable survey (adding 1 more survey and validate if sort_order is set incrementally)
        csq = new custom_survey_question__c();
        csq.session__c = s.id;
        csq.question__c = 'ifugjjrieijkdkf';
        csq.enable_free_form__c = true;
        csq.survey_type__c = 'checkbox';
        jr_session.create_survey(csq, new list<custom_survey_option__c>());
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id AND question__c = 'ifugjjrieijkdkf'].sort_order__c);
        
        // valid survey in free text
        csq = new custom_survey_question__c();
        csq.session__c = s.id;
        csq.question__c = 'poiuerwoieur';
        csq.survey_type__c = 'free';
        csos = new list<custom_survey_option__c>();
        jr_session.create_survey(csq, csos);
        csqs = [select id from custom_survey_question__c where session__c = :s.id AND question__c = 'poiuerwoieur'];
        system.assertEquals(1, csqs.size());
        system.assertEquals(1, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
    }

    private static testmethod void validate_edit_survey(){
        try {
            jr_session.edit_survey(new custom_survey_question__c(), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        
        session__c s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        
        try {
            jr_session.edit_survey(new custom_survey_question__c(session__c = s.id), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.survey_id_is_not_set, e.getMessage());
        }

        list<custom_survey_question__c> csqs = [select id from custom_survey_question__c where session__c = :s.id];
        
        try {
            jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.pls_enter_question, e.getMessage());
        }

        delete s;
        
        try {
            jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.specified_session_does_not_exist, e.getMessage());
        }

        s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        
        try {
            jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), new list<custom_survey_option__c>());
        } catch (Exception e){
            system.assertEquals(system.label.specified_survey_does_not_exist, e.getMessage());
        }
        
        s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        csqs = [select id from custom_survey_question__c where session__c = :s.id];
        list<custom_survey_option__c> csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        
        // validate updating custom_survey_question__c.question__c
        custom_survey_question__c csq_for_validate_updating_question = new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate');
        jr_session.edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals('question for validate', [select question__c from custom_survey_question__c where id = :csqs[0].id].question__c);

        // validate enabling free form
        csq_for_validate_updating_question.enable_free_form__c = true;
        jr_session.edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals(true, [select enable_free_form__c from custom_survey_question__c where id = :csqs[0].id].enable_free_form__c);
        system.assertEquals(1, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id AND enable_free_form__c = true].size());
        
        // validate disabling free form
        csq_for_validate_updating_question.enable_free_form__c = false;
        jr_session.edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals(false, [select enable_free_form__c from custom_survey_question__c where id = :csqs[0].id].enable_free_form__c);
        system.assertEquals(0, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id AND enable_free_form__c = true].size());
        
        // validate adding custom_survey_option
        integer num_of_csos_before = csos.size();
        integer num_of_csos_after = num_of_csos_before + 1;
        csos.add(new custom_survey_option__c(option__c = 'added option for validate'));
        jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate updating custom_survey_option
        csos[0].option__c = 'editted option of validate';
        jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals('editted option of validate', [select option__c from custom_survey_option__c where id = :csos[0].id].option__c);
        
        // validate deleting custom_survey_option__c by passing blank custom_survey_option__c.option__c
        csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        num_of_csos_before = csos.size();
        num_of_csos_after = num_of_csos_before - 1;
        csos[0].option__c = '';
        jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate deleting custom_survey_option__c by not passing custom_survey_options
        csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        num_of_csos_before = csos.size();
        num_of_csos_after = num_of_csos_before - 1;
        csos.remove(0);
        jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate non-multi-choice survey
        custom_survey_question__c csq_free = new custom_survey_question__c(session__c = s.id, question__c = 'opiufoijpoij', enable_free_form__c = false, survey_type__c = 'free');
        insert csq_free;
        csq_free.question__c = 'uiouoewrfoi';
        jr_session.edit_survey(csq_free, new list<custom_survey_option__c>());
        system.assertEquals('uiouoewrfoi', [select question__c from custom_survey_question__c where session__c = :s.id AND survey_type__c = 'free'].question__c);
        
        // validate changing survey type from non-free to free
        custom_survey_question__c csq_tofree = new custom_survey_question__c(session__c = s.id, question__c = 'iehjndfbjjg', enable_free_form__c = true, survey_type__c = 'checkbox');
        list<custom_survey_option__c> csos_tofree = new list<custom_survey_option__c>();
        csos_tofree.add(new custom_survey_option__c(session__c = s.id, option__c = 'lkjsdlfjldfsdf'));
        csos_tofree.add(new custom_survey_option__c(session__c = s.id, option__c = system.label.other));
        id csq_tofree_id = jr_session.create_survey(csq_tofree, csos_tofree);
        
        csq_tofree.survey_type__c = 'free';
        jr_session.edit_survey(csq_tofree, new list<custom_survey_option__c>());
        system.assertEquals('free', [select survey_type__c from custom_survey_question__c where id = :csq_tofree_id].survey_type__c);
        system.assertEquals(false, [select enable_free_form__c from custom_survey_question__c where id = :csq_tofree_id].enable_free_form__c);
        system.assertEquals(1, [select option__c from custom_survey_option__c where custom_survey_question__c = :csq_tofree_id].size());
        system.assertEquals(true, [select dummy__c from custom_survey_option__c where custom_survey_question__c = :csq_tofree_id].dummy__c);
        system.assertEquals(system.label.dummy, [select option__c from custom_survey_option__c where custom_survey_question__c = :csq_tofree_id][0].option__c);
        
        // validate changing survey type from free to non-free
        csq_tofree.survey_type__c = 'checkbox';
        csq_tofree.enable_free_form__c = false;
        csos_tofree = new list<custom_survey_option__c>();
        jr_session.edit_survey(csq_tofree, new list<custom_survey_option__c>());
        system.assertEquals('checkbox', [select survey_type__c from custom_survey_question__c where id = :csq_tofree_id].survey_type__c);
        system.assertEquals(0, [select option__c from custom_survey_option__c where custom_survey_question__c = :csq_tofree_id].size());
    }
    
    static testmethod void validate_clear_delivered_flag(){
        session__c session = new session__c(name = 'iuehdfiwhejr');
        insert session;
        
        guest__c guest = new guest__c(
            session__c = session.id, 
            last_name__c = 'lkelkhrlw',
            mail_delivered__c = true, 
            guest_pass_delivered__c = true, 
            survey_link_delivered__c = true,
            handout_delivered__c = true
        );  
        insert guest;
        
        // Negative Case
        // Session Id is null
        try {
            jr_session.clear_delivered_flag(null, null);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        // Negative Case
        // Invalid template string
        try {
            jr_session.clear_delivered_flag(session.id, 'kljsldfj');
        } catch (Exception e){
            system.assertEquals(system.label.invalid_value + ' : kljsldfj for template', e.getMessage());
        }
        
        // Positive Case
        // Clear Flag for Mail 
        jr_session.clear_delivered_flag(session.id, 'free');
        guest = [select mail_delivered__c, guest_pass_delivered__c, survey_link_delivered__c, handout_delivered__c from guest__c where session__c = :session.id][0];
        system.assertEquals(false, guest.mail_delivered__c);
        system.assertEquals(true, guest.guest_pass_delivered__c);
        system.assertEquals(true, guest.survey_link_delivered__c);
        system.assertEquals(true, guest.handout_delivered__c);
        
        guest.mail_delivered__c = true;
        update guest;
        
        // Positive Case
        // Clear Flag for Guest Pass
        jr_session.clear_delivered_flag(session.id, 'guest_pass');
        guest = [select mail_delivered__c, guest_pass_delivered__c, survey_link_delivered__c, handout_delivered__c from guest__c where session__c = :session.id][0];
        system.assertEquals(true, guest.mail_delivered__c);
        system.assertEquals(false, guest.guest_pass_delivered__c);
        system.assertEquals(true, guest.survey_link_delivered__c);
        system.assertEquals(true, guest.handout_delivered__c);
        
        guest.guest_pass_delivered__c = true;
        update guest;
        
        // Positive Case
        // Clear Flag for Survey Link
        jr_session.clear_delivered_flag(session.id, 'survey_link');
        guest = [select mail_delivered__c, guest_pass_delivered__c, survey_link_delivered__c, handout_delivered__c from guest__c where session__c = :session.id][0];
        system.assertEquals(true, guest.mail_delivered__c);
        system.assertEquals(true, guest.guest_pass_delivered__c);
        system.assertEquals(false, guest.survey_link_delivered__c);
        system.assertEquals(true, guest.handout_delivered__c);
        
        guest.survey_link_delivered__c = true;
        update guest;
        
        // Positive Case
        // Clear Flag for Handout
        jr_session.clear_delivered_flag(session.id, 'handout');
        guest = [select mail_delivered__c, guest_pass_delivered__c, survey_link_delivered__c, handout_delivered__c from guest__c where session__c = :session.id][0];
        system.assertEquals(true, guest.mail_delivered__c);
        system.assertEquals(true, guest.guest_pass_delivered__c);
        system.assertEquals(true, guest.survey_link_delivered__c);
        system.assertEquals(false, guest.handout_delivered__c);
    }
    
    private static testmethod void validate_submit_survey_with_send_mail_on_submittion(){
        list<guest__c> guests;
        
        session__c session = new session__c(name = '7wefuhihdfw', mail_handout_send_on_submission__c = true);
        insert session;
        
        guest__c guest_without_email = new guest__c(
            session__c = session.id,
            last_name__c = 'asefawfafad'
        );
        guest__c guest_with_email = new guest__c(
            session__c = session.id,
            last_name__c = 'bsaoijefdf',
            email__c = 'asefawfafad@hoge.com'
        );
        insert guest_without_email;
        insert guest_with_email;
        
        jr_session.submit_survey(
            new survey__c(session__c = session.id, rate__c = 5),
            new comment__c(comment__c = ''),
            new list<custom_survey_answer__c>(), 
            'asefawfafad@hoge.com'
        );
        guests = [select id from guest__c where session__c = :session.id and handout_delivered__c = true];
        system.assertEquals(1, guests.size());
        system.assertEquals(guest_with_email.id, guests[0].id);
    }
    
    static testmethod void validate_retrieve_guests_to_be_delivered(){
        list<guest__c> guests;
        
        session__c session = new session__c(name = '7rfhihidhf');
        insert session;
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'a@hoge.com', status__c = 'submitted');
 
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'd@hoge.com', status__c = 'registered', mail_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'e@hoge.com', status__c = 'attended', mail_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'f@hoge.com', status__c = 'submitted', mail_delivered__c = true);
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'g@hoge.com', status__c = 'registered', guest_pass_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'h@hoge.com', status__c = 'attended', guest_pass_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'i@hoge.com', status__c = 'submitted', guest_pass_delivered__c = true);
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'j@hoge.com', status__c = 'registered', survey_link_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'k@hoge.com', status__c = 'attended', survey_link_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'l@hoge.com', status__c = 'submitted', survey_link_delivered__c = true);
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'm@hoge.com', status__c = 'registered', handout_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'n@hoge.com', status__c = 'attended', handout_delivered__c = true);
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'o@hoge.com', status__c = 'submitted', handout_delivered__c = true);
        
        insert new guest__c(session__c = session.id, last_name__c = 'a', status__c = 'submitted');
        
        
        // Negative Case
        // Required Field is missing
        try {
            jr_session.retrieve_guests_to_be_delivered(null, null, null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing, e.getMessage());
        }
        
        // Positive Case
        for (string template : new list<string>{'free', 'guest_pass', 'survey_link', 'handout'}){
            guests = jr_session.retrieve_guests_to_be_delivered(session.id, template, 'anyone');
            system.assertEquals(10, guests.size());
            
            guests = jr_session.retrieve_guests_to_be_delivered(session.id, template, 'attendees');
            system.assertEquals(7, guests.size());
            
            guests = jr_session.retrieve_guests_to_be_delivered(session.id, template, 'who_have_submitted_survey');
            system.assertEquals(4, guests.size());
        }
    }
    
    /*
    static testmethod void validate_send_mail(){
        try {
            jr_session.send_mail(null, 'free', 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.session_id_is_not_set, e.getMessage());
        }
        
        
        session__c session = new session__c(name = 'ihqwefadfasdf');
        insert session;
        insert new guest__c(session__c = session.id, last_name__c = 'a', email__c = 'a@hoge.com', status__c = 'submitted');
        
        // Negative Case
        // Empty value for template
        try {
            jr_session.send_mail(session.id, null, 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing + ' : template', e.getMessage());
        }
        
        
        // Negative Case
        // Invalid value for template
        try {
            jr_session.send_mail(session.id, 'hoge', 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.invalid_value + ' : hoge for template', e.getMessage());
        }

        // Negative Case
        // Empty value for to
        try {
            jr_session.send_mail(session.id, 'free', null, 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing + ' : to', e.getMessage());
        }
        
        
        // Negative Case
        // Invalid value for to
        try {
            jr_session.send_mail(session.id, 'free', 'hoge', 'test sub', 'test body', 'test@hoge.com', null);
        } catch (Exception e){
            system.assertEquals(system.label.invalid_value + ' : hoge for to', e.getMessage());
        }
        
        
        // Positive Case
        for (string template : new list<string>{'free', 'guest_pass', 'survey_link', 'handout'}) {
            integer r = jr_session.send_mail(session.id, template, 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
            system.assertEquals(1, r);
            
            // check dedupe
            r = jr_session.send_mail(session.id, template, 'anyone', 'test sub', 'test body', 'test@hoge.com', null);
            system.assertEquals(0, r);
        }
    }
    */

    private static testmethod void validate_get_guests_by_condition(){
        session__c s = validate_session.createDummySession('igjfnfjeidjfd', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        

        // Required Parameter is missing
        try {
            jr_session.get_guests_by_condition(null, null, null);
        } catch (Exception e){
            system.assertEquals(system.label.required_parameter_is_missing, e.getMessage());
        }
        
        // Search By rate
        system.assertEquals(1, jr_session.get_guests_by_condition(s.id, 'rate', '5').size());
        
        // Search By cso_id
        list<custom_survey_option__c> csos = [select id from custom_survey_option__c where session__c = :s.id and option__c = 'test option1'];
        system.assertEquals(2, jr_session.get_guests_by_condition(s.id, 'cso_id', String.valueOf(csos[0].id)).size());
        
        // Search By guest_id
        list<guest__c> guests = [select id from guest__c where session__c = :s.id and email__c = 'hoge1@hoge.com'];
        system.assertEquals(1, jr_session.get_guests_by_condition(s.id, 'guest_id', String.valueOf(guests[0].id)).size());
    }
}