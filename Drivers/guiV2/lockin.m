classdef lockin < handle % Lockin hardware object class
    properties
        integrationTime
        samplingRate
        timeConstant
        Sensitivity
        IE488
        dataPointsAvailable
        dataBuffer
        snapShot
        frequency
        
        
    end
    
    properties (SetAccess=private)
        integrationTimeList=cellstr({'10us';'30us';'100us';'300us';'1ms';'3ms';'10ms';'30ms';'100ms';'300ms';'1s';'3s';'10s';'30s';'100s';'300s';'1ks';'3ks';'10ks';'30ks'});
        samplingRateList=[0.0625,0.125,0.25,0.5,1,2,4,8,16,32,64,128,256,512,0];
        sensitivityList=cellstr({'2nV','5nV','10nV','20nV','50nV','100nV','200nV','500nV','1uV','2uV','5uV','10uV','20uV','50uV','100uV','200uV','500uV','1mV','2mV','5mV','10mV','20mV','50mV','100mV','200mV','500mV','1V'})
        
    end
    
    
    methods
        function obj=lockin() %Constructor Method
            
            
            % Find a GPIB object.
            obj.IE488 = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', 2, 'Tag', '');
            % Create the GPIB object if it does not exist
            % otherwise use the object that was found.
            if isempty(obj.IE488)
                obj.IE488= gpib('NI', 0, 2);
            else
                fclose(obj.IE488);
                obj.IE488= obj.IE488(1);
            end
            % Connect to instrument object, obj.
            obj.IE488.EOSCharCode = char(13);
            obj.IE488.EOSMode = 'write';
            obj.IE488.EOIMode = 'off';
            obj.IE488.OutputBufferSize=100000000;
            obj.IE488.InputBufferSize =100000000;
            obj.IE488.Timeout = 10;
            fopen(obj.IE488);
            fprintf(obj.IE488, 'FMOD 0'); % 0 auf externe Referenz Stellen, 1 wäre interne Referenz frequenz
            fprintf(obj.IE488, 'RSLP 1'); %Rising edge trigger (0= sin,2 =falling)
         %   fprintf(obj.IE488, 'FREQ 532');
            fprintf(obj.IE488, 'ISRC 0'); %Setzt auf Spannungseingang
            fprintf(obj.IE488, 'IGND 0'); %Setzt auf Float GND (1 wäre GND)
            fprintf(obj.IE488, 'ICPL 0'); % AC input coupling
            fprintf(obj.IE488, 'RMOD 0'); % Reserve to low, low noise 0 wäre high reserve
            fprintf(obj.IE488, 'SEND 0'); % End of buffer mode 0 = 1shot
            fprintf(obj.IE488, 'DDEF 1, 0, 0'); % channel 1 als x-wert
            fprintf(obj.IE488, 'DDEF 2, 0, 0'); % channel 1 als y-wert
            fprintf(obj.IE488, 'OFSL 1'); % Filter auf 12 dB (1)
            fprintf(obj.IE488, 'SRAT 10')  % Setzt sample rate auf 64 Hz, 14 wäre trigger... kann auch softwaremäßig getriggert werden
            a=2;
            while(a ~=(1))  %Warte bis Lock-In Initialisiert ist
                a=str2num(query(obj.IE488, '*STB?'));
                pause(1);
            end
            
            obj.setFrequency(112.5);
        end
        
        function delete(obj)
            fclose(obj.IE488);
        end
        
        function setIntegrationTime(obj,inttime)
            fprintf(obj.IE488,['OFLT ',num2str(inttime-1)]);
        end
        
        function setSensitivity(obj,index);
            fprintf(obj.IE488,['SENS ',num2str(index-1)]);
        end
        
        function out = get.integrationTime(obj)
            fprintf(obj.IE488,'OFLT ?');
            formatStr=strcat('%i\n');
            val(1)= (fscanf(obj.IE488,formatStr));
                 val=obj.integrationTimeList(val(1)+1);
                 out=val{1}
        end
        
        function out = get.Sensitivity(obj)
                        fprintf(obj.IE488,'SENS ?');
                         formatStr=strcat('%i\n');
                val(1)= (fscanf(obj.IE488,formatStr));
                 val=obj.sensitivityList(val(1)+1);
                 out=val{1};
            end
        
        
        function setFrequency(obj,frequency)
            fprintf(obj.IE488,['FREQ ',num2str(frequency)]);
        end
        
        function out = get.frequency(obj)
            fprintf(obj.IE488,'FREQ ?');
          %  formatStr=strcat('%i\n');
           out = str2num(fscanf(obj.IE488));
            disp(out);
            
        end
        
        function out = get.samplingRate(obj)
            fprintf(obj.IE488,'SRAT ?');
            formatStr=strcat('%i\n');
            out(1)= (fscanf(obj.IE488,formatStr));
            disp([num2str(obj.samplingRateList(out+1)),' Hz']);
            
        end
        
        function setSamplingRate(obj,srate)
            fprintf(obj.IE488,['SRAT  ',num2str(srate)]);
        end
        
        function out = get.snapShot(obj)
            fprintf(obj.IE488,'SNAP?1,2,3');
            out = str2num(fscanf(obj.IE488));
        end
        
        function startRecording(obj,srate)
            fprintf(obj.IE488,'STRT');
        end
        
        function stopRecording(obj,srate)
            fprintf(obj.IE488,'PAUS');
        end
        
        function reset(obj,srate)
            fprintf(obj.IE488,'REST');
        end
        
        function out = get.dataPointsAvailable(obj)
            fprintf(obj.IE488,'SPTS ?');
            formatStr=strcat('%i\n');
            out = (fscanf(obj.IE488,formatStr));
        end
        
        function out = get.dataBuffer(obj)
           dp= obj.dataPointsAvailable;
            fprintf(obj.IE488,['TRCA? 1,0,',num2str(dp)]);
            out(:,1) = str2num(fscanf(obj.IE488));
            fprintf(obj.IE488,['TRCA? 2,0,',num2str(dp)]);
            out(:,2) = str2num(fscanf(obj.IE488));
            out(:,3) = (0:dp-1)/obj.samplingRateList(obj.samplingRate+1);
        end
        
        function setAuxOut(obj,channel,voltage)
            fprintf(obj.IE488, ['AUXV ',num2str(channel),', ',num2str(voltage)]);
        end
        
        function out = getAuxOut(obj,channel)
            out=str2num(query(obj.IE488, ['AUXV? ',num2str(channel)]));
        end
        
        function out = getAuxIn(obj,channel)
            out=str2num(query(obj.IE488, ['OAUX? ',num2str(channel)]));
        end
        
    end
end
