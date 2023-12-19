function plot_channel_traces(tss,do_save)
path = '/Users/mariofernandez/Downloads/jarand-copy';
if nargin < 2, do_save = true; end
if nargin < 1 || isempty(tss)
    tss = begonia.scantype.find_scans(path);
end
idx = tss.has_var('stabilized');
tss = tss(idx);
tags = tss.load_var("tags");
tags = categorical(tags);
cats = unique(tags);
colors = rand(5,3);
for i = 1:length(cats)
    c = cats(i);
    tss_cat = tss(tags == c);
    comp = tss_cat.load_var('channel_traces');
    fov = cellfun(@(s) s.Data,comp,'UniformOutput',false);
    fov_astro = arrayfun(@(s) s{:}(:,2),fov,'UniformOutput',false);
    fov_ast = horzcat(fov_astro{:})';
    f0_ast = mode(fov_ast,2);
    fov_ast = (fov_ast - f0_ast)./f0_ast;
    fov_neuron = arrayfun(@(s) s{:}(:,1),fov,'UniformOutput',false);
    fov_neu = horzcat(fov_neuron{:})';
    f0_neu = mode(fov_neu,2);
    fov_neu = (fov_neu - f0_neu)./f0_neu;
    fovs = {fov_ast,fov_neu};
    ch = ["astrocytes", "neurons"];
    for j = 1:length(fovs)
        f = fovs{j};
        fig = figure;
        ncx.stdshade(f,0.3,colors(j,:));
        t = string(c) + " FoV " + ch(j);
        title(t)
        ylim([0 1])
        xlabel('Time')
        ylabel('df/f')
        if do_save
            outpng = fullfile(path,t);
            print(fig, outpng, '-r300', '-depsc');
        end
        delete(fig)
    end
end
disp("Done!")
end
