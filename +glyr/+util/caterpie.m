for l = 1:numel(locs)
    a = 0;
    b = 10;
    cont = 1;
    t = t1;
    while cont
        idx = [locs(l)-a,locs(l)-b];
        seg = t(idx);
        slp = diff(seg)./-diff(idx);
        a = a + 10;
        b = b + 10;
        if round(slp,3) >= 0 & t1(idx) < sigmas
            idx = [locs(l)-a,locs(l)-b];
            seg = t(idx);
            slp = diff(seg)./-diff(idx);
            if round(slp,3) >= 0
                cont = 0;
                idx = idx + 10;
            else
                a = a + 10;
                b = b + 10;
                cont = 1;
            end
        else
            cont = 1;
        end
    end

    idx = flip(idx);
    sseg = [idx(1):idx(2)];
    [m, midx] = min(t1(sseg));

    s = 1;
    while round(slp,4) <= 0
        cc = t1(sseg(midx): sseg(midx) + s);
        slp = diff(cc);
        s = s + 1;
    end
    start(l) = sseg(midx) + s - 1;

end

figure, plot(t1)
hold on
plot(start,t1(start),'r*')