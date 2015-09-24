clear all;
addpath(genpath('libs'));
addpath(genpath('util'));
show_has_label_only = 0;

% set data source
date_path = '2015-05-07.timemachine/';
dataset_path = 'crf26-12fps-1424x800/';
tile_path = '1/2/2.mp4';

% read images
target_dir = 'frames';
path = fullfile(target_dir,date_path,dataset_path,tile_path);
load(fullfile(path,'info.mat'));
data_mat = matfile(fullfile(path,'data.mat'));
label_simple_mat = matfile(fullfile(path,'label_simple.mat'),'Writable',true);

% find frames that have labels
label_simple = label_simple_mat.label_simple;
label_simple_idx = find(label_simple==1);

% label images
global t
global toggle
t = 7500;
toggle = -1;
fig = figure(1);
set(fig,'KeyPressFcn',{@keyDownListenerLabelDataSimple,r_json.frames,data_mat,label_simple_mat,label_simple_idx,show_has_label_only});