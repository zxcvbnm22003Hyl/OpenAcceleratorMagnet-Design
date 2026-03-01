% =========================================================================
% 脚本: build_cond_file_merged.m
%
% 目的:
% 读取所有层级的路径文件，将它们全部构建成BR8单元，并写入
% 一个单一的、总的.cond文件中，便于在OPERA中一次性导入。
% =========================================================================

%% 1. 初始化环境
clear; clc; close all;
fprintf('--- 脚本开始: .cond文件生成器 (合并输出) ---\n\n');

%% 2. 定义转换参数
fprintf('--- 1. 定义 .cond BR8 文件转换参数 ---\n');
input_dir = 'dct_linear_rectangle_path'; % 【【【注意】】】确保这个目录名与第一个脚本的输出目录匹配（rectangle;track）
output_dir = 'dct_cond_output';
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% 【【核心参数：降采样步长】】
% 这个值决定了我们每隔多少个点来构建一个BR8单元。
% 值越大，单元越"厚"，越不容易报错。可以从5或10开始尝试。
path_subsampling_step = 20; 

output_unit_scaling = 10;   % 1 for meters

fprintf('输入文件目录: %s\n', input_dir);
fprintf('输出文件目录: %s\n', output_dir);
fprintf('路径降采样步长: %d\n', path_subsampling_step);

% --- 导体属性 ---
coil_width = 0.03; 
coil_height = 0.03;
current = 500; 
current_density = current / (coil_width * coil_height);
material_index = 1; 
drive_name = "'drive 1'";
fprintf('--- 导体属性 (BR8) ---\n');
fprintf('  截面宽度: %.4f m, 高度: %.4f m\n', coil_width, coil_height);
fprintf('  电流密度: %.2e A/m^2\n', current_density);
disp('---------------------------------------------------');

%% 3. 查找并准备文件
fprintf('--- 2. 开始查找并准备路径文件 ---\n');
file_pattern = fullfile(input_dir, 'dct_layer*_pole*_path.txt');
file_list = dir(file_pattern);
total_files = length(file_list);
if total_files == 0
    error('在目录 "%s" 中没有找到路径文件。', input_dir);
end
fprintf('找到 %d 个文件准备合并转换...\n', total_files);

%% 4. 【【【核心修改】】】合并生成单一.cond文件
% --- 打开一个总文件准备写入 ---
output_filename = fullfile(output_dir, 'all_layers.cond');
fid = fopen(output_filename, 'w');
if fid == -1, error('无法打开总文件写入: %s', output_filename); end
fprintf('正在写入总文件: %s\n', output_filename);

fprintf(fid, 'CONDUCTOR\n');

% --- 循环处理每个文件，将内容追加到总文件中 ---
for k = 1:total_files
    input_filename = fullfile(input_dir, file_list(k).name);
    fprintf('  > 正在合并文件: %s\n', input_filename);
    
    % --- 读取数据 ---
    try
        opts = detectImportOptions(input_filename, 'FileType', 'text');
        opts.Delimiter = {' ', '\t'};
        full_path_data_raw = readmatrix(input_filename, opts);
    catch ME, error('无法处理文件 %s. 错误: %s', input_filename, ME.message); end
    
    % --- 准备数据 (去掉闭合点并降采样) ---
    full_path_data = full_path_data_raw(1:end-1, :); % 只取开放路径部分
    if path_subsampling_step > 1
        full_path_data = full_path_data(1:path_subsampling_step:end, :);
    end
    num_points = size(full_path_data, 1);
    
    % --- 主体BR8单元生成 ---
    for pt_idx = 1:(num_points - 1)
        p1=full_path_data(pt_idx,1:3); n1=full_path_data(pt_idx,7:9); b1=full_path_data(pt_idx,10:12);
        p2=full_path_data(pt_idx+1,1:3); n2=full_path_data(pt_idx+1,7:9); b2=full_path_data(pt_idx+1,10:12);
        write_br8_element_corrected(fid, p1, n1, b1, p2, n2, b2, coil_width, coil_height, current_density, material_index, drive_name);
    end
    
    % --- 添加闭合单元 ---
    p_last=full_path_data(num_points,1:3); n_last=full_path_data(num_points,7:9); b_last=full_path_data(num_points,10:12);
    p_first=full_path_data(1,1:3); n_first=full_path_data(1,7:9); b_first=full_path_data(1,10:12);
    write_br8_element_corrected(fid, p_last, n_last, b_last, p_first, n_first, b_first, coil_width, coil_height, current_density, material_index, drive_name);
end

% --- 文件收尾 ---
fprintf(fid, 'QUIT\n');
fclose(fid);
fprintf('\n--- 所有线圈已成功写入总文件: %s ---\n', output_filename);


%% 辅助函数
function write_br8_element_corrected(fid, p1, n1, b1, p2, n2, b2, width, height, J, mat_idx, drive)
% 辅助函数: 【v52.0 - 绝对正确的BR8写入函数】
    v1=p1-width/2*n1-height/2*b1; v2=p1+width/2*n1-height/2*b1;
    v3=p1+width/2*n1+height/2*b1; v4=p1-width/2*n1+height/2*b1;
    v5=p2-width/2*n2-height/2*b2; v6=p2+width/2*n2-height/2*b2;
    v7=p2+width/2*n2+height/2*b2; v8=p2-width/2*n2+height/2*b2;
    fprintf(fid,'DEFINE BR8\n0 0 0 0 0 0\n0 0 0\n0 0 0\n');
    fprintf(fid,'%.8f %.8f %.8f\n',v1); fprintf(fid,'%.8f %.8f %.8f\n',v2);
    fprintf(fid,'%.8f %.8f %.8f\n',v3); fprintf(fid,'%.8f %.8f %.8f\n',v4);
    fprintf(fid,'%.8f %.8f %.8f\n',v5); fprintf(fid,'%.8f %.8f %.8f\n',v6);
    fprintf(fid,'%.8f %.8f %.8f\n',v7); fprintf(fid,'%.8f %.8f %.8f\n',v8);
    fprintf(fid,'%.8e %d %s\n',J,mat_idx,drive);
    fprintf(fid,'0 0 0\n1e-6\n');
end