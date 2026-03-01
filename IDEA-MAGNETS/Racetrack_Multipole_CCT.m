% Universal_Racetrack_Multipole_CCT.m
% =========================================================================
% 功能：生成任意阶数 (Dipole, Quad, Sextupole, Octupole) 的跑道型 CCT 路径
% 核心原理：利用复数势 z ~ Im((x + iy)^n) 实现自动映射
% 修改记录：将可视化部分的 subplot 分离为两个独立 Figure
% =========================================================================

clc; clear; close all;

%% 1. 参数定义 (User Parameters)
% -------------------------------------------------------------------------
% ！！！在此处修改磁体阶数！！！
n_pole = 1;         % 1=Dipole, 2=Quad, 3=Sextupole, 4=Octupole
k_strength = 0.55;  % 调制幅度 (mm). 注意：高阶磁体可能需要减小此值以防过陡

% 几何尺寸
L_flat = 200;       % 平直段长度 (mm)
R_inner = 80;       % 内层半径 (mm)
R_outer = 90;       % 外层半径 (mm)

% 绕组参数
Pitch = 15;          % 螺距 (mm)
n_turns = 50;       % 匝数
N_pts = 50;         % 每匝点数

% 导出文件名
file_inner = sprintf('racetrack_n%d_inner.txt', n_pole);
file_outer = sprintf('racetrack_n%d_outer.txt', n_pole);

fprintf('=== 生成 %d 极 (n=%d) 跑道型 CCT ===\n', 2*n_pole, n_pole);

%% 2. 生成数据 (Generate Data)
% -------------------------------------------------------------------------
% 内层：角度相位 0 (正调制)
[data_in, x1, y1, z1] = calc_multipole_path(L_flat, R_inner, n_turns, Pitch, k_strength, n_pole, 1, N_pts);

% 外层：角度相位 pi/n (反相调制以抵消螺线管场)
% 对于 n=1, 差 180 度 (反号); n=2, 差 90 度 (反号); n=3, 差 60 度...
% 在 CCT 数学中，简单的做法是：外层幅度取负号 -k_strength
[data_out, x2, y2, z2] = calc_multipole_path(L_flat, R_outer, n_turns, Pitch, -k_strength, n_pole, -1, N_pts);

%% 3. 导出文件
writematrix(data_in, file_inner, 'Delimiter', ' ');
writematrix(data_out, file_outer, 'Delimiter', ' ');
fprintf('文件已导出:\n  %s\n  %s\n', file_inner, file_outer);

%% 4. 可视化分析 (Visualization)
% -------------------------------------------------------------------------
% 修改说明：将原有的 subplot 布局拆分为两个独立的 Figure 窗口

% --- Figure 1: 3D 概览 ---
figure('Name', sprintf('3D View: n=%d Racetrack CCT', n_pole), ...
    'Color', 'w', 'Position', [100, 100, 600, 600]);

plot3(x1, z1, y1, 'r-', 'LineWidth', 1.2); hold on;
plot3(x2, z2, y2, 'b-', 'LineWidth', 1.2);
% 画个简单的骨架参考
draw_racetrack_shell(L_flat, R_inner, min(z1), max(z1));

axis equal; grid on;
axis off;
grid off;

xlabel('X [mm]'); ylabel('Z (Beam) [mm]'); zlabel('Y [mm]');
legend('Inner', 'Outer');
view(-45, 30);
title(sprintf('3D Overview: %d-Pole Racetrack CCT', 2*n_pole));

% --- Figure 2: 平直段拓扑 (Top View) ---
% 这个视图最能体现不同阶数的几何特征
figure('Name', sprintf('Top View: n=%d Racetrack CCT', n_pole), ...
    'Color', 'w', 'Position', [750, 100, 600, 600]);

plot(x1, z1, 'r-', 'LineWidth', 1); hold on;
plot(x2, z2, 'b-', 'LineWidth', 1);
axis equal; grid on;
axis off;
grid off;

xlabel('X (Horizontal Width) [mm]'); ylabel('Z (Beam Direction) [mm]');
title(sprintf('Top View (Flat Section Topology)\nOrder: n=%d', n_pole));
xlim([-L_flat/2 - R_inner, L_flat/2 + R_inner]);
% 放大中间几匝看形状
z_mid = max(z1)/2;
ylim([z_mid - 3*Pitch, z_mid + 3*Pitch]);

%% ========================================================================
%  核心计算函数 (Universal Multipole Function)
% ========================================================================
function [full_data, x, y, z] = calc_multipole_path(L, R, n_turns, pitch, Amp, n, polarity, pts_per_turn)
    total_pts = n_turns * pts_per_turn;
    s_vec = linspace(0, n_turns, total_pts)';
    perimeter = 2*L + 2*pi*R;
    
    x = zeros(total_pts, 1);
    y = zeros(total_pts, 1);
    z = zeros(total_pts, 1);
    
    % 1. 生成截面 (x, y) 坐标
    for i = 1:total_pts
        u_norm = mod(s_vec(i), 1);
        pl = u_norm * perimeter;
        
        if pl <= L
            x(i) = -L/2 + pl; y(i) = -R; % Bottom
        elseif pl <= (L + pi*R)
            ang = -pi/2 + (pl - L)/R;
            x(i) = L/2 + R*cos(ang); y(i) = R*sin(ang); % Right Arc
        elseif pl <= (2*L + pi*R)
            d = pl - (L + pi*R);
            x(i) = L/2 - d; y(i) = R; % Top
        else
            ang = pi/2 + (pl - (2*L + pi*R))/R;
            x(i) = -L/2 + R*cos(ang); y(i) = R*sin(ang); % Left Arc
        end
    end
    
    % 2. 计算多极场 Z 调制 (The Magic Formula)
    % 公式：z_mod = Amp * Imag( (x + i*y)^n ) / R^(n-1)
    % 我们需要除以 R^(n-1) 来进行归一化，确保单位还是 mm
    
    complex_xy = x + 1i * y;
    z_harmonic = imag(complex_xy .^ n);
    
    % 归一化因子 (Scale Factor)
    scale = R^(n-1); 
    
    z_mod = (Amp / scale) * z_harmonic;
    
    % 3. 叠加螺距
    z_linear = pitch * s_vec;
    z = z_mod + z_linear;
    
    % 4. 计算坐标系 (T, N, B)
    [T, N, B] = calc_frenet_frame(x, y, z, L, R);
    
    full_data = [x, y, z, T, N, B];
end

function [T, N, B] = calc_frenet_frame(x, y, z, L, R)
    % 数值微分计算坐标系
    dx = gradient(x); dy = gradient(y); dz = gradient(z);
    T = [dx, dy, dz];
    T = T ./ sqrt(sum(T.^2, 2)); % Normalize T
    
    % 计算骨架表面法向 V_surf
    V_surf = zeros(size(x,1), 3);
    for i=1:size(x,1)
        % 简化的表面法向逻辑
        if abs(y(i)) >= R*0.99 && abs(x(i)) <= L/2 % Flat parts
            V_surf(i,:) = [0, sign(y(i)), 0];
        else % Arc parts
            if x(i) > 0, cx = L/2; else, cx = -L/2; end
            vx = x(i) - cx; vy = y(i);
            v_norm = sqrt(vx^2 + vy^2);
            V_surf(i,:) = [vx/v_norm, vy/v_norm, 0];
        end
    end
    
    B = cross(T, V_surf, 2);
    B = B ./ sqrt(sum(B.^2, 2));
    N = cross(B, T, 2);
    N = N ./ sqrt(sum(N.^2, 2));
end

function draw_racetrack_shell(L, R, zmin, zmax)
    % 画个简单的半透明壳
    [u,v] = meshgrid(linspace(0,1,50), linspace(zmin,zmax,20));
    perim = 2*L + 2*pi*R;
    X = zeros(size(u)); Y = zeros(size(u)); Z = v;
    for i=1:numel(u)
        pl = u(i)*perim;
        if pl<=L, X(i)=-L/2+pl; Y(i)=-R;
        elseif pl<=L+pi*R, ang=-pi/2+(pl-L)/R; X(i)=L/2+R*cos(ang); Y(i)=R*sin(ang);
        elseif pl<=2*L+pi*R, X(i)=L/2-(pl-(L+pi*R)); Y(i)=R;
        else, ang=pi/2+(pl-(2*L+pi*R))/R; X(i)=-L/2+R*cos(ang); Y(i)=R*sin(ang); end
    end
    surf(X,Z,Y, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
end