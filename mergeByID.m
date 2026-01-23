function mergeResult = mergeByID(grouped,id,to_merge)
    
    to_merge = logical(to_merge); % make 1s
    
    mergeResult = grouped + (to_merge.*id);


end