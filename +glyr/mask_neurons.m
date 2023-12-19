function [signals_raw,signals_dff,subtracted_dff,f_mask] = mask_neurons(tss)
% Remove nuclei pixels from neurons somas(NS) to increase SNR. 
% f_mask is the mask of the FoV, showing the NS w/o the nuclei

for ts = tss   
    ch2 = ts.load_var("img_avg_ch2_cy1");
    rois = ts.load_var("roi_table");
    ns_idx = rois.type == "NS";
    neuron_rois = rois(ns_idx,:);
    neuron_donut = ts.load_var("roi_signals_doughnut");
    neuron_donut = neuron_donut.signal_doughnut(ns_idx);
    
    % Frames pixel values
    mat = ts.get_mat(2,1);
    % Load array in memeroy to speed it up
    mat = mat(:,:,:);
    
    % Segment/remove nuclei pixels. Get signals from new NS mask
    for i = 1: height(neuron_rois)
        mask = neuron_rois.mask{i};
        fx = find(sum(mask, 1), 1, 'first');
        fy = find(sum(mask, 2), 1, 'first');
        tx = find(sum(mask, 1), 1, 'last');
        ty = find(sum(mask, 2), 1, 'last');
        
        mask = double(mask);
        mat_roi = ch2(fy:ty, fx:tx,:) .* mask(fy:ty, fx:tx);
        
        nonan = mat_roi;
        nonan(nonan == 0) = nan;
        
        threshold = multithresh(nonan,2); %2 or 3
        
        segmented_mask = imquantize(mat_roi,threshold);
        
        bin_mask = segmented_mask > 1;
        
        new_mask = zeros(512,512);
        new_mask(fy:ty,fx:tx) = bin_mask;
        
        f_mask{i} = new_mask;     
        
        % raw signal
        signals{i} = begonia.processing.roi.extract_single_roi_signal([],mat,new_mask);            
    end

    % dff signal
    signals_raw = vertcat(signals{:});
    f0 = mode(round(signals_raw), 2);
    signals_dff = (signals_raw ./ f0) - 1;  
    
    % Subtract dff signal    
    %subtracted_dff = cell(size(signals_raw,1),1);
    for j = 1:size(signals_raw,1)
        y = signals_raw(j,:)';
        X = neuron_donut{j}';
        
        b = (X'*X)\(X'*y);
        y_hat = (X * b);
        trace = (y - y_hat)/f0(j);
        
       subtracted_dff(j,:) = trace;
    end
    
    % Mask neurons
    f_mask = sum(cat(3,f_mask{:}),3);
      
end
end