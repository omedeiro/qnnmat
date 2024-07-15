close all
import com.comsol.model.*
import com.comsol.model.util.*
addpath exports
model = mphopen('diode_llmatlab_v8.mph');

runname = "const_bias_steady_state-";
runtime = datestr(now, 'yyyy-mm-dd-HH-MM-SS');
expath = pwd+"\exports\"+runname+runtime;
mkdir(expath)
addpath(expath)

tstop=1000;
model.param.set('tstop', tstop);

std1 = model.study('std1');
std1.feature('time').set('tlist', 'range(0,25,tstop)');

width=8.33;
j0 = 0:0.04:0.7;
N = length(j0);

Ba = -0.2:0.015:0;
M = length(Ba);

V = zeros(N,M); % voltage
Vs = zeros(N,M); % voltage with switch check
Ic = zeros(1,M);

x = -20:0.1:20;
y = -width/2:0.5:width/2;
z = 0;
[xx,yy] = meshgrid(x,y);
cords = [xx(:),yy(:)]';

x2 = 0; 
y2 = -width/2:0.01:width/2-0.6*width;
z2 = 0;
[xx2,yy2] = meshgrid(x2,y2);
cords2 = [xx2(:),yy2(:)]';

x3 = [-1.8]; 
y3 = -width/2:0.01:width/2;
z3 = 0;
[xx3,yy3] = meshgrid(x3,y3);
cords3 = [xx3(:),yy3(:)]';

x3 = [1.8]; 
y3 = -width/2:0.01:width/2;
z3 = 0;
[xx3,yy3] = meshgrid(x3,y3);
cords3A = [xx3(:),yy3(:)]'; 

count_total = N*M;
count=1;
tic
for j = 1:M
    for i = 1:N
        disp("Start: " + datestr(now))
        tstart = tic;
        model.param.set('j0', j0(i));
        model.param.set('Ba', Ba(j));
        model.study('std1').run;

        tplot = tstop;

        [x0, y0, Ex, Ey] = mphinterp(model,{'x','y','-u3t', 'u4t'},'coord',cords, 't', tplot);
%         [x0, y0, Ex, Ey] = mphinterp(model,{'x','y','-u3t', 'u4t'},'domain',1, 't', tplot);

        Exx = reshape(Ex, numel(y),numel(x));
        Eyy = reshape(Ey, numel(y),numel(x));

        Emag = sqrt(Exx.^2+Eyy.^2);
        Emag(isnan(Emag)) = 0;

%         V(i,j) = trapz(x, Emag,2)*(x(2)-x(1))*sign(j0(i));
        V(i,j) = trapz(y,trapz(x, Emag,2)',2)*(x(2)-x(1))*(y(2)-y(1));


        [x02, y02, cpd, Ix, Iy, Ecenx, Eceny] = mphinterp(model,{'x','y','u^2+u2^2', '-(u3yy-u4xy)', '-(u4xx-u3xy)', '-u3t', 'u4t'},'coord',cords2,'t', tplot);
        [x03, y03, cpdside] = mphinterp(model,{'x','y','u^2+u2^2'}, 'coord', cords3, 't', tplot);
        [x03A, y03A, cpdsideA] = mphinterp(model,{'x','y','u^2+u2^2'}, 'coord', cords3A, 't', tplot);

        s1 = max(cpd,[],2)<0.2;
        s2 = max(cpdside,[],2)<0.2;
        s3 = max(cpdsideA,[],2)<0.2;

        if s1+s2+s3>=1
            switched = 1;
            Ic(j) = j0(i);
            Vs(i,j) = V(i,j)*switched;
            disp("====== Switched "+j0(i)+"uA ====== Voltage = "+V(i,j))
            mphplot(model, 'pg1')
            drawnow
            break
        else
            switched = 0;
            Vs(i,j) = V(i,j)*switched;
        end
        disp("Voltage = "+V(i,j))

        f2 = figure(2);
        f2.Position = [2639 573 560 420];
        imagesc(Ba,j0,V)
        ax = gca;
        ax.YDir = 'normal';
        colorbar

        figure(3)
        cla
        mphplot(model, 'pg1')

        toc(tstart)
        fprintf('%d%% complete \n', round(count/count_total*100, 0))
        count = count+1;
        drawnow

    end


end
toc

plot(Ba, Ic, '-o')
timestr = datestr(now, 'yyyy-mm-dd-HH-MM-SS');
save(expath+"\diode_steady_state-"+timestr, 'j0', 'Ba', 'V', 'Vs', 'Ic')
