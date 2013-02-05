global class schedule_copy_comment_to_feedItem implements Schedulable{
	global integer interval = 1;
	
    global void execute(SchedulableContext SC) {
    	// execute copy
        jr_session.copy_comment_to_feedItem(null);
        
        // schedule next copy
        Datetime next = Datetime.now().addMinutes(this.interval);
        string sch = string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?';
        System.schedule('Copy comment to feedItem - ' + string.valueOf(next.second()) + ' ' + string.valueOf(next.minute()) + ' ' + string.valueOf(next.hour()) + ' ' + string.valueOf(next.day()) + ' ' + string.valueOf(next.month()) + ' ?', sch, new schedule_copy_comment_to_feedItem());
        
        // abort this job
        System.abortJob(sc.getTriggerId());
    }
    
    private static testmethod void validate_execute(){
    	session__c session = validate_session.createDummySession('irjffiejdjhjkf', 'Eメールの入力が必要', 'アンケートの入力が必要');
    	string sch = '0 0 * * * ?';
    	Test.startTest();
    	System.schedule('Copy comment to feedItem for validate', sch, new schedule_copy_comment_to_feedItem());
    	Test.stopTest();
    	
    	system.assertEquals(2, [select id from feedItem where parentId = :session.id].size());
    }
}