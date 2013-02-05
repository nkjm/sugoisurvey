public with sharing class device_detector {
    public boolean is_mobile {get;set;}

    public PageReference detect_device() {
        string user_agent = ApexPages.currentPage().getHeaders().get('USER-AGENT');
        string reg_mobile = '(?i)(iphone|ipod|ipad|blackberry|android|palm|windows\\s+ce)';
        Matcher m = Pattern.compile(reg_mobile).matcher(user_agent);
        if (m.find()){
            this.is_mobile = true;
        } else {
            this.is_mobile = false;
        }
        return null;
    }
    
    private static testmethod void validate_detect_device(){
    	device_detector dd = new device_detector();
    	
    	ApexPages.currentPage().getHeaders().put('USER-AGENT', 'iphone');
    	dd.detect_device();
    	system.assertEquals(true, dd.is_mobile);
    	
    	ApexPages.currentPage().getHeaders().put('USER-AGENT', 'ipad');
    	dd.detect_device();
    	system.assertEquals(true, dd.is_mobile);
    	
    	ApexPages.currentPage().getHeaders().put('USER-AGENT', 'macosx');
    	dd.detect_device();
    	system.assertEquals(false, dd.is_mobile);
    }
}