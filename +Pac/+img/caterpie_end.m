function ends = caterpie_end(trace,locs,thr,fps)
a = 0;
b = 2*fps;
cont = 1;
t = trace;
addit = 2*fps;
if thr < 0.15, thr = 0.15; end

while cont
    idx = [locs+a,locs+b];
    if idx(2) > length(t), ends = length(t); return, end
    seg = t(idx);
    slp = diff(seg)./diff(idx);
    a = a + addit;
    b = b + addit;
    if round(slp,2) == 0 & t(idx) < round(thr/2,2) %prctile(t,30) %thr/2
        idx = [locs+a,locs+b];
        if idx(2) > length(t), idx(2) = length(t); end
        seg = t(idx);
        slp2 = diff(seg)./diff(idx);
        if round(slp2,2) == 0
            cont = 0;
            if abs(slp2) > abs(slp)
                idx = idx - addit;
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

sseg = idx(1):idx(2);
[~, midx] = min(t(sseg));

mf = find(islocalmin(t(locs:idx(2)))) + locs;
mf(t(mf) >= thr/2.5) = [];
if any(mf)
    if numel(t(mf)) >= 1
        [~,wmin] = min(mf - locs);
        minx = mf(wmin);
        if minx < sseg(midx)
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
ends = midx - 1;% + s - 1;