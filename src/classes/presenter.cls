public with sharing class presenter {
    public presenter__c presenter;
    public decimal rate_avg;
    
    public class performance_stat {
        public decimal rate_avg {get;set;}
        public integer total_guests {get;set;}
        public integer total_events {get;set;}
        public session__c best_session {get;set;}
    }

    private class sexception extends exception {}

    public presenter(ApexPages.StandardController controller) {
        this.presenter = (presenter__c)controller.getRecord();
    }

    @remoteAction 
    public static presenter__c get_presenter(id presenter_id){
        presenter__c presenter;
        
        if (presenter_id == null){
            sexception e = new sexception();
            e.setMessage('Presenter Id is null');
            throw e;
        }
        
        string soql_presenter_flds = scrud.getAccessibleFieldsInCSV('sugoisurvey4__Presenter__c');
        string soql_session_flds = '(select ' + scrud.getAccessibleFieldsInCSV('sugoisurvey4__Session__c') + ' from session__r where enable_rate__c = true and rate_avg__c != 0.00 order by open__c desc, date__c desc, createdDate desc)';

        string soql_flds = soql_presenter_flds + ',' + soql_session_flds;
        string soql = 'select ' + soql_flds + ' from presenter__c where id = :presenter_id';
        presenter = Database.query(soql);
        
        return presenter;
    }

    @remoteAction
    public static list<presenter__c> get_presenters(){
        return scrud.slist('sugoisurvey4__Presenter__c');
    }
    
    public list<session__c> getSessions(){
        return get_presenter(this.presenter.id).session__r;
    }
    
    public performance_stat getPerformance_stat(){
        performance_stat ps = new performance_stat();
        
        // set rate_avg
        ps.rate_avg = 0;
        list<session__c> sessions = getSessions();
        if (sessions == null || sessions.size() < 1){
            return null;
        }
        for (session__c s : sessions){
            ps.rate_avg += s.rate_avg__c;
        }
        ps.rate_avg = ps.rate_avg / sessions.size();
        ps.rate_avg = ps.rate_avg.setScale(2);
        
        // set total_guests
        ps.total_guests = 0;
        for (session__c s : sessions){
            ps.total_guests += Integer.valueOf(s.guest_sum__c);
        }
        
        // set total_events
        ps.total_events = sessions.size();
        
        // set best_event
        decimal best_score = 0.00;
        for (session__c s : sessions){
            if (s.rate_avg__c > best_score){
                best_score = s.rate_avg__c;
                ps.best_session = s;
            }
        }
        
        return ps;
    }
    
    /*
    //Once Visualforce Charting supports float value, replace google chart to this visualforce charting
    public list<session__c> getRate_chart_data(){
        list<session__c> rate_chart_data = new list<session__c>();
        list<session__c> sessions = getSessions();
        if (sessions == null){
            return null;
        }
        for (session__c s : sessions){
            rate_chart_data.add(s);
            if(rate_chart_data.size() > 10){
                break;
            }
        }
        return rate_chart_data;
    }
    */
}