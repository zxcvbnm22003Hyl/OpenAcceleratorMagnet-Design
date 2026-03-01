% =========================================================================
% 综合CCT线圈建模系统 (MAX级别整合版本)
% 
% 功能描述:
%   1. 支持7种CCT线圈类型生成：
%      - 直线型圆形CCT
%      - 直线型椭圆CCT
%      - 弯曲圆形CCT
%      - 弯曲椭圆形CCT
%      - 直线拟多边形CCT
%      - 弯曲拟多边形CCT 
%      - 生成所有类型
%   2. 提供专业级TNB标架计算（RMF算法）
%   3. 统一使用毫米(mm)作为长度单位
%   4. 完整的数据导出和三维可视化功能
%   5. 增强的进度显示和错误处理
%
% 使用方法：
%   直接修改下方【参数控制区】中的参数，然后运行脚本
%
% 版本: CCT建模系统MAX
% 作者: He Yulin
% 日期: 2025.09.17
% =========================================================================

clear; clc; close all; % 清空工作区、命令窗口、关闭所有图形窗口
warning('off', 'MATLAB:polyshape:repairedBySimplify'); % 关闭多边形简化修复的警告信息

%% ╔════════════════════════════════════════════════════════════════════╗
%% ║                     【用户参数控制区】                             
%% ║            请根据需要修改以下参数，然后运行脚本                    
%% ╚════════════════════════════════════════════════════════════════════╝

% ===【主控制参数】===
% 选择要生成的线圈类型（修改编号）：
%   1 - 直线型圆形CCT (Linear Circular CCT)
%   2 - 直线型椭圆CCT (Linear Elliptic CCT)
%   3 - 弯曲圆形CCT (Curved Circular CCT)
%   4 - 弯曲椭圆形CCT (Curved Elliptic CCT)
%   5 - 直线拟多边形CCT (Linear Quasi-polygonal CCT)
%   6 - 弯曲拟多边形CCT (Bent Quasi-polygonal CCT) 
%   7 - 生成所有类型 (Generate All Types)
COIL_TYPE = 5;  % <-- 修改此处数字选择线圈类型

% TNB标架计算方法（修改数字）：
%   1 - RMF算法（旋转最小化标架，推荐，防止扭转）
%   2 - 简化算法（计算速度快）（不推荐，OPERA有一定几率报错）
TNB_METHOD = 1;  % <-- 修改此处数字选择TNB算法

% ===【直线型圆形CCT参数】=== （当COIL_TYPE=1时生效）
LINEAR_CIRCULAR_PARAMS.Pitch = 10;           % 螺距 (mm) - 线圈沿轴向前进一圈的距离
LINEAR_CIRCULAR_PARAMS.Amp = 30;              % 调制幅度 (mm) - 轴向位置的正弦调制幅度
LINEAR_CIRCULAR_PARAMS.N_pole = 2;            % 磁场阶数 (2=四极场, 3=六极场)
LINEAR_CIRCULAR_PARAMS.N_turns = 20;          % 总匝数 - 线圈绕制的总圈数
LINEAR_CIRCULAR_PARAMS.N_points_per_turn = 20;% 每匝采样点数 - 每圈的离散点数量
LINEAR_CIRCULAR_PARAMS.R1 = 50;               % 内层半径 (mm) - 内层线圈的半径
LINEAR_CIRCULAR_PARAMS.R2 = 60;               % 外层半径 (mm) - 外层线圈的半径

% ===【直线型椭圆CCT参数】=== （当COIL_TYPE=2时生效）
LINEAR_ELLIPTIC_PARAMS.Pitch = 15;           % 螺距 (mm) - 线圈沿轴向前进一圈的距离
LINEAR_ELLIPTIC_PARAMS.Amp = 25;             % 调制幅度 (mm) - 轴向位置的正弦调制幅度
LINEAR_ELLIPTIC_PARAMS.N_pole = 3;           % 磁场阶数 - 决定磁场的多极性
LINEAR_ELLIPTIC_PARAMS.N_turns = 20;         % 总匝数 - 线圈绕制的总圈数
LINEAR_ELLIPTIC_PARAMS.N_points_per_turn = 20;% 每匝采样点数 - 每圈的离散点数量
LINEAR_ELLIPTIC_PARAMS.a1 = 60;              % 内层半长轴 (mm) - 内层椭圆的长轴半径
LINEAR_ELLIPTIC_PARAMS.b1 = 40;              % 内层半短轴 (mm) - 内层椭圆的短轴半径
LINEAR_ELLIPTIC_PARAMS.a2 = 70;              % 外层半长轴 (mm) - 外层椭圆的长轴半径
LINEAR_ELLIPTIC_PARAMS.b2 = 48;              % 外层半短轴 (mm) - 外层椭圆的短轴半径
LINEAR_ELLIPTIC_PARAMS.rotation_deg = 60;     % 起始旋转角度 (度) - 椭圆的初始旋转角

% ===【弯曲圆形CCT参数】=== （当COIL_TYPE=3时生效）
CIRCULAR_PARAMS.Rc = 250;           % 主半径 (mm) - 弯曲的主曲率半径
CIRCULAR_PARAMS.r1 = 50;            % 内层半径 (mm) - 内层线圈横截面半径
CIRCULAR_PARAMS.r2 = 60;            % 外层半径 (mm) - 外层线圈横截面半径
CIRCULAR_PARAMS.n = 2;              % 主谐波阶数 - 控制调制的周期性
CIRCULAR_PARAMS.Cn = 0.2;           % 调制系数 - 控制调制的强度
CIRCULAR_PARAMS.phi0 = pi/50;       % 螺旋角步进 - 控制螺旋的紧密程度
CIRCULAR_PARAMS.rotation_deg = 45;  % 旋转角度 (度) - 初始相位旋转
CIRCULAR_PARAMS.turns = 30;         % 总匝数 - 线圈绕制的总圈数
CIRCULAR_PARAMS.points_per_turn = 50;% 每匝采样点数 - 每圈的离散点数量
CIRCULAR_PARAMS.bend_axis = 'Y';    % 弯曲轴: 'Y'或'Z' - 确定弯曲平面

% ===【弯曲椭圆形CCT参数】=== （当COIL_TYPE=4时生效）
ELLIPTIC_PARAMS.Rc = 200;           % 环半径 (mm) - 弯曲的主曲率半径
ELLIPTIC_PARAMS.a1 = 50;            % 内层半长轴 (mm) - 内层椭圆长轴半径
ELLIPTIC_PARAMS.b1 = 20;            % 内层半短轴 (mm) - 内层椭圆短轴半径
ELLIPTIC_PARAMS.a2 = 60;            % 外层半长轴 (mm) - 外层椭圆长轴半径
ELLIPTIC_PARAMS.b2 = 24;            % 外层半短轴 (mm) - 外层椭圆短轴半径
ELLIPTIC_PARAMS.n = 1;              % 极对数 - 控制磁场的多极性
ELLIPTIC_PARAMS.turns = 40;         % 总匝数 - 线圈绕制的总圈数
ELLIPTIC_PARAMS.phi0 = pi/50;       % 角节距 - 控制螺旋的紧密程度
ELLIPTIC_PARAMS.Amp = 40;           % 摆动幅度 (mm) - 调制的振幅
ELLIPTIC_PARAMS.rotation_deg = 0;   % 旋转角度 (度) - 初始相位旋转
ELLIPTIC_PARAMS.points_per_turn = 40;% 每匝采样点数 - 每圈的离散点数量

% ===【直线拟多边形CCT参数】=== （当COIL_TYPE=5时生效）
% 形状类型选择（修改数字）：
%   1 - 椭圆形 (elliptic)
%   2 - 三角形 (triangular) 
%   3 - 正方形 (square)
%   4 - 五边形 (quasipentagon)
%   5 - 六边形 (quasihexagon)
%   6 - 七边形 (quasiheptagon)
%   7 - 八边形 (quasioctagon)
%   8 - 矩形 (rectangular)
LINEAR_POLY_PARAMS.shape_type = 3;             % <-- 修改此处数字选择多边形形状
LINEAR_POLY_PARAMS.rotation_deg = 45;          % 旋转角度 (度) - 多边形的旋转角度
LINEAR_POLY_PARAMS.points_per_turn = 30;       % 每匝采样点数(推荐50以下，OPERA支持20节点导体)
% 以下参数会根据shape_type自动设置，也可手动覆盖
LINEAR_POLY_PARAMS.override = false;           % 设为true以使用下面的自定义参数
LINEAR_POLY_PARAMS.custom.c = 100;             % 形状参数c (mm) - 控制变形程度
LINEAR_POLY_PARAMS.custom.rho0 = 65;           % 基础半径 (mm) - 参考圆半径
LINEAR_POLY_PARAMS.custom.m_pole = 1;          % 极对数 - 磁场多极性
LINEAR_POLY_PARAMS.custom.w = 15;              % 螺距参数 (mm) - 轴向前进速率
LINEAR_POLY_PARAMS.custom.Am = 50;             % 调制幅度 (mm) - 轴向调制振幅
LINEAR_POLY_PARAMS.custom.turns = 50;          % 总匝数 - 线圈总圈数
LINEAR_POLY_PARAMS.custom.n_poly = 3;          % 多边形边数 - 形状的边数

% ===【弯曲拟多边形CCT参数】=== （当COIL_TYPE=6时生效）★新增★
% 形状类型选择（修改数字）：
%   1 - 椭圆形 (elliptic)
%   2 - 三角形 (triangular) 
%   3 - 正方形 (square)
%   4 - 五边形 (quasipentagon)
%   5 - 六边形 (quasihexagon)
%   6 - 七边形 (quasiheptagon)
%   7 - 八边形 (quasioctagon)
%   8 - 矩形 (rectangular)
BENT_POLY_PARAMS.shape_type = 4;               % <-- 修改此处数字选择多边形形状
BENT_POLY_PARAMS.rotation_deg = 45;            % 旋转角度 (度) - 多边形的旋转角度
BENT_POLY_PARAMS.R_bend = 500.0;               % 弯曲主半径 (mm) - 弯曲曲率半径
BENT_POLY_PARAMS.bend_angle = pi/2;            % 弯曲角度 (弧度) - 弯曲的总角度
BENT_POLY_PARAMS.points_per_turn = 100;        % 每匝采样点数 - 每圈离散点数
BENT_POLY_PARAMS.layer_separation_factor = 1.15; % 层间分离系数 - 内外层半径比
% 以下参数会根据shape_type自动设置，也可手动覆盖
BENT_POLY_PARAMS.override = false;             % 设为true以使用下面的自定义参数
BENT_POLY_PARAMS.custom.c = 100;               % 形状参数c (mm) - 控制变形程度
BENT_POLY_PARAMS.custom.rho0 = 50;             % 基础半径 (mm) - 参考圆半径
BENT_POLY_PARAMS.custom.m_pole = 2;            % 极对数 - 磁场多极性
BENT_POLY_PARAMS.custom.w = 40;                % 螺距参数 (mm) - 轴向前进速率
BENT_POLY_PARAMS.custom.Am = 80;               % 调制幅度 (mm) - 轴向调制振幅
BENT_POLY_PARAMS.custom.n_poly = 4;            % 多边形边数 - 形状的边数

% ===【输出控制参数】===
OUTPUT_PARAMS.save_files = true;        % 是否保存文件 - true保存，false不保存
OUTPUT_PARAMS.show_plots = true;        % 是否显示图形 - true显示，false不显示
OUTPUT_PARAMS.plot_tnb_vectors = true;  % 是否绘制TNB矢量 - true绘制标架矢量
OUTPUT_PARAMS.tnb_vector_skip = 30;     % TNB矢量显示间隔 - 每隔多少个点显示一次
OUTPUT_PARAMS.tnb_vector_scale = 10;    % TNB矢量长度比例 (mm) - 矢量显示长度
OUTPUT_PARAMS.file_precision = 8;       % 文件输出精度（小数位数）- 保存数据的精度
OUTPUT_PARAMS.save_mat_file = true;     % 是否保存.mat文件 - MATLAB格式数据文件
OUTPUT_PARAMS.show_progress = true;     % 是否显示进度条 - 显示计算进度
OUTPUT_PARAMS.plot_quality = 'high';    % 图形质量: 'low', 'medium', 'high'

%% ╔════════════════════════════════════════════════════════════════════╗
%% ║                        系统执行区域                                 ║
%% ║                    （以下代码无需修改）                             ║
%% ╚════════════════════════════════════════════════════════════════════╝

% 开始计时
tic; % 启动计时器，用于测量程序运行时间

% 打印程序启动信息
fprintf('╔════════════════════════════════════════╗\n');
fprintf('║    综合CCT线圈建模系统 (MAX v4.0)       ║\n');
fprintf('║       含弯曲拟多边形CCT功能             ║\n');
fprintf('╚════════════════════════════════════════╝\n\n');

%% ==================== 核心TNB计算函数 ====================

% --- 专业版TNB计算函数 (使用旋转最小化标架RMF) ---
function full_path_data = calculate_tnb_frames_pro(path_xyz, show_progress)
    % 使用旋转最小化标架(RMF)方法计算TNB标架
    % 输入: path_xyz - N x 3 矩阵，每行为[X, Y, Z]坐标（单位：毫米）
    %       show_progress - 是否显示进度
    % 输出: full_path_data - N x 12 矩阵 [X, Y, Z, Tx, Ty, Tz, Nx, Ny, Nz, Bx, By, Bz]
    
    % 如果没有提供第二个参数，默认不显示进度
    if nargin < 2
        show_progress = false;
    end
    
    % 输入验证
    if size(path_xyz, 2) ~= 3 % 检查输入是否为3列（X,Y,Z）
        error('输入矩阵 path_xyz 必须是 N x 3 的格式。');
    end
    num_pts = size(path_xyz, 1); % 获取路径点的总数量
    if num_pts < 3 % 至少需要3个点才能计算标架
        error('输入路径至少需要3个点才能计算TNB标架。');
    end

    % 如果需要显示进度，打印进度信息
    if show_progress
        fprintf('  计算TNB标架 (RMF算法): ');
    end

    % 计算切向矢量 (使用中心差分法)
    tangents = zeros(num_pts, 3); % 初始化切向矢量矩阵
    tangents(2:end-1, :) = path_xyz(3:end, :) - path_xyz(1:end-2, :); % 中间点使用中心差分
    tangents(1, :) = path_xyz(2, :) - path_xyz(1, :); % 起始点使用前向差分
    tangents(end, :) = path_xyz(end, :) - path_xyz(end-1, :); % 终点使用后向差分
    tangents = tangents ./ vecnorm(tangents, 2, 2); % 归一化所有切向矢量

    % 使用RMF计算法向矢量
    normals = zeros(num_pts, 3); % 初始化法向矢量矩阵
    
    % 初始化第一个法向矢量
    t1 = tangents(1, :); % 获取第一个切向矢量
    ref_vec = [0, 0, 1]; % 优先使用Z轴作为参考矢量
    if abs(dot(t1, ref_vec)) > 0.99 % 如果切线几乎与Z轴平行
        ref_vec = [0, 1, 0]; % 切换到Y轴作为参考
    end
    
    % 格拉姆-施密特正交化过程，生成与切向垂直的法向
    n1_unnormalized = ref_vec - dot(ref_vec, t1) * t1;
    normals(1, :) = n1_unnormalized / norm(n1_unnormalized); % 归一化
    
    % 迭代计算所有点的法向矢量（使用平行传输）
    progress_step = max(1, floor(num_pts / 20)); % 计算进度显示步长
    for i = 2:num_pts % 从第二个点开始迭代
        if show_progress && mod(i, progress_step) == 0 % 显示进度点
            fprintf('.');
        end
        
        t_prev = tangents(i-1, :); % 前一个点的切向
        n_prev = normals(i-1, :);  % 前一个点的法向
        t_curr = tangents(i, :);   % 当前点的切向
        
        % 计算旋转轴（两个切向的叉积）
        rotation_vec = cross(t_prev, t_curr);
        
        if norm(rotation_vec) < 1e-12 % 如果切线方向几乎没有变化
            normals(i, :) = n_prev; % 直接复制前一个法向
        else
            % 使用Rodrigues旋转公式进行平行传输
            cos_angle = dot(t_prev, t_curr); % 两切向夹角的余弦
            sin_angle = norm(rotation_vec);  % 两切向夹角的正弦
            rotation_vec = rotation_vec / sin_angle; % 归一化旋转轴
            
            % 构建旋转矩阵（Rodrigues公式）
            K = [0, -rotation_vec(3), rotation_vec(2);     % 反对称矩阵
                 rotation_vec(3), 0, -rotation_vec(1);
                 -rotation_vec(2), rotation_vec(1), 0];
            R = eye(3) + sin_angle * K + (1 - cos_angle) * K^2; % 旋转矩阵
            normals(i, :) = (R * n_prev')'; % 应用旋转得到新的法向
        end
    end

    % 计算副法向矢量（切向与法向的叉积）
    binormals = cross(tangents, normals, 2);
    
    if show_progress
        fprintf(' 完成\n');
    end
    
    % 组合输出数据：坐标 + TNB标架
    full_path_data = [path_xyz, tangents, normals, binormals];
end

% --- 简化版TNB计算函数 ---
function tnb_data = calculate_tnb_frames_v1(xyz_coords, show_progress)
    % 简化版TNB计算（使用数值差分）
    if nargin < 2 % 如果没有提供第二个参数
        show_progress = false;
    end
    
    if show_progress
        fprintf('  计算TNB标架 (简化算法): ');
    end
    
    num_pts = size(xyz_coords, 1); % 获取点的数量
    tangents = zeros(num_pts, 3);  % 初始化切向矢量
    normals = zeros(num_pts, 3);   % 初始化法向矢量
    binormals = zeros(num_pts, 3); % 初始化副法向矢量
    
    % 使用梯度计算速度矢量
    velocity = gradient(xyz_coords')'; % 计算各方向的梯度作为速度
    
    progress_step = max(1, floor(num_pts / 20)); % 进度显示步长
    for i = 1:num_pts
        if show_progress && mod(i, progress_step) == 0 % 显示进度
            fprintf('.');
        end
        
        % 计算切向矢量
        T = velocity(i, :); % 获取当前点的速度矢量
        if norm(T) < 1e-9  % 如果速度几乎为零
            T = [1 0 0];    % 使用默认切向
        else
            T = T / norm(T); % 归一化得到单位切向
        end
        tangents(i, :) = T;
        
        % 选择参考矢量（指向原点的径向）
        ref_vec = -[xyz_coords(i,1), xyz_coords(i,2), 0]; % XY平面上指向原点
        if norm(ref_vec) < 1e-9 % 如果在原点附近
            ref_vec = [0, 0, -1]; % 使用负Z方向
        end
        if abs(dot(T, ref_vec/norm(ref_vec))) > 0.999 % 如果几乎平行
            ref_vec = [1, 0, 0]; % 切换到X方向
        end
        
        % 计算法向矢量
        N_un = ref_vec - dot(ref_vec, T) * T; % 正交化
        if norm(N_un) < 1e-9 % 如果正交化后太小
            N = cross(T, [0 0 1]); % 使用切向与Z轴的叉积
        else
            N = N_un / norm(N_un); % 归一化
        end
        normals(i, :) = N;
        
        % 计算副法向矢量
        binormals(i, :) = cross(T, N);
    end
    
    if show_progress
        fprintf(' 完成\n');
    end
    
    % 返回TNB数据
    tnb_data = [tangents, normals, binormals];
end

%% ==================== 主执行模块 ====================

% 参数验证
validate_parameters(); % 调用参数验证函数

% 根据选择的线圈类型执行相应的生成函数
if COIL_TYPE == 7 % 如果选择生成所有类型
    % 生成所有类型
    fprintf('📊 正在生成所有类型的CCT线圈...\n\n');
    all_results = {}; % 初始化结果单元数组
    all_results{1} = generate_linear_circular_cct();    % 生成直线圆形CCT
    all_results{2} = generate_linear_elliptic_cct();    % 生成直线椭圆CCT
    all_results{3} = generate_curved_circular_cct();    % 生成弯曲圆形CCT
    all_results{4} = generate_curved_elliptic_cct();    % 生成弯曲椭圆CCT
    all_results{5} = generate_linear_quasipolygonal_cct(); % 生成直线拟多边形CCT
    all_results{6} = generate_bent_quasipolygonal_cct();   % 生成弯曲拟多边形CCT
    
    % 保存所有结果到一个MAT文件
    if OUTPUT_PARAMS.save_mat_file
        save('all_cct_coils_data.mat', 'all_results'); % 保存到MAT文件
        fprintf('💾 已保存所有线圈数据到: all_cct_coils_data.mat\n');
    end
else % 如果选择单一类型
    switch COIL_TYPE
        case 1
            generate_linear_circular_cct();      % 生成直线圆形CCT
        case 2
            generate_linear_elliptic_cct();      % 生成直线椭圆CCT
        case 3
            generate_curved_circular_cct();      % 生成弯曲圆形CCT
        case 4
            generate_curved_elliptic_cct();      % 生成弯曲椭圆CCT
        case 5
            generate_linear_quasipolygonal_cct(); % 生成直线拟多边形CCT
        case 6
            generate_bent_quasipolygonal_cct();   % 生成弯曲拟多边形CCT
        otherwise
            error('未知的线圈类型编号: %d，请选择1-7', COIL_TYPE);
    end
end

% 计算总用时
elapsed_time = toc; % 获取计时器的时间
fprintf('\n╔════════════════════════════════════════╗\n');
fprintf('║    ✅ CCT线圈生成完成！                ║\n');
fprintf('║    总用时: %.2f 秒                     ║\n', elapsed_time);
fprintf('╚════════════════════════════════════════╝\n');

%% ==================== 参数验证函数 ====================
function validate_parameters()
    % 验证所有输入参数的合理性
    fprintf('🔍 验证输入参数...\n');
    
    % 获取全局参数
    coil_type = evalin('base', 'COIL_TYPE');     % 从基础工作区获取线圈类型
    tnb_method = evalin('base', 'TNB_METHOD');   % 从基础工作区获取TNB方法
    
    % 验证基本参数
    if coil_type < 1 || coil_type > 7 % 检查线圈类型是否在有效范围内
        error('❌ COIL_TYPE必须是1-7之间的整数');
    end
    
    if tnb_method ~= 1 && tnb_method ~= 2 % 检查TNB方法是否有效
        error('❌ TNB_METHOD必须是1或2');
    end
    
    % 根据线圈类型验证具体参数
    switch coil_type
        case 1 % 直线圆形CCT
            params = evalin('base', 'LINEAR_CIRCULAR_PARAMS');
            if params.R1 <= 0 || params.R2 <= 0 % 检查半径是否为正
                error('❌ 半径必须大于0');
            end
            if params.R2 <= params.R1 % 检查外层是否大于内层
                warning('⚠️ 外层半径应大于内层半径');
            end
            
        case 2 % 直线椭圆CCT
            params = evalin('base', 'LINEAR_ELLIPTIC_PARAMS');
            if params.a1 <= 0 || params.b1 <= 0 || params.a2 <= 0 || params.b2 <= 0
                error('❌ 椭圆半轴长度必须大于0');
            end
            if params.a1 <= params.b1 || params.a2 <= params.b2
                warning('⚠️ 通常椭圆的半长轴应大于半短轴');
            end
            
        case 3 % 弯曲圆形CCT
            params = evalin('base', 'CIRCULAR_PARAMS');
            if params.Rc <= 0 || params.r1 <= 0 || params.r2 <= 0
                error('❌ 半径必须大于0');
            end
            
        case 4 % 弯曲椭圆CCT
            params = evalin('base', 'ELLIPTIC_PARAMS');
            if params.Rc <= 0 || params.a1 <= 0 || params.b1 <= 0
                error('❌ 椭圆参数必须大于0');
            end
            
        case 5 % 直线拟多边形CCT
            params = evalin('base', 'LINEAR_POLY_PARAMS');
            if params.shape_type < 1 || params.shape_type > 8
                error('❌ 形状类型必须是1-8之间的整数');
            end
            
        case 6 % 弯曲拟多边形CCT
            params = evalin('base', 'BENT_POLY_PARAMS');
            if params.shape_type < 1 || params.shape_type > 8
                error('❌ 形状类型必须是1-8之间的整数');
            end
            if params.R_bend <= 0 % 检查弯曲半径
                error('❌ 弯曲半径必须大于0');
            end
            if params.bend_angle <= 0 % 检查弯曲角度
                error('❌ 弯曲角度必须大于0');
            end
    end
    
    fprintf('✅ 参数验证通过\n\n');
end

%% ==================== 线圈生成函数模块 ====================

% -------------------- 1. 直线型圆形CCT生成函数 --------------------
function result = generate_linear_circular_cct()
    fprintf('━━━ 生成直线型圆形CCT线圈 ━━━\n');
    
    % 获取参数
    params = evalin('base', 'LINEAR_CIRCULAR_PARAMS'); % 获取圆形CCT参数
    tnb_method = evalin('base', 'TNB_METHOD');          % 获取TNB计算方法
    output_params = evalin('base', 'OUTPUT_PARAMS');    % 获取输出控制参数
    
    % 打印参数信息
    fprintf('📐 参数设置:\n');
    fprintf('  螺距: %.1f mm, 调制幅度: %.1f mm\n', params.Pitch, params.Amp);
    fprintf('  磁场阶数: %d极场, 总匝数: %d\n', 2*params.N_pole, params.N_turns);
    fprintf('  内层半径: %.1f mm, 外层半径: %.1f mm\n\n', params.R1, params.R2);
    
    % 生成参数空间
    total_points = params.N_turns * params.N_points_per_turn; % 计算总点数
    t = linspace(0, params.N_turns * 2 * pi, total_points);  % 生成参数t的等间距数组
    
    fprintf('🔧 生成路径点...\n');
    % 定义内层路径函数
    x1_func = @(T) params.R1 * cos(T);     % X坐标：半径×cos(角度)
    y1_func = @(T) params.R1 * sin(T);     % Y坐标：半径×sin(角度)
    z1_func = @(T) (params.Pitch / (2 * pi)) * T + params.Amp * sin(params.N_pole * T); % Z坐标：线性+正弦调制
    
    % 定义外层路径函数（相位偏移）
    phase_shift = pi / params.N_pole;      % 计算相位偏移量（180度/极数）
    x2_func = @(T) params.R2 * cos(T + phase_shift);  % X坐标：带相位偏移
    y2_func = @(T) params.R2 * sin(T + phase_shift);  % Y坐标：带相位偏移
    z2_func = @(T) (params.Pitch / (2 * pi)) * T + params.Amp * sin(params.N_pole * T); % Z坐标：同内层
    
    % 生成路径点
    xyz1 = zeros(total_points, 3); % 初始化内层坐标矩阵
    xyz2 = zeros(total_points, 3); % 初始化外层坐标矩阵
    for i = 1:total_points
        xyz1(i, :) = [x1_func(t(i)), y1_func(t(i)), z1_func(t(i))]; % 计算内层每个点
        xyz2(i, :) = [x2_func(t(i)), y2_func(t(i)), z2_func(t(i))]; % 计算外层每个点
    end
    
    % 计算TNB标架
    fprintf('📊 计算TNB标架...\n');
    if tnb_method == 1 % 如果选择RMF算法
        full_data_1 = calculate_tnb_frames_pro(xyz1, output_params.show_progress);
        full_data_2 = calculate_tnb_frames_pro(xyz2, output_params.show_progress);
    else % 如果选择简化算法
        tnb1 = calculate_tnb_frames_v1(xyz1, output_params.show_progress);
        tnb2 = calculate_tnb_frames_v1(xyz2, output_params.show_progress);
        full_data_1 = [xyz1, tnb1]; % 组合坐标和TNB
        full_data_2 = [xyz2, tnb2];
    end
    
    % 保存和可视化
    result = save_and_visualize_cct('linear_circular', full_data_1, full_data_2, ...
                                    params.N_pole, params.N_turns);
end

% -------------------- 2. 直线型椭圆CCT生成函数 --------------------
function result = generate_linear_elliptic_cct()
    fprintf('━━━ 生成直线型椭圆CCT线圈 ━━━\n');
    
    % 获取参数
    params = evalin('base', 'LINEAR_ELLIPTIC_PARAMS'); % 获取椭圆CCT参数
    tnb_method = evalin('base', 'TNB_METHOD');          % 获取TNB计算方法
    output_params = evalin('base', 'OUTPUT_PARAMS');    % 获取输出控制参数
    
    % 打印参数信息
    fprintf('📐 参数设置:\n');
    fprintf('  螺距: %.1f mm, 调制幅度: %.1f mm\n', params.Pitch, params.Amp);
    fprintf('  磁场阶数: %d极场, 总匝数: %d\n', 2*params.N_pole, params.N_turns);
    fprintf('  内层椭圆: %.1f × %.1f mm\n', params.a1, params.b1);
    fprintf('  外层椭圆: %.1f × %.1f mm\n\n', params.a2, params.b2);
    
    % 生成参数空间
    total_points = params.N_turns * params.N_points_per_turn; % 计算总点数
    t = linspace(0, params.N_turns * 2 * pi, total_points);  % 生成参数数组
    
    fprintf('🔧 生成椭圆路径点...\n');
    
    % 相位偏移
    psi_offset = deg2rad(params.rotation_deg);  % 将角度转换为弧度
    phase_offset = params.N_pole * psi_offset;  % 计算总相位偏移
    phase_shift = pi / params.N_pole;           % 层间相位差
    
    % 计算椭圆参数（使用椭圆坐标系）
    e_bar1 = sqrt(params.a1^2 - params.b1^2);   % 内层线性偏心率
    eta0_1 = atanh(params.b1/params.a1);        % 内层椭圆参数
    e_bar2 = sqrt(params.a2^2 - params.b2^2);   % 外层线性偏心率
    eta0_2 = atanh(params.b2/params.a2);        % 外层椭圆参数
    
    % 生成路径点
    xyz1 = zeros(total_points, 3); % 初始化内层坐标
    xyz2 = zeros(total_points, 3); % 初始化外层坐标
    
    for i = 1:total_points
        theta = t(i); % 当前参数值
        
        % 内层椭圆路径（使用椭圆坐标系）
        psi1 = theta; % 内层角度参数
        xyz1(i, 1) = e_bar1 * cosh(eta0_1) * cos(psi1); % X坐标
        xyz1(i, 2) = e_bar1 * sinh(eta0_1) * sin(psi1); % Y坐标
        xyz1(i, 3) = (params.Pitch / (2 * pi)) * theta + ...
                     params.Amp * sin(params.N_pole * theta + phase_offset); % Z坐标
        
        % 外层椭圆路径（添加相位偏移）
        psi2 = theta + phase_shift; % 外层角度参数（带偏移）
        xyz2(i, 1) = e_bar2 * cosh(eta0_2) * cos(psi2); % X坐标
        xyz2(i, 2) = e_bar2 * sinh(eta0_2) * sin(psi2); % Y坐标
        xyz2(i, 3) = (params.Pitch / (2 * pi)) * theta + ...
                     params.Amp * sin(params.N_pole * theta + phase_offset); % Z坐标
    end
    
    % 计算TNB标架
    fprintf('📊 计算TNB标架...\n');
    if tnb_method == 1 % 使用RMF算法
        full_data_1 = calculate_tnb_frames_pro(xyz1, output_params.show_progress);
        full_data_2 = calculate_tnb_frames_pro(xyz2, output_params.show_progress);
    else % 使用简化算法
        tnb1 = calculate_tnb_frames_v1(xyz1, output_params.show_progress);
        tnb2 = calculate_tnb_frames_v1(xyz2, output_params.show_progress);
        full_data_1 = [xyz1, tnb1];
        full_data_2 = [xyz2, tnb2];
    end
    
    % 保存和可视化
    result = save_and_visualize_cct('linear_elliptic', full_data_1, full_data_2, ...
                                    params.N_pole, params.N_turns);
end

% -------------------- 3. 弯曲圆形CCT生成函数 --------------------
function result = generate_curved_circular_cct()
    fprintf('━━━ 生成弯曲圆形CCT线圈 ━━━\n');
    
    % 获取参数
    params = evalin('base', 'CIRCULAR_PARAMS');      % 获取弯曲圆形参数
    tnb_method = evalin('base', 'TNB_METHOD');       % 获取TNB计算方法
    output_params = evalin('base', 'OUTPUT_PARAMS'); % 获取输出控制参数
    
    % 打印参数信息
    fprintf('📐 参数设置:\n');
    fprintf('  主半径: %.1f mm, 内层: %.1f mm, 外层: %.1f mm\n', ...
            params.Rc, params.r1, params.r2);
    fprintf('  主谐波阶数: %d, 总匝数: %d, 旋转角度: %.1f°\n', ...
            params.n, params.turns, params.rotation_deg);
    fprintf('  弯曲轴: %s轴\n\n', params.bend_axis);
    
    % 计算相位偏移
    psi_offset = deg2rad(params.rotation_deg);         % 角度转弧度
    phase_offset = params.n * psi_offset;              % 总相位偏移
    total_points = ceil(params.turns * params.points_per_turn); % 总点数
    psi_path = linspace(0, params.turns * 2*pi, total_points);  % 参数数组
    
    % 定义路径函数
    phi_func_L1 = @(psi) +params.Cn * sin(params.n * psi + phase_offset) + (psi / (2*pi)) * params.phi0; % 内层角度函数
    phi_func_L2 = @(psi) -params.Cn * sin(params.n * psi + phase_offset) + (psi / (2*pi)) * params.phi0; % 外层角度函数
    
    fprintf('🔧 生成弯曲路径点...\n');
    % 生成路径点
    xyz1 = zeros(total_points, 3); % 初始化内层坐标
    xyz2 = zeros(total_points, 3); % 初始化外层坐标
    
    if strcmpi(params.bend_axis, 'Y') % 如果绕Y轴弯曲
        % 绕Y轴弯曲（环在XZ平面，Y是高度）
        for i = 1:total_points
            psi = psi_path(i); % 当前参数值
            % 内层路径
            xyz1(i, 1) = (params.Rc + params.r1 * cos(psi)) * cos(phi_func_L1(psi)); % X坐标
            xyz1(i, 2) = params.r1 * sin(psi);                                        % Y坐标
            xyz1(i, 3) = (params.Rc + params.r1 * cos(psi)) * sin(phi_func_L1(psi)); % Z坐标
            % 外层路径
            xyz2(i, 1) = (params.Rc + params.r2 * cos(psi)) * cos(phi_func_L2(psi)); % X坐标
            xyz2(i, 2) = params.r2 * sin(psi);                                        % Y坐标
            xyz2(i, 3) = (params.Rc + params.r2 * cos(psi)) * sin(phi_func_L2(psi)); % Z坐标
        end
    else % 如果绕Z轴弯曲
        % 绕Z轴弯曲（环在XY平面，Z是高度）
        for i = 1:total_points
            psi = psi_path(i); % 当前参数值
            % 内层路径
            xyz1(i, 1) = (params.Rc + params.r1 * cos(psi)) * cos(phi_func_L1(psi)); % X坐标
            xyz1(i, 2) = (params.Rc + params.r1 * cos(psi)) * sin(phi_func_L1(psi)); % Y坐标
            xyz1(i, 3) = params.r1 * sin(psi);                                        % Z坐标
            % 外层路径
            xyz2(i, 1) = (params.Rc + params.r2 * cos(psi)) * cos(phi_func_L2(psi)); % X坐标
            xyz2(i, 2) = (params.Rc + params.r2 * cos(psi)) * sin(phi_func_L2(psi)); % Y坐标
            xyz2(i, 3) = params.r2 * sin(psi);                                        % Z坐标
        end
    end
    
    % 计算TNB标架
    fprintf('📊 计算TNB标架...\n');
    if tnb_method == 1 % 使用RMF算法
        full_data_1 = calculate_tnb_frames_pro(xyz1, output_params.show_progress);
        full_data_2 = calculate_tnb_frames_pro(xyz2, output_params.show_progress);
    else % 使用简化算法
        tnb1 = calculate_tnb_frames_v1(xyz1, output_params.show_progress);
        tnb2 = calculate_tnb_frames_v1(xyz2, output_params.show_progress);
        full_data_1 = [xyz1, tnb1];
        full_data_2 = [xyz2, tnb2];
    end
    
    % 保存和可视化
    result = save_and_visualize_cct('curved_circular', full_data_1, full_data_2, ...
                                    params.n, params.turns);
end

% -------------------- 4. 弯曲椭圆形CCT生成函数 --------------------
function result = generate_curved_elliptic_cct()
    fprintf('━━━ 生成弯曲椭圆形CCT线圈 ━━━\n');
    
    % 获取参数
    params = evalin('base', 'ELLIPTIC_PARAMS');      % 获取弯曲椭圆参数
    tnb_method = evalin('base', 'TNB_METHOD');       % 获取TNB计算方法
    output_params = evalin('base', 'OUTPUT_PARAMS'); % 获取输出控制参数
    
    % 打印参数信息
    fprintf('📐 参数设置:\n');
    fprintf('  环半径: %.1f mm\n', params.Rc);
    fprintf('  内层椭圆: %.1f × %.1f mm\n', params.a1, params.b1);
    fprintf('  外层椭圆: %.1f × %.1f mm\n', params.a2, params.b2);
    fprintf('  极对数: %d, 总匝数: %d\n\n', params.n, params.turns);
    
    % 计算椭圆参数
    e_bar1 = sqrt(params.a1^2 - params.b1^2);  % 内层线性偏心率
    eta0_1 = atanh(params.b1/params.a1);       % 内层椭圆参数
    e_bar2 = sqrt(params.a2^2 - params.b2^2);  % 外层线性偏心率
    eta0_2 = atanh(params.b2/params.a2);       % 外层椭圆参数
    
    % 生成参数空间
    psi_offset = deg2rad(params.rotation_deg);  % 角度转弧度
    phase_offset = params.n * psi_offset;       % 总相位偏移
    total_points = params.turns * params.points_per_turn; % 总点数
    psi_path = linspace(-pi, -pi + params.turns * 2*pi, total_points); % 参数数组
    
    % 定义路径函数
    phi_func_L1 = @(psi) +(params.Amp/params.Rc) * sin(params.n * psi + phase_offset) + (psi / (2*pi)) * params.phi0; % 内层
    phi_func_L2 = @(psi) -(params.Amp/params.Rc) * sin(params.n * psi + phase_offset) + (psi / (2*pi)) * params.phi0; % 外层
    
    fprintf('🔧 生成弯曲椭圆路径点...\n');
    % 生成路径点（绕Y轴弯曲）
    xyz1 = zeros(total_points, 3); % 初始化内层坐标
    xyz2 = zeros(total_points, 3); % 初始化外层坐标
    for i = 1:total_points
        psi = psi_path(i); % 当前参数值
        % 内层路径
        xyz1(i, 1) = (params.Rc + e_bar1*cosh(eta0_1)*cos(psi)) * cos(phi_func_L1(psi)); % X坐标
        xyz1(i, 2) = e_bar1*sinh(eta0_1)*sin(psi);                                        % Y坐标
        xyz1(i, 3) = (params.Rc + e_bar1*cosh(eta0_1)*cos(psi)) * sin(phi_func_L1(psi)); % Z坐标
        % 外层路径
        xyz2(i, 1) = (params.Rc + e_bar2*cosh(eta0_2)*cos(psi)) * cos(phi_func_L2(psi)); % X坐标
        xyz2(i, 2) = e_bar2*sinh(eta0_2)*sin(psi);                                        % Y坐标
        xyz2(i, 3) = (params.Rc + e_bar2*cosh(eta0_2)*cos(psi)) * sin(phi_func_L2(psi)); % Z坐标
    end
    
    % 计算TNB标架
    fprintf('📊 计算TNB标架...\n');
    if tnb_method == 1 % 使用RMF算法
        full_data_1 = calculate_tnb_frames_pro(xyz1, output_params.show_progress);
        full_data_2 = calculate_tnb_frames_pro(xyz2, output_params.show_progress);
    else % 使用简化算法
        tnb1 = calculate_tnb_frames_v1(xyz1, output_params.show_progress);
        tnb2 = calculate_tnb_frames_v1(xyz2, output_params.show_progress);
        full_data_1 = [xyz1, tnb1];
        full_data_2 = [xyz2, tnb2];
    end
    
    % 保存和可视化
    result = save_and_visualize_cct('curved_elliptic', full_data_1, full_data_2, ...
                                    params.n, params.turns);
end

% -------------------- 5. 直线拟多边形CCT生成函数 --------------------
function result = generate_linear_quasipolygonal_cct()
    fprintf('━━━ 生成直线拟多边形CCT线圈 ━━━\n');
    
    % 获取参数
    params = evalin('base', 'LINEAR_POLY_PARAMS');   % 获取直线多边形参数
    tnb_method = evalin('base', 'TNB_METHOD');        % 获取TNB计算方法
    output_params = evalin('base', 'OUTPUT_PARAMS');  % 获取输出控制参数
    
    % 根据数字选择形状类型
    shape_types = {'elliptic', 'triangular', 'square', 'quasipentagon', ...
                   'quasihexagon', 'quasiheptagon', 'quasioctagon', 'rectangular'}; % 形状类型数组
    
    if params.shape_type < 1 || params.shape_type > 8 % 验证形状类型
        error('形状类型必须是1-8之间的整数');
    end
    shape_type = shape_types{params.shape_type}; % 获取形状名称
    
    % 设置具体参数（使用预设或自定义）
    if params.override % 如果使用自定义参数
        % 使用自定义参数
        param = params.custom;
        fprintf('📐 使用自定义参数\n');
    else % 使用预设参数
        % 根据形状类型使用预设参数
        param.points_per_turn = params.points_per_turn; % 复制采样点数
        switch lower(shape_type)
            case 'elliptic' % 椭圆形
                param.c = 100; param.rho0 = 120;
                param.m_pole = 1; param.w = 10; param.Am = 50; param.turns = 15;
            case 'triangular' % 三角形
                param.n_poly = 3; param.c = 100; param.rho0 = 65;
                param.m_pole = 2; param.w = 15; param.Am = 30; param.turns = 50;
            case 'square' % 正方形
                param.n_poly = 4; param.c = 100; param.rho0 = 50;
                param.m_pole = 2; param.w = 10; param.Am = 80; param.turns = 50;
            case 'quasipentagon' % 五边形
                param.n_poly = 5; param.c = 100; param.rho0 = 50;
                param.m_pole = 5; param.w = 10; param.Am = 50; param.turns = 20;
            case 'quasihexagon' % 六边形
                param.n_poly = 6; param.c = 28; param.rho0 = 16;
                param.m_pole = 1; param.w = 10; param.Am = 50; param.turns = 20;
            case 'quasiheptagon' % 七边形
                param.n_poly = 7; param.c = 100; param.rho0 = 55;
                param.m_pole = 7; param.w = 10; param.Am = 50; param.turns = 40;
            case 'quasioctagon' % 八边形
                param.n_poly = 8; param.c = 100; param.rho0 = 58;
                param.m_pole = 1; param.w = 10; param.Am = 80; param.turns = 40;
            case 'rectangular' % 矩形
                param.rho0 = 60; param.m_pole = 2; param.w = 10; 
                param.Am = 50; param.turns = 40;
            otherwise
                error('未知的多边形形状类型: %s', shape_type);
        end
    end
    
    % 打印参数信息
    fprintf('📐 生成【%s】形状的【%d极场】CCT线圈\n', shape_type, 2*param.m_pole);
    fprintf('  基础半径: %.1f mm, 调制幅度: %.1f mm\n', param.rho0, param.Am);
    fprintf('  总匝数: %d, 旋转角度: %.1f°\n\n', param.turns, params.rotation_deg);
    
    % 相位偏移
    psi_offset = deg2rad(params.rotation_deg);      % 角度转弧度
    phase_offset = param.m_pole * psi_offset;       % 总相位偏移
    param.layer_separation = 1.05;                  % 层间分离系数
    
    % 定义映射函数（保形映射）
    if strcmpi(shape_type, 'elliptic') % 椭圆映射
        map_func = @(z, p) (z + p.c^2 ./ z) / 2;
    elseif strcmpi(shape_type, 'rectangular') % 矩形映射
        map_func = @(z, p) -z.^3 + z + 2./z;
    else % 多边形映射
        map_func = @(z, p) z.^(p.n_poly-1)/ p.c^(p.n_poly-2) + (p.c^2) ./ z;
    end
    
    % Z方向函数（轴向位置）
    Z_func = @(theta, w_pitch, m, A_m) ...
        (w_pitch / (2*pi)) * theta + A_m * sin(m * theta + phase_offset);
    
    fprintf('🔧 生成多边形路径点...\n');
    % 生成路径
    total_theta = param.turns * 2*pi;                          % 总角度范围
    total_points = ceil(param.turns * param.points_per_turn);  % 总点数
    theta_path = linspace(0, total_theta, total_points);       % 角度数组
    
    % 内外层半径
    rho0_L1 = param.rho0;                            % 内层基础半径
    rho0_L2 = param.rho0 * param.layer_separation;   % 外层基础半径
    
    % 复平面映射
    z_path_L1 = rho0_L1 * exp(1i * theta_path);      % 内层复平面圆
    z_path_L2 = rho0_L2 * exp(1i * theta_path);      % 外层复平面圆
    zeta_path_L1 = map_func(z_path_L1, param);       % 内层映射后形状
    zeta_path_L2 = map_func(z_path_L2, param);       % 外层映射后形状
    
    % 提取坐标
    X1 = real(zeta_path_L1); Y1 = imag(zeta_path_L1);  % 内层XY坐标
    Z1 = Z_func(theta_path, param.w, param.m_pole, +param.Am); % 内层Z坐标（正调制）
    X2 = real(zeta_path_L2); Y2 = imag(zeta_path_L2);  % 外层XY坐标
    Z2 = Z_func(theta_path, param.w, param.m_pole, -param.Am); % 外层Z坐标（负调制）
    
    xyz1 = [X1', Y1', Z1']; % 组合内层坐标
    xyz2 = [X2', Y2', Z2']; % 组合外层坐标
    
    % 计算TNB标架
    fprintf('📊 计算TNB标架...\n');
    if tnb_method == 1 % 使用RMF算法
        full_data_1 = calculate_tnb_frames_pro(xyz1, output_params.show_progress);
        full_data_2 = calculate_tnb_frames_pro(xyz2, output_params.show_progress);
    else % 使用简化算法
        tnb1 = calculate_tnb_frames_v1(xyz1, output_params.show_progress);
        tnb2 = calculate_tnb_frames_v1(xyz2, output_params.show_progress);
        full_data_1 = [xyz1, tnb1];
        full_data_2 = [xyz2, tnb2];
    end
    
    % 保存和可视化
    result = save_and_visualize_cct(['linear_' shape_type], full_data_1, full_data_2, ...
                                    param.m_pole, param.turns);
end

% -------------------- 6. 弯曲拟多边形CCT生成函数 (新增) --------------------
function result = generate_bent_quasipolygonal_cct()
    fprintf('━━━ 生成弯曲拟多边形CCT线圈 ━━━\n');
    
    % 获取参数
    params = evalin('base', 'BENT_POLY_PARAMS');     % 获取弯曲多边形参数
    tnb_method = evalin('base', 'TNB_METHOD');       % 获取TNB计算方法
    output_params = evalin('base', 'OUTPUT_PARAMS'); % 获取输出控制参数
    
    % 根据数字选择形状类型
    shape_types = {'elliptic', 'triangular', 'square', 'quasipentagon', ...
                   'quasihexagon', 'quasiheptagon', 'quasioctagon', 'rectangular'}; % 形状类型数组
    
    if params.shape_type < 1 || params.shape_type > 8 % 验证形状类型
        error('形状类型必须是1-8之间的整数');
    end
    shape_type = shape_types{params.shape_type}; % 获取形状名称
    
    % 设置具体参数（使用预设或自定义）
    if params.override % 如果使用自定义参数
        % 使用自定义参数
        param = params.custom;
        param.R_bend = params.R_bend;
        param.bend_angle = params.bend_angle;
        param.layer_separation_factor = params.layer_separation_factor;
        param.points_per_turn = params.points_per_turn;
        fprintf('📐 使用自定义参数\n');
    else % 使用预设参数
        % 根据形状类型使用预设参数
        param.points_per_turn = params.points_per_turn;
        param.R_bend = params.R_bend;
        param.bend_angle = params.bend_angle;
        param.layer_separation_factor = params.layer_separation_factor;
        
        switch lower(shape_type)
            case 'elliptic' % 椭圆形
                param.c = 100; param.rho0 = 120; param.m_pole = 1; 
                param.w = 10; param.Am = 50; param.turns = 20;
            case 'triangular' % 三角形
                param.n_poly = 3; param.c = 100; param.rho0 = 65;
                param.m_pole = 3; param.w = 15; param.Am = 30; param.turns = 15;
            case 'square' % 正方形
                param.n_poly = 4; param.c = 100; param.rho0 = 50;
                param.m_pole = 2; param.w = 40; param.Am = 80; param.turns = 20;
            case 'quasipentagon' % 五边形
                param.n_poly = 5; param.c = 100; param.rho0 = 50;
                param.m_pole = 5; param.w = 10; param.Am = 50; param.turns = 20;
            case 'quasihexagon' % 六边形
                param.n_poly = 6; param.c = 28; param.rho0 = 16;
                param.m_pole = 3; param.w = 10; param.Am = 50; param.turns = 20;
            case 'quasiheptagon' % 七边形
                param.n_poly = 7; param.c = 100; param.rho0 = 55;
                param.m_pole = 7; param.w = 10; param.Am = 50; param.turns = 40;
            case 'quasioctagon' % 八边形
                param.n_poly = 8; param.c = 100; param.rho0 = 58;
                param.m_pole = 1; param.w = 10; param.Am = 80; param.turns = 40;
            case 'rectangular' % 矩形
                param.rho0 = 60; param.m_pole = 2; param.w = 10; 
                param.Am = 50; param.turns = 40;
            otherwise
                error('未知的多边形形状类型: %s', shape_type);
        end
    end
    
    % 打印参数信息
    fprintf('📐 生成【%s】形状的【%d极场】弯曲CCT线圈\n', shape_type, 2*param.m_pole);
    fprintf('  基础半径: %.1f mm, 调制幅度: %.1f mm\n', param.rho0, param.Am);
    fprintf('  弯曲半径: %.1f mm, 弯曲角度: %.2f°\n', param.R_bend, rad2deg(param.bend_angle));
    fprintf('  旋转角度: %.1f°\n\n', params.rotation_deg);
    
    % 定义映射函数（保形映射）
    if strcmpi(shape_type, 'elliptic') % 椭圆映射
        map_func = @(z, p) (z + p.c^2 ./ z) / 2;
    elseif strcmpi(shape_type, 'rectangular') % 矩形映射
        map_func = @(z, p) -z.^3 + z + 2./z;
    else % 多边形映射
        map_func = @(z, p) z.^(p.n_poly-1)/ p.c^(p.n_poly-2) + (p.c^2) ./ z;
    end
    
    % Z方向函数
    Z_func = @(theta, w, m, Am) (w / (2*pi)) * theta + Am * sin(m * theta);
    
    % 精确计算匝数以匹配弯曲弧长
    target_Z = param.R_bend * param.bend_angle;                     % 目标Z长度
    z_error_func = @(theta) Z_func(theta, param.w, param.m_pole, param.Am) - target_Z; % 误差函数
    theta_guess = (target_Z / param.w) * 2*pi;                      % 初始猜测
    options = optimset('TolX',1e-9, 'Display','off');               % 优化选项
    total_theta = fzero(z_error_func, theta_guess, options);        % 求解精确角度
    required_turns = total_theta / (2*pi);                          % 计算所需匝数
    
    fprintf('🔧 计算所需匝数: %.2f 匝 (对应弯曲角度 %.2f°)\n', required_turns, rad2deg(param.bend_angle));
    
    % 生成路径点
    total_points = ceil(required_turns * param.points_per_turn); % 总点数
    if total_points < 3 % 验证点数
        error('计算出的点数过少（至少需要3个点）');
    end
    
    theta_path = linspace(0, total_theta, total_points); % 角度数组
    
    % 生成未旋转的路径
    z_path_L1 = param.rho0 * exp(1i * theta_path);                            % 内层复平面圆
    z_path_L2 = (param.rho0 * param.layer_separation_factor) * exp(1i * theta_path); % 外层复平面圆
    
    % 应用保形映射
    zeta_path_L1_unrotated = map_func(z_path_L1, param); % 内层映射（未旋转）
    zeta_path_L2_unrotated = map_func(z_path_L2, param); % 外层映射（未旋转）
    
    % 应用旋转
    rotation_rad = deg2rad(params.rotation_deg);                   % 旋转角度（弧度）
    zeta_path_L1 = zeta_path_L1_unrotated * exp(1i * rotation_rad); % 内层旋转
    zeta_path_L2 = zeta_path_L2_unrotated * exp(1i * rotation_rad); % 外层旋转
    
    % 提取直线坐标
    X1 = real(zeta_path_L1); Y1 = imag(zeta_path_L1);                  % 内层XY坐标
    Z1 = Z_func(theta_path, param.w, param.m_pole, +param.Am);         % 内层Z坐标
    X2 = real(zeta_path_L2); Y2 = imag(zeta_path_L2);                  % 外层XY坐标
    Z2 = Z_func(theta_path, param.w, param.m_pole, -param.Am);         % 外层Z坐标
    
    % 直线路径
    path_data_1_straight = [X1', Y1', Z1']; % 内层直线坐标
    path_data_2_straight = [X2', Y2', Z2']; % 外层直线坐标
    
    % 应用弯曲变换（绕Y轴弯曲）
    fprintf('🔧 应用弯曲变换...\n');
    
    % 内层弯曲
    alpha1 = path_data_1_straight(:,3) / param.R_bend;                                   % 弯曲角度
    bent_Y1 = (param.R_bend + path_data_1_straight(:,2)) .* cos(alpha1) - param.R_bend;  % Y坐标变换
    bent_Z1 = (param.R_bend + path_data_1_straight(:,2)) .* sin(alpha1);                 % Z坐标变换
    final_path_1 = [path_data_1_straight(:,1), bent_Y1, bent_Z1];                        % 最终内层坐标
    
    % 外层弯曲
    alpha2 = path_data_2_straight(:,3) / param.R_bend;                                   % 弯曲角度
    bent_Y2 = (param.R_bend + path_data_2_straight(:,2)) .* cos(alpha2) - param.R_bend;  % Y坐标变换
    bent_Z2 = (param.R_bend + path_data_2_straight(:,2)) .* sin(alpha2);                 % Z坐标变换
    final_path_2 = [path_data_2_straight(:,1), bent_Y2, bent_Z2];                        % 最终外层坐标
    
    % 计算TNB标架
    fprintf('📊 计算最终TNB标架...\n');
    if tnb_method == 1 % 使用RMF算法
        full_data_1 = calculate_tnb_frames_pro(final_path_1, output_params.show_progress);
        full_data_2 = calculate_tnb_frames_pro(final_path_2, output_params.show_progress);
    else % 使用简化算法
        tnb1 = calculate_tnb_frames_v1(final_path_1, output_params.show_progress);
        tnb2 = calculate_tnb_frames_v1(final_path_2, output_params.show_progress);
        full_data_1 = [final_path_1, tnb1];
        full_data_2 = [final_path_2, tnb2];
    end
    
    % 保存和可视化
    result = save_and_visualize_cct(['bent_' shape_type], full_data_1, full_data_2, ...
                                    param.m_pole, required_turns);
end

%% ==================== 数据保存和可视化函数 ====================

function result = save_and_visualize_cct(type_name, full_data_1, full_data_2, n_pole, turns)
    % 统一的数据保存和可视化函数
    
    % 获取输出控制参数
    output_params = evalin('base', 'OUTPUT_PARAMS');
    
    % 创建结果结构体
    result.type = type_name;       % 保存线圈类型
    result.layer1 = full_data_1;    % 保存内层数据
    result.layer2 = full_data_2;    % 保存外层数据
    result.n_pole = n_pole;         % 保存极数
    result.turns = turns;           % 保存匝数
    
    % 保存文件
    if output_params.save_files
        fprintf('\n💾 保存数据文件...\n');
        
        % 保存完整路径数据（包含TNB）
        filename1 = sprintf('%s_cct_layer1_path_mm.txt', type_name); % 内层文件名
        filename2 = sprintf('%s_cct_layer2_path_mm.txt', type_name); % 外层文件名
        
        % 写入文件（使用指定精度）
        writematrix(full_data_1, filename1, 'Delimiter', '\t'); % 写入内层数据
        writematrix(full_data_2, filename2, 'Delimiter', '\t'); % 写入外层数据
        fprintf('  ✅ 完整路径: %s, %s\n', filename1, filename2);
        
        % 保存仅XYZ坐标
        xyz_file1 = sprintf('%s_cct_layer1_xyz_mm.txt', type_name);     % 内层XYZ文件名
        xyz_file2 = sprintf('%s_cct_layer2_xyz_mm.txt', type_name);     % 外层XYZ文件名
        writematrix(full_data_1(:,1:3), xyz_file1, 'Delimiter', ',');   % 写入内层XYZ
        writematrix(full_data_2(:,1:3), xyz_file2, 'Delimiter', ',');   % 写入外层XYZ
        fprintf('  ✅ XYZ坐标: %s, %s\n', xyz_file1, xyz_file2);
        
        % 保存MAT文件
        if output_params.save_mat_file
            mat_filename = sprintf('%s_cct_data.mat', type_name);       % MAT文件名
            save(mat_filename, 'full_data_1', 'full_data_2', 'n_pole', 'turns'); % 保存变量
            fprintf('  ✅ MAT文件: %s\n', mat_filename);
        end
    end
    
    % 显示图形
    if output_params.show_plots
        fprintf('\n📊 生成可视化...\n');
        
        % 创建高质量图形
        figure('Name', sprintf('CCT线圈: %s', strrep(type_name, '_', ' ')), ... % 图形标题
               'Position', [50, 50, 1400, 700], 'Color', 'w');                  % 窗口位置和大小
        
        % 设置图形质量
        if strcmpi(output_params.plot_quality, 'high')
            set(gcf, 'Renderer', 'opengl');        % 使用OpenGL渲染器
            set(gcf, 'GraphicsSmoothing', 'on');   % 开启图形平滑
        end
        
        % 主3D视图
        subplot(2,2,[1,3]); % 占据左侧两个位置
        hold on;
        
        % 绘制线圈路径
        h1 = plot3(full_data_1(:,1), full_data_1(:,2), full_data_1(:,3), ...
              'r-', 'LineWidth', 2.5, 'DisplayName', '内层线圈'); % 绘制内层
        h2 = plot3(full_data_2(:,1), full_data_2(:,2), full_data_2(:,3), ...
              'b-', 'LineWidth', 2.5, 'DisplayName', '外层线圈'); % 绘制外层
        
        % 绘制TNB标架矢量
        if output_params.plot_tnb_vectors && size(full_data_1, 2) == 12
            skip = max(1, floor(size(full_data_1, 1) / output_params.tnb_vector_skip)); % 计算跳过间隔
            scale = output_params.tnb_vector_scale;                                      % 获取缩放比例
            
            for i = 1:skip:size(full_data_1, 1) % 每隔skip个点绘制一次
                pos = full_data_1(i, 1:3);    % 当前点位置
                T = full_data_1(i, 4:6) * scale;  % 切向矢量
                N = full_data_1(i, 7:9) * scale;  % 法向矢量
                B = full_data_1(i, 10:12) * scale; % 副法向矢量
                
                % 绘制切向矢量（红色）
                quiver3(pos(1), pos(2), pos(3), T(1), T(2), T(3), 0, ...
                        'r', 'LineWidth', 0.5, 'MaxHeadSize', 0.3, 'HandleVisibility', 'off');
                % 绘制法向矢量（绿色）
                quiver3(pos(1), pos(2), pos(3), N(1), N(2), N(3), 0, ...
                        'g', 'LineWidth', 0.5, 'MaxHeadSize', 0.3, 'HandleVisibility', 'off');
                % 绘制副法向矢量（蓝色）
                quiver3(pos(1), pos(2), pos(3), B(1), B(2), B(3), 0, ...
                        'b', 'LineWidth', 0.5, 'MaxHeadSize', 0.3, 'HandleVisibility', 'off');
            end
            
            % 添加图例项
            plot3(NaN, NaN, NaN, 'r-', 'LineWidth', 1, 'DisplayName', 'T (切向)');
            plot3(NaN, NaN, NaN, 'g-', 'LineWidth', 1, 'DisplayName', 'N (法向)');
            plot3(NaN, NaN, NaN, 'b-', 'LineWidth', 1, 'DisplayName', 'B (副法向)');
        end
        
        % 判断是否为弯曲线圈
        if contains(type_name, 'bent') || contains(type_name, 'curved')
            title_suffix = '(弯曲)';
        else
            title_suffix = '(直线)';
        end
        
        % 设置标题和标签
        title(sprintf('%s CCT线圈 %s (%d极场, %.1f匝)', ...
              strrep(type_name, '_', ' '), title_suffix, 2*n_pole, turns), ...
              'FontSize', 14, 'FontWeight', 'bold');
        xlabel('X (mm)', 'FontSize', 12);
        ylabel('Y (mm)', 'FontSize', 12);
        zlabel('Z (mm)', 'FontSize', 12);
        
        axis equal; grid on; box on;  % 设置坐标轴属性
        view(135, 30);                 % 设置视角
        lighting phong;                % 设置光照
        camlight('headlight');         % 添加相机光源
        material dull;                 % 设置材质
        legend('Location', 'best', 'FontSize', 10); % 显示图例
        
        % XY平面投影
        subplot(2,2,2); % 右上角
        hold on;
        plot(full_data_1(:,1), full_data_1(:,2), 'r-', 'LineWidth', 2); % 内层投影
        plot(full_data_2(:,1), full_data_2(:,2), 'b-', 'LineWidth', 2); % 外层投影
        title('XY平面投影', 'FontSize', 12, 'FontWeight', 'bold');
        xlabel('X (mm)', 'FontSize', 11);
        ylabel('Y (mm)', 'FontSize', 11);
        axis equal; grid on;
        legend('内层', '外层', 'Location', 'best');
        
        % XZ平面投影
        subplot(2,2,4); % 右下角
        hold on;
        plot(full_data_1(:,1), full_data_1(:,3), 'r-', 'LineWidth', 2); % 内层投影
        plot(full_data_2(:,1), full_data_2(:,3), 'b-', 'LineWidth', 2); % 外层投影
        title('XZ平面投影', 'FontSize', 12, 'FontWeight', 'bold');
        xlabel('X (mm)', 'FontSize', 11);
        zlabel('Z (mm)', 'FontSize', 11);
        axis equal; grid on;
        legend('内层', '外层', 'Location', 'best');
    end
    
    % 打印统计信息
    fprintf('\n📈 统计信息:\n');
    fprintf('  线圈类型: %s\n', strrep(type_name, '_', ' '));
    fprintf('  数据点数: %d\n', size(full_data_1, 1));
    fprintf('  内层路径长度: %.2f mm\n', calculate_path_length(full_data_1(:,1:3)));
    fprintf('  外层路径长度: %.2f mm\n', calculate_path_length(full_data_2(:,1:3)));
    fprintf('  坐标范围:\n');
    fprintf('    X: [%.2f, %.2f] mm\n', min(full_data_1(:,1)), max(full_data_1(:,1)));
    fprintf('    Y: [%.2f, %.2f] mm\n', min(full_data_1(:,2)), max(full_data_1(:,2)));
    fprintf('    Z: [%.2f, %.2f] mm\n', min(full_data_1(:,3)), max(full_data_1(:,3)));
    
    % 计算线圈体积估算
    volume_est = estimate_coil_volume(full_data_1(:,1:3), full_data_2(:,1:3));
    fprintf('  线圈体积估算: %.2f mm³\n', volume_est);
    
    fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
end

% ==================== 辅助函数 ====================

% 计算路径长度
function path_length = calculate_path_length(xyz_coords)
    diffs = diff(xyz_coords);                % 计算相邻点的差值
    distances = sqrt(sum(diffs.^2, 2));      % 计算每段的欧氏距离
    path_length = sum(distances);            % 累加得到总长度
end

% 估算线圈体积
function volume = estimate_coil_volume(xyz1, xyz2)
    % 简单估算：使用包围盒体积
    min1 = min(xyz1); max1 = max(xyz1);      % 内层最小最大值
    min2 = min(xyz2); max2 = max(xyz2);      % 外层最小最大值
    
    min_all = min([min1; min2]);             % 总体最小值
    max_all = max([max1; max2]);             % 总体最大值
    
    volume = prod(max_all - min_all);        % 计算包围盒体积
end