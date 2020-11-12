%% SCOPE test
%%clear
%%close all
%%clc

instruments.scope = scope('18.25.28.104');
% instruments.scope = scope('qnn-scope1.mit.edu');

instruments.scope.set_orizontal_scale(1,-5)
instruments.scope.set_vertical_scale('C1',3,0)

instruments.scope.set_trigger_mode('Single') 
instruments.scope.set_trigger('Ext/10', 1, 'Positive')
%%
wave = instruments.scope.getWaveform('C1');
wave2=instruments.scope.getWaveform('C2');
figure()
plot(wave.x,wave.y,wave2.x,wave2.y)
