classdef lockinsr830dsp
    %lockin amplifier sr830-dsp driver
    
    properties
        inst
    end
    
    methods
        
        function obj = lockinsr830dsp(GPIB_Address)
            if ~exist('GPIB_Address')
                GPIB_Address = 8;
            end
            obj.inst = inst('ni', GPIB_Address);
            fopen(obj.inst);
            %             obj.clearErrors();
        end
        
        function OutXcos = readX(obj)
            fprintf(obj.inst,'outp?1')
            OutXcos = fscanf(obj.inst,'%f') ;
        end
        
        function OutYsin = readY(obj)
            fprintf(obj.inst,'outp?2')
            OutYsin = fscanf(obj.inst,'%f') ;
        end
        
        function OutAmp = readAmplitude(obj)
            fprintf(obj.inst,'outp?3')
            OutAmp = fscanf(obj.inst,'%f') ;
        end
        
        function OutPhase = readPhase(obj)
            fprintf(obj.inst,'outp?4')
            OutPhase = fscanf(obj.inst,'%f') ;
        end
        
        function clearErrors(obj)
            fprintf(obj.inst,'errs?');
        end
        
    end
    
end
