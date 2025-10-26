clc
clear all
close all

%% ONDA HGL200 with AH-2010 Preamplifier Hydrophone Callibration
M_c = 45e-9; % 50nV/Pa
C_h = 13e-12; % 30pF Onda HGL-0200 Hydrophone
C_a = 6.3e-12; % 6.3pf Onda AH-2010 Pre-Amplifier
C_c = 1.6e-12; % Right Angle Connector
G = 10; % 20dB Pre-Amplifier Gain

callibration = G*M_c*(C_h/(C_h+C_c+C_a));
M = 1e-6*((118/1000)./callibration);

%%
for i = 1:length(sB)
    [pk,loc] = findpeaks(sA{i}(45000:end));
    peak_pressure(i) = mean(abs(pk(1:1)));
end
%% Plotting
function plotdata(tA, sA, tB, sB, callibration)
    tA = tA*1e6;
    sA = sA;

    subplot(2,1,1)
    plot(tA,sA)
    xlabel('Time (us)')
    ylabel('Voltage (V)')
    title("Measured Hydrophone Voltage")
    subplot(2,1,2)
    hold on
    %plot(tA,1e-6*sA./callibration)
    plot(tA,sA)
    plot(tA,sB*(max(sA)/max(sB)))
    hold off
    legend('Acoustic Pressure', 'Trigger')
    xlabel('Time (us)')
    ylabel('Acoustic Pressure (MPa)')
    title("Measured Pressure")
    axis([0 50 -inf inf])

end