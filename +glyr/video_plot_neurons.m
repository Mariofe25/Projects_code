tss = begonia.scantype.find_scans('/Volumes/GlyR/GlyR project/img/BR/TSeries-04162021-1356-003_stabilized.h5');
% tss = begonia.scantype.find_scans(get_ts_path + "Glyr/img/ts")

begonia.logging.set_level(1);

for i = 1:length(tss)
    ts = tss(i);
    rois = begonia.processing.roi.load_processed_signals(ts);
    ns_rois = rois(rois.channel == 2 & rois.type == "NS",:);
    np_rois = rois(rois.channel == 2 & rois.type == "Np",:);
    donut_rois = ts.load_var('donut_dff');

    % get the frames
    mat_original = ts.get_mat(2);
    
    merged_frames = 10;
    
    mat_original = begonia.util.stepping_window(mat_original,merged_frames,1);
        
    frames = 1:size(mat_original,3);
    
    roi_padding = 10;
    
    for j = 1:height(ns_rois)
        %%
        % Find closest np roi       
        x_pos = ns_rois.center_x;
        y_pos = ns_rois.center_y;
        
%         np_pos = [np.]
        
        arrayfun(@(a) pdist2([x_pos,y_pos],[a.center_x,a.center_y]),np_rois)
        
        
        % Crop fov       
        [y,x] = find(roi_table.mask{j});
        
        x_min = min(x);
        x_max = max(x);
        y_min = min(y);
        y_max = max(y);
        
        x_min = x_min - roi_padding;
        x_max = x_max + roi_padding;
        y_min = y_min - roi_padding;
        y_max = y_max + roi_padding;
        
        x_min = max(1,x_min);
        x_max = min(512,x_max);
        y_min = max(1,y_min);
        y_max = min(512,y_max);
        
        mat = mat_original(y_min:y_max,x_min:x_max,:);
        
        % create tilelayout
        fig = figure("Position",[928,253,1118,979]);
        layout = tiledlayout(5,5);
        title(layout,"Signal overview " + roi_table.short_name(j))
        
        filename = sprintf("/Volumes/GlyR/Neuron ROI video/%s/%s",ts.name,roi_table.short_name(j));
        begonia.path.make_dirs(filename);
        v = VideoWriter(filename,"MPEG-4");
        v.open();

        ax_neuron = nexttile(1,[2 2]);
        img_neuron = imagesc(mat(:,:,1));
        
        ax_dff= nexttile(3,[1 3]);
        trace_1 = plot(ax_dff,smooth(roi_neurons{j}));        
        xlim([0,length(roi_signals_raw.signal_raw{j})])
        
        ax_sub = nexttile(3,[1 3]);
        trace_1 = plot(ax_sub,smooth(roi_signals_raw.signal_raw{j}));        
        xlim([0,length(roi_signals_raw.signal_raw{j})])
        
        
        
% plot frames and save video
        tic
        for frame = frames
            if toc > 1
                begonia.logging.log(1,"%d/%d",frame,frames(end));
                tic
            end
            img_neuron.CData = mat(:,:,frame);
            
            r = roi_signals_raw.signal_raw{j};
            r(frame:end) = nan;
            trace_1.YData = r;
            
            v.writeVideo(getframe(fig));
            
        end
        v.close();
        disp("finished")
        close(fig);

%         ax2 = nexttile(16,[2 2]);
%         imagesc(mat_s(:,:,1))
%         title()
% 
%         ax3 = nexttile(3,[1 3])
%         plot(ax2)
%         title()
% 
%         ax4 = nexttile(8,[1 3])
%         plot()
%         title()
% 
%         ax5 = nexttile(13,[1 3])
%         plot()
%         title()
% 
%         ax6 = nexttile(18,[1 3])
%         plot()
%         title()
% 
%         ax7 = nexttile(23,[1 3])
%         plot()
%         title()
% 
% 
%         imagesc(cell2mat(ast.rois));
%         title("Astrocytes (df/f0)"); xlabel("Frame (#)"); colorbar();
% 
%         yticks(ast_type_start); yticklabels(ast_types);
%         axis tight
% 
%         ax2 = nexttile();
%         imagesc(cell2mat(neu.rois));
%         title("Neurons (df/f0)"); xlabel("Frame (#)"); colorbar();
%         yticks(neu_type_start); yticklabels(neu_types);
%         axis tight




        % function [limits_y, limits_x] =  get_limits(ns_mask,mat)
        % 
        % fov_dim = size(mat,[1,2]); 
        % 
        % [y,x] = find(ns_mask{:});
        % 
        % 
        % if r
        %     
        % xtra_px = 25
        % 
        % limits_y = [min(y) - xtra_px
        % 
        % 
        % 
        % 
        % 
        % 
        % end
        % 
        % mat = ts.get_mat(2);
        % m = mat(:,:,:);
        % mat_s  = begonia.util.stepping_window(mat,30);
        % mx = max(mat_m,[],'all');
        % mn = min(mat_m,[],'all');
        % yucca.plot.matview(mat_m,[mn mx])
    end
end