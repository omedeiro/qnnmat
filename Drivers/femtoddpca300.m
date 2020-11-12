classdef femtoddpca300
    %Arduino controlled femtoamplifier ddpca300
    
    properties
        inst
    end
    
    methods
        function obj = femtoddpca300(Address)
            if ~exist('Address')
                Address = 'COM3';
            end
            
            obj.inst = arduino(Address, 'Uno');
        end
        
        function setGain(obj, gain)
            gain_binary = de2bi(gain-4,4);
            writeDigitalPin(obj.inst, 'D10', gain_binary(1));
            writeDigitalPin(obj.inst, 'D11', gain_binary(2));
            writeDigitalPin(obj.inst, 'D12', gain_binary(3));
            writeDigitalPin(obj.inst, 'D13', gain_binary(4));
        end
        
        function result = readAnalogVoltage(obj, pin)
            result = readVoltage(obj.inst,pin);
        end

    end
    
end
