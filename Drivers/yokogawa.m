classdef yokogawa

    
    properties
        inst
        console
    end
    
    methods
        function obj = yokogawa(GPIB_Address)
            if ~exist('GPIB_Address')
                GPIB_Address = 20;
            end
            obj.inst = gpib('ni',0, GPIB_Address);
            fopen(obj.inst);
        end
        
  
        function setSource(obj, source)
            fprintf(obj.inst,[':SOUR:FUNC ' source]);
             obj.clearErrors();
        end
        
        function setRange(obj, range)
            % range = 30E0, 10E0
            fprintf(obj.inst,[':SOUR:RANG ' range]);
             obj.clearErrors();
        end
        
        function setLevel(obj, level)
            fprintf(obj.inst,[':SOUR:LEV ' num2str(level)]);
             obj.clearErrors();
        end
        
        function setOutput(obj, status)
            fprintf(obj.inst,[':OUTP:STAT ' status]);
            obj.clearErrors();
        end
       
        function clearErrors(obj)
            fprintf(obj.inst,':STATus:ERRor?');

        end
        
        function Close(obj)
            fclose(obj.inst);
        end
        
    end
    
end

