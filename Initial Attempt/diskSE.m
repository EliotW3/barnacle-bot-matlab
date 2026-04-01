%% functions - to be moved into seperate files
function se = diskSE(radius)
    % will return a disk SE of diameter (2 * radius) + 1
    
    % Create a square grid
    [x, y] = meshgrid(-radius:radius, -radius:radius);
    
    % Create disk mask
    se = (x.^2 + y.^2) <= radius^2;
end
