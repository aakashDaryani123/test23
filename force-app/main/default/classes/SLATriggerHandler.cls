/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-21-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class SLATriggerHandler {
    
    public static List<Date> getHolidays(){
        List<Date> dateAtWhichWeHaveHoliday = new List<Date>();
        System.debug('test');
        for(Holiday__c holidayList : [SELECT Id,Holiday_Date__c FROM Holiday__c]){
            dateAtWhichWeHaveHoliday.add(holidayList.Holiday_Date__c);
        }
        return dateAtWhichWeHaveHoliday;
    }
    
    public static Map<Id,Map<String,String>> getWorkSchedule(Set<Id> serviceAgentIds){
        Map<Id,Map<String,String>> mapOfTimeWorkDays = new Map<Id,Map<String,String>>();
        for(Service_Agent__c workSchedule : [SELECT Id,Work_Schedule__c, Work_Schedule__r.Monday_Start__c,Work_Schedule__r.Monday_End__c,Work_Schedule__r.Tuesday_Start__c,Work_Schedule__r.Tuesday_End__c,Work_Schedule__r.Wednesday_Start__c, Work_Schedule__r.Wednesday_End__c, Work_Schedule__r.Thursday_Start__c, Work_Schedule__r.Thursday_End__c, Work_Schedule__r.Friday_Start__c, Work_Schedule__r.Friday_End__c, Work_Schedule__r.Saturday_Start__c, Work_Schedule__r.Saturday_End__c, Work_Schedule__r.Sunday_Start__c, Work_Schedule__r.Sunday_End__c FROM Service_Agent__c WHERE Id IN :serviceAgentIds AND Work_Schedule__c != NULL]){
            Map<String,String> weekDaysAndTime = new Map<String,String>();
            if (workSchedule.Work_Schedule__r.Monday_Start__c != null && workSchedule.Work_Schedule__r.Monday_End__c != null) {
                weekDaysAndTime.put('Monday', workSchedule.Work_Schedule__r.Monday_Start__c + '-' + workSchedule.Work_Schedule__r.Monday_End__c);
            }
            if (workSchedule.Work_Schedule__r.Tuesday_Start__c != null && workSchedule.Work_Schedule__r.Tuesday_End__c != null) {
                weekDaysAndTime.put('Tuesday', workSchedule.Work_Schedule__r.Tuesday_Start__c + '-' + workSchedule.Work_Schedule__r.Tuesday_End__c);
            }
            if (workSchedule.Work_Schedule__r.Wednesday_Start__c != null && workSchedule.Work_Schedule__r.Wednesday_End__c != null) {
                weekDaysAndTime.put('Wednesday', workSchedule.Work_Schedule__r.Wednesday_Start__c + '-' + workSchedule.Work_Schedule__r.Wednesday_End__c);
            }
            if (workSchedule.Work_Schedule__r.Thursday_Start__c != null && workSchedule.Work_Schedule__r.Thursday_End__c != null) {
                weekDaysAndTime.put('Thursday', workSchedule.Work_Schedule__r.Thursday_Start__c + '-' + workSchedule.Work_Schedule__r.Thursday_End__c);
            }
            if (workSchedule.Work_Schedule__r.Friday_Start__c != null && workSchedule.Work_Schedule__r.Friday_End__c != null) {
                weekDaysAndTime.put('Friday', workSchedule.Work_Schedule__r.Friday_Start__c + '-' + workSchedule.Work_Schedule__r.Friday_End__c);
            }
            if (workSchedule.Work_Schedule__r.Saturday_Start__c != null && workSchedule.Work_Schedule__r.Saturday_End__c != null) {
                weekDaysAndTime.put('Saturday', workSchedule.Work_Schedule__r.Saturday_Start__c + '-' + workSchedule.Work_Schedule__r.Saturday_End__c);
            }
            if (workSchedule.Work_Schedule__r.Sunday_Start__c != null && workSchedule.Work_Schedule__r.Sunday_End__c != null) {
                weekDaysAndTime.put('Sunday', workSchedule.Work_Schedule__r.Sunday_Start__c + '-' + workSchedule.Work_Schedule__r.Sunday_End__c);
            }
            mapOfTimeWorkDays.put(workSchedule.Id,weekDaysAndTime);         
        }
        return mapOfTimeWorkDays;
    }
    
    public static void updateSLA(List<SLA__c> slaList,Set<Id> priorityIds,Set<Id> serviceAgentIds){
        List<Date> idealResponseTime = new List<Date>();
        String userTimeZone = UserInfo.getTimeZone().getID();
        Map<Id,Priority__c> priorityMap = new Map<Id,Priority__c>([SELECT Id, Resolution_Duration__c FROM Priority__c WHERE Id IN : priorityIds]);
        Map<Id,Map<String,String>> mapOfTimeWorkDays = getWorkSchedule(serviceAgentIds);
        List<Date> dateAtWhichWeHaveHoliday = getHolidays();
        for(SLA__c sla:slaList){
            if(priorityMap.containsKey(sla.Priority__c)){
                sla.Ideal_Response_Time__c =  sla.SLA_Request_Time__c.addMinutes((Integer)priorityMap.get(sla.Priority__c).Resolution_Duration__c);
                System.debug(sla.Ideal_Response_Time__c);
            }
        }
        Integer i=0;
        While(i<slaList.size()){
            Time endTime;
            Time startTime;
            DateTime startDateTime;
            TimeZone tz = UserInfo.getTimeZone();
            if((mapOfTimeWorkDays.containsKey(slaList[i].Service_Agent__c) && !mapOfTimeWorkDays.get(slaList[i].Service_Agent__c).isEmpty())){
                if(mapOfTimeWorkDays.get(slaList[i].Service_Agent__c).containsKey(slaList[i].Ideal_Response_Time__c.format('EEEE'))){
                    endTime = Time.newInstance(Integer.valueOf(mapOfTimeWorkDays.get(slaList[i].Service_Agent__c).get(slaList[i].Ideal_Response_Time__c.format('EEEE')).split('-')[1].split(':')[0]), Integer.valueOf(mapOfTimeWorkDays.get(slaList[i].Service_Agent__c).get(slaList[i].Ideal_Response_Time__c.format('EEEE')).split('-')[1].split(':')[1]), 0, 0);
                    startTime = Time.newInstance(Integer.valueOf(mapOfTimeWorkDays.get(slaList[i].Service_Agent__c).get(slaList[i].Ideal_Response_Time__c.format('EEEE')).split('-')[0].split(':')[0]), Integer.valueOf(mapOfTimeWorkDays.get(slaList[i].Service_Agent__c).get(slaList[i].Ideal_Response_Time__c.format('EEEE')).split('-')[0].split(':')[1]), 0, 0);
                	startDateTime = DateTime.newInstance(slaList[i].SLA_Request_Time__c.Date(),startTime);
                }
                else{
                   System.debug('Not available');
                   slaList[i] = weekDayNotAvailable(slaList[i], startTime, priorityMap, mapOfTimeWorkDays);
                }
            }
            if ((endTime != NULL && slaList[i].Ideal_Response_Time__c.time() > endTime) || (startTime != NULL && slaList[i].SLA_Request_Time__c<startDateTime) || dateAtWhichWeHaveHoliday.contains(slaList[i].Ideal_Response_Time__c.date()) || slaList[i].Ideal_Response_Time__c.format('EEEE') == 'Saturday' || slaList[i].Ideal_Response_Time__c.format('EEEE') == 'Sunday') {
                if(!dateAtWhichWeHaveHoliday.contains(slaList[i].Ideal_Response_Time__c.date()) && slaList[i].Ideal_Response_Time__c.format('EEEE') != 'Saturday' && slaList[i].Ideal_Response_Time__c.format('EEEE') != 'Sunday'){
                    if(endTime != NULL && slaList[i].Ideal_Response_Time__c.time() > endTime){
                        System.debug('in first');
                        slaList[i] = handleTime(slaList[i], endTime, priorityMap, mapOfTimeWorkDays);
                    }
                    if(startTime != NULL && slaList[i].SLA_Request_Time__c<startDateTime){
                        System.debug('In start');
                        DateTime dateTimeTest = DateTime.newInstance(slaList[i].SLA_Request_Time__c.Date(), startTime).addMinutes((Integer)priorityMap.get(slaList[i].Priority__c).Resolution_Duration__c);
                        slaList[i].Ideal_Response_Time__c = dateTimeTest;
                    }
                }
                if(dateAtWhichWeHaveHoliday.contains(slaList[i].Ideal_Response_Time__c.date()) || slaList[i].Ideal_Response_Time__c.format('EEEE') == 'Saturday' || slaList[i].Ideal_Response_Time__c.format('EEEE') == 'Sunday'){
                    System.debug('in Secondd');
                    slaList[i].Ideal_Response_Time__c = slaList[i].Ideal_Response_Time__c.addDays(1);
                }
                else{
                    i++;
                }
            }
            else{
                i++;
            }
        }
    }
    
    public static SLA__c weekDayNotAvailable(SLA__c sla, Time startTime, Map<Id,Priority__c> priorityMap, Map<Id,Map<String,String>> mapOfTimeWorkDays){
        Boolean temp = true;
        while(temp){
            sla.Ideal_Response_Time__c = sla.Ideal_Response_Time__c.addDays(1);
            if(mapOfTimeWorkDays.get(sla.Service_Agent__c).containsKey(sla.Ideal_Response_Time__c.format('EEEE'))){
                temp = false;
                startTime = Time.newInstance(Integer.valueOf(mapOfTimeWorkDays.get(sla.Service_Agent__c).get(sla.Ideal_Response_Time__c.format('EEEE')).split('-')[0].split(':')[0]), Integer.valueOf(mapOfTimeWorkDays.get(sla.Service_Agent__c).get(sla.Ideal_Response_Time__c.format('EEEE')).split('-')[0].split(':')[1]), 0, 0);
                DateTime dateTimeTest = DateTime.newInstance(sla.Ideal_Response_Time__c.Date(), startTime).addMinutes((Integer)priorityMap.get(sla.Priority__c).Resolution_Duration__c);
                sla.Ideal_Response_Time__c = dateTimeTest;
            }
        } 
        return sla;
    }
    
    public static SLA__c handleTime(SLA__c sla, Time endTime, Map<Id,Priority__c> priorityMap, Map<Id,Map<String,String>> mapOfTimeWorkDays){
        TimeZone tz = UserInfo.getTimeZone();
        System.debug(sla.Ideal_Response_Time__c);
        DateTime convertedTime = sla.Ideal_Response_Time__c.addSeconds((tz.getOffset(sla.Ideal_Response_Time__c)/1000));
        System.debug(convertedTime);
        //Get the acutal time when the day ends
        DateTime dateTimeTest = DateTime.newInstance(sla.SLA_Request_Time__c.Date(), endTime).addSeconds((tz.getOffset(sla.Ideal_Response_Time__c)/1000));
        System.debug(dateTimeTest);
        Long differenceMinutes = (convertedTime.getTime() - dateTimeTest.getTime()) / 1000;
        System.debug(differenceMinutes);
        //If difference is high then priority this means time we have to use it for the next day 
        if(differenceMinutes > (Integer)priorityMap.get(sla.Priority__c).Resolution_Duration__c*60){
            differenceMinutes = (Integer)priorityMap.get(sla.Priority__c).Resolution_Duration__c*60;
        }
        System.debug(differenceMinutes);
        DateTime nextWorkingDay = sla.Ideal_Response_Time__c.date().addDays(1);
        System.debug(nextWorkingDay);
        if(mapOfTimeWorkDays.containsKey(sla.Service_Agent__c)){
            Time startTime;
            Date nextDate = Date.newInstance(nextWorkingDay.year(), nextWorkingDay.month(), nextWorkingDay.day());
            if(mapOfTimeWorkDays.containsKey(sla.Service_Agent__c) && mapOfTimeWorkDays.get(sla.Service_Agent__c).containsKey(nextWorkingDay.format('EEEE'))){
                startTime = Time.newInstance(Integer.valueOf(mapOfTimeWorkDays.get(sla.Service_Agent__c).get(nextWorkingDay.format('EEEE')).split('-')[0].split(':')[0]),Integer.valueOf(mapOfTimeWorkDays.get(sla.Service_Agent__c).get(nextWorkingDay.format('EEEE')).split('-')[0].split(':')[1]),0,0);
            }
            else{
                Boolean temp= true;
                while(temp){
                    nextWorkingDay = nextWorkingDay.addDays(1);
                    if(mapOfTimeWorkDays.containsKey(sla.Service_Agent__c) && mapOfTimeWorkDays.get(sla.Service_Agent__c).containsKey(nextWorkingDay.format('EEEE'))){
                        temp = false;
                        nextDate = Date.newInstance(nextWorkingDay.year(), nextWorkingDay.month(), nextWorkingDay.day());
                        startTime = Time.newInstance(Integer.valueOf(mapOfTimeWorkDays.get(sla.Service_Agent__c).get(nextWorkingDay.format('EEEE')).split('-')[0].split(':')[0]),Integer.valueOf(mapOfTimeWorkDays.get(sla.Service_Agent__c).get(nextWorkingDay.format('EEEE')).split('-')[0].split(':')[1]),0,0);
                    }
                }
            }
            System.debug(nextDate);
            DateTime adjustedIdealResponseTime = DateTime.newInstance(nextDate,startTime);
            adjustedIdealResponseTime = adjustedIdealResponseTime.addSeconds((Integer)differenceMinutes);
            sla.Ideal_Response_Time__c = adjustedIdealResponseTime;
            System.debug(adjustedIdealResponseTime.addSeconds((tz.getOffset(sla.Ideal_Response_Time__c)/1000)));
        }
        return sla;
    }
    
    
    public static void calculateWorkHours(List<SLA__c> slaList, Set<Id> serviceAgentIds) {
        Map<Id,Map<String,String>> workSchedules = getWorkSchedule(serviceAgentIds);
        List<Date> holidays = getHolidays();
        String userTimeZone = UserInfo.getTimeZone().getID();
        Map<Id, Integer> workHours = new Map<Id, Integer>();
        for (SLA__c sla : slaList) {
            if(!workHours.containsKey(sla.Id)){
                workHours.put(sla.Id, 0);
            }            
            Id serviceAgentId = sla.Service_Agent__c;
            DateTime startDate = sla.SLA_Request_Time__c;
            DateTime endDate = sla.Actual_Response_Time__c;
            Map<Id,Map<String,String>> mapOfTimeWorkDays = getWorkSchedule(serviceAgentIds);
            while (startDate.Date() <= endDate.Date()){
                System.debug(startDate.Date());
                if (startDate.format('EEEE') != 'Sunday' && startDate.format('EEEE') != 'Saturday' && !holidays.contains(startDate.Date())) {
                    Map<String, String> workSchedule = workSchedules.get(serviceAgentId);
                    if (workSchedule != null) {
                        String dayOfWeek = startDate.format('EEEE');
                        if (workSchedule.containsKey(dayOfWeek)) {
                            String[] startAndEndTimes = workSchedule.get(dayOfWeek).split('-');
                            DateTime startDateTime;
                            if(startDate.Date() == sla.SLA_Request_Time__c.Date()){
                                startDateTime = sla.SLA_Request_Time__c;
                                System.debug(startDateTime);
                                Time startTime = Time.newInstance(Integer.valueOf(mapOfTimeWorkDays.get(sla.Service_Agent__c).get(sla.Ideal_Response_Time__c.format('EEEE')).split('-')[0].split(':')[0]), Integer.valueOf(mapOfTimeWorkDays.get(sla.Service_Agent__c).get(sla.Ideal_Response_Time__c.format('EEEE')).split('-')[0].split(':')[1]), 0, 0);
                				DateTime startDateTimeAdjusted = DateTime.newInstance(sla.SLA_Request_Time__c.Date(),startTime);
                                if(startDateTime<startDateTimeAdjusted){
                                    startDateTime = startDateTimeAdjusted;
                                }
                                System.debug(startDateTime);
                            }
                            else{
                                String startTimeString = startAndEndTimes[0];
                                Integer hours = Integer.valueOf(startTimeString.split(':')[0]);
                                Integer minutes = Integer.valueOf(startTimeString.split(':')[1]);
                                Time startTime = Time.newInstance(hours, minutes, 0, 0);
                                startDateTime = DateTime.newInstance(startDate.date(),startTime);
                            }
                            DateTime endDateTime;
                            if(startDate.Date() == sla.Actual_Response_Time__c.Date()){
                                endDateTime = sla.Actual_Response_Time__c;
                            }
                            else{
                                String startTimeString = startAndEndTimes[1];
                                Integer hours = Integer.valueOf(startTimeString.split(':')[0]);
                                Integer minutes = Integer.valueOf(startTimeString.split(':')[1]);
                                Time endTime = Time.newInstance(hours, minutes, 0, 0);
                                endDateTime = DateTime.newInstance(startDate.date(),endTime);
                            }
                            if(sla.SLA_Request_Time__c > endDateTime){
                                workHours.put(sla.Id, workHours.get(sla.Id) + 0); 
                            }
                            else{
                                workHours.put(sla.Id, workHours.get(sla.Id) + calculateTimeDifferenceForDay(startDateTime,endDateTime));
                            }
                        }
                    }
                }
                startDate = startDate.addDays(1);
            }
            sla.Actual_Response_Duration__c = workHours.get(sla.Id);
        }  
    }
    
    public static Integer calculateTimeDifferenceForDay(DateTime startDateTime,DateTime endDateTime) {
        if (endDateTime != null && startDateTime != null) {
            Long millisecondsDifference = endDateTime.getTime() - startDateTime.getTime();
            return (Integer)(millisecondsDifference / (1000 * 60));
        }
        return 0;
    } 
}