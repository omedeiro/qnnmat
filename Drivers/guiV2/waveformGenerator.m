classdef waveformGenerator < handle
    properties
        gpibObj
        frqz
        vpp
        offset
    end
    methods
        function obj=waveformGenerator()
            %% Instrument Connection
            
            % Find a GPIB object.
            obj.gpibObj = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', 1, 'Tag', '');
            %Primary Address is set by Device!
            % Create the GPIB object if it does not exist
            % otherwise use the object that was found.
            if isempty(obj.gpibObj)
                obj.gpibObj = gpib('NI', 0, 1);
            else
                fclose(obj.gpibObj);
                obj.gpibObj = obj.gpibObj(1);
            end
            
            % Connect to instrument object, obj1.
            fopen(obj.gpibObj);
            %% Setup Routine for Experiment. Change in later version to be more arbitrary
            obj.write('FUNC RAMP');
            obj.frqz=1;
            obj.write('OUTP:SYNC ON');
            obj.write('VOLT 4.7');
            obj.write('VOLT:OFFS 2.5');
            obj.write('FUNC:RAMP:SYMM 100');
            % Set Burst Mode
            obj.write('BURS:STAT ON');
            obj.write('BURS:MODE TRIG');
            obj.write('TRIG:SOUR BUS');
            obj.write('BURS:NCYC 1');
            obj.write('BURS:PHAS 181');
        end
        function trigger(obj)
        obj.write('TRIG');
        end
        function set.frqz(obj,value)
        fprintf(obj.gpibObj,'FREQ %i',value);
        obj.frqz=value;
        end
%         function out=get.frqz()
%         out=query('FREQ?');
%         end
        function out=query(obj,inString) % Overloading the query function for this AWG object
            obj.write(inString);
            pause(0.1);
            out=obj.read();
        end
        
        function write(obj,inString)
            fprintf(obj.gpibObj,inString);
        end
        function out=read(obj)
            out=fscanf(obj.gpibObj);
        end
        
        function delete(obj)
        fclose(obj.gpibObj);
        end
        
    end
end