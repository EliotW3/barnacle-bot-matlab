function centroid = bbCentroid(bb)

    % finds centroid of a bounding box using (min_u + max u) / 2 etc.

    c_u = (bb(1) + bb(3)) / 2;
    c_v = (bb(2) + bb(4)) / 2;

    centroid = [c_u,c_v];

end