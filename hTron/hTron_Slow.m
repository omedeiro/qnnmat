clear all;
close all;
clc;

s=scope;
a=awg;

sampleRate = 1e9;
preSilence = 200e-9;
postSilence = 100e-6;
hPulseWidth = 10e-9;
readWidth = 10e-9;
numSamplesPerRun = 100;

protoHeat = [ones(1,hPulseWidth*sampleRate)];

delays = linspace(0e-9, 20e-9, 21);
readLevel = linspace(10e-3,20e-3,11);
heatLevel = 3;

for i = 1:numel(delays)
    readWave = [zeros(1,preSilence*sampleRate), ones(1,readWidth*sampleRate), zeros(1,postSilence*sampleRate)];
    heatWave = [zeros(1,(preSilence-delays(i))*sampleRate), protoHeat];
    heatWave = [heatWave, zeros(1,numel(readWave)-numel(heatWave))];
    
    a.sendWaveform(1, readWave, sampleRate, 'read');
    a.sendWaveform(2, heatWave, sampleRate, 'heat');
    a.setAmplitude(1, readLevel(1));
    a.setAmplitude(2, heatLevel);
    a.setOutput(1, 1);
    a.setOutput(2, 1);
    pause(0.5);
    a.sync(2);
    pause(0.1);
    %keyboard
    for j = 1:numel(readLevel)
        a.setAmplitude(1, readLevel(j));
        s.trigger('normal')
        pause(0.05);

        % wait for samples
        s.clearSweeps();
        pause(0.5);
        fprintf('Acquiring please stand by.')
        while (s.getNumSweeps('F1') < numSamplesPerRun)
            pause(0.5);
            fprintf('.');
        end
        fprintf('\n');
        pause(0.5);

        % Get acq
        s.trigger('stop')
        disp('Getting F1')
        waveF1 = s.getWaveform('F1');
        params = s.getTrendData('F1');
        results(i,j,:) = params.vOffset + params.vStepSize*waveF1.y(1:numSamplesPerRun);
        s.trigger('normal')
    end
    a.setOutput(1, 0);
    a.setOutput(2, 0);
end
%%
figure(100)
imagesc(readLevel*1e3,delays*1e9, mean(results,3))
ylabel('Delays (ns)')
xlabel('Read Level (mV)')