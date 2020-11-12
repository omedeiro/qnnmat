classdef inst
    properties
        GPIB_Address
        handle
        console
        idn
    end
    methods
        function obj = inst(console, GPIB_Address)
            obj.GPIB_Address = GPIB_Address;
            obj.console = console;
            obj.handle = obj.connect(1000);
        end
        
        function handle = connect(obj, bufferSize)
            handle = instrfind('Type', 'gpib', 'BoardIndex', 32, 'PrimaryAddress', obj.GPIB_Address, 'Tag', '');

            % Create the GPIB object if it does not exist
            % otherwise use the object that was found.
            if isempty(handle)
                handle = gpib('AGILENT', 32, obj.GPIB_Address);
            else
                fclose(handle);
                handle = handle(1);
            end

            handle.Timeout = 5; %set IO time out
            %calculate output buffer size
            set (handle,'OutputBufferSize',bufferSize);

            %open connection to instrument
            try
                fopen(handle);
            catch exception %problem occurred throw error message
                errorMsg = ['Error occurred trying to connect to the the instrument at addess ' num2str(obj.GPIB_Address) '.'];
                obj.console.error(errorMsg);
                uiwait(msgbox(errorMsg,'Error Message','error'));
                rethrow(exception);
                return
            end

            %Query Idendity string and report
            fprintf(handle, '*IDN?');
            obj.idn = fscanf(handle);
            obj.console.print(obj.idn);
        end
        
        function send(obj, command)
            fprintf(obj.handle, command);
        end
        
        function value = read(obj)
            value = fscanf(obj.handle);
        end
        
        function setBufferSize(obj, bufferSize)
            fclose(obj.handle);
            obj.console.print(['Closing GPIB address ' num2str(obj.GPIB_Address) '\n']);
            obj.handle = obj.connect(bufferSize);
        end
        
        function delete(obj)
            fclose(obj.handle);
            obj.console.print(['Closing GPIB address ' num2str(obj.GPIB_Address) '\n']);
        end
        
    end
end
