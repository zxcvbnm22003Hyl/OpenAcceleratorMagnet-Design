% =========================================================================
% ManifoldDCT_Demo.m
% 基于黎曼流形保角映射的广义 DCT 磁体生成演示
% 支持：1. 螺旋面 (Helicoid) - 用于螺旋加速器/FFAG
%       2. 马鞍面 (Enneper)  - 用于复杂聚焦/偏转磁体
% =========================================================================

clear; clc; close all;

%% 1. 参数配置
% -------------------------------------------------------------------------
% 选择流形类型: 'Helicoid' (螺旋面) 或 'Enneper' (马鞍面)
Manifold_Type = 'Enneper'; 

% 磁场参数 (在 2D 展开平面上的定义)
m_pole = 2;          % 多极数 (2=Dipole场, 3=Quadrupole场...)
N_turns = 5;        % 匝数
Wire_Width = 0.05;   % 视觉上的线宽

% 网格精度
Nu = 100; Nv = 360;

%% 2. 构建保角参数空间 (Conformal UV Domain)
% -------------------------------------------------------------------------
% 这里的 (u, v) 是平直的二维平面，满足拉普拉斯方程
% 所有的物理场计算都在这个平面上完成

if strcmp(Manifold_Type, 'Helicoid')
    % 螺旋面参数范围
    u_range = linspace(-2, 2, Nu);   % 径向参数 (对应 sinh 变换)
    v_range = linspace(0, 2*pi, Nv); % 螺旋角度 (2圈)
    c_const = 10.0;                   % 螺旋节距参数
    
elseif strcmp(Manifold_Type, 'Enneper')
    % 马鞍面参数范围
    u_range = linspace(-1.5, 1.5, Nu);
    v_range = linspace(-1.5, 1.5, Nv);
    c_const = 1.0; % 缩放因子
end

[U, V] = meshgrid(u_range, v_range);

%% 3. 在 UV 平面上设计流函数 (Stream Function)
% -------------------------------------------------------------------------
% 在保角映射下，平直空间的正弦波映射到流形上即为测地线调制的余弦线圈

% 定义流函数 Psi = cos(m*v + k*u) 
% v 对应角向，u 对应轴向/径向
if strcmp(Manifold_Type, 'Helicoid')
    % 螺旋面：沿着螺旋方向 v 进行调制
    Psi = cos(m_pole/2 * V) .* cos(pi * U / max(abs(u_range))); 
else
    % 马鞍面：生成双曲型线圈分布
    Psi = sin(m_pole * atan2(V, U)) .* (U.^2 + V.^2); 
    % 或者简单的波纹： Psi = cos(4*U) .* cos(4*V);
end

% 归一化流函数
Psi = Psi / max(abs(Psi(:)));

%% 4. 执行流形映射 (Mapping to 3D Manifold)
% -------------------------------------------------------------------------
% 关键步骤：将 (u, v) 映射到 (x, y, z)
% 必须保证度规 ds^2 = lambda^2 (du^2 + dv^2) 以维持保角性

X = zeros(size(U)); Y = zeros(size(U)); Z = zeros(size(U));

if strcmp(Manifold_Type, 'Helicoid')
    % --- 螺旋面保角参数化 ---
    % x = c * sinh(u) * cos(v)
    % y = c * sinh(u) * sin(v)
    % z = c * v
    % 这里的 u 不是半径 r，而是 r = c*sinh(u) 的反变换
    
    X = c_const * sinh(U) .* cos(V);
    Y = c_const * sinh(U) .* sin(V);
    Z = c_const * V;
    
    Title_Str = '螺旋面 (Helicoid) DCT 线圈';
    
elseif strcmp(Manifold_Type, 'Enneper')
    % --- 恩内佩尔马鞍面保角参数化 ---
    % 这是一个极小曲面，天然保角
    % 形状类似马鞍，方程 z = x^2 - y^2 的高阶修正版
    
    X = c_const * (U - U.^3/3 + U.*V.^2);
    Y = c_const * (V - V.^3/3 + V.*U.^2);
    Z = c_const * (U.^2 - V.^2);
    
    Title_Str = '马鞍面 (Enneper Saddle) DCT 线圈';
end

%% 5. 提取线圈路径并可视化
% -------------------------------------------------------------------------

figure('Color', 'w', 'Position', [100 100 1200 600]);

% --- 子图1: UV 参数平面 (计算域) ---
subplot(1, 2, 1);
contourf(U, V, Psi, 20, 'LineColor', 'none'); 
colormap(jet); hold on;
% 提取等值线作为线圈
levels = linspace(-0.9, 0.9, N_turns*2);
[C, h] = contour(U, V, Psi, levels, 'k');
title('1. UV 参数平面 (计算域)');
xlabel('Parameter u'); ylabel('Parameter v');
axis equal; grid on;

% --- 子图2: 3D 流形空间 (物理域) ---
subplot(1, 2, 2);
% 绘制半透明曲面作为参考
surf(X, Y, Z, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
hold on;
light; lighting gouraud; 

% 解析并映射线圈路径
i = 1;
while i < size(C, 2)
    lvl = C(1, i);
    num_pts = C(2, i);
    idx_range = (i+1) : (i+num_pts);
    
    u_seg = C(1, idx_range);
    v_seg = C(2, idx_range);
    
    % --- 核心：将 2D 线圈点映射回 3D ---
    if strcmp(Manifold_Type, 'Helicoid')
        x_seg = c_const * sinh(u_seg) .* cos(v_seg);
        y_seg = c_const * sinh(u_seg) .* sin(v_seg);
        z_seg = c_const * v_seg;
    elseif strcmp(Manifold_Type, 'Enneper')
        x_seg = c_const * (u_seg - u_seg.^3/3 + u_seg.*v_seg.^2);
        y_seg = c_const * (v_seg - v_seg.^3/3 + v_seg.*u_seg.^2);
        z_seg = c_const * (u_seg.^2 - v_seg.^2);
    end
    
    % 绘制 3D 导线
    plot3(x_seg, y_seg, z_seg, 'LineWidth', 1.5, 'Color', 'r');
    
    i = i + num_pts + 1;
end

axis equal; grid on;
xlabel('X'); ylabel('Y'); zlabel('Z');
title(['2. 映射后的 ', Title_Str]);
view(45, 30);
camlight;

%% 6. (可选) 计算表面法向量与硬弯 (Hardway Bend)
% 在复杂流形上，导线可能会经历剧烈的侧向弯曲
% 这里计算流形表面的法向量 n
if strcmp(Manifold_Type, 'Helicoid')
    % Helicoid 的解析法向量
    denom = sqrt(c_const^2 * cosh(U).^2); % 度规因子
    % 为了演示简单，这里仅展示度规变化
    fprintf('流形度规因子 Lambda 范围: [%.2f, %.2f]\n', min(denom(:)), max(denom(:)));
end