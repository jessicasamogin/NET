function errorMsg = import_anatomy_fs(iSubject, FsDir, nVertices, isInteractive, sFid, isExtraMaps)
% IMPORT_ANATOMY_FS: Import a full FreeSurfer folder as the subject's anatomy.
%
% USAGE:  errorMsg = import_anatomy_fs(iSubject, FsDir=[], nVertices=15000, isInteractive=1, sFid=[], isExtraMaps=0)
%
% INPUT:
%    - iSubject     : Indice of the subject where to import the MRI
%                     If iSubject=0 : import MRI in default subject
%    - FsDir        : Full filename of the FreeSurfer folder to import
%    - nVertices    : Number of vertices in the file cortex surface
%    - isInteractive: If 0, no input or user interaction
%    - sFid         : Structure with the fiducials coordinates
%    - isExtraMaps  : If 1, create an extra folder "FreeSurfer" to save some of the
%                     FreeSurfer cortical maps (thickness, ...)
% OUTPUT:
%    - errorMsg : String: error message if an error occurs

% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2014 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Francois Tadel, 2012-2013

%% ===== PARSE INPUTS =====
% Extrac cortical maps
if (nargin < 6) || isempty(isExtraMaps)
    isExtraMaps = 0;
end
% Fiducials
if (nargin < 5) || isempty(sFid)
    sFid = [];
end
% Interactive / silent
if (nargin < 4) || isempty(isInteractive)
    isInteractive = 1;
end
% Ask number of vertices for the cortex surface
if (nargin < 3) || isempty(nVertices)
    nVertices = [];
end
% Initialize returned variable
errorMsg = [];
% Ask folder to the user
if (nargin < 2) || isempty(FsDir)
    % Get default import directory and formats
    LastUsedDirs = bst_get('LastUsedDirs');
    % Open file selection dialog
    FsDir = java_getfile( 'open', ...
        'Import FreeSurfer folder...', ...     % Window title
        bst_fileparts(LastUsedDirs.ImportAnat, 1), ...           % Last used directory
        'single', 'dirs', ...                  % Selection mode
        {{'.folder'}, 'FreeSurfer folder', 'FsDir'}, 0);
    % If no folder was selected: exit
    if isempty(FsDir)
        return
    end
    % Save default import directory
    LastUsedDirs.ImportAnat = FsDir;
    bst_set('LastUsedDirs', LastUsedDirs);
end
% Unload everything
bst_memory('UnloadAll', 'Forced');



%% ===== DELETE PREVIOUS ANATOMY =====
% Get subject definition
sSubject = bst_get('Subject', iSubject);
% Check for existing anatomy
if ~isempty(sSubject.Anatomy) || ~isempty(sSubject.Surface)
    % Ask user whether the previous anatomy should be removed
    if isInteractive
        isDel = java_dialog('confirm', ['Warning: There is already an anatomy defined for this subject.' 10 10 ...
            'Are you sure you want to delete the previous MRI and surfaces ?' 10 10], 'Import FreeSurfer folder');
    else
        isDel = 1;
    end
    % If user canceled process
    if ~isDel
        bst_progress('stop');
        return;
    end
    % Delete MRI
    if ~isempty(sSubject.Anatomy)
        file_delete(file_fullpath({sSubject.Anatomy.FileName}), 1);
        sSubject.Anatomy(1:end) = [];
    end
    % Delete surfaces
    if ~isempty(sSubject.Surface)
        file_delete(file_fullpath({sSubject.Surface.FileName}), 1);
        sSubject.Surface(1:end) = [];
    end
    % Empty defaults lists
    sSubject.iAnatomy = [];
    sSubject.iCortex = [];
    sSubject.iScalp = [];
    sSubject.iInnerSkull = [];
    sSubject.iOuterSkull = [];
    % Update subject structure
    bst_set('Subject', iSubject, sSubject);
    panel_protocols('UpdateNode', 'Subject', iSubject);
end


%% ===== ASK NB VERTICES =====
if isempty(nVertices)
    nVertices = java_dialog('input', 'Number of vertices on the cortex surface:', 'Import FreeSurfer folder', [], '15000');
    if isempty(nVertices)
        return
    end
    nVertices = str2double(nVertices);
end
% Number for each hemisphere
nVertHemi = round(nVertices / 2);


%% ===== PARSE FREESURFER FOLDER =====
bst_progress('start', 'Import FreeSurfer folder', 'Parsing folder...');
% Find MRI
MriFile = file_find(FsDir, 'T1.mgz');
if isempty(MriFile)
    errorMsg = [errorMsg 'MRI file was not found: T1.mgz' 10];
end
% Find surfaces
TessLhFile = file_find(FsDir, 'lh.pial');
TessRhFile = file_find(FsDir, 'rh.pial');
TessLwFile = file_find(FsDir, 'lh.white');
TessRwFile = file_find(FsDir, 'rh.white');
TessLsphFile = file_find(FsDir, 'lh.sphere.reg');
TessRsphFile = file_find(FsDir, 'rh.sphere.reg');
if isempty(TessLhFile)
    errorMsg = [errorMsg 'Surface file was not found: lh.pial' 10];
end
if isempty(TessRhFile)
    errorMsg = [errorMsg 'Surface file was not found: rh.pial' 10];
end
% Find volume segmentation
AsegFile = file_find(FsDir, 'aseg.mgz');
% Find labels
AnnotLhFiles = {file_find(FsDir, 'lh.aparc.a2009s.annot'), file_find(FsDir, 'lh.aparc.annot'), file_find(FsDir, 'lh.BA.annot'), file_find(FsDir, 'lh.BA.thresh.annot'), file_find(FsDir, 'lh.aparc.DKTatlas40.annot'), ...
                file_find(FsDir, 'lh.PALS_B12_Brodmann.annot'), file_find(FsDir, 'lh.PALS_B12_Lobes.annot'), file_find(FsDir, 'lh.PALS_B12_OrbitoFrontal.annot'), file_find(FsDir, 'lh.PALS_B12_Visuotopic.annot'), file_find(FsDir, 'lh.Yeo2011_7Networks_N1000.annot'), file_find(FsDir, 'lh.Yeo2011_17Networks_N1000.annot')};
AnnotRhFiles = {file_find(FsDir, 'rh.aparc.a2009s.annot'), file_find(FsDir, 'rh.aparc.annot'), file_find(FsDir, 'rh.BA.annot'), file_find(FsDir, 'rh.BA.thresh.annot'), file_find(FsDir, 'rh.aparc.DKTatlas40.annot'), ...
                file_find(FsDir, 'rh.PALS_B12_Brodmann.annot'), file_find(FsDir, 'rh.PALS_B12_Lobes.annot'), file_find(FsDir, 'rh.PALS_B12_OrbitoFrontal.annot'), file_find(FsDir, 'rh.PALS_B12_Visuotopic.annot'), file_find(FsDir, 'rh.Yeo2011_7Networks_N1000.annot'), file_find(FsDir, 'rh.Yeo2011_17Networks_N1000.annot')};
AnnotLhFiles(cellfun(@isempty, AnnotLhFiles)) = [];
AnnotRhFiles(cellfun(@isempty, AnnotRhFiles)) = [];
% Find thickness maps
if isExtraMaps
    ThickLhFile = file_find(FsDir, 'lh.thickness');
    ThickRhFile = file_find(FsDir, 'rh.thickness');
end
% Find fiducials definitions
FidFile = file_find(FsDir, 'fiducials.m');
% Report errors
if ~isempty(errorMsg)
    if isInteractive
        bst_error(['Could not import FreeSurfer folder: ' 10 10 errorMsg], 'Import FreeSurfer folder', 0);        
    end
    return;
end


%% ===== IMPORT MRI =====
% Read MRI
[BstMriFile, sMri] = import_mri(iSubject, MriFile);
if isempty(BstMriFile)
    errorMsg = 'Could not import FreeSurfer folder: MRI was not imported properly';
    if isInteractive
        bst_error(errorMsg, 'Import FreeSurfer folder', 0);
    end
    return;
end
% Size of the volume
cubeSize = (size(sMri.Cube) - 1) .* sMri.Voxsize;


%% ===== DEFINE FIDUCIALS =====
% If fiducials file exist: read it
OffsetMri = [];
if ~isempty(FidFile)
    % Execute script
    fid = fopen(FidFile, 'rt');
    FidScript = fread(fid, [1 Inf], '*char');
    fclose(fid);
    % Execute script
    eval(FidScript);    
    % If not all the fiducials were loaded: ignore the file
    if ~exist('AC', 'var') || ~exist('PC', 'var') || ~exist('IH', 'var') || ~exist('NAS', 'var') || ~exist('LPA', 'var') || ~exist('RPA', 'var') || ...
        isempty(AC) || isempty(PC) || isempty(IH) || isempty(NAS) || isempty(LPA) || isempty(RPA)
        FidFile = [];
    end
end
% Random points
if ~isInteractive || ~isempty(FidFile)
    % Use fiducials from file
    if ~isempty(FidFile)
        % Already loaded
    % Set some random fiducial points
    elseif isempty(sFid)
        NAS = [cubeSize(1)./2,  cubeSize(2),           cubeSize(3)./2];
        LPA = [1,               cubeSize(2)./2,        cubeSize(3)./2];
        RPA = [cubeSize(1),     cubeSize(2)./2,        cubeSize(3)./2];
        AC  = [cubeSize(1)./2,  cubeSize(2)./2 + 20,   cubeSize(3)./2];
        PC  = [cubeSize(1)./2,  cubeSize(2)./2 - 20,   cubeSize(3)./2];
        IH  = [cubeSize(1)./2,  cubeSize(2)./2,        cubeSize(3)./2 + 50];
    % Else: use the defined ones
    else
        NAS = sFid.NAS;
        LPA = sFid.LPA;
        RPA = sFid.RPA;
        AC = sFid.AC;
        PC = sFid.PC;
        IH = sFid.IH;
    end
    figure_mri('SetSubjectFiducials', iSubject, NAS, LPA, RPA, AC, PC, IH);
% Define with the MRI Viewer
else
    % MRI Visualization and selection of fiducials (in order to align surfaces/MRI)
    hFig = view_mri(BstMriFile, 'EditMri');
    drawnow;
    bst_progress('stop');
    % Display help message: ask user to select fiducial points
    jHelp = bst_help('MriSetup.html', 0);
    % Wait for the MRI Viewer to be closed
    waitfor(hFig);
    % Close help window
    jHelp.close();
end
% Load SCS and NCS field to make sure that all the points were defined
sMri = load(BstMriFile, 'SCS', 'NCS');
if ~isfield(sMri, 'SCS') || isempty(sMri.SCS) || isempty(sMri.SCS.NAS) || isempty(sMri.SCS.LPA) || isempty(sMri.SCS.RPA) || isempty(sMri.SCS.R) || ~isfield(sMri, 'NCS') || isempty(sMri.NCS) || isempty(sMri.NCS.AC) || isempty(sMri.NCS.PC) || isempty(sMri.NCS.IH)
    errMsg = ['Could not import FreeSurfer folder: ' 10 10 'Some fiducial points were not defined properly in the MRI.'];
    if isInteractive
        bst_error(errMsg, 'Import FreeSurfer folder', 0);
    end
    return;
end


%% ===== IMPORT SURFACES =====
% Left pial
if ~isempty(TessLhFile)
    % Import file
    [iLh, BstTessLhFile, nVertOrigL] = import_surfaces(iSubject, TessLhFile, 'FS', 0);
    BstTessLhFile = BstTessLhFile{1};
    % Load atlases
    if ~isempty(AnnotLhFiles)
        bst_progress('start', 'Import FreeSurfer folder', 'Loading atlases: left pial...');
        [sAllAtlas, err] = import_label(BstTessLhFile, AnnotLhFiles, 1);
        errorMsg = [errorMsg err];
    end
    % Load sphere
    if ~isempty(TessLsphFile)
        bst_progress('start', 'Import FreeSurfer folder', 'Loading registered sphere: left pial...');
        [TessMat, err] = tess_addsphere(BstTessLhFile, TessLsphFile);
        errorMsg = [errorMsg err];
    end
    % Downsample
    bst_progress('start', 'Import FreeSurfer folder', 'Downsampling: left pial...');
    [BstTessLhLowFile, iLhLow, xLhLow] = tess_downsize(BstTessLhFile, nVertHemi, 'reducepatch');
end
% Right pial
if ~isempty(TessRhFile)
    % Import file
    [iRh, BstTessRhFile, nVertOrigR] = import_surfaces(iSubject, TessRhFile, 'FS', 0);
    BstTessRhFile = BstTessRhFile{1};
    % Load atlases
    if ~isempty(AnnotRhFiles)
        bst_progress('start', 'Import FreeSurfer folder', 'Loading atlases: right pial...');
        [sAllAtlas, err] = import_label(BstTessRhFile, AnnotRhFiles, 1);
        errorMsg = [errorMsg err];
    end
    % Load sphere
    if ~isempty(TessRsphFile)
        bst_progress('start', 'Import FreeSurfer folder', 'Loading registered sphere: right pial...');
        [TessMat, err] = tess_addsphere(BstTessRhFile, TessRsphFile);
        errorMsg = [errorMsg err];
    end
    % Downsample
    bst_progress('start', 'Import FreeSurfer folder', 'Downsampling: right pial...');
    [BstTessRhLowFile, iRhLow, xRhLow] = tess_downsize(BstTessRhFile, nVertHemi, 'reducepatch');
end
% Left white matter
if ~isempty(TessLwFile)
    % Import file
    [iLw, BstTessLwFile] = import_surfaces(iSubject, TessLwFile, 'FS', 0);
    BstTessLwFile = BstTessLwFile{1};
    % Load atlases
    if ~isempty(AnnotLhFiles)
        bst_progress('start', 'Import FreeSurfer folder', 'Loading atlases: left white...');
        [sAllAtlas, err] = import_label(BstTessLwFile, AnnotLhFiles, 1);
        errorMsg = [errorMsg err];
    end
    if ~isempty(TessLsphFile)
        bst_progress('start', 'Import FreeSurfer folder', 'Loading registered sphere: left pial...');
        [TessMat, err] = tess_addsphere(BstTessLwFile, TessLsphFile);
        errorMsg = [errorMsg err];
    end
    % Downsample
    bst_progress('start', 'Import FreeSurfer folder', 'Downsampling: left white...');
    [BstTessLwLowFile, iLwLow, xLwLow] = tess_downsize(BstTessLwFile, nVertHemi, 'reducepatch');
end
% Right white matter
if ~isempty(TessRwFile)
    % Import file
    [iRw, BstTessRwFile] = import_surfaces(iSubject, TessRwFile, 'FS', 0);
    BstTessRwFile = BstTessRwFile{1};
    % Load atlases
    if ~isempty(AnnotRhFiles)
        bst_progress('start', 'Import FreeSurfer folder', 'Loading atlases: right white...');
        [sAllAtlas, err] = import_label(BstTessRwFile, AnnotRhFiles, 1);
        errorMsg = [errorMsg err];
    end
    % Load sphere
    if ~isempty(TessRsphFile)
        bst_progress('start', 'Import FreeSurfer folder', 'Loading registered sphere: right pial...');
        [TessMat, err] = tess_addsphere(BstTessRwFile, TessRsphFile);
        errorMsg = [errorMsg err];
    end
    % Downsample
    bst_progress('start', 'Import FreeSurfer folder', 'Downsampling: right white...');
    [BstTessRwLowFile, iRwLow, xRwLow] = tess_downsize(BstTessRwFile, nVertHemi, 'reducepatch');
end
% Process error messages
if ~isempty(errorMsg)
    if isInteractive
        bst_error(errorMsg, 'Import FreeSurfer folder', 0);
    end
    return;
end


%% ===== GENERATE MID-SURFACE =====
if ~isempty(TessLhFile) && ~isempty(TessRhFile) && ~isempty(TessLwFile) && ~isempty(TessRwFile)
    bst_progress('start', 'Import FreeSurfer folder', 'Generating mid-surface...');
    % Average pial and white surfaces
    BstTessLmFile = tess_average({BstTessLhFile, BstTessLwFile});
    BstTessRmFile = tess_average({BstTessRhFile, BstTessRwFile});
    % Downsample
    bst_progress('start', 'Import FreeSurfer folder', 'Downsampling: mid-surface...');
    [BstTessLmLowFile, iLmLow, xLmLow] = tess_downsize(BstTessLmFile, nVertHemi, 'reducepatch');
    [BstTessRmLowFile, iRmLow, xRmLow] = tess_downsize(BstTessRmFile, nVertHemi, 'reducepatch');
else
    MidHiFile = [];
end


%% ===== MERGE SURFACES =====
rmFiles = {};
rmInd   = [];
% Merge hemispheres: pial
if ~isempty(TessLhFile) && ~isempty(TessRhFile)
    % Hi-resolution surface
    CortexHiFile  = tess_concatenate({BstTessLhFile,    BstTessRhFile},    sprintf('cortex_%dV', nVertOrigL + nVertOrigR), 'Cortex');
    CortexLowFile = tess_concatenate({BstTessLhLowFile, BstTessRhLowFile}, sprintf('cortex_%dV', length(xLhLow) + length(xRhLow)), 'Cortex');
    % Delete separate hemispheres
    rmFiles = cat(2, rmFiles, {BstTessLhFile, BstTessRhFile, BstTessLhLowFile, BstTessRhLowFile});
    % Rename high-res file
    oldCortexHiFile = file_fullpath(CortexHiFile);
    CortexHiFile    = bst_fullfile(bst_fileparts(oldCortexHiFile), 'tess_cortex_pial_high.mat');
    movefile(oldCortexHiFile, CortexHiFile);
    CortexHiFile = file_short(CortexHiFile);
    % Rename high-res file
    oldCortexLowFile = file_fullpath(CortexLowFile);
    CortexLowFile    = bst_fullfile(bst_fileparts(oldCortexLowFile), 'tess_cortex_pial_low.mat');
    movefile(oldCortexLowFile, CortexLowFile);
    CortexHiFile = file_short(CortexHiFile);
else
    CortexHiFile = [];
    CortexLowFile = [];
end
% Merge hemispheres: white
if ~isempty(TessLwFile) && ~isempty(TessRwFile)
    % Hi-resolution surface
    WhiteHiFile  = tess_concatenate({BstTessLwFile,    BstTessRwFile},    sprintf('white_%dV', nVertOrigL + nVertOrigR), 'Cortex');
    WhiteLowFile = tess_concatenate({BstTessLwLowFile, BstTessRwLowFile}, sprintf('white_%dV', length(xLwLow) + length(xRwLow)), 'Cortex');
    % Delete separate hemispheres
    rmFiles = cat(2, rmFiles, {BstTessLwFile, BstTessRwFile, BstTessLwLowFile, BstTessRwLowFile});
    % Rename high-res file
    oldWhiteHiFile = file_fullpath(WhiteHiFile);
    WhiteHiFile    = bst_fullfile(bst_fileparts(oldWhiteHiFile), 'tess_cortex_white_high.mat');
    movefile(oldWhiteHiFile, WhiteHiFile);
    % Rename high-res file
    oldWhiteLowFile = file_fullpath(WhiteLowFile);
    WhiteLowFile    = bst_fullfile(bst_fileparts(oldWhiteLowFile), 'tess_cortex_white_low.mat');
    movefile(oldWhiteLowFile, WhiteLowFile);
end
% Merge hemispheres: mid-surface
if ~isempty(TessLhFile) && ~isempty(TessRhFile) && ~isempty(TessLwFile) && ~isempty(TessRwFile)
    % Hi-resolution surface
    MidHiFile  = tess_concatenate({BstTessLmFile,    BstTessRmFile},    sprintf('mid_%dV', nVertOrigL + nVertOrigR), 'Cortex');
    MidLowFile = tess_concatenate({BstTessLmLowFile, BstTessRmLowFile}, sprintf('mid_%dV', length(xLmLow) + length(xRmLow)), 'Cortex');
    % Delete separate hemispheres
    rmFiles = cat(2, rmFiles, {BstTessLmFile, BstTessRmFile, BstTessLmLowFile, BstTessRmLowFile});
    % Rename high-res file
    oldMidHiFile = file_fullpath(MidHiFile);
    MidHiFile    = bst_fullfile(bst_fileparts(oldMidHiFile), 'tess_cortex_mid_high.mat');
    movefile(oldMidHiFile, MidHiFile);
    % Rename high-res file
    oldMidLowFile = file_fullpath(MidLowFile);
    MidLowFile    = bst_fullfile(bst_fileparts(oldMidLowFile), 'tess_cortex_mid_low.mat');
    movefile(oldMidLowFile, MidLowFile);
%     % Use by default instead of the cortex surface
%     CortexHiFile  = MidHiFile;
%     CortexLowFile = MidLowFile;
end
% Delete intermediary files
if ~isempty(rmFiles)
    % Delete files
    file_delete(file_fullpath(rmFiles), 1);
    % Reload subject
    db_reload_subjects(iSubject);
    % Refresh tree
    panel_protocols('UpdateNode', 'Subject', iSubject);
    panel_protocols('SelectNode', [], 'subject', iSubject, -1 );
end


%% ===== GENERATE HEAD =====
% Generate head surface
HeadFile = tess_isohead(iSubject, 10000, 0, 2);

%% ===== LOAD ASEG.MGZ =====
if ~isempty(AsegFile)
    % Import atlas
    [iAseg, BstAsegFile] = import_surfaces(iSubject, AsegFile, 'MRI-MASK', 0, OffsetMri);
else
    BstAsegFile = [];
end

%% ===== IMPORT THICKNESS MAPS =====
if isExtraMaps && ~isempty(CortexHiFile) && ~isempty(ThickLhFile) && ~isempty(ThickLhFile)
    % Create a condition "FreeSurfer"
    iStudy = db_add_condition(iSubject, 'FreeSurfer');
    % Import cortical thickness
    ThickFile = import_sources(iStudy, CortexHiFile, ThickLhFile, ThickRhFile, 'FS');
end


%% ===== UPDATE GUI =====
% Set default cortex
% if ~isempty(MidHiFile)
%     [sSubject, iSubject, iSurface] = bst_get('SurfaceFile', MidHiFile);
%     db_surface_default(iSubject, 'Cortex', iSurface);
% end
if ~isempty(TessLhFile) && ~isempty(TessRhFile)
    [sSubject, iSubject, iSurface] = bst_get('SurfaceFile', CortexLowFile);
    db_surface_default(iSubject, 'Cortex', iSurface);
end
% Save database
db_save();
% Unload everything
bst_memory('UnloadAll', 'Forced');
% Give a graphical output for user validation
if isInteractive
    % Display the downsampled cortex + head + ASEG
    hFig = view_surface(HeadFile);
    % Display cortex
    if ~isempty(CortexLowFile)
        view_surface(CortexLowFile);
    end
%     % Display ASEG
%     if ~isempty(BstAsegFile)
%         view_surface(BstAsegFile);
%     end
    % Set orientation
    figure_3d('SetStandardView', hFig, 'left');
end
% Close progress bar
bst_progress('stop');




