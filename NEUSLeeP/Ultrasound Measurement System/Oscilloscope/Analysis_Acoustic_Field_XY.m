%%
clc
clear all
close all

%% Load Data

load("C:\Users\Administrator\Desktop\Acoustic Scans\MiniUlTra_D7_Scan01_1V.mat")

%% Set up Filter
ub = 1000e3;
lb = 100e3;
fc = 650e3;
fs = sRateA;
[b, a] = butter(3, [lb, ub]/(fs/2), 'bandpass');

%% ONDA HGL200 with AH-2010 Preamplifier Hydrophone Callibration
M_c = 50e-9; % 50nV/Pa
C_h = 30e-12; % 30pF Onda HGL-0200 Hydrophone
C_a = 6.3e-12; % 6.3pf Onda AH-2010 Pre-Amplifier
C_c = 1.6e-12; % Right Angle Connector
G = 10; % 20dB Pre-Amplifier Gain

callibration = G*M_c*(C_h/(C_h+C_c+C_a));

%% Stimulation Parameters
rho = 1046;                     % kg/m3
c0 = 1530;                      % m/s
alpha = 0.07;                   % dB/cm/MHz
PD = 3e-6;                      % s
NCycles = 4;
PRF = 1/(PD/NCycles);           % Hz
TPRF = 1e-3;                     % Hz
%% Filter Signals
cutoff_start = 7500;
%cutoff_start = 15000;

for j = 1:ceil(Dim.Y)
            for i = 1:ceil(Dim.X)
                
                x = sA{i,j};
                filtered.sA{i,j} = filtfilt(b, a, x);
                %filtered.sA{i,j} = filtered.sA{i,j} - filtered.sA{i,width(sA)};
                signal = filtered.sA{i,j}(cutoff_start:end,:);
                [pks, locs] = findpeaks(filtered.sA{i,j}(cutoff_start:end,:), 'minpeakheight', 3*std(signal));
                %PressureField(i,j) = 1e-6*abs(mean(pks))./callibration;
                PressureField(i,j) = 1e-6*abs((min(signal))./callibration);
               
                
                % Compute Values
                PPI(i,j) = trapz(signal.^2);
                PII(i,j) = PPI(i,j)./(rho*c0);
                MI(i,j) = PressureField(i,j)/sqrt(fc/1e6);
                
                DeratingFactor = exp(-0.069*(fc/1e6)*(j*Increment.Y/10));
                
                I.SPPA(i,j) = max(PII(i,j)/PD);
                I.SPTA(i,j) = max(PII(i,j)/TPRF);
                I.SPTA_Derated(i,j) = I.SPTA(i,j)*DeratingFactor;
                I.SPPA_Derated(i,j) = I.SPPA(i,j)*DeratingFactor;
                display("Processing: " + "(" + i + "," + j + ")")
            end
end


%%
% figure
% subplot(2,1,1)
% plot(1e6*tA{80,60},filtered.sA{80,60});
% subplot(2,1,2)
% hold on
% plot(1e6*tA{40,10},filtered.sA{40,10});
% plot(1e6*tA{40,20},filtered.sA{40,20});
% title(string((fc/1530)));
% hold off
%% Plot Analysis
x_slice = 10;
z_slice = 10;
z_offset = 0;


figure
subplot(2,2,[1 3])
%pcolor(PressureField'./max(max(PressureField)))
%pcolor(PressureField(:,5:end)')
pcolor((PressureField)')
%shading interp
set(gca,'YTick', [1:10:Dim.Y],'YTickLabel', [0+z_offset:10*Increment.Y:z_offset+(Dim.Y-1/2)/2])
set(gca,'XTick', [0:10:Dim.X-1],'XTickLabel', [-dimension_mm/2:10*Increment.X:dimension_mm/2])
set(gca,'FontSize', 16,'FontWeight', 'Bold')
set(gca,'YAxisLocation','left')
%caxis([0 0.55])
ylabel('Axial (mm)')
xlabel('Radial (mm)')
%axis([-inf inf 0 20])
c = colorbar;
colormap(turbo);
c.Label.String = "Acoustic Pressure (MPa)";
%caxis([0 1]);
title("Beam Profile");
subplot(2,2,2)
for n = 40
    hold on
    plot(PressureField(n,:)','-o' ,'MarkerSize',4,'LineWidth',1.5)
end
%legend("X = -5.0mm", "X = -2.5mm","X = 0.0mm","X = 2.5mm","X = 5.0mm")
set(gca,'XTick', [1:10:Dim.Y],'XTickLabel', [0+z_offset:10*Increment.Y:z_offset+(Dim.Y-1/2)/2])
set(gca,'FontSize', 12,'FontWeight', 'Bold')
xlabel('Axial (mm)')
ylabel('Acoustic Pressure (MPa)')
title("Unixial Profile");
subplot(2,2,4)
for n = 1:30
    hold on
    plot(PressureField(:,n),'-o' ,'MarkerSize',2,'LineWidth',1.5)
end
%legend("Y = 0.5mm", "Y = 2.0mm","Y = 4.5mm","Y = 6.5mm","Y = 8.5mm", "Y = 10.5mm")
hold off
title("Radial Profile");
set(gca,'XTick', [0:10:Dim.X],'XTickLabel', [-dimension_mm/2:10*Increment.X:dimension_mm/2])
set(gca,'FontSize', 12,'FontWeight', 'Bold')
xlabel('Radial (mm)')
ylabel('Acoustic Pressure (MPa)')

%% Plot Analysis (Log Plot)
x_slice = 10;
z_slice = 10;
z_offset = 0;
Ref_SPL = 1e-6; % 20uPa Reference for SPL


figure
subplot(2,2,[1 3])
%pcolor(PressureField'./max(max(PressureField)))
pcolor(20*log(PressureField'./Ref_SPL))
%shading interp
set(gca,'YTick', [1:10:Dim.Y],'YTickLabel', [0+z_offset:10*Increment.Y:z_offset+(Dim.Y-1/2)/2])
set(gca,'XTick', [0:10:Dim.X],'XTickLabel', [-dimension_mm/2:10*Increment.Y:dimension_mm/2])
set(gca,'FontSize', 12,'FontWeight', 'Bold')
ylabel('Axial (mm)')
xlabel('Radial (mm)')
%axis([-inf inf 0 20])
c = colorbar;
colormap(turbo);
c.Label.String = "SPL (dB ref 20\muPa)";
%caxis([0 1.8]);
title("Beam Profile");
subplot(2,2,2)
for n = 31:5:51
    hold on
    plot(20*log(PressureField(n,1:2:end)/Ref_SPL),'-o' ,'MarkerSize',4,'LineWidth',1.5)
end
legend("X = -5.0mm", "X = -2.5mm","X = 0.0mm","X = 2.5mm","X = 5.0mm")
set(gca,'XTick', [1:10:Dim.X],'XTickLabel', [0+z_offset:10*Increment.X:z_offset+(Dim.X-1/2)/2])
set(gca,'FontSize', 12,'FontWeight', 'Bold')
xlabel('Axial (mm)')
ylabel('SPL (dB ref 20\muPa)')
title("Unixial Profile");
subplot(2,2,4)
for n = 1:4:24
    hold on
    plot(20*log(PressureField(:,n)/Ref_SPL),'-o' ,'MarkerSize',2,'LineWidth',1.5)
end
legend("Y = 0.5mm", "Y = 2.0mm","Y = 4.5mm","Y = 6.5mm","Y = 8.5mm", "Y = 10.5mm")
hold off
title("Radial Profile");
set(gca,'XTick', [0:10:Dim.X],'XTickLabel', [-dimension_mm/2:10*Increment.Y:dimension_mm/2])
set(gca,'FontSize', 12,'FontWeight', 'Bold')
xlabel('Radial (mm)')
ylabel('SPL (dB ref 20\muPa)')

%% Figures of Merits


figure
subplot(1,2,1)
hold on
plot((I.SPPA(40,:)/max(I.SPPA(40,:)))','LineWidth',1.5)
plot((I.SPPA_Derated(40,:)/max(I.SPPA(40,:)))','--r','LineWidth',1.5)
hold off
legend('Free Field I_{SPPA}', 'In Situ I_{SPPA}')
set(gca,'FontSize', 14, 'FontWeight','Bold')
set(gca,'XTick', [1:10:Dim.Y],'XTickLabel', [0+z_offset:10*Increment.Y:z_offset+(Dim.Y-1/2)/2])
ylabel('I/I_{max}')
xlabel('Axial (mm)')
subplot(1,2,2)
hold on
plot((I.SPPA(:,40)/max(I.SPPA(:,40)))','LineWidth',1.5)
plot((I.SPPA_Derated(:,40)/max(I.SPPA(:,40)))','--r','LineWidth',1.5)
hold off
%legend('Free Field I_{SPPA}', 'Derated I_{SPPA} in Tissue')
set(gca,'FontSize', 14, 'FontWeight','Bold')
set(gca,'XTick', [0:10:Dim.X],'XTickLabel', [-dimension_mm/2:10*Increment.Y:dimension_mm/2])
ylabel('I/I_{max}')
xlabel('Radial (mm)')
%% Safety
figure
subplot(1,2,1)
hold on
scatter(PressureField,1e3*I.SPPA,'.k');
scatter(PressureField,1e3*I.SPPA_Derated,'.r');
hold off
legend('Free Field I_{SPTA}', 'In Situ Derated I_{SPPA}')
xlabel('P_r (MPa)')
ylabel('I_{SPPA} (mW/cm^2)')
set(gca,'FontSize', 14, 'FontWeight','Bold')
%axis([0 2.5 0 10])
subplot(1,2,2)
hold on
scatter(MI,1e3*I.SPPA,'.k');
scatter(MI,1e3*I.SPPA_Derated,'.r');
hold off
xline(1.9,'r','LineWidth',2)
legend('Free Field I_{SPTA}', 'In Situ Derated I_{SPPA}')
xlabel('Mechanical Index (MI)')
ylabel('I_{SPPA} (mW/cm^2)')
%axis([0 1000 0 inf])
set(gca,'FontSize', 14, 'FontWeight','Bold')
set(gca,'XScale','log')
%% 
N = 40;
figure
subplot(2,1,1)
plot(1e6*tB{40,N},10*sB{40,N},'k','LineWidth' ,1)
xlabel('Time (\mus)')
ylabel('Driving Voltage (V)')
set(gca,'FontSize', 14,'FontWeight', 'Bold')
subplot(2,1,2)
plot(1e6*tA{40,N},sA{40,N},'k','LineWidth' ,1)
xlabel('Time (\mus)')
ylabel('Measured Signal (V)')
set(gca,'FontSize', 14,'FontWeight', 'Bold')


%%
%cutoff_start = 7500;
index = reshape(1:25, 5, 5).';
figure
for i = 1:25
    subplot(5,5,index(i))
    x = sA{40,i*2};
    y = filtfilt(b, a, x);
    plot(1e6*tA{30,i*2}(cutoff_start:end),1e-6*y(cutoff_start:end)./callibration,'k','LineWidth' ,0.8)
    %plot(1e6*tA{40,i*2},1e-6*y./callibration,'k','LineWidth' ,0.8)
    %plot(1e6*tA{40,i*2},y,'k','LineWidth' ,0.8)
    xlabel('Time (\mus)')
    ylabel('Pressure (MPa)')
    title("Z = " + string(i*2*0.5) + " (mm)")
    %axis([-inf inf -0.2 0.2])
    %axis([-25 0 -0.01 0.01])
    %axis([-inf inf -1 1])
    set(gca,'FontSize', 10,'FontWeight', 'Bold')
end

%% FFT at Focal

[f,PSD] = find_fft(fs, y);

%%
figure
for i = 1:80
    for j = 1:80
        test(j) = min(filtered.sA{i,j}(20000:end,:));
    end
    title('X: ' + string(j))
    plot(abs(test))
    ylim([0 0.55])
    pause(0.1)
end

%% Functions
function [f,PSD] = find_fft(Fs, X)
                 
    T = 1/Fs;             % Sampling period       
    L = length(X);             % Length of signal
    t = (0:L-1)*T;        % Time vector

    Y = fft(X);
    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2*P1(2:end-1);

    f = Fs*(0:(L/2))/L;
    PSD = P1./max(P1);
    
    figure
    subplot(1,2,1)
    plot(f,PSD) 
    title("Power Spectrum Density of X(t)")
    xlabel("f (Hz)")
    ylabel("Normalized Amplitude (a.u)")
    axis([0 3e7 0 1])
    subplot(1,2,2)
    plot(f,PSD) 
    title("Power Spectrum Density of X(t)")
    xlabel("f (Hz)")
    ylabel("Normalized Amplitude (a.u)")
    axis([0 5e6 0 1])
end



