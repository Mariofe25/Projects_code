path = "/Volumes/GlyR/GlyR project/Plots/Behaviour";
for ts = tss  
    fig = figure ('Position',[1001 433 1034 904]);
    layout = tiledlayout(3, 1, "tilespacing", "compact");
    title(layout,ts.name)
    nexttile()
    glyr.plot.plot_behaviour(ts,0);
    title("Behaviour States")
    nexttile()
    glyr.plot.plot_speed_vs_states(ts,0);
    nexttile()
    glyr.plot.plot_whisking_vs_states(ts,0);
    
    filename_signal = "Behaviour " + ts.name;
    outpng_1 = fullfile(path, [char(filename_signal) '.png']);
    print(fig, outpng_1, '-r300', '-dpng');
    % clean up:
    delete(fig)
end