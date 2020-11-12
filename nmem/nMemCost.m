function cost = nMemCost(vars, instruments)
% vars order: heater, readLevel, writeLevel
% channel 1 is channel
% channel 2 is heater
% scope F1 is the level readout trend line for read 1
% scope F2 is the level readout trend line for read 0
    sampleRate = 1e9;
    numSamplesPerBER = 10000;
    
    [heaterWave, channelWave] = nMemWaveform_ramp(vars(2), vars(1), 60e-9, 20e-9, 100e-9, 1000e-9, 2e-6, sampleRate);%nMemWaveform(vars(2),vars(3), vars(1), 60e-9, 20e-9, 100e-9, 100e-9, 1e-6, sampleRate);
                                %nMemWaveform(readLevel, writeLevel, heatLevel, ChannelWidth, HeatWidth, readDelay, CycleDelay, HoldOff, sampleRate)
                                           %nMemWaveform(writeLevel, heatLevel, ChannelWidth, HeatWidth, readDelay, CycleDelay, HoldOff, sampleRate)
    % Correct for calbe length differences:
%    phase = 0;%2-0.4+2.4-1.3-3.4;%degrees
%    shift = floor(phase*numel(heaterWave)/360);
%    heaterWave = [heaterWave(shift:end) zeros(1, shift-1)];
    % DC heater then use this line:
    %heaterWave = max(abs(heaterWave))*ones(size(heaterWave));
    %% Download waveforms
    instruments.awg.sendWaveform(1, channelWave, sampleRate, 'chan');
    instruments.awg.sendWaveform(2, heaterWave, sampleRate, 'heat');
    instruments.awg.setOffset(1, 0);%vars(4));
    instruments.awg.sync(2);
    instruments.awg.setOutput(1, 1);
    instruments.awg.setOutput(2, 1);
    pause(0.1);
    %% clear scope and wait for acq
    instruments.scope.clearSweeps();
    fprintf('Please stand by.')
    pause(0.5);
    while (instruments.scope.getNumSweeps('F1') < numSamplesPerBER) || (instruments.scope.getNumSweeps('F2') < numSamplesPerBER)
        pause(0.5);
        fprintf('.')
    end
    fprintf('\n')
    
    %% get acq
    disp('Getting F1')
    instruments.scope.trigger('STOP');
    waveR1 = instruments.scope.getWaveform('F1');
    trend1 = instruments.scope.getTrendData('F1');
    disp('Getting F2')
    waveR0 = instruments.scope.getWaveform('F2');
    trend0 = instruments.scope.getTrendData('F2');
    instruments.scope.trigger('NORMAL');
    
    %% Calculate BER
    minLength = min(length(waveR1.y),length(waveR0.y));
    %R1 = trend1.vOffset + trend1.vStepSize*waveR1.y(1:minLength);
    %R0 = trend0.vOffset + trend0.vStepSize*waveR0.y(1:minLength);
    R1 = waveR1.y(1:minLength);
    R0 = waveR0.y(1:minLength);
    
%     R1val = isnan(R1);
%     R0val = isnan(R0);
%     R1 = R1 + inf*R1val;
%     R0 = R0 + inf*R0val;
    
    [yR1,xR1] = hist(R1,100);
    [yR0,xR0] = hist(R0,100);
    
    save(['E:\BrendensMatlabDrivers\bert20\sweep_' datestr(now, 30)], 'yR1', 'xR1', 'yR0', 'xR0', 'vars', 'R1', 'R0','numSamplesPerBER');
    
    figure(123);
    hold off;
    plot(xR1,yR1,'b'); hold on;     % write positive 1 (1)
    plot(xR0,yR0,'r');          % write negative 1 (0)
    

    modDiff = abs(mode(R1)- mode(R0));
    threshDiff = modDiff/2;
    thresh = (mode(R1) + mode(R0))/2;
    thresh = (min([R1(:);R0(:)])+ max([R1(:);R0(:)]))/2;%quantile([R1(:);R0(:)],0.5);
%     valuesToTry = linspace(min([R1(:);R0(:)]), max([R1(:);R0(:)]), 1000);
%     
%     best = (sum(R1<valuesToTry(1)) + sum(R0>valuesToTry(1)));
%     thresh = valuesToTry(1);
%     for i = 1:numel(valuesToTry)
%         err1 = (sum(R1<valuesToTry(i)) + sum(R0>valuesToTry(i)));
%         if (err1>best)
%             thresh = valuesToTry(i);
%             best = err1;
%         end
%     end
        
    
    %lastError = inf;
    %secondLastError = inf;
    while (threshDiff > modDiff/100000 )
        %secondLastError = lastError;
        thresh1 = thresh + threshDiff;%(max(max(R1),max(R0))+min(min(R1),min(R0)))./2;%mean([R1(:); R0(:)]);;    % TODO: fix this, it will cause probelms
        err1 = (sum(R1>thresh1) + sum(R0<thresh1));
        
        thresh2 = thresh - threshDiff;%(max(max(R1),max(R0))+min(min(R1),min(R0)))./2;%mean([R1(:); R0(:)]);;    % TODO: fix this, it will cause probelms
        err2 = (sum(R1>thresh2) + sum(R0<thresh2));
        
        if err1 > err2
            thresh = thresh2;
            %lastError = err2;
        else
            thresh = thresh1;
            %lastError = err1;
        end
        
        %plot([thresh, thresh],[min(ylim), max(ylim)],'m')
        %plot([thresh1, thresh1],[min(ylim), max(ylim)],'m')
        %plot([thresh2, thresh2],[min(ylim), max(ylim)],'b')
        threshDiff = threshDiff/1.1;
    end
    
    thresh = (mode(R1) + mode(R0))/2;
    
    plot([thresh, thresh],[min(ylim), max(ylim)],'g')
    xlabel('Level At Read (binary state)'); ylabel('Counts')
    title('Threshold determination')
    
    % swapped correct and error for ramp measurements
    err = (sum(R1>thresh) + sum(R0<thresh));
    corr = (sum(R1<thresh) + sum(R0>thresh));

    fprintf('Error rate is %.3f%% = %.1e\n',100*err/(2*minLength), err/(2*minLength))
    fprintf('Correct rate is %.3f%% \n',100*corr/(2*minLength))
    
    instruments.awg.setText(sprintf('BER=%.1e',  err/(2*minLength)));
    
    quantileThresh = 0.001;
    distanceBetweenTails = (quantile(R1,quantileThresh) - quantile(R0,1-quantileThresh));
    plot([quantile(R1,quantileThresh), quantile(R1,quantileThresh)],[min(ylim), max(ylim)],'c')
    plot([quantile(R0,1-quantileThresh), quantile(R0,1-quantileThresh)],[min(ylim), max(ylim)],'m')
    
    legend('write 1','write 0', 'threshold', 'write 1 qtl', 'write 0 qtl')
    cost = err/(2*minLength);% + exp(-distanceBetweenTails)*1e-3;%(1e-4).^(distanceBetweenTails);
end