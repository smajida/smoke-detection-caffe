tic
clear all;
addpath(genpath('libs'));
addpath(genpath('util'));

% set data source
date_path = '2015-05-02.timemachine/';
dataset_path = 'crf26-12fps-1424x800/';
tile_path = '1/2/2.mp4';

% read frames
target_dir = 'frames';
path = fullfile(target_dir,date_path,dataset_path,tile_path);
fprintf('Loading data.mat\n');
load(fullfile(path,'data.mat'));

% create workers
try
    fprintf('Closing any pools...\n');
    delete(gcp('nocreate'));
catch ME
    disp(ME.message);
end
local_cluster = parcluster('local');
num_workers = 3;
if(local_cluster.NumWorkers > num_workers + 1)
    num_workers = local_cluster.NumWorkers;
end
parpool('local',num_workers);

% compute texture for every image
texture = zeros(size(data),'uint8');
parfor t=1:size(data,4)
    fprintf('Processing frame %d\n',t);
    img = double(data(:,:,:,t));
    img_smooth = gaussianSmooth(img,0.5);
    img_smooth_lcn = mat2gray(localnormalize(img_smooth,64,64));
    texture(:,:,:,t) = im2uint8(mat2gray(entropyfilt(img_smooth_lcn,true(9,9))));
end

% save file
filename = 'texture.mat';
fprintf('Saving %s\n',filename);
save(fullfile(path,filename),'texture','-v7.3');

% close workers
delete(gcp('nocreate'));
toc