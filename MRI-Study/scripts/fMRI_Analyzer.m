%% 
clc
clear all
close all

%%
folder_name = "Wang-BSonix-Pilot_002.1 (FUS-)";
dir_folder = dir(fullfile(folder_name, '*.dcm'));

%% Load Directory
for i = 1:length(dir_folder)
    x = struct2cell(dir_folder(i));
    filename = x(1);
    info = dicominfo(fullfile(folder_name,string(filename)));
    data.sequence_name(i,1) = string(info.SeriesDescription);
    display('Reading Directory: ' + string(i) + '/' + string(length(dir_folder)));
end


%% Display Structural Scan (Sagittal)
%select_data = 470; % T1
%select_data = 471; %FGATIR
select_data = 12; %T1 fMRI

if select_data == 470 
        rot = 0;
end
if select_data == 471
        rot = -3;
end
if select_data == 12
        rot = -3;
end

x = struct2cell(dir_folder(select_data));
filename = x(1);
info = dicominfo(fullfile(folder_name,string(filename)));
Y = dicomread(info);

figure('name', 'Sagittal')
for i = 1:length(Y(1,:,1))
    Z.sagittal = rot90(squeeze(Y(:,i,:)),rot);
    imshow(Z.sagittal,[], 'InitialMagnification', 2000);
    title(string(info.SeriesDescription) + ': Slice ' + string(i),'Interpreter', 'none');
    pause(0.1)
end

%% Display Structural Scan (Coronal)
x = struct2cell(dir_folder(select_data));
filename = x(1);
info = dicominfo(fullfile(folder_name,string(filename)));
Y = dicomread(info);

figure('name', 'Coronal')
for i = 1:length(Y(:,1,1))
    Z.coronal = rot90(squeeze(Y(i,:,:)),rot);
    imshow(Z.coronal,[], 'InitialMagnification', 2000);
    title(string(info.SeriesDescription) + ': Slice ' + string(i),'Interpreter', 'none');
    pause(0.1)
end

%% Display Structural Scan (Transverse)
x = struct2cell(dir_folder(select_data));
filename = x(1);
info = dicominfo(fullfile(folder_name,string(filename)));
Y = dicomread(info);

figure('name', 'Transverse')
for i = 1:length(Y(:,:,1))
    Z.coronal = rot90(squeeze(Y(:,:,i)),rot);
    imshow(Z.sagittal,[], 'InitialMagnification', 2000);
    title(string(info.SeriesDescription) + ': Slice ' + string(i),'Interpreter', 'none');
    pause(0.1)
end

%% Display fMRI
%ROI_slice = 40;
End_File = 437;
ROI_slice = 48;

for i = 12:End_File
    x = struct2cell(dir_folder(i));
    filename = x(1);
    info = dicominfo(fullfile(folder_name,string(filename)));
    Y = dicomread(info);
    data.fMRI.coronal(:,:,:,i) = squeeze(Y(ROI_slice,:,:));
    display('Merging Slices: ' + string(i-End_File) + '/' + string(465-End_File));
end

%% Select ROI
X = data.fMRI.coronal;
Xref = data.fMRI.coronal(:,:,12);

%% Plot fMRI
figure('name', 'fMRI Sequence')
for i = 1:length(X(1,1,:))
    subplot(2,2,1)
    Xp = (squeeze(X));
    imshow(rot90(Xp(:,:,i),1),[], 'InitialMagnification', 4000);
    title(string(info.SeriesDescription) + ': Slice ' + string(i),'Interpreter', 'none');
    subplot(2,2,2)
    Xp = (squeeze(X))- Xref;
    imshow(rot90(Xp(:,:,i),1),[], 'InitialMagnification', 4000);
    title(string(info.SeriesDescription) + ': Slice ' + string(i),'Interpreter', 'none');
    subplot(2,2,3)
    Xp = (squeeze(X))- Xref;
    imshow(rot90(Xp(:,:,i),1),[0 100], 'InitialMagnification', 4000);
    title(string(info.SeriesDescription) + ': Slice ' + string(i),'Interpreter', 'none');
    subplot(2,2,4)
    Xp = (squeeze(X))- Xref;
    imshow(rot90(Xp(:,:,i),1),[0 500], 'InitialMagnification', 4000);
    title(string(info.SeriesDescription) + ': Slice ' + string(i),'Interpreter', 'none');
    pause(0.01)
    
end

%% Select ROI to Analyze Intensity
figure('name', 'Select ROI', 'Position',[0 0 1000 1000])
Xp = (squeeze(X));
imshow(rot90(Xp(:,:,100),1),[],'InitialMagnification', 4000)
[roi, rx, ry] = roipoly;
close

%Xp = (squeeze(X))- Xref;
% Process Data
for i = 1:length(X(1,1,:))
    frame = rot90(Xp(:,:,i),1);
    I = double(frame).*double(roi);
    Intensity(i) = sum(sum(I))./(width(I)*height(I));
end

[b, a] = butter(3, [0.05]/(0.8/2), "low");
Intensity_filt = filtfilt(b, a, Intensity./max(Intensity));

%% Plot BOLD
figure('name', 'BOLD Signal', 'Position',[0 0 2000 1000])
subplot(2,4,1)
Xp = (squeeze(X));
imshow(rot90(Xp(:,:,13),1),[], 'InitialMagnification', 4000); hold on
plot(rx, ry, 'r-', 'MarkerSize', 5);
hold off
title("Structural");
subplot(2,4,2)
Xp = (squeeze(X)) - Xref;
imshow(rot90(Xp(:,:,13),1),[], 'InitialMagnification', 4000); hold on
plot(rx, ry, 'r-', 'MarkerSize', 5);
hold off
title("Pre-Stimulation");
subplot(2,4,3)
Xp = (squeeze(X)) - Xref;
imshow(rot90(Xp(:,:,350),1),[], 'InitialMagnification', 4000); hold on
plot(rx, ry, 'r-', 'MarkerSize', 5);
hold off
title("Stimulation");
subplot(2,4,4)
Xp = (squeeze(X)) - Xref;
imshow(rot90(Xp(:,:,end),1),[], 'InitialMagnification', 4000); hold on
plot(rx, ry, 'r-', 'MarkerSize', 5);
hold off
title("Post-Stimulation");
subplot(2,4,[5 8])
plot(Intensity./max(Intensity),'k'); hold on
plot(Intensity_filt,'LineWidth',2,'Color', 'r'); 
legend('Intensity (Raw)','Intensity (Low-Pass)')
ylabel('Normalized Pixel Intensity')
xlabel('Time (Scan #)')
title('BOLD Signal')
axis([0 inf 0.8 1])
set(gca,'FontSize',12,'FontWeight', 'Bold')

%% Select Multiple ROI to Analyze Intensity
num_roi = 4;

figure('name', 'Select ROI', 'Position',[0 0 1000 1000])
for k = 1:num_roi
    Xp = (squeeze(X));
    imshow(rot90(Xp(:,:,100),1),[],'InitialMagnification', 4000)
    [roim{k}, rxm{k}, rym{k}] = roipoly;
    close
    
    % Process Data
    for i = 1:length(X(1,1,:))
        frame = rot90(Xp(:,:,i),1);
        I = double(frame).*double(roim{k});
        Intensitym{k}(i) = sum(sum(I))./(width(I)*height(I));
    end
    [b, a] = butter(3, [0.05]/(0.8/2), "low");
    Intensity_filtm{k} = filtfilt(b, a, Intensitym{k}./max(Intensitym{k}));
end

%
% Plot BOLD
figure('name', 'BOLD Signal', 'Position',[0 0 2000 1000])
colororder("gem12")
subplot(2,4,1)
Xp = (squeeze(X));
imshow(rot90(Xp(:,:,13),1),[], 'InitialMagnification', 4000); hold on
for k = 1:num_roi
    plot(rxm{k}, rym{k}, '-', 'LineWidth', 2);
    title("Structural");
end
hold off
subplot(2,4,2)
Xp = (squeeze(X)) - Xref;
imshow(rot90(Xp(:,:,13),1),[], 'InitialMagnification', 4000); hold on
for k = 1:num_roi
    plot(rxm{k}, rym{k}, '-', 'MarkerSize', 5);
    title("Pre-Stimulation");
end
hold off
subplot(2,4,3)
Xp = (squeeze(X)) - Xref;
imshow(rot90(Xp(:,:,350),1),[], 'InitialMagnification', 4000); hold on
for k = 1:num_roi
    plot(rxm{k}, rym{k}, '-', 'MarkerSize', 5);
    title("Stimulation");
end
hold off
subplot(2,4,4)
Xp = (squeeze(X)) - Xref;
imshow(rot90(Xp(:,:,end),1),[], 'InitialMagnification', 4000); hold on
for k = 1:num_roi
    plot(rxm{k}, rym{k}, '-', 'MarkerSize', 5);
    title("Post-Stimulation");
end
hold off
subplot(2,4,[5 8])
hold on
for k = 1:num_roi
    plot(Intensity_filtm{k},'LineWidth',2); 
end
hold off
legend
ylabel('Normalized Pixel Intensity')
xlabel('Time (Scan #)')
title('BOLD Signal')
axis([0 inf 0.8 1])
set(gca,'FontSize',12,'FontWeight', 'Bold')