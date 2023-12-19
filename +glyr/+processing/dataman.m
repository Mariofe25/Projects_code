c_ac = glyr.processing.action.dataman_glyr_menu();
try
    datman = dataman.start(tss,c_ac);
catch
    datman = dataman.start([],c_ac);
end