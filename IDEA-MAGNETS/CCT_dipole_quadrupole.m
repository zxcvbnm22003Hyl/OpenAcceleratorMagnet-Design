%% cct_2plus4_nested_export_CN.m
% 嵌套双层 CCT (二极 + 四极) 设计验证与 Opera 导出脚本
%
% 功能:
%   1. 生成二极场 (Dipole) + 四极场 (Quadrupole) 叠加的 CCT 路径
%   2. 验证中心平面的磁场质量 (毕奥-萨伐尔定律)
%   3. 计算 TNB 标架 (切向/法向/副法向) 并导出为 Opera/Ansys 可用格式
%
% 目标场:
%   Bx = G*y
%   By = B0 + G*x
%
% 修正说明:
%   - 修复了变量名冲突导致的 horzcat 维度错误
%   - 所有注释已汉化
%   - 导出格式包含完整的 TNB 局部坐标系

clear; close all; clc;

%% ===================== 1. 用户参数设置 ======================
mu0 = 4*pi*1e-7;

% --- 几何参数 (嵌套圆筒) ---
a1     = 0.050;     % [m] 内层半径
dr     = 0.01;     % [m] 层间距 (外层 - 内层)
a2     = a1 + dr;   % [m] 外层半径

pitch  = 0.015;     % [m/turn] 螺距 (每 2pi 的轴向进给)
Nturn  = 60;        % [-] 匝数

% --- 电流参数 ---
I = 8000;           % [A] 单层电流

% --- 目标磁场 (两层总和) ---
B0_target = 2.0;    % [T] 二极场分量
G_target  = 20.0;   % [T/m] 四极场梯度

%由于两层 CCT 的横向场是叠加的，每层设计为目标值的一半
B0_layer = B0_target/2;
G_layer  = G_target/2;

% --- 路径离散化精度 ---
ptsPerTurn = 15;   % 每匝点数 (建模导出用 360 足够，高精度场计算可用 720+)

% --- 场验证区域 (z=0 平面) ---
rEval   = 0.020;    % [m] 评估区域半宽 (正方形 [-rEval, rEval])
nGrid   = 41;       % 网格分辨率 (点数)

%% ===================== 2. 构建 3D 路径 ======================
% --- 角度参数 (强制为列向量) ---
theta = linspace(0, 2*pi*Nturn, Nturn*ptsPerTurn + 1).'; 

% --- 基础螺旋 (单调增长) ---
zlin = (pitch/(2*pi)) * theta;

% --- 轴向调制函数 (CCT 核心公式) ---
% z_mod = - (a * pitch / I) * (2/mu0) * ( B_dipole*sin(theta) + B_quad*sin(2*theta) ... )
% 注意：四极场项系数为 (G * a / 2)
zmod1 = -(a1*pitch/I)*(2/mu0) * ( B0_layer*sin(theta) + (G_layer*a1/2)*sin(2*theta) );
zmod2 = -(a2*pitch/I)*(2/mu0) * ( B0_layer*sin(theta) + (G_layer*a2/2)*sin(2*theta) );

zA = zlin + zmod1;
zB = zlin + zmod2;

% --- Layer A (内层): 正向旋转 ---
thetaA = theta;
pathA  = [a1*cos(thetaA), a1*sin(thetaA), zA];

% --- Layer B (外层): 反向旋转 (Opposite Tilt) ---
% 反向旋转是为了抵消螺线管轴向场 (Bz)，同时保留横向场
thetaPhase = 0.0;
thetaB = -theta + thetaPhase;
pathB  = [a2*cos(thetaB), a2*sin(thetaB), zB];

% --- 轴向对中 (将两层中心移至 z=0) ---
zShift = -0.5*( min([zA;zB]) + max([zA;zB]) );
pathA(:,3) = pathA(:,3) + zShift;
pathB(:,3) = pathB(:,3) + zShift;

fprintf('路径生成完毕:\n');
fprintf('  层 A (内) z范围: [%.4f, %.4f] m\n', min(pathA(:,3)), max(pathA(:,3)));
fprintf('  层 B (外) z范围: [%.4f, %.4f] m\n', min(pathB(:,3)), max(pathB(:,3)));

%% ===================== 3. 计算 TNB 局部标架 (用于导出) ======================
disp('正在计算 TNB 标架 (Tangent, Normal, Binormal)...');

% 使用自定义函数计算，返回结果重命名为 _vec 结尾，避免变量冲突
[~, TA_vec, NA_vec, BA_vec] = calculateTNB(pathA);
[~, TB_vec, NB_vec, BB_vec] = calculateTNB(pathB);

%% ===================== 4. 磁场验证 (z=0 平面) ======================
% 为了验证设计是否正确，计算中心平面的磁场
xv = linspace(-rEval, rEval, nGrid);
yv = linspace(-rEval, rEval, nGrid);
[X, Y] = meshgrid(xv, yv);
P = [X(:), Y(:), zeros(numel(X),1)];

% 计算毕奥-萨伐尔积分
% 注意：这里的 BA_field 是磁场，不是上面的 BA_vec (副法向)
BA_field = biotSavartPolylineMidpoint(pathA, I, P);
BB_field = biotSavartPolylineMidpoint(pathB, I, P);
B_total  = BA_field + BB_field;

Bx = reshape(B_total(:,1), size(X));
By = reshape(B_total(:,2), size(X));
Bz = reshape(B_total(:,3), size(X));

% 简单的统计检查
fprintf('\n===== 磁场检查 (z=0) =====\n');
fprintf('  By 平均值 (目标 %.2f T): %.4f T\n', B0_target, mean(By(:)));
fprintf('  Bz 最大值 (螺线管分量): %.4f T (越小越好)\n', max(abs(Bz(:))));

% 拟合梯度 G
% By = B0 + G*x -> G = dBy/dx
dx = xv(2) - xv(1);
[dBy_dx, ~] = gradient(By, dx);
G_extracted = mean(dBy_dx(:));
fprintf('  四极场梯度 G (目标 %.2f T/m): %.4f T/m\n', G_target, G_extracted);

%% ===================== 5. 导出 Opera/Ansys 数据文件 ======================
% 导出格式: X Y Z Tx Ty Tz Nx Ny Nz Bx By Bz
% 说明: 这里的 Bx By Bz 指的是副法向向量 (Binormal) 的分量，不是磁场！

header = 'X[m] Y[m] Z[m] Tx Ty Tz Nx Ny Nz Bx_vec By_vec Bz_vec';

fileA = 'cct_combined_layerA_opera.txt';
fileB = 'cct_combined_layerB_opera.txt';

% 拼接数据 (使用 _vec 变量，确保维度一致)
% pathA 是 Nx3, TA_vec 是 Nx3 ... 拼接后是 Nx12
outA = [pathA, TA_vec, NA_vec, BA_vec];
outB = [pathB, TB_vec, NB_vec, BB_vec];

writematrix(outA, fileA, 'Delimiter', ' ');
writematrix(outB, fileB, 'Delimiter', ' ');

fprintf('\n===== 导出成功 =====\n');
fprintf('  内层文件: %s\n', fileA);
fprintf('  外层文件: %s\n', fileB);
fprintf('  列格式: %s\n', header);

%% ===================== 6. 绘图与可视化 ======================

% 图1: 3D 路径与截面向量
figure('Name','CCT 路径与 TNB 标架','Color','w'); hold on; axis equal; grid on;
plot3(pathA(:,1), pathA(:,2), pathA(:,3), 'b', 'LineWidth', 1.5);
plot3(pathB(:,1), pathB(:,2), pathB(:,3), 'r', 'LineWidth', 1.5);

% 为了不让箭头太密集，每隔 100 个点画一个箭头
idx = 1:100:size(pathA,1);
scale = 0.015; % 箭头长度缩放

% 画法向 (Normal) - 通常对应导体的"宽度"方向 (沿半径)
quiver3(pathA(idx,1), pathA(idx,2), pathA(idx,3), ...
        NA_vec(idx,1), NA_vec(idx,2), NA_vec(idx,3), scale, 'c', 'LineWidth', 1.5);

% 画副法向 (Binormal) - 通常对应导体的"厚度"方向 (沿轴向)
quiver3(pathA(idx,1), pathA(idx,2), pathA(idx,3), ...
        BA_vec(idx,1), BA_vec(idx,2), BA_vec(idx,3), scale, 'm', 'LineWidth', 1.5);

xlabel('x [m]'); ylabel('y [m]'); zlabel('z [m]');
title('CCT 几何路径与截面方向向量 (青色=法向, 品红=副法向)');
legend('内层路径', '外层路径', '法向 (Normal)', '副法向 (Binormal)');
view(3);

% 图2: 磁场云图 By
figure('Name','磁场分布 By','Color','w');
contourf(X, Y, By, 40, 'LineStyle','none'); colorbar;
axis equal; grid on;
xlabel('x [m]'); ylabel('y [m]');
title(['By 分布云图 (目标 B0=', num2str(B0_target), 'T, G=', num2str(G_target), 'T/m)']);

%% ===================== 本地函数 ======================

function [path, T, N, B] = calculateTNB(path_in)
% CALCULATETNB 计算离散路径的 Frenet-Serret (TNB) 标架
% 使用参考向量法避免拐点翻转
%
% 输入: path_in (Nx3 坐标矩阵)
% 输出: T (切向), N (法向), B (副法向) 全部为 Nx3 单位向量

    path = path_in; % 传递路径
    nPoints = size(path, 1);
    
    T = zeros(nPoints, 3);
    N = zeros(nPoints, 3);
    B = zeros(nPoints, 3);
    
    % 1. 计算切向 (T) - 使用中心差分梯度
    dx = gradient(path(:,1));
    dy = gradient(path(:,2));
    dz = gradient(path(:,3));
    v = [dx, dy, dz];
    
    % 归一化 T
    for i = 1:nPoints
        v_norm = norm(v(i,:));
        if v_norm > 1e-9
            T(i,:) = v(i,:) / v_norm;
        else
            T(i,:) = [0, 0, 1]; % 防止零除
        end
    end
    
    % 2. 计算法向 (N) - 使用参考向量法 (Reference Vector Method)
    % CCT 线圈主要沿 Z 轴延伸，使用 [0,0,1] 作为参考向量通常最稳定
    ref_vec_default = [0, 0, 1]; 
    
    for i = 1:nPoints
        ref = ref_vec_default;
        
        % 如果切向 T 与参考向量平行 (奇异点)，临时切换参考向量到 X 轴
        if abs(dot(T(i,:), ref)) > 0.99
            ref = [1, 0, 0]; 
        end
        
        % Gram-Schmidt 正交化: N 垂直于 T
        % N_temp = Ref - (Ref . T) * T
        n_vec = ref - dot(ref, T(i,:)) * T(i,:);
        
        % 归一化 N
        n_norm = norm(n_vec);
        if n_norm > 1e-9
            N(i,:) = n_vec / n_norm;
        else
            N(i,:) = [1, 0, 0]; % 备用
        end
        
        % 3. 计算副法向 (B)
        B(i,:) = cross(T(i,:), N(i,:));
    end
end

function B_field = biotSavartPolylineMidpoint(path, I, P)
% BIOTSAVARTPOLYLINEMIDPOINT 毕奥-萨伐尔定律计算磁场
% 输入: path (Nx3), I (电流), P (Mx3 场点)
% 输出: B_field (Mx3 磁场矢量)

    mu0 = 4*pi*1e-7;
    c = mu0*I/(4*pi);

    r1 = path(1:end-1,:);
    r2 = path(2:end,:);
    dl = r2 - r1;            % 线元矢量
    rm = 0.5*(r1 + r2);      % 线元中点

    B_field = zeros(size(P));
    
    % 简单的矢量化循环 (如果网格点非常多，可进一步优化)
    for m = 1:size(P,1)
        R = P(m,:) - rm;                 % 距离矢量
        r2n = sum(R.^2,2);               % 距离平方
        r3 = (sqrt(r2n)).^3 + 1e-30;     % 距离立方 (加微小量防除零)
        dB = cross(dl, R, 2) ./ r3;      % dB 贡献
        B_field(m,:) = c * sum(dB, 1);   % 积分求和
    end
end