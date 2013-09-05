@isTest
public class validate_chatter_notification {
    private static testmethod void validate_notify_checkin_to_record_feed(){
        boolean r;
        session__c s = validate_session.createDummySession('oiwjefoef', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        
        /*
        guest is null
         */
        r = chatter_notification.notify_checkin_to_record_feed(null);
        system.assertEquals(false, r);
        
        /*
        guest is set.
        contact is not linked.
         */
        guest__c g = [select id, name__c, session__c, contact__c from guest__c where session__c = :s.id and first_name__c = 'uruffjjfr'];
        r = chatter_notification.notify_checkin_to_record_feed(g);
        system.assertEquals(true, r);
        list<feedItem> fis = [select id, linkUrl from feedItem where parentId = :s.id];
        boolean found = false;
        for (feedItem fi : fis){
            if (fi.linkUrl == '/' + g.id){
                found = true;
                break;
            }
        }
        system.assertEquals(true, found);
        
        /*
        guest is set.
        contact is linked.
        contact exists.
        Post_To_Account_Record_Feed__c is false
        Post_To_Contact_Record_Feed__c is false
         */
        account a = new account(name = 'lksjdfojwedflj');
        insert a;
        contact c = new contact(lastname = 'oidfklwlfeljflk', accountId = a.id);
        insert c;
        g.contact__c = c.id;
        update c;
        
        r = chatter_notification.notify_checkin_to_record_feed(g);
        system.assertEquals(true, r);
        
        fis = [select id, linkUrl from feedItem where parentId = :a.id];
        found = false;
        for (feedItem fi : fis){
            if (fi.linkUrl == '/' + s.id){
                found = true;
                break;
            }
        }
        system.assertEquals(false, found);
        
        fis = [select id, linkUrl from feedItem where parentId = :c.id];
        found = false;
        for (feedItem fi : fis){
            if (fi.linkUrl == '/' + s.id){
                found = true;
                break;
            }
        }
        system.assertEquals(false, found);
        
        /*
        guest is set.
        contact is linked.
        contact exists.
        Post_To_Account_Record_Feed__c is true
        Post_To_Contact_Record_Feed__c is true
         */
        s.Post_To_Account_Record_Feed__c = true;
        s.Post_To_Contact_Record_Feed__c = true;
        update s;
        
        r = chatter_notification.notify_checkin_to_record_feed(g);
        system.assertEquals(true, r);
        
        fis = [select id, linkUrl from feedItem where parentId = :a.id];
        found = false;
        for (feedItem fi : fis){
            if (fi.linkUrl == '/' + s.id){
                found = true;
                break;
            }
        }
        system.assertEquals(true, found);
        
        fis = [select id, linkUrl from feedItem where parentId = :c.id];
        found = false;
        for (feedItem fi : fis){
            if (fi.linkUrl == '/' + s.id){
                found = true;
                break;
            }
        }
        system.assertEquals(true, found);
        
        /*
        guest is set.
        contact is linked.
        contact does not exists.
         */
        delete c;
        
        r = chatter_notification.notify_checkin_to_record_feed(g);
        system.assertEquals(false, r);
    }
}