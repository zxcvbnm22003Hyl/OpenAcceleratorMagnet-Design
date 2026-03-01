% =========================================================================
% W7-X Style Modular Coil Generator (Topological Demo)
% 基于逆向流函数法 (Inverse Stream Function Method)
% =========================================================================
clear; clc; close all;

%% 1. W7-X 几何参数定义 (简化版拓扑)
% W7-X 是 5 周期对称结构
N_periods = 5;      
R0 = 5.5;           % 大半径 [m]
a_minor = 0.53;     % 平均小半径 [m] (用于定义绕组面)

% --- 定义扭曲的等离子体/绕组表面 ---
% 我们使用参数方程构建一个具有 "豆形 (Bean-shape)" 和 "椭圆度 (Elongation)" 的旋转环面
% u: 极向角 (Poloidal), v: 环向角 (Toroidal)

Nu = 200;           % 极向分辨率
Nv = 720;           % 环向分辨率 (对应一个完整圆周)
u = linspace(0, 2*pi, Nu); 
v = linspace(0, 2*pi, Nv);
[U, V] = meshgrid(u, v);

% --- 表面调制参数 (模拟 W7-X 的 3D 形状) ---
% 1. 螺旋轴偏移 (Helical Axis Excursion)
Delta_R = 0.3 * cos(N_periods * V); 
Delta_Z = 0.3 * sin(N_periods * V);

% 2. 截面形状调制 (Rotating Ellipse/Bean)
% 这是一个简化的 rotating elongation 模型
Elongation = 1.0 + 0.4 * cos(N_periods * V); % 截面拉长程度随环向变化
Rotation   = -0.5 * sin(N_periods * V);      % 截面旋转

% --- 构建 3D 表面坐标 (X, Y, Z) ---
% 局部坐标 (r, z_loc)
r_loc = a_minor .* (cos(U) + 0.2*cos(2*U)); % 添加一点豆形因子 (cos(2u))
z_loc = a_minor .* sin(U) .* Elongation;

% 旋转局部坐标
r_rot = r_loc .* cos(Rotation) - z_loc .* sin(Rotation);
z_rot = r_loc .* sin(Rotation) + z_loc .* cos(Rotation);

% 转换到全局环面坐标
R_surf = R0 + Delta_R + r_rot;
Z_surf =      Delta_Z + z_rot;

X = R_surf .* cos(V);
Y = R_surf .* sin(V);
Z = Z_surf;

%% 2. 定义模块化线圈的流函数 (Stream Function)
% 对于模块化线圈，我们寻找的是 "变形的切面"。
% 基础势函数：S = v (环向角)。
% 如果 S = const，我们得到通过轴线的平面 (普通 TF 线圈)。
% 我们要给 S 加上扰动：S = v + G(u,v)

% --- 关键：线圈扭曲函数 (Warping Function) ---
% 这些系数决定了线圈有多"扭曲"。在 NESCOIL 中，这些是通过优化 B_normal=0 算出来的。
% 这里我们手动设定一些典型的谐波来模拟 W7-X 的外观。

Warping = 0.35 * sin(U - N_periods*V) ...   % 主螺旋项 (模拟螺旋绕组效应)
        + 0.15 * sin(2*U - N_periods*V) ... % 高阶整形
        + 0.10 * sin(U);                    % 极向修正

% 最终流函数 (Stream Function)
% 我们希望线圈均匀分布在环向，所以 Coil_Index ~ v + Warping
Current_Potential = V - Warping;

%% 3. 提取线圈路径 (Contour Method)
fprintf('正在提取模块化线圈路径...\n');

% 设定要生成的线圈数量 (比如 50 个线圈均分 360 度)
Num_Coils = 50; 
coil_levels = linspace(0, 2*pi, Num_Coils+1); 
coil_levels(end) = []; % 去掉重复的末端

% 使用 contourc 在 (u,v) 空间寻找等值线
C = contourc(v, u, Current_Potential', coil_levels); 
% 注意：contourc 的输入 x,y 对应 v,u，因为 Current_Potential 转置了

Wire_Paths = {}; % 存储所有线圈数据

idx = 1;
limit_counter = 0;
while idx < size(C, 2)
    lvl = C(1, idx);
    n_pts = C(2, idx);
    idx = idx + 1;
    
    v_c = C(1, idx:idx+n_pts-1); % 提取的环向角 v
    u_c = C(2, idx:idx+n_pts-1); % 提取的极向角 u
    
    % --- 数据清洗与映射 ---
    % 1. 映射回 3D 空间
    x_coil = interp2(U, V, X, u_c, v_c, 'spline');
    y_coil = interp2(U, V, Y, u_c, v_c, 'spline');
    z_coil = interp2(U, V, Z, u_c, v_c, 'spline');
    
    % 2. 闭合线圈 (首尾相连)
    % contourc 生成的闭合线圈未必首尾重合，手动闭合
    x_coil = [x_coil, x_coil(1)];
    y_coil = [y_coil, y_coil(1)];
    z_coil = [z_coil, z_coil(1)];
    
    Wire_Paths{end+1} = [x_coil; y_coil; z_coil];
    
    idx = idx + n_pts;
    limit_counter = limit_counter + 1;
end

%% 4. 可视化结果
figure('Color', 'k', 'Position', [100 100 1200 800]);

% --- 绘制等离子体表面 (半透明幽灵模式) ---
s = surf(X, Y, Z, 'EdgeColor', 'none', 'FaceColor', [0.2 0.8 1.0]);
s.FaceAlpha = 0.15;
hold on; axis equal; axis off;
lighting gouraud; 
material shiny;
camlight('headlight');
camlight('left');

% --- 绘制模块化线圈 ---
% 根据周期性给线圈上色，模拟 W7-X 的模块分组
Colormap_W7X = parula(N_periods); 

for i = 1:length(Wire_Paths)
    pts = Wire_Paths{i};
    
    % 计算该线圈属于哪个周期 (粗略计算重心角度)
    mean_angle = atan2(mean(pts(2,:)), mean(pts(1,:)));
    if mean_angle < 0, mean_angle = mean_angle + 2*pi; end
    period_idx = ceil(mean_angle / (2*pi/N_periods));
    if period_idx < 1, period_idx = 1; end
    if period_idx > N_periods, period_idx = N_periods; end
    
    % 绘制管状线圈 (简单用 plot3，实际可以用 tubeplot)
    plot3(pts(1,:), pts(2,:), pts(3,:), ...
        'Color', [1 0.7 0.2], 'LineWidth', 2); % 金色线圈
end

% 装饰
title('W7-X Style Modular Coils Simulation', 'Color', 'w', 'FontSize', 16);
subtitle('Generated via Inverse Stream Function Mapping', 'Color', [0.8 0.8 0.8]);
view(3); rotate3d on;

% 增加辉光效果 (如果是 2020b 以上版本)
try
    exportgraphics(gcf, 'W7X_Sim.png', 'BackgroundColor', 'k');
end