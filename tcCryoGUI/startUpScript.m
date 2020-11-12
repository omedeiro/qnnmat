instrreset
cryocon = visa('ni','GPIB::4::INSTR');

% Make the UD .NET assembly visible in MATLAB.
ljasm = NET.addAssembly('LJUDDotNet');
labjack = LabJack.LabJackUD.LJUD;
