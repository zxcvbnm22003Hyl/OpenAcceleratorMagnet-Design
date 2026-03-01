% =========================================================================
% Corrected_Saddle_Magnet.m
% 功能：生成基于双曲抛物面 (Hyperbolic Paraboloid) 的跑道型超导线圈
% 应用：模拟超导二极管/四极管的端部 (Coil Ends)
% =========================================================================

clear; clc; close all;

%% 1. 定义物理表面 (双曲抛物面)
% ---------------------------------------------------------
% 方程: z = (x^2 - y^2) / c
% 这是一个直纹面，也是唯一的双重平移面，非常适合工程绕制
c = 2.5;             % 曲率系数 (越大越平缓)
L_range = 1.2;       % 空间范围

[U, V] = meshgrid(linspace(-L_range, L_range, 100));
X_surf = U;
Y_surf = V;
Z_surf = (U.^2 - V.^2) / c;

%% 2. 设计 2D 跑道型线圈 (Racetrack Coil)
% ---------------------------------------------------------
% 在 UV 参数平面上设计闭合线圈
% 使用超椭圆方程: (x/a)^n + (y/b)^n = 1
N_turns = 10;        % 线圈匝数
t = linspace(0, 2*pi, 500); % 参数 t

% 线圈几何参数
Coil_Width = 0.7;    % 跑道宽度 (a)
Coil_Height = 0.4;   % 跑道高度 (b)
Sqaureness = 4;      % 方形系数 (2=圆/椭圆, >2=圆角矩形)

% 初始化 3D 线圈数组
coils_x = {}; coils_y = {}; coils_z = {};

for i = 1:N_turns
    % 让每一匝稍微向外扩张一点 (模拟多层线圈)
    scale = 1.0 + (i-1)*0.05; 
    
    a = Coil_Width * scale;
    b = Coil_Height * scale;
    
    % 超椭圆参数方程
    % sign 函数用于处理任意象限的符号
    u_coil = a * sign(cos(t)) .* abs(cos(t)).^(2/Sqaureness);
    v_coil = b * sign(sin(t)) .* abs(sin(t)).^(2/Sqaureness);
    
    % --- 核心：保角/直接映射到 3D 表面 ---
    x_c = u_coil;
    y_c = v_coil;
    z_c = (x_c.^2 - y_c.^2) / c;
    
    coils_x{i} = x_c;
    coils_y{i} = y_c;
    coils_z{i} = z_c;
end

%% 3. 可视化
% ---------------------------------------------------------
figure('Color', 'w', 'Position', [100 100 1000 600]);

% 绘制半透明马鞍面
surf(X_surf, Y_surf, Z_surf, 'FaceColor', [0.9 0.9 0.9], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold on;

% 绘制线圈
for i = 1:N_turns
    plot3(coils_x{i}, coils_y{i}, coils_z{i}, ...
        'LineWidth', 2, 'Color', 'r'); % 红色线圈
end

% 美化
title(['修正版马鞍面磁体 (Hyperbolic Paraboloid)', newline, ...
       '闭合跑道型线圈 (Closed Racetrack Coils)'], 'FontSize', 12);
xlabel('X (Width)'); ylabel('Y (Length)'); zlabel('Z (Height)');
axis equal; grid on; box on;
view(45, 30);
camlight; lighting gouraud;

% 添加注释：说明为什么这样设计
text(0, 0, max(Z_surf(:))+0.2, 'Beam Axis (束流轴)', ...
    'HorizontalAlignment', 'center', 'Color', 'b');