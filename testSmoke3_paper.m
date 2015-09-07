clear all;
addpath(genpath('libs'));
addpath(genpath('util'));
select_box = 0;

t = 7543;
% t = [4369,4406,5108,5936,7000,6613,6617,7298,7435,7543,9007,9011,12929,12566];
% t = [7543,6617];

% set data source
date_path = '2015-05-02.timemachine/';
dataset_path = 'crf26-12fps-1424x800/';
tile_path = '1/2/2.mp4';

% read frames
target_dir = 'frames';
path = fullfile(target_dir,date_path,dataset_path,tile_path);
data_mat = matfile(fullfile(path,'data.mat'));
label_mat = matfile(fullfile(path,'label.mat'));
data_median_mat = matfile(fullfile(path,'data_median_60.mat'));

% define mask
if(select_box == 1)
    t_ref = 5936;
    img = data_mat.data(:,:,:,t_ref);
    [bbox_row,bbox_col] = selectBound(img);
    save(fullfile(path,'bbox.mat'),'bbox_row','bbox_col');
else
    load(fullfile(path,'bbox.mat'));
end

% compute filter bank (Laws' texture energy measures)
filter_bank = getFilterbank();

for i=1:numel(t)
    if(t(i)<3) 
        continue;
    end
    
    % crop an image and detect smoke
    img_label = label_mat.label(bbox_row,bbox_col,:,t(i));
    span = 5;
    imgs = data_mat.data(bbox_row,bbox_col,:,t(i)-span:span:t(i)+span);
    imgs_fd = cat(4,imgs(:,:,:,1),imgs(:,:,:,3));
    img_bg = data_median_mat.median(bbox_row,bbox_col,:,t(i));
    img = imgs(:,:,:,2);
    tic
    [val,imgs_filtered] = detectSmoke3(img,img_bg,filter_bank,imgs_fd);
    toc
    
    % visualize images
    fig = figure(51);
    img_cols = 4;
    img_rows = 2;
    fig_idx = 1;
    
    I = imgs(:,:,:,2);
    str = '$I_{t}$';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = img_bg;
    str = '$B_{t}$';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_HFCD.img_DoG;
    str = '$I_{DoG}$';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_HFCD.img_bg_DoG;
    str = '$B_{DoG}$';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_HFCD.img_bs_DoG;
    str = '$BS_{DoG}$';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_HFCD.img_bs_DoG_thr;
    str = '$S_{DoG}>thr1$';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_HFCD.img_bs_DoG_thr_entropy;
    str = '$\mathrm{Entropyfilt}(S_{DoG}>thr1)$';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.HFCD;
    str = 'HFCD';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);

    % print figure
    print_dir = 'figs';
    if ~exist(print_dir,'dir')
        mkdir(print_dir);
    end
    set(gcf,'PaperPositionMode','auto')
    print(fig,fullfile(print_dir,[num2str(t(i)),'_1']),'-dpng','-r0')
    
    % visualize images
    fig = figure(52);
    img_cols = 4;
    img_rows = 2;
    fig_idx = 1;
    
    I = imgs_filtered.imgs_IICD.img_histeq;
    str = 'img-histeq';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_IICD.img_bg_histeq;
    str = 'img-bg-histeq';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_IICD.img_bs_thr;
    str = 'img-bs-thr';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_IICD.img_bs_thr_smooth;
    str = 'img-bs-thr-smooth';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_IICD.img_last_histeq;
    str = 'img-last-histeq';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_IICD.img_last_diff_thr;
    str = 'img-last-diff-thr';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.imgs_IICD.img_last_diff_thr_smooth;
    str = 'img-last-diff-thr-smooth';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    I = imgs_filtered.IICD;
    str = 'IICD';
    math = '';
    fig_idx = subplotSerial(I,img_rows,img_cols,fig_idx,'',str,math);
    
    % print figure
    print_dir = 'figs';
    if ~exist(print_dir,'dir')
        mkdir(print_dir);
    end
    set(gcf,'PaperPositionMode','auto')
    print(fig,fullfile(print_dir,[num2str(t(i)),'_2']),'-dpng','-r0')
end