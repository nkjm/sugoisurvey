global class schedule_copy_comment_to_feedItem implements Schedulable{
    global integer interval = 1;
    
    global void execute(SchedulableContext SC) {
        //// execute copy
        // comment copy
        jr_session.copy_comment_to_feedItem(null);

        // schedule next copy
        Datetime next = Datetime.now().addMinutes(this.interval);
        string sch = string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?';
        System.schedule('Copy comment to feedItem - ' + sch, sch, new schedule_copy_comment_to_feedItem());
        
        // abort this job
        if (!Test.isRunningTest()){
            System.abortJob(sc.getTriggerId());
        }
    }
    
    private static testmethod void validate_execute(){
        session__c session = validate_session.createDummySession('irjffiejdjhjkf', system.label.picklist_require_email, system.label.picklist_require_survey_submission);
        string sch = '0 0 * * * ?';
        Test.startTest();
        System.schedule('Cron Trigger v1.3', sch, new schedule_copy_comment_to_feedItem());
        Test.stopTest();
        
        system.assertEquals(2, [select id from feedItem where parentId = :session.id].size());
    }
}