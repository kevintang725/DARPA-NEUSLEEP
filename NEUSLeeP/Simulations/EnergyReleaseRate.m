% Energy Release Rate vs Peel Angle for Multiple Substrate Pairs
% Includes Polyamide, TransferRite Ultra 582U, Aquasol, and Aquasol-to-TransferRite

clear; clc; close all;

% Define peel angles (degrees)
angles_deg = [0:5:180];
angles_rad = deg2rad(angles_deg);

% Estimated adhesion strengths (N/m)
adhesion_polyamide       = 220;  % 3M 1126 on polyamide (estimated)
adhesion_transferrite    = 137;  % 3M 1126 on TransferRite Ultra 582U (estimated)
adhesion_aquasol         = 100;  % 3M 1126 on Aquasol (estimated)
adhesion_aquasol_trtf    = 50;   % Aquasol on TransferRite Ultra 582U (estimated lower)

% Compute Energy Release Rate: G = adhesion * (1 - cos(theta))
G_polyamide        = adhesion_polyamide       .* (1 - cos(angles_rad));
G_transferrite     = adhesion_transferrite    .* (1 - cos(angles_rad));
G_aquasol         = adhesion_aquasol         .* (1 - cos(angles_rad));
G_aquasol_trtf    = adhesion_aquasol_trtf    .* (1 - cos(angles_rad));

% Plotting
figure;
plot(angles_deg, G_polyamide,    '-o', 'LineWidth', 1.5); hold on;
plot(angles_deg, G_transferrite, '-s', 'LineWidth', 1.5);
plot(angles_deg, G_aquasol,      '-^', 'LineWidth', 1.5);
plot(angles_deg, G_aquasol_trtf, '-d', 'LineWidth', 1.5); hold off;

xlabel('Peel Angle (degrees)');
ylabel('Energy Release Rate G (J/m^2)');
title('Estimated Energy Release Rate vs Peel Angle (Multiple Substrates)');
legend('Polyamide (3M 1126)', 'TransferRite (3M 1126)', 'Aquasol (3M 1126)', 'Aquasol on TransferRite', ...
    'Location', 'northwest');
grid on;

% Save figure
saveas(gcf, 'energy_release_rate_comparison_extended.png');

% Optional: export data to CSV
T = table(angles_deg', G_polyamide', G_transferrite', G_aquasol', G_aquasol_trtf', ...
    'VariableNames', {'Angle_deg', 'G_Polyamide', 'G_TransferRite', 'G_Aquasol', 'G_Aquasol_on_TransferRite'});
writetable(T, 'energy_release_rate_data_extended.csv');
