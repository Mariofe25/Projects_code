roi_types = {'AS','AP','AE','Gp','NS','NS-dnt','Np'};
colors = [0,1,0;0.2,0.8,0.1;0.4,0.7,0.2;0.9,0.9,0.4;1,0,0;1,0,0.5;0.8,0.2,0.3];
colors = num2cell(colors,2);
roi_colors = containers.Map(roi_types,colors);