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
bodies = buildBodies(grouped_bodies);



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








