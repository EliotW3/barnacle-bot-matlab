# barnacle-bot-matlab
An image processing module for MATLAB for identifying and measuring crowded images of barnacles.

This MATLAB code acts as a stepping stone for a more complete and easy to use python program.


- [x] Shape fitting for convex curves
- [ ] Shape fitting for concave curves (likely will require rewriting convex curves)
- [x] Background removal and cleanup of barnacle images
- [x] Thresholding/morphological operations 
- - [ ] Controlled by sliders in real time (user friendly)
- [ ] Identify groups of barnacles touching
- - [ ] Seperate individual barnacles out from further processing
- - [ ] Smooth edges of each group, perform shape fitting, and predict barnacles
- [ ] User friendly output
- [ ] Port to Python


## 
Images of barnacles can be crowded, with barnacles often overlapping one another. This project aims to
develop a method of automatically counting and measuring barnacles in a given image.

![A crowded image of barnacles](/Images/barnacles.jpeg)

This project aims to test a method of shape fitting to identify and seperate barnacles that overlap one another.

## Shape Fitting
For example - 

![A shape made up of overlapping ellipses](/ShapeFitting/filled.jpg)

This shape is made up of overlapping ellipses, which by eye you can still identify where each ellipses sits, and that a total of 4 ellipses make up the image.

![The outlines of the previous shape of overlapping ellipses](/ShapeFitting/outlines.jpg)

Each of these ellipses should be identifiable and measurable, despite overlapping eachother in the original image.
By eye, we can identify where each "curve" starts and finishes.

![The outlines of the shape split where each ellipses overlaps](/ShapeFitting/good_example.png)

## 
### Background / Noise Removal
Images are converted to greyscale and a gaussian blur is performed and subtracted from the original greyscale image.
![Background removal result](/Images/Subtracted_Image.png)

Images with morphological operators applied.
![Filled in and binarised barnacle images](/Images/Filled_in.png)

Attempts at using watershedding appear innaccurate - hence the focus on shape fitting.
![Inaccurate watershedding attempts](/Images/watershedding.png)

## 
### Shape fitting + barnacles

Looking at a single group of barnacles, shape fitting by eye can see where barnacles "should" sit in the group.

![Small section of the barnacles, where all barnacles are touching.](/Images/overlay.png)

Predictions made in red.

![Predicted barnacle locations based on fitting ellipses](/Images/circled_barnacles.png)

Accuracy - 

![Predictd barnacles shown over the real image](/Images/circled_barnacles_nowhite.png)