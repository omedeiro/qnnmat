classdef b2902a
    %B2902A SMU Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        inst
        console
    end
    
    methods
        function obj = b2902a(USB_Address)
            if ~exist('USB_Address')
                USB_Address = 'USB0::2391::35864::my51140488::0::INSTR';
            end
            obj.inst = visa('agilent', USB_Address);
            %Set buffer sizes
            set(obj.inst, 'InputBufferSize', 100000);
            set(obj.inst, 'OutputBufferSize', 100000);
            set(obj.inst, 'Timeout', 300.0);
            
            fopen(obj.inst);
            
            fprintf(obj.inst, '*RST'); %Resetting the instrument
            fprintf(obj.inst, 'OUTP1 OFF'); %Turning off channel 1
            fprintf(obj.inst, 'OUTP2 OFF'); %Turning off channel 2
            
        end
        
        
        function data = IV_Sweep(obj,VDS,VGS,PrimVar,trig_delay,NPLC)
            %This program is used for three terminal MOSFET measurements using the
            %Agilent B2902A.  Channel 1 is used for VDS, Channel 2 is used for the
            %gate (VGS).  PrimVar dictates whether the primary variable is VDS or VGS
            %(for ID-VDS or ID-VGS measurements)
            
            %PrimVar = 1 -> ID-VDS
            %PrimVar = 2 -> ID-VGS
            
            %to set terminal current compliance
            if(max(abs(VDS)) > 20), IdsCompStr = '0.1'; %We will reach current compliance
            else, IdsCompStr = '1';
            end
            
            IgsCompStr = '1e-1'; %Gate compliance set to 10 nA
            
            
            
            % Connect to instrument object, smu.
            %             fopen(obj.inst);
            
            %I will setup the Agilent B2902A first
            %Now I will setup the SMU
            %Preliminary settings for the SMU
            fprintf(obj.inst, '*RST'); %Resetting the instrument
            fprintf(obj.inst, 'OUTP1 OFF'); %Turning off channel 1
            fprintf(obj.inst, 'OUTP2 OFF'); %Turning off channel 2
            
            fprintf(obj.inst, 'sour1:func:mode volt'); %Setting Channel 1 mode to voltage
            fprintf(obj.inst, 'sour2:func:mode volt'); %Setting Channel 2 mode to voltage
            
            fprintf(obj.inst, 'OUTP1:LOW GRO'); %Activiting the ground for the low terminal
            fprintf(obj.inst, 'OUTP2:LOW GRO'); %Activiting the ground for the low terminal
            
            fprintf(obj.inst, ['SENS1:CURR:PROT ' IdsCompStr]); %Setting the current compliance for drain
            fprintf(obj.inst, ['SENS2:CURR:PROT ' IgsCompStr]); %Setting the current compliance for gate
            
            
            fprintf(obj.inst, 'SOUR1:VOLT:RANG:AUTO ON'); %Setting the voltage range to auto
            fprintf(obj.inst, ':SENS1:CURR:DC:RANG:AUTO ON'); %Setting the current range to auto
            fprintf(obj.inst, 'SOUR2:VOLT:RANG:AUTO ON'); %Setting the voltage range to auto
            fprintf(obj.inst, ':SENS2:CURR:DC:RANG:AUTO ON'); %Setting the current range to auto
            fprintf(obj.inst, [':SENS1:CURR:DC:NPLC ' num2str(NPLC)]); %Changed to NPLC 3 from NPLC 5 to speed up measurements
            fprintf(obj.inst, [':SENS2:CURR:DC:NPLC ' num2str(NPLC)]); %Used to be 5.  3 was good.  Change to 1
            
            fprintf(obj.inst, [':sour1:volt:mode list']); %I am setting Source 1 to voltage list mode
            fprintf(obj.inst, [':sour2:volt:mode list']); %I am setting Source 2 to voltage list mode
            
            data = zeros(length(VDS)*length(VGS),4);
            
            
            if(PrimVar == 1) %ID-VDS sweeps
                
                VDSStr = sprintf('%g,',VDS); %This converts Vbias into a string
                VDSStr = VDSStr(1:length(VDSStr)-1); %I drop the final comma
                fprintf(obj.inst, [':sour1:list:volt ' VDSStr]); %Setting the list voltages
                fprintf(obj.inst, ':trig1:sour aint'); %Automatic timing of trigger
                fprintf(obj.inst, [':trig1:coun ' num2str(length(VDS))]); %I need to trigger for
                fprintf(obj.inst, ':trig2:sour aint'); %Automatic timing of trigger
                fprintf(obj.inst, [':trig2:coun ' num2str(length(VDS))]); %I need to trigger for
                fprintf(obj.inst, [':trig1:acquire:delay ', num2str(trig_delay)]); %trigger delay
                fprintf(obj.inst, [':trig2:acquire:delay ', num2str(trig_delay)]); %trigger delay
                figure(1);
                hold all;
                for n = 1:length(VGS)
                    
                    VGSStr = sprintf('%g,',ones(length(VDS),1).*VGS(n));
                    VGSStr = VGSStr(1:length(VGSStr)-1); %I drop the final comma
                    fprintf(obj.inst, [':sour2:list:volt ' VGSStr]); %Setting the list voltages
                    fprintf(obj.inst, 'OUTP1 ON'); %Turning on channel 1
                    fprintf(obj.inst, 'OUTP2 ON'); %Turning on channel 2
                    
                    fprintf(obj.inst, ':init (@1,2)'); %Initializing the sweep
                    IDSVal = transpose(str2num(query(obj.inst, ':fetc:arr:curr? (@1)')));
                    VDSVal = transpose(str2num(query(obj.inst, ':fetc:arr:volt? (@1)')));
                    IGSVal = transpose(str2num(query(obj.inst, ':fetc:arr:curr? (@2)')));
                    VGSVal = transpose(str2num(query(obj.inst, ':fetc:arr:volt? (@2)')));
                    data((n-1)*length(VDS) + 1:n*length(VDS),1) = VDSVal(:,1);
                    data((n-1)*length(VDS) + 1:n*length(VDS),2) = IDSVal(:,1);
                    data((n-1)*length(VDS) + 1:n*length(VDS),3) = VGSVal(:,1);
                    data((n-1)*length(VDS) + 1:n*length(VDS),4) = IGSVal(:,1);
                    figure(1);
                    plot(VDSVal(:,1),IDSVal(:,1));
                    
                end
                %                 csvwrite([FileName '_IDVDS.csv'],data);
                %                 savefig([FileName '_IDVDS.fig']);
                
                %close; % close Figure
                
            else %ID-VGS sweeps
                VGSStr = sprintf('%g,',VGS); %This converts Vbias into a string
                VGSStr = VGSStr(1:length(VGSStr)-1); %I drop the final comma
                fprintf(obj.inst, [':sour2:list:volt ' VGSStr]); %Setting the list voltages
                fprintf(obj.inst, [':sour2:swe:sta doub']); % double sweep
                
                fprintf(obj.inst, ':trig1:sour aint'); %Automatic timing of trigger
                fprintf(obj.inst, [':trig1:coun ' num2str(length(VGS))]); %I need to trigger for
                fprintf(obj.inst, ':trig2:sour aint'); %Automatic timing of trigger
                fprintf(obj.inst, [':trig2:coun ' num2str(length(VGS))]); %I need to trigger for
                fprintf(obj.inst, [':trig1:acquire:delay ', num2str(trig_delay)]); %trigger delay
                fprintf(obj.inst, [':trig2:acquire:delay ', num2str(trig_delay)]); %trigger delay
                
                for n = 1:length(VDS)
                    
                    VDSStr = sprintf('%g,',ones(length(VGS),1).*VDS(n));
                    VDSStr = VDSStr(1:length(VDSStr)-1); %I drop the final comma
                    fprintf(obj.inst, [':sour1:list:volt ' VDSStr]); %Setting the list voltages
                    
                    fprintf(obj.inst, 'OUTP1 ON'); %Turning on channel 1
                    fprintf(obj.inst, 'OUTP2 ON'); %Turning on channel 2
                    
                    fprintf(obj.inst, ':init (@1,2)'); %Initializing the sweep
                    IDSVal = transpose(str2num(query(obj.inst, ':fetc:arr:curr? (@1)')));
                    VDSVal = transpose(str2num(query(obj.inst, ':fetc:arr:volt? (@1)')));
                    IGSVal = transpose(str2num(query(obj.inst, ':fetc:arr:curr? (@2)')));
                    VGSVal = transpose(str2num(query(obj.inst, ':fetc:arr:volt? (@2)')));
                    data((n-1)*length(VGS) + 1:n*length(VGS),1) = VGSVal(:,1);
                    data((n-1)*length(VGS) + 1:n*length(VGS),2) = IDSVal(:,1);
                    data((n-1)*length(VGS) + 1:n*length(VGS),3) = VDSVal(:,1);
                    data((n-1)*length(VGS) + 1:n*length(VGS),4) = IGSVal(:,1);
                    plot(VGSVal(:,1),abs(IDSVal(:,1)));
                    figure(2);
                    semilogy(VGSVal(:,1),IDSVal(:,1), '-');
                    semilogy(VGSVal(:,1),abs(IGSVal(:,1)), ':');
                end
                %                 csvwrite([FileName '_IDVGS.csv'],data);
                %                 savefig([FileName '_IDVGS.fig']);
                %pause(1);
                %close; % close Figure
                
            end
            
            fprintf(obj.inst, 'OUTP1 OFF'); %Turning off channel 1
            fprintf(obj.inst, 'OUTP2 OFF'); %Turning off channel 2
            
            % Disconnect from instrument object, smu.
            %             fclose(obj.inst);
            
            % Clean up all objects.
            %             delete(obj.inst);
        end
        
        
        
        
        function Close(obj)
            fclose(obj.inst);
        end
        
    end
    
end

