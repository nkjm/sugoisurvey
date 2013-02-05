@isTest
private class validate_survey_for_guest {
    static testMethod void validate_getGuest(){
        session__c session = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        guest__c guest = new guest__c(last_name__c = 'Nakajima for validate', session__c = session.id);
        insert guest;
        ApexPages.StandardController sc = new ApexPages.StandardController(guest);
        survey_for_guest sfg = new survey_for_guest(sc);
        
        guest__c g = sfg.getGuest();
        system.assertEquals(session.id, g.session__c);
    }
    
    static testmethod void validate_getCustom_Survey_Questions(){
        session__c session = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        guest__c guest = new guest__c(last_name__c = 'Nakajima for validate', session__c = session.id);
        insert guest;
        ApexPages.StandardController sc = new ApexPages.StandardController(guest);
        survey_for_guest sfg = new survey_for_guest(sc);
        
        list<custom_survey_question__c> csqs = sfg.getCustom_Survey_Questions();
        system.assertEquals(1, csqs.size());
    }
    
    /*
    static testmethod void validate_loadTweet(){
        session__c session = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        guest__c guest = new guest__c(last_name__c = 'Nakajima for validate', session__c = session.id);
        insert guest;
        ApexPages.StandardController sc = new ApexPages.StandardController(guest);
        survey_for_guest sfg = new survey_for_guest(sc);
        
        sfg.loadTweet();
        system.assertEquals(1, 1);
    }
    
    static testMethod void validate_parseAndInsertTweetInJSON() {
        session__c session = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        guest__c guest = new guest__c(last_name__c = 'Nakajima for validate', session__c = session.id);
        insert guest;
        ApexPages.StandardController sc = new ApexPages.StandardController(guest);
        survey_for_guest sfg = new survey_for_guest(sc);
        
        string tweet_json = '[';
        tweet_json += '{"created_at":"Wed Sep 29 07:57:26 +0000 2012","screen_name":"nkjm_sfdc","id":"007742502663495680","profile_image_url":"http://nkjmkzk.net","text":"abc"},';
        tweet_json += '{"created_at":"Wed Sep 30 07:57:26 +0000 2012","screen_name":"nkjm_sfdc","id":"007742502663495681","profile_image_url":"http://nkjmkzk.net","text":"cdf"}';
        tweet_json += ']';
        list<tweet__c> existing_tweets = new list<tweet__c>();
        
        sfg.parseAndInsertTweetInJSON(tweet_json, existing_tweets);
        existing_tweets = [select id__c from tweet__c where session__c = :session.id and guest__c = :guest.id];
        system.assertEquals(1, existing_tweets.size());
        
        sfg.parseAndInsertTweetInJSON(tweet_json, existing_tweets);
        system.assertEquals(1, existing_tweets.size());
    }
    */
    
    static testmethod void validate_createLead(){
        session__c session = validate_session.createDummySession('test session1', 'Eメールの入力が必要', 'アンケートの入力が必要');
        guest__c guest = new guest__c(last_name__c = 'Nakajima for lead', first_name__c = 'Kazuki for lead', title__c = 'ISV Architect', company__c = 'Salesforce.com', email__c = 'knakajima@salesforce.com', phone__c = '0000000000', session__c = session.id);
        insert guest;
        ApexPages.StandardController sc = new ApexPages.StandardController(guest);
        survey_for_guest sfg = new survey_for_guest(sc);
        
        sfg.createLead();
        system.assertEquals('Nakajima for lead', [select lastname from lead where guest__c = :guest.id AND session__c = :session.id].lastname);
        
        guest = new guest__c(last_name__c = 'Nakajima for lead', session__c = session.id);
        insert guest;
        sc = new ApexPages.StandardController(guest);
        sfg = new survey_for_guest(sc);
        sfg.createLead();
        system.assertEquals(system.label.unknown_company, [select company from lead where guest__c = :guest.id AND session__c = :session.id].company);
    }
}