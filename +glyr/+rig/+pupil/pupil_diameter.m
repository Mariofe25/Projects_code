function pup_diameter = pupil_diameter(trials)
% Calculate pupil diameter by fittting a circle. Takes the output from DLC.
% It also calculates the pupil-eye_diameter ratio
import begonia.logging.log
for trial = trials
    if trial.has_var("eye_diameter") && trial.has_var("pupil_tab")
        log(1,trial.path + ": Calculating pupil diameter...")
        eye_size = trial.load_var("eye_diameter");
        pt = trial.load_var("pupil_tab");

        % Eye size
        eye1 = pt(:,{'coords','x_8','y_8','likelihood_8','x_9',...
            'y_9','likelihood_9'});
        eye2 = pt(:,{'coords','x_10','y_10','likelihood_10','x_11',...
            'y_11','likelihood_11'}); %lid

        eye1_d = euc_distance(eye1);
        eye2_d = euc_distance(eye2);

        eye_d = pdist(eye_size);

        % Dots coordinates
        x = [pt.x,pt.x_1,pt.x_2,pt.x_3,pt.x_4,pt.x_5,pt.x_6,pt.x_7];
        y = [pt.y,pt.y_1,pt.y_2,pt.y_3,pt.y_4,pt.y_5,pt.y_6,pt.y_7];

        % Dots likelihood
        l = [pt.likelihood,pt.likelihood_1,pt.likelihood_2,pt.likelihood_3,...
            pt.likelihood_4,pt.likelihood_5,pt.likelihood_6,pt.likelihood_7];

        % Set to 0.6 the min acceptable likelihood
        ll = l < 0.7;

        % Reliability. Since the pupil size is calculated by fitting a
        % circle, take only frames with at least 4 points. If only 3
        % points available, at least one of them has to be confronted
        % (other half of the pupil)
        rel1 = sum(ll(:,[1:3,8]) == 0,2);
        rel2 = sum(ll(:,4:7) == 0,2);
        rel = sum(ll == 0,2);
        rel(rel == 3 & (rel1 == 0 | rel2 == 0)) = 0;
        do_idx = rel > 2;
        x(ll) = nan;
        y(ll) = nan;

        % Calculate pupil size by fitting a circle
        D = nan(length(x),1);
        err =  nan(length(x),1);
        cx = nan(length(x),1);
        cy = nan(length(x),1);
        for c = 1:length(x)
            if do_idx(c)
                % coords to fit circle
                xx = x(c,~isnan(x(c,:)));
                yy = y(c,~isnan(y(c,:)));

                % Fit circle
                [cx(c),cy(c),R] = glyr.util.circfit(xx,yy);

                % Circle fit goodness
                err(c) = glyr.util.circrmse(xx,yy,R,cx(c),cy(c));
                if err(c) < 6 % a circcle would have an rmse closer to 0. 4 is high
                    D(c) = R*2;
                else
                    % last chance. Maybe one ore more coords are not good
                    % even with high likelihood. Try to find distance t the
                    % center, remove the outllier and fit again the circle
                    %                     pdist([cx(c),cy(c);xx(1),yy(1)])
                    %                     dist2c{c} = arrayfun(@(s,ss) sqrt(sum(diff([s,ss;cx(c),...
                    %                         cy(c)]).^2,2)),x(c,:),y(c,:));

                    % Calculate the distance between coords and eliminate
                    % the possible outliers. If more than 5 coords,
                    % elimininate 2, otherwise eliminate just 1
                    coord_dist = pdist([xx',yy']);
                    sq_coord = squareform(coord_dist);
                    dist = sum(sq_coord);
                    if length(dist) > 5, rc = 2; else, rc = 1; end
                    [~,I] =  maxk(dist,rc);
                    xx(I) = [];
                    yy(I) = [];
                    [cx(c),cy(c),R] = glyr.util.circfit(xx,yy);

                    % Check again
                    err(c) = glyr.util.circrmse(xx,yy,R,cx(c),cy(c));
                    if err(c) < 3
                        D(c) = R*2;
                    else

                        D(c) = nan;
                    end
                end
            else
                continue
            end
        end

        % Clean trace
        % Remove sudden changes in pupil diameter
        rmv_idx = [0;diff(D)];
        D(abs(rmv_idx) > 5) = nan;

        % Remove fast changes in pupil locaiton (circle centre).Most likely
        % wrong measurement
        rmv_idx2 = sqrt(sum(diff([cx,cy],2).^2,2));
        D(abs(rmv_idx2) > 7) = nan;

        % Consider changes in eye size. When the mouse is blinking or with
        % reduced eye size. Take the 2nd eye diameter (lid)

        % If eye size is at its 50%, measure is most likey not
        % reliable. Eliminate
        D(eye2_d < 0.6*eye_d) = nan;

        % Remove lonely chuncks of data points (5) and remove outlier
        % chuncks
        conn = bwconncomp(~isnan(D)).PixelIdxList;
        good = conn(cellfun(@length,conn) > 100);
        g_idx = vertcat(good{:});
        mind = min(D(g_idx));
        maxd = max(D(g_idx));
        mstd = std(D(g_idx));
        conn2 = conn(cellfun(@length,conn) < 100);
        menos = cellfun(@(s)  mean(D(s)) < mind - 3*mstd,conn2);
        mas = cellfun(@(s)  mean(D(s)) > maxd + 3*mstd,conn2);
        mm = menos|mas;
        out_idx = vertcat(conn2{mm});
        D(out_idx) = nan;
        bad = conn(cellfun(@length,conn) <= 5);
        b_idxs = vertcat(bad{:});
        D(b_idxs) = nan;


        % If eye size is < 70% max eye size, remove data points. If
        %         eye_thr1 = round(0.7*max(eye2_d));
        %         blink_idx = find(eye2_d < eye_thr1);
        %         blink_idx(D < 0.5*max(eye2_d)) = 0;
        %         pup_diameter(blink_idx) = nan;
        %         eye_thr2 = round(0.85*max(eye2_d));
        %         semi_idx = eye2_d <= eye_thr2 & eye2_d > eye_thr1;


        % Interpolate missing values
        D = fillmissing(D,'makima','MaxGap',30,'EndValues','none');

        % Smooth trace to remove possible outliers
        % remove super fast changes 2
        D = hampel(D,30,2);
        % This also would filled missing values
        D = movmean(D,5);

        % Pupil/ eye rtio
        pup_ratio = D/eye_d;

        % convert to timeseries
        pup_diameter = D;
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