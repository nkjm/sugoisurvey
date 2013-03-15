@isTest
public class validate_jr_session {
    private static testmethod void validate_start_init(){
        jr_session.r r = new jr_session.r();
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
        r = jr_session.start_init('https://sugoisurvey4.na12.visual.force.com');
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.already_initialized, r.message);
        
        /*
        initialized => true
        need re-initialization => true
        */
        config = config__c.getOrgDefaults();
        config.initialized__c = true;
        config.need_re_initialization__c = true;
        upsert config;
        r = jr_session.start_init('https://sugoisurvey4.na12.visual.force.com');
        system.assertEquals(true, r.status);
        

        /* Case #1
        Initialized => false
        Edition => DE
        Sandbox => false
        MyDomain => false
        */
        r = jr_session.start_init('https://sugoisurvey4.na12.visual.force.com/apex/init');
        system.assertEquals(true, r.status);
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
        r = jr_session.start_init('https://sugoisurvey4.cs5.visual.force.com/apex/init');
        system.assertEquals(true, r.status);
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
        r = jr_session.start_init('https://japan-isv--japanisv--sugoisurvey4.cs6.visual.force.com/apex/init');
        system.assertEquals(true, r.status);
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
        jr_session.r r = new jr_session.r();
        config__c config;
        /*
        Negative Case #1
        config.survey_sites_domain__c = null
        */
        r = jr_session.assign_permission_set();
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.sites_not_activated, r.message);
        
        /*
        Negative Case #2
        sites_user not found
        */
        config = config__c.getOrgDefaults();
        config.survey_sites_domain__c = 'sugoisurvey4-developer-edition.na11.force.com';
        upsert config;
        r = jr_session.assign_permission_set();
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.sites_user_not_found, r.message);
        
        /*
        string sites_user_username = 'sugoisurvey@sugoisurvey-developer-edition.na14.force.com';
        id sites_user_id = [select id from user where username = :sites_user_username].id;
        id sites_permission_set_id = [select id from permissionSet where name = 'Sugoi_Survey_Sites_for_Any_License'].id;
        system.assertEquals(1, [select id from permissionSetAssignment where assigneeId = :sites_user_id and permissionSetId = :sites_permission_set_id].size());
        */
    }

    private static testmethod void validate_finish_init(){
        jr_session.r r = new jr_session.r();

        config__c config = config__c.getOrgDefaults();
        config.initialized__c = false;
        upsert config;
        
        /*
        Positive Case #1
        initialized = false
        */
        r = jr_session.finish_init();
        system.assertEquals(true, r.status);
        system.assertEquals(true, config__c.getOrgDefaults().initialized__c);
        
        /*
        Negative Case #1
        initialized = true
        */
        r = jr_session.finish_init();
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.already_initialized, r.message);
    }
    
    private static testmethod void validate_close_survey(){
        jr_session.r r = new jr_session.r();
        session__c session = validate_session.createDummySession('irjffiejdjhjkf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        system.assertEquals(true, [select open__c from session__c where id = :session.id].open__c);
        
        /*
        Positive Case #1
        */
        jr_session.close_survey(session.id);
        system.assertEquals(false, [select open__c from session__c where id = :session.id].open__c);
        system.assertEquals(2, [select id from feedItem where parentId = :session.id].size());
        
        /*
        Negative Case #1
        Session does not exist
        */
        delete session;
        r = jr_session.close_survey(session.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
    }
    
    private static testmethod void validate_copy_comment_to_feedItem(){
        // perform only for batch based copy since manual copy validation is implemented in validate_close_survey()
        jr_session.r r = new jr_session.r();
        session__c s1 = validate_session.createDummySession('irjffiejdjhjkf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        session__c s2 = validate_session.createDummySession('afjrrhjgjjfjfjjf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        session__c s3 = validate_session.createDummySession('brjffisdferdjhjkf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        s3.open__c = false;
        update s3;
        
        r = jr_session.copy_comment_to_feedItem(null);
        system.assertEquals(true, r.status);
        system.assertEquals(2, [select id from feedItem where parentId = :s1.id].size());
        system.assertEquals(2, [select id from feedItem where parentId = :s2.id].size());
        system.assertEquals(0, [select id from feedItem where parentId = :s3.id].size());
    }

    private static testMethod void validate_submit_survey(){
        jr_session.r r = new jr_session.r();
        
        //create dummy session
        List<session__c> session_list = new List<session__c>();
        session_list.add(new Session__c(who_can_submit_survey__c = system.label.picklist_no_condition));
        session_list.add(new Session__c(who_can_submit_survey__c = system.label.picklist_require_email));
        session_list.add(new Session__c(who_can_submit_survey__c = system.label.picklist_registered_guests_only));
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
            r = jr_session.submit_survey(
                new survey__c(),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(false, r.status);
            system.assertEquals(system.label.session_id_is_not_set, r.message);
            
            // null rate
            r = jr_session.submit_survey(
                new survey__c(session__c = session.id),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(false, r.status);
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.xPointScale, r.message);
            
            // invalid rate
            r = jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 101),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(false, r.status);
            system.assertEquals(system.label.pls_enter_required_field + ' ' + system.label.xPointScale, r.message);
            
            //correct submit
            r = jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 5),
                new comment__c(comment__c = 'test comment1'),
                csas_of_guest1, 
                guest1.email__c
            );
            system.assertEquals(true, r.status);
            
            //duplicated submit
            r = jr_session.submit_survey(
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
            r = jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 4),
                new comment__c(comment__c = 'test comment2'),
                csas_of_guest2, 
                'guest2.hoge.com'
            );
            system.assertEquals(false, r.status);
            r = jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 4),
                new comment__c(comment__c = 'test comment2'),
                csas_of_guest2, 
                'guest2@hoge.com'
            );
            
            //create answer of guest3 (Anonymous)
            list<custom_survey_answer__c> csas_of_guest3 = new list<custom_survey_answer__c>();
            csas_of_guest3.add(new custom_survey_answer__c(custom_survey_option__c = custom_survey_option2.id));
            
            r = jr_session.submit_survey(
                new survey__c(session__c = session.id, rate__c = 3),
                new comment__c(comment__c = 'test comment3'),
                csas_of_guest3, 
                ''
            );
            
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
        
        // validate enable_rate__c
        session__c session_rate_disabled = new session__c(name='rirjfnkeik', enable_rate__c=true, who_can_submit_survey__c = system.label.picklist_no_condition);
        insert session_rate_disabled;
        r = jr_session.submit_survey(new survey__c(session__c = session_rate_disabled.id), new comment__c(comment__c = ''), new list<custom_survey_answer__c>(), '');
        system.assertEquals(false, r.status);
        session_rate_disabled.enable_rate__c = false;
        update session_rate_disabled;
        r = jr_session.submit_survey(new survey__c(session__c = session_rate_disabled.id), new comment__c(comment__c = ''), new list<custom_survey_answer__c>(), '');
        system.assertEquals(true, r.status);
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
        system.assertEquals(null, jr_session.get_session(session.id));
    }
    
    private static testmethod void validate_reorder_question(){
        jr_session.r r = new jr_session.r();
        
        session__c s = new session__c(name = 'curnfivdnbnef');
        insert s;
        
        custom_survey_question__c csq = new custom_survey_question__c(session__c = s.id, question__c = '#1');
        insert csq;
        
        list<id> question_ids = new list<id>();
        question_ids.add(csq.id);

        // session id is null       
        r = jr_session.reorder_question(null, question_ids);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);

        // requested # of question < 2
        r = jr_session.reorder_question(s.id, question_ids);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.there_are_not_enough_number_of_question_to_sort, r.message);

        // re-order and sort_order__c in 2 questions are updated
        csq = new custom_survey_question__c(session__c = s.id, question__c = '#2');
        insert csq;
        question_ids.add(csq.id);
        r = jr_session.reorder_question(s.id, question_ids);
        system.assertEquals(true, r.status);
        system.assertEquals(1, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#1'].sort_order__c);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#2'].sort_order__c);

        // reverse the order
        list<id> question_ids_reversed = question_ids.clone();
        question_ids_reversed[0] = question_ids[1];
        question_ids_reversed[1] = question_ids[0];
        r = jr_session.reorder_question(s.id, question_ids_reversed);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#1'].sort_order__c);
        system.assertEquals(1, [select sort_order__c from custom_survey_question__c where session__c = :s.id and question__c = '#2'].sort_order__c);
        
        // # of question in database < 2
        delete csq;
        r = jr_session.reorder_question(s.id, question_ids_reversed);
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
        r = jr_session.reorder_question(s.id, question_ids);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.requested_number_of_question_is_not_valid, r.message);

        // # of requested question > database
        csqs = [select id from custom_survey_question__c where session__c = :s.id];
        question_ids = new list<id>();
        for (custom_survey_question__c csq_ueryyruu : csqs){
            question_ids.add(csq_ueryyruu.id);
        }
        question_ids[0] = s.id;
        r = jr_session.reorder_question(s.id, question_ids);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_question_not_found, r.message);
    }
    
    private static testmethod void validate_clone_session(){
        jr_session.r r = new jr_session.r();
        r = jr_session.clone_session(null);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        session__c s = validate_session.createDummySession('woeiru34oriudf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        r = jr_session.clone_session(s.id);
        system.assertEquals(true, r.status);
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
        system.assertEquals(null, jr_session.get_free_answers(null));

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
        system.assertEquals(null, jr_session.get_free_answers(csq.id));
        
        // for non-selectable survey
        jr_session.r r = new jr_session.r();
        r = jr_session.create_survey(new custom_survey_question__c(session__c = s.id, question__c = 'jfioirgjbiorfv', survey_type__c = 'free'), new list<custom_survey_option__c>());
        id cso_id = [select id from custom_survey_option__c where session__c = :s.id and custom_survey_question__c = :r.message].id;
        insert new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso_id, free_form__c = 'lkjhsdfoewiur');
        insert new custom_survey_answer__c(session__c = s.id, custom_survey_option__c = cso_id, free_form__c = 'iefjvniefjjie');
        system.assertEquals(2, jr_session.get_free_answers(r.message).size());
        system.assertEquals('iefjvniefjjie', jr_session.get_free_answers(r.message)[0].free_form__c);
        system.assertEquals('lkjhsdfoewiur', jr_session.get_free_answers(r.message)[1].free_form__c);  
    }
    
    private static testmethod void validate_add_session(){
        jr_session.r r = new jr_session.r();
        r = jr_session.add_session('');
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.pls_enter_session_name, r.message);
        
        r = jr_session.add_session('session for validate');
        system.assertEquals(true, r.status);
    }
    
    private static testmethod void validate_delete_session(){
        jr_session.r r = new jr_session.r();
        r = jr_session.delete_session(null);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        session__c s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        delete s;
        r = jr_session.delete_session(s.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
        
        s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        r = jr_session.delete_session(s.id);
        system.assertEquals(true, r.status);
    }
    
    private static testmethod void validate_delete_survey(){
        jr_session.r r = new jr_session.r();
        
        r = jr_session.delete_survey(null);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.survey_id_is_not_set, r.message);
        
        r = jr_session.delete_survey('000000000000000000');
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_survey_does_not_exist, r.message);
            
        session__c s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        custom_survey_question__c csq = [select id from custom_survey_question__c where session__c = :s.id];
        
        r = jr_session.delete_survey(csq.id);
        system.assertEquals(true, r.status);
    }
    
    private static testmethod void validate_create_survey(){
        jr_session.r r = new jr_session.r();
        
        custom_survey_question__c csq = new custom_survey_question__c();
        list<custom_survey_option__c> csos = new list<custom_survey_option__c>();
        
        r = jr_session.create_survey(csq, csos);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        // non-exist sesssion
        session__c s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        delete s;
        csq.session__c = s.id;
        r = jr_session.create_survey(csq, csos);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
        
        // empty question
        s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        csq.session__c = s.id;
        r = jr_session.create_survey(csq, csos);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.pls_enter_question, r.message);
        
        // valid survey in case of selectable survey
        csq.question__c = 'wqoeiurpqowiuer';
        csq.enable_free_form__c = true;
        csq.survey_type__c = 'checkbox';
        csq.sort_order__c = 1;
        csos.add(new custom_survey_option__c(option__c = 'option1 for validate'));
        csos.add(new custom_survey_option__c(option__c = 'option2 for validate'));
        r = jr_session.create_survey(csq, csos);
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
        r = jr_session.create_survey(csq, new list<custom_survey_option__c>());
        system.assertEquals(true, r.status);
        system.assertEquals(2, [select sort_order__c from custom_survey_question__c where session__c = :s.id AND question__c = 'ifugjjrieijkdkf'].sort_order__c);
        
        // valid survey in free text
        csq = new custom_survey_question__c();
        csq.session__c = s.id;
        csq.question__c = 'poiuerwoieur';
        csq.survey_type__c = 'free';
        csos = new list<custom_survey_option__c>();
        r = jr_session.create_survey(csq, csos);
        system.assertEquals(true, r.status);
        csqs = [select id from custom_survey_question__c where session__c = :s.id AND question__c = 'poiuerwoieur'];
        system.assertEquals(1, csqs.size());
        system.assertEquals(1, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
    }

    private static testmethod void validate_edit_survey(){
        jr_session.r r = new jr_session.r();

        r = jr_session.edit_survey(new custom_survey_question__c(), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        session__c s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        
        r = jr_session.edit_survey(new custom_survey_question__c(session__c = s.id), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.survey_id_is_not_set, r.message);
        
        list<custom_survey_question__c> csqs = [select id from custom_survey_question__c where session__c = :s.id];
        
        r = jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.pls_enter_question, r.message);
        
        delete s;
        
        r = jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
        
        s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        
        r = jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), new list<custom_survey_option__c>());
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_survey_does_not_exist, r.message);
        
        s = validate_session.createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        csqs = [select id from custom_survey_question__c where session__c = :s.id];
        list<custom_survey_option__c> csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        
        // validate updating custom_survey_question__c.question__c
        custom_survey_question__c csq_for_validate_updating_question = new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate');
        r = jr_session.edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals('question for validate', [select question__c from custom_survey_question__c where id = :csqs[0].id].question__c);

        // validate enabling free form
        csq_for_validate_updating_question.enable_free_form__c = true;
        r = jr_session.edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals(true, [select enable_free_form__c from custom_survey_question__c where id = :csqs[0].id].enable_free_form__c);
        system.assertEquals(1, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id AND enable_free_form__c = true].size());
        
        // validate disabling free form
        csq_for_validate_updating_question.enable_free_form__c = false;
        r = jr_session.edit_survey(csq_for_validate_updating_question, csos);
        system.assertEquals(false, [select enable_free_form__c from custom_survey_question__c where id = :csqs[0].id].enable_free_form__c);
        system.assertEquals(0, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id AND enable_free_form__c = true].size());
        
        // validate adding custom_survey_option
        integer num_of_csos_before = csos.size();
        integer num_of_csos_after = num_of_csos_before + 1;
        csos.add(new custom_survey_option__c(option__c = 'added option for validate'));
        r = jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate updating custom_survey_option
        csos[0].option__c = 'editted option of validate';
        r = jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals('editted option of validate', [select option__c from custom_survey_option__c where id = :csos[0].id].option__c);
        
        // validate deleting custom_survey_option__c by passing blank custom_survey_option__c.option__c
        csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        num_of_csos_before = csos.size();
        num_of_csos_after = num_of_csos_before - 1;
        csos[0].option__c = '';
        r = jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate deleting custom_survey_option__c by not passing custom_survey_options
        csos = [select id, option__c from custom_survey_option__c where custom_survey_question__c = :csqs[0].id];
        num_of_csos_before = csos.size();
        num_of_csos_after = num_of_csos_before - 1;
        csos.remove(0);
        r = jr_session.edit_survey(new custom_survey_question__c(session__c = s.id, id = csqs[0].id, question__c = 'question for validate'), csos);
        system.assertEquals(num_of_csos_after, [select id from custom_survey_option__c where custom_survey_question__c = :csqs[0].id].size());
        
        // validate non-multi-choice survey
        custom_survey_question__c csq_free = new custom_survey_question__c(session__c = s.id, question__c = 'opiufoijpoij', enable_free_form__c = false, survey_type__c = 'free');
        insert csq_free;
        csq_free.question__c = 'uiouoewrfoi';
        r = jr_session.edit_survey(csq_free, new list<custom_survey_option__c>());
        system.assertEquals('uiouoewrfoi', [select question__c from custom_survey_question__c where session__c = :s.id AND survey_type__c = 'free'].question__c);
    }
    
    static testmethod void validate_deliver_deck(){
        jr_session.r r = new jr_session.r();
        
        session__c session;
        list<guest__c> guests;
        list<survey__c> surveys;
        
        // Condition
        // - session_id => null
        r = jr_session.deliver_deck(null);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_id_is_not_set, r.message);
        
        // Condition
        // - session_id => set(not exist)
        session = validate_session.createDummySession('test session', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        delete session;
        r = jr_session.deliver_deck(session.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.specified_session_does_not_exist, r.message);
        
        // Condition
        // - mass_mail_sender__c => 'test@hoge.com'
        // - who_can_get_handout__c => 'Require Survey Submission'
        // - bcc address size <= 20
        //
        session = validate_session.createDummySession('test session', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        session.mass_mail_additional_body__c = 'additional text for validate';
        session.handout_password__c = 'pwoeiurqwer';
        update session;
        r = jr_session.deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('5', r.message);
        system.assertEquals(5, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());
        
        
        // Condition
        // - mass_mail_sender__c => ''
        // - who_can_get_handout__c => 'Require Survey Submission'
        // - bcc address size <= 20
        //
        session.mass_mail_sender__c = '';
        update session;
        r = jr_session.deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('0', r.message);
        system.assertEquals(5, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());
        
        // Condition
        // - mass_mail_sender__c => ''
        // - who_can_get_handout__c => 'Require Survey Submission'
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
        r = jr_session.deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('30', r.message);
        system.assertEquals(35, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());
        
        // Condition
        // - mass_mail_sender__c => 'test@hoge.com'
        // - who_can_get_handout__c => 'Anyone'
        // - bcc address size <= 20
        //
        session = validate_session.createDummySession('test session', system.label.picklist_require_email, system.label.picklist_anyone);
        r = jr_session.deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('6', r.message);
        system.assertEquals(6, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());
        
        // Condition
        // - mass_mail_sender__c => 'test@hoge.com'
        // - who_can_get_handout__c => 'Anyone'
        // - bcc address size > 20
        //
        guests = new list<guest__c>();
        for (integer num_of_guests = 11; num_of_guests <= 40; num_of_guests++){
            string email = 'hoge' + string.valueOf(num_of_guests) + '@hoge.com';
            string last_name = 'test guest ' + string.valueOf(num_of_guests);
            guests.add(new guest__c(session__c = session.id, last_name__c = last_name, email__c = email));
        }
        insert guests;
        r = jr_session.deliver_deck(session.id);
        system.assertEquals(true, r.status);
        system.assertEquals('30', r.message);
        system.assertEquals(36, [select id from guest__c where session__c = :session.id AND handout_delivered__c = true].size());

        // Condition
        // - mass_mail_sender__c => 'test@hoge.com'
        // - who_can_get_handout__c => 'Invalid Setting'
        // - bcc address size <= 20
        //
        session = validate_session.createDummySession('test session', system.label.picklist_require_email, 'Invalid Setting');
        r = jr_session.deliver_deck(session.id);
        system.assertEquals(false, r.status);
        system.assertEquals(system.label.session_is_not_configured_correctly, r.message);
    }
}