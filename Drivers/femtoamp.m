classdef femtoamp
    %AWG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        inst
    end
    
    methods
        function obj = femtoamp(Address)
            if ~exist('Address')
                Address = 'Uno';
            end
            
            obj.inst = arduino('COM3', Address);
%             obj.clearErrors();
        end
        
        function setGain(obj, gain)
            gain_binary = de2bi(gain-4,4);
            writeDigitalPin(obj.inst, 'D10', gain_binary(1));
            writeDigitalPin(obj.inst, 'D11', gain_binary(2));
            writeDigitalPin(obj.inst, 'D12', gain_binary(3));
            writeDigitalPin(obj.inst, 'D13', gain_binary(4));
        end
%         
        function result = readAnalogVoltage(obj, pin)
            result = readVoltage(obj.inst,pin);
        end
%         
%         function setOutput(obj, chan, enabled)
%             opt = {'OFF','ON'};
%             obj.inst.send(['OUTPUT' num2str(chan) ' ' opt{enabled+1}]);
%             obj.clearErrors();
%         end
%         
%         function setSampleRate(obj, chan, sampleRate)
%             obj.inst.send(['SOURCE' num2str(chan) ':FUNCtion:ARB:SRATe ' num2str(sampleRate)]); %create sample rate command
%             obj.clearErrors();
%         end
%         
%         function sync(obj, chan)
%             obj.inst.send(['SOURCE' num2str(chan) ':FUNCtion:ARBitrary:SYNChronize']);
%             obj.clearErrors();
%         end
%         
%         function sendWaveform(obj, chan, waveform, sampleRate, name)
%             %create waitbar for sending waveform to 33500
%             %mes = ['Connected to instrument, sending waveforms.....'];
%             %h = waitbar(0,mes);
%             obj.setOutput(chan, 0);
%             
%             %Set buffer size
%             bufferLength = length(waveform)*8+125;
%             obj.inst.setBufferSize(bufferLength);
% 
%             %Reset instrument
%             %obj.inst.send('*RST');
% 
%             %make sure waveform data is a row vector
%             waveform = waveform(:)';
% 
%             %set the waveform data to single precision
%             waveform = single(waveform);
% 
%             %scale data between 1 and -1
%             mx = max(abs(waveform));
%             waveform = (1*waveform)/mx;
% 
%             %update waitbar
%             %waitbar(.1,h,mes);
% 
%             %send waveform to 33500
%             obj.inst.send(['SOURce' num2str(chan) ':DATA:VOLatile:CLEar']); %Clear volatile memory
%             obj.inst.send('FORM:BORD SWAP');  %configure the box to correctly accept the binary arb points
%             arbBytes=num2str(length(waveform) * 4); %# of bytes
%             header = ['SOURce' num2str(chan) ':DATA:ARBitrary ' name ', #' num2str(length(arbBytes)) arbBytes]; %create header
%             binblockBytes = typecast(waveform, 'uint8');  %convert datapoints to binary before sending
%             fwrite(obj.inst.handle, [header binblockBytes], 'uint8');
%             obj.inst.send( '*WAI');   %Make sure no other commands are exectued until arb is done downloadin
%             %update waitbar
%             %waitbar(.8,h,mes);
%             %Set desired configuration for channel 1
%             command = ['SOURce' num2str(chan) ':FUNCtion:ARBitrary ' name];
%             %fprintf(fgen,'SOURce1:FUNCtion:ARBitrary GPETE'); % set current arb waveform to defined arb testrise
%             obj.inst.send(command); % set current arb waveform to defined arb testrise
%             command = ['MMEM:STOR:DATA' num2str(chan) ' "INT:\' name '.arb"'];
%             %fprintf(fgen,'MMEM:STOR:DATA1 "INT:\GPETE.arb"');%store arb in intermal NV memory
%             obj.inst.send(command);
%             %update waitbar
%             %waitbar(.9,h,mes);
%             obj.setSampleRate(chan,sampleRate);
%             obj.inst.send(['SOURce' num2str(chan) ':FUNCtion ARB']); % turn on arb function
% 
%             %obj.console()
%             fprintf(['Arb waveform downloaded to channel ' num2str(chan) '\n\n']) %print waveform has been downloaded
% 
%             %get rid of message box
%             %waitbar(1,h,mes);
%             %delete(h);
%             obj.setAmplitude(chan, mx);
%             obj.setOutput(chan, 1);
% 
%             %Read Error
%             obj.inst.send('SYST:ERR?');
%             errorstr = obj.inst.read();
% 
%             % error checking
%             if strncmp (errorstr, '+0,"No error"',13)
%                errorcheck = 'Arbitrary waveform generated without any error\n';
%                fprintf (errorcheck)
%             else
%                errorcheck = ['Error reported: ', errorstr];
%                fprintf (errorcheck)
%             end
%             
%             obj.clearErrors();
%         end
%         
%         function clearErrors(obj)
%             error = 1;
%             while error
%                 obj.inst.send('SYST:ERR?');
%                 errorstr = obj.inst.read();
% 
%                 % error checking
%                 if strncmp (errorstr, '+0,"No error"',13)
%                     error = 0;
%                 else
%                    errorcheck = ['Error reported: ', errorstr];
%                    fprintf (errorcheck)
%                 end
%             end
%         end
        
    end
    
end
