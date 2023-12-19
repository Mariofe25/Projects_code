function nope =  get_negative_glyr_ns(tss)
idx = tss.has_var("glyr_expression");
if sum(idx) > 0
    tsg = tss(idx);
    glyr_exp = tsg.load_var("glyr_expression");
    glyr_exp = vertcat(glyr_exp{:});
    % ns  = unique(glyr_exp.neu_id);
    nope = glyr_exp.neu_id(glyr_exp.expression == 0);
else
    nope = [];
end
end