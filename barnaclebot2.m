clear; clc; close all;

%% Load image
img = iread("barnacles.jpeg");
figure;
idisp(img, 'title', 'Input Image');

%% Convert to grayscale

if ndims(img) == 3
    img_gray = rgb2gray(img);
else
    img_gray = img;
end

figure; idisp(img_gray, 'title', 'Grayscale Image');

%% Preprocessing

% smooth for noise reduction
% Gaussian smoothing (toolbox-safe)
g = kgauss(5, 2);        % kernel size 5x5, sigma = 2
img_smooth = iconvolve(img_gray, g);

%% enhance contrast
% High-boost filtering for contrast enhancement
h = [0 -1 0; -1 5 -1; 0 -1 0];
img_enhanced = iconvolve(img_smooth, h);

% rescale intensities
img_enhanced = double(img_enhanced);

img_enhanced = img_enhanced - min(img_enhanced(:));
img_enhanced = img_enhanced / max(img_enhanced(:));

figure; idisp(img_enhanced, 'title', 'Enhanced (Scaled)');


%% Thresholding (barnacles assumed brighter than background)

figure;
ihist(img_enhanced);
title('Intensity Histogram');

thresh = 0.53; % should be taken from histogram  
bw = img_enhanced > thresh;

figure; idisp(bw, 'title', 'Binary Threshold Result');

%% Morphological cleanup Temporarily dont use this




%bw = imorph(bw, diskSE(3), 'max');

%figure; idisp(bw, 'title', 'Dilated Binary Image')

%bw = imorph(bw, diskSE(2), 'min');

%figure; idisp(bw, 'title', 'Eroded Binary Image')


%% Build barnacles from touching white pixels

[grouped_bodies, body_total] = groupBodies(bw);
bodies = buildBodies(grouped_bodies, body_total);



%% size distribution for bodies
% Histogram of body sizes (area in pixels)
figure;
histogram([bodies.Area], 200);   % bins
title('Distribution of Body Sizes');
xlabel('Area (pixels)');
ylabel('Number of Bodies');
grid on;

%% plot bounding boxes ontop of image

bw_grouped = grouped_bodies >= 1;
figure; idisp(bw_grouped, 'title', 'Detected Bodies');
hold on;

for i = 1:size(bodies,1)
    bb = bodies(i).BoundingBox;
    plot_box(bb(1),bb(2),bb(3),bb(4), 'g', 'LineWidth', 1);
    text(bodies(i).Centroid(1), bodies(i).Centroid(2), ...
        sprintf('%d', i), ...
        'Color', 'y', 'FontSize', 4, 'FontWeight', 'bold');
end

hold off;


%% functions - to be moved into seperate files
function se = diskSE(radius)
    % will return a disk SE of diameter (2 * radius) + 1
    
    % Create a square grid
    [x, y] = meshgrid(-radius:radius, -radius:radius);
    
    % Create disk mask
    se = (x.^2 + y.^2) <= radius^2;
end

% Identify connected pixels in binary image to build a list of bodies
% where each body shares the ID
function [gb, num] = groupBodies(bw)
    % make array of same dimensions as bw
    group = zeros(size(bw));
    checked = zeros(size(bw));
    % iterate through bw and give an id to every pixel that is part of body
    bodyId = 1;
    bodyFound = false;
    for row = 2:size(bw,1)-1
        for col = 2:size(bw,2)-1
            if bw(row,col) && ~checked(row,col)
                % current pixel is 1 and not checked yet
                % check surrounding pixels for a group value
                for r = -1:1
                    for c = -1:1
                        if checked(row + r, col + c) && ~bodyFound
                            % if any of the surrounding pixels have been
                            % checked and therefore assigned a group value

                            % this will also filter out itself at r=0 c=0

                            group(row, col) = group(row + r, col + c);
                            checked(row,col) = 1;
                            bodyFound = true;
                        end
                    end
                end

                if ~bodyFound
                    % none of the surrounding pixels have been
                    % checked, therefore do not have a group value
                    % yet
                    group(row,col) = bodyId;
                    bodyId = bodyId + 1;
                    checked(row,col) = 1;
                end
                bodyFound = false;
            end           
        end
    end
    
    % needs a second pass to update any bodies that are touching so that
    % they only have 1 body id.


    % return the grouped bodies and num bodies
    gb = group;
    num = bodyId-1;

end

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

function perimeter = bodyPerimeter(body)
    % function to find the perimeter value of a body of binarised pixels

    % for each true value (1) in the body, count how many false values(0)
    % it is touching (non corners), count is perimeter

    p = 0;
    for row = 2:size(body,1)-1
        for col = 2:size(body,2)-1
            if body(row,col)
                % true value, check adjacent values ( non corners)
                if ~body(row-1,col)
                    p = p + 1;
                end
                if ~body(row+1,col)
                    p = p + 1;
                end
                if ~body(row,col-1)
                    p = p + 1;
                end
                if ~body(row,col+1)
                    p = p + 1;
                end
            end
        end
    end

    perimeter = p;
end

function bounding_box = bodyBoundingBox(body)

    % find the bounding box of a body (min u to max u, min v to max v)
    min_u = 0;
    min_v = 0;

    max_u = 0;
    max_v = 0;

    for row = 1:size(body,1)
        for col = 1:size(body,1)
            if body(row,col)
                % 1 value/ white pixel
                
                % update v values
                if col < min_v || min_v == 0
                    min_v = col;
                end

                if col > max_v
                    max_v = col;
                end

                % update u values
                if row < min_u || min_u == 0
                    min_u = row;
                end

                if row > max_u
                    max_u = row;
                end
            end
        end
    end
                 
    bounding_box = [min_u,min_v,max_u,max_v];

end

function centroid = bbCentroid(bb)

    % finds centroid of a bounding box using (min_u + max u) / 2 etc.

    c_u = (bb(1) + bb(3)) / 2;
    c_v = (bb(2) + bb(4)) / 2;

    centroid = [c_u,c_v];

end