classdef pm100USB < handle
    properties
        visaOBJ     % VISA Obj for Communication with the USB device
        wavelength
    end
    methods
        function obj=pm100USB()
            % Do NOT use the Thorlabs driver!!! Use Standard USBTMC (USB
            % Test and Measurement Class)
            
            obj.visaOBJ=instrfind('Name','VISA-USB-0-0x1313-0x8072-PM004112-1');
            if isempty(obj.visaOBJ)==1
                obj.visaOBJ=visa('ni','USB::0x1313::0x8078::PM004112::INSTR');
            end
            fopen(obj.visaOBJ);
            
        end
        function out=measurePower(obj)
            s=query(obj.visaOBJ,'MEAS:POWER?\n');
            out=str2num(s);
            
        end
        
        function setWavelength(obj,value) % wavelength in nm !
            fprintf(obj.visaOBJ,'CORR:WAV %f\n',value)
            obj.wavelength=value;
        end
        
        function out=getWavelength(obj)
            s=query(obj.visaOBJ,'CORR:WAV?\n');
            out=str2num(s);
            obj.wavelength=out;
        end
        
        function delete(obj)
            fclose(obj.visaOBJ);
        end
    end
end