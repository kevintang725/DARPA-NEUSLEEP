
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

%% Calculate RMSSD for HRV
[HRV_RMSSD,ekg] = compute_rmssd(EEG.times(1,:)/(fs), EEG.data(8,:)/1000);

%% Generate Poincare plot for HRV
[SD1, SD2, rr_intervals] = poincare_plot_ecg(EEG.data(8,:)/1000, fs)

%% Functions

function [rmssd,ekg] = compute_rmssd(time, ekg)
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
    filtered_ekg = filtfilt(b, a, ekg(1*fs*60:3*fs*60));
    %filtered_ekg = filtfilt(b, a, ekg);

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

function [SD1, SD2, rr_intervals] = poincare_plot_ecg(ecg_signal, fs)
% ============================================================
% poincare_plot_ecg: Generate a Poincaré plot for HRV from ECG signal,
% automatically handling reverse-polarized ECG traces.
%
% INPUT:
%   ecg_signal - vector of raw ECG signal (in mV or arbitrary units)
%   fs         - sampling frequency (Hz)
%
% OUTPUT:
%   SD1          - short-term HRV (perpendicular to line of identity)
%   SD2          - long-term HRV (along line of identity)
%   rr_intervals - computed RR intervals (in milliseconds)
%
% EXAMPLE:
%   [SD1, SD2, rr_intervals] = poincare_plot_ecg(ecg_data, 1000);
% ============================================================

    % --- Step 1: Preprocess ECG (bandpass filter) ---
    ecg_filtered = bandpass(ecg_signal, [1 30], fs);

    % --- Step 2: Check if ECG is reverse-polarized ---
    [pos_pks, ~] = findpeaks(ecg_filtered);
    [neg_pks, ~] = findpeaks(-ecg_filtered);

    if mean(abs(neg_pks)) > mean(abs(pos_pks))
        disp('ECG appears to be reverse-polarized. Flipping signal...');
        ecg_filtered = -ecg_filtered;
    end

    % --- Step 3: Detect R-peaks ---
    tune = 0.5;
    minPeakHeight = tune * max(ecg_filtered); % Adjust as needed
    [~, locs_R] = findpeaks(ecg_filtered, ...
        'MinPeakHeight', minPeakHeight, ...
        'MinPeakDistance', round(tune*fs));  % assuming min 40 bpm

    if length(locs_R) < 3
        error('Not enough R-peaks detected. Check signal quality or parameters.');
    end

    % Convert peak indices to time (s)
    t_R = locs_R / fs;

    % --- Step 4: Compute RR intervals ---
    rr_intervals = diff(t_R) * 1000;  % convert to milliseconds

    % --- Step 5: Prepare Poincaré data ---
    RRn = rr_intervals(1:end-1);
    RRn1 = rr_intervals(2:end);

    % --- Step 6: Calculate SD1 and SD2 ---
    diffs = RRn1 - RRn;
    SD1 = std(diffs) / sqrt(2);
    SD2 = sqrt(2 * std(rr_intervals)^2 - SD1^2);

    % --- Step 7: Generate Poincaré plot ---
    figure;
    scatter(RRn, RRn1, 50, 'b', 'filled');
    xlabel('RR_n (ms)');
    ylabel('RR_{n+1} (ms)');
    title('Poincaré Plot of HRV');
    axis equal;
    grid on;
    hold on;

    % Plot line of identity
    minRR = min([RRn, RRn1]);
    maxRR = max([RRn, RRn1]);
    plot([minRR, maxRR], [minRR, maxRR], 'k--', 'LineWidth', 1);

    % Plot SD1/SD2 ellipse (for visual reference)
    meanRR = mean(rr_intervals);
    theta = linspace(0, 2 * pi, 100);
    ellipse_x = meanRR + SD2 * cos(theta);
    ellipse_y = meanRR + SD1 * sin(theta);
    plot(ellipse_x, ellipse_y, 'r', 'LineWidth', 1.5);

    % --- Step 8: Display outputs ---
    disp(['SD1 (short-term variability): ', num2str(SD1, '%.2f'), ' ms']);
    disp(['SD2 (long-term variability): ', num2str(SD2, '%.2f'), ' ms']);
    disp(['Number of detected RR intervals: ', num2str(length(rr_intervals))]);
end
