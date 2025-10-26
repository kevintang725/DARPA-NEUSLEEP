
clear; clc; close all;
addpath(genpath('/Users/kevintang/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Desktop-Kevin/UTAustin/Project/DARPA-REM-Sleep/Experiments/Clinical/StudyB_2NightSleepHealthy/Data/eeglab2025.0.0'));
newset = 0;
if newset
    fprintf('enter "eeglab" in the command line');
else
    EEG = pop_loadset();
end

%%
restoredefaultpath
rehash toolboxcache
%% Set Plot Parameters
% Set Time Interval Plots (min)
% t1 = [0 1 2.5 4 5.5]
% t2 = [1 2 3.5 5 6.5]
t1 = 2.5*60;
t2 = 3.5*60;

% Set Colorbar limits (dB)
lb = 5;
ub = 20;

% Channel labels
ch_label1 = ["Fpz", "Fp1", "F7", "T3", "EoG", "EMG", "ECG", "Oz"];
%ch_label1 = ["Fpz", "Fp1", "F7", "T3", "ECG1","EoG", "EMG"];

%
total_channels = height(EEG.data);

% Monitor to Plot
monitor = 1;
%% Time-Frequency Analysis: sTFT

fs = EEG.srate; % Sampling rate
% load a signal
fpass1 = [1 30]; % band-pass condition
[b,a] = butter(3,fpass1/(fs/2),"bandpass");

fpass2 = [1 200]; % band-pass condition
[b2,a2] = butter(3,fpass2/(fs/2));

fpass3 = [59 61]; % notch filter
[b3,a3] = butter(3,fpass3/(fs/2),'stop');

fpass4 = [0.05 100]; % notch filter
[b4,a4] = butter(3,fpass3/(fs/2),'bandpass');

%% Plot Sleep Data (NEUSLEEP)
% %figure('Position', [300, 300, 110*10, 27*10]);
% scrsz = get(0,'MonitorPositions');
% figure('name', "NEUSLEEP",'Position',[1 scrsz(monitor,4)/2 scrsz(monitor,3)/2 scrsz(monitor,4)])
% for ch = 1:total_channels - 2
%     subplot(total_channels-1,1,ch)
%     signal = double(EEG.data(ch,:));
%     x = filtfilt(b, a,signal);
%     xlen = length(x(1,:));              % signal length
%     t = (0:xlen-1)/fs;                  % time vector
% 
%     % Time-Frequency Analysis Parameters
%     wlen = 1024;                        % window length (recommended to be power of 2)
%     nfft = 2*wlen;                      % number of fft points (recommended to be power of 2)
%     hop = wlen/4;                       % hop size (recommended to be 1/4 of the window length)
% 
%     % Perform STFT
%     w1 = blackman(wlen, 'periodic');
%     [~, fS1, tS1, PSD1] = spectrogram(x(1,:), w1, wlen-hop, nfft, fs);
%     Samp1 = 20*log10(sqrt(PSD1.*enbw(w1, fs))*sqrt(2));
% 
%     % Plot Data
%     plot_spectrogram(tS1, fS1, Samp1, ch_label1, t1, t2, lb, ub, ch, 0)
% end
% 
% %Plot Oz
% subplot(total_channels-1,1,ch)
% signal = double(EEG.data(ch,:));
% x = filtfilt(b2, a2,signal);
% xlen = length(x(1,:));              % signal length
% t = (0:xlen-1)/fs;                  % time vector
% 
% % Time-Frequency Analysis Parameters
% wlen = 1024;                        % window length (recommended to be power of 2)
% nfft = 2*wlen;                      % number of fft points (recommended to be power of 2)
% hop = wlen/4;                       % hop size (recommended to be 1/4 of the window length)
% 
% % Perform STFT
% w1 = blackman(wlen, 'periodic');
% [~, fS1, tS1, PSD1] = spectrogram(x(1,:), w1, wlen-hop, nfft, fs);
% Samp1 = 20*log10(sqrt(PSD1.*enbw(w1, fs))*sqrt(2));
% 
% % Plot Data
% plot_spectrogram(tS1, fS1, Samp1, ch_label1, t1, t2, lb, ub, total_channels, 0)
%saveas(gcf,'pilot.png')

% %Plot ECG
% subplot(total_channels+1,1,ch+1)
% x = filtfilt(b4, a4,EEG.data(ch+1,:));
% plot(EEG.times/(fs)/60, -EEG.data(ch+1,:)/1000, 'k', 'LineWidth', 0.5);
% set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
% axis([t1 t2, -inf inf]);
% ylabel('ECG (mV)');
% xlabel('Time (min)');
% % enable colorbar
% hcol = colorbar(['EastOutside']);
% set(hcol, 'FontName', 'Arial', 'FontSize', 12,'FontWeight','Bold')

% %Heart Rate Variability
% subplot(total_channels+1,1,ch+2)
[HRV_time, HRV_SDNN] = computeHRV(EEG.times/(fs), EEG.data(8,:)/1000, 60, 10, fs);
% plot(HRV_time/60/2, HRV_SDNN,'k', 'LineWidth', 0.5);
% ylabel("HRV (ms)")
% xlabel("Time (min)")
% set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
% % enable colorbar
% hcol = colorbar(['EastOutside']);
% set(hcol, 'FontName', 'Arial', 'FontSize', 12,'FontWeight','Bold')

% %Plot Triggers
% subplot(total_channels-1,1,ch+1)
% scatter([EEG.urevent(1:end).latency]*(1/fs)/60,[EEG.urevent(1:end).duration],2,'filled','red');
% set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
% axis([t1 t2, 0 2]);
% ylabel('FUS');
% xlabel('Time (min)');
% % enable colorbar
% hcol = colorbar(['EastOutside']);
% set(hcol, 'FontName', 'Arial', 'FontSize', 12,'FontWeight','Bold')

%Calculate RMSSD for HRV
HRV_RMSSD = compute_rmssd(EEG.times(1,:)/(fs), EEG.data(8,:)/1000);


%% Plot Hypnogram with STFT 
file = "/Users/KevinTang/Desktop/Desktop - Macbook Pro (Kevin)/UTAustin/Project/DARPA REM Sleep/Experiments/Sleep Study/NEUSLEEP V4.4/05202024/Hypnogram/MM_05202024_23-May-2024-10-58-41.mat";
hypnogram = load(file);
window = hypnogram.stageData.win;
stages = hypnogram.stageData.stages;
t1 = 0;
t2 = t1+60;

figure
subplot(4,1,1)
signal = double(EEG.data(1,:));
x = filtfilt(b, a,signal);
xlen = length(x(1,:));              % signal length
t = (0:xlen-1)/fs;                  % time vector
% Perform STFT
w1 = blackman(wlen, 'periodic');
[~, fS1, tS1, PSD1] = spectrogram(x(1,:), w1, wlen-hop, nfft, fs);
Samp1 = 20*log10(sqrt(PSD1.*enbw(w1, fs))*sqrt(2));
% Plot Data
plot_spectrogram(tS1, fS1, Samp1, ch_label1, t1, t2, lb, ub, 1, 0);

subplot(4,1,2)
signal = double(EEG.data(5,:));
x = filtfilt(b, a,signal);
WinLen = fs*2;                        % Window Length For RMS Calculation
x = sqrt(movmean(x.^2, WinLen));  
xlen = length(x(1,:));              % signal length
xlen = length(x(1,:));              % signal length
t = (0:xlen-1)/fs/60;                  % time vector
plot(t,x, 'k','LineWidth',1.5);
xlabel('Time (min)')
ylabel('|Voltage| (uV)')
%ylim([-100 100])
xlim([t1 t2])
title('EoG')
set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
colorbar

subplot(4,1,3)
signal = double(EEG.data(6,:));
x = filtfilt(b2, a2,signal);
x = filtfilt(b3, a3,x);
WinLen = fs*2;                        % Window Length For RMS Calculation
x = sqrt(movmean(x.^2, WinLen));  
xlen = length(x(1,:));              % signal length
t = (0:xlen-1)/fs/60;                  % time vector
plot(t,x, 'k','LineWidth',1.5);
xlabel('Time (min)')
ylabel('|Voltage| (uV)')
%ylim([-1000 1000])
xlim([t1 t2])
title('EMG')
set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
colorbar

subplot(4,1,4)
plot([0:window/60:(length(stages)-1)*window/60], -stages,'k','LineWidth',1.5)
set(gca, 'FontName', 'Arial', 'FontSize', 8, 'FontWeight','Bold')
yticks([-5 -4 -3 -2 -1 0 1])
yticklabels({'Unscored','REM','N3','N2','N1','Awake'})
xlabel('Time (min)')
colorbar
xlim([t1 t2])
ylim([-6 1])

% figure
% for ch = 1:total_channels/2 - 2
%     subplot(total_channels/2 -1,1,ch)
%     % Perform STFT
%     w1 = blackman(wlen, 'periodic');
%     [~, fS1, tS1, PSD1] = spectrogram(x(1,:), w1, wlen-hop, nfft, fs);
%     Samp1 = 20*log10(sqrt(PSD1.*enbw(w1, fs))*sqrt(2));
%     plot_spectrogram(tS1, fS1, Samp1, ch_label1, 0, 60, lb, ub, ch, 0);
% end
% subplot(total_channels/2 -1 ,1,ch + 1)
% plot([0:window/60:(length(stages)-1)*window/60], -stages,'k','LineWidth',1.5)
% set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
% yticks([-5 -4 -3 -2 -1 0 1])
% yticklabels({'Unscored','REM','N3','N2','N1','Awake'})
% xlabel('Time (min)')
% colorbar
% xlim([0 60])
% ylim([-6 1])

%% Plot Fitbit Data
fs_HR = 10;     % 10 Per Second
fs_SpO2 = 1;    % 10 Per Minute

figure
subplot(2,1,1)
plot([0:1:length(HR)-1]/(60*fs_HR),HR,'LineWidth', 1);
set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
ylabel("Heart Rate (BPM)");
xlabel("Time (hour)");
axis([t1/60 t2/60 -inf inf])
subplot(2,1,2)
plot([0:1:length(SP)-1]/(60*fs_SpO2),filloutliers(SP,"nearest"),'LineWidth', 1);
set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
ylabel("SpO2 (%)");
xlabel("Time (hour)");
axis([t1/60 t2/60 -inf inf])

%% Functions

% Plot the spectrogram
function plot_spectrogram(tS1, fS1, Samp1, ch_label, t1 , t2, lb, ub, ch, EMG)
    if (EMG == 0)
        surf(tS1/(60), fS1(1:125), Samp1(1:125,:))
        caxis([lb, ub])
    else
        surf(tS1/(60), fS1(1:end), Samp1(1:end,:))
        caxis([lb, ub])
    end
    shading interp
    axis tight
    box on
    set(gca, 'FontName', 'Arial', 'FontSize', 12, 'FontWeight','Bold')
    xlabel('Time (min)')
    ylabel(ch_label(ch))
    %title(ch_label(ch))
    view(0, 90)
    xlim([t1 t2])
    ylim([0 20])
    colormap('turbo')

    % enable colorbar
    hcol = colorbar(['EastOutside']);
    set(hcol, 'FontName', 'Arial', 'FontSize', 12,'FontWeight','Bold')
    ylabel(hcol, '(dB)')
end

function [HRV_time, HRV_SDNN] = computeHRV(time, ecg, window_size, step_size, fs)
% computeHRV calculates HRV (SDNN) over time from an ECG signal.
%
% Inputs:
%   time         - time vector (in seconds)
%   ecg          - ECG signal vector
%   window_size  - window size for HRV calculation (in seconds, e.g., 60)
%   step_size    - step size for sliding window (in seconds, e.g., 10)
%
% Outputs:
%   HRV_time     - time vector for each HRV point (center of the window)
%   HRV_SDNN     - SDNN values over time

    % Ensure column vectors
    time = time(:);
    ecg = ecg(:);

    % Bandpass filter for QRS (5–15 Hz)
    [b, a] = butter(1, [5 15] / (fs / 2), 'bandpass');
    ecg_filtered = filtfilt(b, a, ecg);
    

    % R-peak detection
    [~, locs_R] = findpeaks(ecg_filtered, 'MinPeakHeight', max(ecg_filtered) * 0.33, ...
        'MinPeakDistance', round(0.4 * fs)); % ~150 bpm max

    % R-R intervals
    RR_intervals = diff(time(locs_R));
    RR_times = (time(locs_R(1:end-1)) + time(locs_R(2:end))) / 2;

    % Initialize outputs
    HRV_SDNN = [];
    HRV_time = [];

    % Sliding window SDNN
    for t = min(RR_times):step_size:max(RR_times)-window_size
        idx = RR_times >= t & RR_times < t + window_size;
        if sum(idx) >= 2
            HRV_SDNN(end+1) = 1000*std(RR_intervals(idx));
            HRV_time(end+1) = t + window_size/2;
        end
    end
end


function rmssd = compute_rmssd(time, ekg)
% compute_rmssd - Calculate RMSSD from EKG signal
%
% Syntax: rmssd = compute_rmssd(time, ekg)
%
% Inputs:
%    time - Time vector (in seconds)
%    ekg  - EKG signal vector
%
% Output:
%    rmssd - Root Mean Square of Successive Differences of RR intervals (in ms)

    % Ensure column vectors
    time = time(:);
    ekg = ekg(:);
    
    % Bandpass filter (e.g., 5-15 Hz) to enhance QRS detection
    fs = 1 / mean(diff(time)); % Sampling frequency
    [b, a] = butter(2, [1 30] / (fs), 'bandpass');
    %filtered_ekg = filtfilt(b, a, ekg(1*fs*60:2*fs*60));
    filtered_ekg = filtfilt(b, a, ekg);

    % Tune
    tune = 0.5;
    
    figure
    % Detect R-peaks using findpeaks
    subplot(2,1,1)
    minPeakHeight = tune * max(filtered_ekg); % Adjust as needed
    [r_vals1, r_locs1] = findpeaks(filtered_ekg, 'MinPeakHeight', minPeakHeight,'MinPeakDistance', round(tune*fs));
    plot(filtered_ekg); hold on
    plot(r_locs1,r_vals1, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Peaks'); hold off
    xlabel('Time');
    ylabel('EKG');

    
    r_times1 = time(r_locs1);               % Time of R-peaks
    rr_intervals1 = diff(r_times1);        % RR intervals in seconds
    rr_ms1 = rr_intervals1 * 1000;         % Convert to milliseconds

    % Detect R-peaks using findpeaks
    subplot(2,1,2)
    minPeakHeight = tune * max(-filtered_ekg); % Adjust as needed
    [r_vals2, r_locs2] = findpeaks(-filtered_ekg, 'MinPeakHeight', minPeakHeight,'MinPeakDistance', round(tune*fs));
    plot(-filtered_ekg); hold on
    plot(r_locs2,r_vals2,'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Peaks'); hold off
    xlabel('Time');
    ylabel('EKG');
    
    r_times2 = time(r_locs2);               % Time of R-peaks
    rr_intervals2 = diff(r_times2);        % RR intervals in seconds
    rr_ms2 = rr_intervals2 * 1000;         % Convert to milliseconds

    % Compute RMSSD    
    diff_rr = diff(rr_ms1);
    rmssd1 = sqrt(mean(diff_rr .^ 2));

    % Compute RMSSD    
    diff_rr = diff(rr_ms2);
    rmssd2 = sqrt(mean(diff_rr .^ 2));

    rmssd = min(rmssd1,rmssd2);
end
