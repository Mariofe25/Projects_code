% b = bwboundaries(ns_mask);

figure
hold on
% r  = containers.Map()
for i = 1:length(b)
    
   p =  plot(b{i}(:,2),b{i}(:,1),'ButtonDownFcn',@lineCallback);
   
  
end
% plot(rand(1,5),'ButtonDownFcn',@lineCallback)

function lineCallback(src,~)
src.Color = rand(3,1);
end