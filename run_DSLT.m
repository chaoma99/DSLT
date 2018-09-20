
function [precision, fps] = run_DSLT(video, show_visualization, show_plots)

    dbstop if error;
    close all;
    
    %path to the videos (you'll be able to choose one with the GUI).
    base_path = './OTB_dataset';
    addpath(genpath('toolbox'));
    
    %res_path = 'results3/';
%     if ~exist(res_path)
%         mkdir(res_path);
%     end
    
    addpath('util');
   
	%default settings
	if nargin < 1, video = 'choose'; end
	if nargin < 2, show_visualization = ~strcmp(video, 'all'); end
	if nargin < 3, show_plots = ~strcmp(video, 'all'); end
	
    switch video
	case 'choose',
		%ask the user for the video, then call self with that video name.
		video = choose_video(base_path);
		if ~isempty(video),
			[precision, fps] = run_DSLT(video,show_visualization, show_plots);
            
			if nargout == 0,  %don't output precision as an argument
				clear precision
			end
		end
				
	case 'all',
		%all videos, call self with each video name.
		
		%only keep valid directory names
		dirs = dir(base_path);
		videos = {dirs.name};
		videos(strcmp('.', videos) | strcmp('..', videos) | ...
			strcmp('anno', videos) | ~[dirs.isdir]) = [];
		
		%the 'Jogging' sequence has 2 targets, create one entry for each.
		%we could make this more general if multiple targets per video
		%becomes a common occurence.
        if numel(videos)>51
		
	        videos(strcmpi('Skating2', videos)) = [];
		    videos(end+1:end+2) = {'Skating2.1', 'Skating2.2'};
            %videos(strcmpi('Jogging', videos)) = [];
		    %videos(end+1:end+2) = {'Jogging.1', 'Jogging.2'};
        else
            %videos(strcmpi('Jogging', videos)) = [];
		    %videos(end+1:end+2) = {'Jogging.1', 'Jogging.2'};
        end
		all_precisions = zeros(numel(videos),1);  %to compute averages
		all_fps = zeros(numel(videos),1);
		
% 		if ~exist('matlabpool', 'file'),
% 			%no parallel toolbox, use a simple 'for' to iterate
% 			for k = 1:numel(videos),
% 				[all_precisions(k), all_fps(k)] = run_tracker(videos{k}, show_visualization, show_plots);
% 			end
% 		else
			%evaluate trackers for all videos in parallel
% 			if matlabpool('size') == 0,
% 				matlabpool open;
% 			end
			for k = 1:numel(videos),
				[all_precisions(k), all_fps(k)] = run_DCT(videos{k}, show_visualization, show_plots);
			end
		%end
		
		%compute average precision at 20px, and FPS
		mean_precision = mean(all_precisions);
		fps = mean(all_fps);
		fprintf('\nAverage precision (20px):% 1.3f, Average FPS:% 4.2f\n\n', mean_precision, fps)
		if nargout > 0,
			precision = mean_precision;
        end
		
		
	otherwise
		%we were given the name of a single video to process.
	
		%get image file names, initial state, and ground truth for evaluation
		[img_files, pos, target_sz, ground_truth, ground_truth1, video_path] = load_video_info(base_path, video);
		
        seq.name = video;
        seq.img_files = img_files;
        seq.path = video_path;
        im_name = img_files{1,1};
        seq.startFrame = str2num(im_name(1:end-4));
        seq.endFrame = size(ground_truth,1);
        seq.init_rect = [pos([2,1])-target_sz([2,1])./2 target_sz([2,1])];
      
        res = DSLT(seq, show_visualization); %main function
		len = size(res,1);
        results.type = 'rect';
        results.res = res.res;
        results.len = size(res.res,1);        
        positions1= res.res(:,[2,1]);
        positions1 = positions1 + res.res(:,[4,3])./2;
        %positions1(:,[3,4]) = positions(:,[4,3]);
		%calculate and show precision plot, as well as frames-per-second
		precisions = precision_plot(positions1, ground_truth, video, show_plots);
		
        fprintf('%12s - Precision (20px):% 1.3f', video, precisions(20))
        %fprintf('Center Location Error: %.3g pixels\nDistance Precision: %.3g %%\nOverlap Precision: %.3g \n', ...
		
        prec = precisions(20);
        
        %save([res_path video '.mat'],'prec');
       
        
		if nargout > 0,
			%return precisions at a 20 pixels threshold
			precision = precisions(20);
        end

         fps=1;
	end
end
