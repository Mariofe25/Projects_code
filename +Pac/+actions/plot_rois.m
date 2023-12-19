function plot_rois(dlocs, model, editor)
path = uigetdir; %'/Volumes/Xiaoyi2/Plots';
for dloc = dlocs
    fig_1 = begonia.processing.roi.plot_qa_signals(dloc);
    fig_2 = begonia.processing.roi.plot_qa_rois(dloc);
    filename_signal = dloc.name + " RoIs signal" ;
    filename_mask = dloc.name  + " Mask RoIs";
    outpng_1 = fullfile(path, [char(filename_signal) '.png']);
    print(fig_1, outpng_1, '-r300', '-dpng');
    outpng_2 = fullfile(path, [char(filename_mask) '.png']);
    print(fig_2, outpng_2, '-r300', '-dpng');
    % clean up:
    delete(fig_1);
    delete(fig_2)
end
end

