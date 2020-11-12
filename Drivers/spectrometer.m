classdef spectrometer
    
    properties
        inst
    end
    
    methods
        function obj = spectrometer(GPIB)
            if ~exist('GPIB')
                GPIB = 7;
            end
            
            obj1 = instrfind('Type', 'gpib', 'BoardIndex', 0, 'PrimaryAddress', GPIB, 'Tag', '');
            
            if isempty(obj1)
                obj.inst=gpib('ni',0,GPIB);
            else
                fclose(obj1);
                obj.inst = obj1(1);
            end
            
            set(obj.inst,'InputBufferSize',8*20001);              % Standard is 512 ASCII signs that transfers
            set(obj.inst,'Timeout',30);
            fopen(obj.inst);
        end
        
        function [wavelength, level] = acquireSweep(obj, trace)
            query(obj.inst,'SGL');
            pause(30)
            disp('Retreiving Wavelength...')
            wave=str2num(query(obj.inst,['WDAT' trace ]));        %Acquires wavelength data
            disp('Retreiving Level...')
            value=str2num(query(obj.inst,['LDAT' trace ]));       %Acquires level data
            wavelength=wave(2:end);                            %Crops out relevant data
            level=value(2:end);
            
            %              obj.clearErrors();  %%DOESNT WORK
            return
        end
        
        function setStart(obj, wl)
            query(obj.inst,['STAWL' num2str(wl)]); %create start wavelength command
            %             obj.clearErrors();
        end
        
        function setStop(obj, wl)
            query(obj.inst,['STPWL' num2str(wl)]); %create stop wavelength command
            %             obj.clearErrors();
        end
        
        function setCenter(obj, wl)
            query(obj.inst,['CTRWL' num2str(wl)]); %create center wavelength command
            %             obj.clearErrors();
        end
        
        function setSpan(obj, wl)
            query(obj.inst,['SPAN' num2str(wl)]); %create span command
            %             obj.clearErrors();
        end
        
        function setReference(obj, ref)
            query(obj.inst,['REFL' num2str(ref)]); %create reference command
            %             obj.clearErrors();
        end
        
        function setLevelScale(obj, scale)
            query(obj.inst,['LSCL' num2str(scale)]); %create level scale command
            %             obj.clearErrors();
        end
        
        function setResolution(obj, res)
            query(obj.inst,['RESLN' num2str(res)]); %create resolution command
            %             obj.clearErrors();
        end
        
        function setSamplingPoint(obj, smp)
            query(obj.inst,['SMPL' num2str(smp)]);
            %             obj.clearErrors();
        end
        
        function setAverage(obj, avg)
            query(obj.inst,['AVG' num2str(avg)]);
            %             obj.clearErrors();
        end
        
        function closeConnection(obj)
            fclose(obj.inst);                                        % Close connection to GPIB
            set(obj.inst,'InputBufferSize',512);                     % Resets InputBufferSize
        end
        
        function clearErrors(obj)
            error = 1;
            while error
                errorstr = query(obj.inst,'WARN?');
                
                % error checking
                if strncmp (errorstr, '0,"No error"',12)
                    error = 0;
                else
                    errorcheck = ['Error reported: ', errorstr];
                    fprintf (errorcheck)
                end
            end
        end
        
    end
    
end

