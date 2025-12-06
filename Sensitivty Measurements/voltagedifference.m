%% ----------------- Compare Voltages -----------------

% Compute voltage difference between Lungs + Corner and Lungs Only
delta_v_lungs_corner = vi_corner.meas - vi_lungs.meas;

%% -----------------------------------------------
% 1. Plot absolute voltages for each case
figure;
plot([vi_lungs.meas, vi_corner.meas], 'LineWidth', 1.5);
legend('Lungs Only', 'Lungs + Corner', 'Location','best');
xlabel('Measurement index'); ylabel('Voltage (V)');
title('Simulated Voltages: Lungs Only vs Lungs + High-Conductivity Corner');
grid on; axis tight;

% 2. Plot voltage difference
figure;
plot(delta_v_lungs_corner, 'r-o', 'LineWidth', 1.5);
xlabel('Measurement index'); ylabel('Voltage difference (V)');
title('Voltage Difference: Lungs + Corner minus Lungs Only');
grid on; axis tight;

% 3. Optional: compare with background voltages
figure;
plot([vh_lungs.meas, vi_lungs.meas, vi_corner.meas], 'LineWidth', 1.5);
legend('Background','Lungs Only','Lungs + Corner','Location','best');
xlabel('Measurement index'); ylabel('Voltage (V)');
title('Simulated Voltages: Background, Lungs Only, Lungs + Corner');
grid on; axis tight;

%% -----------------------------------------------
% Sort measurements by |ΔV| to find most sensitive ones
[sorted_vals, idx_sorted] = sort(abs(delta_v_lungs_corner), 'descend');

%% Select top-K granuloma-sensitive measurements
K = 200; % choose K
meas_keep = idx_sorted(1:K);

figure;
stem(meas_keep, delta_v_lungs_corner(meas_keep), 'r', 'LineWidth', 1.5);
xlabel('Measurement index (1 to 43,680)');
ylabel('\DeltaV (V)');
h = title(['Top ' num2str(K) ' Granuloma-Sensitive Measurements']);
h.FontSize = 16
grid on;

%% -----------------------------------------------
%  Extract: stimulation index, row-in-stim, electrode pair (+/-)

N_stim = length(stim_lungs);                 % 240
N_meas = length(delta_v_lungs_corner);       % 43680
meas_per_stim = N_meas / N_stim;             % 182

% For convenience, build mapping measurement->stim index
meas_to_stim = ceil((1:N_meas) / meas_per_stim);

%% Example: Extract values for the single MOST sensitive measurement
m = idx_sorted(1);    % measurement index of largest |ΔV|

stim_index = meas_to_stim(m);  
row_within_stim = m - (stim_index - 1) * meas_per_stim;

mp = stim_lungs(stim_index).meas_pattern(row_within_stim, :);

pos_el = find(mp > 0);   % positive electrode
neg_el = find(mp < 0);   % negative electrode

fprintf('Most sensitive measurement:\n');
fprintf('  Measurement index: %d of %d\n', m, N_meas);
fprintf('  Stimulation index: %d of %d\n', stim_index, N_stim);
fprintf('  Row within stimulation: %d of %d\n', row_within_stim, meas_per_stim);
fprintf('  Measured between electrodes  +%d  and  -%d\n', pos_el, neg_el);
fprintf('  ΔV = %.6g V\n', delta_v_lungs_corner(m));

