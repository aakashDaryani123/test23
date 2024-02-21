trigger SLATrigger on SLA__c (before insert, before update) {
    
    if(trigger.isBefore){
        if(trigger.isInsert){
            List<SLA__c> slaList = new List<SLA__c>();
            Set<Id> priorityIds = new Set<Id>();
            Set<Id> serviceAgentsIds = new Set<Id>();
            for(SLA__c sla:trigger.new){
                if(sla.Priority__c != NULL && sla.SLA_Request_Time__c != NULL && sla.Service_Agent__c != NULL){
                    slaList.add(sla);
                    priorityIds.add(sla.Priority__c);
                    serviceAgentsIds.add(sla.Service_Agent__c);
                }
            }
            if(!slaList.isEmpty()){
                SLATriggerHandler.updateSLA(slaList, priorityIds,serviceAgentsIds);
            }
        }
        if(trigger.isUpdate){
            List<SLA__c> slaList = new List<SLA__c>();
            Set<Id> serviceAgentsIds = new Set<Id>();
            for(SLA__c sla:trigger.new){
                if(sla.Priority__c != NULL && sla.SLA_Request_Time__c != NULL && sla.Service_Agent__c != NULL && sla.Status__c == 'Assigned' && sla.Status__c != trigger.oldMap.get(sla.Id).Status__c && sla.Actual_Response_Time__c != NULL){
                    slaList.add(sla);
                    serviceAgentsIds.add(sla.Service_Agent__c);
                }
            }
            if(!slaList.isEmpty()){
                SLATriggerHandler.calculateWorkHours(slaList,serviceAgentsIds);
            }
        }
    }
    
}