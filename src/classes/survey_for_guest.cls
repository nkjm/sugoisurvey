public with sharing class survey_for_guest {
    public guest__c guest;
    
    /*
    private OAuth oa;
    */
    
    public static string getLanguage_locale_key(){
        return [select languageLocaleKey from user where id = :Userinfo.getUserId()].languageLocaleKey;
    }

    public survey_for_guest(ApexPages.StandardController controller) {
        guest__c guest_tmp = (guest__c)controller.getRecord();
        if (guest_tmp.id == null){
            return;
        }
        this.guest = [
            select 
                id, 
                name__c, 
                last_name__c, 
                first_name__c, 
                title__c, 
                company__c, 
                email__c, 
                phone__c, 
                profile_photo__c, 
                session__c, 
                status__c,
                checkin__c,
                session__r.name, 
                session__r.date__c,
                contact__c
            from guest__c where id = :guest_tmp.id
        ];
        /*
        if (!Test.isRunningTest()){
            oa = OAuth.newInstance('Twitter');
        }
        */
    }
    
    public guest__c getGuest(){
        return this.guest;
    }
    
    public list<custom_survey_question__c> getCustom_Survey_Questions(){
        list<custom_survey_question__c> csqs = [select id, question__c, survey_type__c, enable_free_form__c from custom_survey_question__c where session__c = :this.guest.session__c order by name];
        return csqs;
    }
    
    /*
    public void loadTweet(){
        if (this.guest.twitter_user_id__c == null || this.guest.session__r.date__c == null){
            return;
        }
        
        // Retrive exising tweets in database so that we can check if the tweets retrieved from Twitter is new
        list<tweet__c> existing_tweets;
        existing_tweets = [select id__c from tweet__c where session__c = :this.guest.session__c AND guest__c = :this.guest.id];
        
        // Issue call out to Twitter API and retrive json response.
        String tweet_json = searchTweetByTwitterId(this.guest.twitter_user_id__c);
        
        parseAndInsertTweetInJSON(tweet_json, existing_tweets);
    }
    
    public void parseAndInsertTweetInJSON(string tweet_json, list<tweet__c> existing_tweets){
        // Parse json response with JSON parser and set list of tweet__c.
        list<tweet__c> all_tweets = new list<tweet__c>();
        all_tweets = parseTweet(tweet_json);
        
        // Prepare tweet list to add
        list<tweet__c> tweets_to_add = new list<tweet__c>();
        boolean skip = false;
        for (tweet__c t : all_tweets){
            // Skip if date does not match the session date.
            if (t.created_at__c.date() != this.guest.session__r.date__c){
                continue;
            }
            // Skip if tweet has already been saved in database.
            for (tweet__c et : existing_tweets){
                if (t.id__c == et.id__c){
                    skip = true;
                }
            }
            // Set session id and guest id, and add to the list
            if (!skip){
                t.session__c = this.guest.session__c;
                t.guest__c = this.guest.id;
                tweets_to_add.add(t);
            }
        }
        // Insert tweets.
        commitTweets(tweets_to_add);
        
        // Insert tweets to chatter feed.
        for (tweet__c t : tweets_to_add){
            string who = '';
            if (this.guest.company__c != null && this.guest.company__c != ''){
                who += this.guest.company__c;
            }
            if (this.guest.title__c != null && this.guest.title__c != ''){
                who += ' ' + this.guest.title__c;
            }
            if (this.guest.name__c != null && this.guest.name__c != ''){
                who += ' ' + this.guest.name__c;
            }
            rest_survey_v2.createLinkPost(this.guest.session__c, t.text__c, '/' + this.guest.id, who);
        }
    }
    
    private string searchTweetByTwitterId(string twitter_user_id){
        string body = '[]';
        try {
            HttpResponse res;
            if (twitter_user_id != null && twitter_user_id != '') {
                res = oa.get('https://api.twitter.com/1/statuses/user_timeline.json?screen_name=' + twitter_user_id + '&count=100');
                body = res.getBody();
            }
        } catch (OAuthException e) {
        }
        return body;
    }
    
    private static List<tweet__c> parseTweet(String jsonString) {
        JSONParser parser = JSON.createParser(jsonString);
        List<tweet__c> tweets = new List<tweet__c>();
        while (parser.nextToken() != null) {
            Tweet__c tweet = new Tweet__c();
            // scan json response untill all the field required to create a tweet record being set
            while (parser.nextToken() != null) {
                 if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'created_at')){
                    if (tweet.created_at__c == null){
                        parser.nextToken();
                        list<string> datetime_list = parser.getText().split(' ', 0);
                        string dt = datetime_list[5] + '-' + getMonthInNumber(datetime_list[1]) + '-' + datetime_list[2] + ' ' + datetime_list[3]; 
                        tweet.created_at__c = datetime.valueOf(dt);
                        tweet.created_at__c = tweet.created_at__c.addHours(9);
                    }
                } else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'screen_name')){
                    if (tweet.from_user__c == null){
                        parser.nextToken();
                        tweet.from_user__c = parser.getText();
                    }
                } else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'id')){
                    if (tweet.id__c == null){
                        parser.nextToken();
                        tweet.id__c = parser.getText();
                    }
                } else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'profile_image_url')){
                    if (tweet.profile_image_url__c == null){
                        parser.nextToken();
                        tweet.profile_image_url__c = parser.getText();
                    }
                } else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'text')){
                    if (tweet.text__c == null){
                        parser.nextToken();
                        tweet.text__c = parser.getText();
                    }
                } 
                
                // add tweet to list for inserting record if all set
                if (tweet.created_at__c != null && tweet.from_user__c != null && tweet.id__c != null && tweet.text__c != null && tweet.profile_image_url__c != null) {
                    tweets.add(tweet);
                    break;
                }  
            }
        }
        return tweets;
    }
    
    private static void commitTweets(List<tweet__c> tweets){
        insert tweets;
    }
    
    private static string getMonthInNumber(string monthInLetter){
        string m = monthInLetter.toLowerCase();
        map<string, string> month_map = new map<string, string>{'jan' => '01', 'feb' => '02', 'mar' => '03', 'apr' => '04', 'may' => '05', 'jun' => '06', 'jul' => '07', 'aug' => '08', 'sep' => '09', 'oct' => '10', 'nov' => '11', 'dec' => '12'};
        return month_map.get(m);
    }
    */
    
    public PageReference createLead(){
        lead l = new lead();
        if (this.guest.company__c != null && this.guest.company__c != ''){
            l.Company = this.guest.company__c;
        } else {
            l.Company = system.label.unknown_company;
        }
        if (this.guest.title__c != null && this.guest.title__c != ''){
            l.Title = this.guest.title__c;
        }
        if (this.guest.last_name__c != null && this.guest.last_name__c != ''){
            l.LastName =  this.guest.last_name__c;
        }
        if (this.guest.first_name__c != null && this.guest.first_name__c != ''){
            l.FirstName =  this.guest.first_name__c;
        }
        if (this.guest.email__c != null && this.guest.email__c != ''){
            l.Email =  this.guest.email__c;
        }
        if (this.guest.phone__c != null && this.guest.phone__c != ''){
            l.Phone =  this.guest.phone__c;
        }
        l.guest__c = this.guest.id;
        l.session__c = this.guest.session__c;
        insert l;
        
        PageReference pr = new ApexPages.StandardController(l).view();
        pr.setRedirect(true);
        return pr;
    }
}