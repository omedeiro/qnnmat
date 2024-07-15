close all
import com.comsol.model.*
import com.comsol.model.util.*
addpath exports
model = mphopen('diode_llmatlab_v7.mph');

tstop=100;
model.param.set('tstop', tstop);

std1 = model.study('std1');
std1.feature('time').set('tlist', 'range(0,25,tstop)');


j0 = -0.6:0.05:0.6;
Ba = -0.5:0.1:0.5;

runname = "const_bias-";
runtime = datestr(now, 'yyyy-mm-dd-HH-MM-SS');

expath = pwd+"\exports\"+runname+runtime;
mkdir(expath)
addpath(expath)

N=length(j0);
M=length(Ba);
E=[];
Ic=zeros(N,M);
V=zeros(N,M);
Vs = zeros(N,M);
current=zeros(N,M);

c = turbo(M);
count_total = N*M;
count=1;



for j = 1:M
    for i = 1:N
        disp("Start: " + datestr(now))
        tic
        
        model.param.set('j0', j0(i));
        model.param.set('Ba', Ba(j));
        model.study('std1').run;

%         current(:,i) = mphglobal(model, 'an1(t)', 'dataset', 'dset1')*j0(i);

        pd = mpheval(model, 't');
        times = pd.d1(:,1);
        
        tplot = tstop;
        model.result('pg1').set('t', tplot);



        x = -10:0.1:10;
        y = 0;
        z = 0;
        [xx,yy] = meshgrid(x,y);
        cords = [xx(:),yy(:)]';
        [x0, y0, Ex, Ey] = mphinterp(model,{'x','y','-u3t', 'u4t'},'coord',cords, 't', tplot);
        E(:,:,1) = Ex;
        E(:,:,2) = Ey;
        Emag = vecnorm(E,2,3);
        V(i,j) = trapz(x, Emag,2)*(x(2)-x(1))*sign(j0(i));

        x2 = 0; 
        y2 = -1:0.01:1-sqrt(2)/2;
        z2 = 0;
        [xx2,yy2] = meshgrid(x2,y2);
        cords2 = [xx2(:),yy2(:)]';
        [x02, y02, cpd, Ix, Iy, Ecenx, Eceny] = mphinterp(model,{'x','y','u^2+u2^2', '-(u3yy-u4xy)', '-(u4xx-u3xy)', '-u3t', 'u4t'},'coord',cords2,'t', tplot);
        Ecen(:,:,1) = Ecenx;
        Ecen(:,:,2) = Eceny;
        Emagcen = vecnorm(Ecen,2,3);
        Vcen(i,j) = trapz(y2, Emagcen,2)*(y2(2)-y2(1));
        
        x3 = [-1 1]; 
        y3 = -1:0.01:1;
        z3 = 0;
        [xx3,yy3] = meshgrid(x3,y3);
        cords3 = [xx3(:),yy3(:)]';
        [x03, y03, cpdside] = mphinterp(model,{'x','y','u^2+u2^2'},'coord',cords3, 't', tplot);
        
        
        s1 = max(cpd,[],2)<0.2;
        s2 = max(cpdside,[],2)<0.2;
        
        if max(s1)>0 && max(s2)>0
            Ic(i,j) = j0(i);
            disp('SWITCHED ' + Ic(i,j))
            switched = 1;
        else
            switched = 0;
        end
        Vs(i,j) = V(i,j)*switched;

        f1 = figure(1);
        f1.Position = [2017 558 560 420];
        a = mphplot(model, 'pg1');
        hold on
        plot(xx2, yy2, '-r')
        plot(xx3, yy3, '-r') 
        plot(x0,y0, '-r')
        ax=gca;
        ax.XLim = [-5 5];
        ax.YLim = [-1 1];
        ax.Title.String = "I="+j0(i)+" B="+Ba(j)+" t="+tplot;

        


        
    
        f2 = figure(2);
        f2.Position = [2639 573 560 420];
        plot(j0, V(:,j), 'Color', c(j,:))
        hold off
        ylabel('voltage')
        xlabel('current')

        f3 = figure(3);
        f3.Position = [2639 57 560 420];
        plot(x, Emag, '-', 'Color', c(j,:))
        hold on
        xlabel('x')
        ylabel('E')
        title("t="+tplot)

        f4 = figure(4);
        f4.Position = [3227 49 560 420];
        plot(y2, Emagcen, '-', 'Color', c(j,:))
        xlabel('y [center]')
        ylabel('E field center')
        title("t="+tplot)
        hold on

        f5 = figure(5);
        f5.Position = [3228 566 560 420];
        plot(j0, Vs(:,j), '-o', 'Color', c(j,:))
        xlabel('I')
        ylabel('V')
        hold off

        timestr = datestr(now, 'yyyy-mm-dd-HH-MM-SS');

        model.result('pg1').set('ylabel',  "I="+j0(i)+" B="+Ba(j));
        model.result('pg1').set('ylabelactive', 'on');
%         model.result('pg2').set('ylabel',  "I="+j0(i)+" B="+Ba(j));
%         model.result('pg2').set('ylabelactive', 'on');
%         model.result.export('anim1').set('target', 'file');
%         model.result.export('anim1').set('giffilename',pwd+"\exports\"+runname+runtime+"\"+runname+timestr+"-current.gif");
%         model.result.export('anim1').run()

%         model.result.export('anim2').set('target', 'file');
%         model.result.export('anim2').set('giffilename',pwd+"\exports\"+runname+runtime+"\"+runname+timestr+"-field.gif");
%         model.result.export('anim2').run()


        
        toc
        fprintf('%d%% complete \n', round(count/count_total*100, 0))
        count = count+1;
        drawnow
    end



    f6 = figure(6);
    f6.Position = [2017 46 560 420];
    plot(Ba, Ic(j,:), '-o')
    xlabel('magnetic field')
    ylabel('critical current')
    hold on


end
exportgraphics(f1,expath+"\cpdplot-"+timestr+".png")

exportgraphics(f2,expath+"\iv-curve-"+timestr+".png")

exportgraphics(f3,expath+"\field-"+timestr+".png")
exportgraphics(f4,expath+"\Emagcen-"+timestr+".png")
exportgraphics(f5,expath+"\Vcen-"+timestr+".png")

exportgraphics(f6,expath+"\Ic-"+timestr+".png")

save(expath+"\data-"+timestr, 'j0', 'Ba', 'V', 'Vs')







function findSwitchPoint()
    s1 = max(cpd,[],2)<0.2;
    s2 = max(cpdside,[],2)<0.2;
    [switchpoint, loc]= min([find(s1==1, 1) find(s2==1, 1)]);

    if loc==1
        switched=s1;
    else
        switched=s2;
    end
    
    if isempty(switchpoint)
        Ic(i,j) = j0(i);
    else
        Ic(i,j) = current(switchpoint-1,i);
    end
end

    