function ellipse = leastSquareEllipse(points)

    xs = points(:,2);
    ys = points(:,1);

    % parameters for Ax^2 + Bxy + Cy^2 + Dx + Ey + F
    X = [xs .* ys, ys.^2 - xs.^2, xs, ys, ones(size(xs))];
    rhs = -(xs.^2);

    params = X \ rhs; % least squares

    B = params(1);
    C = params(2);
    D = params(3);
    E = params(4);
    F = params(5);

    A = 1 - C;

    % as a matrix
    M = [A B/2 D/2
        B/2 C E/2
        D/2 E/2 F];

    % Eigen decomposition
    [V, L] = eig(M(1:2,1:2));
    lambda = diag(L);

    % center of ellipse
    center = M(1:2,1:2) \ (-M(1:2,3));

    x0 = center(1);
    y0 = center(2);

    % Semi-axis lengths
    detM = det(M);
    a = sqrt(-detM / (lambda(1)*lambda(2)*lambda(1)));
    b = sqrt(-detM / (lambda(1)*lambda(2)*lambda(2)));

    % Rotation angle
    theta = atan2(V(2,1), V(1,1));

    data.x0 = x0;
    data.y0 = y0;
    data.a = a;
    data.b = b;
    data.theta = theta;

    ellipse = data;

end