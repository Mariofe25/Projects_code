
n_ts = ~tss.has_var("ca_state");
if sum(n_ts) > 0
    disp(sum(n_ts) + " tseries w/o ca_states var")
    tss = tss(~n_ts);   
end
    
genotypes = ["Bl6","IP3R2","AQP4_kokw","AQP4_koko"];
tss_path = string({tss.path})';
types = ["still","still_whisk","run","trans_still_run"];
for j = 1:numel(genotypes)
    s = regexp(tss_path,genotypes(j));
    gen_idx = find(~cellfun(@isempty,s));
    tss_selected = tss(gen_idx);
    ca_states = tss_selected.load_var("ca_state");
    ca_states = [ca_states{:}];
    for i = 1:numel(types)
        
        % concatenate all ca signal in a column vector
        ca_all = arrayfun(@(s) reshape(s.(types(i)),[],1), ca_states,'UniformOutput',false);
        ca_all = vertcat(ca_all{:});
        
        % concatenate roi types in column vector. Assign roi type to each row       
        roi_types_all = arrayfun(@(s) repmat(s.roi_type',size(s.(types(i)),1),1), ca_states,'UniformOutput',false);
        roi_types_all =  cellfun(@(s) reshape(s,[],1),roi_types_all,'UniformOutput',false);
        roi_types_all = vertcat(roi_types_all{:});
        
        % plotting
        f = figure;
        boxplot(ca_all,roi_types_all)
        title(genotypes(j)+ "    " + types(i))
        folder_path = "/Volumes/Xiaoyi2/4mt/Plots/Analysis";
        file_name = genotypes(j) + "_" + types(i);
        outpng = fullfile(folder_path,file_name);
        print(f,outpng,'-r300','-dpng')
        delete(f)         
    end
end