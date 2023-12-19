function compare_wall(tss)
% Load wall mtabs
tab = table();
for ts  = tss
    if ts.has_var("mtab_wall")
        t =  ts.load_var("mtab_wall");
    else
        continue
    end
    tab =[tab;t];
end
tab(tab.roi_type == "ND",:) = [];
tab(tab.roi_type == "Gp",:) = [];

% Split mtab
pre = tab(tab.wall_cat == "Pre_wall",:);
dur = tab(tab.wall_cat == "Early_wall",:);
post = tab(tab.wall_cat == "Late_wall",:);

% Merge rois
pre = merge_it(pre);
dur = merge_it(dur);
post = merge_it(post);

% Plot by roi type

r_t = unique(pre.roi_type);




histogram(pre.mean_trace)

mtab = [pre;dur;post];
r_t = unique(mtab.roi_type);

for i = 1:length(r_t)
    
    
   otab = mtab(mtab.roi_type == r_t,:);
   ev = otab.n_events(otab.wall_cat =="Ea
   
    
    ntab
    
    
    
    
    
    
    
    
end



boxchart(categorical(mtab.roi_type),mtab.mean_trace,'GroupByColor',categorical(mtab.wall_cat))




end

function merge_tab = merge_it(mtab)
rois = unique(mtab.roi_short_name,'stable');
mtab = mtab(:,[3,4,11:20]);
for i = 1:length(rois)
    roi =  mtab(mtab.roi_short_name == rois(i),:);
    p = roi(1,:);
    p.trace = {[roi.trace{:}]};
    p.mean_trace = mean(p.trace{:},"all");
    p.max_trace = mean(max(p.trace{:}));
    p.n_events = mean(roi.n_events);
    p.event_in = mean(roi.event_in);
    merge_tab(i,:) = p;
end
end





