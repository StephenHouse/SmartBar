# SmartBar

A "smarter", customizable alternative to batch converting micrographs than the built-in export options on your acquisition software. Featuring the SmartBar: the "smarter scalebar".

## What is SmartBar?

A MATLAB function for batch-converting and processing TEM images. SmartBar's scalebars are more intelligently applied and aesthetically designed. They are automatically adjusted in size, color, stroke, etc to match the images and automatically position themselves in regions of least interest to avoid obscuring the parts of the image you care about. SmartBar also gives the user full control over all these parameters, to adjust to your particular tastes. SmartBar can handle TEM, STEM, and Diffraction images, and allows processing parameters to be tweaked individually for each type.

(I was disatisfied with the built-in options of all the microscopy programs I've had to deal with. So I decided to write my own batch-processing and scalebar-labeling function.)

Current Version: 01.05

## Acceptable File Types

.dm3 (Digital Micrograph)\
.emd (Velox version only)\
.ser (ESVision/TIA)\
.tif, .tiff, .jpg, .jpeg, .png, .gif (Intensity processing only, no pixel scale information.)

Reading in .dm3, .emd, and .ser files requires the MATLAB files ReadDM3, serReader, and ReadVelox, respectively. These files are included in this repository.

## MATLAB Dependencies

SmartBar has been written in a way to avoid all usage of MATLAB toolboxes and to maximize backwards compatibility with older versions of MATLAB. I think it is currently compatible with as old as R2009, and potentially even pre-R2006 (but I lack all those versions to confirm). That is why some functions -- which would be faster, easier, or more compact -- are not used here. I also prefer to sacrifice some code conciseness for the sake of greatly enhanced readability; easier to grok and modify later.

Note: EMD/HDF5 images will only work with R2011a and later.

## Installation
Put the SmartBar file, ReadDM3, serReader, and ReadVelox in the same folder (or in your MATLAB folder).

## Using SmartBar

The SmartBar function has no output variables and can be invoked with or without an input. The user-adjustable parameters are contained at the beginning of the function. If an input variable is provided, it must be a single structure array with fields that match the parameters listed below. Any matching fields will be used in place of the parameters in the file. (The input need not have every field.)

If not using an input, adjust the parameters manually in the file itself. The parameters are found in an explicitly labeled section at the beginning of the file.

Example without inputs:
`SmartBar_01_05()`

Example with inputs:
`SmartBar_01_05(Options)`
where Options contains fields like 
`Options.NormAnswer = 'Yes' `

## Processing Parameters
**Variable Name**\
Options\
_Description_

### Basic parameters
**NormAnswer**\
Yes, No\
_Whether to normalize the image intensities. If yes, the image intensities will be normalized according to the limits set by the parameters below._

**STEMFractionSaturated**\
A real number 0-1 (default = 0)\
_Fraction of pixels (high & low) to saturate during normalization of STEM images. This value is also used for any image where the imaging mode cannot be determined._

**TEMFractionSaturated**\
A real number 0-1 (default 0.01 or 0.0005)\
_As above, but for TEM images._

**DPFractionSaturated**\
A real number 0-1 (default 0.0005)\
_As above, but for TEM diffraction patterns._

**SmartBarAnswer**\
Yes, No\
_Whether to apply SmartBars (scalebars) to images_

### Export Options
**Export8BitNoScalebar**\
Yes, No\
_Whether or not to export 8-bit Tiff versions of the images without any scalebars applied._

**Export8BitWithSmartBar**\
Yes, No\
_Whether or not to export 8-bit Tiff versions of the images with SmartBars. Note: These will not be exported if the SmartBar option (SmartBarAnswer) is not enabled._

**Export16BitNoScalebar**\
Yes, No\
_Whether or not to export 16-bit Tiff versions of the images._

**Export16BitAsRaw**\
Yes, No\
_Whether the 16-bit images should have the original/raw intensities (if 'No', they will be normalized)._

**ExportScaleList**\
Yes, No\
_Whether or not to export a .csv file containing a list of each file along with its size and pixel scale._

**EmbedScale**\
Yes, No\
_Whether or not to embed the pixel scale metadata in the Tiff resolution tags._\
_The upside is that programs like ImageJ will be able to read it. The downside is that MSOffice and its ilk will read it, and make their initial sizes tiny when you embed them. (You can resize them after, of course, it can just be a little annoying.) Note: The scalebar images do not have embedded scale metadata by default._

### SmartBar Options
**AllowedPositions**\
A 1x4 vector (default [0,0,1,1]) of 0 or 1.\
_What corners of the image the SmartBar is allowed to be in. (1 = yes, 0 = no) The order of the vector entries are clockwise from Upper Left (i.e.: [Upper Left, Upper Right, Lower Right, Lower Left])_

**AllowedScales**\
A 1xn vector (default [1,2,5])\
_The scale multiples that SmartBar is allowed to test (e.g., [1,2,5] means the scale could be 1, 2, 5, 10, 20, 50, ...etc)._

**TargetBarWidthFraction**\
A real number 0-1 (default 0.2)\
_The fraction of image width the scalebar's width will aim for._

**TargetBarHeightFraction**\
A real number 0-1 (default 0.01)\
_The fraction of image width the scalebar's height will aim for._

**TargetBarSpacing**\
A real number (default 2)\
_What multiple of bar height should the bar be away from the corner of the image._

**TargetLabelSpacing**\
A real number 0-1 (default 0.5)\
_What fraction of bar height to put as spacing between the bar and its label._

**TargetLabelHeight**\
A real number (default 4)\
_Height of the scalebar label, in units of bar height. (Note: actual font height is shorter than this.)_

**TargetStroke**\
A real number 0-1 (default 0.2)\
_Fraction of scalebar height the stroke should be._

## Usage
Copyright (c) 2020, Stephen D. House
All rights reserved

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution
  
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## Support & Contributing
I'll be updating this program as I add more functionality. If you have ideas, requests, improvements, etc, I'd love to hear it! 
