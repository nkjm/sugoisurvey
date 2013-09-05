@isTest
public class validate_session {
    public static Session__c createDummySession(String session_name, String who_can_submit_survey, String who_can_get_handout) {
        Session__c session = new Session__c(
            name = session_name,
            date__c = date.valueOf('2012-09-30'),
            who_can_submit_survey__c = who_can_submit_survey,
            who_can_get_handout__c = who_can_get_handout,
            mass_mail_sender__c = 'test@hoge.com',
            handout_url__c = 'http://hoge.com',
            Post_To_Account_Record_Feed__c = false,
            Post_To_Contact_Record_Feed__c = false
        );
        insert session;
        
        //create dummy handout
        Attachment attachment1 = new Attachment(parentid=session.id, name='test attachment1', contenttype='text/plain', body=blob.valueOf('test body1'));
        Attachment attachment2 = new Attachment(parentid=session.id, name='test attachment2', contenttype='text/plain', body=blob.valueOf('test body2'));
        insert attachment1;
        insert attachment2;
        
        //create dummy guest
        guest__c guest1 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest1', email__c='hoge1@hoge.com', first_name__c='uruffjjfr', title__c='rufhbrfjjf', company__c='jfjieerjfkf');
        guest__c guest2 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest2', email__c='hoge2@hoge.com');
        guest__c guest3 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest3', email__c='hoge3@hoge.com');
        guest__c guest4 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest4', email__c='hoge4@hoge.com');
        guest__c guest5 = new guest__c(status__c = 'submitted', session__c=session.id, last_name__c='test guest5', email__c='hoge5@hoge.com');
        guest__c guest6 = new guest__c(session__c=session.id, last_name__c='test guest6', email__c='hoge6@hoge.com');
        insert guest1;
        insert guest2;
        insert guest3;
        insert guest4;
        insert guest5;
        insert guest6;
        
        //create dummy question
        custom_survey_question__c csq1 = new custom_survey_question__c(session__c=session.id, question__c='test question1');
        insert csq1;
        
        //create dummy option
        custom_survey_option__c cso1 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq1.id, option__c='test option1');
        custom_survey_option__c cso2 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq1.id, option__c='test option2');
        insert cso1;
        insert cso2;
        
        //create dummy survey
        survey__c survey1 = new survey__c(session__c=session.id, guest__c=guest1.id, rate__c=1);
        survey__c survey2 = new survey__c(session__c=session.id, guest__c=guest2.id, rate__c=2);
        survey__c survey3 = new survey__c(session__c=session.id, guest__c=guest3.id, rate__c=3);
        survey__c survey4 = new survey__c(session__c=session.id, guest__c=guest4.id, rate__c=4);
        survey__c survey5 = new survey__c(session__c=session.id, guest__c=guest5.id, rate__c=5);
        insert survey1;
        insert survey2;
        insert survey3;
        insert survey4;
        insert survey5;
        
        //create dummy comment
        comment__c comment1 = new comment__c(session__c=session.id, guest__c=guest1.id, comment__c='test comment1');
        comment__c comment2 = new comment__c(session__c=session.id, guest__c=guest2.id, comment__c='test comment2');
        insert comment1;
        insert comment2;
        
        //create dummy tweet
        /*
        tweet__c tweet1 = new tweet__c(session__c=session.id, id__c='00000000', text__c='test text 1');
        tweet__c tweet2 = new tweet__c(session__c=session.id, id__c='00000001', text__c='text text 2');
        insert tweet1;
        insert tweet2;
        */
        
        //create dummy answer
        custom_survey_answer__c csa1 = new custom_survey_answer__c(session__c=session.id, guest__c=guest1.id, custom_survey_option__c=cso1.id);
        custom_survey_answer__c csa2 = new custom_survey_answer__c(session__c=session.id, guest__c=guest1.id, custom_survey_option__c=cso2.id);
        custom_survey_answer__c csa3 = new custom_survey_answer__c(session__c=session.id, guest__c=guest2.id, custom_survey_option__c=cso1.id);
        insert csa1;
        insert csa2;
        insert csa3;
        
        return session;
    }
    
    public static Session__c createDummySessionIncludeRequiredQuestion() {
        Session__c session = new Session__c(
            name = '9ejlflkldsflkjdf'
        );
        insert session;
        
        //create dummy question
        custom_survey_question__c csq1 = new custom_survey_question__c(session__c=session.id, question__c='q1_h9hefljlkjf', survey_type__c = 'checkbox', required__c=false);
        custom_survey_question__c csq2 = new custom_survey_question__c(session__c=session.id, question__c='q2_oiuj0wfjoie', survey_type__c = 'radio', required__c=true);
        custom_survey_question__c csq3 = new custom_survey_question__c(session__c=session.id, question__c='q3_dfjf0wfsdfj', survey_type__c = 'free', required__c=false);
        insert csq1;
        insert csq2;
        insert csq3;
        
        //create dummy option
        custom_survey_option__c cso1 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq1.id, option__c='o1_ldjfojwef');
        custom_survey_option__c cso2 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq1.id, option__c='o2_ljsdkflkj');
        insert cso1;
        insert cso2;
        custom_survey_option__c cso3 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq2.id, option__c='o1_3rfjpofb');
        custom_survey_option__c cso4 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq2.id, option__c='o2_djfhonfk');
        insert cso3;
        insert cso4;
        custom_survey_option__c cso5 = new custom_survey_option__c(session__c=session.id, custom_survey_question__c=csq3.id, option__c='o1_0ifoflkdf', dummy__c = true, enable_free_form__c = true);
        insert cso5;

        return [
        	select 
        		id, name,
        		(select id, name, question__c from custom_survey_question__r),
        		(select id, name, option__c from custom_survey_option__r)
    		from session__c
    		where id = :session.id
		];
    }
    
    static testmethod void validate_getSession(){
    	Session__c session1 = createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
    	ApexPages.StandardController sc1 = new ApexPages.StandardController(session1);
        session_v2 sugoi_session1 = new session_v2(sc1);
        system.assertEquals('test session1', sugoi_session1.getSession().name);
    }
    
    static testmethod void validate_getSessions(){
    	Session__c session1 = createDummySession('test session1', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
    	ApexPages.StandardController sc1 = new ApexPages.StandardController(session1);
        session_v2 sugoi_session1 = new session_v2(sc1);
        system.assertEquals(1, sugoi_session1.getSessions().size());
        system.assertEquals('test session1', sugoi_session1.getSessions()[0].name);
    }
    
    static testmethod void validate_getDeliveryDestinations(){
     	session__c session;
    	ApexPages.StandardController sc;
    	session_v2 i_session;
    	PageReference pr;
    	list<guest__c> guests;
    	
    	session = createDummySession('test session', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        sc = new ApexPages.StandardController(session);
        i_session = new session_v2(sc);
        guests = i_session.getDeliveryDestinations();
        system.assertEquals(5, guests.size());
        
        session = createDummySession('test session', system.label.picklist_require_email, system.label.picklist_anyone);
        sc = new ApexPages.StandardController(session);
        i_session = new session_v2(sc);
        guests = i_session.getDeliveryDestinations();
        system.assertEquals(6, guests.size());
    }
    
    static testmethod void validate_getMailBody(){
    	session__c session;
    	ApexPages.StandardController sc;
    	session_v2 i_session;
    	PageReference pr;
    	
    	session = createDummySession('jfuvdedikfkvmd', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        session.mass_mail_additional_body__c = 'ksldhfoihoedfjosdklf';
        session.handout_url__c = 'https://woieur.woeifjoeiwjfow.com';
        session.handout_password__c = 'kriigjeifnief';
        update session;
        
        sc = new ApexPages.StandardController(session);
        i_session = new session_v2(sc);
        
        string mail_body = i_session.getMailBody();
        system.assertEquals('<p>ksldhfoihoedfjosdklf</p><p>' + system.label.handout_download_url + ' : <a href="https://woieur.woeifjoeiwjfow.com">https://woieur.woeifjoeiwjfow.com</a><br/>' + system.label.password + ' : kriigjeifnief</p>', mail_body);
    }
}