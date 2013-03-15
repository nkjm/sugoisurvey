global class cron_trigger implements Schedulable{
    global integer interval = 1;
    
    global void execute(SchedulableContext SC) {
        // notify guest registration
        chatter_notification.notify_registration_to_record_feed_for_pending_guest();

        // schedule next copy
        Datetime next = Datetime.now().addMinutes(this.interval);
        string sch = string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?';
        id cron_trigger_id = System.schedule('Cron Trigger v1.13 - ' + sch, sch, new cron_trigger());

        // update config
        config__c config = config__c.getOrgDefaults();
        config.cron_trigger_id__c = cron_trigger_id;
        upsert config;
        
        // abort this job
        if (!Test.isRunningTest()){
            System.abortJob(sc.getTriggerId());
        }
    }
    
    private static testmethod void validate_execute(){
        list<session__c> sessions = validate_link_to_contact.create_sessions();
        validate_link_to_contact.create_account_and_contacts();
        guest__c g;
        list<feedItem> feedItems;
        
        config__c config = new config__c(survey_sites_domain__c = 'sugoisurvey4-developer-edition.na11.force.com');
        upsert config;
        
        User u = [select id from User where username = 'sugoisurvey@sugoisurvey4-developer-edition.na11.force.com'];
        System.runAs(u){
            g = new guest__c();
            g.email__c = 'aoeifioj@hoge.com';
            g.session__c = sessions[0].id;
            insert g;
        }
        
        list<guest__c> guests = [select to_be_posted_to_record_feed__c from guest__c where session__c = :sessions[0].id];
        system.assertEquals(1, guests.size());
        system.assertEquals(true, guests[0].to_be_posted_to_record_feed__c);
        
        string sch = '0 0 * * * ?';
        Test.startTest();
        System.schedule('Cron Trigger for Validate', sch, new cron_trigger());
        Test.stopTest();

        guests = [select to_be_posted_to_record_feed__c from guest__c where session__c = :sessions[0].id];
        system.assertEquals(false, guests[0].to_be_posted_to_record_feed__c);
    }
}