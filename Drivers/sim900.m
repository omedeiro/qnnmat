classdef sim900

    
    properties
        inst
        console
    end
    
    methods
        function obj = sim900(GPIB_Address)
            if ~exist('GPIB_Address')
                GPIB_Address = 7;
            end
            obj.inst = gpib('ni',0, GPIB_Address);
            fopen(obj.inst);            
        end
        
        
        function txt = read(obj)
            txt = fscanf(obj.inst);
        end
        
        function write(obj, string)
            fprintf(obj.inst,[string]);
        end
        
        function setLevel(obj, voltage, sim900port)
            message = sprintf('VOLT %0.4e', voltage);
            fprintf(obj.inst,['SNDT '  num2str(sim900port)  ',"' message '"']);
            %              obj.clearErrors();
            
        end
        
        function setOutput(obj, status, sim900port)
            if status == 1
                message = sprintf('OPON');
                fprintf(obj.inst,['SNDT '  num2str(sim900port)  ',"' message '"']);
            else
                message = sprintf('OPOF');
                fprintf(obj.inst,['SNDT '  num2str(sim900port)  ',"' message '"']);
            end
        end
        
        
        
        function Close(obj)
            fclose(obj.inst);
        end
        
    end
    
end

