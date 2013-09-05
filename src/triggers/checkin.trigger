trigger checkin on Guest__c (after update) {
    for (guest__c g : Trigger.new){
        if (Trigger.oldMap.get(g.id).status__c != 'attended' && g.status__c == 'attended' && g.session__c != null){
            // post checkin status to record feed
            chatter_notification.notify_checkin_to_record_feed(g);
        }
    }
}