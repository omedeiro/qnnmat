classdef baseFunctions
    %collection of functions used in processing lab data. 
    
    properties
        
    end
    
    methods
        
        function d = import_mat_list(obj, file_path)
            % import .mat files from directory at file_path. Struct 1xN is
            % returned. Each .mat must have same fields. 

            files = dir(join([file_path,'/*.mat']));
            N = length(files);
            for i = N:-1:1 %Backwards so that memory is pre allocated 
                disp(strcat("Imported ",files(i).name))
                d(i) = load(files(i).name); %not sure if there is a nice way to intialize a nxm struct.
            end
            
        end
        
        function Lk = kinetic_inductance(obj, b)
            %Returns kinetic inductance in pH
            tau = 1/b;
            Lk = tau*50 * 1e12;
        end
        
        function data = readTcTxt(obj,file_name)
            formatSpec = '%f, %f';
            sizeA = [2 Inf];
            fileID = fopen(file_name,'r');
            data = fscanf(fileID,formatSpec,sizeA);
        end
        
        
    end
        
        
end
    
   