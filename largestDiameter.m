function l_d = largestDiameter(body)

    % get perimeter pixels
    p = [];
    for row = 2:size(body,1)-1
        for col = 2:size(body,2)-1
            if body(row,col)
                % true value, check adjacent values ( non corners)
                if ~body(row-1,col) || ~body(row+1,col) || ~body(row,col-1) || ~body(row,col+1)
                    p(end+1,:) = [row,col];
                end
            end
        end
    end

    % Calculate the largest distance between perimeter points
    l_d = 0;
    for i = 1:size(p,1)
        for j = i+1:size(p,1)
            dist = sqrt((p(i,1) - p(j,1))^2 + (p(i,2) - p(j,2))^2);
            l_d = max(l_d, dist);
        end
    end

end