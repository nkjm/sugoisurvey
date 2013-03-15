@isTest
public class validate_link_to_contact {
    public static list<session__c> create_sessions(){
        list<session__c> sessions = new list<session__c>();
        session__c s;
        s = new session__c();
        s.name = 'awoeiru';
        s.Post_To_Account_Record_Feed__c = true;
        s.Post_To_Contact_Record_Feed__c = true;
        sessions.add(s.clone());
        
        s = new session__c();
        s.name = 'bweoriu';
        s.Post_To_Account_Record_Feed__c = false;
        s.Post_To_Contact_Record_Feed__c = true;
        sessions.add(s.clone());
        
        s = new session__c();
        s.name = 'coijefe';
        s.Post_To_Account_Record_Feed__c = true;
        s.Post_To_Contact_Record_Feed__c = false;
        sessions.add(s.clone());
        
        s = new session__c();
        s.name = 'dvoijoi';
        s.Post_To_Account_Record_Feed__c = false;
        s.Post_To_Contact_Record_Feed__c = false;
        sessions.add(s.clone());
        
        insert sessions;
        return sessions;
    }
    
    public static void create_account_and_contacts(){
        account a = new account();
        a.name = 'adsoiuf';
        insert a;
        
        list<contact> contacts = new list<contact>();
        contact c;
        c = new contact();
        c.lastname = 'aoeifioj';
        c.firstname = 'aoeifioj';
        c.title = 'aoeifioj';
        c.email = 'aoeifioj@hoge.com';
        c.phone = '090-0000-0000';
        c.accountId = a.id;
        contacts.add(c.clone());
        
        c = new contact();
        c.lastname = 'boeifioj';
        c.email = 'boeifioj@hoge.com';
        c.accountId = a.id;
        contacts.add(c.clone());
        
        c = new contact();
        c.lastname = 'coeifioj';
        c.email = 'boeifioj@hoge.com';
        c.accountId = a.id;
        contacts.add(c.clone());
        
        c = new contact();
        c.lastname = 'doeifioj';
        c.email = 'doeifioj@hoge.com';
        contacts.add(c.clone());
        
        insert contacts;
    }
    
    private static testmethod void validate_notify_registration_to_record_feed(){
        list<session__c> sessions = create_sessions();
        create_account_and_contacts();
        guest__c g;
        list<feedItem> feedItems;
        
        //// Test Case #1
        // create guest
        g = new guest__c();
        g.email__c = 'aoeifioj@hoge.com';
        g.session__c = sessions[0].id;
        insert g;
        // assert
        g = [select id, session__c, session__r.name, contact__c, contact__r.name, contact__r.accountId, last_name__c, first_name__c, title__c, company__c, phone__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :g.id];
        system.assertEquals('aoeifioj', g.last_name__c);
        system.assertEquals('aoeifioj', g.first_name__c);
        system.assertEquals('aoeifioj', g.title__c);
        system.assertEquals('adsoiuf', g.company__c);
        system.assertEquals('090-0000-0000', g.phone__c);
        system.assertEquals(false, g.multiple_contacts__c);
        system.assertEquals(false, g.to_be_posted_to_record_feed__c);
        feeditems = [select linkUrl, title, body from feedItem where parentId = :g.contact__c];
        system.assertEquals(1, feedItems.size());
        system.assertEquals(g.session__r.name, feedItems[0].title);
        system.assertEquals('/' + g.session__c, feedItems[0].linkUrl);
        system.assertEquals(g.contact__r.name + ' ' + system.label.attending_the_event1 + ' ' + g.session__r.name + ' ' + system.label.attending_the_event2, feedItems[0].body);
        feeditems = [select linkUrl, title, body from feedItem where parentId = :g.contact__r.accountId];
        system.assertEquals(1, feedItems.size());
        system.assertEquals(g.session__r.name, feedItems[0].title);
        system.assertEquals('/' + g.session__c, feedItems[0].linkUrl);
        system.assertEquals(g.contact__r.name + ' ' + system.label.attending_the_event1 + ' ' + g.session__r.name + ' ' + system.label.attending_the_event2, feedItems[0].body);
        
        //// Test Case #2
        // create guest
        g = new guest__c();
        g.email__c = 'boeifioj@hoge.com';
        g.session__c = sessions[0].id;
        insert g;
        // assert
        g = [select id, last_name__c, first_name__c, title__c, company__c, phone__c, session__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :g.id];
        system.assertEquals('boeifioj', g.last_name__c);
        system.assertEquals('adsoiuf', g.company__c);
        system.assertEquals(true, g.multiple_contacts__c);
        system.assertEquals(false, g.to_be_posted_to_record_feed__c);
        
        //// Test Case #3
        // create guest
        g = new guest__c();
        g.email__c = 'doeifioj@hoge.com';
        g.session__c = sessions[0].id;
        insert g;
        // assert
        g = [select id, last_name__c, first_name__c, title__c, company__c, phone__c, session__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :g.id];
        system.assertEquals('doeifioj', g.last_name__c);
        system.assertEquals(null, g.company__c);
        system.assertEquals(false, g.multiple_contacts__c);
        system.assertEquals(false, g.to_be_posted_to_record_feed__c);
        
        //// Test Case #4
        // create guest
        g = new guest__c();
        g.last_name__c = system.label.unregistered_guest;
        g.email__c = 'eoeifioj@hoge.com';
        g.session__c = sessions[0].id;
        insert g;
        // assert
        g = [select id, last_name__c, first_name__c, title__c, company__c, phone__c, session__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :g.id];
        system.assertEquals(system.label.unregistered_guest, g.last_name__c);
        system.assertEquals(null, g.company__c);
        system.assertEquals(false, g.multiple_contacts__c);
        system.assertEquals(false, g.to_be_posted_to_record_feed__c);
        
        //// Test Case #5 - Invoke Bulk Trigger
        // delete guest;
        delete [select id from guest__c where session__c = :sessions[0].id];
        // create guest
        list<guest__c> guests;
        guests = new list<guest__c>();
        g = new guest__c();
        g.email__c = 'aoeifioj@hoge.com';
        g.session__c = sessions[0].id;
        guests.add(g.clone());
        g = new guest__c();
        g.email__c = 'boeifioj@hoge.com';
        g.session__c = sessions[0].id;
        guests.add(g.clone());
        insert guests;
        // assert
        g = [select id, last_name__c, first_name__c, title__c, company__c, phone__c, session__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :guests[0].id];
        system.assertEquals('aoeifioj', g.last_name__c);
        g = [select id, last_name__c, first_name__c, title__c, company__c, phone__c, session__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :guests[1].id];
        system.assertEquals('boeifioj', g.last_name__c);
        
        //// Test Case #6 - Disable post to account feed, Enable post to contact feed
        // clear feedItem;
        delete [select id from feedItem];
        // create guest
        g = new guest__c();
        g.email__c = 'aoeifioj@hoge.com';
        g.session__c = sessions[1].id;
        insert g;
        // assert
        g = [select id, session__c, session__r.name, contact__c, contact__r.name, contact__r.accountId, last_name__c, first_name__c, title__c, company__c, phone__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :g.id];
        feeditems = [select linkUrl, title, body from feedItem where parentId = :g.contact__r.accountId];
        system.assertEquals(0, feedItems.size());
        feeditems = [select linkUrl, title, body from feedItem where parentId = :g.contact__c];
        system.assertEquals(1, feedItems.size());
        
        //// Test Case #7 - Enable post to account feed, Disable post to contact feed
        // clear feedItem;
        delete [select id from feedItem];
        // create guest
        g = new guest__c();
        g.email__c = 'aoeifioj@hoge.com';
        g.session__c = sessions[2].id;
        insert g;
        // assert
        g = [select id, session__c, session__r.name, contact__c, contact__r.name, contact__r.accountId, last_name__c, first_name__c, title__c, company__c, phone__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :g.id];
        feeditems = [select linkUrl, title, body from feedItem where parentId = :g.contact__r.accountId];
        system.assertEquals(1, feedItems.size());
        feeditems = [select linkUrl, title, body from feedItem where parentId = :g.contact__c];
        system.assertEquals(0, feedItems.size());
        
        //// Test Case #8 - Disable post to account feed, Disable post to contact feed
        // clear feedItem;
        delete [select id from feedItem];
        // create guest
        g = new guest__c();
        g.email__c = 'aoeifioj@hoge.com';
        g.session__c = sessions[3].id;
        insert g;
        // assert
        g = [select id, session__c, session__r.name, contact__c, contact__r.name, contact__r.accountId, last_name__c, first_name__c, title__c, company__c, phone__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :g.id];
        feeditems = [select linkUrl, title, body from feedItem where parentId = :g.contact__r.accountId];
        system.assertEquals(0, feedItems.size());
        feeditems = [select linkUrl, title, body from feedItem where parentId = :g.contact__c];
        system.assertEquals(0, feedItems.size());
        
        //// Test Case #9 - Create guest based on survey submittion from sites
        config__c config = new config__c(survey_sites_domain__c = 'sugoisurvey4-developer-edition.na11.force.com');
        upsert config;
        delete [select id from guest__c];
        User u = [select id from User where username = 'sugoisurvey@sugoisurvey4-developer-edition.na11.force.com'];
        System.runAs(u){
            g = new guest__c();
            g.email__c = 'aoeifioj@hoge.com';
            g.session__c = sessions[0].id;
            insert g;
            // assert
            g = [select id, session__c, session__r.name, contact__c, contact__r.name, contact__r.accountId, last_name__c, first_name__c, title__c, company__c, phone__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where id = :g.id];
            system.assertEquals('aoeifioj', g.last_name__c);
            system.assertEquals('aoeifioj', g.first_name__c);
            system.assertEquals('aoeifioj', g.title__c);
            system.assertEquals('adsoiuf', g.company__c);
            system.assertEquals('090-0000-0000', g.phone__c);
            system.assertEquals(false, g.multiple_contacts__c);
            system.assertEquals(true, g.to_be_posted_to_record_feed__c);
        }
    }
    
    private static testmethod void validate_notify_registration_to_record_feed_for_pending_guest(){
        list<session__c> sessions = create_sessions();
        create_account_and_contacts();
        guest__c g;
        list<feedItem> feedItems;
        
        //// Test Case #1 - Create guest based on survey submittion from sites
        config__c config = new config__c(survey_sites_domain__c = 'sugoisurvey4-developer-edition.na11.force.com');
        upsert config;
        User u = [select id from User where username = 'sugoisurvey@sugoisurvey4-developer-edition.na11.force.com'];
        System.runAs(u){
            g = new guest__c();
            g.email__c = 'aoeifioj@hoge.com';
            g.session__c = sessions[0].id;
            insert g;
            
            g = new guest__c();
            g.email__c = 'doeifioj@hoge.com';
            g.session__c = sessions[0].id;
            insert g;
        }
        chatter_notification.notify_registration_to_record_feed_for_pending_guest();
        list<guest__c> guests = [select id, session__c, session__r.name, contact__c, contact__r.name, contact__r.accountId, last_name__c, first_name__c, title__c, company__c, phone__c, multiple_contacts__c, to_be_posted_to_record_feed__c from guest__c where session__c = :sessions[0].id];
        system.assertEquals(2, guests.size());
        system.assertEquals(false, guests[0].to_be_posted_to_record_feed__c);
        
        feeditems = [select linkUrl, title, body from feedItem where parentId = :guests[0].contact__c];
        system.assertEquals(1, feedItems.size());
        system.assertEquals(system.label.survey_answer, feedItems[0].title);
        system.assertEquals('/' + guests[0].id, feedItems[0].linkUrl);
        system.assertEquals(guests[0].contact__r.name + ' ' + system.label.attended_the_event_and_submitted_survey1 + ' ' + guests[0].session__r.name + ' ' + system.label.attended_the_event_and_submitted_survey2, feedItems[0].body);
        
    }
}