%% Import Data

%% ONDA HGL200 with AH-2010 Preamplifier Hydrophone Callibration
M_c = 50e-9; % 50nV/Pa
C_h = 30e-12; % 30pF Onda HGL-0200 Hydrophone
C_a = 6.3e-12; % 6.3pf Onda AH-2010 Pre-Amplifier
C_c = 1.6e-12; % Right Angle Connector
G = 10; % 20dB Pre-Amplifier Gain

callibration = G*M_c*(C_h/(C_h+C_c+C_a));

%% Stimulation Parameters
fc = 0.65e6;
rho = 1046;                     % kg/m3
c0 = 1530;                      % m/s
alpha = 0.07;                   % dB/cm/MHz
PD = 30e-6;                     % s
PRF = 1000;                     % Hz;
TPRF = 1/PRF;                   % s

%%

figure
hold on
for n = 1:1:length(sA)

    %Pr{n} = 1e-6*sA{n}./callibration;
    %Pr{n} = 1e-6*ifft(fft(sA{n}(30000:50000))./callibration);
    Pr{n} = 1e-6*ifft(fft(sA{n}(30000:31500))./callibration);
    
    
    % Compute Values
    %PPI(n) = trapz(Pr{n}.^2);
    %PII(n) = PPI(n)./(rho*c0);
    PII{n} = (1e6*Pr{n}.^2)./(rho*c0);
    MI(n) = abs(min(Pr{n}))/sqrt(fc/1e6);

    I.SPPA(n) = 1e-4*max(PII{n}/PD);
    I.SPTA(n) = 1e-4*max(Pr{n}/TPRF);
    Pmax(n) = abs(min(Pr{n}));
    
    %plot(1e6*tA{n}(30000:50000),Pr{n})
    plot(1e6*tA{n}(30000:31500),Pr{n})
    %axis([-100 0 -inf inf])
    xlabel('Time (us)')
    ylabel('Acoustic Pressure (MPa)')
    %legend('2.65Vpp','5.3Vpp','7.95Vpp','10.6Vpp','21.2Vpp','31.8Vpp')
end
hold off

figure
subplot(2,2,1)
%plot([2.65 5.3 7.95 10.6 21.2 31.8], I.SPPA)
plot([0:length(I.SPPA)-1], I.SPPA,'.-')
%xlabel('Peak-to-Peak Voltage (Vpp)')
xlabel('Axial (mm)')
ylabel('I_{SPPA} (W/cm^2)')
subplot(2,2,2)
%plot([2.65 5.3 7.95 10.6 21.2 31.8], I.SPTA)
plot([0:length(I.SPTA)-1], I.SPTA,'.-')
%xlabel('Peak-to-Peak Voltage (Vpp)')
xlabel('Axial (mm)')
ylabel('I_{SPTA} (W/cm^2)')
subplot(2,2,3)
%plot([2.65 5.3 7.95 10.6 21.2 31.8], I.SPTA)
plot([0:length(MI)-1], MI,'.-')
%xlabel('Peak-to-Peak Voltage (Vpp)')
xlabel('Axial (mm)')
ylabel('Mechanical Index (MI)')
subplot(2,2,4)
%plot([2.65 5.3 7.95 10.6 21.2 31.8], I.SPTA)
plot([0:length(Pmax)-1], Pmax,'.-')
%xlabel('Peak-to-Peak Voltage (Vpp)')
xlabel('Axial (mm)')
ylabel('Peak Pressure (MPa)')



