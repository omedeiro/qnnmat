%% Power Meter settling time test

sh.flipUp(2);
for i=1:60
x(i)=pw.measurePower();
pause(0.5);
end
%%
t=0:0.5:29.5
figure;
plot(t,x)