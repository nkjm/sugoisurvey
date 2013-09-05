trigger guest_cascade_delete on Guest__c (before delete) {
    for (guest__c g : Trigger.old){
        delete [select id from survey__c where guest__c = :g.id];
        delete [select id from custom_survey_answer__c where guest__c = :g.id];
        delete [select id from comment__c where guest__c = :g.id];
        
        list<feedItem> feedItems = [select id, linkUrl from feedItem where parentId = :g.session__c];
        list<feedItem> feedItems_to_del = new list<feedItem>();
        string linkUrl = '/' + g.id;
        for (feedItem fi : feedItems){
            if (fi.linkUrl == linkUrl){
                feedItems_to_del.add(fi);
            }
        }
        if (feedItems_to_del.size() > 0){
            delete feedItems_to_del;
        }
    }
}