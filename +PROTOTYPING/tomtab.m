clear data
g = unique(mtab.tab.group_id);

for i = 2:length(g)
    
    data{i} = mtab.by_group_id(string(g(i)),1/10,"trim");
    data{i}= mtab.tag_to_column (data{i}, "roi_channel", @categorical);
    data{i} = mtab.tag_to_column(data{i}, "roi_group", @categorical);
    data{i} = mtab.tag_to_column(data{i}, "mouse", @categorical);
    data{i}= mtab.tag_to_column(data{i}, "state", @string);
    
end

