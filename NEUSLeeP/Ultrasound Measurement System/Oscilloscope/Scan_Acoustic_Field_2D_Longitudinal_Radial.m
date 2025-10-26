%% 
% Written By: Kai Wing Kevin Tang
% Date: 03/07/2023

%% Clear Work Space
clc
clear all
close all

%% Set Filename
save_filename = input("Please input filename to save as: \n", "s")
%% ONDA HNR-0500 Hydrophone Callibration
M_c = 243e-9; % 50nV/Pa
C_h = 13e-12; % 30pF Onda HNR-0500 Hydrophone
C_a = 0; % 6.3pf Onda AH-2010 Pre-Amplifier
C_c = 0; % Right Angle Connector
G = 1; % 20dB Pre-Amplifier Gain

callibration = G*M_c*(C_h/(C_h+C_c+C_a));
M = 1e-6*((118/1000)./callibration);


%% Setup Connection to Oscilloscope
ScopeUSBAddress = 'USB0::0xF4ED::0xEE3A::SDS1EDEC5R1189::INSTR';
channel_A = 1;
channel_B = 2;

%% Filter
[temp1, temp2 sRateA] = acquireOscilloscopeData(ScopeUSBAddress, channel_A);

ub = 1000e3;
lb = 100e3;
fs = sRateA;
[b, a] = butter(3, [lb, ub]/(fs/2), 'bandpass');

%% Scan Parameters
dimension_mm = 40;   % in mm
transducer_diameter = 20; % in mm
Increment.X = 0;  % in mm
Increment.Y = 0.5;  % in mm
Increment.Z = 0;  % in mm
Dim.X = 0;
Dim.Y  = dimension_mm/Increment.Y;
Dim.Z  = 0;

% Zero Coordinate Spaces
X = 0;
Y = 0;
Z = 0;

% Delays during Position Movement
Sample_Delay_Motor = 0.1;
Buffer_Delay_Motor = 0.1;


%% Setup Serial Communication between Arduino and MATLAB
PortName = "COM5";
BaudRate = 115200;
s=serial(PortName,'BaudRate', BaudRate);
fopen(s) % open serial port

%% Stimulation Parameters
c = 1540; % Speed of Sound of Medium (m/s)
rho = 1000; % Density of Medium (kg/m^3)
PD = 0.5;   % Pulse Duration
DC = 0.36;  % Duty Cycle

%% Move to Start Position
display('Callibration Beginning...')
pause(2)

tStart = tic;
figure('units','normalized','outerposition',[0 0 1 1])
try
    %display('Moving to Origin Z')
    %data = "G1 " + "Z" + string(transducer_diameter*0.5);
    %pause(Buffer_Delay_Motor)
    %fprintf(s, '%s\n', data);
    %pause(Buffer_Delay_Motor)

    display('Moving to Origin X')
    data = "G1 " + "Y" + string(-dimension_mm*0.5);
    pause(Buffer_Delay_Motor)
    fprintf(s, '%s\n', data);
    pause(Buffer_Delay_Motor)
    
    display('Beginning Scans...')

    i = 1;
    k = 1;

    for j = 1:ceil(Dim.Y)
        [tA{i,j,k}, sA{i,j,k}, sRateA] = acquireOscilloscopeData(ScopeUSBAddress, channel_A);
        [tB{i,j,k}, sB{i,j,k}, sRateB] = acquireOscilloscopeData(ScopeUSBAddress, channel_B);
        dist = sqrt(abs(((j)*Increment.X)).^2 );

        % Pressure
        P(j,:) = 1e-6*sA{i,j,k}/callibration;
        P(j,:) = 5.8*P(j,:);
        PF(j,:) = filtfilt(b,a, P(j,:));
        Pn(j) = min(PF(j,:));
        Pp(j) = max(PF(j,:));

        % Intensity
        Isppa(j) = 70*PD*1e6*Pn(j)^2/(2*rho*c);
        Ispta(j) = 70*DC*1e6*Pn(j)^2/(2*rho*c);

        display("Scanning: " + X + "," + Y + "," + Z);
        plotdata(tA{i,j,k}, tB{i,j,k}, sA{i,j,k}, sB{i,j,k} , X , Y , Z, P(j,:), PF(j,:), Pn(j), Pp(j), Ispta(j), Isppa(j), dist, dimension_mm)
        pause(Sample_Delay_Motor)
        data = "G1 " + "Y" + string(Increment.Y);
        fprintf(s, '%s\n', data);
        Y = Y + Increment.Y;
        pause(Sample_Delay_Motor)
    end
    pause(Sample_Delay_Motor);
    data = "G1 " + "Y" + string(-dimension_mm/2);
    fprintf(s, '%s\n', data);
  
    
catch e
    display(e)
    display('Error: Closing Serial Port...')
    fclose(s)
end

tEnd = toc(tStart);

display("Time Elapsed: " + string(tEnd))


% Close Serial Port
fclose(s)

%% Save Workspace
display("Saving File...")
save(save_filename)
display("Save Finished")
%% Plotting
function plotdata(tA, tB, sA, sB , X , Y , Z, P, PF, Pn, Pp, Ispta, Isppa, dist, dimension_mm)
    tA = tA*1e6;
    tB = tB*1e6;

    subplot(2,2,1)
    plot(tA,sB , 'r') ; hold on
    plot(tA,sA ,'k');
    hold off
    xlabel('Time (us)')
    ylabel('Voltage (V)')
    title("Measured Pressure " + "(" + X + "," + Y + "," + Z + ")")
    axis([-inf inf  -inf inf])
    subplot(2,2,3)
    plot(tA,sB , 'r') ; hold on
    plot(tA,PF, 'k')
    hold off
    xlabel('Time (us)')
    ylabel('Acoustic Pressure (MPa)')
    title("Coordinates: "  + "(" + X + "," + Y + "," + Z + ")")
    axis([-inf inf  -inf inf])

    subplot(2,2,2)
    hold on
    scatter(Y-dimension_mm/2,abs(Pp),'.b');
    xlabel('Axial (mm)')
    ylabel('Pressure (MPa)');
    axis([-dimension_mm/2 dimension_mm/2 -inf inf]);
    hold off

    subplot(2,2,4)
    hold on
    scatter(Y-dimension_mm/2,Isppa,'.b');
    %scatter(Y-dimension_mm/2,Ispta,'.r');
    xlabel('Radial (mm)')
    ylabel('Intensity');
    axis([-dimension_mm/2 dimension_mm/2 -inf inf]);
    hold off
    
end