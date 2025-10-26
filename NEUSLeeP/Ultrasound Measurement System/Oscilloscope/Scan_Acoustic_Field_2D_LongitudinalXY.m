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
dimension_mm = 60;   % in mm
transducer_diameter = 48; % in mm
Increment.X = 1;  % in mm
Increment.Y = 1;  % in mm
Increment.Z = 0;  % in mm
Offset = 0;
%Dim.X = dimension_mm/Increment.X;
Dim.X = 100-Offset;
%Dim.X = 30;
%Dim.Y  = dimension_mm/Increment.Y;
Dim.Y = dimension_mm;
Dim.Z  = 0;

% Zero Coordinate Spaces
X = 0;
Y = 0;
Z = 0;

% Set Planes;
k = 1;

% Error Counts
e_count = 0;

% Delays during Position Movement
Sample_Delay_Motor = 0.01;
Buffer_Delay_Motor = 10;


%% Setup Serial Communication between Arduino and MATLAB
PortName = "COM5";
BaudRate = 115200;
%s=serial(PortName,'BaudRate', BaudRate);
s = serialport(PortName, BaudRate); % For > MATLAB 2021a
fopen(s) % open serial port

%% Move to Start Position
display('Callibration Beginning...')
pause(2)

tStart = tic;
figure('units','normalized','outerposition',[0 0 1 1])
display('Moving to Origin X')
data = "G1 " + "Y" + string(-dimension_mm*0.5);
fprintf(s, '%s\n', data);
pause(Buffer_Delay_Motor)

display('Beginning Scans...')

for j = 1:ceil(Dim.X)
    for i = 1:ceil(Dim.Y)
        [tA{i,j,k}, sA{i,j,k}, sRateA] = acquireOscilloscopeData(ScopeUSBAddress, channel_A);
        [tB{i,j,k}, sB{i,j,k}, sRateB] = acquireOscilloscopeData(ScopeUSBAddress, channel_B);
        dist = sqrt(abs(((i-Dim.X/2)*Increment.X)).^2 + (j*Increment.Y).^2);
        P{i,j,k} = 1e-6*sA{i,j,k}/callibration;
        PF{i,j,k} = filtfilt(b,a, P{i,j,k});

        try
            data = "G1 " + "Y" + string(Increment.Y);
            fprintf(s, '%s\n', data);

        catch e
            display(e)
            % Try again
            while e_count < 10
                pause(10);
                e_count = e_count + 1;
                obj = instrfind;
                fclose(obj);
                pause(5);
                fopen(s);
            end
            display('Error: Restarting Serial Port...')
            %fclose(s)
        end

        Y = Y + Increment.Y;
        display("Scanning: " + X + "," + Y + "," + Z);
        plotdata(tA{i,j,k}, tB{i,j,k}, sA{i,j,k}, sB{i,j,k} , X , Y , Z, P{i,j,k}, PF{i,j,k}, dist)
        pause(Sample_Delay_Motor)
    end

    try
    data = "G1 " + "Y" + string(-Dim.Y*Increment.Y);
    fprintf(s, '%s\n', data);
    catch e
        display(e)
        % Try again
        while e_count < 10
            pause(10);
            e_count = e_count + 1;
            obj = instrfind;
            fclose(obj);
            pause(5);
            fopen(s);
        end
        display('Error: Restarting Serial Port...')
        %fclose(s)
    end
    Y = Y + -Dim.Y*Increment.Y;
    pause(Buffer_Delay_Motor)

    try
    data = "G1 " + "X" + string(Increment.X);
    fprintf(s, '%s\n', data);
    catch e
        display(e)
        % Try again
        while e_count < 10
            pause(10);
            e_count = e_count + 1;
            obj = instrfind;
            fclose(obj);
            pause(5);
            fopen(s);
        end
        display('Error: Restarting Serial Port...')
        %fclose(s)
    end
    X = X + Increment.X;
    pause(2)
end
 

tEnd = toc(tStart);

display("Time Elapsed: " + tEnd)

% Close Serial Port
display('Closing Serial Port...')
fclose(s)

%% Save Workspace
display("Saving File...")
save(save_filename)
display("Save Finished")
%% Plotting
function plotdata(tA, tB, sA, sB , X , Y , Z, P, PF, dist)
    tA = tA*1e6;
    tB = tB*1e6;

    subplot(2,1,1)
    %plot(tA,sB./max(sB) , 'r') ; hold on
    plot(tA,sB ,'r'); hold on
    plot(tA,P, 'k'); 
    xline(-100+(dist*1e-3)/(1500)*1e6, 'b')
    hold off
    legend('TX','Signal', 'Path Distance')
    xlabel('Time (us)')
    ylabel('Input Voltage (V)')
    axis([-inf inf  -inf inf])
    subplot(2,1,2)
    plot(tA,sB ,'r'); hold on
    xline(-100+(dist*1e-3)/(1540)*1e6 , 'b'); 
    plot(tA,PF); 
    hold off
    legend('Signal', 'Path Distance')
    xlabel('Time (us)')
    ylabel('Acoustic Pressure (MPa)')
    axis([-inf inf  -inf inf])

end