clc; clear; close all;

%% General Parameters
c_t = 3770;        
k_t = 0.195;         
c_b = 3770;        
T_a = 37;          
Z = 1.5e6;         

%% Perfusion Rate
F_ml_per_min_per_100g = 80;    
rho_b = 1060;                  
rho_t = 1040;                   

F_m3_per_s_per_kg = F_ml_per_min_per_100g * 1e-6 / 60 / 0.1;
omega_b = (rho_b * F_m3_per_s_per_kg) / rho_t;

fprintf('Perfusion: %.2f mL/min/100g → %.4e m³/s/kg → omega_b: %.4e 1/s\n', ...
    F_ml_per_min_per_100g, F_m3_per_s_per_kg, omega_b);

%% Absorption Coefficient
attenuation_dB_MHz_cm = 0.75;  
frequency_MHz = 0.65;          
attenuation_dB_cm = attenuation_dB_MHz_cm * frequency_MHz;
mu_abs = attenuation_dB_cm * 0.1151 * 100;    

fprintf('Attenuation @ %.3f MHz: %.4f dB/cm → mu_abs: %.4f Np/m\n', ...
    frequency_MHz, attenuation_dB_cm, mu_abs);

%% Load Pressure Field
load('Free-Field -f170.mat');  
[Nr, Ny] = size(p_measured);

%% Mesh Setup
r_max = 0.06; y_max = 0.1;
dr = r_max / Nr; dy = y_max / Ny;
r = linspace(-r_max/2, r_max/2, Nr);
y = linspace(0, y_max, Ny);

%% Time Setup
%t_final = 5400;   
t_final = 60;
dt = 0.05;       
Nt = round(t_final / dt);
alpha = k_t / (rho_t * c_t);
dt_critical = min(dr^2, dy^2) / (4 * alpha);
if dt >= dt_critical
    warning('Time step dt = %.5f exceeds stability limit dt_critical = %.5f! Consider reducing dt.', dt, dt_critical);
else
    fprintf('Time step OK: dt = %.5f < dt_critical = %.5f\n', dt, dt_critical);
end

%% Initial Conditions
T = T_a * ones(Nr, Ny);
Q_base = mu_abs * (abs(p_measured * 1e6)).^2 / Z;
fprintf('Max Q_base: %.3e W/m³\n', max(Q_base(:)));

%% Skull + Axial Attenuation
alpha_s_dB_per_cm_MHz = 20;  
f_MHz = 0.65;                
d_s_cm = 0.6;                
loss_dB = alpha_s_dB_per_cm_MHz * f_MHz * d_s_cm;
amp_factor = 10^(-loss_dB / 20);
attenuation_factor_axial = flip(exp(-2 * mu_abs * y))';   
attenuation_matrix = repmat(attenuation_factor_axial, 1, Nr)';  
Q_eff_brain = Q_base .* attenuation_matrix * amp_factor^2;

%% Precompute Terms
perf_term = omega_b * c_b / (rho_t * c_t);
src_term = 1 / (rho_t * c_t);

%% Build Laplacian
Nx = Nr * Ny; e = ones(Nx,1);
D_r = spdiags([e -2*e e], -1:1, Nr, Nr) / dr^2;
D_y = spdiags([e -2*e e], -1:1, Ny, Ny) / dy^2;
L_r = kron(speye(Ny), D_r);
L_y = kron(D_y, speye(Nr));
L = L_r + L_y;
M = speye(Nx) - dt * alpha * L - dt * perf_term * speye(Nx);

%% Stimulation Protocol
block_on = 30; block_off = 30; block_period = block_on + block_off;
PRF = 100; duty_cycle = 0.05; prf_period = 1 / PRF;
prf_on_time = duty_cycle * prf_period;

%% Select ROI
figure;
imagesc(r*1000, y*1000, rot90(p_measured,2)); axis xy; 
cb = colorbar; cb.Label.String = 'Pressure (a.u.)'; cb.Label.FontSize = 16;
colormap('turbo');
xlabel('Radial (mm)', 'FontSize', 16); ylabel('Axial (mm)', 'FontSize', 16);
title('Pressure Field p(x,y)', 'FontSize', 18);
set(gca, 'FontSize', 16);
roi_mask = roipoly;

%% Initialize ROI Stats
T_mean_time = zeros(1, Nt);
T_max_time = zeros(1, Nt);
T_min_time = zeros(1, Nt);
time_points = (1:Nt) * dt;

%% GIF Setup
gif_filename = 'temperature_evolution.gif';
delay_time = 0.1;  
isFirstFrame = true;

%% Time Loop with Dirichlet Boundaries and GIF Saving
figure('Position', [100, 100, 600, 500]);
h = imagesc(r*1000, y*1000, rot90(T,2), [37 40]); axis xy; 
cb = colorbar; cb.Label.String = 'Temperature (°C)'; cb.Label.FontSize = 16;
colormap('turbo');
xlabel('Radial (mm)', 'FontSize', 16); ylabel('Axial (mm)', 'FontSize', 16);
title('Temperature Evolution', 'FontSize', 18);
set(gca, 'FontSize', 16);

for n = 1:Nt
    time = n * dt;
    if time <= 300  
        block_cycle = mod(time, block_period);
        if block_cycle <= block_on
            prf_cycle = mod(time, prf_period);
            Q_eff = (prf_cycle <= prf_on_time) * Q_eff_brain;
        else
            Q_eff = zeros(Nr, Ny);
        end
    else  
        Q_eff = zeros(Nr, Ny);
    end

    T_vec = T(:); Q_vec = Q_eff(:);
    rhs = T_vec + dt * src_term * Q_vec;
    T_new = M \ rhs;
    T = reshape(T_new, Nr, Ny);

    T(1, :) = T_a; T(end, :) = T_a; T(:, 1) = T_a; T(:, end) = T_a;
    T = min(max(T, T_a), 100);

    roi_vals = T(roi_mask);
    T_mean_time(n) = mean(roi_vals);
    T_max_time(n) = max(roi_vals);
    T_min_time(n) = min(roi_vals);

    if mod(n, round(0.5/dt)) == 0 || n == Nt
        set(h, 'CData', rot90(T,2));
        title(sprintf('Time: %.1f s', time), 'FontSize', 18);
        drawnow;

        frame = getframe(gcf);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im, 256);
        if isFirstFrame
            imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', inf, 'DelayTime', delay_time);
            isFirstFrame = false;
        else
            imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', delay_time);
        end
    end
end

fprintf('GIF saved as: %s\n', gif_filename);

%% Final Temperature Map
figure;
imagesc(r*1000, y*1000, rot90(T,2)); axis xy; 
cb = colorbar; cb.Label.String = 'Temperature (°C)'; cb.Label.FontSize = 16;
colormap('turbo');
xlabel('Radial (mm)', 'FontSize', 16); ylabel('Axial (mm)', 'FontSize', 16);
title('Final Temperature (°C)', 'FontSize', 18);
set(gca, 'FontSize', 16);

%% ROI Temperature Over Time
figure;
plot(time_points, T_mean_time, 'b-', 'LineWidth', 2); hold on;
plot(time_points, T_max_time, 'r--', 'LineWidth', 1.5);
plot(time_points, T_min_time, 'g--', 'LineWidth', 1.5);
xlabel('Time (s)', 'FontSize', 16); ylabel('Temperature (°C)', 'FontSize', 16);
title('ROI Temperature Over Time', 'FontSize', 18);
legend('Mean ROI Temp', 'Max ROI Temp', 'Min ROI Temp', 'Location', 'best', 'FontSize', 14);
grid on; xlim([0 t_final]); set(gca, 'FontSize', 16);

%%
[Q_norm, y_mm] = plotNormalizedPowerDeposition1D_vertical()
%%
function [Q_norm, y_mm] = plotNormalizedPowerDeposition1D_vertical()

    % Acoustic and tissue parameters
    mu_abs = 5.611
    z_brain = 1.5e6;             % Rayl
    z_skull = 7.8e6;             % Rayl
    z_water = 1.48e6;            % Rayl
    alpha_skull = 30;            % Np/m
    alpha_brain = 5;             % Np/m

    % Boundary locations (in meters)
    y_water_skull = 0.002;       % 2 mm
    y_skull_brain = 0.007;       % 7 mm

    % Depth vector (0–100 mm)
    y = linspace(0, 0.1, 2000); % in meters
    Q = zeros(size(y));

    % Reflection coefficients
    R1 = (z_water - z_skull) / (z_water + z_skull);
    R2 = (z_brain - z_skull) / (z_brain + z_skull);

    % Initial Q at y = 0
    Q0 = mu_abs * 1^2 / z_brain;

    for i = 1:length(y)
        yi = y(i);
        if yi <= y_water_skull
            % In water
            Q(i) = Q0;
        elseif yi <= y_skull_brain
            % In skull
            d_skull = yi - y_water_skull;
            Q(i) = Q0 * exp(-2 * alpha_skull * d_skull) * (R1^2);
        else
            % In brain
            d_skull = y_skull_brain - y_water_skull;
            d_brain = yi - y_skull_brain;
            Q(i) = Q0 * exp(-2 * alpha_skull * d_skull) * (R1^2) * ...
                   exp(-2 * alpha_brain * d_brain) * (R2^2);
        end
    end

    % Normalize to Q = 1 at y = 0
    Q_norm = Q / Q(1);
    y_mm = y * 1e3;

    % Plot vertically
    figure;
    plot(Q_norm, y_mm, 'b-', 'LineWidth', 2); hold on;
    xline(1, 'k--', 'Q = 1');
    yline(y_water_skull * 1e3, 'r--', 'Water–Skull');
    yline(y_skull_brain * 1e3, 'g--', 'Skull–Brain');

    set(gca, 'YDir', 'reverse');  % Depth increases downward
    ylim([0, 100]);
    xlabel('Normalized Power Deposition Q(y)');
    ylabel('Depth y (mm)');
    title('Vertical View of Normalized Power Deposition (Q = 1 at y = 0)');
    grid on;
end
