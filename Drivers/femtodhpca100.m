classdef femtodhpca100
    %Arduino controlled femtoamplifier dhpca100
    
    properties
        inst
    end
    
    methods
        function obj = femtodhpca100(Address)
            if ~exist('Address')
                Address = 'COM7';
            end
            
            obj.inst = arduino(Address, 'Uno');
        end
        
        function setMode(obj,mode)
            if strcmp(mode,'LOW')
                writeDigitalPin(obj.inst, 'D13', 0);
            else
                writeDigitalPin(obj.inst, 'D13', 1);
            end
        end
        
        function setCoupling(obj,coupling)
            if strcmp(coupling,'DC')
                writeDigitalPin(obj.inst, 'D9', 0);
            else
                writeDigitalPin(obj.inst, 'D9', 1);
            end
        end
        
        function overload = readOverload(obj)
            overload = readDigitalPin(obj.inst, 'D5');
        end
        
        function setGain(obj, gain, mode)
            if strcmp(mode,'LOW')
                writeDigitalPin(obj.inst, 'D13', 0);
                gain_binary = de2bi(gain-2,3);
                writeDigitalPin(obj.inst, 'D10', gain_binary(1));
                writeDigitalPin(obj.inst, 'D11', gain_binary(2));
                writeDigitalPin(obj.inst, 'D12', gain_binary(3));
            else
                writeDigitalPin(obj.inst, 'D13', 1);
                gain_binary = de2bi(gain-3,3);
                writeDigitalPin(obj.inst, 'D10', gain_binary(1));
                writeDigitalPin(obj.inst, 'D11', gain_binary(2));
                writeDigitalPin(obj.inst, 'D12', gain_binary(3));
            end
            
            
        end
        
        function result = readAnalogVoltage(obj, pin)
            result = readVoltage(obj.inst,pin);
        end
        
    end
    
end
