function tss_nodes(tss)
fig = uifigure;
t = uitree(fig);
for i = 1:numel(tss)    
    t.SelectionChangedFcn = @nodechange;
    uitreenode(t,'Text',string(tss(i).load_var('fov')),'NodeData',tss(i));    
end
    function nodechange(src,event)
        node = event.SelectedNodes;
        display(node.NodeData)
    end
end