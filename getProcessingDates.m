function date = getProcessingDates()
    date1 = genDatestr('2015-05-01','2015-05-09');
    date2 = {'2015-01-26','2015-02-10','2015-03-06','2015-04-02','2015-05-28','2015-06-11','2015-07-08','2015-08-13','2015-09-09','2015-10-05','2015-11-15'};
    date3 = {'2015-01-30','2015-02-26','2015-03-17','2015-04-13','2015-05-15','2015-06-15','2015-07-26','2015-08-24','2015-09-19','2015-10-19','2015-11-26'};
    date = [date1,date2(4:end),date3(4:end)];
%     date = {'2015-05-02'};
end