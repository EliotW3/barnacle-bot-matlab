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