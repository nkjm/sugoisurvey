global class post_install implements InstallHandler {
    global void onInstall(InstallContext context) {
        config__c config = config__c.getOrgDefaults();
        // script for upgrade
        if (context.isUpgrade()){
            if (config.cron_trigger_id__c != null && !Test.isRunningTest()){
                system.abortJob(config.cron_trigger_id__c);
            }
            config.need_re_initialization__c = true;
            upsert config;
        }
    }
    
    @isTest
    static void validate_post_install() {
        config__c config = config__c.getOrgDefaults();
        system.assertEquals(false, config.need_re_initialization__c);
        
        post_install pi = new post_install();
        Test.testInstall(pi, new version(1,0),true);
        
        config = config__c.getOrgDefaults();
        system.assertEquals(true, config.need_re_initialization__c);
    }
}