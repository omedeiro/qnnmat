classdef cepControl < handle
    properties
        gpib
        cep
    end
    methods
        function obj = cepControl()
            %% Instrument Connection
            
            % Find a GPIB object.
            obj.gpib = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', 12, 'Tag', '');
            
            % Create the GPIB object if it does not exist
            % otherwise use the object that was found.
            if isempty(obj.gpib)
                obj.gpib = gpib('NI', 0, 12);
            else
                fclose(obj.gpib);
                obj.gpib = obj.gpib(1);
            end
            
            % Connect to instrument object, obj1.
            fopen(obj.gpib);
            
            %% Instrument Configuration and Control
            % Communicating with instrument object, obj1.
            fprintf(obj.gpib, 'PHAS 0');
            obj.cep=0;
            
            
        end
        function set.cep(obj,value)
        % values in radian
        fprintf(obj.gpib,'PHAS %i',(360/(2*pi))*value);
        obj.cep=value;
        end
        
        
        function delete(obj)
            %% Disconnect and Clean Up
            
            % Disconnect from instrument object, obj1.
            fclose(obj.gpib);
        end
        
    end
end