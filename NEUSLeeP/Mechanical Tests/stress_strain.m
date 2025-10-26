clc; clear all; close all;

addpath(genpath('Adhesion Strength'));
cond = '10%';
filetype = '.txt';
sample_width = 1; % cm

%% Extension data

cd '/Users/kevintang/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Desktop-Kevin/UTAustin/Project/DARPA-REM-Sleep/Experiments/Bioadhesive Substrate/stress_strain/Distance';
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
fq_ext = 30; % frequency = 30 Hz for extension motor

%% Pick coords for each test

fq_force = 80; % frequency = 80 Hz for force gauge meter

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
        startsends(n,2) = dataF(startsends(n,1));
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
        startsends(n,2) = dataF(startsends(n,1));
    end
    dataF = abs(dataF(startsends(1,1):startsends(2,1)));
    avg_vlu = [avg_vlu mean(dataF)];
    close;
    figuredata(i).sample = data_figure;

    %% Young’s Modulus Calculation
    original_length_mm = 25; % <<< change this to your sample's original length in mm
    cross_sectional_area_cm2 = 0.1; % <<< change this to your sample's cross-sectional area in cm²

    % Time and extension calculation
    t = length(figuredata(i).sample) / fq_force;
    dist = t * 0.038 * fq_ext;
    ext = linspace(0, dist, length(figuredata(i).sample)); % in mm

    strain{i} = ext / original_length_mm; % unitless
    stress{i} = figuredata(i).sample / cross_sectional_area_cm2; % N/cm²
    x_strain = strain{i};
    y_stress = stress{i};

    % Linear fit to initial 10% of data
    lin_idx = 1:round(0.66 * length(x_strain));
    p = polyfit(x_strain(lin_idx), y_stress(lin_idx), 1);
    youngs_modulus(i) = p(1); % N/cm²

    fprintf('Sample %d Young''s Modulus: %.2f N/cm²\n', i, youngs_modulus(i));

    % Optional plot: stress-strain curve
    % figure;
    % plot(strain, stress, 'b-', 'LineWidth', 1.5); hold on;
    % plot(strain(lin_idx), polyval(p, strain(lin_idx)), 'r--', 'LineWidth', 1.5);
    % xlabel('Strain');
    % ylabel('Stress (N/cm²)');
    % title(sprintf('Stress-Strain Curve - Sample %d', i));
    % legend('Data', 'Linear Fit');
    % grid on;
    % close;

end


cd ..
cd ..
