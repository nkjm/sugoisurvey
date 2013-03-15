trigger link_to_contact on Guest__c (before insert) {
    list<contact> contacts;
    list<chatter_notification.args_for_guest_registration> args_for_guest_registration_list = new list<chatter_notification.args_for_guest_registration>();
    list<session__c> sessions = [select id, name, post_to_account_record_feed__c, post_to_contact_record_feed__c from session__c];
 
    // Retrieve contact records.   
    if (Trigger.new.size() > 1){
        // This is a bulk trigger.
        // Retrieve all contact records in buld so that we can avoid executing SOQL query inside loop
        contacts = [
            select 
                id, 
                name,
                lastname,
                firstname,
                email,
                phone,
                title,
                accountId, 
                account.Name,
                createdDate
            from contact
            order by createdDate
        ];
    } else if (String.isEmpty(Trigger.new[0].email__c)){
        // This is not a bulk trigger.
        // email__c is not set in guest record and there is no possibility that we can link to the contact so exiting.
        return;
    } else {
        // This is not a bulk trigger.
        // Retrieve one contact record corresponding to the guest record.
        // If there is no corresponding record, we exit.
        try {
            contacts = [
                select 
                    id, 
                    name,
                    lastname,
                    firstname,
                    email,
                    phone,
                    title,
                    accountId, 
                    account.Name,
                    createdDate
                from contact
                where email = :Trigger.new[0].email__c
                order by createdDate
            ];
        } catch (Exception e){
            return;
        }
    }

    config__c config = config__c.getOrgDefaults();
    
    // Set flag meaning if current user is from Sites.
    boolean is_sites_user = false;
    string sites_username = 'sugoisurvey@' + config.survey_sites_domain__c;
    if (Userinfo.getUserName() == sites_username){
        is_sites_user = true;
    }
    
    for (guest__c g : Trigger.new){
    
        // prepare contacts to be linked
        boolean found = false;
        list<contact> contacts_candidate = new list<contact>();
        for (contact c : contacts){
            if (!String.isEmpty(g.email__c) && g.email__c == c.email){
                contacts_candidate.add(c);
            }
        }
        if (contacts_candidate.size() == 0){
            continue;
        } else if (contacts_candidate.size() > 1){
            g.multiple_contacts__c = true;
        }

        // link guest record and contact record. And autofill blank field of guest__c from contact. 
        // In case that multiple candidates exist, oldedst candidate is picked up and is used.
        contact c = contacts_candidate[0];
        // link
        g.contact__c = c.id;
        // autofill
        if ((String.isEmpty(g.last_name__c) || g.last_name__c == system.label.unregistered_guest) && !String.isEmpty(c.lastname)){
            g.last_name__c = c.lastname;
        }
        if (String.isEmpty(g.first_name__c) && !String.isEmpty(c.firstname)){
            g.first_name__c = c.firstname;
        }
        if (String.isEmpty(g.title__c) && !String.isEmpty(c.title)){
            g.title__c = c.title;
        }
        if (String.isEmpty(g.company__c) && c.accountId != null){
            g.company__c = c.account.name;
        }
        if (String.isEmpty(g.phone__c) && !String.isEmpty(c.phone)){
            g.phone__c = c.phone;
        }

        // Set flag for schduled batch to post feeItem to record feed
        if (is_sites_user == true){
            g.to_be_posted_to_record_feed__c = true;
            return;
        }
        
        // Prepare information to execute chatter_notification.notify_registration_to_record_feed
        chatter_notification.args_for_guest_registration args_for_guest_registration = new chatter_notification.args_for_guest_registration();
        args_for_guest_registration.session_id = g.session__c;
        for (session__c s : sessions){
            if (s.id == g.session__c){
                args_for_guest_registration.session_name = s.name;
                args_for_guest_registration.post_to_account_record_feed = s.post_to_account_record_feed__c;
                args_for_guest_registration.post_to_contact_record_feed = s.post_to_contact_record_feed__c;
            }
        }
        args_for_guest_registration.contact_id = c.id;
        args_for_guest_registration.contact_name = c.name;
        args_for_guest_registration.account_id = c.accountId;
        
        args_for_guest_registration_list.add(args_for_guest_registration);
    }
    
    // Create feedItem notifying the contact who has been registered to the event.
    // In case that multiple candidates exist, feedItem is posted to oldest Account/Contact record
    if (is_sites_user == false){
        chatter_notification.notify_registration_to_record_feed(args_for_guest_registration_list, false);
    }
}