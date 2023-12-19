function place_new_var(editor,new_var,known_var)
v = editor.model.varlist;
if ~ismember(new_var,v)
    v{end + 1} = new_var;
    vv = cell2table(v,'VariableNames',v);
    f = movevars(vv,new_var,"Before",known_var);
    ff = table2cell(f);
    editor.model.varlist = ff;
end
editor.datagrid.reloadTable(); 
end

