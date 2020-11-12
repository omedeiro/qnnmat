

%% New fast pulses with low-duty
function [heaterWave, channelWave] = nMemWaveform(readLevel, writeLevel, heatLevel, ChannelWidth, HeatWidth, readDelay, CycleDelay, HoldOff, sampleRate)
% OP|   W1  w0   r   R   W0  w1  r   R
%  H|____^___________^___^___________^_____
%   |    _       _   _       _   _   _
%  C|___| |_   _| |_| |_   _| |_| |_| |____
%           |_|         |_|

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
%% write 0 - no heat
channelWave(lastTime + readDel + heatToChanDel+(1:chanWid)) = -writeLevel;
lastTime = lastTime + readDel + heatToChanDel + chanWid;
%% read - no heat
channelWave(lastTime + readDel + heatToChanDel+(1:chanWid)) = readLevel;
lastTime = lastTime + readDel + heatToChanDel + chanWid;
%% read
channelWave(lastTime + readDel + heatToChanDel+(1:chanWid)) = readLevel;
heaterWave(lastTime + readDel + chanToHeatDel + (1:heatWid)) = heatLevel;
lastTime = lastTime + readDel + max(heatToChanDel + chanWid, chanToHeatDel+heatWid);


%% write 0
channelWave(lastTime+cycDel + heatToChanDel+(1:chanWid)) = -writeLevel;
heaterWave(lastTime+cycDel+chanToHeatDel + (1:heatWid)) = heatLevel;
lastTime = lastTime + cycDel + max(heatToChanDel+chanWid, chanToHeatDel+heatWid);
%% write 1 - no heat
channelWave(lastTime + readDel + heatToChanDel+(1:chanWid)) = writeLevel;
lastTime = lastTime + readDel + heatToChanDel + chanWid;
%% read - no heat
channelWave(lastTime+readDel + heatToChanDel+(1:chanWid)) = readLevel;
lastTime = lastTime + readDel + heatToChanDel + chanWid;
%% read
channelWave(lastTime+readDel + heatToChanDel+(1:chanWid)) = readLevel;
heaterWave(lastTime+readDel+chanToHeatDel + (1:heatWid)) = heatLevel;

end
