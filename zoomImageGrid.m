function count = zoomImageGrid(imagePath)

    t_count = 0;

    % Read the image
    img = imread(imagePath);
    [rows, cols, ~] = size(img);
    
    % Define grid size
    gridSize = 8;
    sectionRows = floor(rows / gridSize);
    sectionCols = floor(cols / gridSize);
    
    % Loop through each section of the grid
    for i = 0:gridSize-1
        for j = 0:gridSize-1
            % Calculate the section boundaries
            rowStart = i * sectionRows + 1;
            rowEnd = min((i + 1) * sectionRows, rows);
            colStart = j * sectionCols + 1;
            colEnd = min((j + 1) * sectionCols, cols);
            
            % Extract the section
            section = img(rowStart:rowEnd, colStart:colEnd, :);
            
            % Display the section
            imshow(section);
            title(['Section (' num2str(i+1) ', ' num2str(j+1) ')']);
            
            count = input("Enter section count:");
            t_count = t_count + count;
        end
    end

    
    count = t_count;

end