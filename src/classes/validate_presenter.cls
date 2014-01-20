@isTest
public class validate_presenter {
    private static presenter__c createDummySessionAndPresenter() {
        // create presenter
        presenter__c p = new presenter__c(name = 'redjnvjif');
        insert p;
        
        session__c s;
        list<survey__c> svys;
        
        //// create session1
        // Rate Avg. 4.5, Presenter is set
        s = new session__c(name = 'afjnmfrienq', presenter__c = p.id, date__c = date.newinstance(2013, 2, 1));
        insert s;
        svys = new list<survey__c>();
        svys.add(new survey__c(session__c = s.id, rate__c = 5));
        svys.add(new survey__c(session__c = s.id, rate__c = 4));
        insert svys;
        
        //// create session2
        // Rate Avg. 3.5, Presenter is set
        s = new session__c(name = 'berfimifkmv', presenter__c = p.id, date__c = date.newinstance(2013, 2, 2));
        insert s;
        svys = new list<survey__c>();
        svys.add(new survey__c(session__c = s.id, rate__c = 4));
        svys.add(new survey__c(session__c = s.id, rate__c = 3));
        insert svys;
        
        //// create session3
        // Rate Avg. 3, Presenter is NOT set
        s = new session__c(name = 'cerfimimv');
        insert s;
        svys = new list<survey__c>();
        svys.add(new survey__c(session__c = s.id, rate__c = 3));
        insert svys;
        
        return p;
    }

    static testmethod void validate_get_presenter(){
        try {
            presenter.get_presenter(null);
        } catch (Exception e){
            system.assertEquals('Presenter Id is null', e.getMessage());
        }

        presenter__c p = createDummySessionAndPresenter();
        p = presenter.get_presenter(p.id);
        system.assertEquals('redjnvjif', p.name);
        system.assertEquals(2, p.session__r.size());
    }

    static testmethod void validate_get_presenters(){
        system.assertEquals(null, presenter.get_presenters());
        presenter__c p = createDummySessionAndPresenter();
        system.assertEquals(1, presenter.get_presenters().size());
    }

    static testmethod void validate_getSessions(){
        presenter__c p_co;
        ApexPages.StandardController sc;
        presenter p;
        
        p_co = new presenter__c(name = 'kfjfjrekf');
        sc = new ApexPages.StandardController(p_co);
        p = new presenter(sc);
        try {
            p.getSessions();
        } catch (Exception e){
            system.assertEquals('Presenter Id is null', e.getMessage());
        }
        
        p_co = createDummySessionAndPresenter();
        sc = new ApexPages.StandardController(p_co);
        p = new presenter(sc);
        system.assertEquals(2, p.getSessions().size());
    }
    
    static testmethod void validate_getPerformance_stat(){
        presenter__c p_co;
        ApexPages.StandardController sc;
        presenter p;
        presenter.performance_stat ps;
        
        p_co = new presenter__c(name = 'kfjfjrekf');
        sc = new ApexPages.StandardController(p_co);
        p = new presenter(sc);
        try {
            p.getPerformance_stat();
        } catch (Exception e){
            system.assertEquals('Presenter Id is null', e.getMessage());
        }
        
        p_co = createDummySessionAndPresenter();
        sc = new ApexPages.StandardController(p_co);
        p = new presenter(sc);
        ps = p.getPerformance_stat();
        system.assertEquals(4, ps.rate_avg);
        system.assertEquals(4.5, ps.best_session.rate_avg__c);
        system.assertEquals(2, ps.total_events);
    }
    
    // Deprecated
    /*
    static testmethod void validate_getSessions_json(){
        presenter__c p_co;
        ApexPages.StandardController sc;
        presenter p;

        p_co = new presenter__c(name = 'kfjfjrekf');
        sc = new ApexPages.StandardController(p_co);
        p = new presenter(sc);
        system.assertEquals(null, p.getSessions_json());

        p_co = createDummySessionAndPresenter();
        sc = new ApexPages.StandardController(p_co);
        p = new presenter(sc);
        string sessions_json = p.getSessions_json();
        
        list<session__c> sessions = (list<session__c>)JSON.deserialize(sessions_json, list<sobject>.class);
        system.assertEquals(2, sessions.size());
        system.assertEquals('berfimifkmv', sessions[0].name);
    }
    
    static testmethod void validate_getSessions_desc_json(){
        presenter__c p_co;
        ApexPages.StandardController sc;
        presenter p;

        p_co = new presenter__c(name = 'kfjfjrekf');
        sc = new ApexPages.StandardController(p_co);
        p = new presenter(sc);
        system.assertEquals(null, p.getSessions_desc_json());

        p_co = createDummySessionAndPresenter();
        sc = new ApexPages.StandardController(p_co);
        p = new presenter(sc);
        string sessions_json = p.getSessions_desc_json();
        
        list<session__c> sessions = (list<session__c>)JSON.deserialize(sessions_json, list<sobject>.class);
        system.assertEquals(2, sessions.size());
        system.assertEquals('afjnmfrienq', sessions[0].name);        
    }
    */
}