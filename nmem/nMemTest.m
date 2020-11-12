% nMem optimizer main program
%
% We are assuming a symmetric read
% current is applied to channel then the heaters is pulsed for both reading
% and writing to the memory.
%% clear and close all
clear;
close all;
clc;
% Initialization
instruments.awg = awg();
instruments.scope = scope();

%
    sampleRate = 1000e6;
    numSamplesPerBER = 1000;
    %%
    [heaterWave, channelWave] = nMemWaveform(0.012,0.010, 3.1, 20e-9, 10e-9, 100e-9, 100e-9, 10e-6, sampleRate);
    
    % Download waveforms
    instruments.awg.sendWaveform(1, channelWave, sampleRate, 'chan');
    instruments.awg.sendWaveform(2, heaterWave, sampleRate, 'heat');
    instruments.awg.sync(2);
    instruments.awg.setOutput(1, 1);
    instruments.awg.setOutput(2, 1);
%% Starting values and optimization limits - min and max are not implemented yet
% heater = 0.6885; HT031 values
% heaterMin = 0.5;
% heaterMax = 1.2;
% 
% readLevel = 0.0357;
% readLevelMin = 0.01;
% readLevelMax = 0.041;
% 
% writeLevel = 0.0313;
% writeLevelMin = 0.01;
% writeLevelMax = 0.41;

% % HT028
% heater = 2.0748;
% heaterMin = 0.5;
% heaterMax = 1.2;
% 
% readLevel = 0.0413;
% readLevelMin = 0.01;
% readLevelMax = 0.041;
% 
% writeLevel = 0.0312;
% writeLevelMin = 0.01;
% writeLevelMax = 0.41;

% % HT028
% heater = 2.2720;
% readLevel = 0.0401;
% writeLevel = 0.0292;

% HY028 - out of helim
% heater = 2;
% readLevel = 0.021;
% writeLevel = 0.018;

% HY028
% heater = 5;
% readLevel  = 0.031;
% writeLevel = 0.025;
% offset = 0;

% This gave 0.288% (1k sweeps)
% heater = 1.4119;
% readLevel = 0.0216;
% writeLevel = 0.0245;
% offset = 0;

% This gave 0.020%  (10k sweeps)
% heater = 1.452043;
% readLevel = 0.021503;
% writeLevel = 0.024377;
% offset = 0;

% This gave 0.008%   (100k sweeps)
% heater = 1.456624096418929;
% readLevel = 0.021641908681767;
% writeLevel = 0.024366667701285;
% offset = 0;




% First
% % heater = 0.3225;%0.100;
% % readLevel =  0.0675;%0.058*1.16;%0.0475*1.4;
% % writeLevel = 0.0825;%0.075;%0.0594%*170/200*80/200*70/200;
% % offset = 0;
% % 

% second
% heater = 0.3206;
% readLevel =  0.0674;
% writeLevel = 0.0827;

%third - added 20db attenuator to channel
% heater = 0.3200;
% readLevel =  0.671;
% writeLevel = 0.829;

%fourth - got to zero in 2000
% heater = 0.3179;
% readLevel =  0.6791;
% writeLevel = 0.8124;

%fifth - got to 9.8e-5 in 5k, next added 20db to both (for a total of 40db
%for channel
% heater = 0.3187*10;
% readLevel =  0.6795*10;
% writeLevel = 0.8088*10;
% 
% %sixth
% heater = 3.1992;
% readLevel =  6.8494;
% writeLevel = 8.1766;

%seventh
% heater = 3.5;
% readLevel =  6.8494/1.22;
% writeLevel = 8.1766/1.22;
% 


% New device (old design revised)
% heater = 3.5;
% %readLevel = 3.1;
% writeLevel = 3;



% Single device left
heater = 0.75;
%readLevel = 3.1;
writeLevel = 1;


% 
% heater = 1.7;
% readLevel = 0.0274;
% writeLevel = 0.0294;
% offset = 0;

% initVars = [ ...
%     heater, heaterMin, heaterMax; ...
%     readLevel, readLevelMin, readLevelMax; ...
%     writeLevel, writeLevelMin, writeLevelMax];


initVars = [ ...
    heater, 0, 0; ...
    %readLevel, 0, 0; ...
    writeLevel, 0, 0];% ...
    %offset, 0, 0];
    
nMemCost(initVars(:,1), instruments);
%%
writeLevels = linspace(2,5,201);
cost=[];

for i=1:numel(writeLevels)
writeLevel = writeLevels(i);
initVars = [ ...
    heater, 0, 0; ...
    %readLevel, 0, 0; ...
    writeLevel, 0, 0];% ...
    %offset, 0, 0];
    
cost(i) = nMemCost(initVars(:,1), instruments);
if i>1
figure(1656510);
plot([writeLevels(i-1), writeLevels(i)], [cost(i-1), cost(i)]);
hold on;
end
end
%% Setup Optimizer
op = optimizer(initVars, @nMemCost, @conv, inf, inf, instruments);
op.run(1);

%% Plot projections
heaterValues = op.evalVarHistory(1,:); % (1:3:end);
readValues = op.evalVarHistory(2,:); % (2:3:end);
writeValues = op.evalVarHistory(3,:); % (3:3:end);

figure(200);
start = 1;
scatter3(heaterValues(start:end), readValues(start:end), writeValues(start:end), 1+100*op.evalCostHistory(start:end))
xlabel('Heater Level')
ylabel('Read Level')
zlabel('Write Level')
title('Error rate over parameter space')


