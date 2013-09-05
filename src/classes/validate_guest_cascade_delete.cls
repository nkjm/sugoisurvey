@isTest
private class validate_guest_cascade_delete {
    static testmethod void validate_guest_cascade_delete(){
        session__c session = validate_session.createDummySession('poiqjefpoerfj', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        guest__c g = [select id from guest__c where session__c = :session.id and first_name__c = 'uruffjjfr'];
        jr_session.copy_comment_to_feedItem(session.id);
        list<feedItem> feedItems = [select id, linkUrl from feedItem where parentId = :session.id];
        string linkUrl = '/' + g.id;
        system.assertEquals(1, [select id from survey__c where guest__c = :g.id].size());
        system.assertEquals(2, [select id from custom_survey_answer__c where guest__c = :g.id].size());
        system.assertEquals(1, [select id from comment__c where guest__c = :g.id].size());
        
        list<feedItem> feedItems_to_del = new list<feedItem>();
        for (feedItem fi : feedItems){
            if (fi.linkUrl == linkUrl){
                feedItems_to_del.add(fi);
            }
        }
        system.assertEquals(1, feedItems_to_del.size());
        
        delete g;
        system.assertEquals(0, [select id from survey__c where guest__c = :g.id].size());
        system.assertEquals(0, [select id from custom_survey_answer__c where guest__c = :g.id].size());
        system.assertEquals(0, [select id from comment__c where guest__c = :g.id].size());
        feedItems.clear();
        feedItems = [select id, linkUrl from feedItem where parentId = :session.id];
        feedItems_to_del.clear();
        for (feedItem fi : feedItems){
            if (fi.linkUrl == linkUrl){
                feedItems_to_del.add(fi);
            }
        }
        system.assertEquals(0, feedItems_to_del.size());
    }
}