function responsiveness(path,threshold_type)

if nargin < 2, threshold_type = "3std"; end
if nargin < 1, path ='/Users/mariofernandez/Downloads/jarand-copy/analysis/latency';end

dirs = dir(path);
thres = string({dirs.name})';
thres_idx = find(thres == threshold_type);
thres_folder = fullfile(dirs(thres_idx).folder, dirs(thres_idx).name);
exp_folders = dir(fullfile(thres_folder,'Plots'));
exp_tag = string({exp_folders.name})';
exp_tag = exp_tag(~contains(exp_tag,'.'));
tags = ["Control" , "KB ", "KB+PP"];
comps = ["AE","AP","AS"];
color = rand(5,3);
for i = 1:numel(tags)
    fig = figure;
    exp_idx = find(contains(string({exp_folders.name})',tags(i)));
    exp_names = string({exp_folders(exp_idx).name});
    exp_paths = arrayfun(@(s) fullfile(exp_folders(s).folder,exp_folders(s).name),exp_idx,'UniformOutput',false);
    for j = 1:numel(comps)
        comp_path = fullfile(exp_paths,comps(j));
        co = char(comps(j));
        for c = 1:numel(comp_path)
            p = char(comp_path(c));
            d = dir([p,'/**/',co,'*.png']);
            d_folders = string({d.folder})';
            exp(c,:) = exp_names(c);
            total(c,:) = numel(d);
            ok(c,:) = sum(~contains(d_folders,'nope'));
            nope(c,:) = sum(contains(d_folders,'nope'));
        end
        ratio_ok = ok./total;
        tab = table(ok,nope,total,ratio_ok);
        tab.Properties.RowNames = exp;
        tab = flip(tab);
        
        outab = "/Users/mariofernandez/Downloads/jarand-copy/analysis/latency/" + threshold_type + "/Responsiveness";
        if ~isfolder(outab), mkdir(outab); end
        
        file = tags(i) + "_" + comps(j);
        tab_path = fullfile(outab,file);
        writetable(tab,tab_path,"FileType","spreadsheet","WriteRowNames",true)
        
        % Ploting
        plot(tab.ratio_ok,...
            'Color',color(j,:),...
            'LineWidth',2,...
            'MarkerSize',15,...
            'Marker','o',...
            'MarkerEdgeColor',color(j,:),...
            'MarkerFaceColor',color(j,:))
        hold on
    end
    hold off
    ylim([0 1])
    xticks([1 2])
    xlim([0.5 2.5])
    set(gca,'xtick',[0:3],'xticklabel',{'',char(tab.Properties.RowNames(1)), char(tab.Properties.RowNames(2)),''})
    legend(comps)
    title("Responsiveness: " + tags(i))
    ylabel("Ratio responsiveness")
    outfig = outab + "/" + tags(i);
    print(fig,outfig,'-r300', '-dpng')
end
end