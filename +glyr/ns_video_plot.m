%ts = begonia.scantype.find_scans(ts.path);
% tss = begonia.scantype.find_scans(get_ts_path + "Glyr/img/ts")

begonia.logging.set_level(1);

for i = 1:length(ts)
    %% Get rois and smooth neuron channel
    % load rois
    rois = begonia.processing.roi.load_processed_signals(ts);
    ns_rois = rois(rois.channel == 2 & rois.type == "NS",:);
    np_rois = rois(rois.channel == 2 & rois.type == "Np",:);
    donut_rois = ts.load_var('donut_dff');
    
    % get the frames
    mat_original = ts.get_mat(2); % 2 == neuron channel
    window_smooth = 10;
    merge = 2;
    % smooth images. When input 3 is 1 it does not merge (it is like using
    % movmean)
    mat_original = begonia.util.stepping_window(mat_original,window_smooth,merge);
    frames = 1:size(mat_original,3);
    
    roi_padding = 10;
    
    %%
    
    
    for j = 1:height(ns_rois)
        %% Create layout
        % Find closest np roi
        x_pos = ns_rois.center_x(j);
        y_pos = ns_rois.center_y(j);
        
        np_pos= [np_rois.center_x,np_rois.center_y];
        
        for k = 1:height(np_rois)
            dist(k) = pdist2([x_pos,y_pos],[np_pos(k,1),np_pos(k,2)]);
        end
        [~,I] = min(dist);
        
        % Subtract np
        ns_raw = ns_rois.signal_raw{j};
        f0 = ns_rois.f0(22);
        np = np_rois.signal_raw{I};
        y = ns_raw';
        X = np';
        
        b = (X'*X)\(X'*y);
        y_hat = X * b;
        trace = (y - y_hat)/f0;
        Ns_subtract = trace';
        
        % Edges ns & np masks
        ns_mask = ns_rois.mask{j};
        np_mask = np_rois.mask{I};
        
        % Crop fov
        [y,x] = find(ns_mask);
        
        x_min = min(x);
        x_max = max(x);
        y_min = min(y);
        y_max = max(y);
        
        x_min = x_min - roi_padding;
        x_max = x_max + roi_padding;
        y_min = y_min - roi_padding;
        y_max = y_max + roi_padding;
        
        % min value is 1 and max is 512 (resolution is 512x512)
        x_min = max(1,x_min);
        x_max = min(512,x_max);
        y_min = max(1,y_min);
        y_max = min(512,y_max);
        
        mat = mat_original(y_min:y_max,x_min:x_max,:);
        mask_ns_mat = ns_rois.mask{22}(y_min:y_max,x_min:x_max);
        
        % create tilelayout
        fig = figure("Position",[928,253,1118,979]);
        layout = tiledlayout(5,5);
        title(layout,"Signal overview " + ns_rois.short_name(j))
        
        % create video
        filename = sprintf("/Volumes/GlyR/Neuron ROI video/%s/%s",ts.name,ns_rois.short_name(j));
        begonia.path.make_dirs(filename);
        v = VideoWriter(filename,"MPEG-4");
        v.open();
        
        % single neuron image
        ax_neuron = nexttile(1,[2 2]);
        img_neuron = imagesc(mat(:,:,20));
        title(ns_rois.short_name{j})
        hold on
        visboundaries(mask_ns_mat,"Color","r")
        
        % foV w/ target ns and np image
        ax_neurons = nexttile(16,[2 2]);
        img_neurons = imagesc(mat_original(:,:,1));
        title("FoV")
        hold on
        visboundaries(ns_mask,"Color","r")
        visboundaries(np_mask,"Color",[0.8 0.3 0])
        
        % ns dff
        ns_dff = smooth(ns_rois.signal_dff{j});
        ax_dff = nexttile(3,[1 3]);
        trace_1 = plot(ax_dff,ns_dff);
        xlim([0,length(ns_rois.signal_dff{j})])
        title("NS dff")
        
        % ns dff subtracted
        ns_dff_sub = smooth(ns_rois.signal_subtracted_dff{j});
        ax_sub = nexttile(8,[1 3]);
        trace_2 = plot(ax_sub,ns_dff_sub);
        xlim([0,length(ns_rois.signal_subtracted_dff{j})])
        title("NS dff donut subtracted")
        
        % ns donut dff
        donut_dff = smooth(donut_rois.signal_donut_dff{j});
        ax_d = nexttile(13,[1 3]);
        trace_3 = plot(ax_d,donut_dff);
        xlim([0,length(donut_rois.signal_donut_dff{j})])
        title("donut dff")
        
        % np dff
        np_dff = smooth(np_rois.signal_dff{I});
        ax_np = nexttile(18,[1 3]);
        trace_4 = plot(ax_np,np_dff);
        xlim([0,length(np_rois.signal_dff{I})])
        title("Np dff")
        
        % ns w/ np subtracted
        nsp_sub = smooth(Ns_subtract);
        ax_nsp = nexttile(23,[1 3]);
        trace_5 = plot(ax_nsp,nsp_sub);
        xlim([0,length(Ns_subtract)])
        title("Ns-np subtracted")
        
        linkaxes([ax_dff,ax_sub,ax_d,ax_np,ax_nsp],'xy')
        
        %% Plot frames and save video
        tic
        for frame = frames
            if toc > 1
                begonia.logging.log(1,"%d/%d",frame,frames(end));
                tic
            end
            % single neuron
            img_neuron.CData = mat(:,:,frame);
            
            % FoV
            img_neurons.CData = mat_original(:,:,frame);
            
            % dff
            r = ns_dff;
            r(frame*merge:end) = nan;
            trace_1.YData = r;
            
            % dff subtracted
            s = ns_dff_sub;
            s(frame*merge:end) = nan;
            trace_2.YData = s;
            
            % donut dff
            d = donut_dff;
            d(frame*merge:end) = nan;
            trace_3.YData = d;
            
            % np dff
            n = np_dff;
            n(frame*merge:end) = nan;
            trace_4.YData = n;
            
            % ns-np subtracted
            nsp = nsp_sub;
            nsp(frame*merge:end) = nan;
            trace_5.YData = nsp;
            
            % update frame
            v.writeVideo(getframe(fig));
        end
        
        v.close();
        disp("finished")
        close(fig);
        
    end
end