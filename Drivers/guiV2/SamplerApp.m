classdef SamplerApp < SamplerLayout
    properties
        %%Data Logging Properties
        fileName % File name (Not in use)
        filePath % Path to the Folder where the individual measurements will be stored
        subFolderPath % 
        measurementID
        %% Aquired Data
        ch1
        ch2
        ch3
        ch4
        %% Averaged and resampled - CH1 CH2 and time
        ch1A
        ch2A
        tA
        %%Hardware Objects
        shutterObj
        oscObj
        awgObj
        lockinObj
        femtoObj
        yokogawaObj
        cepObj
        powerObj
    end
    methods
        function app=SamplerApp(shutter,lockin,awg,osci,yoko,cep,power) % Constructor Class
            app=app@SamplerLayout(); % Constructor of the Superclass
            app.makeFolder();% Creates Folder to save data
            %app.getMeasurementID();
            app.shutterObj=shutter;
            app.lockinObj=lockin;
            app.awgObj=awg;
            app.oscObj=osci;
            app.yokogawaObj=yoko;
            app.cepObj=cep;
            app.powerObj=power;
            %% GUI Prep
            app.TimeConstantDropDown.Items = app.lockinObj.integrationTimeList;
            app.SensitivityDropDown.Items = app.lockinObj.sensitivityList;
            app.SensitivityDropDown.Enable = 'on';
            app.TimeConstantDropDown.Enable = 'on';
            
        end
        %% Set/Get Methods
        function set.measurementID(app,value)
            app.measurementID=value;
            app.MeasurementID1Label.Text=strcat('Measurement ID',' ',value);
        end
        
        %% Data Logging Functions
        
        function makeFolder(app)
            app.filePath=uigetdir();
            disp(strcat('Data will be saved to folder: ',app.filePath))
            dateN=now;
            strFolder=datestr(dateN,'ddmmyyyy');
            app.filePath=strcat(app.filePath,'/',strFolder,'Sampler');
            mkdir(app.filePath);
            app.filePath=strcat(app.filePath,'/');
        end
        
        function makeSubFolder(app)
            app.measurementID=datestr(now,'hhMMss');
            app.subFolderPath=strcat(app.filePath,'Trace',app.measurementID,'/');
            mkdir(app.subFolderPath);
        end
        
        function saveState(app,fileID)
            
        end
        
        %% GUI Functions
        %% These Function overload the functions of the layout superclass
        %% Make sure they are named exactly like in the .mlapp File! Copy Paste should work.
        
        % Button pushed function: StartButton
        function StartButtonPushed(app, event) % This Function Triggers measurement routine
            app.makeSubFolder();  % Make a new folder for measurment
            diary consoleLog.txt
            echo SamplerApp
            % FIXME insert Diary function to log data into the sub folder!!
            value=app.RampSpeedsEditField.Value;
            app.HorizDivsEditField.Value=value./10;
            app.HorizOffsetsEditField.Value=-value/2;
            % Save state pre measurement
            % Insert Polling FCN for everything
            if strcmp(app.SeniorScientistModeSwitch.Value,'Off')
                app.pollStatePre();
            end
            %warndlg('Please unblock the beam!')
            %measurement routine
            app.ch1A=[];
            app.ch2A=[]
            w8=waitbar(0,'Scan in Progress...')
            for i=1:app.NoScansEditField.Value
                waitbar((i-1)/app.NoScansEditField.Value,w8,strcat('Scan in Progress...','',num2str(i),' of ',' ',num2str(app.NoScansEditField.Value)));
                app.measureSingleScan()
                app.getData(i)
                waitbar(i/app.NoScansEditField.Value,w8,strcat('Scan in Progress...','',num2str(i),' of ',' ',num2str(app.NoScansEditField.Value)));
                L=length(app.ch1.x);
                if i==1
                    app.ch1A=downsample(app.ch1.y,1);
                    app.ch2A=downsample(app.ch2.y,1);
                    app.tA=downsample(app.ch1.x,1);
                else
                    app.ch1A=app.ch1A+downsample(app.ch1.y,1);
                    app.ch2A=app.ch2A+downsample(app.ch2.y,1);
                end
                
                app.ch2A=app.ch2A+downsample(app.ch2.y,1);
                plot(app.UIAxes3,app.ch1.x,app.ch1.y,app.ch2.x,app.ch2.y,app.ch3.x,app.ch3.y,app.ch4.x,app.ch4.y)
                plot(app.UIAxes2,app.ch1.y(1:L),app.ch2.y(1:L));
                plot(app.UIAxes,app.tA,app.ch1A./i,app.tA,app.ch2A(1:length(app.ch1A))./i)
                app.UIAxes2.XLim=[-10 10];
                app.UIAxes2.YLim=[-10 10];
            end
            delete(w8)
            
            %             app.plotResult()
            %save state post measurement
            if strcmp(app.SeniorScientistModeSwitch.Value,'Off')
                app.pollStatePost()
            end
            echo off
            diary off
            movefile('consoleLog.txt',app.subFolderPath)
            app.SeniorScientistModeSwitch.Value='Off';
            warndlg('Scan finished.')
        end
        function measureSingleScan(app)
            %% Start Osci Trigger
            
            app.oscObj.scope.set_orizontal_scale(app.HorizDivsEditField.Value,app.HorizOffsetsEditField.Value)
            %app.oscObj.scope.set_vertical_scale('C1',3,0)
            app.oscObj.scope.set_trigger_mode('Single')
            app.oscObj.scope.set_trigger('Ext/10', 1, 'Positive')
            %app.oscObj.scope.set_vertical_scale('C4',0.05,0)
            app.shutterState(1,1)
            pause(1)
            app.awgObj.trigger;
            pause(app.HorizDivsEditField.Value.*10+1);
            app.shutterState(1,0)
        end
        function getData(app,scanNo)
            ch1 = app.oscObj.scope.getWaveform('C1');
            ch2 = app.oscObj.scope.getWaveform('C2');
            ch3 = app.oscObj.scope.getWaveform('C3');
            ch4 = app.oscObj.scope.getWaveform('C4');
            save(strcat('OsciData',num2str(scanNo),'.mat'),'ch1','ch2','ch3','ch4')
            movefile(strcat('OsciData',num2str(scanNo),'.mat'),app.subFolderPath)
            app.ch1=ch1;
            app.ch2=ch2;
            app.ch3=ch3;
            app.ch4=ch4;
            
            
        end
        
        function pollStatePre(app)
            fid=fopen(strcat(app.subFolderPath,'preState.txt'),'w');
            fprintf(fid,'This file saves all experiment parameters\r\n');
            fprintf(fid,strcat('Start Time:',datestr(now),'\r\n'));
            fprintf(fid,'CEP rad; %s;\r\n',app.CEPradEditField.Value);
            fprintf(fid,'Lock In Time Constant; %s;\r\n',app.lockinObj.integrationTime);
            fprintf(fid,'Lock In Sensitivity; %s;\r\n',app.lockinObj.Sensitivity);
            fprintf(fid,'Lock In DemodF; %s;\r\n',app.lockinObj.frequency);
            fprintf(fid,'AWG Frqz; %i;\r\n',app.awgObj.frqz);
            fprintf(fid,'OsciCH1; %s;\r\n',app.EditField.Value);
            fprintf(fid,'OsciCH2; %s;\r\n',app.EditField_2.Value);
            fprintf(fid,'OsciCH3; %s;\r\n',app.EditField_3.Value);
            fprintf(fid,'OsciCH4; %s;\r\n',app.EditField_4.Value);
            fprintf(fid,'Osci Horiz Div(s); %s;\r\n',num2str(app.HorizDivsEditField.Value));
            fprintf(fid,'Osci Horiz Offset(s); %s;\r\n',app.HorizOffsetsEditField.Value);
            app.shutterObj.flipUp(2);
            t1=tic
            %Maybe Use flipmount? so the user only needs to read it?
            output=inputdlg({'Enter Femto Gain:','Enter Bias Voltage in V:','Enter Chip and Pad ID:','Enter ND OD:','Enter additional Comments:'},'Be a good Scientist')
            fprintf(fid,'Femto Gain (V/A); %s;\r\n',output{1});
            fprintf(fid,'Bias Voltage (V/A); %s;\r\n',output{2});
            fprintf(fid,'Sample ID; %s;\r\n',output{3});
            fprintf(fid,'ND (OD); %s;\r\n',output{4});
            fprintf(fid,'Additional Comments;%s\r\n',output{5});
            while toc(t1)<=20
            pause(0.5);
            end
            power=app.powerObj.measurePower()
            fprintf(fid,'Probe Power; %f;\r\n',power);
            app.shutterObj.flipDown(2)
            fclose(fid);
            pause(1);
        end
        function pollStatePost(app)
            fid=fopen(strcat(app.subFolderPath,'postState.txt'),'w');
            fprintf(fid,'This file saves all experiment parameters\r\n');
            fprintf(fid,strcat('Start Time:',datestr(now),'\r\n'));
            fprintf(fid,'CEP rad; %s;\r\n',app.CEPradEditField.Value);
            fprintf(fid,'Lock In Time Constant; %s;\r\n',app.lockinObj.integrationTime);
            fprintf(fid,'Lock In Sensitivity; %s;\r\n',app.lockinObj.Sensitivity);
            fprintf(fid,'Lock In DemodF; %s;\r\n',app.lockinObj.frequency);
            fprintf(fid,'AWG Frqz; %i;\r\n',app.awgObj.frqz);
            fprintf(fid,'OsciCH1; %s;\r\n',app.EditField.Value);
            fprintf(fid,'OsciCH2; %s;\r\n',app.EditField_2.Value);
            fprintf(fid,'OsciCH3; %s;\r\n',app.EditField_3.Value);
            fprintf(fid,'OsciCH4; %s;\r\n',app.EditField_4.Value);
            fprintf(fid,'Osci Horiz Div(s); %s;\r\n',num2str(app.HorizDivsEditField.Value));
            fprintf(fid,'Osci Horiz Offset(s); %s;\r\n',app.HorizOffsetsEditField.Value);
            app.shutterObj.flipUp(2);
            t1=tic;
            %Maybe Use flipmount? so the user only needs to read it?
            output=inputdlg({'Enter additional Comments:'},'Be a good Scientist');
            fprintf(fid,'Additional Comments;%s\r\n',output{1});
            while toc(t1)<=20
            pause(0.5);
            end
            power=app.powerObj.measurePower()
            app.shutterObj.flipDown(2);
            fprintf(fid,'Probe Power; %f;\r\n',power);
            fclose(fid);
        end
        
        % Selection changed function: ChannelSelectionButtonGroup
        function ChannelSelectionButtonGroupSelectionChanged(app, event)
            selectedButton = app.ChannelSelectionButtonGroup.SelectedObject;
            
        end
        
        
        % Value changed function: Channel1DropDown
        function Channel1DropDownValueChanged(app, event)
            value = app.Channel1DropDown.Value;
            
        end
        
        % Value changed function: Channel2DropDown
        function Channel2DropDownValueChanged(app, event)
            value = app.Channel2DropDown.Value;
            
        end
        
        % Value changed function: TimeConstantDropDown
        function TimeConstantDropDownValueChanged(app, event)
            value = app.TimeConstantDropDown.Value;
            indexC=strfind(app.lockinObj.integrationTimeList,value),
            index=find(not(cellfun('isempty',indexC)));
            app.lockinObj.setIntegrationTime(index);
        end
        
        % Value changed function: SensitivityDropDown
        function SensitivityDropDownValueChanged(app, event)
            value = app.SensitivityDropDown.Value;
            indexC=strfind(app.lockinObj.sensitivityList,value),
            index=find(not(cellfun('isempty',indexC)));
            app.lockinObj.setSensitivity(index);
        end
        
        %%
        
        % Value changed function: AmplitudeVEditField
        function AmplitudeVEditFieldValueChanged(app, event)
            value = app.AmplitudeVEditField.Value;
            
        end
        
        % Value changed function: OffsetVEditField
        function OffsetVEditFieldValueChanged(app, event)
            value = app.OffsetVEditField.Value;
            
        end
        
        % Button pushed function: ToggleButton
        function ToggleButtonPushed(app, event)
            app.shutterObj.toggle(1);
            if app.shutterObj.toggleState(1)==0
                app.MicroscopeLamp.Color = [1 0 0];
            elseif app.shutterObj.toggleState(1)==1
                app.MicroscopeLamp.Color = [0 1 0];
            end
        end
        function shutterState(app,id,state) % shutter function to summarize the shutter command and the lamp in one function
            if state==0
                app.shutterObj.off(id);
                %% Please change if second shutter is included
                app.MicroscopeLamp.Color = [1 0 0];
            elseif state==1
                app.shutterObj.on(id);
                app.MicroscopeLamp.Color = [0 1 0];
            end
        end
        % Button pushed function: ToggleButton_2
        function ToggleButton_2Pushed(app, event)
            if app.shutterObj.toggleState(2)==0
                app.shutterObj.flipUp(2)
                app.PowerMeterLamp.Color = [0 1 0];
            elseif app.shutterObj.toggleState(2)==1
                app.PowerMeterLamp.Color = [1 0 0];
                app.shutterObj.flipDown(2)
            else
                disp('fuck')
            end
        end
        % Value changed function: GainDropDown
        function GainDropDownValueChanged(app, event)
            value = app.GainDropDown.Value;
            
        end
        
        % Value changed function: BiasEditField
        function BiasEditFieldValueChanged(app, event)
            value = app.BiasEditField.Value;
            
        end
        
        % Button pushed function: Button_4
        function Button_4Pushed(app, event)
            
        end
        
        % Button pushed function: Button_5
        function Button_5Pushed(app, event)
            
        end
        
        % Value changed function: FileNameEditField
        function FileNameEditFieldValueChanged(app, event)
            value = app.FileNameEditField.Value;
            
        end
        
        % Button pushed function: FolderButton
        function FolderButtonPushed(app, event)
            app.makeFolder();
        end
        
        % Button pushed function: AbortButton
        function AbortButtonPushed(app, event)
            
        end
        
        % Value changed function: EditField
        function EditFieldValueChanged(app, event)
            value = app.EditField.Value;
            
        end
        
        % Value changed function: EditField_2
        function EditField_2ValueChanged(app, event)
            value = app.EditField_2.Value;
            
        end
        
        % Value changed function: EditField_3
        function EditField_3ValueChanged(app, event)
            value = app.EditField_3.Value;
            
        end
        
        % Value changed function: EditField_4
        function EditField_4ValueChanged(app, event)
            value = app.EditField_4.Value;
            
        end
        %% Oscilloscope functions
        % Value changed function: HorizOffsetsEditField
        function HorizOffsetsEditFieldValueChanged(app, event)
            app.oscObj.scope.set_orizontal_scale(app.HorizDivsEditField.Value,app.HorizOffsetsEditField.Value)
            
            
        end
        % Value changed function: HorizDivsEditField
        function HorizDivsEditFieldValueChanged(app, event)
            app.oscObj.scope.set_orizontal_scale(app.HorizDivsEditField.Value,app.HorizOffsetsEditField.Value)
            
        end
        % Value changed function: Ch1EditField
        function Ch1EditFieldValueChanged(app, event)
            value = app.Ch1EditField.Value;
            app.oscObj.scope.set_vertical_scale('C1',app.Ch1EditField.Value,app.Ch1EditField_2.Value)
            
        end
        
        % Value changed function: Ch2EditField
        function Ch2EditFieldValueChanged(app, event)
            value = app.Ch2EditField.Value;
            app.oscObj.scope.set_vertical_scale('C2',app.Ch2EditField.Value,app.Ch2EditField_2.Value)
            
        end
        
        % Value changed function: Ch3EditField
        function Ch3EditFieldValueChanged(app, event)
            value = app.Ch3EditField.Value;
            app.oscObj.scope.set_vertical_scale('C3',app.Ch3EditField.Value,app.Ch3EditField_2.Value)
            
        end
        
        % Value changed function: Ch4EditField
        function Ch4EditFieldValueChanged(app, event)
            value = app.Ch4EditField.Value;
            app.oscObj.scope.set_vertical_scale('C4',app.Ch4EditField.Value,app.Ch4EditField_2.Value)
            
        end
        
        % Value changed function: Ch1EditField_2
        function Ch1EditField_2ValueChanged(app, event)
            value = app.Ch1EditField_2.Value;
            app.oscObj.scope.set_vertical_scale('C1',app.Ch1EditField.Value,app.Ch1EditField_2.Value)
            
        end
        
        % Value changed function: Ch2EditField_2
        function Ch2EditField_2ValueChanged(app, event)
            value = app.Ch2EditField_2.Value;
            app.oscObj.scope.set_vertical_scale('C2',app.Ch2EditField.Value,app.Ch2EditField_2.Value)
            
        end
        
        % Value changed function: Ch3EditField_2
        function Ch3EditField_2ValueChanged(app, event)
            value = app.Ch3EditField_2.Value;
            app.oscObj.scope.set_vertical_scale('C3',app.Ch3EditField.Value,app.Ch3EditField_2.Value)
            
        end
        
        % Value changed function: Ch4EditField_2
        function Ch4EditField_2ValueChanged(app, event)
            value = app.Ch4EditField_2.Value;
            app.oscObj.scope.set_vertical_scale('C4',app.Ch4EditField.Value,app.Ch4EditField_2.Value)
            
        end
        %% AWG Functions
        % Button pushed function: AutosetOsciButton
        function AutosetOsciButtonPushed(app, event)
            value=app.RampSpeedsEditField.Value;
            app.HorizDivsEditField.Value=value./10;
            app.HorizOffsetsEditField.Value=-value/2;
        end
        % Value changed function: RampSpeedsEditField
        function RampSpeedsEditFieldValueChanged(app, event)
            value = app.RampSpeedsEditField.Value;
            app.awgObj.frqz=1/value;
        end
        
        %% CEP Control
        
        % Value changed function: CEPradEditField
        function CEPradEditFieldValueChanged2(app, event)
            value = app.CEPradEditField.Value;
            app.cepObj.cep=str2num(value);
        end
    end
    
    
end