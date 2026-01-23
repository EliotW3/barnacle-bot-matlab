# barnacle-bot-matlab
An image processing module for MATLAB for identifying and measuring crowded images of barnacles.

This MATLAB code acts as a stepping stone for a more complete and easy to use python program.
Built using functions from Peter Corke's Machine Vision Toolbox.

## Intended pipeline
- Input image of barnacles
- Tweak threshold and morph parameters until happy with result
- Perform body grouping
- Identify and verify each body (view and count)
    - Largest to smallest, smallest to largest
    - changes/inaccuracies are recorded for each body
- Verify non-body occupied space
    - Grid defined by input
    - non-identified barnacles are summed
- Output count and body data

## TODO
- Test bounding box area and longest diameter
- Data verification process
- Include "holes" for barnacle body grouping to ensure accuracy
- Data output
- Conversion via input for meters to pixels, update all output data accordingly
- Easy to use interface, display charts and allow tweaking of thresholds/min-max areas/etc.
- Update README with how-to and images
- Port to python opencv


