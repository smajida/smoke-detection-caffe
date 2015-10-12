tic
clear all;
addpath(genpath('libs'));
addpath(genpath('util'));
use_simple_label = true;
% plot_result = true;
plot_result = false;
smoke_level = 2;

date = getProcessingDates();

% read mask
target_dir = 'frames';
fprintf('Loading bbox.mat\n');
load(fullfile(target_dir,'bbox.mat'));

% for uploading to esdr
data_esdr = struct();
data_esdr.channel_names = cell(1,2);
data_esdr.channel_names{1} = 'smoke_level';
data_esdr.channel_names{2} = '';
smoke = [];

% parameters
sigma = 0.5;

for idx=1:numel(date)
    try
        fprintf('Processing date %s\n',date{idx});

        % set data source
        date_path = [date{idx},'.timemachine/'];
        dataset_path = 'crf26-12fps-1424x800/';
        tile_path = '1/2/2.mp4';
        path = fullfile(target_dir,date_path,dataset_path,tile_path);
        load(fullfile(path,'sun_frame.mat'));

        % 2015-05-01 after steam
        % sunrise_frame = 7900;

        % 2015-05-02 after steam
        % sunrise_frame = 6800; 

        % 2015-05-03 after steam
        % sunrise_frame = 6700;

        % Gaussian smooth the prediction
        load(fullfile(path,'response.mat'));
        response = filter1D(response,sigma);

        % find local max with steam
        min_peak_prominence = 150;
        min_peak_height = 150;
        min_peak_distance = 0;
        thr = 0;
        min_peak_width = 1.15;
        max_peak_width = 6;
        [pks,locs,w,p] = findpeaks(response,'MinPeakProminence',min_peak_prominence,'MinPeakHeight',min_peak_height,'MinPeakDistance',min_peak_distance,'Threshold',thr,'MaxPeakWidth',max_peak_width,'MinPeakWidth',min_peak_width);

        % remove night time idx
        idx_remove = find(locs<sunrise_frame | locs>sunset_frame);
        pks(idx_remove) = [];
        locs(idx_remove) = [];
        w(idx_remove) = [];
        p(idx_remove) = [];

        % prediction
        predict = false(size(response));
        for j=1:length(locs)
            w_ = w(j)*2;
            predict(round(locs(j)-w_):round(locs(j)+w_)) = true;
        end
        predict = double(predict);

        if(plot_result)
            % load ground truth
            if(use_simple_label)
                load(fullfile(path,'label_simple.mat'));
                truth = double(label_simple);
            else
                load(fullfile(path,'label.mat'));
                % count the number of true smoke pixels in each images
                sum_smoke_pixel = sum(reshape(label(bbox_row,bbox_col,:,:),[],size(label,4)));
                truth = double(sum_smoke_pixel>0);
            end
            truth(1:sunrise_frame) = 0;
            truth(sunset_frame:end) = 0;
            truth_plot = truth;
            if(use_simple_label)
                truth(truth<smoke_level) = 0;
            end

            % compute F-score
            if(use_simple_label)
                fscore = computeFscore(truth>=smoke_level,predict);
            else
                fscore = computeFscore(truth,predict);
            end
            fscore.date = date{idx}

            % plot ground truth and prediction
            fig = figure(98);
            fig_idx = 1;
            img_cols = 1;
            if(use_simple_label)
                img_rows = 3;
            else
                img_rows = 4;
            end

            if(~use_simple_label)
                subplot(img_rows,img_cols,fig_idx)
                bar(sum_smoke_pixel,'r')
                xlim([sunrise_frame sunset_frame])
                title(['Ground truth ( ',date{idx},' )'])
                fig_idx = fig_idx + 1;
            end

            subplot(img_rows,img_cols,fig_idx)
            plot(response,'b')
            xlim([sunrise_frame sunset_frame])
            title('Response of smoke detection')
            hold on
            plot(locs,pks,'ro')
            hold off
            fig_idx = fig_idx + 1;

            subplot(img_rows,img_cols,fig_idx)
            bar(predict,'b')
            xlim([sunrise_frame sunset_frame])
            set(gca,'YTickLabel',[]);
            set(gca,'YTick',[]);
            round_to = 2;
            fscore_str = ['(',num2str(round(fscore.precision,round_to)),', ',num2str(round(fscore.recall,round_to)),', ',num2str(round(fscore.score,round_to)),')'];
            title(['Predicted frames: (precision, recall, fscore) = ',fscore_str])
            fig_idx = fig_idx + 1;

            subplot(img_rows,img_cols,fig_idx)
            bar(truth_plot,'r')
            xlim([sunrise_frame sunset_frame])
            set(gca,'YTickLabel',[]);
            set(gca,'YTick',[]);
            title(['Ground truth ( ',date{idx},' )'])
            fig_idx = fig_idx + 1;

            % print figure
            print_dir = 'figs';
            if ~exist(print_dir,'dir')
                mkdir(print_dir);
            end
            set(gcf,'PaperPositionMode','auto')
            print(fig,fullfile(print_dir,date{idx}),'-dpng','-r0')
        end

        % output a json file
        js_dir = 'js';
        if ~exist(js_dir,'dir')
            mkdir(js_dir);
        end
        response(1:sunrise_frame) = 0;
        response(sunset_frame:end) = 0;
        response = round(response);
        js = array2json(response,predict);
        fileID = fopen(fullfile(js_dir,['smoke-',date{idx},'.js']),'w');
        fprintf(fileID,js);
        fclose(fileID);

        % save data for uploading to esdr
        load(fullfile(path,'info.mat'));
        datetime_all = posixtime(datetime(tm_json.capture_times));
        datetime_all = datetime_all';
        datetime_all = datetime_all(sunrise_frame:sunset_frame);
        response = response(sunrise_frame:sunset_frame);
        smoke = cat(1,smoke,cat(2,datetime_all,response));
    catch ME
        fprintf('Error detecting smoke of date %s\n',date{idx});
        logError(ME);
    end
end

data_esdr.data = smoke;
savejson('',data_esdr,'json/data.json');

fprintf('Done\n');
toc