clear; clc; close all;

% =========================================================
% DOMAIN SETUP
% =========================================================
Nx = 320;   % axial samples
Ny = 400;   % radial samples

Lx = 100e-3;   % axial extent = 100 mm
Ly =  60e-3;   % radial extent = 60 mm

dx = Lx / Nx;
dy = Ly / Ny;

x = (0:Nx-1) * dx;   % m
y = (0:Ny-1) * dy;   % m

x_mm = x * 1e3;
y_mm = y * 1e3;

[Xmm, Ymm] = ndgrid(x_mm, y_mm); %#ok<NASGU>
kgrid = kWaveGrid(Nx, dx, Ny, dy);

% =========================================================
% DISPLAY COORDINATES
% =========================================================
% 0 mm at bottom, 100 mm at top
axial_disp_mm = x_mm(end) - x_mm;

% -30 mm to 30 mm
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
src_depth_mm_display = axial_disp_mm(src_row);

% =========================================================
% 8-CHANNEL CONCENTRIC RING ARRAY
% =========================================================
ring_ID_mm = [ 5.35, 10.72, 16.07, 21.43, 26.79, 32.15, 37.51, 42.86 ];
ring_OD_mm = [10.07, 15.42, 20.78, 26.14, 31.49, 36.86, 42.21, 47.57 ];

ring_IR_mm  = ring_ID_mm / 2;
ring_OR_mm  = ring_OD_mm / 2;
ring_mid_mm = (ring_IR_mm + ring_OR_mm) / 2;
nChannels = numel(ring_ID_mm);

source.p_mask = zeros(Nx, Ny);
array_center_mm = 0;
r_mm = abs(radial_disp_mm - array_center_mm);

channel_map = zeros(1, Ny);
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

target_focus_depth_mm = 72.2;   % bottom -> top
focus_dist_mm = target_focus_depth_mm - src_depth_mm_display;
focus_dist_m  = focus_dist_mm * 1e-3;

if focus_dist_mm <= 0
    error('Target focal depth must be above the source.');
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
% BASE SKULL PARAMETERS
% =========================================================
skull_thickness_mm = 6;     % actual thickness
base_skull_density = 1900;  % kg/m^3
base_skull_c       = 2800;  % m/s
base_skull_alpha   = 20;

% =========================================================
% RUN FREE FIELD ONCE
% =========================================================
disp('Running free-field simulation...');
input_args = {'PMLInside', false, 'PlotPML', false, 'DisplayMask', 'off'};
sensor_data_ff = kspaceFirstOrder2D(kgrid, medium_ff, source, sensor, input_args{:}); %#ok<NASGU>

% =========================================================
% SWEEPS
% =========================================================
curvature_vals = [0, 0.003, 0.006, 0.009];
density_vals   = [1600, 1700, 1800, 1900];
thickness_vals = [4, 5, 6, 7];

curv_results  = struct([]);
dens_results  = struct([]);
thick_results = struct([]);

% =========================================================
% CURVATURE SWEEP
% =========================================================
for ii = 1:numel(curvature_vals)
    curvature_strength = curvature_vals(ii);

    [medium_skull, skull_mask, post_skull_mask] = make_skull_medium( ...
        medium_ff, Xmm, radial_disp_mm, axial_disp_mm, src_row, ...
        skull_thickness_mm, curvature_strength, ...
        base_skull_c, base_skull_density, base_skull_alpha);

    fprintf('Running curvature sweep case %d/%d ...\n', ii, numel(curvature_vals));
    sensor_data_sk = kspaceFirstOrder2D(kgrid, medium_skull, source, sensor, input_args{:});
    p_max_sk = reshape(sensor_data_sk.p_max, Nx, Ny);

    [focus_row, focus_col, focus_ax, focus_rad, peak_val] = ...
        detect_postskull_focus(p_max_sk, post_skull_mask, axial_disp_mm, radial_disp_mm);

    axial_profile = p_max_sk(:, focus_col);
    radial_profile = p_max_sk(focus_row, :);

    axial_valid  = (~skull_mask(:, focus_col)) & post_skull_mask(:, focus_col);
    radial_valid = (~skull_mask(focus_row, :).') & post_skull_mask(focus_row, :).';

    [ax_fwhm, axL, axR] = local_fwhm_masked(axial_disp_mm, axial_profile, axial_valid);
    [rd_fwhm, rdL, rdR] = local_fwhm_masked(radial_disp_mm, radial_profile, radial_valid);

    curv_results(ii).curvature = curvature_strength;
    curv_results(ii).p_max = p_max_sk;
    curv_results(ii).skull_mask = skull_mask;
    curv_results(ii).focus_row = focus_row;
    curv_results(ii).focus_col = focus_col;
    curv_results(ii).focus_ax = focus_ax;
    curv_results(ii).focus_rad = focus_rad;
    curv_results(ii).peak = peak_val;

    curv_results(ii).axial_profile = axial_profile;
    curv_results(ii).radial_profile = radial_profile;
    curv_results(ii).axial_valid = axial_valid;
    curv_results(ii).radial_valid = radial_valid;

    curv_results(ii).axial_fwhm = ax_fwhm;
    curv_results(ii).radial_fwhm = rd_fwhm;
    curv_results(ii).axL = axL; curv_results(ii).axR = axR;
    curv_results(ii).rdL = rdL; curv_results(ii).rdR = rdR;
end

% =========================================================
% DENSITY SWEEP
% =========================================================
for ii = 1:numel(density_vals)
    skull_density = density_vals(ii);

    [medium_skull, skull_mask, post_skull_mask] = make_skull_medium( ...
        medium_ff, Xmm, radial_disp_mm, axial_disp_mm, src_row, ...
        skull_thickness_mm, 0.012, ...
        base_skull_c, skull_density, base_skull_alpha);

    fprintf('Running density sweep case %d/%d ...\n', ii, numel(density_vals));
    sensor_data_sk = kspaceFirstOrder2D(kgrid, medium_skull, source, sensor, input_args{:});
    p_max_sk = reshape(sensor_data_sk.p_max, Nx, Ny);

    [focus_row, focus_col, focus_ax, focus_rad, peak_val] = ...
        detect_postskull_focus(p_max_sk, post_skull_mask, axial_disp_mm, radial_disp_mm);

    axial_profile = p_max_sk(:, focus_col);
    radial_profile = p_max_sk(focus_row, :);

    axial_valid  = (~skull_mask(:, focus_col)) & post_skull_mask(:, focus_col);
    radial_valid = (~skull_mask(focus_row, :).') & post_skull_mask(focus_row, :).';

    [ax_fwhm, axL, axR] = local_fwhm_masked(axial_disp_mm, axial_profile, axial_valid);
    [rd_fwhm, rdL, rdR] = local_fwhm_masked(radial_disp_mm, radial_profile, radial_valid);

    dens_results(ii).density = skull_density;
    dens_results(ii).p_max = p_max_sk;
    dens_results(ii).skull_mask = skull_mask;
    dens_results(ii).focus_row = focus_row;
    dens_results(ii).focus_col = focus_col;
    dens_results(ii).focus_ax = focus_ax;
    dens_results(ii).focus_rad = focus_rad;
    dens_results(ii).peak = peak_val;

    dens_results(ii).axial_profile = axial_profile;
    dens_results(ii).radial_profile = radial_profile;
    dens_results(ii).axial_valid = axial_valid;
    dens_results(ii).radial_valid = radial_valid;

    dens_results(ii).axial_fwhm = ax_fwhm;
    dens_results(ii).radial_fwhm = rd_fwhm;
    dens_results(ii).axL = axL; dens_results(ii).axR = axR;
    dens_results(ii).rdL = rdL; dens_results(ii).rdR = rdR;
end

% =========================================================
% THICKNESS SWEEP
% =========================================================
for ii = 1:numel(thickness_vals)
    skull_thickness_this = thickness_vals(ii);

    [medium_skull, skull_mask, post_skull_mask] = make_skull_medium( ...
        medium_ff, Xmm, radial_disp_mm, axial_disp_mm, src_row, ...
        skull_thickness_this, 0.012, ...
        base_skull_c, base_skull_density, base_skull_alpha);

    fprintf('Running thickness sweep case %d/%d ...\n', ii, numel(thickness_vals));
    sensor_data_sk = kspaceFirstOrder2D(kgrid, medium_skull, source, sensor, input_args{:});
    p_max_sk = reshape(sensor_data_sk.p_max, Nx, Ny);

    [focus_row, focus_col, focus_ax, focus_rad, peak_val] = ...
        detect_postskull_focus(p_max_sk, post_skull_mask, axial_disp_mm, radial_disp_mm);

    axial_profile  = p_max_sk(:, focus_col);
    radial_profile = p_max_sk(focus_row, :);

    axial_valid  = (~skull_mask(:, focus_col)) & post_skull_mask(:, focus_col);
    radial_valid = (~skull_mask(focus_row, :).') & post_skull_mask(focus_row, :).';

    [ax_fwhm, axL, axR] = local_fwhm_masked(axial_disp_mm, axial_profile, axial_valid);
    [rd_fwhm, rdL, rdR] = local_fwhm_masked(radial_disp_mm, radial_profile, radial_valid);

    thick_results(ii).thickness = skull_thickness_this;
    thick_results(ii).p_max = p_max_sk;
    thick_results(ii).skull_mask = skull_mask;
    thick_results(ii).focus_row = focus_row;
    thick_results(ii).focus_col = focus_col;
    thick_results(ii).focus_ax = focus_ax;
    thick_results(ii).focus_rad = focus_rad;
    thick_results(ii).peak = peak_val;

    thick_results(ii).axial_profile = axial_profile;
    thick_results(ii).radial_profile = radial_profile;
    thick_results(ii).axial_valid = axial_valid;
    thick_results(ii).radial_valid = radial_valid;

    thick_results(ii).axial_fwhm = ax_fwhm;
    thick_results(ii).radial_fwhm = rd_fwhm;
    thick_results(ii).axL = axL; thick_results(ii).axR = axR;
    thick_results(ii).rdL = rdL; thick_results(ii).rdR = rdR;
end

%%
% =========================================================
% COLOR LIMITS
% =========================================================
clim_fixed = [0, 1e6];   % 0 to 1 MPa

% =========================================================
% FIGURE 1: CURVATURE SWEEP (3x4)
% =========================================================
figure('Color','w','Name','Curvature Sweep','Position',[50 50 1500 900]);

ax_curv_field = gobjects(1, numel(curvature_vals));

for ii = 1:numel(curvature_vals)

    % ---------------- Row 1: Acoustic field ----------------
    ax_curv_field(ii) = subplot(3, numel(curvature_vals), ii);

    imagesc(radial_disp_mm, axial_disp_mm, curv_results(ii).p_max);
    axis image;
    set(gca, 'YDir', 'normal');
    colormap(gca, turbo);
    caxis(clim_fixed);
    hold on;

    h = imagesc(radial_disp_mm, axial_disp_mm, double(curv_results(ii).skull_mask));
    set(h, 'AlphaData', 0.14 * double(curv_results(ii).skull_mask));

    contour(radial_disp_mm, axial_disp_mm, curv_results(ii).skull_mask, [1 1], ...
        'w', 'LineWidth', 1.2);
    plot(curv_results(ii).focus_rad, curv_results(ii).focus_ax, ...
        'wo', 'MarkerSize', 7, 'LineWidth', 1.5);

    caxis(clim_fixed);

    title(sprintf('c = %.3f', curv_results(ii).curvature));
    xlim([-30 30]);
    ylim([0 100]);
    xlabel('Radial (mm)');
    if ii == 1
        ylabel('Axial depth (mm)');
    end
    hold off;

    % ---------------- Row 2: Axial FWHM ----------------
    subplot(3, numel(curvature_vals), numel(curvature_vals) + ii);
    prof = curv_results(ii).axial_profile / 1e6; % MPa
    valid = curv_results(ii).axial_valid;
    prof_plot = prof;
    prof_plot(~valid) = NaN;

    plot(axial_disp_mm, prof_plot, 'b-', 'LineWidth', 1.5); hold on;
    yline(max(prof_plot, [], 'omitnan')/2, 'k--', 'LineWidth', 1);
    if ~isnan(curv_results(ii).axL), xline(curv_results(ii).axL, 'r--', 'LineWidth', 1); end
    if ~isnan(curv_results(ii).axR), xline(curv_results(ii).axR, 'r--', 'LineWidth', 1); end

    if ~isnan(curv_results(ii).axial_fwhm)
        title(sprintf('Axial FWHM = %.2f mm', abs(curv_results(ii).axial_fwhm)));
    else
        title('Axial FWHM = NaN');
    end

    xlabel('Axial depth (mm)');
    if ii == 1
        ylabel('Pressure (MPa)');
    end
    xlim([0 100]);
    ylim([0 clim_fixed(2)/1e6]);
    grid on;
    hold off;

    % ---------------- Row 3: Radial FWHM ----------------
    subplot(3, numel(curvature_vals), 2*numel(curvature_vals) + ii);
    prof = curv_results(ii).radial_profile / 1e6; % MPa
    valid = curv_results(ii).radial_valid;
    prof_plot = prof;
    prof_plot(~valid) = NaN;

    plot(radial_disp_mm, prof_plot, 'b-', 'LineWidth', 1.5); hold on;
    yline(max(prof_plot, [], 'omitnan')/2, 'k--', 'LineWidth', 1);
    if ~isnan(curv_results(ii).rdL), xline(curv_results(ii).rdL, 'r--', 'LineWidth', 1); end
    if ~isnan(curv_results(ii).rdR), xline(curv_results(ii).rdR, 'r--', 'LineWidth', 1); end

    if ~isnan(curv_results(ii).radial_fwhm)
        title(sprintf('Radial FWHM = %.2f mm', curv_results(ii).radial_fwhm));
    else
        title('Radial FWHM = NaN');
    end

    xlabel('Radial (mm)');
    if ii == 1
        ylabel('Pressure (MPa)');
    end
    xlim([-30 30]);
    ylim([0 clim_fixed(2)/1e6]);
    grid on;
    hold off;
end

cb1 = colorbar(ax_curv_field(end), 'Position',[0.92 0.69 0.012 0.22]);
ylabel(cb1,'Peak pressure (Pa)');

% =========================================================
% FIGURE 2: DENSITY SWEEP (3x4)
% =========================================================
figure('Color','w','Name','Density Sweep','Position',[80 80 1500 900]);

ax_dens_field = gobjects(1, numel(density_vals));

for ii = 1:numel(density_vals)

    % ---------------- Row 1: Acoustic field ----------------
    ax_dens_field(ii) = subplot(3, numel(density_vals), ii);

    imagesc(radial_disp_mm, axial_disp_mm, dens_results(ii).p_max);
    axis image;
    set(gca, 'YDir', 'normal');
    colormap(gca, jet);
    caxis(clim_fixed);
    hold on;

    h = imagesc(radial_disp_mm, axial_disp_mm, double(dens_results(ii).skull_mask));
    set(h, 'AlphaData', 0.14 * double(dens_results(ii).skull_mask));

    contour(radial_disp_mm, axial_disp_mm, dens_results(ii).skull_mask, [1 1], ...
        'w', 'LineWidth', 1.2);
    plot(dens_results(ii).focus_rad, dens_results(ii).focus_ax, ...
        'wo', 'MarkerSize', 7, 'LineWidth', 1.5);

    caxis(clim_fixed);

    title(sprintf('\\rho = %d', dens_results(ii).density));
    xlim([-30 30]);
    ylim([0 100]);
    xlabel('Radial (mm)');
    if ii == 1
        ylabel('Axial depth (mm)');
    end
    hold off;

    % ---------------- Row 2: Axial FWHM ----------------
    subplot(3, numel(density_vals), numel(density_vals) + ii);
    prof = dens_results(ii).axial_profile / 1e6; % MPa
    valid = dens_results(ii).axial_valid;
    prof_plot = prof;
    prof_plot(~valid) = NaN;

    plot(axial_disp_mm, prof_plot, 'b-', 'LineWidth', 1.5); hold on;
    yline(max(prof_plot, [], 'omitnan')/2, 'k--', 'LineWidth', 1);
    if ~isnan(dens_results(ii).axL), xline(dens_results(ii).axL, 'r--', 'LineWidth', 1); end
    if ~isnan(dens_results(ii).axR), xline(dens_results(ii).axR, 'r--', 'LineWidth', 1); end

    if ~isnan(dens_results(ii).axial_fwhm)
        title(sprintf('Axial FWHM = %.2f mm', abs(dens_results(ii).axial_fwhm)));
    else
        title('Axial FWHM = NaN');
    end

    xlabel('Axial depth (mm)');
    if ii == 1
        ylabel('Pressure (MPa)');
    end
    xlim([0 100]);
    ylim([0 clim_fixed(2)/1e6]);
    grid on;
    hold off;

    % ---------------- Row 3: Radial FWHM ----------------
    subplot(3, numel(density_vals), 2*numel(density_vals) + ii);
    prof = dens_results(ii).radial_profile / 1e6; % MPa
    valid = dens_results(ii).radial_valid;
    prof_plot = prof;
    prof_plot(~valid) = NaN;

    plot(radial_disp_mm, prof_plot, 'b-', 'LineWidth', 1.5); hold on;
    yline(max(prof_plot, [], 'omitnan')/2, 'k--', 'LineWidth', 1);
    if ~isnan(dens_results(ii).rdL), xline(dens_results(ii).rdL, 'r--', 'LineWidth', 1); end
    if ~isnan(dens_results(ii).rdR), xline(dens_results(ii).rdR, 'LineStyle', '--', 'Color', 'r', 'LineWidth', 1); end

    if ~isnan(dens_results(ii).radial_fwhm)
        title(sprintf('Radial FWHM = %.2f mm', dens_results(ii).radial_fwhm));
    else
        title('Radial FWHM = NaN');
    end

    xlabel('Radial (mm)');
    if ii == 1
        ylabel('Pressure (MPa)');
    end
    xlim([-30 30]);
    ylim([0 clim_fixed(2)/1e6]);
    grid on;
    hold off;
end

cb2 = colorbar(ax_dens_field(end), 'Position',[0.92 0.69 0.012 0.22]);
ylabel(cb2,'Peak pressure (Pa)');

% =========================================================
% FIGURE 3: THICKNESS SWEEP (3x4)
% =========================================================
figure('Color','w','Name','Skull Thickness Sweep','Position',[110 110 1500 900]);

ax_thick_field = gobjects(1, numel(thickness_vals));

for ii = 1:numel(thickness_vals)

    % ---------------- Row 1: Acoustic field ----------------
    ax_thick_field(ii) = subplot(3, numel(thickness_vals), ii);

    imagesc(radial_disp_mm, axial_disp_mm, thick_results(ii).p_max);
    axis image;
    set(gca, 'YDir', 'normal');
    colormap(gca, jet);
    caxis(clim_fixed);
    hold on;

    h = imagesc(radial_disp_mm, axial_disp_mm, double(thick_results(ii).skull_mask));
    set(h, 'AlphaData', 0.14 * double(thick_results(ii).skull_mask));

    contour(radial_disp_mm, axial_disp_mm, thick_results(ii).skull_mask, [1 1], ...
        'w', 'LineWidth', 1.2);
    plot(thick_results(ii).focus_rad, thick_results(ii).focus_ax, ...
        'wo', 'MarkerSize', 7, 'LineWidth', 1.5);

    caxis(clim_fixed);

    title(sprintf('Thickness = %d mm', thick_results(ii).thickness));
    xlim([-30 30]);
    ylim([0 100]);
    xlabel('Radial (mm)');
    if ii == 1
        ylabel('Axial depth (mm)');
    end
    hold off;

    % ---------------- Row 2: Axial FWHM ----------------
    subplot(3, numel(thickness_vals), numel(thickness_vals) + ii);
    prof = thick_results(ii).axial_profile / 1e6; % MPa
    valid = thick_results(ii).axial_valid;
    prof_plot = prof;
    prof_plot(~valid) = NaN;

    plot(axial_disp_mm, prof_plot, 'b-', 'LineWidth', 1.5); hold on;
    yline(max(prof_plot, [], 'omitnan')/2, 'k--', 'LineWidth', 1);
    if ~isnan(thick_results(ii).axL), xline(thick_results(ii).axL, 'r--', 'LineWidth', 1); end
    if ~isnan(thick_results(ii).axR), xline(thick_results(ii).axR, 'r--', 'LineWidth', 1); end

    if ~isnan(thick_results(ii).axial_fwhm)
        title(sprintf('Axial FWHM = %.2f mm', abs(thick_results(ii).axial_fwhm)));
    else
        title('Axial FWHM = NaN');
    end

    xlabel('Axial depth (mm)');
    if ii == 1
        ylabel('Pressure (MPa)');
    end
    xlim([0 100]);
    ylim([0 clim_fixed(2)/1e6]);
    grid on;
    hold off;

    % ---------------- Row 3: Radial FWHM ----------------
    subplot(3, numel(thickness_vals), 2*numel(thickness_vals) + ii);
    prof = thick_results(ii).radial_profile / 1e6; % MPa
    valid = thick_results(ii).radial_valid;
    prof_plot = prof;
    prof_plot(~valid) = NaN;

    plot(radial_disp_mm, prof_plot, 'b-', 'LineWidth', 1.5); hold on;
    yline(max(prof_plot, [], 'omitnan')/2, 'k--', 'LineWidth', 1);
    if ~isnan(thick_results(ii).rdL), xline(thick_results(ii).rdL, 'r--', 'LineWidth', 1); end
    if ~isnan(thick_results(ii).rdR), xline(thick_results(ii).rdR, 'LineStyle', '--', 'Color', 'r', 'LineWidth', 1); end

    if ~isnan(thick_results(ii).radial_fwhm)
        title(sprintf('Radial FWHM = %.2f mm', thick_results(ii).radial_fwhm));
    else
        title('Radial FWHM = NaN');
    end

    xlabel('Radial (mm)');
    if ii == 1
        ylabel('Pressure (MPa)');
    end
    xlim([-30 30]);
    ylim([0 clim_fixed(2)/1e6]);
    grid on;
    hold off;
end

cb3 = colorbar(ax_thick_field(end), 'Position',[0.92 0.69 0.012 0.22]);
ylabel(cb3,'Peak pressure (Pa)');

%%
% =========================================================
% SUMMARY TABLES
% =========================================================
fprintf('\n=== Curvature Sweep Summary ===\n');
for ii = 1:numel(curvature_vals)
    fprintf('c = %.3f | Focus = (Ax %.2f, Rd %.2f) mm | FWHM Ax %.2f | Rd %.2f | Peak %.4g\n', ...
        curv_results(ii).curvature, curv_results(ii).focus_ax, curv_results(ii).focus_rad, ...
        curv_results(ii).axial_fwhm, curv_results(ii).radial_fwhm, curv_results(ii).peak);
end

fprintf('\n=== Density Sweep Summary ===\n');
for ii = 1:numel(density_vals)
    fprintf('rho = %d | Focus = (Ax %.2f, Rd %.2f) mm | FWHM Ax %.2f | Rd %.2f | Peak %.4g\n', ...
        dens_results(ii).density, dens_results(ii).focus_ax, dens_results(ii).focus_rad, ...
        dens_results(ii).axial_fwhm, dens_results(ii).radial_fwhm, dens_results(ii).peak);
end

fprintf('\n=== Thickness Sweep Summary ===\n');
for ii = 1:numel(thickness_vals)
    fprintf('thickness = %d mm | Focus = (Ax %.2f, Rd %.2f) mm | FWHM Ax %.2f | Rd %.2f | Peak %.4g\n', ...
        thick_results(ii).thickness, thick_results(ii).focus_ax, thick_results(ii).focus_rad, ...
        thick_results(ii).axial_fwhm, thick_results(ii).radial_fwhm, thick_results(ii).peak);
end

%%
% =========================================================
% EXTRACT SUMMARY METRICS FOR PARAMETRIC PLOTS
% =========================================================
curv_peak_pa   = zeros(1, numel(curvature_vals));
curv_peak_mpa  = zeros(1, numel(curvature_vals));
curv_ax_fwhm   = zeros(1, numel(curvature_vals));
curv_rad_fwhm  = zeros(1, numel(curvature_vals));

for ii = 1:numel(curvature_vals)
    curv_peak_pa(ii)  = curv_results(ii).peak;
    curv_peak_mpa(ii) = curv_results(ii).peak / 1e6;
    curv_ax_fwhm(ii)  = -curv_results(ii).axial_fwhm;
    curv_rad_fwhm(ii) = curv_results(ii).radial_fwhm;
end

dens_peak_pa   = zeros(1, numel(density_vals));
dens_peak_mpa  = zeros(1, numel(density_vals));
dens_ax_fwhm   = zeros(1, numel(density_vals));
dens_rad_fwhm  = zeros(1, numel(density_vals));

for ii = 1:numel(density_vals)
    dens_peak_pa(ii)  = dens_results(ii).peak;
    dens_peak_mpa(ii) = dens_results(ii).peak / 1e6;
    dens_ax_fwhm(ii)  = -dens_results(ii).axial_fwhm;
    dens_rad_fwhm(ii) = dens_results(ii).radial_fwhm;
end

thick_peak_pa   = zeros(1, numel(thickness_vals));
thick_peak_mpa  = zeros(1, numel(thickness_vals));
thick_ax_fwhm   = zeros(1, numel(thickness_vals));
thick_rad_fwhm  = zeros(1, numel(thickness_vals));

for ii = 1:numel(thickness_vals)
    thick_peak_pa(ii)  = thick_results(ii).peak;
    thick_peak_mpa(ii) = thick_results(ii).peak / 1e6;
    thick_ax_fwhm(ii)  = -thick_results(ii).axial_fwhm;
    thick_rad_fwhm(ii) = thick_results(ii).radial_fwhm;
end

% Optional: display extracted values in command window
fprintf('\n=== Extracted Curvature Metrics ===\n');
fprintf('Curvature\tPeak(MPa)\tAxFWHM(mm)\tRadFWHM(mm)\n');
for ii = 1:numel(curvature_vals)
    fprintf('%.4f\t\t%.4f\t\t%.4f\t\t%.4f\n', ...
        curvature_vals(ii), curv_peak_mpa(ii), curv_ax_fwhm(ii), curv_rad_fwhm(ii));
end

fprintf('\n=== Extracted Density Metrics ===\n');
fprintf('Density\t\tPeak(MPa)\tAxFWHM(mm)\tRadFWHM(mm)\n');
for ii = 1:numel(density_vals)
    fprintf('%d\t\t%.4f\t\t%.4f\t\t%.4f\n', ...
        density_vals(ii), dens_peak_mpa(ii), dens_ax_fwhm(ii), dens_rad_fwhm(ii));
end

fprintf('\n=== Extracted Thickness Metrics ===\n');
fprintf('Thickness\tPeak(MPa)\tAxFWHM(mm)\tRadFWHM(mm)\n');
for ii = 1:numel(thickness_vals)
    fprintf('%d\t\t%.4f\t\t%.4f\t\t%.4f\n', ...
        thickness_vals(ii), thick_peak_mpa(ii), thick_ax_fwhm(ii), thick_rad_fwhm(ii));
end

figure('Color','w','Name','Metrics vs Curvature, Density, and Thickness', ...
    'Position',[120 120 1400 950]);

% =========================================================
% ROW 1: PEAK PRESSURE
% =========================================================
subplot(3,3,1);
plot(curvature_vals*1e3, curv_peak_mpa, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('1/Radius ofCurvature  (1/mm)');
ylabel('Peak pressure (MPa)');
title('Peak Pressure vs Curvature');
grid on;

subplot(3,3,2);
plot(density_vals, dens_peak_mpa, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('Density (kg/m^3)');
ylabel('Peak pressure (MPa)');
title('Peak Pressure vs Density');
grid on;

subplot(3,3,3);
plot(thickness_vals, thick_peak_mpa, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('Skull thickness (mm)');
ylabel('Peak pressure (MPa)');
title('Peak Pressure vs Thickness');
grid on;

% =========================================================
% ROW 2: AXIAL FWHM
% =========================================================
subplot(3,3,4);
plot(curvature_vals*1e3, curv_ax_fwhm, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('1/Radius of Curvature (1/mm)');
ylabel('Axial FWHM (mm)');
title('Axial FWHM vs Curvature');
grid on;

subplot(3,3,5);
plot(density_vals, dens_ax_fwhm, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('Density (kg/m^3)');
ylabel('Axial FWHM (mm)');
title('Axial FWHM vs Density');
grid on;

subplot(3,3,6);
plot(thickness_vals, thick_ax_fwhm, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('Skull thickness (mm)');
ylabel('Axial FWHM (mm)');
title('Axial FWHM vs Thickness');
grid on;

% =========================================================
% ROW 3: RADIAL FWHM
% =========================================================
subplot(3,3,7);
plot(curvature_vals, curv_rad_fwhm, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('Curvature strength');
ylabel('Radial FWHM (mm)');
title('Radial FWHM vs Curvature');
grid on;

subplot(3,3,8);
plot(density_vals, dens_rad_fwhm, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('Density (kg/m^3)');
ylabel('Radial FWHM (mm)');
title('Radial FWHM vs Density');
grid on;

subplot(3,3,9);
plot(thickness_vals, thick_rad_fwhm, '-o', 'LineWidth', 1.8, 'MarkerSize', 7);
xlabel('Skull thickness (mm)');
ylabel('Radial FWHM (mm)');
title('Radial FWHM vs Thickness');
grid on;

% =========================================================
% LOCAL FUNCTIONS
% =========================================================
function [medium_skull, skull_mask, post_skull_mask] = make_skull_medium( ...
    medium_ff, Xmm, radial_disp_mm, axial_disp_mm, src_row, ...
    skull_thickness_mm, curvature_strength, skull_c, skull_density, skull_alpha)

    x_internal_max = max(Xmm(:));
    src_depth_disp = axial_disp_mm(src_row);

    skull_center_lat_mm = 0;
    skull_bottom_disp_mm = (src_depth_disp + 1.0) + ...
        curvature_strength * (radial_disp_mm - skull_center_lat_mm).^2;
    skull_top_disp_mm = skull_bottom_disp_mm + skull_thickness_mm;

    skull_bottom_internal_mm = x_internal_max - skull_bottom_disp_mm;
    skull_top_internal_mm    = x_internal_max - skull_top_disp_mm;

    [Nx_local, ~] = size(Xmm);
    skull_bottom_2d = repmat(skull_bottom_internal_mm, Nx_local, 1);
    skull_top_2d    = repmat(skull_top_internal_mm, Nx_local, 1);

    skull_mask = (Xmm >= skull_top_2d) & (Xmm <= skull_bottom_2d);

    medium_skull = medium_ff;
    medium_skull.sound_speed(skull_mask) = skull_c;
    medium_skull.density(skull_mask)     = skull_density;
    medium_skull.alpha_coeff(skull_mask) = skull_alpha;

    % post-skull valid region
    post_skull_mask = false(size(skull_mask));
    for j = 1:size(skull_mask,2)
        skull_rows = find(skull_mask(:,j));
        if isempty(skull_rows)
            post_skull_mask(:,j) = true;
        else
            skull_axial_vals = axial_disp_mm(skull_rows);
            top_of_skull_axial = max(skull_axial_vals);
            post_skull_mask(:,j) = axial_disp_mm(:) > top_of_skull_axial;
        end
    end
end

function [focus_row, focus_col, focus_ax, focus_rad, peak_val] = ...
    detect_postskull_focus(p_max, post_skull_mask, axial_disp_mm, radial_disp_mm)

    p_search = p_max;
    p_search(~post_skull_mask) = -Inf;

    [peak_val, idx] = max(p_search(:));
    [focus_row, focus_col] = ind2sub(size(p_search), idx);

    focus_ax  = axial_disp_mm(focus_row);
    focus_rad = radial_disp_mm(focus_col);
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