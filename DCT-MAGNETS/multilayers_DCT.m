% =========================================================================
% Universal DCT Generator (Multi-Layer & Single Pole)
% 
% Purpose:
%   Generates MULTIPLE LAYERS for ONE POLE of symmetry modeling in Opera.
%   (e.g., for Quadrupole m=2, generates 0-90 deg N-pole with multiple layers).
% 
% Usage in Opera:
%   1. Import all generated files.
%   2. Use "Reflection" (Mirror) or "Rotation" to generate the full magnet.
% =========================================================================

clear; clc; close all;

%% ===== 1. 用户参数配置 (User Config) =====

% --- 曲面形状选择 (1-10) ---
% 1=圆锥, 2=双曲线(1/z), 3=指数, 4=悬链面, 5=抛物面
% 6=正态钟形, 7=钟形+直管, 8=正弦波纹, 9=S形过渡, 10=1/4正弦
Surface_Type = 7; 

% --- 几何范围 [mm] ---
Z_start = -400;    
Z_end   = 400;    

% --- 线圈层数配置 ---
num_layers = 3;                      % 总层数
layer_config = struct();             % 每层配置
layer_config(1).R_entry = 50;        % 第1层入口半径
layer_config(1).R_exit_target = 150; % 第1层出口目标半径
layer_config(1).N_turns = 4;         % 第1层单极匝数
layer_config(1).radial_offset = 0;   % 径向偏移量(额外间隙)

layer_config(2).R_entry = 60;        % 第2层入口半径
layer_config(2).R_exit_target = 160; % 第2层出口目标半径
layer_config(2).N_turns = 3;         % 第2层单极匝数
layer_config(2).radial_offset = 2;   % 径向偏移量(额外间隙)

layer_config(3).R_entry = 70;        % 第3层入口半径
layer_config(3).R_exit_target = 170; % 第3层出口目标半径
layer_config(3).N_turns = 2;         % 第3层单极匝数
layer_config(3).radial_offset = 3;   % 径向偏移量(额外间隙)

% --- 极对数和对称性 ---
m = 3;            % 极对数 (m=2 -> 四极 -> 单极面为 90度)

% --- 形状函数参数 ---
ratio_entry = 0.15; % 入口端过渡区占比
ratio_exit  = 0.15; % 出口端过渡区占比

% --- 网格精度 ---
Nz = 80;          % 轴向网格点
Nphi = 40;        % 角向网格点(单个极面)

% --- 导出设置 ---
do_export = true; 
output_dir = 'dct_multi_layer_export'; 

%% ===== 2. 初始化与验证 =====
fprintf('=== 生成多层单极面模型 (Surface Type %d, %d Layers) ===\n', ...
        Surface_Type, num_layers);

% 验证层配置
if numel(layer_config) ~= num_layers
    error('层数配置错误: layer_config 元素数量必须等于 num_layers');
end

% 创建输出目录
if do_export && ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('创建输出目录: %s\n', output_dir);
end

% 颜色映射 (每层不同颜色)
colors = lines(num_layers);
color_names = {'Layer 1', 'Layer 2', 'Layer 3', 'Layer 4', 'Layer 5'};

%% ===== 3. 主处理循环 (每层独立处理) =====
figure('Color','w', 'Position', [50, 50, 1200, 800]);
hold on; axis equal; grid on; view(30, 20);
xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
title(sprintf('Multi-Layer Single Pole (m=%d): %d Layers', m, num_layers));
colormap(jet(num_layers));

for layer_idx = 1:num_layers
    fprintf('\n--- 处理 Layer %d ---\n', layer_idx);
    
    % 获取当前层配置
    R_entry = layer_config(layer_idx).R_entry;
    R_exit_target = layer_config(layer_idx).R_exit_target;
    N_turns = layer_config(layer_idx).N_turns;
    radial_offset = layer_config(layer_idx).radial_offset;
    
    %% ===== 3.1 生成当前层几何形状 =====
    z_vec = linspace(Z_start, Z_end, Nz);
    
    % 验证特殊曲面
    if (Surface_Type == 2 || Surface_Type == 5) && Z_start <= 0
        error('对于双曲线或抛物面，Z_start 必须大于 0！');
    end
    
    switch Surface_Type
        case 1 % Cone
            tan_alpha = (R_exit_target - R_entry) / (Z_end - Z_start);
            r_vec = R_entry + (z_vec - Z_start) * tan_alpha;
            dr_dz = repmat(tan_alpha, size(z_vec));
            name_str = 'Conical';
        case 2 % Hyperbolic (1/z)
            k_hyp = R_entry * Z_start;
            r_vec = k_hyp ./ z_vec;
            dr_dz = -k_hyp ./ (z_vec.^2);
            name_str = 'Hyperbolic (1/z)';
        case 3 % Exponential
            L_mag = Z_end - Z_start;
            k_exp = log(R_exit_target / R_entry) / L_mag;
            r_vec = R_entry * exp(k_exp * (z_vec - Z_start));
            dr_dz = r_vec * k_exp;
            name_str = 'Exponential';
        case 4 % Catenoid
            L_mag = Z_end - Z_start;
            k_cat = acosh(R_exit_target / R_entry) / L_mag;
            r_vec = R_entry * cosh(k_cat * (z_vec - Z_start));
            dr_dz = R_entry * k_cat * sinh(k_cat * (z_vec - Z_start));
            name_str = 'Catenoid';
        case 5 % Paraboloid
            k_para = Z_start / (R_entry^2);
            r_vec = sqrt(z_vec / k_para);
            dr_dz = 0.5 ./ (sqrt(z_vec * k_para) * k_para);
            name_str = 'Paraboloid';
        case 6 % Gaussian Bell
            z_center = (Z_start + Z_end)/2;
            L_half = (Z_end - Z_start)/2;
            sigma_sq = -(L_half^2) / (2 * log(R_entry / R_exit_target));
            r_vec = R_exit_target * exp(-(z_vec - z_center).^2 / (2 * sigma_sq));
            dr_dz = -r_vec .* (z_vec - z_center) / sigma_sq;
            name_str = 'Gaussian Bell';
        case 7 % Bell + Straight
            L_straight = 150; 
            z_s = Z_start + L_straight; z_e = Z_end - L_straight;
            L_bell = z_e - z_s; z_c = (z_s + z_e)/2; Amp = R_exit_target - R_entry;
            r_vec = zeros(size(z_vec)); dr_dz = zeros(size(z_vec));
            for i=1:Nz
                z=z_vec(i);
                if z<=z_s || z>=z_e
                    r_vec(i)=R_entry; 
                    dr_dz(i)=0;
                else
                    x=2*pi*(z-z_c)/L_bell; 
                    r_vec(i)=R_entry+Amp*0.5*(1+cos(x)); 
                    dr_dz(i)=Amp*0.5*(-sin(x))*(2*pi/L_bell); 
                end
            end
            name_str = 'Smooth Bell';
        case 8 % Symmetric Corrugation
            Num_Cycles = 3; Amp_Wave = 10;
            L_mag = Z_end - Z_start; z_center = (Z_start+Z_end)/2;
            k_wave = 2*pi*Num_Cycles/L_mag;
            phase = k_wave*(z_vec-z_center);
            r_vec = R_entry + Amp_Wave*cos(phase);
            dr_dz = -Amp_Wave*k_wave*sin(phase);
            name_str = 'Corrugated';
        case 9 % Sigmoid
            z_c = (Z_start+Z_end)/2; w=(Z_end-Z_start)/6;
            R_diff=R_exit_target-R_entry; R_mean=(R_entry+R_exit_target)/2;
            val=(z_vec-z_c)/w;
            r_vec=R_mean+(R_diff/2)*tanh(val);
            dr_dz=(R_diff/2)*(sech(val).^2)*(1/w);
            name_str = 'Sigmoid';
        case 10 % Sine Quarter
            L_mag=Z_end-Z_start; Amp=R_exit_target-R_entry;
            x=(pi/2)*(z_vec-Z_start)/L_mag;
            r_vec=R_entry+Amp*sin(x);
            dr_dz=Amp*cos(x)*(pi/(2*L_mag));
            name_str = 'Sine 1/4';
    end
    
    % 应用径向偏移
    r_vec = r_vec + radial_offset;
    fprintf('Layer %d: 应用径向偏移 = %.2f mm\n', layer_idx, radial_offset);
    
    % 保角映射积分
    integrand = sqrt(1 + dr_dz.^2) ./ r_vec;
    u_vec = cumtrapz(z_vec, integrand); 
    u_max = max(u_vec);
    
    %% ===== 3.2 单极面流函数场 =====
    phi_max = pi / m; 
    phi_vec = linspace(0, phi_max, Nphi);
    
    [U_grid, Phi_grid] = meshgrid(u_vec, phi_vec);
    
    % 形状函数 (轴向)
    u_len_entry = u_max * ratio_entry;
    u_len_exit  = u_max * ratio_exit;
    u_s = u_len_entry;
    u_e = u_max - u_len_exit;
    
    f_u = zeros(size(U_grid));
    for i = 1:numel(U_grid)
        u_val = U_grid(i);
        if u_val < u_s
            f_u(i) = cos(pi * (u_s - u_val) / u_len_entry);
        elseif u_val <= u_e
            f_u(i) = 1;
        else
            f_u(i) = cos(pi * (u_val - u_e) / u_len_exit);
        end
    end
    f_u(f_u < 0) = 0; % 负值截断
    
    % 计算流函数
    Psi = sin(m * Phi_grid) .* f_u;
    
    %% ===== 3.3 参考曲面可视化 =====
    theta_surf = linspace(0, phi_max, 40);
    [Z_surf, T_surf] = meshgrid(z_vec, theta_surf);
    R_surf = interp1(z_vec, r_vec, Z_surf); 
    X_surf = R_surf .* cos(T_surf);
    Y_surf = R_surf .* sin(T_surf);
    surf(X_surf, Z_surf, Y_surf, ...
        'FaceAlpha', 0.1, ...
        'EdgeColor', 'none', ...
        'FaceColor', colors(layer_idx,:), ...
        'DisplayName', sprintf('Layer %d Surface', layer_idx));
    
    %% ===== 3.4 离散化与导出 =====
    % 专利公式离散化
    i_vec = 1:N_turns;
    psi_targets = (i_vec - 0.5) / N_turns;
    
    % 提取等值线
    C_mat = contourc(u_vec, phi_vec, Psi, psi_targets);
    
    idx = 1;
    coil_count = 0;
    limit = size(C_mat, 2);
    
    % 存储当前层所有线圈
    all_coils = {};
    
    while idx < limit
        num_pts = C_mat(2, idx);
        idx = idx + 1;
        
        u_seg = C_mat(1, idx : idx+num_pts-1);
        phi_seg = C_mat(2, idx : idx+num_pts-1);
        
        % 逆映射
        z_base = interp1(u_vec, z_vec, u_seg, 'pchip');
        r_base = interp1(z_vec, r_vec, z_base, 'pchip');
        dr_dz_base = interp1(z_vec, dr_dz, z_base, 'pchip');
        
        x_base = r_base .* cos(phi_seg);
        y_base = r_base .* sin(phi_seg);
        
        xyz_coords = [x_base(:), y_base(:), z_base(:)];
        all_coils{end+1} = xyz_coords; % 存储线圈坐标
        
        % 绘图 (按层着色)
        plot3(x_base, z_base, y_base, ...
            'Color', colors(layer_idx,:), ...
            'LineWidth', 1.5, ...
            'DisplayName', sprintf('Layer %d, Coil %d', layer_idx, coil_count+1));
        
        % 导出数据
        if do_export
            coil_count = coil_count + 1;
            full_data = calculate_tnb(xyz_coords, phi_seg(:), dr_dz_base(:));
            
            % 创建层专用子目录
            layer_dir = fullfile(output_dir, sprintf('layer_%02d', layer_idx));
            if ~exist(layer_dir, 'dir')
                mkdir(layer_dir);
            end
            
            fn = fullfile(layer_dir, sprintf('coil_%03d.txt', coil_count));
            try
                writematrix(full_data, fn, 'Delimiter', ' ');
                fprintf('  导出: %s (点数: %d)\n', fn, size(full_data,1));
            catch ME
                warning('导出失败: %s\n错误: %s', fn, ME.message);
            end
        end
        
        idx = idx + num_pts;
    end
    
    fprintf('Layer %d: 生成 %d 个线圈 (单极)\n', layer_idx, coil_count);
end

%% ===== 4. 完成与提示 =====
axis tight; camlight; lighting gouraud;
legend('Location', 'northeastoutside');
set(gca, 'FontSize', 10, 'FontWeight', 'bold');
colorbar('Ticks', 1:num_layers, 'TickLabels', color_names(1:num_layers));

fprintf('\n=== 多层单极面生成完毕 ===\n');
fprintf('总层数: %d\n', num_layers);
fprintf('Opera 提示:\n');
fprintf('1. 导入所有层目录中的线圈文件\n');
fprintf('2. 使用 Symmetry 功能生成完整磁体:\n');
fprintf('   - 选择 "Rotation" 对称\n');
fprintf('   - 旋转角度: 360/(2*m) = %.1f 度\n', 180/m);
fprintf('   - 重复次数: %d 次\n', 2*m-1);
fprintf('3. 建议创建材料组以管理不同层\n');

%% ===== TNB 计算函数 =====
function full_data = calculate_tnb(xyz_coords, phi_vec, dr_dz_vec)
    num_pts = size(xyz_coords, 1);
    if num_pts < 3
        full_data = [];
        return;
    end
    
    % 1. T (切向量)
    tangents = zeros(num_pts, 3);
    % 内部点中心差分
    for i = 2:num_pts-1
        v1 = xyz_coords(i, :) - xyz_coords(i-1, :);
        v2 = xyz_coords(i+1, :) - xyz_coords(i, :);
        t_avg = (v1/norm(v1)) + (v2/norm(v2));
        tangents(i, :) = t_avg / (norm(t_avg) + eps);
    end
    % 端点单边差分
    tangents(1,:) = xyz_coords(2,:) - xyz_coords(1,:);
    tangents(end,:) = xyz_coords(end,:) - xyz_coords(end-1,:);
    tangents = tangents ./ (vecnorm(tangents, 2, 2) + eps);
    
    % 2. B (曲面法向量)
    norm_fac = sqrt(1 + dr_dz_vec.^2) + eps;
    nx = cos(phi_vec) ./ norm_fac;
    ny = sin(phi_vec) ./ norm_fac;
    nz = -dr_dz_vec   ./ norm_fac;
    B_vecs = [nx, ny, nz];
    
    % 3. N (主法向量)
    N_vecs = cross(B_vecs, tangents, 2);
    N_norms = vecnorm(N_vecs, 2, 2);
    N_vecs = N_vecs ./ (N_norms + eps);
    
    % 4. 修正B (确保正交)
    B_vecs = cross(tangents, N_vecs, 2);
    B_vecs = B_vecs ./ (vecnorm(B_vecs, 2, 2) + eps);
    
    % 组合输出 [x y z Tx Ty Tz Nx Ny Nz Bx By Bz]
    full_data = [xyz_coords, tangents, N_vecs, B_vecs];
end