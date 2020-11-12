clear;
close all;
clc;

s = scope;
a = awg;

heatLevels = [linspace(-0,0.4,401)];%,linspace(2,0,51)];

sampleRate = 1e6;
numSamplesPerHist = 1000;
rawDataLevel = zeros(numel(heatLevels), numSamplesPerHist);
rawDataTime = zeros(numel(heatLevels), numSamplesPerHist);


heaterWave = zeros(1, 10000);
a.sendWaveform(2, heaterWave, sampleRate, 'heat');
a.setOffset(2, 0);
a.setOutput(2, 1);

startT = tic;

for i = 1:numel(heatLevels)
    %% Download waveforms
    %instruments.awg.sendWaveform(1, channelWave, sampleRate, 'chan');
    a.setOffset(2, heatLevels(i));
    %instruments.awg.sync(2);
    %instruments.awg.setOutput(1, 1);
    a.setOutput(2, 1);
    pause(0.1);
    %% clear scope and wait for acq
    s.clearSweeps();
    pause(0.5);
    fprintf('Please stand by')
    numSamplesPerHist = numSamplesPerHist*1.5;
    while (s.getNumSweeps('F1') < 1.1*numSamplesPerHist) || (s.getNumSweeps('F2') < 1.1*numSamplesPerHist) || (s.getNumSweeps('F5') < 1.1*numSamplesPerHist) || (s.getNumSweeps('F6') < 1.1*numSamplesPerHist) || (s.getNumSweeps('F7') < 1.1*numSamplesPerHist)
        pause(0.5);
        fprintf('.')
    end
    numSamplesPerHist = numSamplesPerHist/1.5;
    fprintf('\n');
    pause(1);
    
    %% get acq
    %disp('Getting F1')
%     waveF1 = s.getWaveform('F1');
%     rawData(i,:) = waveF1.y(1:numSamplesPerHist)';
%     waveF2 = s.getWaveform('F2');
%     rawDataTime(i,:) = waveF2.y(1:numSamplesPerHist)';
    
    % Get acq
    s.trigger('stop')
    disp('Acq...')
    pause(1);
    waveF1 = s.getWaveform('F1');
    if(numel(waveF1.y) < numSamplesPerHist)
        pause(2);
        waveF1 = s.getWaveform('F1');
    end
    params = s.getTrendData('F1');
    rawDataTime(i,:) = params.vOffset + params.vStepSize*waveF1.y(1:numSamplesPerHist);
    
    %disp('Getting F2')
    waveF2 = s.getWaveform('F2');
    params = s.getTrendData('F2');
    rawDataLevel_inaccurateForLowIC(i,:) = params.vOffset + params.vStepSize*waveF2.y(1:numSamplesPerHist);
    
    waveF5 = s.getWaveform('F5');
    params = s.getTrendData('F5');
    rawDataHeaterVdrop(i,:) = params.vOffset + params.vStepSize*waveF5.y(1:numSamplesPerHist);
    
    waveF7 = s.getWaveform('F7');
    params = s.getTrendData('F7');
    rawPeakRead_srcSide(i,:) = params.vOffset + params.vStepSize*waveF7.y(1:numSamplesPerHist);
    
    waveF6 = s.getWaveform('F6');
    params = s.getTrendData('F6');
    rawPeakRead_loadSide(i,:) = params.vOffset + params.vStepSize*waveF6.y(1:numSamplesPerHist);
    
    s.trigger('normal')
    

    disp([num2str(100*i/numel(heatLevels)) '% complete. El: ' num2str(toc(startT)) 's, est:' num2str(toc(startT)/(i/numel(heatLevels))-toc(startT)) 's more to go...']);
end
a.setOutput(2, 0);

save 'hTronSweepInFSCryo_2LONG';

%% Processing
Vmax = mean(rawPeakRead_srcSide(:)); % Peak = p2p since we are not matched (10K>>50R)
riseTimeFromZeroToPeak = 5*500e-6;
%f = 100;    % Hz
R = 10e3;
%trendDivision = 100e-6;     % 100us/div
scaleFactor = Vmax/R/riseTimeFromZeroToPeak;%f*4*Vmax*trendDivision*200;

N = [];
I = [];
figure(123)
hold off;
c = jet(numel(heatLevels));
for i = 1:numel(heatLevels)
    [N, X] = hist(scaleFactor*rawDataTime(i,:) - 0*mean(scaleFactor*rawDataTime(i,:)),100);
    plot(X*1e6, N, 'color', c(i,:));
    hold on;
end
grid on;
xlabel('Switching Current (\muA)')
ylabel('Counts')
title('Switching Distribution')% (mean removed)')

figure(456)
hold off;
for i = 1:numel(heatLevels)
    
    variance(i) = var(scaleFactor*rawDataTime(i,:));
    means(i) = mean(scaleFactor*rawDataTime(i,:));
end
errorbar(heatLevels, means, variance);
grid on;
xlabel('Heater Votlage (V)')
ylabel('Isw Variance (\muA^2)')
%title('Switching Distribution')% (mean removed)')


%%
% Vpp = 3;  % peak to peak voltage from AWG
% Vmax = Vpp; % Peak = p2p since we are not matched (10K>>50R)
% f = 100;    % Hz
% R = 10e3;
% %trendDivision = 100e-6;     % 100us/div
% scaleFactor = f*4*Vmax/R;%f*4*Vmax*trendDivision*200;
% figure(124)
% 
% for i = 1:numel(heatLevels)
%     m(i) = -mean(scaleFactor*rawDataTime(i,:));
%     v(i) = var(scaleFactor*rawDataTime(i,:));
% end
% 
% plot(heatLevels, sqrt(v)*1e6)
% xlabel('Heater voltage (V)')
% ylabel('Isw std dev (\muA)')
% grid on;
% title('Dist. Vs Heat')
% 
% figure(125);
% errorbar(heatLevels, m*1e6, sqrt(v*1e6))
% xlabel('Heater voltage (V)')
% ylabel('Isw (\muA)')
% grid on;
% title('Suppression')

