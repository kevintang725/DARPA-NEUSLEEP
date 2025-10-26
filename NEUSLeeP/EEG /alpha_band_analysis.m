
clear; clc;
close all;
addpath(genpath('/Users/KevinTang/Desktop/Desktop - Macbook Pro (Kevin)/UTAustin/Code/eeglab2023.0'));
addpath(genpath('Open_Eyes Closed'));
newset = 0;
event_num = 10;
if newset
    fprintf('enter "eeglab" in the command line');
else
    EEG = pop_loadset();
end

fs = EEG.srate; % Sampling rate
%%
channel = 1;
start_epoch = 15;
%%
startEndTrigger = [];
for i = start_epoch:(event_num+start_epoch-1)    %total event number starting from 2 to ...
    startEndTrigger = [startEndTrigger; EEG.event(i).latency]; 
end
%%
windowlength  = 10*fs;
segmentedData = [];
for i = 1:length(startEndTrigger)
    segmentedData = [segmentedData; double(EEG.data(channel,nearest(startEndTrigger(i)):nearest(startEndTrigger(i))+windowlength-1))];
end

%% filtered data 
Graphene_power =[]; Graphene_amp = [];
windowLength = 1 *fs;
[b,a] = butter(2,[8,13]/(fs/2)); 
for i = 1:event_num
    Graphene_power = [Graphene_power; filter(1/(windowLength)*ones(windowLength,1),1,filtfilt(b,a,segmentedData(i,:)).^2)]; % filter the data
    Graphene_amp = [Graphene_amp; filtfilt(b,a,segmentedData(i,:))];
end

%% average alpha power difference between open- and close- eyes trials
Graphene_power_OE = [];
Graphene_power_CE = [];
averageALPHApower = mean(Graphene_power,2);
for i = 1:length(Graphene_power(:,1))
    if rem(i,2) == 1
        Graphene_power_OE = [Graphene_power_OE averageALPHApower(i)];
    else
        Graphene_power_CE = [Graphene_power_CE averageALPHApower(i)];
    end
end
meanPower = [mean(Graphene_power_OE);mean(Graphene_power_CE)];
stdH = [std(Graphene_power_OE);std(Graphene_power_CE)];
stdL = stdH;
figure;
bar(1:2,meanPower,'LineWidth',1); hold on;
er = errorbar(1:2,meanPower,stdL,stdH,"LineWidth",2);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';
hold off;
set(gca,'XTickLabel',{'open','close'})
title('AVG alpha power');
ylabel('Alpha band power (\muV^2)');
filename = append('AVGalphaPOWER',EEG.setname);
savefig(filename);
%% PSD Visualization
Graphene_CE = [];
Graphene_OE = [];
[b,a] = butter(2,[1,30]/(fs/2)); 
for i = 1:length(segmentedData(:,1))
    if rem(i,2) == 0
        Graphene_CE = [Graphene_CE; filtfilt(b,a,segmentedData(i,:))];
    else
        Graphene_OE = [Graphene_OE; filtfilt(b,a,segmentedData(i,:))];
    end
end

open_eyes_psd = [];
close_eyes_psd = [];
figure;
subplot(2,1,1);
for i = 1:(event_num/2)
[open_eyes_psd(i,:),f2] = psdcal(4,0.1,30,fs,Graphene_OE(i,:));
plot(f2,open_eyes_psd(i,:),"LineWidth",2); hold on;
end
title('open');
ylabel('Power spectrual density (\muV^2/Hz)');
xlabel('Frequency (Hz)');
hold off;

subplot(2,1,2);
for i = 1:(event_num/2)
[close_eyes_psd(i,:),f2] = psdcal(4,0.1,30,fs,Graphene_CE(i,:));
plot(f2,close_eyes_psd(i,:),"LineWidth",2); hold on;
end
title('close');
ylabel('Power spectral density (\muV^2/Hz)');
xlabel('Frequency (Hz)');
hold off;
filename = append('open_close',EEG.setname);
savefig(filename);

figure
plot(f2,mean(open_eyes_psd),"LineWidth",2); hold on;
plot(f2,mean(close_eyes_psd),"LineWidth",2); hold off;
legend('Open','Closed')
title('Grand Average PSD')
ylabel('Power spectral density (\muV^2/Hz)');
xlabel('Frequency (Hz)');
%% SNR calculation (close eyes period)
BG = [];
SOI = [];
for i = 1:length(close_eyes_psd(:,1))
    BG(i) = mean(cat(2,close_eyes_psd(i,1:41),close_eyes_psd(i,92:length(close_eyes_psd(i,:)))));
    SOI(i) = mean(close_eyes_psd(i,41:92));
end

SNR = 10.*log(SOI./BG);
mSNR = mean(SNR); stdSNR = std(SNR);
figure;
bar(1,mSNR); hold on;
er = errorbar(1,mSNR,stdSNR,stdSNR,"LineWidth",2);    
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
hold off;
title('SNR')
set(gca,'XTickLabel',{'SNR: alpha [8-13] vs bg [4-7.9, 13.1-30]'})
filename = append('SNR',EEG.setname);
savefig(filename);

