classdef optimizer < handle
    %OPTIMIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        varsi
        optimum
        varLimits
        costFunction
        criteria
        maxIters
        maxTime
        functionEvaluations
        console
        instruments
        
        tempHistory
        %% following track all optimal values (at that time)
        varHistory
        timeHistory
        costHistory
        %% following track all evaluations
        evalVarHistory
        evalTimeHistory
        evalCostHistory
        
        
    end
    
    methods
        function obj = optimizer(variables, costFunctionHandle, criteriaHandle, maxIters, maxTime, instruments)
            obj.varsi = variables(:,1);
            obj.optimum = obj.varsi;
            obj.varLimits = variables(:,2:3);
            obj.costFunction = costFunctionHandle;
            obj.criteria = criteriaHandle;
            obj.maxIters = maxIters;
            obj.maxTime = maxTime;
            obj.functionEvaluations = 0;
            obj.console = console('Optimizer');
            obj.instruments = instruments;
        end
        
        function saveValue(obj, vars, cost, time)
            obj.evalVarHistory = [obj.evalVarHistory, vars(:)];
            obj.evalCostHistory = [obj.evalCostHistory, cost];
            obj.evalTimeHistory = [obj.evalTimeHistory, time];
        end
        
        function run(obj, plotOn)
            T = 0;
            
            iter = 0;
            tstart = tic;
            lastCost = inf;
            n = numel(obj.varsi);
            size(obj.varsi)
            v = [obj.varsi(1)+rand(1,n+1).*obj.varsi(1)/10;...
                obj.varsi(2)+rand(1,n+1).*obj.varsi(2)/10;];%...
                %obj.varsi(3)+rand(1,n+1).*obj.varsi(3)/10];%...
                %obj.varsi(4)+rand(1,n+1).*obj.varsi(4)/1000];%
            %v = zeros(n,n+1);
            size(v)
            fv = inf(1,n+1);
            %v(:,1) = obj.varsi;
            x = obj.varsi;
            fv(:,1) = obj.costFunction(x, obj.instruments);
            obj.functionEvaluations = 1;
            
            rho = 1; chi = 2; psi = 0.5; sigma = 0.5;
            
            obj.console.print('Optimization Stared.')
            obj.console.print(' Iteration   Func-count     min f(x)       T         Procedure');
            
            if plotOn
                fig = figure();
            end
            
            while iter <= obj.maxIters && toc(tstart) <= obj.maxTime && obj.criteria(obj.optimum, lastCost)

                % xbar = average of the n (NOT n+1) best points
                xbar = sum(v(:,1:n), 2)/n;
                xr = (1 + rho)*xbar - rho*v(:,end);
                x(:) = xr;
                fxr = obj.costFunction(x, obj.instruments); obj.saveValue(x, fxr, toc(tstart));
                obj.functionEvaluations = obj.functionEvaluations+1;

                if fxr < fv(:,1)
                    % Calculate the expansion point
                    xe = (1 + rho*chi)*xbar - rho*chi*v(:,end);
                    x(:) = xe; fxe = obj.costFunction(x, obj.instruments); obj.saveValue(x, fxe, toc(tstart));
                    obj.functionEvaluations = obj.functionEvaluations+1;
                    if fxe < fxr
                        v(:,end) = xe;
                        fv(:,end) = fxe;
                        how = 'expand';
                    else
                        v(:,end) = xr;
                        fv(:,end) = fxr;
                        how = 'reflect';
                    end
                else % fv(:,1) <= fxr
                    if fxr < fv(:,n)
                        v(:,end) = xr;
                        fv(:,end) = fxr;
                        how = 'reflect';
                    else % fxr >= fv(:,n)
                        % Perform contraction
                        if fxr < fv(:,end)
                            % Perform an outside contraction
                            xc = (1 + psi*rho)*xbar - psi*rho*v(:,end);
                            x(:) = xc; fxc = obj.costFunction(x, obj.instruments); obj.saveValue(x, fxc, toc(tstart));
                            obj.functionEvaluations = obj.functionEvaluations+1;

                            if fxc <= fxr
                                v(:,end) = xc;
                                fv(:,end) = fxc;
                                how = 'contract outside';
                            else
                                % perform a shrink
                                how = 'shrink';
                            end
                        else
                            % Perform an inside contraction
                            xcc = (1-psi)*xbar + psi*v(:,end);
                            x(:) = xcc; fxcc = obj.costFunction(x, obj.instruments); obj.saveValue(x, fxcc, toc(tstart));
                            obj.functionEvaluations = obj.functionEvaluations+1;

                            if fxcc < fv(:,end)
                                v(:,end) = xcc;
                                fv(:,end) = fxcc;
                                how = 'contract inside';
                            else
                                % perform a shrink
                                how = 'shrink';
                            end
                        end
                        if strcmp(how,'shrink')
                            for j=2:n+1
                                v(:,j)=v(:,1)+sigma*(v(:,j) - v(:,1));
                                x(:) = v(:,j); fv(:,j) = obj.costFunction(x, obj.instruments); obj.saveValue(x, fv(:,j), toc(tstart));
                            end
                            obj.functionEvaluations = obj.functionEvaluations + n;
                        end
                    end
                end
                [fv,j] = sort(fv);
                v = v(:,j);
%                itercount = itercount + 1;
%                 if prnt == 3
                    obj.console.print(sprintf(' %5.0f        %5.0f     %12.6g          %2.3f           %s', iter, obj.functionEvaluations, fv(1), T, how));
%                 elseif prnt == 4
%                     disp(' ')
%                     disp(how)
%                     v
%                     fv
%                     func_evals
%                 end
                % OutputFcn and PlotFcns call
%                 if haveoutputfcn || haveplotfcn
%                     [xOutputfcn, optimValues, stop] = callOutputAndPlotFcns(outputfcn,plotfcns,v(:,1),xOutputfcn,'iter',itercount, ...
%                         func_evals, how, fv(:,1),varargin{:});
%                     if stop  % Stop per user request.
%                         [x,fval,exitflag,output] = cleanUpInterrupt(xOutputfcn,optimValues);
%                         if  prnt > 0
%                             disp(output.message)
%                         end
%                         return;
%                     end
%                 end
%                     
                    
                    
%                     explore = linspace(-1,1,21);
%                     costs = zeros(size(explore));
%                     for j = 1:numel(explore)
%                         trial = obj.vars;
%                         trial(i) = trial(i) + explore(j);
%                         costs(j) = obj.costFunction(trial);
%                     end
%                     [lastCost, minLoc] = min(costs);
%                     obj.vars(i) = obj.vars(i) + explore(minLoc);
                %end
                lastCost = fv(1);
                obj.optimum = v(:,1);
                iter = iter + 1;
                obj.varHistory = [obj.varHistory; obj.optimum'];
                obj.costHistory = [obj.costHistory; lastCost];
                obj.timeHistory = [obj.timeHistory; toc(tstart)];
                obj.tempHistory = [obj.tempHistory; T];
                
                %% add annealing
                v(:,2:end) = v(:,2:end) + rand(size(v(:,2:end))).*(repmat(obj.varsi(:),1,size(v(:,2:end),2)) * T);
                T = T*0.9;
                
                if plotOn
                    figure(fig);
                    semilogy(obj.timeHistory, obj.costHistory);
                    xlabel('Time (s)')
                    ylabel('Cost')
                    title('Optimization Progress')
                    grid on;
                end
            end
            
            if iter > obj.maxIters
                obj.console.error(['Optimization Stopped: Ran to maxIters (' num2str(obj.maxIters) ').'])
            end
            if toc(tstart) > obj.maxTime
                obj.console.error(['Optimization Stopped: Ran over maxTime (' num2str(obj.maxTime) 's).'])
            end
            obj.console.print('Best value saved to .optimum');
        end

    end
    
end

