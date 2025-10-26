clc;clear all;close all;                

addpath(genpath('Adhesion Strength'));
cond = '1_';
filetype = '.txt';
sample_width = 1; % cm


%% Extension data

cd '/Users/kevintang/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Desktop-Kevin/UTAustin/Writings/Publications/Bioadhesive Hydrogel-Coupled and Miniaturized Ultrasound Transducer System for Long-Term, Wearable Neuromodulation/Data/Device Characterization/Hydrogel/Raw data_BZP and non/Raw data_BZP treated/ex';
dirr = append(cond,'*.txt');
filelist = dir(dirr);

timeused = zeros(length(filelist),2);
for j = 1:length(filelist)
    filename = filelist(j).name;
    FID = fopen(filename);
    D = textscan(FID,'%s');
    fclose(FID);
    stringData = string(D{:});
    elapsetime = double(stringData(length(stringData)));
    timeused(j,1) = j;
    timeused(j,2) = elapsetime;
    TF = isnan(timeused(j,2));
    if TF == 1
        elapsetime = convertStringsToChars(stringData(length(stringData)-15));
        elapsetime = double(convertCharsToStrings(elapsetime(1:length(elapsetime)-7)));
        timeused(j,2) = elapsetime;
    end
end
fq_ext = 30; %freqncy = 30 Hz for extension motor
%% pick coords for each test

fq_force = 80; %frequency = 80 Hz for force gauge meter

cd ..
cd Force

coord = zeros(4,2,length(filelist),1);
avg_vlu = [];
figuredata = ([]);
for i = 1:length(filelist)
    filename = filelist(i).name;
    FID = fopen(filename);
    D = textscan(FID,'%s');
    fclose(FID);
    stringData = string(D{:});
    data = stringData(27:length(stringData));

    dataF = zeros(floor(length(data)/2),1);
    for m = 1: length(dataF)
        dataF(m) = data(m*2);
    end
    dataF = movmean(dataF,5);
    plot(dataF);
    title(i);
    ylabel('N');
    xlabel('Sample#')
    legend('choose start and end points')
    startsends = zeros(2,2);
    [startsends(:,1),~] = ginput(2);
    startsends(:,1) = int64(startsends(:,1));
    for n = 1:length(startsends(:,1))
        startsends(n,2) = dataF(startsends(n,1)) ;  %
    end
    shift = dataF(1);
    close;
    for j = 1:length(dataF)
        dataF(j) = dataF(j) - shift;
    end
    dataF = abs(dataF(startsends(1,1):startsends(2,1)))/sample_width;
    data_figure = dataF;
    plot(dataF);
    title(i);
    ylabel('N');
    xlabel('Sample#')
    legend('choose start and end points to average')
    startsends = zeros(2,2);
    [startsends(:,1),~] = ginput(2);
    startsends(:,1) = int64(startsends(:,1));
    for n = 1:length(startsends(:,1))
        startsends(n,2) = dataF(startsends(n,1)) ;  %find actual force value with sample index
    end
    dataF = abs(dataF(startsends(1,1):startsends(2,1)));
    avg_vlu = [avg_vlu mean(dataF)];
    close;
    figuredata(i).sample = data_figure;

end
for i = 1: length(figuredata)
    t = length(figuredata(i).sample)/fq_force;
    dist = t*0.038*fq_ext;  % time of extension counted in * step dist * freqency of motor
    ext = 1/(length(figuredata(i).sample)):dist/(length(figuredata(i).sample)):dist;
    figure;
    fig = plot(ext, figuredata(i).sample, 'LineWidth', 1.5);
    set(gca,'LineWidth',1.5);
    ylabel('Adhesion force (N/cm)');
    xlabel('Displacement (mm)');
    title('T-peeling adhesion');
    fn = append('figure',cond,num2str(i));
    saveas(fig, fn,'png')
end

%%
cd ..
cd ..
