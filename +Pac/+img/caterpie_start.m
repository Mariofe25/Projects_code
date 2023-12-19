function start = caterpie_start(trace,locs,thr,fps)
a = 0;
b = 2*fps;
cont = 1;
t = trace;
addit = 2*fps;
if thr < 0.15, thr = 0.15; end
while cont
    idx = [locs-a,locs-b];
    if idx(2) < 1, start = 1; return, end 
    seg = t(idx);
    slp = diff(seg)./-diff(idx);
    a = a + addit;
    b = b + addit;
    if round(slp,2) == 0 & t(idx) < thr/2 %prctile(t,30) %thr/2
        idx = [locs-a,locs-b];
         if idx(2) < 1, idx(2) = 1;end 
        seg = t(idx);
        slp2 = diff(seg)./-diff(idx);
        if abs(round(slp,2)) <= 0.01
            cont = 0;
            if abs(slp2) > abs(slp)
                idx = idx + addit;
            end
        else
            a = a + addit;
            b = b + addit;
            cont = 1;
        end
    else
        cont = 1;
    end
end

idx = flip(idx);
sseg = idx(1):idx(2);
[m, midx] = min(t(sseg));

mf = find(islocalmin(t(idx(1):locs))) + idx(1);
mf(t(mf) >= thr/2.5) = [];
if any(mf)
    if numel(t(mf)) >= 1
        [~,wmin] = min(locs - mf);
        minx = mf(wmin);
        if minx > sseg(midx)
            midx = minx;
        else
            midx = sseg(midx);
        end
    end
else
    midx = sseg(midx);
end

% s = 1;
% while round(slp,3) <= 0
%     cc = t(sseg(midx): sseg(midx) + s);
%     slp = diff(cc);
%     s = s + 1;
% end
start = midx +1; %+ s - 1;
end
% figure, plot(t1)
% hold on
% plot(start,t1(start),'r*')