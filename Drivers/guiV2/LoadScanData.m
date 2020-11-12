clear all; close all;
c=2.998.*1e8;%speed of light in m/s
%%
currentFolder=cd();
dateN=now;
strFolder=datestr(dateN,'ddmmyyyy');
mkdir(strcat(strFolder,'AutoCorr'));
%%
[data,fid,fpath]=loadData;
dir=strcat(strFolder,'AutoCorr','/',fid(1:end));
mkdir(dir);

ch1=data.ch1;
ch2=data.ch2;
ch3=data.ch3;
ch4=data.ch4;
vecLength=length(ch1.y);
%%
cd(fpath);
dataList=ls('OsciData*.mat');
cd(currentFolder);
dataList=string(dataList);
dataList=split(dataList);
% Cutting the empty String in the List out
cutStringIndex=ones(length(dataList),1);
for i=1:length(dataList)
    if strlength(dataList(i))==0
    cutStringIndex(i)=0;
    end
end
dataList=dataList(logical(cutStringIndex));
%% 
time=[];
dataCH1=[];
dataCH2=[];
dataCH3=[];
dataCH4=[];
for i=1:length(dataList)
    data=load(strcat(fpath,'/',dataList(i)));
    time(:,i)=data.ch1.x;
    dataCH1(:,i)=data.ch1.y;
    dataCH2(:,i)=data.ch2.y(1:vecLength);
    dataCH3(:,i)=data.ch3.y(1:vecLength);
    dataCH4(:,i)=data.ch4.y(1:vecLength);
end
%% Averaged Traces
dSample=100;
timeA=downsample(time(:,1),dSample); %Will be assumed to be identical
ch1A=downsample(mean(dataCH1,2),dSample);
ch2A=downsample(mean(dataCH2,2),dSample);
ch3A=downsample(mean(dataCH3,2),dSample);
ch4A=downsample(mean(dataCH4,2),dSample);

%%
fig1=figure(1);
set(gcf,'PaperUnits','centimeters','PaperSize',[15,7],'PaperPosition',[0 0 15 7]);
plot(ch1.x,ch1.y,ch2.x,ch2.y,ch3.x,smooth(ch3.y),ch4.x,ch4.y);
ax=gca;
ax.XLabel.String='Time [s]';
%ax.XLimMode='manual';
%ax.XLim=[-10 10];
%ax.XTick=[-14:2:14];
ax.XMinorTick='on';
%ax.YLimMode='manual';
 %ax.YLim=[-1 1 ];
ax.YLabel.String=' Voltage [V]';
ax.YMinorTick='on';

%title(variableName);
%lgd=legend('0','\pi','Location','northwest');
%legend('boxoff');
%title(lgd,'CEP=');
set(ax,'FontSize',11);
% axis tight;
box on
 grid off
print(strcat(dir,'/','RawDataOutput'),'-dpng','-r1200')
%%
cmplx=ch1.y+1i.*ch2.y(1:length(ch1.y));

%%
phase=0;
rot=exp(-1i.*phase);
figure(4);
set(gcf,'PaperUnits','centimeters','PaperSize',[15,7],'PaperPosition',[0 0 15 7]);
%plot(ch1.x,ch1.y.*cos((smooth(ch2.y(1:stopIndex)-offsetPhase).*2*pi/phaseScale-ch2.y(indexMax)*2*pi/phaseScale)+phaseFudge),ch1.x,ch1.y.*sin((smooth(ch2.y(1:stopIndex)-offsetPhase).*2*pi/phaseScale-ch2.y(indexMax)*pi/phaseScale)+phaseFudge));
plot(ch1.x,real(cmplx.*rot),ch1.x,imag(cmplx.*rot))
ax=gca;
ax.XLabel.String='Time [s]';
%ax.XLimMode='manual';
%ax.XLim=[-10 10];
%ax.XTick=[-14:2:14];
ax.XMinorTick='on';
%ax.YLimMode='manual';
 %ax.YLim=[-1 1 ];
ax.YLabel.String=' Lock-In Voltage [V]';
ax.YMinorTick='on';
%title(variableName);
%lgd=legend('0','\pi','Location','northwest');
%legend('boxoff');
%title(lgd,'CEP=');
set(ax,'FontSize',11);
% axis tight;
box on
 grid off
print(strcat(dir,'/','FinalOutputXY'),'-dpng','-r1200')



%% Complex PLot of Lockin
%cmplx=(ch1.y.*exp(-1i.*unwrap((smooth(ch2.y(1:stopIndex)-minPhase).*2*pi/phaseScale)-ch2.y(indexMax)*2*pi/phaseScale)));

fig1=figure(3);
set(gcf,'PaperUnits','centimeters','PaperSize',[15,7],'PaperPosition',[0 0 15 7]);
plot(real(cmplx.*rot),imag(cmplx.*rot))
view([0,90])
shading interp
ax=gca;
ax.XLabel.String='X Voltage [V]';
%ax.XLimMode='manual';
%ax.XLim=[-10 10];
%ax.XTick=[-14:2:14];
ax.XMinorTick='on';
%ax.YLimMode='manual';
 %ax.YLim=[-1 1 ];
ax.YLabel.String=' Y Voltage [V]';
ax.YMinorTick='on';

%title(variableName);
%lgd=legend('0','\pi','Location','northwest');
%legend('boxoff');
%title(lgd,'CEP=');
set(ax,'FontSize',11);
% axis tight;
box on
 grid off
print(strcat(dir,'/','ComplexMap'),'-dpng','-r1200')

%%
%%
fig5=figure(5);
plot(timeA,ch4A)
[x1,y1]=getpts(fig5);
[~,cutIndex1]=min(abs(timeA-x1(1)));
[~,cutIndex2]=min(abs(timeA-x1(2)));
t=timeA(cutIndex1:cutIndex2);
c4=ch4A(cutIndex1:cutIndex2);
%%
figure(6)
plot(fittedmodel,t,c4);
fitData=fittedmodel(t);
[~,posIndex]=findpeaks(fitData);
[~,negIndex]=findpeaks(-fitData);
Index= sort([posIndex; negIndex]);
figure(7);
plot(t,c4,t(Index),c4(Index),'*')
delay=0:(1.1e-6./(2*c)):(1.1e-6./(2*c))*(length(Index)-1);
delayRealTime=t(Index);
%% Scale to fs axis!
[fitDelay,~]=delayFit(delayRealTime,delay);
figure;
plot(fitDelay(timeA).*1e15,ch1A);


%% Resampling for FFT
FS=1e17;
[y,ty]=resample(ch1A,fitDelay(timeA),FS,1,1);
figure;
plot(fitDelay(timeA).*1e15,ch1A,ty.*1e15,y)
%%
padData=[zeros(50000,1);y;zeros(50000,1)];
L=length(padData);
spectrum=fft(padData);
frqz=(FS*(0:(L/2))/L);
fig7=figure(7);
yyaxis left
semilogy(frqz.*1e-12,abs(spectrum(1:L/2+1)))
yyaxis right
plot(frqz.*1e-12,unwrap(angle(spectrum(1:L/2+1))))
unwrapPhase=unwrap(angle(spectrum(1:L/2+1)));
xlim([0 1000])
[x1,y1]=getpts(fig7);
[~,posIndex1]=min(abs(frqz-x1(1).*1e12));
[~,posIndex2]=min(abs(frqz-x1(2)).*1e12);
slope=(unwrapPhase(posIndex2)-unwrapPhase(posIndex1))/(frqz(posIndex2)-frqz(posIndex1));
%%
fig7=figure(8);
yyaxis left
semilogy(frqz.*1e-12,abs(spectrum(1:L/2+1)))
yyaxis right
plot(frqz.*1e-12,unwrap(angle(spectrum(1:L/2+1)))-slope.*frqz')
unwrapPhase=unwrap(angle(spectrum(1:L/2+1)));
xlim([0 1000])


function [data,fid,path]=loadData()
%% Setup the Import Options

% Import the data
[path]=uigetdir();
file='OsciData1.mat';
out=strsplit(path,'/')
out=out{end}
fid=out;
data=load(strcat(path,'/',file));

end
function [fitresult, gof] = delayFit(delayRealTime, delay)
%CREATEFIT(DELAYREALTIME,DELAY)
%  Create a fit.
%
%  Data for 'untitled fit 1' fit:
%      X Input : delayRealTime
%      Y Output: delay
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.

%  Auto-generated by MATLAB on 18-Nov-2019 18:01:38


%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( delayRealTime, delay );

% Set up fittype and options.
ft = fittype( 'poly4' );

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft );
end