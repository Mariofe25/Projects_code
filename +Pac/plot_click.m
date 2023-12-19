
% Load or generate your 90 traces data (replace this with your actual data)

% Create a blank figure
figure;
title('Trace Peaks Visualization - Click to Continue');

% Loop through the traces
for i = 1:size(df,1)
    % Update the plot with the current trace
    % set(h, 'YData', traces(:, traceIdx));
    
    % Wait for a mouse click
    waitforbuttonpress;
    
    % Find peaks in the current trace
   findpeaks(df(i,:),"MinPeakHeight",thr1(i),"MinPeakProminence",thr1(i),...
    "MinPeakDistance",5*fs,"MinPeakWidth",3*fs) 
end