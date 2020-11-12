classdef console
    %CONSOLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        window
        list
    end
    
    methods
        function obj = console(consoleTitle)
            if ~exist('consoleTitle')
                consoleTitle = 'Console';
            end
            obj.window = figure('menubar', 'none', 'Name', consoleTitle,'NumberTitle','off');
            obj.list = uicontrol('Style', 'listbox', 'Units', 'normalized', 'Position', [0,0,1,1], 'String', {}, 'Min', 0, 'Max', 2, 'Value', [], 'FontName', 'FixedWidth');
            title(consoleTitle)
            obj.print([consoleTitle ' started.'])
        end
        
        function print(obj, str)
            date = datestr(now, 0);
            newString = cat(1, get(obj.list, 'String'), {[date ' MSG-> ' str]});
            set(obj.list, 'String', newString);
            index = size(get(obj.list,'string'), 1);        % Scroll to the end
            set(obj.list,'ListboxTop',index);
            drawnow;
        end
        
        function error(obj, str)
            pre = '<HTML><FONT color="red">';
            post = '</FONT></HTML>';
            date = datestr(now, 0);
            newString = cat(1, get(obj.list, 'String'), {[pre date ' ERR-> ' str post]});
            set(obj.list, 'String', newString);
            index = size(get(obj.list,'string'), 1);        % Scroll to the end
            set(obj.list,'ListboxTop',index);
            drawnow;
        end
        
    end
    
end

