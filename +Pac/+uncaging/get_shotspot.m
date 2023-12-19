function shotspot = get_shotspot(tseries)
    name = tseries.name;
    shotspot = struct();
    
    if endsWith(name, ["-A", "-B"])
       name = name(1:end-2);
    end

    markfile = fullfile(tseries.path, [name '_Cycle00001_MarkPoints.xml']);
    if ~exist(markfile, 'file')
        shotspot.x = nan;
        shotspot.y = nan;
        return;
    end
    
    mfxml = xmlread(markfile);
    root = mfxml.getDocumentElement();
    pnodes = root.getElementsByTagName('Point');
    point = pnodes.item(0);
    
    
    shotspot.x = str2double(point.getAttribute('X')) * tseries.img_dim(1);
    shotspot.y = str2double(point.getAttribute('Y')) * tseries.img_dim(2);
end

