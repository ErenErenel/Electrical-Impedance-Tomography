%% ----------------- 3D Cylinder + Cylindrical Lungs (No Granuloma) -----------------

%% 1. Build cylinder + evenly spaced electrodes
height = 3; radius = 1; max_elem = 0.072; 
shape_lungs = [height, radius, max_elem];          
el_sz_lungs = [0.1, 0, 0.05];  

angles = (45:90:315)';  % same for all 4 layers
za = 2.75*ones(size(angles));
zb = 1.0*ones(size(angles));
zc = 0.2*ones(size(angles));
zd = 1.5*ones(size(angles));

el_pos_lungs = [angles za; angles zb; angles zc; angles zd];

fmdl_lungs = ng_mk_cyl_models(shape_lungs, el_pos_lungs, el_sz_lungs);
fprintf('Mesh built: %d elements, %d electrodes\n', size(fmdl_lungs.elems,1), numel(fmdl_lungs.electrode));

figure;
show_fem(fmdl_lungs); view(3); axis equal tight;
title('Forward FEM model (Lungs Only)');
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');

%% 2. Create inverse model
imdl_lungs = mk_common_model('a2c2',16);
imdl_lungs.fwd_model = fmdl_lungs;
nelec_lungs = length(fmdl_lungs.electrode);

%% 3. Generate every valid 4-electrode stimulation/measurement pattern
elecs = 1:nelec_lungs;
N_patterns = 16*15*14*13;   % total permutations
patterns = zeros(N_patterns, 4);
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
stim_lungs = stim_meas_list(patterns);

% Assign to forward model
imdl_lungs.fwd_model.stimulation = stim_lungs;

%% 4. Define cuboid lungs
img_bg_lungs = mk_image(imdl_lungs, 1.0);  
ctr_lungs = interp_mesh(fmdl_lungs);     

hx_lungs = 0.36; hy_lungs = 0.486; hz_lungs = 1.0825;  
sep_lungs = 0.1;  

ctr_left  = [-0.5*sep_lungs - hx_lungs, 0, 1.5];
ctr_right = [0.5*sep_lungs + hx_lungs, 0, 1.5];

left_mask  = abs(ctr_lungs(:,1)-ctr_left(1)) <= hx_lungs & ...
             abs(ctr_lungs(:,2)-ctr_left(2)) <= hy_lungs & ...
             abs(ctr_lungs(:,3)-ctr_left(3)) <= hz_lungs;
right_mask = abs(ctr_lungs(:,1)-ctr_right(1)) <= hx_lungs & ...
             abs(ctr_lungs(:,2)-ctr_right(2)) <= hy_lungs & ...
             abs(ctr_lungs(:,3)-ctr_right(3)) <= hz_lungs;

mask_lungs_only = left_mask | right_mask;
lung_conductivity_only = 0.0001;  

%% 5. Build final conductivity image
img_lungs_only = mk_image(img_bg_lungs, 1.0);
img_lungs_only.elem_data(mask_lungs_only) = lung_conductivity_only;
img_lungs_only.fwd_model.stimulation = stim_lungs;

%% 6. Visualize conductivity distribution
figure;
show_fem(img_lungs_only,1);
view(3); axis equal tight;
f = title('Cylinder with two lungs (No Granuloma)');
f.FontSize = 16
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
colorbar;

%% 7. Forward solve for voltages (sequential)
vh_lungs = fwd_solve(img_bg_lungs);   
vi_lungs = fwd_solve(img_lungs_only);  

figure;
plot([vh_lungs.meas, vi_lungs.meas]);
legend('Background','Lungs Only','Location','best');
xlabel('Measurement index'); ylabel('Voltage (V)');
p=title('Simulated voltage data (Background vs. Lungs Only)');
p.FontSize = 16
grid on; axis tight;
