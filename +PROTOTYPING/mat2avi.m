function mat2avi(mat,fs,path,map)
% mat2avi creates a gif from a matrix
%
%   mat2avi(mat,fs,path)
%   mat2avi(mat,fs,path,map)
%
%   REQUIRED
%   mat             - (3d numeric) 
%                     Input 3d matrix.
%   fs              - (numeric)
%                     Frame rate
%   path            - (char)
%                     Output path. Include .avi in the path.
%   PARAMETERS
%   mat             - (256x3 double/single)
%                     Matrix of a colormap. 
%                       default : begonia.colormaps.viridis(256)
if nargin < 4
    map = begonia.colormaps.viridis(256);
end


mat = normalize(mat,'type','uint8');

v = VideoWriter(path,'Indexed AVI');
v.Colormap = map;
v.FrameRate = fs;
open(v);
writeVideo(v,mat);
close(v);

% for i = 1:size(mat,3)
%     im = mat(:,:,i);
%     if i == 1
%         imwrite(im,map,path,'gif','LoopCount',Inf,'DelayTime',0);
%     else
%         imwrite(im,map,path,'gif','WriteMode','append','DelayTime',0);
%     end
% end

end

function mat = normalize(mat,varargin)
% normalize changes the min and max values of mat to 0 and 1.
%   Min and max can be replaced. 
%
%   mat = normalize(mat)
%   mat = normalize(...,NAME,VALUE)
%
%   REQUIRED
%   mat             - (numeric) 
%                       Input 3d matrix. 
%   
%   PARAMETERS
%   limits          - (1x2 numeric) 
%                     The two values that will be mapped to 0 and 1. 
%                       default : [min(mat(:)),max(mat(:))]
%   type            - (char)
%                     Output type of the transformed matrix. Note that
%                     either single or double is used in the intermediate
%                     calculation.
%
%                     Options:
%                       'double'    : (default)
%                       'single'    :
%                       'uint8'     : min = 0 max = 255
%                     
%
%   RETURNED
%   mat             - (numeric) 
%                     Transformed matrix.
p = inputParser;
p.addRequired('mat', ...
    @(x) validateattributes(x,{'numeric','logical'},{}));
p.addOptional('limits',[], ...
    @(x) validateattributes(x,{'numeric'},{}));
p.addOptional('type','double', ...
    @(x) validatestring(x,{'double','single','uint8'}));
p.parse(mat,varargin{:});

limits = p.Results.limits;
type = p.Results.type;


if isempty(limits)
    limits = [min(mat(:)),max(mat(:))]; 
end

if isinteger(limits)
    if strcmp(type,'double')
        limits = double(limits);
    else
        limits = single(limits);
    end
end

mat = mat(:,:,:);

if isinteger(mat)
    if strcmp(type,'double')
        mat = double(mat);
    else
        mat = single(mat);
    end
end


min_val = limits(1);
max_val = limits(2);

mat = (mat - min_val)/(max_val - min_val);
mat(mat(:) < 0) = 0;
mat(mat(:) > 1) = 1;

switch type
    case 'double'
        mat = double(mat);
    case 'uint8'
        mat = uint8(mat*255);
    case 'single'
        mat = single(mat);
end




end



function validatestring(x,validStrings)

if ~any(strcmp(x,validStrings))
    str = sprintf('Expected input to match one of these values:');
    str = strcat(str,'\n\n');
    for i = 1:length(validStrings)
        str_tmp = sprintf(' ''%s'',',validStrings{i});
        str = strcat(str,str_tmp);
    end
    str(end) = [];
    str = strcat(str,'\n\n');
    str_tmp = sprintf('The input, ''%s'', did not match any of the valid values.',x);
    str = strcat(str,str_tmp);
    
    error('begonia:validators:invalid_arguments', str);
end

end

