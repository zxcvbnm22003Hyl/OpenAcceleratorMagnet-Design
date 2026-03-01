% =================================================================================================
%   ULTRA SCRIPT: 通用CCT线圈.cond文件生成器 (for Opera)
% =================================================================================================
%   功能描述:
%   本脚本是一个高度集成和可配置的工具，用于为Opera电磁仿真软件生成CCT（Canted-Cosine-Theta）
%   线圈的导体定义文件（.cond）。它整合了多种功能，用户只需通过修改配置区的参数，即可实现：
%
%   1.  截面形状选择: 支持 'rectangular' (矩形) 和 'circular' (圆形) 两种导线截面。
%   2.  输出模式控制: 支持 'combined' (将内外两层线圈合并到一个文件) 和
%                      'separate' (为内外两层线圈分别生成独立文件) 两种输出方式。
%   3.  灵活参数定义: 所有物理和几何参数（如尺寸、电流、文件名等）均可在配置区轻松设定。
%
%   使用方法:
%   1.  将此脚本与路径数据文件（例如 'linear_cct_layer1_inner_path_log_mm.txt'）放在同一目录下。
%   2.  根据您的需求，修改下面的 "核心用户配置区"。
%   3.  运行此MATLAB脚本。
% =================================================================================================

%% 1. 初始化环境 (Environment Initialization)
% -------------------------------------------------------------------------------------------------
clear; clc; close all;
fprintf('====================================================\n');
fprintf('      CCT线圈 .cond 文件通用生成脚本 (ULTRA)      \n');
fprintf('====================================================\n\n');

%% 2. 核心用户配置区 (CORE USER CONFIGURATION)
% -------------------------------------------------------------------------------------------------
% --- 模式选择 (Mode Selection) ---
options.cross_section_shape = 'rectangular';  % 导线截面形状: 'rectangular' (矩形) 或 'circular' (圆形)
options.output_mode         = 'combined';     % 输出模式: 'combined' (合并输出) 或 'separate' (分开输出)

% --- 几何尺寸 (Geometric Dimensions) [单位: 米] ---
% (1) 当 cross_section_shape = 'rectangular' 时，以下参数生效
options.coil_width  = 2;   % 矩形导线宽度 (mm)
options.coil_height = 4.5;  % 矩形导线高度/厚度 (mm)

% (2) 当 cross_section_shape = 'circular' 时，以下参数生效
options.coil_radius = 1.5; % 圆形导线半径 (m)

% --- 电学参数 (Electrical Parameters) ---
options.current          = 500;  % 总电流 (A)
options.material_index   = 1;    % 材料索引 (对应Opera中的材料库)
options.drive_name_inner = "'drive_1'"; % 内层驱动电路名称 (注意: 必须是带单引号的字符串)
options.drive_name_outer = "'drive_2'"; % 外层驱动电路名称 (注意: 必须是带单引号的字符串)

% --- 文件路径与名称 (File Paths & Names) ---
% (1) 输入的路径数据文件名
options.input_path_file_inner = 'path_layer1_inner_sqrt_mm.txt';
options.input_path_file_outer = 'path_layer2_outer_sqrt_mm.txt';

% (2) 输出的.cond文件名
%    - 若为 'combined' 模式, output_file_combined 生效
options.output_file_combined = 'CCT_Coil_Combined.cond';
%    - 若为 'separate' 模式, output_file_inner 和 output_file_outer 生效
options.output_file_inner = 'CCT_Coil_Layer1_Inner.cond';
options.output_file_outer = 'CCT_Coil_Layer2_Outer.cond';
% -------------------------------------------------------------------------------------------------

%% 3. 参数预处理与配置确认 (Parameter Pre-processing & Confirmation)
% -------------------------------------------------------------------------------------------------
% --- 根据截面形状计算电流密度 ---
fprintf('--- 脚本配置确认 ---\n');
fprintf('截面形状: %s\n', options.cross_section_shape);
fprintf('输出模式: %s\n', options.output_mode);

switch options.cross_section_shape
    case 'rectangular'
        cross_section_area = options.coil_width * options.coil_height;
        if cross_section_area == 0
            error('矩形截面面积为零，请检查 coil_width 和 coil_height 的设置！');
        end
        current_density_magnitude = options.current / cross_section_area;
        fprintf('导线尺寸: 宽度 %.4f m, 高度 %.4f m\n', options.coil_width, options.coil_height);
        
    case 'circular'
        cross_section_area = pi * options.coil_radius^2;
        if cross_section_area == 0
            error('圆形截面面积为零，请检查 coil_radius 的设置！');
        end
        current_density_magnitude = options.current / cross_section_area;
        fprintf('导线尺寸: 半径 %.4f m\n', options.coil_radius);
        
    otherwise
        error("无效的截面形状 '%s'！请选择 'rectangular' 或 'circular'。", options.cross_section_shape);
end

fprintf('总 电 流: %.1f A\n', options.current);
fprintf('截面面积: %.6f m^2\n', cross_section_area);
fprintf('电流密度: %.3e A/m^2\n', current_density_magnitude);
fprintf('--------------------------\n\n');

%% 4. 主程序：生成 .cond 文件 (Main Program: Generate .cond files)
% -------------------------------------------------------------------------------------------------
% --- 主循环，处理每一层线圈 ---
for layer_index = 1:2
    
    % --- Step 4.1: 为当前层配置输入/输出参数 ---
    if layer_index == 1
        disp('>>> 开始处理: 内层 inner (Layer 1)');
        input_path_file = options.input_path_file_inner;
        current_density = current_density_magnitude; % 定义为正方向
        current_drive_name = options.drive_name_inner; % 分配内层 drive
        if strcmp(options.output_mode, 'separate')
            output_cond_file = options.output_file_inner;
        else
            output_cond_file = options.output_file_combined;
        end
        fprintf('电流方向: 正, Drive Label: %s\n', current_drive_name);
    else % layer_index == 2
        fprintf('\n'); % 增加换行，使得输出更清晰
        disp('>>> 开始处理: 外层 outer (Layer 2)');
        input_path_file = options.input_path_file_outer;
        current_density = -current_density_magnitude; % 定义为负方向
        current_drive_name = options.drive_name_outer; % 分配外层 drive
        if strcmp(options.output_mode, 'separate')
            output_cond_file = options.output_file_outer;
        else
            output_cond_file = options.output_file_combined;
        end
        fprintf('电流方向: 负, Drive Label: %s\n', current_drive_name);
    end
    fprintf('读取路径文件: %s\n', input_path_file);
    fprintf('写入目标文件: %s\n', output_cond_file);

    % --- Step 4.2: 文件操作：打开 .cond 文件并写入文件头 ---
    if strcmp(options.output_mode, 'separate') || (strcmp(options.output_mode, 'combined') && layer_index == 1)
        % 分开模式下，每层都新开一个文件；合并模式下，只在处理第一层时新开文件
        fprintf('正在创建并打开文件: %s\n', output_cond_file);
        fileID = fopen(output_cond_file, 'w'); % 'w'模式会覆盖旧文件
        if fileID == -1, error('无法打开文件进行写入: %s', output_cond_file); end
        fprintf(fileID, 'CONDUCTOR\n'); % 写入Opera导体定义命令
    end

    % --- Step 4.3: 加载路径数据 ---
    fprintf('正在加载路径数据...\n');
    try
        full_path_data = readmatrix(input_path_file);
    catch
        error('加载文件 "%s" 失败！请确保文件存在且格式正确。', input_path_file);
    end
    num_points = size(full_path_data, 1);
    if size(full_path_data, 2) < 12
        error('文件 "%s" 必须是12列格式！此脚本需要完整的Frenet标架信息 (P, T, N, B)。', input_path_file);
    end

    % --- Step 4.4: 核心循环 - 生成所有BR20单元并写入文件 ---
    fprintf('正在为当前层生成 %d 个 BR20 单元...\n', num_points - 1);
    for i = 1:(num_points - 1)
        % 1. 提取路径点 i 和 i+1 的完整几何信息 (P:位置, T:切向, N:法向, B:副法向)
        p1 = full_path_data(i, 1:3);   T1 = full_path_data(i, 4:6);
        n1 = full_path_data(i, 7:9);   b1 = full_path_data(i, 10:12);
        
        p2 = full_path_data(i+1, 1:3); T2 = full_path_data(i+1, 4:6);
        n2 = full_path_data(i+1, 7:9); b2 = full_path_data(i+1, 10:12);

        % 2. 【几何核心 A】根据截面形状，定义前后两个截面上的8个基础角点
        vertices = zeros(20, 3);
        switch options.cross_section_shape
            case 'rectangular'
                % 对于矩形，角点就是截面的四个顶点
                c1 = p1 - options.coil_width/2*n1 - options.coil_height/2*b1; % 前截面-左下
                c2 = p1 + options.coil_width/2*n1 - options.coil_height/2*b1; % 前截面-右下
                c3 = p1 + options.coil_width/2*n1 + options.coil_height/2*b1; % 前截面-右上
                c4 = p1 - options.coil_width/2*n1 + options.coil_height/2*b1; % 前截面-左上
                
                c5 = p2 - options.coil_width/2*n2 - options.coil_height/2*b2; % 后截面-左下
                c6 = p2 + options.coil_width/2*n2 - options.coil_height/2*b2; % 后截面-右下
                c7 = p2 + options.coil_width/2*n2 + options.coil_height/2*b2; % 后截面-右上
                c8 = p2 - options.coil_width/2*n2 + options.coil_height/2*b2; % 后截面-左上
                
                % 角点 (XP1..XP8)
                vertices(1, :) = c2; vertices(2, :) = c3; vertices(3, :) = c4; vertices(4, :) = c1;
                vertices(5, :) = c6; vertices(6, :) = c7; vertices(7, :) = c8; vertices(8, :) = c5;
                
                % 截面中点 (XP9,10,11,12 & XP17,18,19,20)
                vertices(9, :)  = (vertices(1,:) + vertices(2,:)) / 2;
                vertices(10, :) = (vertices(2,:) + vertices(3,:)) / 2;
                vertices(11, :) = (vertices(3,:) + vertices(4,:)) / 2;
                vertices(12, :) = (vertices(4,:) + vertices(1,:)) / 2;
                vertices(17, :) = (vertices(5,:) + vertices(6,:)) / 2;
                vertices(18, :) = (vertices(6,:) + vertices(7,:)) / 2;
                vertices(19, :) = (vertices(7,:) + vertices(8,:)) / 2;
                vertices(20, :) = (vertices(8,:) + vertices(5,:)) / 2;
                
            case 'circular'
                % 对于圆形，用8个分布在圆周上的点来近似。BR20单元会将其拟合为二次曲面。
                % 0, 90, 180, 270度作为"角点"，45, 135, 225, 315度作为"中点"。
                angles = (0:45:315) * pi/180; % 0, 45, 90, ..., 315 度
                
                % 前截面点
                p1_pts = p1 + options.coil_radius * (cos(angles)'*n1 + sin(angles)'*b1);
                % 后截面点
                p2_pts = p2 + options.coil_radius * (cos(angles)'*n2 + sin(angles)'*b2);
                
                % 角点 (XP1..XP8)，对应 0, 90, 180, 270 度
                vertices(1, :) = p1_pts(1,:); vertices(2, :) = p1_pts(3,:); vertices(3, :) = p1_pts(5,:); vertices(4, :) = p1_pts(7,:);
                vertices(5, :) = p2_pts(1,:); vertices(6, :) = p2_pts(3,:); vertices(7, :) = p2_pts(5,:); vertices(8, :) = p2_pts(7,:);
                
                % 截面中点 (XP9.. & XP17..)，对应 45, 135, 225, 315 度
                vertices(9, :) = p1_pts(2,:); vertices(10, :) = p1_pts(4,:); vertices(11, :) = p1_pts(6,:); vertices(12, :) = p1_pts(8,:);
                vertices(17, :) = p2_pts(2,:); vertices(18, :) = p2_pts(4,:); vertices(19, :) = p2_pts(6,:); vertices(20, :) = p2_pts(8,:);
        end
        
        % 3. 【几何核心 B】计算路径修正量，用于校正弯曲单元侧边中点的位置
        L = norm(p2 - p1); % 计算两路径点之间的弦长
        path_correction = L/8 * (T1 - T2); % Opera BR20单元的二阶修正项

        % 4. 【几何核心 C】计算连接前后截面的4条棱边中点 (XP13,14,15,16)，并应用路径修正
        vertices(13, :) = (vertices(1,:) + vertices(5,:))/2 + path_correction;
        vertices(14, :) = (vertices(2,:) + vertices(6,:))/2 + path_correction;
        vertices(15, :) = (vertices(3,:) + vertices(7,:))/2 + path_correction;
        vertices(16, :) = (vertices(4,:) + vertices(8,:))/2 + path_correction;
        
        % 5. 【文件写入】将20个顶点坐标和物理参数格式化后写入文件
        fprintf(fileID, 'DEFINE BR20\n');
        fprintf(fileID, '0.0 0.0 0.0 0.0 0.0 0.0\n');
        fprintf(fileID, '0.0 0.0 0.0\n');
        fprintf(fileID, '0.0 0.0 0.0\n');
        fprintf(fileID, '%.8f %.8f %.8f\n', vertices'); % .8f保证精度
        % 使用动态分配的 current_drive_name 写入文件
        fprintf(fileID, '%.8e %d %s\n', current_density, options.material_index, current_drive_name);
        fprintf(fileID, '0 0 0\n');
        fprintf(fileID, '0.0\n');
    end
    
    fprintf('第 %d 层数据处理完毕。\n', layer_index);

    % --- Step 4.5: 文件操作：关闭文件 ---
    if strcmp(options.output_mode, 'separate') || (strcmp(options.output_mode, 'combined') && layer_index == 2)
        % 分开模式下，每层处理完都关闭文件；合并模式下，处理完最后一层才关闭
        fprintf(fileID, 'QUIT\n'); % 写入文件结束符
        fclose(fileID);
        fprintf('成功写入文件: %s\n', output_cond_file);
    end
    disp('----------------------------------------------------');
end

%% 5. 脚本执行完毕
% -------------------------------------------------------------------------------------------------
fprintf('\n脚本执行完毕！\n');