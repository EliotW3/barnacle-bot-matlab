function bd = buildBodies(groups, count)
    
    % groups will be a X by Y array of values from 1+ 
    % all values greater than 0 represent a white pixel, with values of the
    % same value indicating part of the same body.

    % count will be the number of bodies.

    % struct should include, ID, Area in pixels, perimeter in pixels,
    % diameter in pixels, bounding box, and centroid of bounding box
    
    bodies = struct([]);

    ID = [];
    Area = [];
    Perimeter = [];
    BoundingBox = [];
    Centroid = [];
    
    for i = 1:count % Calculate properties for each body

        ID(end+1,1) = i; % store body ID

        bodyPixels = groups == i; % logical array for current body
        Area(end+1,1) = sum(bodyPixels(:)); % count pixels in the body
        

        Perimeter(end+1,1) = bodyPerimeter(bodyPixels); % count boundary pixels
        
        % Calculate bounding box
        boundingBox = bodyBoundingBox(bodyPixels); 
        BoundingBox(end+1,:) = boundingBox;
        
        
        Centroid(end+1,:) = bbCentroid(boundingBox); % store centroid

    end

    % build struct safely

    bodies = struct('ID', num2cell(ID), ...
               'Area', num2cell(Area), ...
               'Perimeter', num2cell(Perimeter), ...
               'BoundingBox', num2cell(BoundingBox,2),...
               'Centroid', num2cell(Centroid,2));


    %% clean up filters for body data - should be moved out of here

    
    % Remove bodies where centroid x is equal to bounding box x or centroid y is equal to bounding box y
    
    minArea = 4;
    maxArea = 100;

    keepCentroid = arrayfun(@(b) b.Centroid(1) ~= b.BoundingBox(1) && b.Centroid(2) ~= b.BoundingBox(2), bodies);
    keepArea = [bodies.Area] >= minArea & [bodies.Area] <= maxArea;

    bodies = bodies(keepCentroid & transpose(keepArea));

    bd = bodies;
end