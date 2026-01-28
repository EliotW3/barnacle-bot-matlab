clear; clc; close all;

%% ALL INPUT DATA
image_path = "barnacles.jpeg";

[pathstr, name, ext] = fileparts(image_path);
image_name = name;

real_width = 8; % in centimeters
real_height = 8;
min_area = 30;
max_area = 3000;
dilation = 0;
erosion = 0;
threshold = 0.55;

output_subdivisions = 8; % divisions along each axis will make a XbyX grid


%% Load image
img = iread(image_path);
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
% Gaussian smoothing 
g = kgauss(5, 2);        % kernel size 5x5, sigma = 2
img_smooth = iconvolve(img_gray, 2*g);

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


bw = img_enhanced > threshold;

figure; idisp(bw, 'title', 'Binary Threshold Result');

%% Morphological cleanup Temporarily dont use this

% Perform morph operations if inputted


% Find edges 
edges = icanny(bw);


% Remove edges from image
bw = logical(bw - logical(edges));
figure; idisp(bw, 'title', 'Edges removed')

if dilation > 0

    bw = imorph(bw, diskSE(dilation), 'max');

    figure; idisp(bw, 'title', 'Dilated Binary Image')

end

if erosion > 0
    bw = imorph(bw, diskSE(erosion), 'min');

    figure; idisp(bw, 'title', 'Eroded Binary Image')
end


%% Build barnacles from touching white pixels

% get white bodies
[grouped_bodies, body_total] = groupBodies(bw);

% calculate conversion factor for image
cf_x = real_width / size(bw,2);
cf_y = real_height / size(bw,1);

% these values should be the same for a square image, but in the event that
% they are not, take an average
cf = (cf_x + cf_y) / 2; % cf is number of cm per pixel

bodies = buildBodies(grouped_bodies, min_area, max_area, cf);



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
figure; idisp(img, 'title', 'Detected Bodies');
hold on;

for i = 1:size(bodies,1)
    bb = bodies(i).BoundingBox;
    plot_box(bb(1),bb(2),bb(3),bb(4), 'g', 'LineWidth', 1);
    text(bodies(i).Centroid(1), bodies(i).Centroid(2), ...
        sprintf('%d', i), ...
        'Color', 'y', 'FontSize', 12, 'FontWeight', 'bold');
end

hold off;



%% functionality to check accuracy of your filters
% show every pixel that sits inside a bounding box of a body, and plot
% bounding boxes ontop

maskInside = zeros(size(bw));

for i = 1:size(bodies,1)
    bb = bodies(i).BoundingBox;
    for x = bb(2):1:bb(4)
        for y= bb(1):1:bb(3)
            % sets the value to i, this will be used for centroid checking
            % later
            maskInside(x,y) = bodies(i).ID;
        end
    end
end

% convert from i to 1
convertedMaskInside = uint8(zeros(size(img)));
convertedMaskInside(:,:,1) = uint8(logical(maskInside));
convertedMaskInside(:,:,2) = uint8(logical(maskInside));
convertedMaskInside(:,:,3) = uint8(logical(maskInside));

showInside = img.*convertedMaskInside;



figure; idisp(showInside, 'title', 'Checked areas')

for i = 1:size(bodies,1)
    bb = bodies(i).BoundingBox;
    plot_box(bb(1),bb(2),bb(3),bb(4), 'g', 'LineWidth', 1);
    text(bodies(i).Centroid(1), bodies(i).Centroid(2), ...
        sprintf('%d', i), ...
        'Color', 'y', 'FontSize', 12, 'FontWeight', 'bold');
end

hold off;
   


%% show every pixel that sits outside the bounding boxes

maskOutside = uint8(~double(maskInside));

showOutside = img.*maskOutside;
figure; 
idisp(showOutside, 'title', 'Checked areas Outside Bounding Boxes');

%{
for i = 1:output_subdivisions
    for z = 1:output_subdivisions
        z_x = 1+(size(bw,2) / output_subdivisions)*(i-1);
        z_y = 1+(size(bw,1) / output_subdivisions)*(z-1);

        e_x = size(bw,2) - (size(bw,2)/output_subdivisions) * (output_subdivisions - i);
        e_y = size(bw,1) - (size(bw,1)/output_subdivisions) * (output_subdivisions - z);
   
        idisp(showOutside, 'axis',[z_x e_x z_y e_y]);
        pause;
    end
end
%}



%% Output barnacle data
barnacle_table = struct2table(bodies);

disp('Barnacle statistics:');
disp(barnacle_table);

%% save results
writetable(barnacle_table, image_name+'.csv');




%% To find and merge the missing centers of bodies, group the inverted bodies of pixels within the bounding box
%Currently not in use / not working as intended so commented out

%{

% Then find a body that includes the centroid of the barnacle bounding box
% - then merge bodies

% invert image
inverted_bodies = ~bw;
resultGroups = grouped_bodies;

for i = 1:size(bodies,1)
    c_u = bodies(i).Centroid(1);
    c_v = bodies(i).Centroid(2);
    bbPixels = maskInside(maskInside==bodies(i).ID);

    [invertedGroups, invCount] = groupBodies(bbPixels);
    
    if invCount > 0

        % inverted bodies found
        % build the bodies
        invertedBodies = buildBodies(invertedGroups);

        % see if centroid sits inside any of the bodies
        for j = 1:size(invertedBodies,1)


            inv_min_u = invertedBodies(j).BoundingBox(1);
            inv_min_v = invertedBodies(j).BoundingBox(2);
            inv_max_u = invertedBodies(j).BoundingBox(3);
            inv_max_v = invertedBodies(j).BoundingBox(4);

            if c_u >= inv_min_u && c_u <= inv_max_u
                if c_v >= inv_min_v && c_v <= inv_max_v
                    % centroid lies in body, merge bodies.

                    targetPixels = invertedGroups(invertedGroups == j);
                    resultGroups = mergeByID(groupedBodies,bodies(i).ID,targetPixels);
                end
            end
        end

    end

end

% by this point, all areas should be updated.
invResult = ~logical(resultGroups);
figure; idisp(invResult, 'title', 'Checking centroids')

for i = 1:size(bodies,1)
    bb = bodies(i).BoundingBox;
    plot_box(bb(1),bb(2),bb(3),bb(4), 'g', 'LineWidth', 1);
    text(bodies(i).Centroid(1), bodies(i).Centroid(2), ...
        sprintf('%d', i), ...
        'Color', 'y', 'FontSize', 12, 'FontWeight', 'bold');
end

hold off;


%}
