%% Plot rpa by compartment

plots_folder = '/Volumes/Xiaoyi2/4mt/Plots';

if ~isfolder(plots_folder)
    mkdir(plots_folder)
end

for ts = tss    
    fig = begonia.processing.rpa.plot_qa_compartment(ts);
    plot_type = "roa_compartment";
    mt.save_plot(ts,plots_folder,fig,plot_type)
    
    delete(fig)
end