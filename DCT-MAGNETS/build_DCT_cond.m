% =========================================================================
% 脚本: Build_DCT_cond_Symmetric_v2.m
% 目的: 将 DCT 路径转换为 .cond 文件 (支持 BR8/BR20 brick+ 自动计算配置不同极面电流驱动)
% =========================================================================

%% 1. 初始化环境
clear; clc; close all;

%% 2. 核心用户配置区
fprintf('--- 1. 定义转换参数 ---\n');

% --- [关键] 磁场极数配置 (用于计算扇区) ---
options.multipole_order = 2;   % 例如: 2=四极场(4个极)

% --- 单元与截面 ---
options.element_type = 'BR20';  % 可选: 'BR8' (8节点) 或 'BR20' (20节点)
options.cross_section_shape = 'rectangular'; % 'rectangular' 或 'circular'

% --- 几何尺寸 (mm) ---
options.coil_width  = 12;    % 宽度 mm
options.coil_height = 1;     % 高度 mm
options.coil_radius = 1;     % 圆半径 mm

% --- 电学参数 ---
options.current        = 500;  % 单根导线电流 (A)
options.symmetry_index = 1;    % opera symmetry index

% --- 文件路径 ---
options.input_dir = 'dct_output'; 
options.output_dir = 'DCT_cond';  
if ~exist(options.output_dir, 'dir'), mkdir(options.output_dir); end

output_filename = sprintf('FDCT_Symmetric_m%d_%s1.cond', options.multipole_order, options.element_type);
options.output_cond_file = fullfile(options.output_dir, output_filename);

%% 3. 参数预处理
% 单位转换 mm -> m
width_m  = options.coil_width;
height_m = options.coil_height;
radius_m = options.coil_radius;

if strcmp(options.cross_section_shape, 'rectangular')
    area = height_m * width_m;
else
    area = pi * radius_m^2;
end
current_density = options.current / area;

fprintf('配置: m=%d, 单元=%s\n', options.multipole_order, options.element_type);

%% 4. 文件查找
file_pattern = fullfile(options.input_dir, 'coil_*.txt'); 
file_list = dir(file_pattern);
total_files = length(file_list);
if total_files == 0, error('未找到路径文件'); end

%% 5. 核心处理循环
fileID = fopen(options.output_cond_file, 'w');
fprintf(fileID, 'CONDUCTOR\n'); 

num_poles = 2 * options.multipole_order;
sector_angle = 360 / num_poles;

for file_index = 1:total_files
    % --- 读取数据 ---
    filename = file_list(file_index).name;
    full_path = fullfile(options.input_dir, filename);
    raw_data = readmatrix(full_path);
    
    if size(raw_data, 2) < 12, continue; end
    num_points = size(raw_data, 1);
    
    % === 自动计算驱动名称 ===
    p_start = raw_data(1, 1:3); 
    theta_deg = rad2deg(atan2(p_start(2), p_start(1)));
    if theta_deg < 0, theta_deg = theta_deg + 360; end
    pole_idx = floor(theta_deg / sector_angle) + 1;
    if pole_idx > num_poles, pole_idx = num_poles; end
    dynamic_drive_name = sprintf('''DRIVE_2%d''', pole_idx);
    
    fprintf('处理: %s -> %s\n', filename, dynamic_drive_name);

    % --- 逐段生成单元 ---
    for i = 1:(num_points - 1)
        % 提取基向量
        p1 = raw_data(i, 1:3);   n1 = raw_data(i, 7:9);  b1 = raw_data(i, 10:12);
        p2 = raw_data(i+1, 1:3); n2 = raw_data(i+1, 7:9); b2 = raw_data(i+1, 10:12);
        
        % 预分配顶点数组 (最大20)
        vertices = zeros(20, 3);
        
        % === 1. 计算基础8个角点 (BR8/BR20 通用) ===
        if strcmp(options.cross_section_shape, 'rectangular')
            offsets = [ -1, -1; 1, -1; 1, 1; -1, 1 ] .* [width_m/2, height_m/2];
            for k=1:4, vertices(k,:) = p1 + offsets(k,1)*n1 + offsets(k,2)*b1; end
            for k=1:4, vertices(k+4,:) = p2 + offsets(k,1)*n2 + offsets(k,2)*b2; end
        else
            angles = [0, 90, 180, 270] * pi/180;
            vertices(1:4, :) = p1 + radius_m * (cos(angles)'*n1 + sin(angles)'*b1);
            vertices(5:8, :) = p2 + radius_m * (cos(angles)'*n2 + sin(angles)'*b2);
        end
        
        % === 2. 分支写入 ===
        if strcmp(options.element_type, 'BR8')
            % --- BR8 模式 ---
            fprintf(fileID, 'DEFINE BR8\n');
            fprintf(fileID, '0.0 0.0 0.0 0.0 0.0 0.0\n0.0 0.0 0.0\n0.0 0.0 0.0\n');
            % 只写入前8个点
            fprintf(fileID, '%.8f %.8f %.8f\n', vertices(1:8, :)');
            
        elseif strcmp(options.element_type, 'BR20')
            % --- BR20 模式 (需要计算中点) ---
            
            % A. 截面边中点
            if strcmp(options.cross_section_shape, 'rectangular')
                vertices(9:12, :) = (vertices(1:4, :) + vertices([2:4, 1], :)) / 2;
                vertices(17:20, :) = (vertices(5:8, :) + vertices([6:8, 5], :)) / 2;
            else
                mid_as = [45, 135, 225, 315] * pi/180;
                vertices(9:12, :) = p1 + radius_m * (cos(mid_as)'*n1 + sin(mid_as)'*b1);
                vertices(17:20, :) = p2 + radius_m * (cos(mid_as)'*n2 + sin(mid_as)'*b2);
            end
            
            % B. 路径棱中点 (含弯曲修正)
            T1 = raw_data(i, 4:6); T2 = raw_data(i+1, 4:6);
            L = norm(p2 - p1);
            correction = L/8 * (T1 - T2);
            for k=1:4, vertices(12+k, :) = (vertices(k,:) + vertices(k+4,:))/2 + correction; end
            
            fprintf(fileID, 'DEFINE BR20\n');
            fprintf(fileID, '0.0 0.0 0.0 0.0 0.0 0.0\n0.0 0.0 0.0\n0.0 0.0 0.0\n');
            % 写入全部20个点
            fprintf(fileID, '%.8f %.8f %.8f\n', vertices');
        end
        
        % 3. 写入属性
        fprintf(fileID, '%.8e %d %s\n', current_density, options.symmetry_index, dynamic_drive_name);
        fprintf(fileID, '0 0 0\n1e-6\n');
    end
end

fprintf(fileID, 'QUIT\n');
fclose(fileID);
fprintf('--- 转换完成: %s ---\n', options.output_cond_file);
