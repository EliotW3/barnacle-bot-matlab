function bd = buildBodies(groups, min_area, max_area, conversion_factor)
    
    % groups will be a X by Y array of values from 1+ 
    % all values greater than 0 represent a white pixel, with values of the
    % same value indicating part of the same body.

    % count will be the number of bodies.

    % struct should include, ID, Area in pixels, perimeter in pixels,
    % diameter in pixels, bounding box, and centroid of bounding box
    
    bodies = struct([]);

    ID = [];
    Area = [];
    AreaReal = [];
    Perimeter = [];
    BoundingBox = [];
    BoundingBoxArea = [];
    BoundingBoxAreaReal = [];
    Diameter = [];
    DiameterReal = [];
    Centroid = [];

    unique_ids = unique(groups(groups > 0));
    
    for i = 1:length(unique_ids) % Calculate properties for each body

        ID(end+1,1) = unique_ids(i); % store body ID

        bodyPixels = groups == unique_ids(i); % logical array for current body
        s_b = sum(bodyPixels(:));
        Area(end+1,1) = s_b; % count pixels in the body
        AreaReal(end+1,1) = s_b * conversion_factor^2;

        Perimeter(end+1,1) = bodyPerimeter(bodyPixels); % count boundary pixels
        
        % Calculate bounding box
        boundingBox = bodyBoundingBox(bodyPixels); 
        BoundingBox(end+1,:) = boundingBox;
        
        % calculate bounding box area
        BoundingBoxArea(end+1,1) = (boundingBox(3)- boundingBox(1)) * (boundingBox(4) - boundingBox(2)); 
        BoundingBoxAreaReal(end+1,1) = (boundingBox(3)- boundingBox(1)) * (boundingBox(4) - boundingBox(2)) * conversion_factor^2;

        d = largestDiameter(bodyPixels);
        Diameter(end+1,1) = d;
        DiameterReal(end+1,1) = d * conversion_factor;

        Centroid(end+1,:) = bbCentroid(boundingBox); % store centroid

    end

    % build struct safely

    bodies = struct('ID', num2cell(ID), ...
               'Area', num2cell(Area), ...
               'AreaReal', num2cell(AreaReal), ...
               'Perimeter', num2cell(Perimeter), ...
               'BoundingBox', num2cell(BoundingBox,2),...
               'BoundingBoxArea', num2cell(BoundingBoxArea),...
               'BoundingBoxAreaReal', num2cell(BoundingBoxAreaReal),...
               'Diameter', num2cell(Diameter),...
               'DiameterReal', num2cell(DiameterReal),...
               'Centroid', num2cell(Centroid,2));


    %% clean up filters for body data - should be moved out of here

    
    % Remove bodies where centroid x is equal to bounding box x or centroid y is equal to bounding box y
    % removes any lines (if centroid x = x then must be a line / no height)
    keepCentroid = arrayfun(@(b) b.Centroid(1) ~= b.BoundingBox(1) && b.Centroid(2) ~= b.BoundingBox(2), bodies);
    % filters out based on min max area
    keepArea = [bodies.Area] >= min_area & [bodies.Area] <= max_area;

    bodies = bodies(keepCentroid & transpose(keepArea));

    bd = bodies;
end