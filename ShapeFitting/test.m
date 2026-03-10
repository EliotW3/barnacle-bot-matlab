% Shape fitting tests
clear; close all;

img = imread('filled2.jpg');
imshow(img);

% convert to grayscale if needed
if size(img,3) == 3
    gray = rgb2gray(img);
else
    gray = img;
end



% detect edges using Canny 
edges = edge(gray, 'Canny');


% show edge image
figure;
imshow(edges);
title('Detected Edges');


% get all curve coordinates
curvePixels = zeros(nnz(edges), 2);
curveCounter = 1;

% trace connected edge pixels in clockwise order starting from a boundary pixel
% find one starting pixel (topmost-leftmost edge pixel)
[rStart,cStart] = find(edges,1,'first');
if isempty(rStart)
    error('No edge pixels found.');
end

% 8-connected neighborhood offsets (row,col) in clockwise order starting from north
nbrOffsets = [-1  0;  % N
              -1  1;  % NE
               0  1;  % E
               1  1;  % SE
               1  0;  % S
               1 -1;  % SW
               0 -1;  % W
              -1 -1]; % NW

visited = false(size(edges));
% We'll follow boundary by preferring next neighbor in clockwise order relative to previous move.
% Initialize previous direction as coming from west (so we start checking from north)
prevDir = 7; % index into nbrOffsets corresponding to W (0-based idea -> use 7 for W here)

curR = rStart; curC = cStart;
idx = 1;
curvePixels(idx,:) = [curR, curC];
visited(curR,curC) = true;

maxIter = nnz(edges) * 4; % safety
iter = 0;
while true
    iter = iter + 1;
    if iter > maxIter
        break;
    end

    % choose search start: one step clockwise from direction we came from
    % compute starting neighbor index (prevDir + 1) mod 8 to prefer clockwise continuation
    startSearch = mod(prevDir,8) + 1; % 1..8
    found = false;
    % search 8 neighbors clockwise from startSearch
    for k = 0:7
        ni = mod(startSearch-1 + k, 8) + 1;
        nr = curR + nbrOffsets(ni,1);
        nc = curC + nbrOffsets(ni,2);
        if nr < 1 || nr > size(edges,1) || nc < 1 || nc > size(edges,2)
            continue;
        end
        if edges(nr,nc)
            % choose this neighbor
            prevDir = mod(ni-1 + 4, 8) + 1; % update prevDir to direction from new pixel back to current (opposite)
            curR = nr; curC = nc;
            % stop if we returned to start and have >1 point
            if curR == rStart && curC == cStart && idx > 1
                found = true;
                break;
            end
            if ~visited(curR,curC)
                idx = idx + 1;
                curvePixels(idx,:) = [curR, curC];
                visited(curR,curC) = true;
            else
                % if visited but not start, still move to continue tracing (to handle loops)
                % append anyway to preserve traversal order
                idx = idx + 1;
                curvePixels(idx,:) = [curR, curC];
            end
            found = true;
            break;
        end
    end
    if ~found
        break;
    end
    % stop if returned to start (closed loop)
    if curR == rStart && curC == cStart
        break;
    end
end

% trim preallocated curvePixels size if necessary (ensure matches nnz later)
if exist('curvePixels','var')
    curvePixels = curvePixels(1:idx,:);
else
    curvePixels = zeros(0,2);
end

%{
for y=1:size(edges,1)
    for x = 1:size(edges,1)
        if edges(x,y) == 1
            curvePixels(curveCounter,:) = [x,y];
            curveCounter = curveCounter + 1;
        end
    end
end
%}
% compute totals of columns of curvePixels
avr_x = sum(curvePixels(:,1)) / size(curvePixels,1);
avr_y = sum(curvePixels(:,2))/ size(curvePixels,1);

hold on;
plot(avr_x, avr_y, 'r.', 'MarkerSize', 15);

curveWeights = zeros(size(curvePixels,1),1);

% Calculate the weights based on the distance from the average point
for i = 1:size(curvePixels,1)
    curveWeights(i) = sqrt((curvePixels(i,1) - avr_x)^2 + (curvePixels(i,2) - avr_y)^2);
end

% normalize weights 
w = curveWeights;
w = w - min(w);
if max(w) > 0
    w = w / max(w);
end


cmap = jet(256);

% map weights to colors
idx = max(1, round(1 + w*(size(cmap,1)-1)));
colors = cmap(idx, :);

% colored pixels over the top
figure;
imshow(img); hold on;
scatter(curvePixels(:,2), curvePixels(:,1), 10, colors, 'filled'); % note: x->cols (y), y->rows (x)
title('Curve pixels colored by weight (distance from centroid)');

% colorbar
ax = gca;
colormap(ax, cmap);
c = colorbar('Ticks',[0,1], 'TickLabels', {sprintf('%.2f', min(curveWeights)), sprintf('%.2f', max(curveWeights))});
c.Label.String = 'Distance from centroid';


smooth_dw = smoothdata(curveWeights);

% plot dw as a line chart
figure;
plot(smooth_dw, '-b', 'LineWidth', 1.5);
grid on;
xlabel('Index');
ylabel('Difference in weight (dw)');

% find local minima in smooth_dw
% use islocalmin for robustness (requires MATLAB R2017b+). Fallback if unavailable.
if exist('islocalmin','builtin')
    locMinMask = islocalmin(smooth_dw);
else
    % simple neighbor comparison: true if less than both neighbors
    n = numel(smooth_dw);
    locMinMask = false(size(smooth_dw));
    for k = 2:n-1
        if smooth_dw(k) < smooth_dw(k-1) && smooth_dw(k) < smooth_dw(k+1)
            locMinMask(k) = true;
        end
    end
    % endpoints: consider them minima if less than their single neighbor
    if n >= 2
        if smooth_dw(1) < smooth_dw(2); locMinMask(1) = true; end
        if smooth_dw(n) < smooth_dw(n-1); locMinMask(n) = true; end
    end
end

% get x (index) values of local minima
x_local_min = find(locMinMask);

% optional: plot minima on the smooth_dw figure if it's the current figure
if ~isempty(x_local_min)
    hold on;
    plot(x_local_min, smooth_dw(x_local_min), 'ro', 'MarkerFaceColor','r');
end




% find local maxima in smooth_dw
if exist('islocalmax','builtin')
    locMaxMask = islocalmax(smooth_dw);
else
    % simple neighbor comparison for maxima
    n = numel(smooth_dw);
    locMaxMask = false(size(smooth_dw));
    for k = 2:n-1
        if smooth_dw(k) > smooth_dw(k-1) && smooth_dw(k) > smooth_dw(k+1)
            locMaxMask(k) = true;
        end
    end
    % endpoints: consider them maxima if greater than their single neighbor
    if n >= 2
        if smooth_dw(1) > smooth_dw(2); locMaxMask(1) = true; end
        if smooth_dw(n) > smooth_dw(n-1); locMaxMask(n) = true; end
    end
end

% indices and values of local maxima
x_local_max = find(locMaxMask);
y_local_max = smooth_dw(x_local_max);

% If there are at least two maxima, check first and last and remove the smaller one
if numel(x_local_max) >= 2
    if y_local_max(1) < y_local_max(end)
        % remove first
        x_local_max(1) = [];
        y_local_max(1) = [];
    else
        % remove last
        x_local_max(end) = [];
        y_local_max(end) = [];
    end
end

% plot maxima on the smooth_dw figure
if ~isempty(x_local_max)
    hold on;
    plot(x_local_max, y_local_max, 'ks', 'MarkerFaceColor','y', 'MarkerSize',8);
    % annotate indices near markers
    for kk = 1:numel(x_local_max)
        text(x_local_max(kk), y_local_max(kk), sprintf(' %d', x_local_max(kk)), ...
            'VerticalAlignment','bottom','HorizontalAlignment','left','Color','k','FontSize',9);
    end
end






curves = zeros(size(curveWeights,1),1);
curveId = 1;

for c = 1:size(x_local_min,1)-1
    start = x_local_min(c);
    finish = x_local_min(c+1);

    for i = start:finish
        curves(i) = curveId;
    end
    curveId = curveId + 1;

end

start = x_local_min(end);
finish = size(curveWeights,1);
for i = start:finish
    curves(i) = curveId;
end

start = 1;
finish = x_local_min(1);
for i = start:finish
    curves(i) = curveId;
end


% create a colormap with as many distinct colors as there are curve ids
nCurves = max(curves);
if nCurves < 1
    error('No curve segments found to color.');
end
% use lines colormap for distinct colors, fallback to jet if many
if nCurves <= 20
    segCmap = lines(nCurves);
else
    segCmap = jet(nCurves);
end

% build an RGB image for edges (initialize to black)
edgeRGB = zeros([size(edges), 3]);

% For each pixel in curvePixels assign color based on its curve id.
% curvePixels rows correspond to traversal order; curves has same length.
for k = 1:size(curvePixels,1)
    cid = curves(k);
    if cid < 1 || cid > nCurves
        continue;
    end
    r = curvePixels(k,1);
    c = curvePixels(k,2);
    edgeRGB(r,c,1:3) = reshape(segCmap(cid,:), [1,1,3]);
end

% display colored edges over a black background
figure;
imshow(edgeRGB);
title('Edges colored by curve segment');

% also overlay colored edge pixels on original image for context
figure;
imshow(img); hold on;
% create scatter with colors mapped from curves (note x=cols, y=rows)
scatter(curvePixels(:,2), curvePixels(:,1), 10, segCmap(curves,:), 'filled');
title('Colored edge pixels over original image');

%%
% show the local minima points in red
for c = 1:size(x_local_max,1)
    plot(curvePixels(x_local_max(c),2),curvePixels(x_local_max(c),1), 'ro', 'MarkerFaceColor', 'r');
end


%show local minima points in blue
for c = 1:size(x_local_min,1)
    plot(curvePixels(x_local_min(c),2),curvePixels(x_local_min(c),1), 'bo', 'MarkerFaceColor', 'b');
end

t = linspace(0,2*pi,100);
for i =1:nCurves
    pts = curvePixels(curves == i, :);
    ellipse = leastSquareEllipse(pts);

    x_e = ellipse.x0 + ellipse.a * cos(t) * cos(ellipse.theta) - ellipse.b*sin(t)*sin(ellipse.theta);
    y_e = ellipse.y0 + ellipse.a * cos(t) * sin(ellipse.theta) - ellipse.b*sin(t)*cos(ellipse.theta);
    
    plot(x_e,y_e, 'y--', 'LineWidth', 2);
    plot(ellipse.x0,ellipse.y0,'bx','MarkerSize',5)

end

% mark overlaps between ellipses: check pairwise intersections of their filled masks
imgSize = size(img);
t = linspace(0,2*pi,360);

% Create binary masks for each ellipse (filled)
ellipseMasks = false([imgSize(1), imgSize(2), nCurves]);
for i = 1:nCurves
    pts = curvePixels(curves == i, :);
    if size(pts,1) < 5
        continue;
    end
    ellipse = leastSquareEllipse(pts);
    x_e = ellipse.x0 + ellipse.a * cos(t) * cos(ellipse.theta) - ellipse.b.*sin(t)*sin(ellipse.theta);
    y_e = ellipse.y0 + ellipse.a * cos(t) * sin(ellipse.theta) - ellipse.b.*sin(t)*cos(ellipse.theta);
    % create polygon and rasterize into mask
    px = round(x_e(:));
    py = round(y_e(:));
    % clamp to image bounds
    px = min(max(px,1), imgSize(2));
    py = min(max(py,1), imgSize(1));
    mask = poly2mask(px, py, imgSize(1), imgSize(2));
    % fill to ensure interior included
    ellipseMasks(:,:,i) = mask;
end

% compute pairwise overlaps and mark their boundary/intersection points
overlapMask = false(imgSize);
for i = 1:nCurves-1
    for j = i+1:nCurves
        if ~any(ellipseMasks(:,:,i),'all') || ~any(ellipseMasks(:,:,j),'all')
            continue;
        end
        ov = ellipseMasks(:,:,i) & ellipseMasks(:,:,j);
        if any(ov,'all')
            % store overlap region
            overlapMask = overlapMask | ov;
            % find boundary pixels of the overlap region to mark
            B = bwperim(ov);
            [ry, cx] = find(B);
            hold on;
            % plot red dots at boundary pixels (convert cols->x, rows->y)
            plot(cx, ry, '.r', 'MarkerSize', 8);
        else
            % if no filled-pixel overlap, check contour intersections of perimeters
            bi = bwperim(ellipseMasks(:,:,i));
            bj = bwperim(ellipseMasks(:,:,j));
            [yi, xi] = find(bi);
            [yj, xj] = find(bj);
            if isempty(xi) || isempty(xj)
                continue;
            end
            % convert to polygons and compute intersections via polyshape if available
            try
                polyi = polyshape(xi, yi);
                polyj = polyshape(xj, yj);
                inter = intersect(polyi, polyj);
                if ~isempty(inter.Vertices)
                    v = inter.Vertices;
                    plot(v(:,1), v(:,2), '.r', 'MarkerSize', 10);
                    overlapMask = overlapMask | inpolygon(repmat((1:imgSize(2)),imgSize(1),1), repmat((1:imgSize(1))',1,imgSize(2)), v(:,1), v(:,2));
                end
            catch
                % fallback: mark any perimeter pixels that are within 1 pixel distance
                D = pdist2([xi, yi], [xj, yj]);
                [ridx, cidx] = find(D <= 1.5);
                if ~isempty(ridx)
                    pts = [xi(ridx), yi(ridx)];
                    plot(pts(:,1), pts(:,2), '.r', 'MarkerSize', 8);
                    for k = 1:size(pts,1)
                        overlapMask(pts(k,2), pts(k,1)) = true;
                    end
                end
            end
        end
    end
end

% optionally overlay a semi-transparent red region where overlaps exist
if any(overlapMask,'all')
    [oy, ox] = find(overlapMask);
    scatter(ox, oy, 12, [1 0 0], 'filled', 'MarkerFaceAlpha', 0.4);
end