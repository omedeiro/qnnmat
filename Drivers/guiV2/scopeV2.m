classdef scopeV2
    %SCOPE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        interface
    end
    
    methods
        
        function obj = scopeV2(ip)
            if ~exist('ip')
                ip = 'qnn-scope1.mit.edu';
            end
            obj.interface = visa('ni', ['TCPIP::' ip '::INSTR']);
            obj.interface.InputBufferSize = 65536;
            fopen(obj.interface);
            
            obj.write('COMM_HEADER OFF')            % Don't use the header
            obj.write('COMM_FORMAT DEF9,WORD,BIN'); % Set to 16bis
        end
        
        function write(obj, command)
            fwrite(obj.interface, command);
        end
        
        function result = read(obj)
            [result,~,~] = fread(obj.interface);
        end
        
        function result = rawRead(obj)
            [result,n,~] = fread(obj.interface, obj.interface.InputBufferSize/2,'uint16');
            while n ~= 0;
                [lastResult,n,~] = fread(obj.interface, obj.interface.InputBufferSize/2,'uint16');
                result = [result; lastResult];
            end
            %result = binblockread(obj.interface);
            %result = fread(obj.interface,obj.interface.BytesAvailable,'uint16');
        end
        
        function beep (obj)
            obj.write('BUXX BEEP');
        end
        
        function wave = getWaveform (obj, channel)
            
            wave.x=[];
            wave.y=[];
            wave.offset=0;
            wave.gain=1;
            
            ADDR_VGAIN = 156+1;
            ADDR_VOFFSET = 160+1;
            ADDR_HINTERVAL = 176+1;
            ADDR_HOFFSET = 180+1;
            %readasync(obj.interface);
            flushinput(obj.interface);
            obj.write([channel ':WAVEFORM? DAT1']);
            %keyboard
            %disp('starting read')
            databytes = obj.rawRead();
            %disp('finished read')
            %keyboard
            databytes = databytes(17:end);  % remove header
            if numel(databytes) == 0
                return
            end
            if mod(numel(databytes),2) == 1 % Sometimes accidentally returns an extra byte
                databytes = databytes(1:end-1);
            end
            
            isNegative = int16(bitget(databytes, 16));
            data=single(int16(bitset(databytes, 16, 0))+(-2^16)*isNegative);%single(typecast(uint16(databytes),'int16'));
            %data = single(typecast(uint16(databytes)','int16'));
            flushinput(obj.interface);
            fwrite(obj.interface, [channel ':WAVEFORM? DESC'])
            [desc,~,~] = fread(obj.interface);%obj.rawRead();
            desc = desc(17:end);  % remove header
            vgain = typecast(typecast(uint8((desc(ADDR_VGAIN:ADDR_VGAIN+3))), 'uint32'),'single');
            voffset = typecast(typecast(uint8((desc(ADDR_VOFFSET:ADDR_VOFFSET+3))), 'uint32'),'single');
            hinterval = typecast(typecast(uint8((desc(ADDR_HINTERVAL:ADDR_HINTERVAL+3))), 'uint32'),'single');
            hoffset = typecast(typecast(uint8((desc(ADDR_HOFFSET:ADDR_HOFFSET+7))), 'uint32'),'double');
            num_samples = numel(databytes);
            wave.x = (1:num_samples)*hinterval + hoffset;
            wave.y = data.*vgain - voffset;
            wave.offset = voffset;
            wave.gain = vgain;
        end
        
        function clearSweeps (obj)
            obj.write('VBS ''app.ClearSweeps''');
        end
        
        function set_trigger(obj, source, volt_level, slope)
            %Slope should be "Either" / "Negative" / "Positive"
            obj.write(['VBS ''app.Acquisition.Trigger.Source = "' source '"']);
            obj.write(['VBS ''app.Acquisition.Trigger.' source '.Level = ' num2str(volt_level, '%.4e') '']);
            obj.write(['VBS ''app.Acquisition.Trigger.' source '.Slope = "' slope '"''']);
        end
        
        function set_trigger_mode(obj, mode)
            %trigger_mode should be set to Auto/Normal/Single/Stop
            obj.write(['VBS ''app.Acquisition.TriggerMode = "' mode '"']);
        end
        
        function set_orizontal_scale(obj, time_per_div,time_offset)
            obj.write(['VBS ''app.Acquisition.Horizontal.HorScale = ' num2str(time_per_div, '%.6e') ]);
            obj.write(['VBS ''app.Acquisition.Horizontal.HorOffset = ' num2str(time_offset, '%.6e') ]);
            
        end
        
        function set_vertical_scale(obj, channel, volt_per_div,volt_offset)
            volt_per_div_str = num2str(volt_per_div, '%.0e');
            a = volt_per_div_str(1);
            b = volt_per_div_str(2:end);
            a_num = str2num(a);
            if a_num <= 1
                a = '1';
            elseif a_num <= 2
                a = '2';
            elseif a_num <= 5
                a = '5';
            else
                a= '10';
            end
            volt_per_div = str2num([a,b]);
            
            obj.write(['VBS ''app.Acquisition.' channel '.VerScale = ' num2str(volt_per_div, '%.0e') ]);
            obj.write(['VBS ''app.Acquisition.' channel '.VerOffset = ' num2str(volt_offset, '%.0e') ]);
            
        end
        function numSweeps = getNumSweeps (obj, channel)
            flushinput(obj.interface);
            obj.write(['VBS? ''return = app.Math.' channel '.Out.Result.Sweeps''']);
            numSweeps = str2num(char(obj.read()'));
        end
        
        function delete (obj)
            %fclose(obj.interface);
        end
    end
    
    
    
    
    
    
    
    
    
    
end

