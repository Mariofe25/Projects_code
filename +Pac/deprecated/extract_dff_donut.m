function extract_dff_donut(tss)

   import begonia.logging.log;
   
   % we need to have the roi signals to perform this processing:
   % if ~ts.has_var("roi_signals_raw")
   %     begonia.processing.roi.extract_roi_signal(ts);
   % end
   
   for ts = tss      
       log(1, "Extracting df_f0 donut signals: " + ts.name);       
       roi_signal_donut = ts.load_var("roi_signals_doughnut");
       roi_table = ts.load_var("roi_table");
       
       roi_signal_donut = join(roi_table,roi_signal_donut);
       
       roi_signal_donut = roi_signal_donut(roi_signal_donut.type == "NS",:);
       
       if isempty(roi_signal_donut), continue; end
         
       
       signal = vertcat(roi_signal_donut.signal_doughnut{:});
       
       % Calculate df/f0
       f0 = mode(round(signal), 2);
       signal = (signal ./ f0) - 1;
       
       % create a joinable output table:
       %roi_id = roi_signal_donut.roi_id;
%        for i = 1:height(roi_signal_donut)
%         short_name(i,1) = string(begonia.util.make_snowflake_id("NS-dnt"));
%        end
       roi_id = string(begonia.util.make_uuids(height(roi_signal_donut)));
       short_name = replace(roi_signal_donut.short_name,"NS","NS-dnt");
       type = repmat("NS-dnt",length(short_name),1);
       signal_donut_dff = num2cell(signal, 2);
       donut_dff = table(short_name,roi_id,type,signal_donut_dff,f0);
       ts.save_var("donut_dff",donut_dff);
   end
end