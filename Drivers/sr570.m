classdef sr570 
    
    properties
        inst
        console
    end
    
    methods
        function obj = sr570(Address)
            if ~exist('Address')
                Address = 'COM8';
            end
            obj.inst = serial(Address);
            fopen(obj.inst);
        end
        
        function setSensitivity(obj,sensitivity)
            if ischar(sensitivity)
                %                            0     1     2     3      4      5       6      7        8      9    10    11     12    13      14     15      16       17    18    19    20     21     22     23     24      25      26     27   
                sensitivityList = cellstr({'1pA','2pV','5pA','10pA','20pV','50pA','100pA','200pV','500pA','1nA','2nV','5nA','10nA','20nV','50nA','100nA','200nV','500nA','1uA','2uV','5uA','10uA','20uV','50uA','100uA','200uV','500uA','1mA'});
                indexC=strfind(sensitivityList,sensitivity);
                index=find(not(cellfun('isempty',indexC)))-1;
            else
                index = sensitivity;
            end
            fprintf(obj.inst,['SENS ',num2str(index)]);
        end
        
    end
    
end

