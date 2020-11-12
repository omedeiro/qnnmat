classdef select_o_matic
    % Interface class for the Select-O-Matic
    
    properties
        inst
    end
    
    methods
        function obj = select_o_matic(serial_port_name)
            if (~exist('serial_port_name'))
                Skey = 'HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM';
                % Find connected serial devices and clean up the output
                [~, list] = dos(['REG QUERY ' Skey]);
                list = strread(list,'%s','delimiter',' ');
                coms = 0;
                for i = 1:numel(list)
                  if strcmp(list{i}(1:3),'COM')
                      if ~iscell(coms)
                          coms = list(i);
                      else
                          coms{end+1} = list{i};
                      end
                  end
                end
                key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';
                % Find all installed USB devices entries and clean up the output
                [~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
                vals = textscan(vals,'%s','delimiter','\t');
                vals = cat(1,vals{:});
                out = 0;
                % Find all friendly name property entries
                for i = 1:numel(vals)
                  if strcmp(vals{i}(1:min(12,end)),'FriendlyName')
                      if ~iscell(out)
                          out = vals(i);
                      else
                          out{end+1} = vals{i};
                      end
                  end
                end
                % Compare friendly name entries with connected ports and generate output
                for i = 1:numel(coms)
                  match = strfind(out,[coms{i},')']);
                  ind = 0;
                  for j = 1:numel(match)
                      if ~isempty(match{j})
                          ind = j;
                      end
                  end
                  if ind ~= 0
                      com = str2double(coms{i}(4:end));
                % Trim the trailing ' (COM##)' from the friendly name - works on ports from 1 to 99
                      if com > 9
                          length = 8;
                      else
                          length = 7;
                      end
                      devs{i,1} = out{ind}(27:end-length);
                      devs{i,2} = com;
                  end
                end

                for i=1:size(devs,2)
                    s = devs(i,1);
                    s = s{1};
                    if (strcmp(s,'USB Serial Port'))
                        port = devs(i,2);
                        port = port{1};
                        serial_port_name = ['COM', num2str(port)];
                    end
                end
                
                if ~exist('serial_port_name')
                    error('No compatible device found');
                end
            end
            
            instrList = instrfind;
            for i = 1:numel(instrList)
                if strcmp(instrList(i).port, serial_port_name)
                    fclose(instrList(i));
                    delete(instrList(i));
                end
            end
            
            obj.inst = serial(serial_port_name);
            set(obj.inst, 'BaudRate', 9600);
            fopen(obj.inst);
        end
        
        function setPort(obj, inputPort)
            if (inputPort<=35 && inputPort >= 0)
                
                fprintf(obj.inst, 'S%.2d', inputPort);
            end
        end
        
        function setEnable(obj, enable)
            if (enable)
                fprintf(obj.inst, 'E1');
            else
                fprintf(obj.inst, 'E0');
            end
        end
        
        function delete(obj)
            fclose(obj.inst);
        end
        
    end
    
end
