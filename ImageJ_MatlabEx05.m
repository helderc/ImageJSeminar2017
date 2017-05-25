clear all; close all; clc;


%% Initializing...

% starting ImageJ
ImageJ();

% importing ImageJ Java class
import ij.*

fn = '../../../_Images/Cameraman256.png';
 
%% Test 01: loading image
im = ij.ImagePlus(fn);
im.show();



%% Test 02: Getting and Visualizing the Histogram
im_processor = im.getProcessor();
imhist = im_processor.getHistogram();
bar(imhist);

%% Test 2.1: getting the data and converting it
im_array = uint8(im_processor.getFloatArray());
im_conv = fliplr(rot90(im_array,-1));
figure, imshow(im_conv);

%% Test03: Performing thresholding with IsoData [1] method
% [1] http://imagej.net/Auto_Threshold
im2 = im.clone();
im2_processor = im2.getProcessor();
fprintf('\nThreshold: %.2f\n', im2_processor.getAutoThreshold());

% applying threshold
im2_processor.autoThreshold();
im2.setProcessor(im2_processor);
im2.show();


%% Test 04: Gaussian blurring
im3 = im.clone();
im3_processor = im3.getProcessor();
im3_processor.blurGaussian(2);
im3.setProcessor(im2_processor);
im3.show();

