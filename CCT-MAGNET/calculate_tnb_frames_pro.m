function full_path_data = calculate_tnb_frames_pro(path_xyz)
% Compatibility wrapper that delegates to shared RMF TNB implementation.

this_dir = fileparts(mfilename('fullpath'));
src_dir = fullfile(this_dir, '..', '..', '..');
addpath(src_dir);
full_path_data = compute_tnb_rmf(path_xyz);
end
