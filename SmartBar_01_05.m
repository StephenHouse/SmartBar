 %   _____                      _   ____             
 %  / ____|                    | | |  _ \            
 % | (___  _ __ ___   __ _ _ __| |_| |_) | __ _ _ __ 
 %  \___ \| '_ ` _ \ / _` | '__| __|  _ < / _` | '__|
 %  ____) | | | | | | (_| | |  | |_| |_) | (_| | |   
 % |_____/|_| |_| |_|\__,_|_|   \__|____/ \__,_|_|   
 %------------------[ Version 01.05 ]------------------
 %
 %function SmartBar_01_05() or SmartBar_01_05(Options)
 %
 %A program for batch-converting and processing TEM images. SmartBar's
 %scalebars are more intelligently applied and aesthetically designed. They are
 %automatically adjusted in size, color, stroke, etc to match the images
 %and automatically position themselves in regions of least interest to
 %avoid obscuring the parts of the image you care about. SmartBar also
 %gives the user full control over all these parameters, to adjust to your
 %particular tastes. SmartBar can handle TEM, STEM, and Diffraction images,
 %and allows processing parameters to be tweaked individually for each
 %type.
 %
 %SmartBar can be fed a folder of a whole variety of different file types
 %and will automatically sift through them and apply the appropriate
 %treatments. Currently supported file types include: 
 %.emd (Velox version only)
 %.dm3 (Digital Micrograph)
 %.ser (ESVision/TIA)
 %.tif,.tiff,.jpg,.jpeg,.png,.gif
 %
 %SmartBar has no output variables and can be invoked with or without an input.
 %The user-adjustable parameters are contained at the beginning of this
 %function. If an input variable is provided, it must be a single structure array
 %with fields that match the parameters here. Any matching fields will be used
 %in place of the parameters in this file. (The input need not have every field.)
 %
 %Example without inputs:
 %SmartBar_01_05()
 %
 %Example with inputs:
 %SmartBar_01_05(Options)
 %where Options contains fields like "Options.NormAnswer = 'Yes' "
 %
 %*************************************************************************
 %Copyright (c) 2020, Stephen D. House
 %All rights reserved
 %
 %Redistribution and use in source and binary forms, with or without 
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
 %
 %*************************************************************************
 %SmartBar has been written in a way to avoid all usage of MATLAB toolboxes
 %and to maximize backwards compatibility with older versions of MATLAB. I
 %think it is currently compatible with as old as R2009, and potentially
 %even pre-R2006 (but I lack all those versions to confirm). That is why
 %some functions -- which would be faster, easier, or more compact -- are
 %not used here. I also prefer to sacrifice some code conciseness for the sake
 %of greatly enhanced readability; easier to grok and modify later.
 %Note: EMD/HDF5 images will only work with R2011a and later.
 
%% SmartBar function begins

function SmartBar_01_05(varargin)

%-----[ Begin user-adjustable processing options ]-----

NormAnswer              = 'Yes';     %Whether to normalize the image intensities ('Yes' or 'No')
STEMFractionSaturated   = 0;         %Fraction of pixels (high & low) to saturate during normalization of STEM images. (0-1, default = 0) This value is also used for any image where the imaging mode cannot be determined.
TEMFractionSaturated    = 0.0005;      %As above, but for TEM images. (0-1, default = 0.01 or 0.0005)
DPFractionSaturated     = 0.0005;    %As above, but for TEM diffraction patterns. (0-1, default = 0.0005)

SmartBarAnswer          = 'Yes';     %Whether to apply SmartBars (scalebars) to images ('Yes' or 'No')

%Export Options:
Export8BitNoScalebar    = 'Yes';     %('Yes' or 'No')
Export8BitWithSmartBar  = 'Yes';     %('Yes' or 'No') Note: won't export if SmartBar option not enabled
Export16BitNoScalebar   = 'No';     %('Yes' or 'No')
Export16BitAsRaw        = 'No';     %Export 16bit images with original/raw intensities? ('Yes' or 'No')
ExportScaleList         = 'Yes';     %This is a list of each image name, along with its size and pixel scale ('Yes' or 'No')
EmbedScale              = 'Yes';     %Whether or not to embed the scale metadata in the Tiff resolution tags. ('Yes' or 'No')
                                     %The upside is that programs like ImageJ will be able to read it. The downside is that MSOffice and its ilk will read it, and make their initial sizes tiny when you embed them.
                                     %NOTE: The scalebar images do not have embedded scale metadata by default

%SmartBar Options:
AllowedPositions        = [0,0,1,1]; %Corners of the image the SmartBar is allowed to be in. 1 = 'Yes', 0 = 'No'. Clockwise from Upper Left. [UL,UR,LR,LL]
AllowedScales           = [1,2,5];   %The scale multiples that SmartBar is allowed to test (default = [1,2,5])
TargetBarWidthFraction  = 0.2;       %Fraction of image width for bar width. (0-1, default = 0.2)
TargetBarHeightFraction = 0.01;      %Fraction of image width for bar height. (0-1, default = 0.01)
TargetBarSpacing        = 2;         %What multiple of bar height should the bar be away from the corner of the image (default = 2)
TargetLabelSpacing      = 0.5;       %What fraction of bar height to put as spacing between the bar and label (0-1, default = 0.5)
TargetLabelHeight       = 4;         %Height of the scalebar label, in units of bar height (Note: actual font height is shorter than this) (default = 4)
TargetStroke            = 0.2;       %Fraction of scalebar height the stroke should be (0-1, default = 0.2)

%-----[ End of user-adjustable processing options ]-----

%Check for function inputs and swap them if appropriate
switch nargin
    case 0 %No inputs provided
        %Leave parameters as-is
    case 1
        Options = varargin{1};
        if isstruct(Options) %Input is a structure array
            if isfield(Options,NormAnswer) %Checks if a matching field exists and replaces the value if it does
                NormAnswer = Options.NormAnswer;
            end
            if isfield(Options,STEMFractionSaturated)
                STEMFractionSaturated = Options.STEMFractionSaturated;
            end
            if isfield(Options,TEMFractionSaturated)
                TEMFractionSaturated = Options.TEMFractionSaturated;
            end
            if isfield(Options,DPFractionSaturated)
                DPFractionSaturated = Options.DPFractionSaturated;
            end
            if isfield(Options,SmartBarAnswer)
                SmartBarAnswer = Options.SmartBarAnswer;
            end
            if isfield(Options,Export8BitNoScalebar)
                Export8BitNoScalebar = Options.Export8BitNoScalebar;
            end
            if isfield(Options,Export8BitWithSmartBar)
                Export8BitWithSmartBar = Options.Export8BitWithSmartBar;
            end
            if isfield(Options,Export16BitNoScalebar)
                Export16BitNoScalebar = Options.Export16BitNoScalebar;
            end
            if isfield(Options,Export16BitAsRaw)
                Export16BitAsRaw = Options.Export16BitAsRaw;
            end
            if isfield(Options,ExportScaleList)
                ExportScaleList = Options.ExportScaleList;
            end
            if isfield(Options,EmbedScale)
                EmbedScale = Options.EmbedScale;
            end
            if isfield(Options,AllowedPositions)
                AllowedPositions = Options.AllowedPositions;
            end
            if isfield(Options,AllowedScales)
                AllowedScales = Options.AllowedScales;
            end
            if isfield(Options,TargetBarWidthFraction)
                TargetBarWidthFraction = Options.TargetBarWidthFraction;
            end
            if isfield(Options,TargetBarHeightFraction)
                TargetBarHeightFraction = Options.TargetBarHeightFraction;
            end
            if isfield(Options,TargetBarSpacing)
                TargetBarSpacing = Options.TargetBarSpacing;
            end
            if isfield(Options,TargetLabelSpacing)
                TargetLabelSpacing = Options.TargetLabelSpacing;
            end
            if isfield(Options,TargetLabelHeight)
                TargetLabelHeight = Options.TargetLabelHeight;
            end
            if isfield(Options,TargetStroke)
                TargetStroke = Options.TargetStroke;
            end
        else %Input provided is not a structure
            disp('Input must be a structure array.')
            return
        end
    otherwise %More than one input, bad!
        disp('Too many input parameters! Only 0 or 1 inputs are allowed.')
        return
end

InputError = 0; %Dummy variable for indicating whether there are any errors in the inputs
SmartBarCheck(); %Checks the input variables, to make sure nothing's illegal
if InputError == 0 %No errors with the inputs
    SmartBarEngine(); %Invokes the function that runs all the processing
else %There are input errors
	disp('Please fix the above inputs before running program.')
    return
end

%-----[ Nested functions begin below ]-----

function SmartBarCheck()%Will change InputError to '1' if there are any errors with the inputs
%Should probably check input type, too.
%Errors can still be caused by garbage input. Should these be try/catch?
%R2017+ added a bunch of convenient input-vetting functions
if strcmp(NormAnswer,'Yes') || strcmp(NormAnswer,'No')
else
    disp('NormAnswer must be ''Yes'' or ''No''.')
    InputError = 1;
end
if STEMFractionSaturated<0 || STEMFractionSaturated>1
    disp('STEMFractionSaturated must be between 0-1.')
    InputError = 1;
end
if TEMFractionSaturated<0 || TEMFractionSaturated>1
    disp('TEMFractionSaturated must be between 0-1.')
    InputError = 1;
end
if DPFractionSaturated<0 || DPFractionSaturated>1
    disp('DPFractionSaturated must be between 0-1.')
    InputError = 1;
end
if strcmp(SmartBarAnswer,'Yes') || strcmp(SmartBarAnswer,'No')
else
    disp('SmartBarAnswer must be ''Yes'' or ''No''.')
    InputError = 1;
end
if strcmp(Export8BitNoScalebar,'Yes') || strcmp(Export8BitNoScalebar,'No')
else
    disp('Export8BitNoScalebar must be ''Yes'' or ''No''.')
    InputError = 1;
end
if strcmp(Export8BitWithSmartBar,'Yes') || strcmp(Export8BitWithSmartBar,'No')
else
    disp('Export8BitWithSmartBar must be ''Yes'' or ''No''.')
    InputError = 1;
end
if strcmp(Export8BitWithSmartBar,'Yes') && strcmp(SmartBarAnswer,'No')
    disp('Images with SmartBars cannot be exported if SmartBarAnswer is ''No''.')
    InputError = 1;
end
if strcmp(Export16BitNoScalebar,'Yes') || strcmp(Export16BitNoScalebar,'No')
else
    disp('Export16BitNoScalebar must be ''Yes'' or ''No''.')
    InputError = 1;
end
if strcmp(NormAnswer,'No') && strcmp(Export16BitAsRaw,'Yes')
    disp('Normalized 16-bit images cannot be exported if NormAnswer is ''No''.')
    InputError = 1;
end
if strcmp(ExportScaleList,'Yes') || strcmp(ExportScaleList,'No')
else
    disp('ExportScaleList must be ''Yes'' or ''No''.')
    InputError = 1;
end
if strcmp(EmbedScale,'Yes') || strcmp(EmbedScale,'No')
else
    disp('EmbedScale must be ''Yes'' or ''No''.')
    InputError = 1;
end
if any(AllowedPositions ~= 0 & AllowedPositions ~= 1)
    disp('AllowedPosition entries must be "0" or "1".')
    InputError = 1;
end
if strcmp(SmartBarAnswer,'Yes') && sum(AllowedPositions)<1
    disp('At least one position must be allowed for scalebar placement.')
    InputError = 1;
end
if TargetBarWidthFraction<0 || TargetBarWidthFraction>1
    disp('TargetBarWidthFraction must be between 0-1.')
    InputError = 1;
end
if TargetBarHeightFraction<0 || TargetBarHeightFraction>1
    disp('TargetBarHeightFraction must be between 0-1.')
    InputError = 1;
end
if TargetBarSpacing <0
    disp('TargetBarSpacing must be non-zero.')
    InputError = 1;
end
if TargetLabelHeight<=0
    disp('TargetLabelHeight must be >0.')
    InputError = 1;
end
if TargetStroke<0 || TargetStroke>1
    disp('TargetStroke must be between 0-1.')
    InputError = 1;
end
end %End of SmartBarCheck function

function SmartBarEngine() %This is the main function, that does all the processing
%% Select the files to be converted
[ImageFileNames,ImageFilePaths,~] = uigetfile({'*.emd;*.dm3;*.ser;*.tif;*.tiff','Micrograph Files (.emd,.dm3,.ser,.tif...)';...
    '*.emd','EMD/Velox Files (*.emd)';...
    '*.dm3','Digital Micrograph Files (*.dm3)';...
    '*.tif;*.tiff','TIFF Files (*.tif,*.tiff)';...
    '*.ser','ESVision Files (*.ser)';...
    '*.*','All Files (*.*)'},...
    'Select the image file(s) to analyze.','MultiSelect','on');    

if isequal(ImageFileNames,0)
   disp('User selected Cancel')
   return
end %End check of whether user selected any files

%Ask for the location, if any export options were selected
if  strcmp(Export8BitNoScalebar,'Yes')||strcmp(Export8BitWithSmartBar,'Yes')||strcmp(Export16BitNoScalebar,'Yes')||strcmp(ExportScaleList,'Yes')
    [~,SavePath,~] = uiputfile({'*.*'},'Choose location for exported files','Results');
    if isequal(SavePath,0)
        disp('User selected Cancel')
        return
    end %End check of whether user selected a save directory
    
    %This next block creates a folder called "SmartBar" to save the exported files in
    %Along with sub-folders for each exported image type
    OriginalFolder = cd(SavePath); %Changes folder to save directory, but stores the original folder path
    if strcmp(ExportScaleList,'Yes')
        mkdir SmartBar
    end
    if strcmp(Export8BitNoScalebar,'Yes')
        mkdir SmartBar SBtif_8bit
    end
    if strcmp(Export8BitWithSmartBar,'Yes')
        mkdir SmartBar SBtif_8bit_Scalebar
    end
    if strcmp(Export16BitNoScalebar,'Yes')
        mkdir SmartBar SBtif_16bit
    end
    cd(OriginalFolder) %Restores the original folder
end

%% Prepare for data extraction
warning('off','images:initSize:adjustingMag'); %This just stops the warnings about displaying images at reduced sizes from spamming the command window
addpath(ImageFilePaths,'-begin')

if isequal(class(ImageFileNames),'char') %Only one image file selected (>1 has class 'cell')
    ImageFileNames = {ImageFileNames}; %Converts its type to a cell, so its class is the same as for >1 image
end

NumFiles = length(ImageFileNames); %Count how many files were selected
disp(['Image File(s): ', fullfile(ImageFilePaths, ImageFileNames{1}),' and ',num2str(NumFiles-1),' more.'])

%Create storage arrays
RawMetadata = cell(NumFiles,1); %The full raw char string
ImageMetadata = cell(NumFiles,4); %The extracted size and scale metadata
%Col 1&2=Image Size width & height, Col 3 = pixel size, Col 4 = pixel size units
ScaleBarInfo = cell(NumFiles,4);
%1=ScalebarW in px, 2=in units, 3=Scalebar label, 4=ScalebarH in px

%Create a cell array to hold the file name and its extension
%Col 1: The name will be used in creating file names to save to
%Col 2: The extension will be used to determine file type. Includes the "."
ImageFileNameParts = cell(NumFiles,2);
for j = 1:NumFiles
    [~,FileName,FileExt] = fileparts(ImageFileNames{j});
    ImageFileNameParts(j,1:2) = {FileName,FileExt};
end

UnitTypes = {'pm','nm','µm','mm','m'}; %These are the possible units the scale could be. (pm will be converted to Å)
AltUnitTypes = {'pm','nm','um','mm','m'}; %May be needed if the files encoded micrometers as um instead of µm

NumUnsuitableFiles = 0; %Number of unsuitable (e.g., non-image) files selected by the user
NumNoScaleFiles = 0; %Number of image files that lacked scale metadata (and so could not have SmartBars applied)
SkippedSmartBar = 0; %A dummy variable used for images that lack scale information

MLVersion = version('-release');
if str2double(MLVersion(1:4)) >= 2011 %MATLAB version is R2011a or newer, and thus has HDF5 functions
    HasR2011aOrNewer = 1; %Dummy variable for indicating whether or not to process HDF5/EMD files
else %Older than R2011a
    HasR2011aOrNewer = 0; %HDF5/EMD files will be skipped
end

%% Begin data processing loop:
ProgressBar = waitbar(0,'Preparing to process images...');

for i = 1:NumFiles %Loops through each of the selected files, one at a time.
%% Import data and extract metadata
waitbar(i/NumFiles,ProgressBar,sprintf('Importing image and metadata for image %d of %d',i,NumFiles));

switch ImageFileNameParts{i,2} %Applies the appropriate metadata extraction method based on file type
    case '.emd'
        %%%Add in a check and separator so it can handle normal/proper EMD
        %%%files as well as Velox's off-white version. Right now it treats
        %%%all .emd files as Velox, which will obviously cause problems.
        %%%Use a try/catch, because the check will look for errors
        
        %The Velox .emd reading functionality was moved into a standalone
        %function file, so that (1) it could be used in other programs, (2)
        %you can run SmartBar in pre-R2011a as long as you aren't reading
        %.emd files, and (3) it's easier to modify/expand ReadVelox later
        if HasR2011aOrNewer == 1
            OutputData = [];
            evalc('[OutputData] = ReadVelox(ImageFileNames{i})'); %Evalc wrapper to suppress the function's output to the consoel

            %Extract the image data from the outputted structure
            RawImage = OutputData.RawImage;
            RawMetadata{i} = OutputData.RawMetadata;
            ImageMode = OutputData.ImageMode;
            ImageMetadata(i,1:4) = {OutputData.ImageWidth,OutputData.ImageHeight,OutputData.PixelScale,OutputData.PixelUnit};
        else %MATLAB version is too old to have the HDF5 functions
            NumUnsuitableFiles = NumUnsuitableFiles + 1;
            ImageMetadata(i,1:4) = {0,0,1,'n/a'};
            if NumUnsuitableFiles == 1
                disp('At least one file is unsuitable for processing and has been skipped.')
            end
            if HasR2011aOrNewer == 0
                disp(['This MATLAB version (R',MLVersion,') cannot read HDF5/EMD files. Such files will be skipped. Requires R2011a or newer.']) 
                HasR2011aOrNewer = 2; %So this warning won't be triggered again
            end
            continue %Skips to next iteration in the for loop (i.e., the next file)
        end

    case '.dm3'
        evalc('[RawImage,~,~] = ReadDM3(ImageFileNames{i},''DMImportLog.txt'')'); %It's in an evalc wrapper to prevent it from barfing the whole log file to the console
        RawMetadata{i} = fileread('DMImportLog.txt'); %Reads in the file as a char vector

        RawImage = double(RawImage);
        RawImage = RawImage'; %Transpose the image to match how it is displayed in Digital Micrograph and ImageJ
        
        ImageMetadata(i,1:2) = {size(RawImage,2),size(RawImage,1)}; %Image Width and Height

        %Check the image type: IMAGING, SCANNING, or DIFFRACTION for TEM, STEM, or DP, respectively
        OperationModePattern = '\|\s\|\s\|\s\|\s\-\sOperation Mode:\s(\w+)';
        [~,ModeTokens,~] = regexp(RawMetadata{i},OperationModePattern,'match','tokens','tokenExtents');
        if isempty(ModeTokens) %.dm3 files created from tifs (etc) do not have the complete metadata necessary for determining mode or scale
            ModeTokens = {'STEM'}; %Default it to STEM
        else
            ModeTokens = ModeTokens{1};
        end
        %Currently assuming square pixels with the same scale
        PixelScalePattern = '\|\s\|\s\|\s\|\s\|\s\|\s\-\sScale:\s(\d+)\.(\d+)\e(\-?\+?\d+)';

        switch ModeTokens{1}
            case 'IMAGING'
                ImageMode = 'TEM';
                PixelUnitPattern = '\|\s\|\s\|\s\|\s\|\s\|\s\-\sUnits:\s(\w+)'; %Not sure what DM puts for micrometers. If it's mu, this will fail.
            case 'SCANNING'
                ImageMode = 'STEM';
                PixelUnitPattern = '\|\s\|\s\|\s\|\s\|\s\|\s\-\sUnits:\s(\w+)';
            case 'DIFFRACTION'
                ImageMode = 'DP';
                PixelUnitPattern = '\|\s\|\s\|\s\|\s\|\s\|\s\-\sUnits:\s(1\/\w+)';
        end

        [~,PixelScaleTokens,~] = regexp(RawMetadata{i},PixelScalePattern,'match','tokens','tokenExtents');
        [~,PixelUnitTokens,~] = regexp(RawMetadata{i},PixelUnitPattern,'match','tokens','tokenExtents');
        
        if isempty(PixelScaleTokens) %.dm3 file is lacking scale information
            NumNoScaleFiles = NumNoScaleFiles + 1;
            if strcmp(SmartBarAnswer,'Yes')
                if NumNoScaleFiles == 1
                    disp('At least one file does not contain scale information and will not have a scalebar applied.')
                end
                SmartBarAnswer = 'No'; %Temporarily disable SmartBar
                ImageMetadata(i,3:4) = {1,'n/a'}; %Fills in blanks into the metadata array (for the export)
                SkippedSmartBar = 1; %Set a trigger to re-enable SmartBar at the end of the loop
            end
        else %.dm3 file has scale information
            PixelScaleTokens = PixelScaleTokens{1}; %Is a 1x3: #.#e# (Exponent will have a +/- if there)
            PixelUnitTokens = PixelUnitTokens{1}; %Is a 1x1
            PixelScale = (str2double(PixelScaleTokens{1})+str2double(['.',PixelScaleTokens{2}]))*10^str2double(PixelScaleTokens{3}); %Converts pixel scale tokens to a meaningful form
            
            switch ImageMode
                case {'TEM','STEM'}
                    if ~strcmp(PixelUnitTokens{1},'m') %If the PixelScale is not already in meters
                        if strcmp(PixelUnitTokens{1},'µm') %If it uses the Greek letter mu
                            InitialUnit = 3; %Initial unit is micrometers
                        else
                            InitialUnit = find(strcmp(PixelUnitTokens{1},AltUnitTypes)); %Assuming it doesn't use Greek letters
                        end
                        NumUnitSteps = 5-InitialUnit; %Number of unit changes needed to reach meters
                        PixelScale = PixelScale/(10^(NumUnitSteps*3)); %Convert PixelScale into m/px
                        ImageMetadata(i,3:4) = {PixelScale,'m'};
                    end
                case 'DP'
                    if ~strcmp(PixelUnitTokens{1},'1/m') %If the PixelScale is not already in inverse meters
                        if strcmp(PixelUnitTokens{1},'1/µm') %If it uses the letter mu
                            InitialUnit = 3;
                        else
                            InitialUnit = find(strcmp(PixelUnitTokens{1}(3:end),AltUnitTypes));
                        end
                        NumUnitSteps = 5-InitialUnit; %Number of unit changes needed to reach meters
                        PixelScale = PixelScale*(10^(NumUnitSteps*3)); %Convert PixelScale into (1/m)/px
                        ImageMetadata(i,3:4) = {PixelScale,'1/m'};
                    end
            end %End PixelScale conversion switch
        end %End if check for having scale information
        
    case '.ser'
        %serReader only provides the image and the X&Y pixel calibration, no units or anything else
        %Based off the values, I think the units are m/px, and I am just guessing, then, that the DP units would be 1/m
        
        SerImage = []; %Create variable prior to calling serReader (needed to avoid error)
        evalc('SerImage = serReader(ImageFileNames{i})'); %Again, using an elvac wrapper to suppress the console output
        RawImage = rot90(SerImage.image); %Rotate the image to match how it is displayed in ImageJ and ESVision
        ImageMetadata(i,1:2) = {size(RawImage,2),size(RawImage,1)}; %Image Width and Height
        
        %If DP are in 1/m, then the sign of the exponent can be used to determine whether the image is real space or reciprocal
        PixelScaleExponent = floor(log10(SerImage.calibration(1))); %Calculate the exponent of the pixel calibration
        if PixelScaleExponent <= 0 %I.e., a real space image
            ImageMetadata(i,3:4) = {SerImage.calibration(1),'m'};
            ImageMode = 'STEM'; %There's no way to tell apart STEM or TEM with serReader, so SmartBar defaults to STEM
        else %PixelScaleExponen > 0, i.e., a DP
            ImageMetadata(i,3:4) = {SerImage.calibration(1),'1/m'};
            ImageMode = 'DP';
        end

    case {'.tif','.tiff','.png','.jpg','.jpeg','.gif'}
        RawImage = double(imread(ImageFileNames{i}));

        if ndims(RawImage) == 2||3
            if ndims(RawImage) == 3 %If it is a color image
                %RawImage = rgb2gray(RawImage); %Convert the image to grayscale
                RawImage = ConvertImage(RawImage,'0-1'); %Convert the image to grayscale
            end
            
            ImageMetadata(i,1:2) = {size(RawImage,2),size(RawImage,1)}; %Image Width and Height
            RawMetadata{i} = imfinfo(ImageFileNames{i}); %Extracts the TIFF file info, including Tags
            
            %Check if ResolutionUnit or XResolution tags are empty (switch needs scalars or char vectors)
            %This is also currently set to remove "default" screen res scales (72 or 96 dpi), since those aren't "real" for this purpose
            if isempty(RawMetadata{i}.ResolutionUnit)||isempty(RawMetadata{i}.XResolution)||(RawMetadata{i}.XResolution==72)||(RawMetadata{i}.XResolution==96)
                RawMetadata{i}.ResolutionUnit = 1; %Set the Tag to "None"
            end
            
            switch RawMetadata{i}.ResolutionUnit
                case {3,'Centimeter','centimeter','cm'}
                    ImageMetadata(i,3:4) = {1/(RawMetadata{i}.XResolution*100),'m'}; %XResolution Tag is in px/cm
                case {2,'Inch','inch','in'}
                    ImageMetadata(i,3:4) = {1/(RawMetadata{i}.XResolution*39.370078740157),'m'}; %39.370078740157 inches per meter
                otherwise %No scale information
                    NumNoScaleFiles = NumNoScaleFiles + 1;
                    if strcmp(SmartBarAnswer,'Yes')
                        if NumNoScaleFiles == 1
                            disp('At least one file does not contain scale information and will not have a scalebar applied.')
                        end
                        SmartBarAnswer = 'No'; %Temporarily disable SmartBar
                        ImageMetadata(i,3:4) = {1,'n/a'}; %Fills in blanks into the metadata array (for the export)
                        SkippedSmartBar = 1; %Set a trigger to re-enable SmartBar at the end of the loop
                    end
            end
            ImageMode = 'STEM'; %Defaults to STEM because there is no Tiff Tag for image mode
        else %unsuitable file
            NumUnsuitableFiles = NumUnsuitableFiles + 1;
            ImageMetadata(i,1:4) = {0,0,1,'n/a'};
            if NumUnsuitableFiles == 1
                disp('At least one file is unsuitable for processing and has been skipped.')
            end
            continue %Skips to next iteration in the for loop (i.e., the next file)
        end
        
    otherwise
        NumUnsuitableFiles = NumUnsuitableFiles + 1;
        ImageMetadata(i,1:4) = {0,0,1,'n/a'};
        if NumUnsuitableFiles == 1
            disp('At least one file is unsuitable for processing and has been skipped.')
        end
        continue %Skips to next iteration in the for loop (i.e., the next file)
end %End switch based on file extension (to extract image and metadata)

%% Image Processing
switch NormAnswer
    case 'Yes'
        waitbar(i/NumFiles,ProgressBar,sprintf('Normalizing image %d of %d',i,NumFiles));
        switch ImageMode
            case 'STEM'
                if STEMFractionSaturated ~= 0 %User wants to saturate a certain fraction of pixels
                    RawImageIntensities = sort(RawImage(:),'descend'); %Arranges all intensities from high to low
                    TopFractionCutOff = RawImageIntensities(floor(length(RawImageIntensities)*STEMFractionSaturated)); %The value of the #% highest intensity
                    BottomFractionCutOff = RawImageIntensities(ceil(length(RawImageIntensities)*(1-STEMFractionSaturated))); %The value of the #% lowest intensity
                    
                    %Saturate the top and bottom #% of the image
                    SaturatedImage = RawImage; 
                    SaturatedImage(SaturatedImage>=TopFractionCutOff) = TopFractionCutOff;
                    SaturatedImage(SaturatedImage<=BottomFractionCutOff) = BottomFractionCutOff;
                    
                    %Normalize the intensities
                    MinInt = min(SaturatedImage(:)); 
                    NormalizedImage = (double(SaturatedImage)-double(MinInt))./double(max(SaturatedImage(:))-MinInt); 
                else %No saturation
                    MinInt = min(RawImage(:));
                    NormalizedImage = (double(RawImage)-double(MinInt))./double(max(RawImage(:))-MinInt);   
                end
            case 'TEM'
                if TEMFractionSaturated ~= 0 %User wants to saturate a certain fraction of pixels
                    RawImageIntensities = sort(RawImage(:),'descend'); %Arranges all intensities from high to low
                    TopFractionCutOff = RawImageIntensities(floor(length(RawImageIntensities)*TEMFractionSaturated)); %The value of the #% highest intensity
                    BottomFractionCutOff = RawImageIntensities(ceil(length(RawImageIntensities)*(1-TEMFractionSaturated))); %The value of the #% lowest intensity
                    
                    %Saturate the top and bottom #% of the image
                    SaturatedImage = RawImage; 
                    SaturatedImage(SaturatedImage>=TopFractionCutOff) = TopFractionCutOff;
                    SaturatedImage(SaturatedImage<=BottomFractionCutOff) = BottomFractionCutOff;
                    
                    %Normalize the intensities
                    MinInt = min(SaturatedImage(:)); 
                    NormalizedImage = (double(SaturatedImage)-double(MinInt))./double(max(SaturatedImage(:))-MinInt); 
                else %No saturation
                    MinInt = min(RawImage(:));
                    NormalizedImage = (double(RawImage)-double(MinInt))./double(max(RawImage(:))-MinInt);   
                end   
            case 'DP'
                if DPFractionSaturated ~= 0 %User wants to saturate a certain fraction of pixels
                    RawImageIntensities = sort(RawImage(:),'descend'); %Arranges all intensities from high to low
                    TopFractionCutOff = RawImageIntensities(floor(length(RawImageIntensities)*DPFractionSaturated)); %The value of the #% highest intensity
                    BottomFractionCutOff = RawImageIntensities(ceil(length(RawImageIntensities)*(1-DPFractionSaturated))); %The value of the #% lowest intensity

                    %Saturate the top and bottom #% of the image
                    SaturatedImage = RawImage; 
                    SaturatedImage(SaturatedImage>=TopFractionCutOff) = TopFractionCutOff;
                    SaturatedImage(SaturatedImage<=BottomFractionCutOff) = BottomFractionCutOff;

                    %Normalize the intensities
                    MinInt = min(SaturatedImage(:)); 
                    NormalizedImage = (double(SaturatedImage)-double(MinInt))./double(max(SaturatedImage(:))-MinInt); 
                else %No saturation
                    MinInt = min(RawImage(:));
                    NormalizedImage = (double(RawImage)-double(MinInt))./double(max(RawImage(:))-MinInt);   
                end 
        end
    case 'No'
        %Do nothing
end
%% Smartbar Application
switch SmartBarAnswer
    case 'Yes'
        waitbar(i/NumFiles,ProgressBar,sprintf('Determining SmartBar for image %d of %d',i,NumFiles));
        
        TargetBarWidth = ImageMetadata{i,1}*TargetBarWidthFraction; %These are what SmartBar will use as its size goals. In pixels
        TargetBarWidthUnits = TargetBarWidth*ImageMetadata{i,3}; %The target width, but in micrograph units (meters, in this case)
        PixelScaleExponent = floor(log10(TargetBarWidthUnits)); %How many digits before the decimel, rounded down.

        %Determine the number of unit changes required (every multiple of 3 in exponent)
        if PixelScaleExponent < 0
            NumUnitSteps = ceil(abs(PixelScaleExponent/3));
        elseif PixelScaleExponent > 0
            NumUnitSteps = floor(abs(PixelScaleExponent/3));
        else %PixelScaleExponent == 0
            NumUnitSteps = 0; %No need to change units
        end
        UnitRemainder = NumUnitSteps*3-abs(PixelScaleExponent); %The number of zeros in the scale label (0,1,2)
        ScaleOptions = AllowedScales*(10^abs(UnitRemainder)); %What lengths (in units) the scalebar can be

        %Converts the target bar width into the correct unit
        if PixelScaleExponent <= 0
            TargetBarWidthScaled = TargetBarWidthUnits*(10^(NumUnitSteps*3));
        else %PixelScaleExponent > 0
            TargetBarWidthScaled = TargetBarWidthUnits/(10^(NumUnitSteps*3));
        end

        [~,IDX] = min(abs(ScaleOptions-TargetBarWidthScaled)); %Determine which of the scalebar lengths is closest to the target
        ScaleBarWidthUnits = ScaleOptions(IDX); %Width of the scalebar, in units
        ScaleBarWidthPixels = round(TargetBarWidth*(ScaleBarWidthUnits/TargetBarWidthScaled)); %Width of the scalebar, rounded to the nearest pixel
        ScaleBarHeightPixels = round(ImageMetadata{i,1}*TargetBarHeightFraction); %Height of scalebar, in pixels

        %This block determines what the label of the scalebar will be
        switch ImageMode
            case {'STEM','TEM'}
                InitialUnit = find(strcmp(ImageMetadata{i,4},UnitTypes)); %Returns the index of the original pixel unit
                ScaledUnit = UnitTypes{InitialUnit + sign(PixelScaleExponent)*NumUnitSteps}; %Shifts the index according to how many unit steps and direction
                if strcmp(ScaledUnit,'pm') %If the label would be in pm
                    ScaleBarWidthUnits = ScaleBarWidthUnits/100; %Scale it from pm to Å
                    ScaledUnit = 'Å';
                end
            case 'DP'
                InitialUnit = find(strcmp(ImageMetadata{i,4}(3:end),UnitTypes)); %Returns the index of the original pixel unit
                ScaledUnit = ['1/',UnitTypes{InitialUnit - sign(PixelScaleExponent)*NumUnitSteps}]; %Shifts in the opposite direction because it is inverse units
                if strcmp(ScaledUnit,'1/pm') %If the label would be in 1/pm
                    ScaleBarWidthUnits = ScaleBarWidthUnits*100; %Scale it from 1/pm to 1/Å
                    ScaledUnit = '1/Å';
                end
        end
        ScaleBarLabel = [num2str(ScaleBarWidthUnits),' ',ScaledUnit]; %The label for the scalebar
        ScaleBarInfo(i,:) = {ScaleBarWidthPixels,ScaleBarWidthUnits,ScaleBarLabel,ScaleBarHeightPixels}; %Stores the scalebar info in a storage array, in case it's needed.
        
        BarSpacing = round(ScaleBarHeightPixels*TargetBarSpacing); %Distance bar will be from corner of image. In px.
        LabelSpacing = ceil(ScaleBarHeightPixels*TargetLabelSpacing); %Spacing between bar and label. In px.
        ScaleLabelFontSize = round(ScaleBarHeightPixels*TargetLabelHeight);
        
        %These are the outer dimensions of the scalebar and label combination
        SmartBarBoundsHeight = ScaleBarHeightPixels+LabelSpacing+ScaleLabelFontSize;
        SmartBarBoundsWidth = ScaleBarWidthPixels;
        
        %AllowedPositions = [#,#,#,#]; %What corners of the image the scalebar is allowed to be in. 1 = 'Yes', 0 = 'No'. Clockwise from Upper Left.
        %Calculate the variance of the (up to) 4 regions
        RegionVariance = [NaN,NaN,NaN,NaN];
        Subregions = {NaN,NaN,NaN,NaN};
        
        %Array addressing is Row,Col
        switch NormAnswer
            case 'Yes' %Use NormalizedImage
                if AllowedPositions(1) == 1 %Upper left is allowed
                    Subregions{1} = NormalizedImage(BarSpacing:(BarSpacing+SmartBarBoundsHeight),BarSpacing:(BarSpacing+SmartBarBoundsWidth));
                    RegionVariance(1) = VarCalc(Subregions{1}); %VarCalc function is defined at end of file
                end
                if AllowedPositions(2) == 1 %Upper right is allowed
                    Subregions{2} = NormalizedImage(BarSpacing:(BarSpacing+SmartBarBoundsHeight),(ImageMetadata{i,1}-(BarSpacing+SmartBarBoundsWidth)):(ImageMetadata{i,1}-BarSpacing));
                    RegionVariance(2) = VarCalc(Subregions{2});
                end
                if AllowedPositions(3) == 1 %Lower right is allowed
                    Subregions{3} = NormalizedImage((ImageMetadata{i,2}-(BarSpacing+SmartBarBoundsHeight)):(ImageMetadata{i,2}-BarSpacing),(ImageMetadata{i,1}-(BarSpacing+SmartBarBoundsWidth)):(ImageMetadata{i,1}-BarSpacing));
                    RegionVariance(3) = VarCalc(Subregions{3});
                end
                if AllowedPositions(4) == 1 %Lower left is allowed
                    Subregions{4} = NormalizedImage((ImageMetadata{i,2}-(BarSpacing+SmartBarBoundsHeight)):(ImageMetadata{i,2}-BarSpacing),BarSpacing:(BarSpacing+SmartBarBoundsWidth));
                    RegionVariance(4) = VarCalc(Subregions{4});
                end
            case 'No' %Use RawImage
                if AllowedPositions(1) == 1 %Upper left is allowed
                    Subregions{1} = RawImage(BarSpacing:(BarSpacing+SmartBarBoundsHeight),BarSpacing:(BarSpacing+SmartBarBoundsWidth));
                    RegionVariance(1) = VarCalc(Subregions{1});
                end
                if AllowedPositions(2) == 1 %Upper right is allowed
                    Subregions{2} = RawImage(BarSpacing:(BarSpacing+SmartBarBoundsHeight),(ImageMetadata{i,1}-(BarSpacing+SmartBarBoundsWidth)):(ImageMetadata{i,1}-BarSpacing));
                    RegionVariance(2) = VarCalc(Subregions{2});
                end
                if AllowedPositions(3) == 1 %Lower right is allowed
                    Subregions{3} = RawImage((ImageMetadata{i,2}-(BarSpacing+SmartBarBoundsHeight)):(ImageMetadata{i,2}-BarSpacing),(ImageMetadata{i,1}-(BarSpacing+SmartBarBoundsWidth)):(ImageMetadata{i,1}-BarSpacing));
                    RegionVariance(3) = VarCalc(Subregions{3});
                end
                if AllowedPositions(4) == 1 %Lower left is allowed
                    Subregions{4} = RawImage((ImageMetadata{i,2}-(BarSpacing+SmartBarBoundsHeight)):(ImageMetadata{i,2}-BarSpacing),BarSpacing:(BarSpacing+SmartBarBoundsWidth));
                    RegionVariance(4) = VarCalc(Subregions{4});
                end
        end
        
        %Determine what region the SmartBar will be in
        [~,SmartBarPosition] = min(RegionVariance); %Returns the index of the allowed region with lowest variance
        
        %Determine if SmartBar should be dark-on-light or light-on-dark
        RegionIntensity = mean(Subregions{SmartBarPosition}(:));
        switch NormAnswer
            case 'Yes' %Image has been normalized to 0-1 intensity
                if RegionIntensity > 0.5 %Region is lighter
                    SmartBarColor = 'black';
                else %Region is darker
                    SmartBarColor = 'white';
                end
            case 'No'
                ImgMax = max(RawImage(:)); %This block determines what the intensity range the image is (Not ideal, but BitDepth metadata is not always encoded correctly in image files)
                if ImgMax>1 && ImgMax <=255 %The intensities are in the 8bit range
                    MidIntensity = 127;
                elseif ImgMax<=1 %The intensities are in the range 0-1
                    MidIntensity = 0.5;
                elseif ImgMax>255 && ImgMax<=65535 %The intensities are in the uint16 range
                    MidIntensity = 32767;
                else %Assuming, then, the intensities are in the uint32 range
                    MidIntensity = 2147483647;
                end
                if RegionIntensity > MidIntensity %Region is lighter.
                    SmartBarColor = 'black';
                else %Region is darker
                    SmartBarColor = 'white';
                end
        end
        
        switch NormAnswer %Create 8bit image to apply overlay to
            case 'Yes'
                %SmartBarImage = im2uint8(NormalizedImage);
                SmartBarImage = ConvertImage(NormalizedImage,'uint8');
            case 'No'
                %SmartBarImage = im2uint8(RawImage);
                SmartBarImage = ConvertImage(RawImage,'uint8');
        end

        SBPadding = round(ImageMetadata{i,1}/20); %Pixel padding on each side of SmartBar, because for whatever reason, MATLAB tight borders weren't working right with small images. Also gives more space for text to spill over
        SBAnnotation = zeros(SmartBarBoundsHeight+2*SBPadding,SmartBarBoundsWidth+2*SBPadding); %Size of padded SmartBar

        SBFigure = figure('Menubar','none','Toolbar','none','Visible','off');
        imshow(SBAnnotation,'Border','tight','InitialMagnification',100);

        FigureScaleBar = annotation('rectangle','Color','none','FaceColor','white',...
            'Units','pixels','Position',[SBPadding,SBPadding,ScaleBarWidthPixels,ScaleBarHeightPixels]);
        FigureScaleLabel = annotation('textbox','String',ScaleBarLabel,'Color','white',...
            'FontUnits','pixels','FontSize',ScaleLabelFontSize,'FontWeight','bold',...
            'EdgeColor','none','LineStyle','none','Units','pixels',...
            'Position',[0,SBPadding+ScaleBarHeightPixels+LabelSpacing,SmartBarBoundsWidth+2*SBPadding,ScaleLabelFontSize],...
            'HorizontalAlignment','center','VerticalAlignment','middle','Margin',0);

        SBFrame = getframe; %Grab the figure
        SBOverlay = SBFrame.cdata; %Just the image, no borders. It's a 24bit RGB image.
        %SBOverlay = rgb2gray(SBOverlay); %This is the foreground portion of the SmartBar
        SBOverlay = ConvertImage(SBOverlay,'uint8');%This is the foreground portion of the SmartBar

        if TargetStroke ~= 0 %Runs the stroke routine if user has selected a non-zero stroke.
            StrokeSize = max(round(ScaleBarHeightPixels*TargetStroke),3); %Stroke must be at least 1 pixel
            SBStrokeStrel = offsetstrel('ball',StrokeSize,StrokeSize);
            SBStroke = SBOverlay; %This will be the stroke background
            SBStroke = imdilate(SBStroke,SBStrokeStrel); %This is the stroke overlay.
            %The dilation makes the background non-zero, too, so that needs to be corrected:
            SBStroke(SBStroke == min(SBStroke(:))) = 0; %Sets all the pixels with the minimum level to zero.
            [RowNZ,ColNZ,~] = find(SBStroke); %Extract position of all non-zero elements.
            SBStrokeCrop = SBStroke(min(RowNZ):max(RowNZ),min(ColNZ):max(ColNZ)); %Crop away any zero padding
        else %No stroke
            StrokeSize = 0;
            [RowNZ,ColNZ,~] = find(SBOverlay); %Extract position of all non-zero elements.
        end

        SBOverlayCrop = SBOverlay(min(RowNZ):max(RowNZ),min(ColNZ):max(ColNZ)); %Crop away any zero padding
        [SBHeight,SBWidth] = size(SBOverlayCrop);

        close(SBFigure)

        %NOTE: Arrays index from upper left corner (unlike Images, which is from lower left)
        switch SmartBarPosition %Define region of imagethat will be replaced
            case 1 %Upper Left
                OverlayRegion = [BarSpacing+1,(BarSpacing+SBHeight),BarSpacing+1,(BarSpacing+SBWidth)];
            case 2 %Upper Right
                OverlayRegion = [BarSpacing+1,(BarSpacing+SBHeight),(ImageMetadata{i,1}-BarSpacing-SBWidth+1),(ImageMetadata{i,1}-BarSpacing)];
            case 3 %Lower Right
                OverlayRegion = [(ImageMetadata{i,2}-BarSpacing-SBHeight+1),(ImageMetadata{i,2}-BarSpacing),(ImageMetadata{i,1}-BarSpacing-SBWidth+1),(ImageMetadata{i,1}-BarSpacing)];
            case 4 %Lower Left
                OverlayRegion = [(ImageMetadata{i,2}-BarSpacing-SBHeight+1),(ImageMetadata{i,2}-BarSpacing),BarSpacing+1,(BarSpacing+SBWidth)];
        end

        if StrokeSize == 0 %No stroke
            switch SmartBarColor %Overlays the SmartBar into the image matrix
                case 'white'
                    SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4)) =...
                        SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4))...
                        +SBOverlayCrop; %It automatically cuts off if >255
                case 'black'
                    %SBOverlayCrop = imcomplement(SBOverlayCrop); %Inverts the SmartBar for dark-on-light
                    SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4)) =...
                        SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4))...
                        -SBOverlayCrop; %It automatically cuts off if <0
            end
        else %Apply a stroke
            switch SmartBarColor %Overlays the SmartBar into the image matrix
                case 'white'
                    SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4)) =...
                        SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4))...
                        -SBStrokeCrop; %Apply stroke background
                    SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4)) =...
                        SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4))...
                        +SBOverlayCrop; %Apply foreground
                case 'black'
                    SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4)) =...
                        SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4))...
                        +SBStrokeCrop;
                    SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4)) =...
                        SmartBarImage(OverlayRegion(1):OverlayRegion(2),OverlayRegion(3):OverlayRegion(4))...
                        -SBOverlayCrop;
            end
        end %End stroke if
    case 'No'
       %Do nothing
end %End SmartBar Switch

%% Export
waitbar(i/NumFiles,ProgressBar,sprintf('Exporting results for image %d of %d',i,NumFiles));

%Set Tiff tags that are the same for each export
TiffTags.ImageLength         = ImageMetadata{i,2}; %It's height (# rows)
TiffTags.ImageWidth          = ImageMetadata{i,1}; %# cols
TiffTags.Photometric         = Tiff.Photometric.MinIsBlack; %Value = 1
TiffTags.SamplesPerPixel     = 1;
TiffTags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky; %Value = 1
TiffTags.Compression         = Tiff.Compression.PackBits; %Value = 32773
TiffTags.Software            = 'MATLAB + SmartBar v01.04';
TiffTags.SampleFormat        = Tiff.SampleFormat.UInt; %Value = 1

%For the images with scalebars, do not embed scale metadata, since you wouldn't do measurements on them anyways, and this way you won't have to resize them in MSOffice, etc
TiffTags.ResolutionUnit      = 1;
TiffTags.XResolution         = 96; %Just give it the Windows default of 96 dpi. I don't think it's worth coding in windows vs MAC (72 dpi) vs Linux (screen-dependent)
TiffTags.YResolution         = 96;

switch Export8BitWithSmartBar
    case 'Yes'
        switch SmartBarAnswer
            case 'Yes'
                ExportSaveName = fullfile(SavePath,'SmartBar','SBtif_8bit_Scalebar',[ImageFileNameParts{i,1},'_8bit_SmartBar.tif']);
                
                SBTiff = Tiff(ExportSaveName,'w'); %Have to recreate the Tiff each time, because SBTiff.FileName is a read-only value
                TiffTags.BitsPerSample = 8;       
                setTag(SBTiff,TiffTags);
                
                %write(SBTiff,im2uint8(SmartBarImage));
                write(SBTiff,ConvertImage(SmartBarImage,'uint8'));
                close(SBTiff);
                clear SBTiff
            case 'No'
                %Do nothing. Warnings are given out both earlier and later
        end
    case 'No'
        %Do nothing
end

%For embedding scale metadata in the images without scalebars
%Resolution calculation is assuming ImageMetadata{i,3} is in units of m/px
if strcmp(EmbedScale,'No') || strcmp(ImageMetadata{i,4},'n/a') %If the file did not have scale information
    %Leave scale metadata as default
else %Embed the scale metadata
    TiffTags.ResolutionUnit = 3; %(1="none",2=inch,3=cm) The Tiff standards group really needs to expand the options!
    TiffTags.XResolution    = 1/(ImageMetadata{i,3}*100); %# of pixels per ResolutionUnit (X = width, Y = height)
    TiffTags.YResolution    = 1/(ImageMetadata{i,3}*100); 
end

switch Export8BitNoScalebar
    case 'Yes'
        ExportSaveName = fullfile(SavePath,'SmartBar','SBtif_8bit',[ImageFileNameParts{i,1},'_8bit.tif']);
        
        SBTiff = Tiff(ExportSaveName,'w'); %Have to recreate the Tiff each time, because SBTiff.FileName is a read-only value
        TiffTags.BitsPerSample = 8; %Change for each export block, 8 or 16        
        setTag(SBTiff,TiffTags);
                
        switch NormAnswer
            case 'Yes'
                %write(SBTiff,im2uint8(NormalizedImage));
                write(SBTiff,ConvertImage(NormalizedImage,'uint8'));
            case 'No'
                %write(SBTiff,im2uint8(RawImage));
                write(SBTiff,ConvertImage(RawImage,'uint8'));
        end
        close(SBTiff);
        clear SBTiff
    case 'No'
        %Do nothing
end

switch Export16BitNoScalebar
    case 'Yes'
        ExportSaveName = fullfile(SavePath,'SmartBar','SBtif_16bit',[ImageFileNameParts{i,1},'_16bit.tif']);
        
        SBTiff = Tiff(ExportSaveName,'w'); %Have to recreate the Tiff each time, because SBTiff.FileName is a read-only value
        TiffTags.BitsPerSample = 16;
        setTag(SBTiff,TiffTags);
                
        switch Export16BitAsRaw
            case 'No'
                %write(SBTiff,im2uint16(NormalizedImage));
                write(SBTiff,ConvertImage(NormalizedImage,'uint16'));
            case 'Yes'
                %write(SBTiff,im2uint16(RawImage));
                write(SBTiff,ConvertImage(RawImage,'uint16'));
        end
        close(SBTiff);
        clear SBTiff
    case 'No'
        %Do nothing
end

if SkippedSmartBar == 1 %If SmartBar was temporarily disabled for an image lacking scale information
    SkippedSmartBar = 0;
    SmartBarAnswer = 'Yes'; %Re-enable SmartBar
end
end %End of the image processing loop

%% Finishing Up
waitbar(1,ProgressBar,'Finishing up');

switch ExportScaleList %For exporting a list of images and their pixel scales. Theoretically, this is a much more backwards-compatible approach.
    case 'Yes'
        ImageInfo = [ImageFileNames',ImageMetadata]';
        TableSaveName = fullfile(SavePath,'SmartBar','Image_Metadata.csv');
        fileID = fopen(TableSaveName,'w');
        fprintf(fileID,'Image Name,Width (px),Height (px),Pixel Size, Pixel Units\r\n');
        fprintf(fileID,'%s,%g,%g,%e,%s\r\n',ImageInfo{1:5,:}); %If there are undocumented issues with backwards compatibility, it's this line here, with how cell arrays (and string arrays) are handled)
        fclose(fileID);
    case 'No'
        %Do nothing
end

%%%Export the input parameter information to a file?
%%%I may need to make the SmartBar folder if it doesn't already exist
%%%Try/catch? If it fails, that means nothing else was exported, so don't
%%%bother to export the input parameters, either

if (NumNoScaleFiles >0) && strcmp(SmartBarAnswer,'Yes') %If any files had to be skipped by SmartBar
    if NumNoScaleFiles == 1
        disp('1 file lacked scale information and so could not have a scalebar applied.')
    else
        disp([num2str(NumNoScaleFiles),' files lacked scale information and so could not have scalebars applied.'])
    end
end
if NumUnsuitableFiles >0 %If any unsuitable files had been selected
    if NumUnsuitableFiles == 1
        disp('1 file was found unsuitable and not processed.')
    else
        disp([num2str(NumUnsuitableFiles),' files were found unsuitable and not processed.'])
    end
end

%Delete the log file created by ReadDM3 if any .dm3 files were involved
if any(strcmp(ImageFileNameParts(:,2),'.dm3'))
    delete 'DMImportLog.txt'
end

close(ProgressBar)
warning('on','images:initSize:adjustingMag'); %Turns the warning back on
disp('Image processing complete!')

end %End SmartBarEngine function
end %End SmartBar main function

function [RegionVar] = VarCalc(Subregion) %calculates the variance from the given subregion
%e.g., RegionVariance(3) = VarCalc(Subregions{3});
NormSubregion = medfilt2(Subregion);
NormSubregion = (double(NormSubregion)-double(min(NormSubregion(:))))./double(max(NormSubregion(:))-min(NormSubregion(:)));
RegionVar = var(NormSubregion(:));
end %End of VarCalc function

function OutputImage = ConvertImage(InputImage,BitTarget)
%This function will be used to convert from RGB, or to uint8,uint16, or to
%0-1 doubles WITHOUT normalizing the intensities (i.e., for raws)
%Due to the limitations of what metadata (and its accuracy) the image
%readers provide, the BitDepth can't always be trusted, hence the assumptions made here based on max intensity.
%This function was written to enhance backwards compatibility, since
%im2uint8,im2uint16,rgb2gray all require the Image Processing Toolbox.

%InputImage should only be uint8,uint16,uint32,(positive) double or single,or 24bit RGB
%BitTarget should be 'uint8','uint16','0-1'
   
if ndims(InputImage)>2 %If it's RGB and needs to be converted to grayscale first
    %The weighting coefficients are those used to calculate luminance
    InputImage = 0.2989*InputImage(:,:,1) + 0.5870*InputImage(:,:,2) + 0.1140*InputImage(:,:,3);
end

ImgMin = min(InputImage(:));
ImgMax = max(InputImage(:));

switch BitTarget
    case 'uint8' %convert to uint8
        if ImgMax>1 && ImgMax <=255 %The intensities are in the 8bit range
            OutputImage = uint8(InputImage);
        elseif ImgMax<=1 %The intensities are in the range 0-1
            OutputImage = uint8(InputImage*255);
        elseif ImgMax>255 && ImgMax<=65535 %The intensities are in the uint16 range
            OutputImage = uint8(InputImage*(255/65535));
        else %Assuming, then, the intensities are in the uint32 range
            OutputImage = uint8(InputImage*(255/(2^32-1)));
        end
    case 'uint16' %convert to uint16
        if ImgMax>255 && ImgMax<=65535 %The intensities are in the uint16 range
            OutputImage = uint16(InputImage);
        elseif ImgMax>1 && ImgMax <=255 %The intensities are in the 8bit range
            OutputImage = uint16(InputImage*(65535/255));
        elseif ImgMax<=1 %The intensities are in the range 0-1
            OutputImage = uint16(InputImage*65535);
        else %Assuming, then, the intensities are in the uint32 range
            OutputImage = uint16(InputImage*(65535/(2^32-1)));
        end
   case '0-1'
        if ImgMax<=1 %The intensities are in the range 0-1
            OutputImage = double(InputImage);
        elseif ImgMax>1 && ImgMax <=255 %The intensities are in the 8bit range
            OutputImage = double(InputImage)/255;
        elseif ImgMax>255 && ImgMax<=65535 %The intensities are in the uint16 range
            OutputImage = double(InputImage)/65535;
        else %Assuming, then, the intensities are in the uint32 range
            OutputImage = double(InputImage)/(2^32-1);
        end
end %End BitTarget switch
end %End convertimage function