function pup_diameter = pupil_diameter_v1(trials)
% Calculate pupil diameter. Takes the output from deeplabcut. It also
% calculates the pupil-eye diameter ratio
import begonia.logging.log
for trial = trials
    if trial.has_var("eye_diameter") && trial.has_var("pupil_tab")
        log(1,trial.path + ": Calculating pupil diameter...")
        eye_size = trial.load_var("eye_diameter");
        pupil_tab = trial.load_var("pupil_tab");

        % There are 8 reference points around the pupil's edge. The diameter can be
        % obtained from any confronted reference pair (1-5,2-6,3-7,4-8). Since the
        % diameter measured from different pairs can slightly differ, take the
        % median of all the pairs to define the diameter. Each reference point
        % has an x/y coord and a likelihood value. Consider only the diameter from
        % pairs which references points have a likelihood > 0.7. If no pair is good
        % enough, define as NaN (mouse blinking or very low quality frame)

        % make tabs with pair references
        diam_1 = pupil_tab(:,{'coords','x','y','likelihood','x_4','y_4',...
            'likelihood_4'});
        diam_2 = pupil_tab(:,{'coords','x_1','y_1','likelihood_1','x_5',...
            'y_5','likelihood_5'});
        diam_3 = pupil_tab(:,{'coords','x_2','y_2','likelihood_2','x_6',...
            'y_6','likelihood_6'});
        diam_4 = pupil_tab(:,{'coords','x_3','y_3','likelihood_3','x_7',...
            'y_7','likelihood_7'});
      
        % get distance from each reference pair
        dist_1 = euc_distance(diam_1);
        dist_2 = euc_distance(diam_2);
        dist_3 = euc_distance(diam_3);
        dist_4 = euc_distance(diam_4);

        dist = [dist_1,dist_2,dist_3,dist_4];

        % Do not calculate pupil diameter if at least 75% of the calcualted
        % distances are not nans
        if sum(sum(isnan(dist),2) > 2)/length(dist) > 0.25
            log(1,"Skipping. Pupil diameter not reliable")
            continue
        end

        % remove super fast changes
        [d1_x,d1_y] = find(abs(diff(dist,2)) > 20);
        dist(d1_x + 2,d1_y) = nan;

        % to make sure that the measurement is reliable, eliminate
        % measueres that only depend on 1 diameter.
        d3_idx = sum(isnan(dist),2) > 2;
        dist(d3_idx,:) = nan;

        %         % In addtion, check that if there are only 2 diameters, these do
        %         % not differ more that 20%
        %         d2_idx = find(sum(isnan(dist),2) == 2);
        %         n_d2 = numel(d2_idx);
        %
        %         for i = 1:n_d2
        %             if abs(diff(dist(d2_idx(i),~isnan(dist(d2_idx(i),:))))) > 10
        %                 dist(d2_idx(i),:) = nan;
        %             end
        %         end

        % When the difrence between the maximum vs minimum diameter is more
        % than 50 px, something is off. Usually the smaller is the right
        % one, but to make things easier, delete that measurment
        mx = max(dist,[],2,'omitnan');
        mn = min(dist,[],2,'omitnan');
        dd = mx - mn;
        dist(dd > 50,:) = nan;

        % eliminate measuremnets that fall within nans. Most likely, these
        % are bad
        dd = reshape(dist',[],1);
        nnan = ~isnan(dd);
        conn = bwconncomp(nnan).PixelIdxList;
        bad = conn(cellfun(@length,conn) <= 3);
        idx = vertcat(bad{:});
        dd(idx) = nan;
        dist = reshape(dd,4,[])';

        % Get average pupil diameter
        pup_diameter = median(dist,2,'omitnan');

        % Interpolate missing values
        pup_diameter = fillmissing(pup_diameter,'makima','MaxGap',30);

        % Smooth trace to remove possible outliers
        % remove super fast changes 2
        pup_diameter = hampel(pup_diameter,30,2);
        % This also would filled missing values
        pup_diameter = movmean(pup_diameter,5);

        % Pupil/ eye ratio
        eye_dim = pdist(eye_size);
        pup_ratio = pup_diameter/eye_dim;

        % convert to timeseries
        Time = pupil_time(trial);
        pup_diameter = timeseries(pup_diameter,Time);
        pup_ratio = timeseries(pup_ratio,Time);

        % sometimes the frame rate is not 30fps, but this is later adjusted
        % when the mtab is created

        % save
        trial.save_var("pupil_diameter",pup_diameter)
        trial.save_var("pupil-eye_ratio",pup_ratio)

    else
        log(1,trial.path + " does not have pupil data")
        continue
    end
end
log(1,"Done!")
end

function dist = euc_distance(tab)
% Calculate diameter (euclidean distance between pairs)
dist = sqrt((tab{:,2} - tab{:,5}).^2 + (tab{:,3} - tab{:,6}).^2);

% Convert to nan non reliable diameters
remv_idx = tab{:,4} < 0.6 | tab{:,7} < 0.6;
dist(remv_idx) = nan;
end

function Time = pupil_time(trial)
pupil_data = dir(fullfile(trial.path,'pupil_data','*.png'));
pupil_data = string({pupil_data.name})';
t = regexp(pupil_data,'\d*','Match');
t = cellstr((cellfun(@(s) strjoin([s(4),s(5)],'.'),t)));
t = cellstr(t);
t = cellfun(@(s) [s(1:2), ':', s(3:4), ':', s(5:10)],t,'UniformOutput',false);
t  = seconds(duration(t));
Time = [0;cumsum(diff(t))];
end