tsName = string({tss.name})';
tab = readtable(mice_path,"Sheet",2);
[~,idx] = ismember(tsName,tab.TSeriesId);

mice = tab.Mouse(idx);

for i = 1:length(tss)
    tss(i).save_var('mouse', mice{i});
end

