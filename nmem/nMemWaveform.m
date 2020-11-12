%% New fast pulses with low-duty

function [heaterWave, channelWave] = nMemWaveform(readLevel, writeLevel, heatLevel, ChannelWidth, HeatWidth, readDelay, CycleDelay, HoldOff, sampleRate)
% OP|   W1    R    W0   R
%  H|____^____^____^____^_____
%   |    _    _         _
%  C|___| |__| |__   __| |____
%                 |_|

% Convert times to integers
chanWid = ceil(ChannelWidth*sampleRate);
heatWid = ceil(HeatWidth*sampleRate);
readDel = ceil(readDelay*sampleRate);
cycDel = ceil(CycleDelay*sampleRate);
hldOff = ceil(HoldOff*sampleRate);

numSamples = chanWid*4+readDel*2+cycDel+hldOff+100;
if(chanWid>heatWid)
   chanToHeatDel = ceil((chanWid - heatWid)/4)+100;
   heatToChanDel = 0+100;
else
   chanToHeatDel = 0+100;
   heatToChanDel = ceil(-(chanWid - heatWid)/4)+100;
end
heaterWave = zeros(1,numSamples);
channelWave = zeros(1,numSamples);

%% write 1
channelWave(heatToChanDel+(1:chanWid)) = writeLevel;
heaterWave(chanToHeatDel + (1:heatWid)) = heatLevel;
%% read
channelWave(chanWid+readDel + heatToChanDel+(1:chanWid)) = readLevel;
heaterWave(chanWid+readDel+chanToHeatDel + (1:heatWid)) = heatLevel;

%% write 0
channelWave(chanWid+readDel+chanWid+cycDel + heatToChanDel+(1:chanWid)) = -writeLevel;
heaterWave(chanWid+readDel+chanWid+cycDel+chanToHeatDel + (1:heatWid)) = heatLevel;

%% read
channelWave(chanWid+readDel+chanWid+cycDel+chanWid+readDel + heatToChanDel+(1:chanWid)) = readLevel;
heaterWave(chanWid+readDel+chanWid+cycDel+chanWid+readDel+chanToHeatDel + (1:heatWid)) = heatLevel;

end






%% Original slow measurments
% function [heaterWave, channelWave] = nMemWaveform(readLevel, writeLevel, heatLevel, length)
% % OP|   W1    R    W0   R
% %  H|____^____^____^____^_____
% %   |    _    _         _
% %  C|___| |__| |__   __| |____
% %                 |_|
% 
% 
% numFrames = 25;
% numSamplesPerFrame = ceil(length/numFrames);
% 
% heaterWave = zeros(1,numFrames*numSamplesPerFrame);
% channelWave = zeros(1,numFrames*numSamplesPerFrame);
% 
% %% write 1
% channelWave(4*numSamplesPerFrame:(4+3)*numSamplesPerFrame) = writeLevel;
% heaterWave(5*numSamplesPerFrame:6*numSamplesPerFrame) = heatLevel;
% 
% %% read
% channelWave((5+4)*numSamplesPerFrame:(5+4+3)*numSamplesPerFrame) = readLevel;
% heaterWave((5+5)*numSamplesPerFrame:(5+6)*numSamplesPerFrame) = heatLevel;
% 
% %% write 0
% channelWave((2*5+4)*numSamplesPerFrame:(2*5+4+3)*numSamplesPerFrame) = -writeLevel;
% heaterWave((2*5+5)*numSamplesPerFrame:(2*5+6)*numSamplesPerFrame) = heatLevel;
% 
% %% read
% channelWave((3*5+4)*numSamplesPerFrame:(3*5+4+3)*numSamplesPerFrame) = readLevel;
% heaterWave((3*5+5)*numSamplesPerFrame:(3*5+6)*numSamplesPerFrame) = heatLevel;
% 
% end