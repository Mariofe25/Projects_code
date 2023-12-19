begonia.processing.roi.extract_neuron_doughnut_signals(ts,8,3);
begonia.processing.roi.subtract_neuropil(ts);
glyr.img.extract_dff_donut(ts);
signals = begonia.processing.roi.load_processed_signals(ts);
donut_dff = ts.load_var("donut_dff");
glyr.plot.plot_neurons(ts)


[signals_raw,signals_dff,subtracted_dff,f_mask] = glyr.mask_neurons(ts);

figure
colormap(begonia.colormaps.magma);
imagesc(subtracted_dff)

%%%%%%
signals_doughnut = signals.signal_doughnut(signals.type == "NS");
signals_doughnut = vertcat(signals_doughnut{:});

signals_raw =  signals.signal_raw(signals.type == "NS");
signals_raw = vertcat(signals_raw{:});

fluoTraces = signals_raw' - 0.9*signals_doughnut';
fluoTraces = fluoTraces - min(fluoTraces);
fluoTraces = hampel(fluoTraces);


% Calculation the baseline in a running time window whose length is the maximum of 15 s or 40 time decays
params.tauDecay = 0.5;
params.fps = 30;
twdw = max(15,40*params.tauDecay);
wdw = round(params.fps*twdw);
numCells = size(fluoTraces,2);
numFrames = size(fluoTraces,1);
smoothBaseline=zeros(size(fluoTraces));

if numFrames > 2*wdw
    for j = 1:numCells
        dataSlice = fluoTraces(:,j);
        temp = zeros(numFrames-2*wdw,1);
        for i =wdw+1:numFrames - wdw
            temp(i-wdw)=prctile(dataSlice(i-wdw:i+wdw),8);
        end
        smoothBaseline(:,j)=[temp(1)*ones(wdw,1) ; temp; temp(end)*ones(wdw,1)];
        smoothBaseline(:,j)=runline(smoothBaseline(:,j),wdw,1);
    end
else
    for j=1:numCells
        smoothBaseline(:,j)=[ones(numFrames,1)*prctile(fluoTraces(:,j),8)];
    end
end

F0 = smoothBaseline;

deltaFoF = (fluoTraces-F0)./F0;


params.BaselineNoiseMethod = 'Gaussian model';
numCells = size(deltaFoF,2);
numFrames = size(deltaFoF,1);

for numcell = 1:numCells
    
    dataCell = deltaFoF(:,numcell);
    
    [smoothDist,x] = ksdensity(dataCell);
    
    [valuePeak,indPeak] = max(smoothDist);
    
    xFit = x(1:indPeak);
    dataToFit = smoothDist(1:indPeak)/numFrames;
    [sigma(numcell),mu(numcell),A] = mygaussfit(xFit',dataToFit);
    
    if ~isreal(sigma(numcell))
        dev=nanstd(dataCell);
        outliers=abs(deltaFoF)>2*dev;
        
        deltaF2=dataCell;
        deltaF2(outliers)=NaN;
        sigma(numcell)=nanstd(deltaF2);
        mu(numcell)=nanmean(deltaF2);
        
    end
    
    
    distFit=A*exp(-(x-mu(numcell)).^2./(2*sigma(numcell)^2));
    
end

deltaFoF = bsxfun(@minus,deltaFoF, mu);

% Check for ROIs with weak baseline
baseline = smoothBaseline;
toDeleteDim1=[];
for j=1:numCells
    dataSlice=fluoTraces(:,j)-baseline(:,j);
    
    [counts,x]=hist(dataSlice,min(round(length(dataSlice)/20),100));
    counts=smooth(counts);
    if any(isnan(x))
        toDeleteDim1=[toDeleteDim1 j];
        continue
    end
    
    
    
    [valueCenter,indCenter]=max(counts);
    
    if counts(1)>valueCenter*params.cutOffIntensity/100
        toDeleteDim1=[toDeleteDim1 j];
    end
    
end

toDeleteDim2=[];
for j=1:numCells
    if any(baseline(:,j)==0)
        toDeleteDim2=[toDeleteDim2 j];
    end
end

deletedCells=union(toDeleteDim1,toDeleteDim2);
toKeep=setdiff(1:numCells,deletedCells);


% Transients

raster=double(bsxfun(@gt,deltaFoF,params.deltaFoFCutOff*sigma+mu));

[densityData, densityNoise, xev, yev] = glyr.NoiseModel(deltaFoF, sigma, 0);
[mapOfOdds] = glyr.SignificantOdds(deltaFoF, sigma, densityData, densityNoise, xev, params, plotFlag);
[raster, mapOfOddsJoint] = glyr.Rasterize(deltaFoF, sigma, mapOfOdds, xev, yev, params);




%%%%%%%%%%

signals_raw =  signals.signal_raw(signals.type == "NS");
signals_raw = vertcat(signals_raw{:});

% f0 = prctile(signals_raw,15,2);
% signals_dff = (signals_raw - f0)./f0;

signals_raw = signals_raw - 0.9*signals_doughnut;
signals_r = signals_raw  - min(signals_raw,[],2);
f0 = prctile(signals_r,15,2);
signals_dff = (signals_r - f0)./f0;


signals_raw = a - 0.9*d;
signals_raw = signals_raw + min;
f0 = prctile(signals_raw,25);
signals_dff = (signals_raw - f0)./f0;



