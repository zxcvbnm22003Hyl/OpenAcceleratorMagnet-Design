% =========================================================================
% ULTIMATE脚本: 可配置的分布式余弦-θ(DCT)线圈统一生成器
% 版本: v1
%
% == 核心功能 ==
% 本脚本将多个脚本的功能融合到一个code中。用户可以通过一个中心控制面板，生成多种不同几何形态的DCT线圈。
%
% == 集成特性 ==
% 1. 【几何可选】: 可生成【线性(直线)】或【弧形(弯曲)】两种磁铁骨架。
% 2. 【末端可选】: 可选择【跑道形】(半圆形末端)或经过优化的【圆角矩形】末端。
% 3. 【间距可选】: 可选用简单的【均匀】层间距，或基于导体物理尺寸的【防重叠】策略，从根本上杜绝导体干涉。
% 4. 【高性能】: 采用【矢量化】计算，尤其在处理弧形几何时，极大提升了运算效率。
% 5. 【数据完整】: 为每一条线圈，完整地生成并导出三维路径(X,Y,Z)及其
%    精确的局部坐标系(T,N,B向量)，共12列数据。
% =========================================================================

%% 1. 初始化工作环境
% -------------------------------------------------------------------------
clear; clc; close all; % 清除工作区变量、清空命令行、关闭所有图形窗口
fprintf('--- ULTIMATE脚本: DCT线圈统一生成器开始执行 ---\n\n');

%% 2. 主控制面板 (用户需要修改配置的唯一区域)
% -------------------------------------------------------------------------
fprintf('--- 1. 配置磁铁设计参数... ---\n');

% --- A. 选择磁铁的【主几何形状】 ---
magnet_type = 'curved'; % 选项: 'linear' (直线型), 'curved' (弧形)

% --- B. 选择线圈【末端的几何形状】 ---
end_geometry_type = 'rounded_rectangle'; % 选项: 'racetrack' (跑道形), 'rounded_rectangle' (圆角矩形)

% --- C. 选择线圈层与层之间的【间距策略】 ---
spacing_strategy = 'physical_anti_overlap'; % 选项: 'uniform' (均匀间距), 'physical_anti_overlap' (基于物理尺寸防重叠)


% --- D. 定义几何与物理参数 (单位: 米) ---

% D.1) 两种磁铁类型【通用】的参数
r_minor = 0.120;     % 绕线截面的半径 (也叫小半径) [单位: m]
N_layers = 10;       % 总共需要生成的嵌套线圈层数
pole_angles_deg = [45, 135, 225, 315]; % 定义磁极的中心角度 [单位: 度]。例如四极场:[45,135,225,315]

% D.2) 仅在 magnet_type = 'linear' (直线型) 时【生效】的参数
if strcmpi(magnet_type, 'linear')
    L_st = 0.500; % 直线段的长度 [单位: m]
end

% D.3) 仅在 magnet_type = 'curved' (弧形) 时【生效】的参数
if strcmpi(magnet_type, 'curved')
    R_major = 1.00; % 弧形骨架的中心大半径 [单位: m]
    bending_angle_deg = 90; % 整个磁铁的中心弯曲角度 [单位: 度]
    % (自动计算) 弧形中心线的总长度
    L_arc = R_major * deg2rad(bending_angle_deg); 
end

% D.4) 仅在 spacing_strategy = 'uniform' (均匀间距) 时【生效】的参数
if strcmpi(spacing_strategy, 'uniform')
    theta_start_deg = 5;  % 最内层线圈的半角宽度 [单位: 度]
    theta_end_deg   = 40; % 最外层线圈的半角宽度 [单位: 度]
end

% D.5) 仅在 spacing_strategy = 'physical_anti_overlap' (防重叠) 时【生效】的参数
if strcmpi(spacing_strategy, 'physical_anti_overlap')
    theta_start_deg = 5;     % 最内层线圈的起始半角宽度 [单位: 度]
    CONDUCTOR_WIDTH_m = 0.003; % 单根导体的物理宽度 [单位: m]
    MINIMUM_GAP_m = 0.01;     % 导体之间期望的最小绝缘间隙 [单位: m]
end

% D.6) 仅在 end_geometry_type = 'rounded_rectangle' (圆角矩形) 时【生效】的参数
if strcmpi(end_geometry_type, 'rounded_rectangle')
    % 这个比例定义了末端有多"圆"。1.0代表完美的半圆形，<1.0则形成圆角矩形。
    corner_radius_ratio = 0.75; 
end


% --- E. 定义离散化精度和输出设置 ---
N_points_per_segment = 100; % 每个几何分段(直线/圆弧)的点数，值越高，模型越平滑
output_dir = 'dct_ULTRA_output_CN'; % 用于存放输出数据文件的文件夹名称


%% 3. 预计算与配置验证
% -------------------------------------------------------------------------
fprintf('--- 2. 验证配置并进行预计算... ---\n');
fprintf('   磁铁类型:          %s\n', upper(magnet_type));
fprintf('   末端几何:   %s\n', upper(end_geometry_type));
fprintf('   间距策略: %s\n', upper(spacing_strategy));

% 创建输出目录。如果目录已存在，则先清空其中的txt文件
if ~exist(output_dir, 'dir')
    mkdir(output_dir); 
else
    delete(fullfile(output_dir, '*.txt')); 
end

% 根据所选的间距策略，计算所有线圈层的角度序列
coil_angles_rad = zeros(1, N_layers); % 预分配内存以提高效率
if strcmpi(spacing_strategy, 'uniform')
    % --- 策略A: 均匀间距 ---
    % 使用linspace函数在线圈的起始和结束角度之间生成均匀分布的N层角度
    coil_angles_rad = deg2rad(linspace(theta_start_deg, theta_end_deg, N_layers));
    fprintf('   已通过【均匀间距】策略生成各层角度。\n');
else % physical_anti_overlap
    % --- 策略B: 物理防重叠 ---
    % a) 计算包含导体和间隙在内的总空间需求
    REQUIRED_SPACING_m = CONDUCTOR_WIDTH_m + MINIMUM_GAP_m;
    % b) 将此物理距离转换为在半径r_minor处所需的最小角度间隔(弧度)
    MIN_ANGLE_SEP_rad = REQUIRED_SPACING_m / r_minor;
    fprintf('   计算出的最小安全角度间隔为: %.2f 度\n', rad2deg(MIN_ANGLE_SEP_rad));
    
    % c) 通过累加方式生成角度序列，确保每一层都满足最小间距要求
    coil_angles_rad(1) = deg2rad(theta_start_deg); % 设置第一层
    for layer_idx = 2:N_layers
        % 下一层的位置 = 上一层的位置 + 计算出的最小安全间距
        coil_angles_rad(layer_idx) = coil_angles_rad(layer_idx - 1) + MIN_ANGLE_SEP_rad;
    end
    fprintf('   已通过【物理防重叠】策略生成各层角度。\n');
end
fprintf('   最终生成的各层半角宽度 (单位: 度):\n');
disp(rad2deg(coil_angles_rad)'); % 转置后显示更清晰


%% 4. 核心计算: 生成、计算并保存所有线圈路径
% -------------------------------------------------------------------------
fprintf('\n--- 3. 开始进入主循环，生成所有线圈路径... ---\n');

% --- 可视化设置 ---
figure('Name', 'DCT线圈三维模型 - ULTIMATE脚本 (全中文注释版)', 'Color', 'w', 'NumberTitle', 'off');
hold on; ax = gca;
colors = turbo(N_layers); % 使用更现代、更美观的色谱

% --- 主生成循环: 遍历每一层和每一个磁极 ---
for i = 1:N_layers % 外层循环: 遍历每一层线圈
    
    % a. 在虚拟的2D平面上，生成展开的"跑道"路径 (s, p)
    %    s: 沿着磁铁中心线的坐标 (轴向坐标)
    %    p: 垂直于中心线的坐标 (展开的周向坐标)
    if strcmpi(end_geometry_type, 'racetrack')
        % 调用函数生成【半圆形】末端的跑道
        end_dim_unrolled = r_minor * coil_angles_rad(i);
        % --- 已修正兼容性问题 ---
        if strcmpi(magnet_type, 'linear')
            path_length = L_st;
        else
            path_length = L_arc;
        end
        [s_path, p_path] = generate_2d_racetrack(path_length, end_dim_unrolled, N_points_per_segment, N_points_per_segment);
    else % rounded_rectangle
        % 调用函数生成【圆角矩形】末端的跑道
        end_width_unrolled = r_minor * 2 * coil_angles_rad(i);
        corner_rad_unrolled = (end_width_unrolled / 2) * corner_radius_ratio;
        % --- 已修正兼容性问题 ---
        if strcmpi(magnet_type, 'linear')
            path_length = L_st;
        else
            path_length = L_arc;
        end
        [s_path, p_path] = generate_rounded_racetrack(path_length, end_width_unrolled, corner_rad_unrolled, N_points_per_segment);
    end

    % b. 将2D路径"包裹"到3D骨架上，并为每个磁极生成一份拷贝
    for p_idx = 1:length(pole_angles_deg) % 内层循环: 遍历每一个磁极位置
        pole_angle_deg = pole_angles_deg(p_idx);
        fprintf('   处理中: 第 %d/%d 层, 位于 %.1f 度的磁极...\n', i, N_layers, pole_angle_deg);
        
        % 将展开的周向坐标p，转换回局部的角度坐标theta
        theta_path_local = p_path / r_minor;
        % 将局部角度叠加上当前磁极的基准角度，得到最终在3D空间中的角度
        final_theta_path = theta_path_local + deg2rad(pole_angle_deg);
        
        % --- 【核心】根据选择的磁铁类型，进行不同的三维映射 ---
        if strcmpi(magnet_type, 'linear')
            % 【直线型映射】: 将(s, final_theta)映射到圆柱坐标系，再转为笛卡尔坐标
            X_path = r_minor * cos(final_theta_path);
            Y_path = r_minor * sin(final_theta_path);
            Z_path = s_path; % Z轴直接就是展开时的轴向坐标s
            xyz_coords = [X_path(:), Y_path(:), Z_path(:)];
        else % 'curved'
            % 【弧形映射】: 调用高性能的矢量化函数，将(s, final_theta)映射到环形骨架上
            xyz_coords = map_path_to_curved_mandrel_vectorized(s_path, final_theta_path, R_major, r_minor);
        end
        
        % c. 为生成的三维路径计算其局部坐标系 (T, N, B 向量)
        full_path_data = calculate_path_with_frame(xyz_coords, magnet_type);
        
        % d. 将包含12列的完整数据保存到文本文件中
        output_filename = fullfile(output_dir, sprintf('dct_layer%02d_pole%02d.txt', i, p_idx));
        writematrix(full_path_data, output_filename, 'Delimiter', ' ');

        % e. 在三维图中实时绘制当前线圈的路径
        plot3(ax, full_path_data(:,1), full_path_data(:,2), full_path_data(:,3), 'Color', colors(i,:), 'LineWidth', 2.0);
    end
end

%% 5. 最终可视化设置
% -------------------------------------------------------------------------
fprintf('\n--- 4. 所有计算已完成，正在进行最终的可视化处理... ---\n');

% 如果是弧形磁铁，绘制中心骨架路径作为参考
if strcmpi(magnet_type, 'curved')
    s_center = linspace(-L_arc/2, L_arc/2, 200);
    center_angles_viz = s_center / R_major;
    p_center_viz = [R_major * cos(center_angles_viz); zeros(size(center_angles_viz)); R_major * sin(center_angles_viz)]';
    plot3(p_center_viz(:,1), p_center_viz(:,2), p_center_viz(:,3), 'k--', 'LineWidth', 2, 'DisplayName', '中心骨架路径');
    legend('show');
end

% --- 美化图形 ---
title_str = sprintf('DCT线圈三维模型 (%s, %s, %s)', upper(magnet_type), upper(end_geometry_type), upper(spacing_strategy));
title(title_str, 'FontSize', 14);
xlabel('X 轴 (m)'); ylabel('Y 轴 (m)'); zlabel('Z 轴 (m)');
axis equal;     % 确保各轴比例相同，模型不变形
grid on;        % 显示网格
view(30, 20);   % 设置初始观察视角
camlight head;  % 添加一盏随摄像头移动的灯光
lighting gouraud; % 使用Gouraud光照模型，使表面更平滑
rotate3d on;    % 允许用户用鼠标交互式旋转图形
hold off;
fprintf('\n--- 脚本执行完毕！ ---\n');


%% 6. 整合的辅助函数库
% =========================================================================

function [axis_path, unrolled_path] = generate_2d_racetrack(L_st, end_radius, N_body, N_end)
% 辅助函数 I: 在2D平面上生成一个【半圆形末端】的跑道路径。
% 输入:
%   L_st:       跑道直线部分的长度
%   end_radius: 末端半圆的半径
%   N_body:     直线部分的离散点数
%   N_end:      半圆部分的离散点数
% 输出:
%   axis_path:     沿着跑道中心线的坐标 (对应3D中的轴向)
%   unrolled_path: 垂直于中心线的坐标 (对应3D中的周向)
    s1 = linspace(-L_st/2, L_st/2, N_body); p1 = ones(size(s1)) * end_radius;
    t2 = linspace(pi/2, -pi/2, N_end); s2 = L_st/2 + end_radius * cos(t2); p2 = end_radius * sin(t2);
    s3 = linspace(L_st/2, -L_st/2, N_body); p3 = -ones(size(s3)) * end_radius;
    t4 = linspace(-pi/2, -3*pi/2, N_end); s4 = -L_st/2 + end_radius * cos(t4); p4 = end_radius * sin(t4);
    % 拼接路径，并移除各段之间的重复点(例如s2(2:end))以保证路径平滑
    axis_path = [s1, s2(2:end), s3(2:end), s4(2:end-1)];
    unrolled_path = [p1, p2(2:end), p3(2:end), p4(2:end-1)];
end

function [axis_path, unrolled_path] = generate_rounded_racetrack(L_st, end_width, corner_rad, N_points)
% 辅助函数 II: 在2D平面上生成一个【圆角矩形末端】的跑道路径。
% 输入:
%   L_st:       跑道中心直线部分的长度
%   end_width:  跑道末端的总宽度
%   corner_rad: 末端圆角的半径
%   N_points:   每个几何分段(直线/圆弧)的离散点数
% 输出: (同上)
    if corner_rad * 2 > end_width + 1e-9 % 增加浮点数容差
        error('错误: 圆角半径太大! 它必须小于或等于末端总宽度的一半。');
    end
    
    L_end_straight = end_width - 2 * corner_rad;
    half_width = end_width / 2;
    half_L_st = L_st / 2;
    
    % 分8个几何区段(4条直线, 4个1/4圆弧)来定义路径
    s1 = linspace(-half_L_st, half_L_st, N_points); u1 = ones(1, N_points) * half_width;
    t_arc1 = linspace(pi/2, 0, N_points); s_arc1 = half_L_st + corner_rad * cos(t_arc1); u_arc1 = (half_width - corner_rad) + corner_rad * sin(t_arc1);
    s_end_straight = ones(1, N_points) * (half_L_st + corner_rad); u_end_straight = linspace(L_end_straight/2, -L_end_straight/2, N_points);
    t_arc2 = linspace(0, -pi/2, N_points); s_arc2 = half_L_st + corner_rad * cos(t_arc2); u_arc2 = (-half_width + corner_rad) + corner_rad * sin(t_arc2);
    s3 = linspace(half_L_st, -half_L_st, N_points); u3 = -ones(1, N_points) * half_width;
    t_arc3 = linspace(-pi/2, -pi, N_points); s_arc3 = -half_L_st + corner_rad * cos(t_arc3); u_arc3 = (-half_width + corner_rad) + corner_rad * sin(t_arc3);
    s_end_straight2 = ones(1, N_points) * (-half_L_st - corner_rad); u_end_straight2 = linspace(-L_end_straight/2, L_end_straight/2, N_points);
    t_arc4 = linspace(-pi, -3*pi/2, N_points); s_arc4 = -half_L_st + corner_rad * cos(t_arc4); u_arc4 = (half_width - corner_rad) + corner_rad * sin(t_arc4);

    % 拼接所有区段，并移除重复点
    axis_path = [s1, s_arc1(2:end), s_end_straight(2:end), s_arc2(2:end), s3(2:end), s_arc3(2:end), s_end_straight2(2:end), s_arc4(2:end-1)];
    unrolled_path = [u1, u_arc1(2:end), u_end_straight(2:end), u_arc2(2:end), u3(2:end), u_arc3(2:end), u_end_straight2(2:end), u_arc4(2:end-1)];
end

function xyz_coords = map_path_to_curved_mandrel_vectorized(s_path, theta_path, R_major, r_minor)
% 辅助函数 III: 【高性能】将2D路径映射到【弧形】骨架上 (矢量化版本)。
% 输入:
%   s_path:     轴向坐标数组
%   theta_path: 周向角度数组 (弧度)
%   R_major:    弧形骨架的大半径
%   r_minor:    绕线小半径
% 输出:
%   xyz_coords: [N x 3] 的三维坐标矩阵
    s_col = s_path(:); % 确保是列向量
    theta_col = theta_path(:);
    
    center_angle = s_col / R_major;
    
    % 一次性计算所有点的中心路径、法向量(N_vectors)和副法向量(B_vectors)
    p_center = [R_major * cos(center_angle), zeros(size(center_angle)), R_major * sin(center_angle)];
    N_vectors = [-cos(center_angle), zeros(size(center_angle)), -sin(center_angle)];
    B_vectors = repmat([0, 1, 0], length(s_col), 1); % 副法向量始终是Y轴方向
    
    % 应用活动标架公式，使用MATLAB的点乘(.*)实现元素级运算，效率极高
    xyz_coords = p_center + r_minor * (cos(theta_col) .* N_vectors + sin(theta_col) .* B_vectors);
end

function full_path_data = calculate_path_with_frame(xyz_coords, magnet_type)
% 辅助函数 IV: 为给定的三维路径点计算其局部坐标系 (T, N, B 向量)。
% 输入:
%   xyz_coords:  一个 [N x 3] 的矩阵，包含有序的路径点
%   magnet_type: 磁铁类型，用于智能选择参考向量
% 输出:
%   full_path_data: 一个 [N x 12] 的矩阵 [X,Y,Z, Tx,Ty,Tz, Nx,Ny,Nz, Bx,By,Bz]

    num_pts = size(xyz_coords, 1);
    
    % 1. 计算切向量 T (Tangent)
    % 使用MATLAB内置的gradient函数计算数值导数，比简单的前后差分更精确
    vx = gradient(xyz_coords(:,1)); vy = gradient(xyz_coords(:,2)); vz = gradient(xyz_coords(:,3));
    velocity_vectors = [vx, vy, vz];
    % 将速度向量归一化得到单位切向量
    norms = vecnorm(velocity_vectors, 2, 2);
    norms(norms < eps) = 1; % 防止除以零
    tangents = velocity_vectors ./ norms;

    % 2. 计算法向量 N (Normal) 和副法向量 B (Binormal)
    % 采用一种在计算机图形学中非常稳健的"参考向量法"
    normals = zeros(num_pts, 3);
    binormals = zeros(num_pts, 3);
    
    % 智能选择一个初始参考向量，以最大可能避免与路径切线平行
    if strcmpi(magnet_type, 'linear')
        ref_vec_initial = [1, 0, 0]; % 对于Z轴向的直线磁铁，X轴或Y轴是很好的参考
    else % 'curved'
        if range(xyz_coords(:,1)) > range(xyz_coords(:,3))
             ref_vec_initial = [0 0 1]; % 如果路径在XY平面上延伸更广，选Z轴作参考
        else
             ref_vec_initial = [1 0 0]; % 如果路径在ZY平面上延伸更广，选X轴作参考
        end
    end

    for i = 1:num_pts
        T = tangents(i, :);
        % 【稳健性处理】处理"万向节锁"问题：如果T恰好与参考向量平行，
        % 则临时切换到一个肯定不平行的向量上
        if abs(dot(T, ref_vec_initial)) > 0.999
            ref_vec_i = cross(T, [T(3), T(1), T(2)]); % 这是一个非常巧妙的构造正交向量的方法
            ref_vec_i = ref_vec_i / (norm(ref_vec_i) + eps);
        else
            ref_vec_i = ref_vec_initial;
        end
        
        % 通过两次叉乘（类似Gram-Schmidt正交化）得到B和N
        B_unnormalized = cross(T, ref_vec_i); % B 垂直于 T 和参考向量构成的平面
        B = B_unnormalized / (norm(B_unnormalized) + eps);
        N = cross(B, T); % N 垂直于 T 和 B，最终构成一个右手坐标系(T,N,B)
        
        normals(i, :) = N;
        binormals(i, :) = B;
    end
    
    % 3. 将所有数据组合成最终的 [N x 12] 输出矩阵
    full_path_data = [xyz_coords, tangents, normals, binormals];
end
