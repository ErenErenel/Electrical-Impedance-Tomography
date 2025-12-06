%% ---------------- 3D Cylinder + Lungs + High-Conductivity Corner ----------------

clear; clc; close all;

%% 1. Build cylinder + electrodes
height = 3; radius = 1; max_elem = 0.072; 
shape_corner = [height, radius, max_elem];          
el_sz_corner = [0.1, 0, 0.05];  

anglesa_corner = (45:90:315)'; za_corner = 2.75*ones(size(anglesa_corner));
anglesb_corner = (45:90:315)'; zb_corner = 1.0*ones(size(anglesb_corner));
anglesc_corner = (45:90:315)'; zc_corner = 0.2*ones(size(anglesc_corner));
anglesd_corner = (45:90:315)'; zd_corner = 1.5*ones(size(anglesd_corner));

el_pos_corner = [anglesa_corner za_corner; anglesb_corner zb_corner;anglesc_corner zc_corner; anglesd_corner zd_corner];
fmdl_corner = ng_mk_cyl_models(shape_corner, el_pos_corner, el_sz_corner);

figure; show_fem(fmdl_corner); view(3); axis equal tight;
title('Forward FEM model (Lungs + High-Conductivity Corner)');

%% 2. Create inverse model
imdl_corner = mk_common_model('a2c2',16);
imdl_corner.fwd_model = fmdl_corner;

nelec_corner = length(fmdl_corner.electrode);

% ==== (NEW) Generate every valid stimulation/measurement pattern ====
elecs = 1:nelec_corner;
patterns = zeros(16*15*14*13, 4);
idx = 1;

for s1 = elecs
    for s2 = elecs(elecs ~= s1)
        rem1 = elecs(~ismember(elecs, [s1 s2]));
        for m1 = rem1
            rem2 = rem1(rem1 ~= m1);
            for m2 = rem2
                patterns(idx,:) = [s1 s2 m1 m2];
                idx = idx + 1;
            end
        end
    end
end

% Convert to EIDORS stim struct
stim_corner = stim_meas_list(patterns);

% Assign to forward model
imdl_corner.fwd_model.stimulation = stim_corner;


%% 3. Define lungs
img_bg_corner = mk_image(imdl_corner, 1.0);  
ctr_corner = interp_mesh(fmdl_corner);     

hy_corner = (0.54*.9); hx_corner = 0.36; hz_corner = 1.0825;  
sep_corner = 0.1;

ctr_left_corner  = [-0.5*sep_corner - hx_corner, 0, 1.5];
ctr_right_corner = [0.5*sep_corner + hx_corner, 0, 1.5];

left_cuboid_corner  = abs(ctr_corner(:,1)-ctr_left_corner(1)) <= hx_corner & ...
                      abs(ctr_corner(:,2)-ctr_left_corner(2)) <= hy_corner & ...
                      abs(ctr_corner(:,3)-ctr_left_corner(3)) <= hz_corner;
right_cuboid_corner = abs(ctr_corner(:,1)-ctr_right_corner(1)) <= hx_corner & ...
                      abs(ctr_corner(:,2)-ctr_right_corner(2)) <= hy_corner & ...
                      abs(ctr_corner(:,3)-ctr_right_corner(3)) <= hz_corner;

mask_lungs_corner = left_cuboid_corner | right_cuboid_corner;
lung_conductivity_corner = 0.0001;

%% 4. High-conductivity corner
corner_hx_corner = 0.15; corner_hy_corner = 0.15; corner_hz_corner = 0.25;
corner_ctr_corner = ctr_right_corner + [hx_corner, hy_corner, hz_corner];  

corner_mask_corner = ...
    (ctr_corner(:,1) >= (corner_ctr_corner(1)-corner_hx_corner) & ctr_corner(:,1) <= corner_ctr_corner(1)) & ...
    (ctr_corner(:,2) >= (corner_ctr_corner(2)-corner_hy_corner) & ctr_corner(:,2) <= corner_ctr_corner(2)) & ...
    (ctr_corner(:,3) >= (corner_ctr_corner(3)-corner_hz_corner) & ctr_corner(:,3) <= corner_ctr_corner(3));

corner_cond_corner = 1;

%% 5. Build final image
img_corner = mk_image(img_bg_corner, 1.0);
img_corner.elem_data(mask_lungs_corner) = lung_conductivity_corner;
img_corner.elem_data(corner_mask_corner) = corner_cond_corner;
img_corner.fwd_model.stimulation = stim_corner;

%% 6. Visualize conductivity
figure;
show_fem(img_corner,1); 
hold on;
plot3(corner_ctr_corner(1), corner_ctr_corner(2), corner_ctr_corner(3), 'ro','MarkerSize',10,'LineWidth',2);
view(3); axis equal tight;
k = title('Cylinder with two lungs + high-conductivity corner');
k.FontSize = 16
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
colorbar;

%% 7. Forward solve for voltages
vh_corner = fwd_solve(img_bg_corner); 
vi_corner = fwd_solve(img_corner); 

figure;
plot([vh_corner.meas, vi_corner.meas]);
legend('Background','With lungs + granuloma','Location','best');
xlabel('Measurement index'); ylabel('Voltage (V)');
o = title('Simulated voltages (Lungs + Removal (Granuloma)');
o.FontSize = 16


%% 8. Create electrode table using meas_sel logical mask
stim = stim_corner(1);  % single stimulation pattern
curr_elec_idx = find(stim.stim_pattern);  % current injection electrodes
num_meas = sum(meas_sel);                 % number of measurements actually selected

elec_table = cell(num_meas,5);
meas_idx = find(meas_sel);  % indices of selected measurements

for k = 1:num_meas
    idx = meas_idx(k);                      % actual measurement index
    volt_elec_idx = find(stim.meas_pattern(:,idx))';  % voltage electrodes
    
    elec_table{k,1} = k;
    elec_table{k,2} = curr_elec_idx;
    elec_table{k,3} = volt_elec_idx;
    
    % Electrode positions
    elec_table{k,4} = {cell2mat(arrayfun(@(i) fmdl_corner.electrode(i).pos, curr_elec_idx, 'UniformOutput', false))};
    elec_table{k,5} = {cell2mat(arrayfun(@(i) fmdl_corner.electrode(i).pos, volt_elec_idx, 'UniformOutput', false))};
end

elec_table = cell2table(elec_table, ...
    'VariableNames', {'Meas_Index','Current_Elecs','Voltage_Elecs','Current_Pos','Voltage_Pos'});

disp(elec_table(1:10,:));


%% 9. Inverse reconstruction using Jacobian + NOSER prior
J_corner = calc_jacobian(calc_jacobian_bkgnd(imdl_corner));
iRtR_corner = inv(prior_noser(imdl_corner));
hp_corner = 0.17;                       
iRN_corner = hp_corner^2 * speye(size(J_corner,1));
RM_corner = iRtR_corner*J_corner'/(J_corner*iRtR_corner*J_corner' + iRN_corner);

imdl_corner.solve = @solve_use_matrix;
imdl_corner.solve_use_matrix.RM = RM_corner;

imgr_corner = inv_solve(imdl_corner, vh_corner, vi_corner);
imgr_corner.calc_colours.ref_level = 0;
imgr_corner.calc_colours.greylev = -0.05;

%% 10. Visualize reconstruction
figure;
show_fem(imgr_corner); view(3); axis equal tight;
title('3D Reconstructed Conductivity (Lungs + High-Conductivity Corner)');
colorbar;