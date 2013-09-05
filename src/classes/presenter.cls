public with sharing class presenter {
    public presenter__c presenter;
    public decimal rate_avg;
    
    public class performance_stat {
        public decimal rate_avg {get;set;}
        public integer total_guests {get;set;}
        public integer total_events {get;set;}
        public session__c best_session {get;set;}
    }

    public presenter(ApexPages.StandardController controller) {
        this.presenter = (presenter__c)controller.getRecord();
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
    
    public list<session__c> getSessions(){
        if (this.presenter.id == null){
            return null;
        }
        try {
            return [
                select 
                    id, 
                    name, 
                    date__c, 
                    rate_avg__c,
                    rate_5__c,
                    rate_4__c,
                    rate_3__c,
                    rate_2__c,
                    rate_1__c,
                    guest_sum__c
                from session__c 
                where 
                    presenter__c = :this.presenter.id and
                    enable_rate__c = true and
                    rate_avg__c != 0.00
                order by date__c desc
            ];
        } catch (Exception e){
            return null;
        }
    }
    
    public string getSessions_json(){
        list<session__c> sessions = getSessions();
        if (sessions == null || sessions.size() < 1){
            return null;
        }
        return JSON.serialize(sessions);
    }
    
    public string getSessions_desc_json(){
        list<session__c> sessions = getSessions();
        if (sessions == null || sessions.size() < 1){
            return null;
        }
        
        list<session__c> sessions_desc = new list<session__c>();
        integer offset = sessions.size() - 1;
        do {
            sessions_desc.add(sessions[offset]);
            offset--;
        } while (offset >= 0);
        
        return JSON.serialize(sessions_desc);
    }

}