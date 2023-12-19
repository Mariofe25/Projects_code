for ts = tss
    path = ts.path;
    metadata_file = fullfile(path,'metadata.mat');
    load(metadata_file);
    % read xml file
    [~,dirr] = fileparts(path);
    xml_file = fullfile(path,[dirr,'.xml']);
    text = fileread(xml_file);
    try
        temp = regexp(text,'(?<=<PVStateValue key="positionCurrent">).*?(?=</PVStateValue>)','match');
        x_temp = regexp(temp,'(?<=<SubindexedValues index="XAxis">).*?(?=</SubindexedValues>)','match');
        x = regexp(x_temp{:},'(?<=subindex="0" value=").*?(?=")','match');
        x = str2double(x{:});
        y_temp = regexp(temp,'(?<=<SubindexedValues index="YAxis">).*?(?=</SubindexedValues>)','match');
        y = regexp(y_temp{:},'(?<=subindex="0" value=").*?(?=")','match');
        y = str2double(y{:});
        z_temp = regexp(temp,'(?<=<SubindexedValues index="ZAxis">).*?(?=</SubindexedValues>)','match');
        z = regexp(z_temp{:},'(?<=subindex="0" value=").*?(?=")','match');
        z = str2double(z{:});
        metadata.frame_position_um = [x,y,z];
    catch
        metadata.frame_position_um = [];
    end
    save(metadata_file,"metadata","-mat")
end