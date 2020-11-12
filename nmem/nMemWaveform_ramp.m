

%% New fast pulses with low-duty
function [heaterWave, channelWave] = nMemWaveform_ramp(writeLevel, heatLevel, ChannelWidth, HeatWidth, readDelay, CycleDelay, HoldOff, sampleRate)
% OP|   W1  R   W0  R
%  H|____^______^________
%   |    _   .       .
%  C|___| |_/|_   __/|___
%              |_|

readLevel = 5;

% Convert times to integers
chanWid = ceil(ChannelWidth*sampleRate);
heatWid = ceil(HeatWidth*sampleRate);
readDel = ceil(readDelay*sampleRate);
cycDel = ceil(CycleDelay*sampleRate);
hldOff = ceil(HoldOff*sampleRate);

numSamples = chanWid*8+readDel*2+cycDel+hldOff;
if(chanWid>heatWid)
   chanToHeatDel = ceil((chanWid - heatWid)/4);
   heatToChanDel = 0;
else
   chanToHeatDel = 0;
   heatToChanDel = ceil(-(chanWid - heatWid)/4);
end
heaterWave = zeros(1,numSamples);
channelWave = zeros(1,numSamples);

%% write 1
channelWave(heatToChanDel+(1:chanWid)) = writeLevel;
heaterWave(chanToHeatDel + (1:heatWid)) = heatLevel;
lastTime = heatToChanDel+chanWid;
%% read
channelWave(lastTime + readDel + heatToChanDel+(1:chanWid*10)) = linspace(0,readLevel,chanWid*10);
heaterWave(lastTime + readDel + chanToHeatDel + (1:chanWid*10)) = heatLevel;
lastTime = lastTime + readDel + max(heatToChanDel + chanWid*10, chanToHeatDel+heatWid);


%% write 0
channelWave(lastTime+cycDel + heatToChanDel+(1:chanWid)) = -writeLevel;
heaterWave(lastTime+cycDel+chanToHeatDel + (1:heatWid)) = heatLevel;
lastTime = lastTime + cycDel + max(heatToChanDel+chanWid, chanToHeatDel+heatWid);
%% read
channelWave(lastTime + readDel + heatToChanDel+(1:chanWid*10)) = linspace(0,readLevel,chanWid*10);
heaterWave(lastTime + readDel + chanToHeatDel + (1:chanWid*10)) = heatLevel;
lastTime = lastTime + readDel + max(heatToChanDel + chanWid*10, chanToHeatDel+heatWid);

heaterWave = [zeros(1,100), heaterWave];
channelWave = [zeros(1,100), channelWave];
end
