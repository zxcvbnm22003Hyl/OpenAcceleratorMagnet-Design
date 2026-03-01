clear; clc; close all;

this_dir = fileparts(mfilename('fullpath'));

coil_width = 0.005;
coil_height = 0.005;
material_index = 1;
drive_name = '''one''';
output_cond_file = fullfile(this_dir, 'cct_coils.cond');

layers = [ ...
    struct('input_path_file', fullfile(this_dir, 'discrete_cct_inner.txt'), 'current_density', 500), ...
    struct('input_path_file', fullfile(this_dir, 'discrete_cct_outer.txt'), 'current_density', -500) ...
];

export_br20_combined_file(layers, coil_width, coil_height, material_index, drive_name, output_cond_file);

function export_br20_combined_file(layers, coil_width, coil_height, material_index, drive_name, output_cond_file)
fileID = fopen(output_cond_file, 'w');
if fileID == -1
    error('Cannot open output file: %s', output_cond_file);
end

fprintf(fileID, 'CONDUCTOR\n');
for j = 1:numel(layers)
    full_path_data = readmatrix(layers(j).input_path_file);
    if size(full_path_data, 2) < 12
        error('File must contain at least 12 columns: %s', layers(j).input_path_file);
    end

    num_points = size(full_path_data, 1);
    for k = 1:(num_points - 1)
        p1 = full_path_data(k, 1:3);
        t1 = full_path_data(k, 4:6);
        n1 = full_path_data(k, 7:9);
        b1 = full_path_data(k, 10:12);

        p2 = full_path_data(k + 1, 1:3);
        t2 = full_path_data(k + 1, 4:6);
        n2 = full_path_data(k + 1, 7:9);
        b2 = full_path_data(k + 1, 10:12);

        c1 = p1 - coil_width / 2 * n1 - coil_height / 2 * b1;
        c2 = p1 + coil_width / 2 * n1 - coil_height / 2 * b1;
        c3 = p1 + coil_width / 2 * n1 + coil_height / 2 * b1;
        c4 = p1 - coil_width / 2 * n1 + coil_height / 2 * b1;

        c5 = p2 - coil_width / 2 * n2 - coil_height / 2 * b2;
        c6 = p2 + coil_width / 2 * n2 - coil_height / 2 * b2;
        c7 = p2 + coil_width / 2 * n2 + coil_height / 2 * b2;
        c8 = p2 - coil_width / 2 * n2 + coil_height / 2 * b2;

        L = norm(p2 - p1);
        path_correction = L / 8 * (t1 - t2);

        vertices = zeros(20, 3);
        vertices(1, :) = c2; vertices(2, :) = c3; vertices(3, :) = c4; vertices(4, :) = c1;
        vertices(5, :) = c6; vertices(6, :) = c7; vertices(7, :) = c8; vertices(8, :) = c5;
        vertices(9, :) = (vertices(1, :) + vertices(2, :)) / 2;
        vertices(10, :) = (vertices(2, :) + vertices(3, :)) / 2;
        vertices(11, :) = (vertices(3, :) + vertices(4, :)) / 2;
        vertices(12, :) = (vertices(4, :) + vertices(1, :)) / 2;
        vertices(13, :) = (vertices(1, :) + vertices(5, :)) / 2 + path_correction;
        vertices(14, :) = (vertices(2, :) + vertices(6, :)) / 2 + path_correction;
        vertices(15, :) = (vertices(3, :) + vertices(7, :)) / 2 + path_correction;
        vertices(16, :) = (vertices(4, :) + vertices(8, :)) / 2 + path_correction;
        vertices(17, :) = (vertices(5, :) + vertices(6, :)) / 2;
        vertices(18, :) = (vertices(6, :) + vertices(7, :)) / 2;
        vertices(19, :) = (vertices(7, :) + vertices(8, :)) / 2;
        vertices(20, :) = (vertices(8, :) + vertices(5, :)) / 2;

        fprintf(fileID, 'DEFINE BR20\n');
        fprintf(fileID, '0.0 0.0 0.0 0.0 0.0 0.0\n');
        fprintf(fileID, '0.0 0.0 0.0\n');
        fprintf(fileID, '0.0 0.0 0.0\n');
        fprintf(fileID, '%.8f %.8f %.8f\n', vertices');
        fprintf(fileID, '%.8e %d %s\n', layers(j).current_density, material_index, drive_name);
        fprintf(fileID, '0 0 0\n');
        fprintf(fileID, '0.0\n');
    end
end

fprintf(fileID, 'QUIT\n');
fclose(fileID);
end
