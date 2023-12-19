function autosize_container(fig,padding)
if nargin < 2
    switch fig.Units
        case 'centimeters'
            padding = 1;
        case 'pixels'
            padding = 10;
        otherwise 
            fig.Units
            error('Invalid units of figure. This function needs to be updated.');
    end
end

children = fig.Children;

if isempty(children)
    return
end


%% Move all the elements left
left_pos = 9999999;
for i = 1:length(children)
    c = children(i);
    if c.Position(1) < left_pos
        left_pos = c.Position(1);
    end
end

left_adjustment = left_pos - padding;
for i = 1:length(children)
    c = children(i);
    c.Position(1) = c.Position(1) - left_adjustment;
end
%% Move all the elements down
lower_pos = 9999999;
for i = 1:length(children)
    c = children(i);
    if c.Position(2) < lower_pos
        lower_pos = c.Position(2);
    end
end

lower_adjustment = lower_pos - padding;
for i = 1:length(children)
    c = children(i);
    c.Position(2) = c.Position(2) - lower_adjustment;
end
%% Adjust the right side of the figure
right_pos = 0;
for i = 1:length(children)
    c = children(i);
    if c.Position(1) + c.Position(3) > right_pos
        right_pos = c.Position(1) + c.Position(3);
    end
end
fig.Position(3) = right_pos + padding;

%% Adjust the upper side of the figure
upper_pos = 0;
for i = 1:length(children)
    c = children(i);
    if c.Position(2) + c.Position(4) > upper_pos
        upper_pos = c.Position(2) + c.Position(4);
    end
end
fig.Position(4) = upper_pos + padding;
end

