% Compare different methods of calcium deconvolution (mlspike and oasis)

for ts = tss
    disp("Deconvolving " + ts.name)
    tab = begonia.processing.roi.load_processed_signals(ts);
    ns = tab.signal_subtracted_dff(tab.type == "NS");
    ns = vertcat(ns{:});
    f0 = tab.f0(tab.type == "NS");

    % Recalculate dF to use mlspike (does not work with f0 around 0)
    F = ns .* f0 + f0;
    df = F./f0;

    %% deconvolve mlspike
    par = tps_mlspikes('par');
    par.dt = 0.1;
    % par.a = 0.1% 0.07; % DF/F for one spike
    par.tau = 0.85;
    par.finetune.sigma = [];
    par.dographsummary = false;


    spikes = zeros(size(df,1),size(df,2));
    ca_dec = zeros(size(df,1),size(df,2));
    drift = zeros(size(df,1),size(df,2));
    disp("Using MLSpike method...")
    for i = 1:size(df,1)
        [spikes,ca_dec(i,:),drift(i,:)] = spk_est(df(i,:),par);
    end

    tab_deconv = table(tab.roi_id,ca_dec,'VariableNames',["roi_id","signal_deconvolved"]);

    ts.save_var('calcium_deconv',calcium_deconv)

    %% deconvolve oasis
    c = zeros(size(ns,1),size(ns,2));
    s = zeros(size(ns,1),size(ns,2));
    disp("Using oasis method...")
    for i = 1:size(ns,1)
        [c(i,:), s(i,:)] = deconvolveCa(ns(i,:),'foopsi', 'ar1','smin',-2.5, ...
            'optimize_pars','optimize_b','optimize_smin');
    end

    ts.save_var('calcium_Oasis',c)
end