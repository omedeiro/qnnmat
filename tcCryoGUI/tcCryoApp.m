classdef tcCryoApp < tcCryoLayout
    properties
        %% Data Logging Properties
        apiClientID 
        apiKey 
        sheetIdTc
        
        fileName
        filePath
        filePathNAS
        filePathCooldown
        filePathCooldownNAS
        subFolderPath
        %% Aquired Data
        cooldownTemp
        cooldownTime
        cooldownDuration
        measuredResistance
        measuredTemp
        measuredCurrent
        globalMinimumTemp

        %% Hardware Objects
        cryoconObj
        labjackObj
        lj
        ljIO
        ljasm
        ljudObj
        
        %% App Objects
        stop
    end
    methods
        function app = tcCryoApp()
            app = app@tcCryoLayout();
            app.setDirectory();
            app.cryoconObj=cryocon;
            app.ljasm = NET.addAssembly('LJUDDotNet');
            app.ljudObj = LabJack.LabJackUD.LJUD;
            [ljerror, ljhandle] = app.ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);
            app.lj = ljhandle;
            app.stop = 0;
            app.apiClientID = '939372684163-6l9568gl5mbst7j4hl3ms5774v4p0lur.apps.googleusercontent.com';
            app.apiKey = 'mKzmbgpNfxP_T7tU2pzTMe5R';
            app.sheetIdTc = '1U96uvHKozNimIb4_gkXFvJUp04TPJNlDoPeP5eBow0g';
            
            app.globalMinimumTemp = 0;
        end
            
        function setDirectory(app)
            addpath C:\Users\qnn-Tc-cryo\Documents\MATLAB\MATLAB_LJUD\LJUD_Functions
            addpath C:\Users\qnn-Tc-cryo\Documents\MATLAB\tcCryoGUI
            app.filePath = 'C:\Users\qnn-Tc-cryo\Documents\tcCryoSampleData';
            app.filePathNAS = 'S:\SC\Measurements';
            app.filePathCooldown = 'C:\Users\qnn-Tc-cryo\Documents\tcCryoCooldownData';
            app.filePathCooldownNAS = 'S:\SC\InstrumentLogging\Cryogenics\TcCryo';
        end
        
        function Tc = calculateTc(app, temp, resistance)
            tol = max(resistance)*.08;
            halfResistance = max(resistance)/2;
            i = find(resistance < halfResistance+tol & resistance > halfResistance - tol);
            if min(resistance) < 10 && length(i) < 40
                Tc = (max(temp(i))+min(temp(i)))/2;
            else
                Tc = 0;
            end
            
        end
        
        function updateTemp(app, value)
            while strcmpi(value, 'on')
                value = app.QuickMeasureSwitch.Value;
                temp = app.cryoconObj.read_temp('B');
                if length(temp) == 1
                    app.TemperatureEditField.Value = temp;
                    pause(0.5)
                end
            end
        end
                    
        function V = getVoltage(app, positions)
            V = zeros(1,length(positions));
            
            for i = 1:length(positions)
                
                % Set up Flex IOType registers
                %AKA select channel
                numbin = fliplr(dec2bin(positions(i)-1,8));
                for bit = 1:8
                    app.ljudObj.eDO(app.lj,bit-1,str2num(numbin(bit)));
%                     disp(['FIO' num2str(bit-1) ' set to ' num2str(numbin(bit))])
                end
%                 disp('---')
                channelP = 2;
                channelN = 3;
                voltage = 0.0;
                LJ_rgBIP10V = app.ljudObj.StringToConstant('LJ_rgBIP10V');
                range = 1;
                resolution = 8;
                settling = 4;
                binary = 0;
                v=zeros(50,1);
                [ljerror, voltage] = app.ljudObj.eAIN(app.lj, channelP, channelN, voltage, range, resolution, settling, binary);
                V(i) = voltage;
            end
        end
        
        
        function V = getTestVoltage(app)
            V = [];
            
            channels = 0:5;
            for i = 1:length(channels)
                
                % Set up Flex IOType registers
                %AKA select channel
                numbin = fliplr(dec2bin(channels(i),8));
                for bit = 1:8
                    app.ljudObj.eDO(app.lj,bit-1,str2num(numbin(bit)));
%                     disp(['FIO' num2str(bit-1) ' set to ' num2str(numbin(bit))])
                end
%                 disp('---')
                channelP = 2;
                channelN = 3;
                voltage = 0.0;
                LJ_rgBIP10V = app.ljudObj.StringToConstant('LJ_rgBIP10V');
                range = 1;
                resolution = 8;
                settling = 4;
                binary = 0;
                v=zeros(50,1);
                for j = 1:50
                    [ljerror, voltage] = app.ljudObj.eAIN(app.lj, channelP, channelN, voltage, range, resolution, settling, binary);
                    v(j) = voltage;
                end
                V = [V,mean(v), std(v)];
            end

        end
        
        function startTestConnections(app)
                % POS 3 and POS 5 flipped
                meanFields = [app.EditField0, app.EditField1, app.EditField2...
                                app.EditField5, app.EditField4, app.EditField3];
                stdFields = [app.EditField0_1, app.EditField1_1, app.EditField2_1...
                                app.EditField5_1, app.EditField4_1, app.EditField3_1];
                testData = zeros(1,12);

            while app.TestConnectionsButton.Value == 1
                current = str2double(app.CurrentListBox.Value);
                testData = app.getTestVoltage();
                for i = 1:6
                    meanFields(i).Value = testData(2*i-1)/current;
                    stdFields(i).Value = testData(2*i)./current;
                    drawnow;
                end
                pause(2);
            end
        end
        
        function startCoolDownLog(app)
            while app.stop == 0
                app.StatusEditField.Value = 'Starting Cooldown Log';
                app.TabGroup2.SelectedTab = app.Tab2_2;
                temp = app.cryoconObj.read_temp('B');
                startTime = datetime('now');

                app.cooldownTemp = [];
                app.cooldownTime = [];
                app.cooldownTemp = [app.cooldownTemp, temp];
                app.cooldownTime = [app.cooldownTime, datetime('now')];

                pause(0.5)
                set_distance = 45;
                while min(app.cooldownTemp) > 10 
                    while (length(app.cooldownTemp) - find(app.cooldownTemp == min(app.cooldownTemp))) < set_distance && app.stop == 0
                        temp = app.cryoconObj.read_temp('B');
                        app.TemperatureEditField.Value = temp;
                        app.cooldownTemp = [app.cooldownTemp, temp];
                        app.cooldownTime = [app.cooldownTime, datetime('now')];
                        app.UIAxes8.YLim = [0 300];
                        datetick(app.UIAxes8,'x')       
                        plot(app.UIAxes8, datenum(app.cooldownTime), app.cooldownTemp,'b.-')

                        app.MinTempEditField.Value = min(app.cooldownTemp);
                        app.globalMinimumTemp = min(app.cooldownTemp);
                        try
                            app.DistanceEditField.Value = length(app.cooldownTemp) - find(app.cooldownTemp == min(app.cooldownTemp));
                        catch
                            disp(length(app.cooldownTemp) - find(app.cooldownTemp == min(app.cooldownTemp)))
                        end
                        drawnow;
                        pause(1)    
                    end
                end
                if app.stop == 1
                    break
                end
                app.cooldownDuration = datetime('now') - startTime;
                if max(app.cooldownTemp > 10)
                    app.saveCooldownResults(app.cooldownTime,app.cooldownTemp,app.cooldownDuration);
                end
                app.StatusEditField.Value = 'Cooldown Complete';
                pause(5)
                
                break
            end
        end
            
        function tcMeasurement(app)
            while app.stop == 0
                %This function is called following the cooldown function. The
                %cooler is at base temperature
                if app.stop == 1
                    break
                end
                
                app.StatusEditField.Value = 'Starting Heater';
                app.TabGroup2.SelectedTab = app.Tab_2;

                samples = string(app.Panel.Children.findobj('Type','uieditfield').get('Value'));
                positions = find(flipud(~cellfun(@isempty,samples)));

                temp = [];
                voltage = [];
                
                highSetpoint = 25;
                lowSetpoint = app.globalMinimumTemp;   
                
                app.cryoconObj.setup_heater(50, '50W', 'B');
                app.cryoconObj.set_control_type_rampp(10)
                app.cryoconObj.set_pid(0.5,5,0);
                app.cryoconObj.stop_heater();
                app.cryoconObj.set_setpoint(lowSetpoint);
                app.cryoconObj.start_heater();
                pause(2)
                
                app.cryoconObj.set_setpoint(highSetpoint);
                app.StatusEditField.Value = 'Set higher setpoint';  
                currentTemp = app.cryoconObj.read_temp('B');
                
                while currentTemp < highSetpoint && app.stop == 0
                    app.StatusEditField.Value = 'Heating';
                    voltage = [voltage;app.getVoltage(positions)];
                    currentTemp = app.cryoconObj.read_temp('B');
                    app.TemperatureEditField.Value = currentTemp;
                    temp = [temp;currentTemp]; 
%                     app.MinTempEditField.Value = min(temp); %removed line
%                     to keep minimum temp set from cooldown. 
                    for i = 1:length(positions)
                        app.plotTcCurves(positions(i),temp,voltage(:,i)./app.measuredCurrent)
                    end
                end
                
                if app.stop == 1
                    break
                end
                
                app.cryoconObj.set_setpoint(lowSetpoint);
                
                while currentTemp > lowSetpoint && app.stop == 0
                    app.StatusEditField.Value = 'Set lower setpoint';
                    voltage = [voltage;app.getVoltage(positions)];
                    currentTemp = app.cryoconObj.read_temp('B');
                    app.TemperatureEditField.Value = currentTemp;
                    temp = [temp;currentTemp]; 
%                     app.MinTempEditField.Value = min(temp);
                    for i = 1:length(positions)
                        app.plotTcCurves(positions(i),temp,voltage(:,i)./app.measuredCurrent)
                    end

                    if max(temp) > 10 && currentTemp < app.globalMinimumTemp*1.1
%                 while (length(app.cooldownTemp) - find(app.cooldownTemp == min(app.cooldownTemp))) < set_distance && app.stop == 0
                        %lowest temperature met
                        app.cryoconObj.stop_heater();
                        app.measuredResistance = voltage./app.measuredCurrent;
                        app.measuredTemp = temp;
                        fieldsTc = [app.Tc0, app.Tc1, app.Tc2, app.Tc5, app.Tc4, app.Tc3];
                        sampleIDs = [app.Position0EditField,app.Position1EditField,app.Position2EditField,...
                            app.Position5EditField,app.Position4EditField,app.Position3EditField];
                        for i = 1:length(positions)
                            try
                                fieldsTc(positions(i)).Value = app.calculateTc(temp,voltage(:,i)/app.measuredCurrent);
                            catch 
                                warning('could not calculate Tc. Assigning 0');
                                fieldsTc(positions(i)).Value = 0;
                            end
%                             app.saveTcResults(sampleIDs(positions(i)).Value,app.calculateTc(temp,voltage(:,i)));
                            app.plotTcCalc(i,fieldsTc(positions(i)).Value)
                            app.saveRTResults(sampleIDs(positions(i)).Value,temp,voltage(:,i)./app.measuredCurrent,fieldsTc(positions(i)).Value);
                        end
                        break
                    end
                    
                end
                break
                
            end
        end
        
        function plotTcCurves(app, plotIndex, temp, resistance)
            plots = [app.UIAxes4_1,app.UIAxes4_2,app.UIAxes4_3,app.UIAxes4_4,app.UIAxes4_5,app.UIAxes4_6];
            axisHandle = plots(plotIndex);

            axisHandle.cla;
            plot(axisHandle,temp,resistance);
            hold(axisHandle, 'on')
            plot(axisHandle,temp(length(temp)),resistance(length(resistance)),'or');
            set(axisHandle, 'Position', axisHandle.Position)
            
            drawnow;
        end
        
        function plotTcCalc(app, plotIndex, Tc)
            plots = [app.UIAxes4_1,app.UIAxes4_2,app.UIAxes4_3,app.UIAxes4_4,app.UIAxes4_5,app.UIAxes4_6];
            axisHandle = plots(plotIndex);
            
            plot(axisHandle,[Tc Tc], axisHandle.YLim)
        end
        
        function saveTcResults(app, name, value)
            sheetNumber = '0';
            s = GetGoogleSpreadsheet(app.sheetIdTc,sheetNumber);
            location = [size(s,1)+1, 1];
            mat2sheets(app.sheetIdTc,sheetNumber, location, {name value});
        end
        
        function saveRTResults(app, name, temp, resistance, Tc)
            % Save Locally
            filename = strcat(app.filePath,'\',name,'--',datestr(datetime('now'),'mm-dd-yyyy--HH-MM-SS'),'.mat');
            save(filename, 'temp', 'resistance', 'Tc');
            
            %Save to network
            try
                filepath_nas = strcat(app.filePathNAS,'\',name,'\','tc_cryo');
                mkdir(filepath_nas);
                filename_nas = strcat(filepath_nas,'\',name,'--',datestr(datetime('now'),'mm-dd-yyyy--HH-MM-SS'),'.mat');
                save(filename_nas, 'temp', 'resistance', 'Tc');
            catch
                warning('Failed to save RT data to network')
            end
        end
        
        function saveCooldownResults(app, time, temp, duration)
            duration = minutes(duration);
            minimum = min(temp);
            filename = strcat(app.filePathCooldown,'\',datestr(datetime('now'),'mm-dd-yyyy--HH-MM-SS'),'--','cooldown','.mat');
            save(filename, 'time', 'temp', 'duration', 'minimum');
            
%             sheetNumber = '757987130';
%             s = GetGoogleSpreadsheet(app.sheetIdTc,sheetNumber);
%             location = [size(s,1)+1, 1];            
%             mat2sheets(app.sheetIdTc,sheetNumber,location, {datestr(datetime('now'),'mm/dd/yyyy') minimum});

            try
                filename = strcat(app.filePathCooldownNAS,'\',datestr(datetime('now'),'mm-dd-yyyy--HH-MM-SS'),'--','cooldown','.mat');
                save(filename, 'time', 'temp', 'duration', 'minimum');
            catch
                warning('Failed to save Cooldown data to network')
            end
        end
        
        function c = checkSampleNames(app)
            samples = string(app.Panel.Children.findobj('Type','uieditfield').get('Value'));
            positions = find(flipud(~cellfun(@isempty,samples)));
            correct_names = [];
            samples = flipud(samples);
            for i = 1:length(positions)                
                exp = '[A-Z]{3}+\d{3}';
                check = regexp(samples(positions(i)),exp);
                if check == 1
                    correct_names = [correct_names, i];
                end
            end
            if length(positions) == length(correct_names)
                c = 1;
            else
                c = 0;
            end
        end
        
        function startTcMeasurement(app)
            app.stop = 0;
            while app.stop == 0
                app.measuredCurrent = str2double(app.CurrentListBox.Value);
                app.startCoolDownLog();
                
                app.tcMeasurement();  
                break
            end
            if app.stop == 1
                app.cryoconObj.stop_heater();
                app.StatusEditField.Value = 'System Stopped';
                app.FieldCheckCheckBox.Value = 0;
                app.TestConnectionsButton.Enable = 'on';

            else
                app.StatusEditField.Value = 'Measurement Complete';
                app.FieldCheckCheckBox.Value = 0;
                app.TestConnectionsButton.Enable = 'on';
                app.QuickMeasureSwitch.Enable = 'on';

            end
            
        end
        


    end
    
    %%%%COPIED FROM APP DESIGNER%%%%

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: RunButton
        function RunButtonPushed(app, event)
            app.StopButton.Enable = 'on';
            samples = string(app.Panel.Children.findobj('Type','uieditfield').get('Value'));
            positions = find(flipud(~cellfun(@isempty,samples)));

            c = app.checkSampleNames();
            
            if app.FieldCheckCheckBox.Value == 1 && ~isempty(positions) && c == 1
                app.RunButton.Enable = 'off';
                
                app.TestConnectionsButton.Value = 0;
                app.TestConnectionsButton.Enable = 'off';
                
%                 app.QuickMeasureSwitch.Value = 'Off';
                app.QuickMeasureSwitch.Enable = 'Off';
            
                app.startTcMeasurement();
            else
                app.StatusEditField.Value = 'Enter Sample Names With Format: ABC123';
            end
        end

        % Value changed function: FieldCheckCheckBox
        function FieldCheckCheckBoxValueChanged(app, event)
            value = app.FieldCheckCheckBox.Value;
            
        end

        % Value changed function: CurrentListBox
        function CurrentListBoxValueChanged(app, event)
            value = app.CurrentListBox.Value;
            
        end

        % Value changed function: TestConnectionsButton
        function TestConnectionsButtonValueChanged(app, event)
            value = app.TestConnectionsButton.Value;
            app.startTestConnections();
        end

        % Selection change function: TabGroup2
        function TabGroup2SelectionChanged(app, event)
            selectedTab = app.TabGroup2.SelectedTab;
            
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            f = uifigure;
            selection = uiconfirm(f,'Confirm Stop?', 'Stop Button Pushed','Icon','warning');
            delete(f)
            if selection == 'OK'
                app.cryoconObj.stop_heater();
                app.StatusEditField.Value = 'System Stopped';
                app.stop = 1;
                app.RunButton.Enable = 'on';
                app.StopButton.Enable = 'off';
                app.TestConnectionsButton.Enable = 'on';

            end
        end

        % Value changed function: QuickMeasureSwitch
        function QuickMeasureSwitchValueChanged(app, event)
            value = app.QuickMeasureSwitch.Value;
            app.updateTemp(value);
        end
    end
end