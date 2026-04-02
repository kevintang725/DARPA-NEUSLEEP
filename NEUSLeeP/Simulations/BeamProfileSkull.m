clear; clc; close all;

% =========================================================
% DOMAIN SETUP
% =========================================================
Nx = 320;   % axial samples
Ny = 400;   % radial samples

Lx = 100e-3;   % axial extent = 100 mm
Ly =  60e-3;   % radial extent = 60 mm  -> display as -30 to 30 mm

dx = Lx / Nx;
dy = Ly / Ny;

% Internal k-Wave coordinates
x = (0:Nx-1) * dx;   % m
y = (0:Ny-1) * dy;   % m

x_mm = x * 1e3;
y_mm = y * 1e3;

[Xmm, Ymm] = ndgrid(x_mm, y_mm);

kgrid = kWaveGrid(Nx, dx, Ny, dy);

% =========================================================
% DISPLAY COORDINATES
% =========================================================
% Axial display: 0 mm at bottom, 100 mm at top
axial_disp_mm = x_mm(end) - x_mm;

% Radial display: -30 mm to 30 mm
radial_disp_mm = y_mm - mean(y_mm);

% =========================================================
% BASE MEDIUM PROPERTIES
% =========================================================
c_bg   = 1500;   % m/s
rho_bg = 1000;   % kg/m^3

medium_ff.sound_speed = c_bg * ones(Nx, Ny);
medium_ff.density     = rho_bg * ones(Nx, Ny);
medium_ff.alpha_coeff = 0.75 * ones(Nx, Ny);
medium_ff.alpha_power = 1.5;

% =========================================================
% SOURCE LOCATION
% =========================================================
src_row = Nx - 3;

src_depth_mm_internal = x_mm(src_row);
src_depth_mm_display  = axial_disp_mm(src_row);

% =========================================================
% 8-CHANNEL CONCENTRIC RING ARRAY SPECIFICATION
% =========================================================
ring_ID_mm = [ 5.35, 10.72, 16.07, 21.43, 26.79, 32.15, 37.51, 42.86 ];
ring_OD_mm = [10.07, 15.42, 20.78, 26.14, 31.49, 36.86, 42.21, 47.57 ];

ring_IR_mm  = ring_ID_mm / 2;
ring_OR_mm  = ring_OD_mm / 2;
ring_mid_mm = (ring_IR_mm + ring_OR_mm) / 2;

nChannels = numel(ring_ID_mm);

% =========================================================
% SOURCE MASK: 2D APPROXIMATION OF 8-CHANNEL CRUTA
% =========================================================
source.p_mask = zeros(Nx, Ny);

array_center_mm = 0;
r_mm = abs(radial_disp_mm - array_center_mm);

channel_map = zeros(1, Ny);   % 0 = inactive, 1..8 = channel
for ch = 1:nChannels
    idx = (r_mm >= ring_IR_mm(ch)) & (r_mm <= ring_OR_mm(ch));
    channel_map(idx) = ch;
end

active_cols = find(channel_map > 0);
source.p_mask(src_row, active_cols) = 1;

% =========================================================
% FOCUSING DELAYS
% =========================================================
f0 = 650e3;         % Hz
source_amp = 1e6;   % Pa

target_focus_depth_mm = 72.2;

focus_dist_mm = target_focus_depth_mm - src_depth_mm_display;
focus_dist_m  = focus_dist_mm * 1e-3;

if focus_dist_mm <= 0
    error('Target focal depth must be above the source when measured from bottom to top.');
end

channel_delay_s = zeros(1, nChannels);
for ch = 1:nChannels
    r_mid_m = ring_mid_mm(ch) * 1e-3;
    path_excess = sqrt(focus_dist_m^2 + r_mid_m^2) - focus_dist_m;
    channel_delay_s(ch) = path_excess / c_bg;
end

channel_delay_s = channel_delay_s - max(channel_delay_s);
channel_apod = ones(1, nChannels);

% =========================================================
% TIME ARRAY
% =========================================================
cfl = 0.1;
t_end = 1.3 * (Lx / c_bg);
kgrid.makeTime(c_bg, cfl, t_end);

% =========================================================
% BUILD SOURCE SIGNALS
% =========================================================
active_pts = find(source.p_mask);
nSrc = numel(active_pts);

source.p = zeros(nSrc, numel(kgrid.t_array));
for i = 1:nSrc
    [~, col_idx] = ind2sub([Nx, Ny], active_pts(i));
    ch = channel_map(col_idx);
    if ch > 0
        tau = channel_delay_s(ch);
        source.p(i, :) = channel_apod(ch) * source_amp * ...
            sin(2*pi*f0*(kgrid.t_array + tau));
    end
end

% =========================================================
% SENSOR
% =========================================================
sensor.mask = ones(Nx, Ny);
sensor.record = {'p_max', 'p_rms'};

% =========================================================
% SOURCE DISPLAY MAP
% =========================================================
source_display = zeros(Nx, Ny);
for col = 1:Ny
    if channel_map(col) > 0
        source_display(src_row, col) = channel_map(col);
    end
end

% =========================================================
% RUN FREE-FIELD
% =========================================================
disp('Running free-field simulation...');
input_args = {'PMLInside', false, 'PlotPML', false, 'DisplayMask', 'off'};

sensor_data_ff = kspaceFirstOrder2D(kgrid, medium_ff, source, sensor, input_args{:});
p_max_ff = reshape(sensor_data_ff.p_max, Nx, Ny);
p_rms_ff = reshape(sensor_data_ff.p_rms, Nx, Ny);

% =========================================================
% FIND FREE-FIELD FOCUS LOCATION
% =========================================================
[~, idx_ff] = max(p_max_ff(:));
[focus_row_ff, focus_col_ff] = ind2sub(size(p_max_ff), idx_ff);
focus_axial_ff_mm  = axial_disp_mm(focus_row_ff);
focus_radial_ff_mm = radial_disp_mm(focus_col_ff);

% =========================================================
% FREE-FIELD FWHM
% =========================================================
axial_profile_ff_peak  = p_max_ff(:, focus_col_ff);
radial_profile_ff_peak = p_max_ff(focus_row_ff, :);

[axial_fwhm_ff_peak_mm, axL_ff_peak, axR_ff_peak] = ...
    local_fwhm(axial_disp_mm, axial_profile_ff_peak);

[radial_fwhm_ff_peak_mm, rdL_ff_peak, rdR_ff_peak] = ...
    local_fwhm(radial_disp_mm, radial_profile_ff_peak);

% =========================================================
% SWEEP CURVATURES FOR SKULL CASES
% =========================================================
skull_thickness_mm  = 6;
skull_center_lat_mm = 0;

% Columns 2-5 in the figure
curvature_list = [0.003, 0.006, 0.009, 0.012];
nCurv = numel(curvature_list);

% Storage
p_max_sk_all            = cell(1, nCurv);
skull_mask_all          = cell(1, nCurv);
post_skull_mask_all     = cell(1, nCurv);

focus_row_sk_all        = nan(1, nCurv);
focus_col_sk_all        = nan(1, nCurv);
focus_axial_sk_mm_all   = nan(1, nCurv);
focus_radial_sk_mm_all  = nan(1, nCurv);

axial_profile_sk_all    = cell(1, nCurv);
radial_profile_sk_all   = cell(1, nCurv);

axial_valid_sk_all      = cell(1, nCurv);
radial_valid_sk_all     = cell(1, nCurv);

axial_fwhm_sk_mm_all    = nan(1, nCurv);
radial_fwhm_sk_mm_all   = nan(1, nCurv);

axL_sk_all              = nan(1, nCurv);
axR_sk_all              = nan(1, nCurv);
rdL_sk_all              = nan(1, nCurv);
rdR_sk_all              = nan(1, nCurv);

peak_sk_all             = nan(1, nCurv);

for k = 1:nCurv
    curvature_strength = curvature_list(k);

    fprintf('Running skull simulation for curvature = %.4f ...\n', curvature_strength);

    % -----------------------------------------------------
    % SKULL GEOMETRY
    % -----------------------------------------------------
    skull_bottom_disp_mm = (src_depth_mm_display + 1.0) + ...
        curvature_strength * (radial_disp_mm - skull_center_lat_mm).^2;
    skull_top_disp_mm = skull_bottom_disp_mm + skull_thickness_mm;

    % Convert skull surfaces to internal x_mm
    skull_bottom_internal_mm = x_mm(end) - skull_bottom_disp_mm;
    skull_top_internal_mm    = x_mm(end) - skull_top_disp_mm;

    skull_bottom_2d = repmat(skull_bottom_internal_mm, Nx, 1);
    skull_top_2d    = repmat(skull_top_internal_mm, Nx, 1);

    skull_mask = (Xmm >= skull_top_2d) & (Xmm <= skull_bottom_2d);

    medium_skull = medium_ff;
    medium_skull.sound_speed(skull_mask) = 2800;
    medium_skull.density(skull_mask)     = 1900;
    medium_skull.alpha_coeff(skull_mask) = 20;

    % -----------------------------------------------------
    % POST-SKULL VALID FOCUS REGION
    % -----------------------------------------------------
    post_skull_mask = false(Nx, Ny);
    for j = 1:Ny
        skull_rows = find(skull_mask(:, j));
        if isempty(skull_rows)
            post_skull_mask(:, j) = true;
        else
            skull_axial_vals = axial_disp_mm(skull_rows);
            top_of_skull_axial = max(skull_axial_vals);
            post_skull_mask(:, j) = axial_disp_mm(:) > top_of_skull_axial;
        end
    end

    % -----------------------------------------------------
    % RUN WITH SKULL
    % -----------------------------------------------------
    sensor_data_sk = kspaceFirstOrder2D(kgrid, medium_skull, source, sensor, input_args{:});
    p_max_sk = reshape(sensor_data_sk.p_max, Nx, Ny);

    % -----------------------------------------------------
    % FIND FOCUS LOCATION (POST-SKULL ONLY)
    % -----------------------------------------------------
    p_max_sk_post = p_max_sk;
    p_max_sk_post(~post_skull_mask) = -Inf;

    [~, idx_sk] = max(p_max_sk_post(:));
    [focus_row_sk, focus_col_sk] = ind2sub(size(p_max_sk_post), idx_sk);

    focus_axial_sk_mm  = axial_disp_mm(focus_row_sk);
    focus_radial_sk_mm = radial_disp_mm(focus_col_sk);

    % -----------------------------------------------------
    % FWHM PROFILES
    % -----------------------------------------------------
    axial_profile_sk_peak  = p_max_sk(:, focus_col_sk);
    radial_profile_sk_peak = p_max_sk(focus_row_sk, :);

    axial_valid_sk_peak  = (~skull_mask(:, focus_col_sk)) & post_skull_mask(:, focus_col_sk);
    radial_valid_sk_peak = (~skull_mask(focus_row_sk, :).') & post_skull_mask(focus_row_sk, :).';

    [axial_fwhm_sk_peak_mm, axL_sk_peak, axR_sk_peak] = ...
        local_fwhm_masked(axial_disp_mm, axial_profile_sk_peak, axial_valid_sk_peak);

    [radial_fwhm_sk_peak_mm, rdL_sk_peak, rdR_sk_peak] = ...
        local_fwhm_masked(radial_disp_mm, radial_profile_sk_peak, radial_valid_sk_peak);

    % -----------------------------------------------------
    % STORE
    % -----------------------------------------------------
    p_max_sk_all{k}           = p_max_sk;
    skull_mask_all{k}         = skull_mask;
    post_skull_mask_all{k}    = post_skull_mask;

    focus_row_sk_all(k)       = focus_row_sk;
    focus_col_sk_all(k)       = focus_col_sk;
    focus_axial_sk_mm_all(k)  = focus_axial_sk_mm;
    focus_radial_sk_mm_all(k) = focus_radial_sk_mm;

    axial_profile_sk_all{k}   = axial_profile_sk_peak;
    radial_profile_sk_all{k}  = radial_profile_sk_peak;

    axial_valid_sk_all{k}     = axial_valid_sk_peak;
    radial_valid_sk_all{k}    = radial_valid_sk_peak;

    axial_fwhm_sk_mm_all(k)   = axial_fwhm_sk_peak_mm;
    radial_fwhm_sk_mm_all(k)  = radial_fwhm_sk_peak_mm;

    axL_sk_all(k)             = axL_sk_peak;
    axR_sk_all(k)             = axR_sk_peak;
    rdL_sk_all(k)             = rdL_sk_peak;
    rdR_sk_all(k)             = rdR_sk_peak;

    peak_sk_all(k)            = max(p_max_sk_post(:));
end

% =========================================================
% COMMON COLOR LIMITS
% =========================================================
clim_pmax = [0 1.5e6];   % Pa
clim_prof = [0 2.5];     % MPa

% =========================================================
% PLOT 3x5 FIGURE
% Row 1 = Acoustic field
% Row 2 = Axial FWHM
% Row 3 = Radial FWHM
% Col 1 = Free-field
% Col 2-5 = Skull with curvature sweep
% =========================================================
figure('Color', 'w', 'Name', 'Curvature Sweep: Free-field and Skull Cases', ...
       'Position', [50 40 1800 950]);

ax_field = gobjects(1, 5);

% =========================================================
% COLUMN 1: FREE-FIELD
% =========================================================
ax_field(1) = subplot(3,5,1);
imagesc(radial_disp_mm, axial_disp_mm, p_max_ff);
axis image;
set(gca, 'YDir', 'normal');
colormap(gca, turbo);
caxis(clim_pmax);
hold on;
plot(focus_radial_ff_mm, focus_axial_ff_mm, 'wo', 'MarkerSize', 8, 'LineWidth', 1.8);
yline(target_focus_depth_mm, 'w--', '72.2 mm target', 'LineWidth', 1.0);
title('No Skull');
xlabel('Radial position (mm)');
ylabel('Axial depth (mm)');
xlim([-30 30]);
ylim([0 100]);
hold off;

subplot(3,5,6);
axial_profile_ff_peak_mpa = axial_profile_ff_peak / 1e6;
plot(axial_disp_mm, axial_profile_ff_peak_mpa, 'b-', 'LineWidth', 1.5); hold on;
halfmax_ff_ax = max(axial_profile_ff_peak_mpa) / 2;
yline(halfmax_ff_ax, 'k--', 'LineWidth', 1);
if ~isnan(axL_ff_peak), xline(axL_ff_peak, 'r--', 'LineWidth', 1); end
if ~isnan(axR_ff_peak), xline(axR_ff_peak, 'r--', 'LineWidth', 1); end
plot([axL_ff_peak axR_ff_peak], [halfmax_ff_ax halfmax_ff_ax], ...
    'ro', 'MarkerFaceColor', 'r');
title(sprintf('Axial FWHM = %.2f mm', axial_fwhm_ff_peak_mm));
xlabel('Axial depth (mm)');
ylabel('Pressure (MPa)');
xlim([0 100]);
ylim(clim_prof);
grid on;
hold off;

subplot(3,5,11);
radial_profile_ff_peak_mpa = radial_profile_ff_peak / 1e6;
plot(radial_disp_mm, radial_profile_ff_peak_mpa, 'b-', 'LineWidth', 1.5); hold on;
halfmax_ff_rd = max(radial_profile_ff_peak_mpa) / 2;
yline(halfmax_ff_rd, 'k--', 'LineWidth', 1);
if ~isnan(rdL_ff_peak), xline(rdL_ff_peak, 'r--', 'LineWidth', 1); end
if ~isnan(rdR_ff_peak), xline(rdR_ff_peak, 'r--', 'LineWidth', 1); end
plot([rdL_ff_peak rdR_ff_peak], [halfmax_ff_rd halfmax_ff_rd], ...
    'ro', 'MarkerFaceColor', 'r');
title(sprintf('Radial FWHM = %.2f mm', radial_fwhm_ff_peak_mm));
xlabel('Radial position (mm)');
ylabel('Pressure (MPa)');
xlim([-30 30]);
ylim(clim_prof);
grid on;
hold off;

% =========================================================
% COLUMNS 2-5: SKULL CURVATURE SWEEP
% =========================================================
for k = 1:nCurv
    col_idx = k + 1;

    p_max_sk = p_max_sk_all{k};
    skull_mask = skull_mask_all{k};

    focus_axial_sk_mm  = focus_axial_sk_mm_all(k);
    focus_radial_sk_mm = focus_radial_sk_mm_all(k);

    axial_profile_sk_peak = axial_profile_sk_all{k};
    radial_profile_sk_peak = radial_profile_sk_all{k};

    axial_valid_sk_peak = axial_valid_sk_all{k};
    radial_valid_sk_peak = radial_valid_sk_all{k};

    axial_fwhm_sk_peak_mm = axial_fwhm_sk_mm_all(k);
    radial_fwhm_sk_peak_mm = radial_fwhm_sk_mm_all(k);

    axL_sk_peak = axL_sk_all(k);
    axR_sk_peak = axR_sk_all(k);
    rdL_sk_peak = rdL_sk_all(k);
    rdR_sk_peak = rdR_sk_all(k);

    curvature_strength = curvature_list(k);

    % ---------------- Row 1: Acoustic field ----------------
    ax_field(col_idx) = subplot(3,5,col_idx);
    imagesc(radial_disp_mm, axial_disp_mm, p_max_sk);
    axis image;
    set(gca, 'YDir', 'normal');
    colormap(gca, turbo);
    caxis(clim_pmax);
    hold on;

    h1 = imagesc(radial_disp_mm, axial_disp_mm, double(skull_mask));
    set(h1, 'AlphaData', 0.16 * double(skull_mask));
    contour(radial_disp_mm, axial_disp_mm, skull_mask, [1 1], 'w', 'LineWidth', 1.5);

    plot(focus_radial_sk_mm, focus_axial_sk_mm, 'wo', 'MarkerSize', 8, 'LineWidth', 1.8);
    yline(target_focus_depth_mm, 'w--', '72.2 mm target', 'LineWidth', 1.0);

    caxis(clim_pmax);
    title(sprintf('Skull, curv = %.4f', curvature_strength));
    xlabel('Radial position (mm)');
    if col_idx == 2
        ylabel('Axial depth (mm)');
    end
    xlim([-30 30]);
    ylim([0 100]);
    hold off;

    % ---------------- Row 2: Axial FWHM ----------------
    subplot(3,5,5 + col_idx);
    axial_profile_sk_peak_mpa = axial_profile_sk_peak / 1e6;
    axial_profile_sk_plot = axial_profile_sk_peak_mpa;
    axial_profile_sk_plot(~axial_valid_sk_peak) = NaN;

    plot(axial_disp_mm, axial_profile_sk_plot, 'b-', 'LineWidth', 1.5); hold on;
    halfmax_sk_ax = max(axial_profile_sk_plot, [], 'omitnan') / 2;
    yline(halfmax_sk_ax, 'k--', 'LineWidth', 1);
    if ~isnan(axL_sk_peak), xline(axL_sk_peak, 'r--', 'LineWidth', 1); end
    if ~isnan(axR_sk_peak), xline(axR_sk_peak, 'r--', 'LineWidth', 1); end
    plot([axL_sk_peak axR_sk_peak], [halfmax_sk_ax halfmax_sk_ax], ...
        'ro', 'MarkerFaceColor', 'r');
    title(sprintf('Axial FWHM = %.2f mm', -axial_fwhm_sk_peak_mm));
    xlabel('Axial depth (mm)');
    if col_idx == 2
        ylabel('Pressure (MPa)');
    end
    xlim([0 100]);
    ylim(clim_prof);
    grid on;
    hold off;

    % ---------------- Row 3: Radial FWHM ----------------
    subplot(3,5,10 + col_idx);
    radial_profile_sk_peak_mpa = radial_profile_sk_peak / 1e6;
    radial_profile_sk_plot = radial_profile_sk_peak_mpa;
    radial_profile_sk_plot(~radial_valid_sk_peak) = NaN;

    plot(radial_disp_mm, radial_profile_sk_plot, 'b-', 'LineWidth', 1.5); hold on;
    halfmax_sk_rd = max(radial_profile_sk_plot, [], 'omitnan') / 2;
    yline(halfmax_sk_rd, 'k--', 'LineWidth', 1);
    if ~isnan(rdL_sk_peak), xline(rdL_sk_peak, 'r--', 'LineWidth', 1); end
    if ~isnan(rdR_sk_peak), xline(rdR_sk_peak, 'r--', 'LineWidth', 1); end
    plot([rdL_sk_peak rdR_sk_peak], [halfmax_sk_rd halfmax_sk_rd], ...
        'ro', 'MarkerFaceColor', 'r');
    title(sprintf('Radial FWHM = %.2f mm', radial_fwhm_sk_peak_mm));
    xlabel('Radial position (mm)');
    if col_idx == 2
        ylabel('Pressure (MPa)');
    end
    xlim([-30 30]);
    ylim(clim_prof);
    grid on;
    hold off;
end

% =========================================================
% SINGLE COLORBAR FOR ACOUSTIC FIELD ROW
% =========================================================
cb = colorbar(ax_field(end), 'Position', [0.92 0.71 0.012 0.20]);
ylabel(cb, 'Peak pressure (Pa)');

% =========================================================
% SUMMARY METRICS
% =========================================================
output_peak_ff = max(p_max_ff(:));

fprintf('\n===== CURVATURE SWEEP SUMMARY =====\n');
fprintf('Axial axis                 : 0 mm bottom -> 100 mm top\n');
fprintf('Radial axis                : -30 mm -> 30 mm\n');
fprintf('Source axial position      : %.2f mm\n', src_depth_mm_display);
fprintf('Target focal depth         : %.2f mm\n', target_focus_depth_mm);
fprintf('Focus distance from source : %.2f mm\n', focus_dist_mm);
fprintf('Skull thickness            : %.2f mm\n', skull_thickness_mm);
fprintf('Free-field peak            : %.4g Pa\n', output_peak_ff);
fprintf('Free-field focus           : axial = %.2f mm, radial = %.2f mm\n', ...
    focus_axial_ff_mm, focus_radial_ff_mm);
fprintf('Free-field axial FWHM      : %.2f mm\n', axial_fwhm_ff_peak_mm);
fprintf('Free-field radial FWHM     : %.2f mm\n', radial_fwhm_ff_peak_mm);
fprintf('\n');

for k = 1:nCurv
    peak_loss_pct = 100 * (1 - peak_sk_all(k) / output_peak_ff);
    focus_shift_axial_mm  = focus_axial_sk_mm_all(k)  - focus_axial_ff_mm;
    focus_shift_radial_mm = focus_radial_sk_mm_all(k) - focus_radial_ff_mm;

    fprintf('Curvature = %.4f\n', curvature_list(k));
    fprintf('  Skull peak (post-skull)  : %.4g Pa\n', peak_sk_all(k));
    fprintf('  Peak loss                : %.2f %%\n', peak_loss_pct);
    fprintf('  Focus                    : axial = %.2f mm, radial = %.2f mm\n', ...
        focus_axial_sk_mm_all(k), focus_radial_sk_mm_all(k));
    fprintf('  Focus shift              : axial = %.2f mm, radial = %.2f mm\n', ...
        focus_shift_axial_mm, focus_shift_radial_mm);
    fprintf('  Axial FWHM               : %.2f mm\n', axial_fwhm_sk_mm_all(k));
    fprintf('  Radial FWHM              : %.2f mm\n', radial_fwhm_sk_mm_all(k));
    fprintf('\n');
end
fprintf('===================================\n\n');

% =========================================================
% LOCAL FUNCTIONS
% =========================================================
function [fwhm, x_left, x_right] = local_fwhm(coord, profile)
    profile = double(profile(:));
    coord   = double(coord(:));

    x_left = NaN;
    x_right = NaN;
    fwhm = NaN;

    if all(profile == 0) || max(profile) <= 0
        return;
    end

    [~, imax] = max(profile);
    halfmax = max(profile) / 2;
    above = profile >= halfmax;

    left_idx = find(above(1:imax), 1, 'first');
    right_idx = imax - 1 + find(above(imax:end), 1, 'last');

    if isempty(left_idx) || isempty(right_idx)
        return;
    end

    if left_idx == 1
        x_left = coord(left_idx);
    else
        x1 = coord(left_idx - 1);
        x2 = coord(left_idx);
        y1 = profile(left_idx - 1);
        y2 = profile(left_idx);
        x_left = x1 + (halfmax - y1) * (x2 - x1) / (y2 - y1);
    end

    if right_idx == numel(profile)
        x_right = coord(right_idx);
    else
        x1 = coord(right_idx);
        x2 = coord(right_idx + 1);
        y1 = profile(right_idx);
        y2 = profile(right_idx + 1);
        x_right = x1 + (halfmax - y1) * (x2 - x1) / (y2 - y1);
    end

    fwhm = x_right - x_left;
end

function [fwhm, x_left, x_right] = local_fwhm_masked(coord, profile, valid_mask)
    profile = double(profile(:));
    coord = double(coord(:));
    valid_mask = logical(valid_mask(:));

    x_left = NaN;
    x_right = NaN;
    fwhm = NaN;

    if numel(coord) ~= numel(profile) || numel(profile) ~= numel(valid_mask)
        error('coord, profile, and valid_mask must have the same length.');
    end

    profile(~valid_mask) = NaN;

    if all(isnan(profile))
        return;
    end

    peak_val = max(profile, [], 'omitnan');
    if isempty(peak_val) || isnan(peak_val) || peak_val <= 0
        return;
    end

    halfmax = peak_val / 2;

    tmp = profile;
    tmp(isnan(tmp)) = -Inf;
    [~, imax] = max(tmp);

    if ~isfinite(tmp(imax))
        return;
    end

    above = (profile >= halfmax);

    if ~above(imax)
        return;
    end

    left_idx = imax;
    while left_idx > 1 && above(left_idx - 1)
        left_idx = left_idx - 1;
    end

    right_idx = imax;
    while right_idx < numel(profile) && above(right_idx + 1)
        right_idx = right_idx + 1;
    end

    if left_idx == 1 || isnan(profile(left_idx - 1))
        x_left = coord(left_idx);
    else
        x1 = coord(left_idx - 1);
        x2 = coord(left_idx);
        y1 = profile(left_idx - 1);
        y2 = profile(left_idx);
        x_left = x1 + (halfmax - y1) * (x2 - x1) / (y2 - y1);
    end

    if right_idx == numel(profile) || isnan(profile(right_idx + 1))
        x_right = coord(right_idx);
    else
        x1 = coord(right_idx);
        x2 = coord(right_idx + 1);
        y1 = profile(right_idx);
        y2 = profile(right_idx + 1);
        x_right = x1 + (halfmax - y1) * (x2 - x1) / (y2 - y1);
    end

    fwhm = x_right - x_left;
end