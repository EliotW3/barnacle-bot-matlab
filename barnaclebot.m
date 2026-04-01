% barnacle bot main script
clear;
close all;

% Open and display image "Barnacles.jpg"
img = imread("barnacles.jpeg");
figure('Name','Barnacles');
imshow(img);

%%

% convert img to grey
g_img = rgb2gray(img);
figure('Name','Greyscale');
imshow(g_img);

% apply a gaussian blur to g_img
sigma = 2;                
filterSize = 2*ceil(3*sigma)+1; 
h = fspecial('gaussian', filterSize, sigma);
g_blur = imfilter(g_img, h, 'replicate');

figure('Name','Gaussian Blur');
imshow(g_blur);


% subtract blurred image from original greyscale image 
detail = imsubtract(g_img, g_blur);
figure('Name','Subtracted Image');
imshow(detail);