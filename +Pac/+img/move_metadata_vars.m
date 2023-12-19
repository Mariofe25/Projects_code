function move_metadata_vars(tss,tsstiff,vars)
if nargin < 3, vars = "roi_table"; end
import begonia.logging.*
vars = string(vars);
n = 0;
log(1, 'Copying vars: %s', join(vars,','))
for tr = tsstiff
    n = n + 1;
    ts = tss(string({tss.name}) == tr.name);
    if isempty(ts)
        warning("No tseries match for denoised tseries " + tr.name + " Skip");
        n = n - 1;
        continue
    end

    for i = 1:numel(vars)
        backwrite(1, 'Copying to denoised tseries metadata: %d/%d', n, length(tsstiff))
        if ts.has_var(vars(i))
            val = ts.load_var(vars(i));
            tr.save_var(vars(i),val)
        else
            warning(ts.name + " does not have variable " + vars(i) + ". Not copied")
        end
    end
end
end
