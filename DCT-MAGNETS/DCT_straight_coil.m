%% --- 主脚本：生成并可视化一个完整的直线型任意偶极DCT磁体（衔接修正版）---
%
%   说明:
%   此版本修正了直线段与端部衔接不平滑的bug。
%   只需修改下面的参数 m 即可生成不同类型的磁体。
%
%--------------------------------------------------------------------------

% 清理工作区和图形窗口
clear; clc; close all;

% --- 定义磁体参数 ---
m = 4;              % <<-- 修改这里以改变磁体极数 (例如, 1, 2, 3, 4...)
N = 5;             % 每极总匝数
r_coil = 100;        % 线圈半径 (mm)
L_st = 500;         % 直线段长度 (mm)
L_e = 100;          % 端部长度 (mm)
R_bend = inf;       % 弯曲半径 (mm)。设置为 inf 即可得到直线型线圈
num_points_half = 251; % 半个线圈的离散点数

% --- 设置图形和绘图 ---
figure('Name', 'Complete Straight Multipole DCT Coil (Fixed)', 'Position', [100, 100, 900, 700]);
hold on;
grid on;
axis equal;
view(30, 25);
pole_number = 2*m;
title_str = sprintf('Complete Straight %d-Pole DCT Coil (m=%d, N=%d)', pole_number, m, N);
title(title_str);
xlabel('X (mm)');
ylabel('Y (mm)');
zlabel('Z (mm)');
colors = jet(N);

% --- 循环生成并绘制每一匝线圈 ---
fprintf('正在为 %d-极磁体生成 %d 匝线圈...\n', pole_number, N);

% 1. 为了效率，先一次性生成所有匝数的"基准路径"
base_paths = cell(N, 3);
for i = 1:N
    [base_paths{i,1}, base_paths{i,2}, base_paths{i,3}] = ...
        generateDCTPath_smooth(m, N, i, r_coil, L_st, L_e, R_bend, num_points_half);
end

% 2. 通过旋转基准路径，生成并绘制所有 2*m 个磁极
for k = 0:(pole_number - 1) % 循环每一个磁极
    
    % 计算当前磁极需要旋转的角度
    angle = k * (2 * pi) / pole_number;
    
    % 定义2D旋转矩阵
    R = [cos(angle), -sin(angle); 
         sin(angle),  cos(angle)];

    for i = 1:N % 循环每一匝线圈
        % 从预先生成的路径中获取基准路径
        X_base = base_paths{i,1};
        Y_base = base_paths{i,2};
        Z_base = base_paths{i,3};

        % 对前半圈的坐标进行旋转
        coords_front = R * [X_base; Y_base];
        
        % 对镜像的后半圈的坐标进行旋转
        coords_back = R * [-X_base; Y_base];
        
        % 绘制旋转后的前后两半，组成一个完整的磁极
        plot3(coords_front(1,:), coords_front(2,:), Z_base, 'Color', colors(i,:), 'LineWidth', 1.5);
        plot3(coords_back(1,:), coords_back(2,:), Z_base, 'Color', colors(i,:), 'LineWidth', 1.5);
    end
end
fprintf('线圈生成完毕。\n');

% --- (可选) 绘制线圈所在的中心圆柱面 ---
[xc, yc, zc] = cylinder(r_coil, 100);
max_len = L_st + 2*L_e;
zc = zc * max_len - max_len/2;
surf(xc, yc, zc, 'FaceColor', '#BDC3C7', 'FaceAlpha', 0.1, 'EdgeColor', 'none');

hold off;
rotate3d on;

%% --- 函数定义 (修正衔接问题) ---
function [X, Y, Z] = generateDCTPath_smooth(m, N, i, r_coil, L_st, L_e, R_bend, num_points_half)
% generateDCTPath_smooth - 生成具有平滑端部的单匝DCT线圈路径的前半圈

% 1. 计算此匝线圈的基本参数
C = (i - 0.5) / N;
if C > 1, C = 1; end % 安全保护

% 2. 修正形状函数 f(s) 的形式，使其从1平滑到0
shape_func = @(s_end) cos( (pi/2) * s_end / L_e );

% 3. 计算此匝线圈在端部的最大延伸长度
s_end_max = (2 * L_e / pi) * acos(C);

% 4. 生成此匝线圈的坐标s向量
s_straight = linspace(-L_st/2, L_st/2, num_points_half);
s_end_positive = linspace(0, s_end_max, round(num_points_half/2));
s_positive_half = [s_straight(s_straight>=0), (s_end_positive(2:end) + L_st/2)];
s_negative_half = -fliplr(s_positive_half);
s = [s_negative_half(1:end-1), s_positive_half];

% 5. 计算随s变化的方位角 theta(s)
% --- Bug修复：为直线段的角度初始化时，加上 (1/m) 因子 ---
theta_s = (1/m) * ones(size(s)) * asin(C);
% --------------------------------------------------------
end_indices = abs(s) > L_st/2;
s_in_end = abs(s(end_indices)) - L_st/2;
f_s_end = shape_func(s_in_end);
arg_asin = C ./ f_s_end;
arg_asin(arg_asin > 1) = 1;
theta_s(end_indices) = (1/m) * asin(arg_asin);

% 6. 根据弯曲半径应用坐标变换
if isinf(R_bend)
    X = r_coil * cos(theta_s);
    Y = r_coil * sin(theta_s);
    Z = s;
else
    phi_s = s / R_bend;
    X = (R_bend + r_coil * cos(theta_s)) .* cos(phi_s);
    Y = (R_bend + r_coil * cos(theta_s)) .* sin(phi_s);
    Z = r_coil * sin(theta_s);
end

end