classdef shutter < handle
    properties
        comObj
        togglePos=[80 0;0 120]%Position 2 - 1 means beam open 0 means beam blocked - ID 1 is shutter and ID 2 is flip mount
        toggleState=[0;0]; % States are either 0 or 1
    end
    methods
        function obj=shutter()
            %% Instrument Connection
            
            % Find a serial port object.
            obj.comObj = instrfind('Type', 'serial', 'Port', 'COM6', 'Tag', '');
            
            % Create the serial port object if it does not exist
            % otherwise use the object that was found.
            if isempty(obj.comObj)
                obj.comObj = serial('COM6');
            else
                fclose(obj.comObj);
                obj.comObj = obj.comObj(1);
            end
            obj.comObj.Baudrate=115200;
            % Connect to instrument object, obj1.
            fopen(obj.comObj);
            obj.setAngle(1,obj.togglePos(1,1));
            obj.setAngle(2,obj.togglePos(2,1));
        end
        
        function flipUp(obj, id)
            obj.setAngle(id,obj.togglePos(id,2));
            obj.toggleState(id)=1;
        end
        function flipDown(obj,id)
            obj.setAngle(id,obj.togglePos(id,1));
            obj.setAngle(id,obj.togglePos(id,1)+10);
            obj.toggleState(id)=0;

        end
        
        function setAngle(obj,id,angle)
            fprintf(obj.comObj,'3,%i,%i;\n',[id-1,angle]);
        end
        function on(obj,id)
            obj.setAngle(id,obj.togglePos(id,2));
            obj.toggleState(id)=1;
            
        end
        function off(obj,id)
            obj.setAngle(id,obj.togglePos(id,1));
            obj.toggleState(id)=0;
        end
        function toggle(obj,id)
            newState=mod(obj.toggleState(id)+1,2);
            obj.setAngle(id,obj.togglePos(id,newState+1));
            obj.toggleState(id)=newState;
        end
        
        function delete(obj)
            fclose(obj.comObj);
        end
        
    end
end