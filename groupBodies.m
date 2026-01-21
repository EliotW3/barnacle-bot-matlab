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

