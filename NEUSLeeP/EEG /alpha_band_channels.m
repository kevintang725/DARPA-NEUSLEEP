
clear; clc;
close all;
addpath(genpath('/Users/KevinTang/Desktop/Desktop - Macbook Pro (Kevin)/UTAustin/Code/eeglab2023.0'));
addpath(genpath('Open_Eyes Closed'));
newset = 0;
event_num = 9;
if newset
    fprintf('enter "eeglab" in the command line');
else
    EEG = pop_loadset();
end

fs = EEG.srate; % Sampling rate

%% Set Plot Parameters
% Set Time Interval Plots (min)
t1 = 0;
t2 = inf;

% Set Colorbar limits (dB)
lb = 5;
ub = 20;

% Channel labels
ch_label1 = ["T3", "F7", "FP1", "FPz", "EoG", "EMG"];
ch_label2 = ["T4", "F8", "FP2", "FPz", "EoG", "EMG"];

% Monitor to Plot
monitor = 1;
%%
start_epoch = 5;

figure('Name', 'Grand Average PSD')
for channel = 1:12
    %% Obtain Event Points
    startEndTrigger = [];
    for i = start_epoch:(event_num+start_epoch-1)    %total event number starting from 2 to ...
        startEndTrigger = [startEndTrigger; EEG.event(i).latency]; 
    end
    %% Segment Data
    secwin = 4;
    windowlength  = 10*fs;
    segmentedData = [];
    for i = 1:length(startEndTrigger)
        segmentedData = [segmentedData; double(EEG.data(channel,nearest(startEndTrigger(i))+secwin*fs:nearest(startEndTrigger(i))+windowlength-1 - secwin*fs))];
        segmentedData = segmentedData - mean(segmentedData);
    end

    %% filtered data 
    Graphene_power =[]; Graphene_amp = [];
    windowLength = 1 *fs;
    [b,a] = butter(3,[8,13]/(fs/2)); 
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
    meanPower{channel} = [mean(Graphene_power_OE);mean(Graphene_power_CE)];
    stdH{channel} = [std(Graphene_power_OE);std(Graphene_power_CE)];
    stdL{channel} = [std(Graphene_power_OE);std(Graphene_power_CE)];
    %% PSD Visualization
    Graphene_CE = [];
    Graphene_OE = [];
    [b,a] = butter(3,[1,30]/(fs/2)); 
    for i = 1:length(segmentedData(:,1))
        if rem(i,2) == 0
            Graphene_CE = [Graphene_CE; filtfilt(b,a,segmentedData(i,:))];
        else
            Graphene_OE = [Graphene_OE; filtfilt(b,a,segmentedData(i,:))];
        end
    end

    open_eyes_psd{channel} = [];
    close_eyes_psd{channel} = [];
    
    
    %% Plot
    [open_eyes_psd,close_eyes_psd,f2, bad_epoch_open, bad_epoch_close] = plot_figure(event_num, fs, Graphene_OE, Graphene_CE, open_eyes_psd, close_eyes_psd, channel);

end

%% Plot Summary
figure('Name', 'Alpha Power')
for channel = 1:12
    plot_alpha_power(meanPower, stdL, stdH, channel, event_num)
end

%% Time-Frequency Analysis: sTFT

fs = EEG.srate; % Sampling rate
% load a signal
filter = [1 30]; % band-pass condition
[b,a] = butter(3,filter/(fs/2));

%% Plot Sleep Data (NEUSLEEP)
%figure('Position', [300, 300, 110*10, 27*10]);
scrsz = get(0,'MonitorPositions');
figure('name', "NEUSLEEP",'Position',[1 scrsz(monitor,4)/2 scrsz(monitor,3)/2 scrsz(monitor,4)])
for ch = 1:height(EEG.data)/2
    subplot(height(EEG.data)/2,1,ch)
    signal = double(EEG.data(ch,:));
    x = filtfilt(b, a,signal);
    xlen = length(x(1,:));              % signal length
    t = (0:xlen-1)/fs;                  % time vector

    % Time-Frequency Analysis Parameters
    wlen = 1024;                        % window length (recommended to be power of 2)
    nfft = 2*wlen;                      % number of fft points (recommended to be power of 2)
    hop = wlen/4;                       % hop size (recommended to be 1/4 of the window length)

    % Perform STFT
    w1 = blackman(wlen, 'periodic');
    [~, fS1, tS1, PSD1] = spectrogram(x(1,:), w1, wlen-hop, nfft, fs);
    Samp1 = 20*log10(sqrt(PSD1.*enbw(w1, fs))*sqrt(2));

    % Plot Data
    plot_spectrogram(tS1, fS1, Samp1, ch_label1, t1, t2, lb, ub, ch)
end
saveas(gcf,'NEUSLEEP.png')

%% Plot Sleep Data (Commercial Electrodes)
%figure('Position', [300, 300, 110*10, 27*10]);
scrsz = get(0,'MonitorPositions');
figure('name', "Commercial Ag/AgCl",'Position',[scrsz(monitor,3)/2 scrsz(monitor,4)/2 scrsz(monitor,3)/2 scrsz(monitor,4)])
for ch = 7:height(EEG.data)
    subplot(height(EEG.data)/2,1,ch-6)
    signal = double(EEG.data(ch,:));
    x = filtfilt(b, a,signal);
    xlen = length(x(1,:));              % signal length
    t = (0:xlen-1)/fs;                  % time vector

    % Time-Frequency Analysis Parameters
    wlen = 1024;                        % window length (recommended to be power of 2)
    nfft = 2*wlen;                      % number of fft points (recommended to be power of 2)
    hop = wlen/4;                       % hop size (recommended to be 1/4 of the window length)

    % Perform STFT
    w1 = blackman(wlen, 'periodic');
    [~, fS1, tS1, PSD1] = spectrogram(x(1,:), w1, wlen-hop, nfft, fs);
    Samp1 = 20*log10(sqrt(PSD1.*enbw(w1, fs))*sqrt(2));

    % Plot Data
    plot_spectrogram(tS1, fS1, Samp1, ch_label2, t1, t2, lb, ub, ch-6)
end
saveas(gcf,'Commercial.png')
%% Functions

% Plot the spectrogram
function plot_spectrogram(tS1, fS1, Samp1, ch_label, t1 , t2, lb, ub, ch)
    surf(tS1, fS1(1:125), Samp1(1:125,:))
    shading interp
    axis tight
    box on
    set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    title(ch_label(ch))
    view(0, 90)
    caxis([lb, ub])
    xlim([t1 t2])
    colormap('turbo')

    % enable colorbar
    hcol = colorbar(['EastOutside']);
    set(hcol, 'FontName', 'Arial', 'FontSize', 12,'FontWeight','Bold')
    ylabel(hcol, 'Magnitude (dB)')
end

function [open_eyes_psd,close_eyes_psd,f2, bad_epoch_open, bad_epoch_close] = plot_figure(event_num, fs, Graphene_OE, Graphene_CE, open_eyes_psd, close_eyes_psd, channel)
    %figure('Name', string(channel))
    %subplot(5,4,channel);
    bad_epoch_open{channel} = [];
    for i = 1:(event_num/2)
    [open_eyes_psd{channel}(i,:),f2] = psdcal(4,0.1,30,fs,Graphene_OE(i,:));
    if (open_eyes_psd{channel}(i,41) > 10)
        open_eyes_psd{channel}(i,:) = [];
        bad_epoch_open{channel} = [bad_epoch_open{channel} i];
    end
    %plot(f2,open_eyes_psd(i,:),"LineWidth",2); hold on;
    end
    %title('open');
    %ylabel('Power spectrual density (\muV^2/Hz)');
    %xlabel('Frequency (Hz)');
    %axis([-inf inf 0 10]);
    %hold off;

    %subplot(5,4,channel+14);
    bad_epoch_close{channel} = [];
    for i = 1:(event_num/2)
    [close_eyes_psd{channel}(i,:),f2] = psdcal(4,0.1,30,fs,Graphene_CE(i,:));
    if (close_eyes_psd{channel}(i,41) > 10)
        close_eyes_psd{channel}(i,:) = [];
        bad_epoch_close{channel} = [bad_epoch_close{channel} i];
    end
    %plot(f2,close_eyes_psd(i,:),"LineWidth",2); hold on;
    end
    %title('close');
    %ylabel('Power spectral density (\muV^2/Hz)');
    %xlabel('Frequency (Hz)');
    %axis([-inf inf 0 10]);
    %hold off;
    %filename = append('open_close',EEG.setname);
    %savefig(filename);

    %figure
    %channel_labels = ["F7", "FT7", "T7", "P7", "EoG1", "EoG2", "EMG", "F7", "FT7", "T7", "P7", "EoG1", "EoG2", "EMG"];
    channel_labels = ["T3", "F7", "FP1", "FPz", "EoG", "EMG","T4", "F8", "FP2", "FPz", "EoG", "EMG"];
    subplot(2,6,channel)
    plot(f2,mean(open_eyes_psd{channel}),"LineWidth",2); hold on;
    plot(f2,mean(close_eyes_psd{channel}),"LineWidth",2); hold off;
    xline(8,'k--', 'LineWidth', 1.5);
    xline(13,'k--', 'LineWidth', 1.5);
    axis([0 30 0 inf])
    legend('Open','Closed')
    title(channel_labels(channel));
    ylabel('Power spectral density (\muV^2/Hz)');
    xlabel('Frequency (Hz)');
    set(gca,'FontWeight','Bold');
end

function plot_alpha_power(meanPower, stdL, stdH, channel, event_num)
    %channel_labels = ["F7", "FT7", "T7", "P7", "EoG1", "EoG2", "EMG", "F7", "FT7", "T7", "P7", "EoG1", "EoG2", "EMG"];
    channel_labels = ["T3", "F7", "FP1", "FPz", "EoG", "EMG","T4", "F8", "FP2", "FPz", "EoG", "EMG"];
    subplot(2,6, channel)
    bar(1:2,meanPower{channel},'LineWidth',1); hold on;
    er = errorbar(1:2,meanPower{channel},stdL{channel}./sqrt(event_num),stdH{channel}./sqrt(event_num),"LineWidth",2);    
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';
    hold off;
    set(gca,'XTickLabel',{'open','close'})
    title(channel_labels(channel));
    ylabel('Alpha band power (\muV^2)');
    set(gca,'FontWeight','Bold');
    %filename = append('AVGalphaPOWER',EEG.setname);
    %savefig(filename);
end