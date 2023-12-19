function deltaFoF = get_dff_roi_old(traces,roi_type,tau,do_subtraction,alpha,signals_donut)
if nargin < 6, signals_donut = []; end
if nargin < 5, alpha = 0.9; end
if nargin < 4, tau = 0.2; end
% inputs:  traces = raw signals from rois mxn (m = frames; n = number rois)
%          roi_type = astrocytes or neurons
%          tau = decay time of the calcium sensor GCamP6f = 0.140? jRCaMP =
%          0.5 secs??
%          alpha = neuropil subtraction factor (only for neurons) default =
%          0.9
%          signal_donut = raw doughnut neuron signals

if roi_type == "neuron" && do_subtraction
    % Subtract neuropil signal from neuron soma rois
    fluoTraces = traces' - alpha*signals_donut';
    fluoTraces = fluoTraces - min(fluoTraces);
    fluoTraces = hampel(fluoTraces);
elseif roi_type == "neuron" && ~do_subtraction
    fluoTraces = traces';
    fluoTraces = hampel(fluoTraces);
else
    fluoTraces = traces';
end

% Calculation the baseline in a running time window whose length is the maximum of 15 s or 40 time decays
tauDecay = tau;
fps = 30;
if roi_type == "neuron"
    twdw = 5;
else
    twdw = 10;
end
twdw = max(15,40*tauDecay);
wdw = round(fps*twdw);
numCells = size(fluoTraces,2);
numFrames = size(fluoTraces,1);
smoothBaseline = zeros(size(fluoTraces));

if numFrames > 2*wdw
    for j = 1:numCells
        dataSlice = fluoTraces(:,j);
        temp = zeros(numFrames-2*wdw,1);
        for i = wdw+1:numFrames - wdw
            temp(i-wdw) = prctile(dataSlice(i-wdw:i+wdw),8);
        end
        smoothBaseline(:,j) = [temp(1)*ones(wdw,1) ; temp; temp(end)*ones(wdw,1)];
        smoothBaseline(:,j) = glyr.util.runline(smoothBaseline(:,j),wdw,1);
    end
else
    for j=1:numCells
        smoothBaseline(:,j) = [ones(numFrames,1)*prctile(fluoTraces(:,j),8)];
    end
end

% dynamic f0
F0 = smoothBaseline;

% dff
deltaFoF = (fluoTraces-F0)./F0;

% Subtract noise from dff
numCells = size(deltaFoF,2);
numFrames = size(deltaFoF,1);

for numcell = 1:numCells
    dataCell = deltaFoF(:,numcell);
    [smoothDist,x] = ksdensity(dataCell);
    [valuePeak,indPeak] = max(smoothDist);
    xFit = x(1:indPeak);
    dataToFit = smoothDist(1:indPeak)/numFrames;
    [sigma(numcell),mu(numcell),A] = glyr.util.mygaussfit(xFit',dataToFit);
    
    if ~isreal(sigma(numcell))
        dev = nanstd(dataCell);
        outliers = abs(deltaFoF)>2*dev;
        
        deltaF2 = dataCell;
        deltaF2(outliers) = NaN;
        sigma(numcell) = nanstd(deltaF2);
        mu(numcell) = nanmean(deltaF2);
    end
    distFit = A*exp(-(x-mu(numcell)).^2./(2*sigma(numcell)^2));
end

deltaFoF = bsxfun(@minus,deltaFoF, mu);

% for i = 150+1:numFrames - 150
%     temp(i-wdw) = dataSlice(i-wdw:i+wdw);
% end

% Check for ROIs with weak baseline
% baseline = smoothBaseline;
% toDeleteDim1=[];
% for j=1:numCells
%     dataSlice=fluoTraces(:,j)-baseline(:,j);
%
%     [counts,x]=hist(dataSlice,min(round(length(dataSlice)/20),100));
%     counts=smooth(counts);
%     if any(isnan(x))
%         toDeleteDim1=[toDeleteDim1 j];
%         continue
%     end
%
%
%     [valueCenter,indCenter]=max(counts);
%
%     if counts(1)>valueCenter*25/100
%         toDeleteDim1=[toDeleteDim1 j];
%     end
%
% end
%
% toDeleteDim2=[];
% for j=1:numCells
%     if any(baseline(:,j)==0)
%         toDeleteDim2=[toDeleteDim2 j];
%     end
% end
%
% deletedCells=union(toDeleteDim1,toDeleteDim2);
% toKeep=setdiff(1:numCells,deletedCells);
end
