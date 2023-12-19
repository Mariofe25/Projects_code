function pac_datman = dataman(tss)
custom_actions = Pac.actions.dataman_pac_menu();
if nargin < 1
    tss = [];
end
pac_datman = dataman.start(tss,custom_actions);
end