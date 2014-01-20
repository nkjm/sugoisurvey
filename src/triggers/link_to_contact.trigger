trigger link_to_contact on Guest__c (before insert) {
    list<contact> contacts;
    list<chatter_notification.args_for_guest_registration> args_for_guest_registration_list = new list<chatter_notification.args_for_guest_registration>();
    list<session__c> sessions = [select id, name, post_to_account_record_feed__c, post_to_contact_record_feed__c from session__c];

	// Create list of new guest's mail which will be used for query to retrieve corresponding contacts
	list<string> guest_mails = new list<string>();
	for (guest__c g : Trigger.new){
		if (!String.isEmpty(g.email__c)){
			guest_mails.add(g.email__c);
		}
	}
	
	if (guest_mails.size() == 0){
		// email__c is not set in guest record and there is no possibility that we can link to the contact so exiting.
		return;
	}
	
	// Retrieve contact records corresponding to new guests.
    if (!scrud.isAccessible('Contact', new list<string>{'Id','Name','LastName','FirstName','Email','Phone','Title','AccountId','CreatedDate'})){
        return;
    }
    if (!scrud.isAccessible('Account', new list<string>{'Name'})){
        return;
    }
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
            createdDate,
            (select id from guest__r)
        from contact
        where email in :guest_mails
        order by createdDate
	];
	// Create map of contact using email as key so that we can search by email
	map<string, contact> contacts_map = new map<string, contact>();
	for (contact c : contacts){
		if (contacts_map.containsKey(c.email)){
			// Contact has already been added but if this one is choosed by user manually more than once, we follow user's decision.
			if (c.guest__r.size() > 0){
				contacts_map.put(c.email, c);
			}
		} else {
			contacts_map.put(c.email, c);
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
    	contact c;
        // prepare contacts to be linked
        if (contacts_map.containsKey(g.email__c)){
        	c = contacts_map.get(g.email__c);
        } else {
        	continue;
        }

        // link
        g.contact__c = c.id;
        // autofill
        if (!String.isEmpty(c.lastname)){
            g.last_name__c = c.lastname;
        }
        if (!String.isEmpty(c.firstname)){
            g.first_name__c = c.firstname;
        }
        if (!String.isEmpty(c.title)){
            g.title__c = c.title;
        }
        if (c.accountId != null){
            g.company__c = c.account.name;
        }
        if (!String.isEmpty(c.phone)){
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
    // In case that multiple candidates exist, feedItem is posted to Account/Contact record which has been linked to guest more than once
    if (is_sites_user == false){
        chatter_notification.notify_registration_to_record_feed(args_for_guest_registration_list, false);
    }
}