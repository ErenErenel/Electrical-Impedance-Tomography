%% ===================== EIT Human Thorax Full Pipeline =====================
% Purpose: Forward + Inverse EIT simulation on adult thorax with lungs
% Model: 'adult_male_16el_lungs' from EIDORS library
% Method: NOSER inverse solver (linearized difference imaging)
% ===========================================================================

clc; clear; close all;

%% 1. Load human thorax geometry (with lung regions)
fmdl = mk_library_model('adult_male_16el_lungs');
fprintf('Mesh built: %d elements, %d electrodes\n', ...
        size(fmdl.elems,1), numel(fmdl.electrode));

%figure;
%show_fem(fmdl);
%view(3); axis equal tight;
%title('Adult Male Thorax Geometry');
%xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');

%% 2. Define stimulation pattern (attach BEFORE making images)
nelec = length(fmdl.electrode);    % should be 16
stim  = mk_stim_patterns(nelec, 1, [0,3], [0,1], {}, 1);
fmdl.stimulation = stim;

%% 3. Define conductivities
bg_cond   = 0.25;   % background (tissue)
lung_cond = 0.25;   % lungs (low conductivity)

% Homogeneous and inhomogeneous images
img_h = mk_image(fmdl, bg_cond);
img_i = mk_image(fmdl, bg_cond);
img_i.elem_data([fmdl.mat_idx{2}; fmdl.mat_idx{3}]) = lung_cond;

figure;
show_fem(img_i);
view(3); axis equal tight;
b = title('Thorax with Low-Conductivity Lungs');
b.FontSize = 16;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)'); colorbar;

%% 4. Forward solve (simulate voltages)
vh = fwd_solve(img_h);   % homogeneous reference
vi = fwd_solve(img_i);   % inhomogeneous (with lungs)

%figure;
%plot([vh.meas, vi.meas]);
%legend('Homogeneous','With lungs','Location','best');
%xlabel('Measurement index'); ylabel('Voltage (V)');
%title('Simulated EIT Voltage Measurements');
%grid on; axis tight;

%% 5. Build inverse model (NOSER)
imdl = mk_common_model('a2c2', nelec); % base inverse model
imdl.fwd_model = fmdl;
imdl.fwd_model.stimulation = stim;

J = calc_jacobian(calc_jacobian_bkgnd(imdl));
iRtR = inv(prior_noser(imdl));   % NOSER prior
hp = 0.2;                         % regularization strength
iRN = hp^2 * speye(size(J,1));
RM  = iRtR * J' / (J * iRtR * J' + iRN);

imdl.solve = @solve_use_matrix;
imdl.solve_use_matrix.RM = RM;

%% 6. Solve inverse problem (difference image)
imgr = inv_solve(imdl, vh, vi);
imgr.calc_colours.ref_level = bg_cond;
imgr.calc_colours.greylev   = -0.05;

%% 7. Visualize reconstruction
figure;
show_fem(imgr);
view(3); axis equal tight;
t = title('Reconstructed Conductivity Distribution');
t.FontSize = 16;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)'); colorbar;


