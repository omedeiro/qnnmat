function obj = attenuator()
            if ~exist('GPIB_Address')
                GPIB_Address = 7;
            end
            obj = instrfind('Type', 'gpib', 'BoardIndex', 32, 'PrimaryAddress', GPIB_Address, 'Tag', '');
            if isempty(obj)
                obj = gpib('Agilent', 32, 7);
            else
                fclose(obj);
                obj = obj(1);
            end
            fopen(obj);
end
