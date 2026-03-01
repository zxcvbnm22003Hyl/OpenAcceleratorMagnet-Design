% =========================================================================
% 脚本 1 (毫米单位版): 生成直线CCT的【完整路径和局部坐标系】
%
% 修正: 所有长度单位统一为毫米 (mm)。
% =========================================================================
%% 1. 初始化环境
% -------------------------------------------------------------------------
clear; clc; close all;
%% 2. 定义CCT线圈的物理和几何参数 (用户修改区域)
% -------------------------------------------------------------------------
disp('--- 开始定义【直线型CCT】参数 (单位: 毫米) ---');
% --- 通用几何参数 ---
% 【【【关键】】】所有长度单位必须是毫米 (mm)！
Pitch = 10; % 螺距 (10 mm)
Amp = 30; % 调制幅度 (30 mm)
N_pole = 2; % 磁场阶数 (n=2 -> 四极场)
N_turns = 20; % 线圈总匝数
N_points_per_turn = 40;

% --- 内外层特定参数 ---
R1 = 50; % 内层半径 (50 mm)
R2 = 60; % 外层半径 (60 mm)
fprintf('螺距: %.1f mm\n', Pitch);
fprintf('幅度: %.1f mm\n', Amp);
fprintf('磁场阶数: %d\n', N_pole);
fprintf('内层半径: %.1f mm, 外层半径: %.1f mm\n', R1, R2);
disp('----------------------');
%% 3. 计算路径和局部坐标系 (T, N, B)
% ... (这部分代码在数学上是正确的，无需修改) ...
total_points = N_turns * N_points_per_turn;
t = linspace(0, N_turns * 2 * pi, total_points);
x1_func = @(T) R1 * cos(T);
y1_func = @(T) R1 * sin(T);
z1_func = @(T) (Pitch / (2 * pi)) * T + Amp * sin(N_pole * T);
phase_shift = pi / N_pole;
x2_func = @(T) R2* cos(T + phase_shift);
y2_func = @(T) R2* sin(T + phase_shift);
z2_func = @(T) (Pitch / (2 * pi)) * T + Amp * sin(N_pole * T);
% ... (process_layer 函数也无需修改) ...
function full_path_data = process_layer(t_vector, x_func, y_func, z_func)
 num_pts = length(t_vector);
 xyz_coords = zeros(num_pts, 3); 
 tangents = zeros(num_pts, 3); 
 normals = zeros(num_pts, 3); 
 binormals = zeros(num_pts, 3);
 syms T_sym;
 dx_dt_sym = diff(x_func(T_sym), T_sym); 
 dy_dt_sym = diff(y_func(T_sym), T_sym); 
 dz_dt_sym = diff(z_func(T_sym), T_sym);
 vx_func = matlabFunction(dx_dt_sym, 'Vars', T_sym); 
 vy_func = matlabFunction(dy_dt_sym, 'Vars', T_sym); 
 vz_func = matlabFunction(dz_dt_sym, 'Vars', T_sym);
for i = 1:num_pts
 current_t = t_vector(i);
 xyz_coords(i, :) = [x_func(current_t), y_func(current_t), z_func(current_t)];
 velocity_vector = [vx_func(current_t), vy_func(current_t), vz_func(current_t)];
 tangents(i, :) = velocity_vector / norm(velocity_vector);
 reference_vector = [0, 0, 1];
if abs(dot(tangents(i, :), reference_vector)) > 0.9999
    reference_vector = [1, 0, 0]; 
end
 normal_unnormalized = reference_vector - dot(reference_vector, tangents(i, :)) * tangents(i, :);
 normals(i, :) = normal_unnormalized / norm(normal_unnormalized);
 binormals(i, :) = cross(tangents(i, :), normals(i, :));
end
 full_path_data = [xyz_coords, tangents, normals, binormals];
end
%% 4. 处理、保存并可视化
% ... (这部分代码也无需修改，只是文件名建议更新一下以作区分) ...
disp('正在处理内层线圈 (Layer 1)...');
full_path_data_1 = process_layer(t, x1_func, y1_func, z1_func);
output_filename_1 = 'linear_cct_layer1_inner_path.txt';
writematrix(full_path_data_1, output_filename_1, 'Delimiter', ' ');
disp(['成功生成内层完整路径文件: ', output_filename_1, ' (单位: mm)']);

disp('正在处理外层线圈 (Layer 2)...');
full_path_data_2 = process_layer(t, x2_func, y2_func, z2_func);
output_filename_2 = 'linear_cct_layer2_outer_path.txt';
writematrix(full_path_data_2, output_filename_2, 'Delimiter', ' ');
disp(['成功生成外层完整路径文件: ', output_filename_2, ' (单位: mm)']);

% ... (可视化部分也无需修改) ...
disp('正在生成预览图...');
figure('Name', 'CCT路径预览 (单位: 毫米)', 'NumberTitle', 'off');
hold on;
plot3(full_path_data_1(:,1), full_path_data_1(:,3), full_path_data_1(:,2), 'b-', 'LineWidth', 2);
plot3(full_path_data_2(:,1), full_path_data_2(:,3), full_path_data_2(:,2), 'r-', 'LineWidth', 2);
grid on; axis equal; 
xlabel('X (mm)'); 
ylabel('Y (mm)'); 
zlabel('Z (mm)');
title('嵌套式CCT线圈中心路径'); 
legend('内层 (Layer 1)', '外层 (Layer 2)'); 
view(30, 20);
hold off;
disp('脚本1 (毫米单位版) 执行完毕！');