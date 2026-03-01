%% 等螺距、等倾角离散 CCT 二极铁仿真 (带数据导出功能)
clear; clc; close all;

%% 1. 核心参数设置
I_amp = 200;          % 单匝/单饼电流幅度 (A)
R_in = 0.040;         % 内层半径 (m)
R_out = 0.045;        % 外层半径 (m)
Tilt = 30;            % 倾斜角度 (度)
L_mag = 0.5;          % 磁体长度 (m)
N_pancakes = 30;      % 单层饼线圈数量

% 导出设置
file_inner = 'discrete_cct_inner.txt';
file_outer = 'discrete_cct_outer.txt';

%% 2. 生成等间距 Z 坐标
z_pos = linspace(-L_mag/2, L_mag/2, N_pancakes);

%% 3. 构建线圈几何
coils = struct('x', {}, 'y', {}, 'z', {}, 'I', {}, 'T', {}, 'N', {}, 'B', {});
cnt = 0;
theta = linspace(0, 2*pi, 8); 

% --- 内层旋转矩阵 ---
Rot_In = [1 0 0; 0 cosd(Tilt) -sind(Tilt); 0 sind(Tilt) cosd(Tilt)];
% --- 外层旋转矩阵 ---
Rot_Out = [1 0 0; 0 cosd(-Tilt) -sind(-Tilt); 0 sind(-Tilt) cosd(-Tilt)];

% 生成函数：包含坐标系计算
for layer = 1:2
    if layer == 1
        R = R_in; Rot = Rot_In; curr = I_amp;
    else
        R = R_out; Rot = Rot_Out; curr = -I_amp;
    end
    
    for k = 1:N_pancakes
        % 局部坐标 (圆)
        xc = R * cos(theta);
        yc = R * sin(theta);
        zc = zeros(size(theta));
        
        % 局部切向 T_loc
        tx = -sin(theta); ty = cos(theta); tz = zeros(size(theta));
        % 局部法向 N_loc (指向圆心)
        nx = -cos(theta); ny = -sin(theta); nz = zeros(size(theta));
        
        % 旋转与平移
        pts = Rot * [xc; yc; zc];
        T_vec = Rot * [tx; ty; tz];
        N_vec = Rot * [nx; ny; nz];
        B_vec = cross(T_vec, N_vec); % 副法向
        
        cnt = cnt + 1;
        coils(cnt).x = pts(1, :);
        coils(cnt).y = pts(2, :);
        coils(cnt).z = pts(3, :) + z_pos(k);
        coils(cnt).I = curr;
        % 存储坐标系 (用于导出)
        coils(cnt).T = T_vec'; 
        coils(cnt).N = N_vec';
        coils(cnt).B = B_vec';
    end
end

%% 4. 数据导出 (新增加部分)
% 仿照第二个代码的 [x, y, z, T, N, B] 格式
fprintf('正在导出数据...\n');

% 内层数据合并
data_in = [];
for k = 1:N_pancakes
    pts = [coils(k).x', coils(k).y', coils(k).z'];
    frames = [coils(k).T, coils(k).N, coils(k).B];
    data_in = [data_in; pts, frames];
end

% 外层数据合并
data_out = [];
for k = N_pancakes+1:cnt
    pts = [coils(k).x', coils(k).y', coils(k).z'];
    frames = [coils(k).T, coils(k).N, coils(k).B];
    data_out = [data_out; pts, frames];
end

writematrix(data_in, file_inner, 'Delimiter', ' ');
writematrix(data_out, file_outer, 'Delimiter', ' ');
fprintf('文件已导出: %s, %s\n', file_inner, file_outer);

%% 4. 磁场计算 (Biot-Savart)
z_axis = linspace(-L_mag*0.8, L_mag*0.8, 200);
By = zeros(size(z_axis));
Bz = zeros(size(z_axis));

fprintf('正在计算 %d 个线圈的磁场...\n', cnt);

for i = 1:length(z_axis)
    obs = [0; 0; z_axis(i)];
    B_vec = [0; 0; 0];
    
    for k = 1:cnt
        X = coils(k).x; Y = coils(k).y; Z = coils(k).z;
        current = coils(k).I;
        
        % 向量化毕奥萨伐尔
        dLx = diff(X); dLy = diff(Y); dLz = diff(Z);
        midX = (X(1:end-1)+X(2:end))/2;
        midY = (Y(1:end-1)+Y(2:end))/2;
        midZ = (Z(1:end-1)+Z(2:end))/2;
        
        Rx = obs(1)-midX; Ry = obs(2)-midY; Rz = obs(3)-midZ;
        R3 = (Rx.^2 + Ry.^2 + Rz.^2).^1.5;
        
        factor = 1e-7 * current ./ R3;
        
        % 叉乘 dL x R
        CPx = dLy.*Rz - dLz.*Ry;
        CPy = dLz.*Rx - dLx.*Rz;
        CPz = dLx.*Ry - dLy.*Rx;
        
        B_vec = B_vec + [sum(factor.*CPx); sum(factor.*CPy); sum(factor.*CPz)];
    end
    By(i) = B_vec(2);
    Bz(i) = B_vec(3);
end

%% 5. 绘图结果
figure('Color', 'w', 'Position', [100, 100, 900, 700]);

% 子图1：3D结构图Q
subplot(2,2,[1,3]); 
hold on; axis equal; grid on; view(3);
for k=1:N_pancakes % 画内层(红)
    plot3(coils(k).x, coils(k).z, coils(k).y, 'r'); 
end
for k=N_pancakes+1:cnt % 画外层(蓝)
    plot3(coils(k).x, coils(k).z, coils(k).y, 'b'); 
end
title('离散倾斜饼式线圈阵列 (Discrete Tilted Pancake)');
legend('Inner Layer (+I)', 'Outer Layer (-I)');
xlabel('X'); ylabel('Y'); zlabel('Z');

% 子图2：By 分布
subplot(2,2,2);
plot(z_axis, By, 'k', 'LineWidth', 1.5); grid on;
title('主场分量 By (Dipole)');
ylabel('Field (T)'); xlabel('Z (m)');

% 子图3：Bz 分布 (验证抵消)
subplot(2,2,4);
plot(z_axis, Bz, 'r', 'LineWidth', 1.5); grid on;
title('轴向分量 Bz (Solenoid) - 应接近0');
ylabel('Field (T)'); xlabel('Z (m)');

fprintf('中心 By = %.4f T\n', max(abs(By)));
fprintf('残留 Bz = %.4f T\n', max(abs(Bz)));