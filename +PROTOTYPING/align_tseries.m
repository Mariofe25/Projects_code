function  align_tseries()
path = '/Volumes/GlyR/GlyR project/Processing list template.xlsx';
file = dir(path);
if ~isfile(path)
    disp('Look for the Processing list.xlsx')
    path = uigetdir;
end
xylobium.stackproc.StackProcessor(path)
disp("Processing list was last updated on " + file.date)
end