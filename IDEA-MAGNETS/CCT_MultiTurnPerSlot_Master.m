function Variable_Gradient_CCT_Vis()
    % =============================================================
    % 纵向变梯度超导二极CCT磁体三维路径可视化
    % 模拟效果：两端线槽稀疏（低场），中部线槽致密（高场）
    % =============================================================
    
    clc; clear; close all;
    
    % --- 1. 基础参数定义 ---
    R = 0.05;           % 磁体孔径半径 (m)
    L_total = 1.0;      % 磁体总长度 (m)
    N_turns_base = 60;  % 基准匝数估算
    Current = 1;        % 归一化电流
    
    % 离散化角度变量 (theta)
    % 这种变梯度通常需要较长的总角度，这里预设一个较大的范围
    theta_total = 2 * pi * N_turns_base; 
    theta = linspace(-theta_total/2, theta_total/2, 5000);
    
    % --- 2. 定义变梯度密度函数 (Winding Density Function) ---
    % 这是一个无量纲函数，1表示基准密度，3表示3倍密度（模拟3层效果）
    % 使用 Sigmoid 函数平滑过渡，避免硬突变导致导线弯折过大
    
    % 归一化位置变量 u (-1 到 1)
    u = theta / (max(theta)); 
    
    % 设计密度分布：两端为1，中间平滑过渡到2.5倍密度
    % 这里的逻辑是：中间区域 (-0.4 到 0.4) 密度高
    density_base = 1.0;
    density_peak = 2.5; % 中部密度是两端的2.5倍（模拟由1层变到2-3层）
    
    % 使用广义高斯或Sigmoid组合来创建"台阶"形状的密度分布
    density_dist = density_base + (density_peak - density_base) * ...
                   (1 ./ (1 + exp(-20*(u + 0.6))) - 1 ./ (1 + exp(-20*(u - 0.6))));
    
    % --- 3. 计算轴向位置 z(theta) ---
    % 原理：z 的增量与密度成反比 (dz/dtheta \propto 1/density)
    % 密度越大，绕一圈 z 前进的距离越短（越密）
    
    % 基础螺距 (Pitch)
    h0 = L_total / N_turns_base; 
    
    % 积分计算 z_centerline
    % z(i) = integral(h0 / density)
    d_theta = theta(2) - theta(1);
    dz = (h0 / (2*pi)) ./ density_dist * d_theta;
    z_axial = cumsum(dz);
    
    % 调整 z 使其中心在 0
    z_axial = z_axial - max(z_axial)/2;
    
    % --- 4. 添加 CCT 二极磁体调制项 ---
    % Dipole CCT 方程: z = z_axial + A * sin(theta)
    % A 决定了倾角，通常 tan(alpha) = 1 (45度倾角) 时效率最高
    % 这里的 A 也需要随密度变化吗？通常保持相对半径固定，
    % 但为了保持孔径恒定，振幅 A 通常设为 R/tan(alpha)。这里设倾角随变。
    
    tilt_angle = 30; % 倾角 (度)
    A = R / tand(tilt_angle); 
    
    % 计算三维路径
    % 注意：对于变梯度，为了保证二极场纯度，振幅 A 理论上应随螺距微调，
    % 但作为几何可视化，固定 A 依然能展示核心结构。
    
    X = R * cos(theta);
    Y = R * sin(theta);
    Z = z_axial + A * sin(theta); % 加上二极分量
    
    % --- 5. 可视化绘图 ---
    figure('Color', 'w', 'Position', [100, 100, 1000, 600]);
    
    % 绘制导线路径
    plot3(Z, X, Y, 'LineWidth', 2, 'Color', [0.85, 0.33, 0.1]); % 铜色
    hold on;
    
    % 绘制参考圆柱面 (骨架示意)
    [Z_cyl, Theta_cyl] = meshgrid(linspace(min(Z), max(Z), 50), linspace(0, 2*pi, 50));
    X_cyl = (R-0.002) * cos(Theta_cyl);
    Y_cyl = (R-0.002) * sin(Theta_cyl);
    surf(Z_cyl, X_cyl, Y_cyl, 'FaceColor', [0.9, 0.9, 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    
    % 视觉美化
    axis equal;
    grid on;
    box on;
    view(30, 25); % 设置视角
    
    % 标注
    title({'纵向变梯度 CCT 磁体绕组路径'; 'Longitudinal Variable-Gradient CCT'}, 'FontSize', 14);
    xlabel('Z (Axial) [m]', 'FontSize', 12);
    ylabel('X [m]', 'FontSize', 12);
    zlabel('Y [m]', 'FontSize', 12);
    
    % 添加注释箭头
    text(min(Z), 0, R*1.5, '两端稀疏 (Pitch Large)', 'HorizontalAlignment', 'center', 'Color', 'b');
    text(0, 0, R*1.5, '中部致密 (Pitch Small)', 'HorizontalAlignment', 'center', 'Color', 'r');
    
    % 绘制密度分布图以供参考
    axes('Position', [0.15, 0.1, 0.3, 0.2]); % 嵌图
    plot(z_axial, density_dist, 'LineWidth', 1.5, 'Color', 'b');
    title('线密度分布 ( ~ 场强分布)', 'FontSize', 10);
    xlabel('Z [m]'); ylabel('Relative Density');
    grid on;
    ylim([0, 3]);
    
    rotate3d on;
end