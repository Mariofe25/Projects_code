function  get_frame_position(tss)
% Grab the frame position from the tseries metadata to determine to which
% Field of View (FoV) they belong.
frame_position = zeros(length(tss),3);

for t = 1:length(tss)
    try
        frame_position(t,:,:) = tss(t).frame_position_um;
    catch
        frame_position(t,:,:) = [];
    end
end

[~,~,fov] = unique(frame_position,'rows',"stable");

% Check that tseries are recorded the same day. In the unlikely case that
% the have the same fov but are not recorded the same day, assign a
% different fov number.
pos = unique(fov);
reorganize = false;
for p = 1:length(pos)
    fov_idx = fov == pos(p);
    t_pos = tss(fov_idx);
    dat = arrayfun(@(t) t.start_time,t_pos);
    formatOut = 'mm/dd/yy';
    dat = datestr(dat,formatOut);
    dat = string(dat);
    [pos_intra,~,intra_fov] = unique(dat,"stable");
    if numel(pos_intra) > 1
        n = 1;
        for s = 2:max(intra_fov)
            intra_fov(intra_fov == s) =  max(fov) + n;
            n = n + 1;
        end
        fov(fov_idx) = intra_fov;
        reorganize = true;
    end
end

% Reorganize FoVs if necessary
% ff = unique(fov,"stable");
% start_fov = arrayfun(@(s) find(fov == s,1,"first"),ff);
if reorganize
    [~,start_fov,~] = unique(fov,"stable");
    for i = 1:length(start_fov) -1
        fov(start_fov(i):start_fov(i + 1) - 1) = i;
        fov(start_fov(end):length(fov)) = i + 1;
    end
end

% Save FoV
for i = 1:length(fov)
    tss(i).save_var('FoV',fov(i))
end
end