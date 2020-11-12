% Plotting ice_log_script.py data


x = datenum(date(1:size(date,1),:),dateformat);
plot(x,[temp1; temp2; temp3; temp4])
datetick('x')