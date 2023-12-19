mat = ts.get_mat(2);

mat = begonia.util.stepping_window(mat,30);


%%
m = min(mat,[],"all")
mm = max(mat,[],"all")
yucca.plot.matview(mat,[m,mm - 500]);