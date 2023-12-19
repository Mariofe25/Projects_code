function extract_downsample(tss,nframes,frate)

if nargin < 3
    frate = 100;
end

if nargin < 2
    nframes = [0 0]; % all
end

for ts = tss
    if ~ts.has_var('whisk_metadata')
        % get associated whisker data path\
        whisker_path = glyr.whisker.actions.get_whisker_path(ts);
        
        if ~isempty(whisker_path)
        % Extract frames
        try
            disp('Extracting frames from .seq file...')
            [ImageCellArray, headerInfo]= glyr.whisker.ReadJpegSEQ(whisker_path,nframes);
        catch err
            disp(err.message)
            continue
        end
        else
            disp('No whisker data associated found')
            continue
        end
        % Downsample to 100fps
        disp("Downsampling to " + frate + "fps")
        o_fr = round(headerInfo.FrameRate); % 500 fps
        Im_array = downsample(ImageCellArray,o_fr/frate);
        
        % Eliminate the original Im_array (consumes loads of memory)
        clear ImageCellArray
        
        % create folder
        d = dir(whisker_path);
        file_name = d.name;
        parent_folder = d.folder;
        f = strrep(file_name,'.seq','');
        h5_folder_path = fullfile(parent_folder,f);
        mkdir(h5_folder_path)
        
        % Convert to H5 format and save it
        disp('Concatenating array...')
        im = cat(3,Im_array{:,1});
        h5_file_name = strrep(file_name,'seq','h5');
        h5_path = fullfile(h5_folder_path,h5_file_name);
        size_im = size(im);
        disp('Transforming to H5 format...')
        h5_file = begonia.util.H5Array(h5_path,size_im,'uint8');
        disp('H5 file created')
        disp('Populating H5 file...')
        h5_file(:,:,:) = im;
        
        % Time array
        time = Im_array(:,2);
        time = datetime(time,"InputFormat",'dd-MMM-yyyy HH:mm:ss:SSS','Format','dd-MMM-uuuu HH:mm:ss.SSSS');
        start_time = time(1);
        stop_time = time(end);
        tt = duration(NaN(length(time),3));
        for i = 1:length(time) - 1
            tt(1) = 0;
            tt(i+1) = time(i+1) - time(i);
        end
        Time = cumsum(tt);
        Time = seconds(Time);
        dt = round(Time(end))/length(Time);
        
        % Create metadata struct
        disp('Creating metadata...')
        whisk_info = struct;
        whisk_info.seq_path = whisker_path;
        whisk_info.h5_path = h5_path;
        whisk_info.file = file_name;
        whisk_info.associated_tseries = ts.path;
        whisk_info.Start_time = start_time;
        whisk_info.Stop_time = stop_time;
        whisk_info.Duration = seconds(Time(end));
        whisk_info.dt = dt;
        whisk_info.Time_arr = Time;
        whisk_info.nframes= length(Time);
        whisk_info.frame_width = headerInfo.ImageWidth;
        whisk_info.frame_height = headerInfo.ImageHeight;
        
        metadata_path = fullfile(h5_folder_path,'metadata');
        save(metadata_path,'whisk_info')
        
        % Save whisk metadata path to tseries metadata
        ts.save_var('whisk_metadata',whisk_info)
    else
        disp(ts.name + " already has an h5 file.")
    end
    disp('Done')
    
end
end