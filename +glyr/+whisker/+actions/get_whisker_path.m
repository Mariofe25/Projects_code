function w_path = get_whisker_path(ts)
    if ts.has_var('Whisker_path')
        w_path = ts.load_var('Whisker_path');
        disp(ts.name + " already has whisker data associated!")
    else     
        w = glyr.whisker.find_whisker_data(ts);
        w_path = string(w.Whisker_path);
    end
end 