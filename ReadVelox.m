function [OutputData] = ReadVelox(InputFile)
%function [OutputData] = ReadVelox(InputFile)
%Version 01.01
%
%Function for reading the .emd image files created by Velox.
%Velox nominally creates EMD/HDF5 formatted files, but something
%is wrong with how they encoded metadata, so standard HDF5
%functions do not work properly with them.
%
%This currently cannot read spectrum or spectral image files,
%only TEM & STEM images and diffraction patterns.
%
%The input is the filename of the .emd file.
%The output is a structure with the following fields:
%   OutputData.RawImage    <-- The image intensities
%   OutputData.RawMetadata <-- The raw metadata string
%   OutputData.ImageMode   <-- 'TEM','STEM', or 'DP'
%   OutputData.ImageWidth  <-- Width of the image, in pixels
%   OutputData.ImageHeight <-- Height of the image, in pixels
%   OutputData.PixelScale  <-- Pixel size, in PixelUnits
%   OutputData.PixelUnit   <-- The units of PixelScale
%
%**************************************************************************
%
% Copyright (c) 2019, Stephen D. House
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 
%     * Redistributions of source code must retain the above copyright 
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in 
%       the documentation and/or other materials provided with the distribution
%       
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.


ScanSizePattern = '"ScanSize":{"width":"(\d+)","height":"(\d+)"}'; %Extracts image size for STEM images. Apparently *not* empty set if TEM image (it's 0's)
ImageSizePattern = '"ImageSize":{"width":"(\d+)","height":"(\d+)"}'; %Extracts image size for TEM images. Empty set if STEM image.
%Apparently, though, the "ImageSize" is the maximum the camera does, not what the image actually is. Need to grab the binning, too:
BinningPattern = '"Binning":{"width":"(\d+)","height":"(\d+)"}'; %Extracts binning
%For extracting the pixel size information, for STEM or TEM mode
%NOTE: This currently assumes that the pixels are square, with the same scale and units in X & Y
PixelScalePattern = '"PixelSize":{"width":"(\d+)\.(\d+)e\-(\d+)","height":"\d+\.\d+e\-\d+"},"PixelUnitX":"(\w+)","PixelUnitY":"\w+"';
%The PixelScale format of a reciprocal space (i.e., DP) image. Again, assumes square pixels
DPScalePattern = '"PixelSize":{"width":"(\d+)\.(\d+)","height":"\d+\.\d+"},"PixelUnitX":"(1\\\/\w+)","PixelUnitY":"1\\\/\w+"';

%Read in the HDF5 file info
ImageInfo = h5info(InputFile);
DataName = ImageInfo.Groups(2).Groups(1).Groups(1).Name; %This is the group containing the micrograph data and metadata
ImageIntensity = h5read(InputFile,[DataName,'/Data']); %Read in the micrograph intensity data 
EMDMetadata = h5read(InputFile,[DataName,'/Metadata']); %Read in the metadata string
OutputData.RawMetadata = char(EMDMetadata); %Convert it from a numeric array to a string of characters

%RegEx searches to extract the relevant metadata
[~,ImageSizeTokens,~] = regexp(OutputData.RawMetadata,ImageSizePattern,'match','tokens','tokenExtents');
[~,ScanSizeTokens,~] = regexp(OutputData.RawMetadata,ScanSizePattern,'match','tokens','tokenExtents');

if isempty(ImageSizeTokens) %Is a STEM image
	SizeTokens = ScanSizeTokens{1}; %Because it returns a cell array in a cell array
	OutputData.ImageWidth = str2double(SizeTokens{1});
	OutputData.ImageHeight = str2double(SizeTokens{2});
	OutputData.ImageMode = 'STEM';
else %Is a TEM or DP image. Apparently TEM images don't have a truly empty ScanSize entry. It's 0's
	[~,BinningTokens,~] = regexp(OutputData.RawMetadata,BinningPattern,'match','tokens','tokenExtents');
	BinningTokens = BinningTokens{1};
	SizeTokens = ImageSizeTokens{1};
	OutputData.ImageWidth = round(str2double(SizeTokens{1})/str2double(BinningTokens{1}));
	OutputData.ImageHeight = round(str2double(SizeTokens{2})/str2double(BinningTokens{2}));
	%Check if it is a diffraction pattern image
	[~,DPScaleTokens,~] = regexp(OutputData.RawMetadata,DPScalePattern,'match','tokens','tokenExtents');
	if isempty(DPScaleTokens)
		OutputData.ImageMode = 'TEM';
	else
		OutputData.ImageMode = 'DP';
		DPScaleTokens = DPScaleTokens{1};
	end
end

%Note: the image size cell is [width,height] in pixels
if strcmp(OutputData.ImageMode,'STEM')||strcmp(OutputData.ImageMode,'TEM')
	[~,PixelScaleTokens,~] = regexp(OutputData.RawMetadata,PixelScalePattern,'match','tokens','tokenExtents');
	PixelScaleTokens = PixelScaleTokens{1};
	%Note: The pixel scale token cell is "1"."2"x10-"3" "units"
	OutputData.PixelScale = (str2double(PixelScaleTokens{1})+str2double(['.',PixelScaleTokens{2}]))*10^str2double(['-',PixelScaleTokens{3}]); %Converts pixel scale tokens to a meaningful form
	OutputData.PixelUnit = PixelScaleTokens{4};
else %If it's a DP image
	OutputData.PixelScale = str2double(DPScaleTokens{1})+str2double(['.',DPScaleTokens{2}]);
	OutputData.PixelUnit = ['1/',DPScaleTokens{3}(4:end)];
end

%Reshape and orient image data
OutputData.RawImage = flipud(rot90(reshape(ImageIntensity,[OutputData.ImageWidth,OutputData.ImageHeight]))); %"real" = [width,height]
end %End function