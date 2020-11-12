%% Hardware Control Startup Script
clear all
close all
%%
lock=lockin;
awg=waveformGenerator;
sh=shutter;
yoko=yokogawa;
power=pm100USB();
instruments.scope = scopeV2('18.25.27.45');
% instruments.scope = scope('qnn-scope1.mit.edu');

instruments.scope.set_orizontal_scale(1,-5)
instruments.scope.set_vertical_scale('C1',3,0)

instruments.scope.set_trigger_mode('Single') 
instruments.scope.set_trigger('Ext/10', 1, 'Positive')
cep=cepControl;
%%
masterControl=SamplerApp(sh,lock,awg,instruments,yoko,cep,power);