clc;clear all;close all;

addpath(genpath('stress_strain'));

windows_switch = 0;  % 1 = using Windows OS

exp_type = 'TensileStress';  
% TensileStress; TensileStressCycling; 

date = '0109';
exp_on = '0%wt_PEIE';    % 
exp_on_fig = '0% wt PEIE';
samplenum = 4;   %how many samples
testnum = 1; %how many tests per sample
condition = '0';   %
filetype = '.txt';
tp = 'TensileStress';   %exp type
sample_crosssection = 20*2; % mm^2
sample_length = [25 20 20 20];   % to calculate young's modulus
%% Extension data

if windows_switch == 0
    en = '/';
    folderp = 'stress_strain/';
    folderp = append(folderp,tp,en,exp_on,en,'Distance');
else
    en = '\';
    folderp = 'stress_strain\';
    folderp = append(folderp,exp_type,en,exp_on,en,'Distance');
end 
cd(folderp);

timeused = zeros(testnum,2,samplenum);

for i = 1: samplenum
    for j = 1:testnum
        filename = append(condition,'%','_','S',num2str(j),filetype);
        FID = fopen(filename);
        D = textscan(FID,'%s');
        fclose(FID);
        stringData = string(D{:});
        elapsetime = double(stringData(length(stringData)));
        timeused(j,1,i) = j;
        timeused(j,2,i) = elapsetime;
        TF = isnan(timeused(j,2,i));
        if TF == 1
            elapsetime = convertStringsToChars(stringData(length(stringData)-15));
            elapsetime = double(convertCharsToStrings(elapsetime(1:length(elapsetime)-7)));
            timeused(j,2,i) = elapsetime;
        end
    end
end

fq_ext = 30; %freqncy = 30 Hz for extension motor
%% pick coords for each test

fq_force = 80; %frequency = 80 Hz for force gauge meter

if windows_switch == 0
    folderp = 'stress_strain/';
    folderp = append(folderp,tp,en,exp_on,en,'Force');
    nav2force = folderp;
else
    en = '\';
    folderp = 'stress_strain\';
    folderp = append(folderp,tp,en,exp_on,en,'Force');
    nav2force = folderp;
end

%nav2force = append(nav2force,en,exp_on,en);

%cd(nav2force);
figure;
coord = zeros(3,2,testnum,samplenum);  %find starting, linear end, and experiment end points

for i = 1:samplenum
    for j = 1:testnum
        filename = append(condition,'%','_','S',num2str(j),filetype);
        FID = fopen(filename);
        D = textscan(FID,'%s');
        fclose(FID);
        stringData = string(D{:});
        data = stringData(27:length(stringData));
        dataF = zeros(length(data)/2,1);
        for m = 1: length(dataF)
            dataF(m) = data(m*2);
        end
        dataF = movmean(dataF,5);
        plot(dataF);
        ylabel('N');
        xlabel('Sample#')
        ttl = append('S',num2str(i),'T',num2str(j),' ',tp,exp_on_fig);
        title(ttl)
        [coord(:,1,j,i),~] = ginput(3);  % select starting, linear end point, and exp end point in this order
        coord(:,1,j,i) = int64(coord(:,1,j,i));
        for n = 1:length(coord(:,1,j,i))
            coord(n,2,j,i) = dataF(coord(n,1,j,i));   % find actual force value with sample index
        end
        close;
        tstress_data{i,j} = abs(dataF(coord(1,1,j,i):coord(3,1,j,i)));
        linearregion{i,j} = abs(dataF(coord(1,1,j,i):coord(2,1,j,i)));
        t = length(tstress_data{i,j})/fq_force;
        dist = t*0.038*fq_ext;  % time of extension counted in * step dist * freqency of motor
        ext{i,j} = 0:dist/(length(tstress_data{i,j})-1):dist;
    end
end

%%
n = 1;

for i = 1:samplenum
    for j = 1:testnum
        y = (tstress_data{i,j}*1000)/sample_crosssection; % unit from N/mm^2 to kpa
        subplot(testnum*samplenum,1,n);
        plot(ext{i,j}, y, 'LineWidth', 1.5);
        set(gca,'LineWidth',1.5);
        ylabel('Stress (kPa)');
        xlabel('Displacement (mm)');
        stressstraindata{i,j}= y;
%         ymax = round(max(y)+10);
        ylim([0 50])   % or ylim([0 ymax])
        xlim([0 130])
        ttl = append('S',num2str(i),'T',num2str(j),' ',tp);
        title(ttl);
        legend(exp_on_fig,'Box', 'Off')
        n = n+1;
    end
end
%%  save figures
% cd ..\..\..\..\..\figures\
% figname = append(exp_type,'_',condition,'.fig');
% savefig(figname);

%%  calculate Young's modulus
n = 1;
 
for i = 1:samplenum
    for j = 1: testnum
        y = (linearregion{i,j}*1000)/sample_crosssection;
        strain{i,j} = 100*(ext{i,j}/sample_length(n));
        x = strain{i,j}(1:length(y))/100;
        p = polyfit(x,y,1);
        f = polyval(p,x)';
        subplot(testnum*samplenum,1,n);
        plot(x,y,'LineWidth',1.5); hold on;
        plot(x,f,'r--');
        legend('exp')
        tb{i,j} = table(x',y,f,y-f,'VariableNames',{'X','Y','Fit','FitError'});
        pcorr{i,j} = corr(y,f);
        n = n + 1;
        if pcorr{i,j} > 0.90
            YModulus{i,j} = (y(length(y))/x(length(x)));
        end
        
    end
end
dataname = append(exp_type,'_',condition,'.mat');
save(dataname);





