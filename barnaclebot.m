% barnacle bot main script
clear;
close all;

% Open and display image "Barnacles.jpg"
img = imread("barnacles.jpeg");
figure('Name','Barnacles');
imshow(img);

%%

% convert img to grey
g_img = rgb2gray(img);
figure('Name','Greyscale');
imshow(g_img);

% apply a gaussian blur to g_img
sigma = 2;                
filterSize = 2*ceil(3*sigma)+1; 
h = fspecial('gaussian', filterSize, sigma);
g_blur = imfilter(g_img, h, 'replicate');

figure('Name','Gaussian Blur');
imshow(g_blur);


% subtract blurred image from original greyscale image 

subtracted_img = g_img - g_blur;
figure('Name','Subtracted Image');
imshow(subtracted_img);


% rescale intensities
subtracted_img = double(subtracted_img);

subtracted_img = subtracted_img - min(subtracted_img(:));
subtracted_img = subtracted_img / max(subtracted_img(:));

%%
% Fill the barnacles in.
% binarise
bw = subtracted_img > 0.3;
figure()
imshow(bw)


bw_filled = imfill(bw, 'holes');
% Closing: dilate then erode — 
se = strel('disk', 5);  
bw_closed = imclose(bw_filled, se);

% remove tiny noise specs
bw_clean = bwareaopen(bw_closed, 5);  % removes objects smaller than 5 px

figure()
imshow(bw_clean)


%% Watershedding - not accurate.
%{
% Distance transform + watershed to split touching objects
D = bwdist(~bw_clean);          % distance from background
D = -D;                          % invert for watershed
D(~bw_clean) = -Inf;             

L = watershed(D);                
bw_seperated = bw_clean;
bw_seperated(L == 0) = 0;        % remove watershed ridge lines

figure()
imshow(bw_seperated)
%}

%%
% Split into grouped bodies

[grouped_bodies, body_total] = groupBodies(bw_clean);

selected_group = grouped_bodies == 2004;
figure();
imshow(selected_group)

%% smooth body 

% Remove extruded pixels by applying morphological operations
bw_smooth = imopen(selected_group, se);  % Morphological opening to smooth the body
figure();
imshow(bw_smooth);

%% any bodies that meet circularity conditions, are a single barnacles and should be highlighted, then removed from this data set
% Calculate circularity for each body

change_recorded = true;
barnacles = struct([]);
stats = regionprops(bw_smooth, 'Area', 'Perimeter','Centroid','PixelList','BoundingBox');

while change_recorded

    disp("Pass");
    change_recorded = false;
    
    circularity = [stats.Area] ./ ([stats.Perimeter].^2 / (4 * pi));
    centroids = cat(1,stats.Centroid);
    
    % select stats with circularity 
    mask = circularity > 0.90;
    
    if numel(stats(mask)) > 0
        change_recorded = true;
    end

    barnacles = [barnacles; stats(mask)];
    


    


    %% remainder after removing individual barnacles
    mask = circularity < 0.90;
    remainder = stats(mask);
    
    watershed_result = false(size(bw_clean));
    
    % for each item in remainder - 
    for j = 1:numel(remainder)
        body = remainder(j);
        
        
        % create body_px from body.PixelList
        body_px = false(size(bw_clean));
        for i = 1:numel(body.PixelList)/2
            body_px(body.PixelList(i,2),body.PixelList(i,1)) = 1;
        end
    
        % perform a watershed operation on the body to split it up
        D = -bwdist(~body_px);          % distance from background
    
    
        L = watershed(D);  
        body_separated = body_px;      % create a copy for separation
        body_separated(L == 0) = 0; % remove watershed ridge lines
    
        % perform minima imposition to filter out small local minimas
        mask = imextendedmin(D,2);
        D2 = imimposemin(D,mask);
        L2 = watershed(D2);
        bw3 = body_px;
        bw3(L2 == 0) = 0;
        watershed_result = watershed_result + bw3;
    
    end
    

    %figure();
    %imshow(watershed_result);


    CC = bwconncomp(watershed_result, 4);
    stats = regionprops(CC, 'Area', 'Perimeter','Centroid','PixelList','BoundingBox');
end

figure();
imshow(bw_smooth);
hold on;
% for each detected barnacle, draw its bounding box and display circularity at centroid
for k = 1:numel(barnacles)
    bb = barnacles(k).BoundingBox;    % [x y width height]
    rectPos = [bb(1), bb(2), bb(3), bb(4)];
    % draw rectangle
    rectangle('Position', rectPos, 'EdgeColor', 'g', 'LineWidth', 2);
    % draw centroid marker
    c = barnacles(k).Centroid;
    plot(c(1), c(2), 'r+', 'MarkerSize', 10, 'LineWidth', 1.5);
    % compute circularity for this region - pull circularity in region
    % props?
    A = barnacles(k).Area;
    P = barnacles(k).Perimeter;
    if P > 0
        circ = A / (P^2 / (4*pi));
    else
        circ = 0;
    end
    % display circularity text at centroid
    txt = sprintf('%.2f', circ);
    text(c(1), c(2) - 10, txt, 'Color', 'yellow', 'FontSize', 10, ...
        'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'BackgroundColor', 'black', 'Margin', 1);
end
hold off;