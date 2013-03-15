public with sharing class chatter_notification {
    public class args_for_guest_registration {
        public id guest_id {get;set;}
        public id session_id {get;set;}
        public string session_name {get;set;}
        public boolean post_to_account_record_feed {get;set;}
        public boolean post_to_contact_record_feed {get;set;}
        public id contact_id {get;set;}
        public string contact_name {get;set;}
        public id account_id {get;set;}
    }
    
    public static boolean notify_registration_to_record_feed_for_pending_guest(){
        list<args_for_guest_registration> args_list = new list<args_for_guest_registration>();
        list<guest__c> guests;
        try {
            guests = [
                select 
                    id,
                    contact__c, 
                    contact__r.name, 
                    contact__r.accountId, 
                    session__c,
                    session__r.name,
                    session__r.post_to_account_record_feed__c,
                    session__r.post_to_contact_record_feed__c
                from guest__c
                where to_be_posted_to_record_feed__c = true
            ];
        } catch (Exception e){
            return false;
        }
        for (guest__c g : guests){
            if(
            String.isEmpty(g.id) ||
            String.isEmpty(g.contact__c) ||
            String.isEmpty(g.contact__r.name) ||
            String.isEmpty(g.session__c) ||
            String.isEmpty(g.session__r.name)){
                continue;
            }
            args_for_guest_registration args = new args_for_guest_registration();
            args.guest_id = g.id;
            args.session_id = g.session__c;
            args.session_name = g.session__r.name;
            args.post_to_account_record_feed = g.session__r.post_to_account_record_feed__c;
            args.post_to_contact_record_feed = g.session__r.post_to_contact_record_feed__c;
            args.contact_id = g.contact__c;
            args.contact_name = g.contact__r.name;
            args.account_id = g.contact__r.accountId;
            args_list.add(args);
            g.to_be_posted_to_record_feed__c = false;
        }
        if (args_list.size() < 1){
            return false;
        }
        boolean r = notify_registration_to_record_feed(args_list, true);
        if (r == false){
            return false;
        }
        update guests;
        return true;
    }
    
    public static boolean notify_registration_to_record_feed(list<args_for_guest_registration> args, boolean submitted_survey){
        list<feedItem> feedItems = new list<feedItem>();
        for (args_for_guest_registration arg : args){
            // post to account record feed
            if (arg.post_to_account_record_feed == true && arg.account_id != null){
                // post to contact record feed
                FeedItem fi = new FeedItem();
                fi.type = 'LinkPost';
                fi.parentId = arg.account_id;
                if (submitted_survey){
                    fi.body = arg.contact_name + ' ' + system.label.attended_the_event_and_submitted_survey1 + ' ' + arg.session_name + ' ' + system.label.attended_the_event_and_submitted_survey2;
                    fi.linkUrl = '/' + arg.guest_id;
                    fi.title = system.label.survey_answer;
                } else {
                    fi.body = arg.contact_name + ' ' + system.label.attending_the_event1 + ' ' + arg.session_name + ' ' + system.label.attending_the_event2;
                    fi.linkUrl = '/' + arg.session_id;
                    fi.title = arg.session_name;
                }
                feedItems.add(fi);
            }
            
            // post to contact record feed
            if (arg.post_to_contact_record_feed == true && arg.contact_id != null){
                FeedItem fi = new FeedItem();
                fi.type = 'LinkPost';
                fi.parentId = arg.contact_id;
                if (submitted_survey){
                    fi.body = arg.contact_name + ' ' + system.label.attended_the_event_and_submitted_survey1 + ' ' + arg.session_name + ' ' + system.label.attended_the_event_and_submitted_survey2;
                    fi.linkUrl = '/' + arg.guest_id;
                    fi.title = system.label.survey_answer;
                } else {
                    fi.body = arg.contact_name + ' ' + system.label.attending_the_event1 + ' ' + arg.session_name + ' ' + system.label.attending_the_event2;
                    fi.linkUrl = '/' + arg.session_id;
                    fi.title = arg.session_name;
                }
                feedItems.add(fi);
            }
        }
        try {
            insert feedItems;
        } catch (Exception e){
            return false;
        }
        return true;
    }
}