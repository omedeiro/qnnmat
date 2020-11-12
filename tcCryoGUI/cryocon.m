classdef cryocon
    %cryocon Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        visa
    end
    
    methods
        function obj = cryocon()
            obj.visa = instrfind('Type', 'visa-gpib', 'RsrcName', 'GPIB0::4::INSTR', 'Tag', '');
            % Create the VISA-GPIB object if it does not exist
            % otherwise use the object that was found.
            if isempty(obj.visa)
                obj.visa = visa('NI', 'GPIB0::4::INSTR');
            else
                fclose(obj.visa);
                obj.visa = obj.visa(1);
            end

            % Connect to instrument object, obj1.
            fopen(obj.visa);
        end
        
        function delete(obj)
            fclose(obj.visa);
        end
        
        function temp = read_temp(obj,channel)
            temp = str2double(query(obj.visa, strcat(":INPUT? ",channel,':TEMP')));
        end


        function setup_heater(obj, load, range, source_channel)
            fprintf(obj.visa,"LOOP 1:SETPT 10");
            fprintf(obj.visa,strcat("LOOP 1:LOAD ", num2str(load)));
            fprintf(obj.visa,strcat("LOOP 1:RANGE ", num2str(range)));
            fprintf(obj.visa,strcat("LOOP 1:SOUR CH",source_channel));
            fprintf(obj.visa,"LOOP 1:TYPE OFF");  % Default to off in case of trouble
            fprintf(obj.visa,"LOOP 1:PMAN 0");  % Default to zero manual power in case of trouble
            % Range can be 50W, 5.0W, 0.5W and 0.05W
            % or for 25ohm load 25W, 2.5W, 0.3W and 0.03W
        end

        function set_pid(obj, P, I, D)
            fprintf(obj.visa,strcat("LOOP 1:PGAIN ",num2str(P)));
            fprintf(obj.visa,strcat("LOOP 1:IGAIN ",num2str(I)));
            fprintf(obj.visa,strcat("LOOP 1:DGAIN ",num2str(D)));
        end

        function set_setpoint(obj, setpoint)
            fprintf(obj.visa,strcat("LOOP 1:SETPT ",num2str(setpoint)));
            disp(strcat("- Changing heater setpoint to ",num2str(setpoint), 'K'))
            pause(1)
        end

        function set_control_type_rampp(obj, ramp_rate)
            %Ramps at a rate of ramp_rate kelvin per minute using PID control%
            fprintf(obj.visa,"LOOP 1:TYPE RAMPP");
            ramp_rate_rounded = round(ramp_rate*10,1)/10;
            fprintf(obj.visa,strcat("LOOP 1:RATE ", num2str(ramp_rate_rounded))); % Ramp rate in K/min
        end

        function set_control_type_pid(obj)
            %Goes to setpoint value using PID control%
            fprintf(obj.visa,"LOOP 1:TYPE PID");
        end    

        function start_heater(obj)
            fprintf(obj.visa,"SYSTEM:BEEP 1");
            fprintf(obj.visa,"CONTROL");
        end

        function stop_heater(obj)
            fprintf(obj.visa,"STOP");
            fprintf(obj.visa,"SYSTEM:BEEP 1");
            pause(0.5)
        end

        function heat_up(obj, load, range, source_channel, setpoint)
            fprintf(obj.visa,strcat("LOOP 1:SETPT ", num2str(setpoint)));
            fprintf(obj.visa,strcat("LOOP 1:LOAD ",num2str(load)));
            fprintf(obj.visa,strcat("LOOP 1:RANGE ", range));
            fprintf(obj.visa,strcat("LOOP 1:SOUR CH",source_channel));
            fprintf(obj.visa,"LOOP 1:TYPE Rampp");  % Default to off in case of trouble
            fprintf(obj.visa,"LOOP 1:PMAN 10");
            obj.start_heater()
        end
    
    end
end

