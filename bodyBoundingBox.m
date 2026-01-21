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
