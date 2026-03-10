% Shape fitting tests
clear; close all;

img = imread('filled.jpg');
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