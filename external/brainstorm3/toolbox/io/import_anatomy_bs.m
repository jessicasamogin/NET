function errorMsg = import_anatomy_bs(iSubject, BsDir, nVertices, isInteractive, sFid)
% IMPORT_ANATOMY_BS: Import a full BrainSuite folder as the subject's anatomy.
%
% USAGE:  errorMsg = import_anatomy_bs(iSubject, BsDir=[], nVertices=15000)
%
% INPUT:
%    - iSubject  : Indice of the subject where to import the MRI
%                  If iSubject=0 : import MRI in default subject
%    - BsDir     : Full filename of the BrainSuite folder to import
%    - nVertices : Number of vertices in the file cortex surface
%    - isInteractive: If 0, no input or user interaction
%    - sFid      : Structure with the fiducials coordinates
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
% Author   : Francois Tadel, 2012-2013
% Modified : Andrew Krause, 2013

%% ===== PARSE INPUTS =====
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
% Initialize returned variables
errorMsg = [];
% Ask folder to the user
if (nargin < 2) || isempty(BsDir)
    % Get default import directory and formats
    LastUsedDirs = bst_get('LastUsedDirs');
    % Open file selection dialog
    BsDir = java_getfile( 'open', ...
        'Import BrainSuite folder...', ...     % Window title
        bst_fileparts(LastUsedDirs.ImportAnat, 1), ...           % Last used directory
        'single', 'dirs', ...                  % Selection mode
        {{'.folder'}, 'BrainSuite folder', 'BsDir'}, 0);
    % If no folder was selected: exit
    if isempty(BsDir)
        return
    end
    % Save default import directory
    LastUsedDirs.ImportAnat = BsDir;
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
            'Are you sure you want to delete the previous MRI and surfaces ?' 10 10], 'Import BrainSuite folder');
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
    nVertices = java_dialog('input', 'Number of vertices on the cortex surface:', 'Import BrainSuite folder', [], '15000');
    if isempty(nVertices)
        return
    end
    nVertices = str2double(nVertices);
end
% Number for each hemisphere
nVertHemi = round(nVertices / 2);


%% ===== PARSE BRAINSUITE FOLDER =====
% Find MRI
FilePrefix = get_fileprefix(BsDir);
if isempty(FilePrefix)
    errorMsg = [errorMsg 'Could not determine file prefix from BFC file' 10];
end
MriFile = {file_find(BsDir, [FilePrefix '.nii.gz']), ...
           file_find(BsDir, [FilePrefix '.nii']), ...
           file_find(BsDir, [FilePrefix '.img.gz']),...
           file_find(BsDir, [FilePrefix '.img'])};
MriFile = [MriFile{find(~cellfun(@isempty, MriFile))}];
if isempty(MriFile)
    errorMsg = [errorMsg 'MRI file was not found: ' FilePrefix '.*' 10];
end
% Find surfaces
HeadFile       = file_find(BsDir, [FilePrefix '.scalp.dfs']);
InnerSkullFile = file_find(BsDir, [FilePrefix '.inner_skull.dfs']);
OuterSkullFile = file_find(BsDir, [FilePrefix '.outer_skull.dfs']);
TessLhFile     = file_find(BsDir, [FilePrefix '.left.pial.cortex.svreg.dfs']);
TessRhFile     = file_find(BsDir, [FilePrefix '.right.pial.cortex.svreg.dfs']);
TessLwFile     = file_find(BsDir, [FilePrefix '.left.inner.cortex.svreg.dfs']);
TessRwFile     = file_find(BsDir, [FilePrefix '.right.inner.cortex.svreg.dfs']);
if isempty(HeadFile)
    errorMsg = [errorMsg 'Scalp file was not found: ' FilePrefix '.left.pial.cortex.dfs' 10];
end
if isempty(InnerSkullFile) && isempty(OuterSkullFile)
    errorMsg = [errorMsg 'Inner or Outer Skull File not found' 10];
end
if isempty(TessLhFile) 
    errorMsg = [errorMsg 'Surface file was not found: ' FilePrefix '.left.pial.cortex.dfs' 10];
end
if isempty(TessRhFile)
    errorMsg = [errorMsg 'Surface file was not found: ' FilePrefix '.right.pial.cortex.dfs' 10];
end
% Find label description file
XMLFile = file_find(BsDir, 'brainsuite_labeldescription.xml');
if isempty(XMLFile)
    errorMsg = [errorMsg 'Label description file was not found: brainsuite_labeldescription.xml' 10];
end

% Report errors
if ~isempty(errorMsg)
    if isInteractive
        bst_error(['Could not import BrainSuite folder: ' 10 10 errorMsg], 'Import BrainSuite folder', 0);        
    end
    return;
end


%% ===== IMPORT MRI =====
% Read MRI
[BstMriFile, sMri] = import_mri(iSubject, MriFile);
if isempty(BstMriFile)
    errorMsg = 'Could not import BrainSuite folder: MRI was not imported properly';
    if isInteractive
        bst_error(errorMsg, 'Import BrainSuite folder', 0);
    end
    return;
end
% Size of the volume
cubeSize = (size(sMri.Cube) - 1) .* sMri.Voxsize;


%% ===== DEFINE FIDUCIALS =====
% Random points
if ~isInteractive
    % Set some random fiducial points
    if isempty(sFid)
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
    errMsg = ['Could not import BrainSuite folder: ' 10 10 'Some fiducial points were not defined properly in the MRI.'];
    if isInteractive
        bst_error(errMsg, 'Import BrainSuite folder', 0);
    end
    return;
end


%% ===== IMPORT SURFACES =====
% Left pial
if ~isempty(TessLhFile)
    % Import file
    [iLh, BstTessLhFile, nVertOrigL] = import_surfaces(iSubject, TessLhFile, 'DFS', 0);
    BstTessLhFile = BstTessLhFile{1};
    % Load atlas
    if ~isempty(TessLhFile)
        bst_progress('start', 'Import BrainSuite folder', 'Loading atlas: left pial...');
        [sAllAtlas, err] = import_label(BstTessLhFile, TessLhFile, 1);
        errorMsg = [errorMsg err];
    end
    % Downsample
    bst_progress('start', 'Import BrainSuite folder', 'Downsampling: left pial...');
    [BstTessLhLowFile, iLhLow] = tess_downsize(BstTessLhFile, nVertHemi, 'reducepatch');
end
% Right pial
if ~isempty(TessRhFile)
    % Import file
    [iRh, BstTessRhFile, nVertOrigR] = import_surfaces(iSubject, TessRhFile, 'DFS', 0);
    BstTessRhFile = BstTessRhFile{1};
    % Load atlas
    if ~isempty(TessRhFile)
        bst_progress('start', 'Import BrainSuite folder', 'Loading atlas: right pial...');
        [sAllAtlas, err] = import_label(BstTessRhFile, TessRhFile, 1);
        errorMsg = [errorMsg err];
    end
    % Downsample
    bst_progress('start', 'Import BrainSuite folder', 'Downsampling: right pial...');
    [BstTessRhLowFile, iRhLow] = tess_downsize(BstTessRhFile, nVertHemi, 'reducepatch');
end
% Left white matter
if ~isempty(TessLwFile)
    % Import file
    [iLw, BstTessLwFile] = import_surfaces(iSubject, TessLwFile, 'DFS', 0);
    BstTessLwFile = BstTessLwFile{1};
    % Load atlas
    if ~isempty(TessLwFile)
        bst_progress('start', 'Import BrainSuite folder', 'Loading atlas: left inner...');
        [sAllAtlas, err] = import_label(BstTessLwFile, TessLwFile, 1);
        errorMsg = [errorMsg err];
    end
    % Downsample
    bst_progress('start', 'Import BrainSuite folder', 'Downsampling: left white...');
    [BstTessLwLowFile, iLwLow] = tess_downsize(BstTessLwFile, nVertHemi, 'reducepatch');
end
% Right white matter
if ~isempty(TessRwFile)
    % Import file
    [iRw, BstTessRwFile] = import_surfaces(iSubject, TessRwFile, 'DFS', 0);
    BstTessRwFile = BstTessRwFile{1};
     % Load atlas
    if ~isempty(TessRwFile)
        bst_progress('start', 'Import BrainSuite folder', 'Loading atlas: right inner...');
        [sAllAtlas, err] = import_label(BstTessRwFile, TessRwFile, 1);
        errorMsg = [errorMsg err];
    end
    % Downsample
    bst_progress('start', 'Import BrainSuite folder', 'Downsampling: right white...');
    [BstTessRwLowFile, iRwLow] = tess_downsize(BstTessRwFile, nVertHemi, 'reducepatch');
end
% Process error messages
if ~isempty(errorMsg)
    if isInteractive
        bst_error(errorMsg, 'Import BrainSuite folder', 0);
    end
    return;
end

%% ===== MERGE SURFACES =====
rmFiles = {};
rmInd   = [];
% Merge hemispheres: pial
if ~isempty(TessLhFile) && ~isempty(TessRhFile)
    % Hi-resolution surface
    CortexHiFile  = tess_concatenate({BstTessLhFile,    BstTessRhFile},    sprintf('cortex_%dV', nVertOrigL + nVertOrigR), 'Cortex');
    CortexLowFile = tess_concatenate({BstTessLhLowFile, BstTessRhLowFile}, sprintf('cortex_%dV', nVertices), 'Cortex');
    % Delete separate hemispheres
    rmFiles = cat(2, rmFiles, {BstTessLhFile, BstTessRhFile, BstTessLhLowFile, BstTessRhLowFile});
    rmInd   = [rmInd, iLh, iRh, iLhLow, iRhLow];
end
% Merge hemispheres: white
if ~isempty(TessLwFile) && ~isempty(TessRwFile)
    % Hi-resolution surface
    WhiteHiFile  = tess_concatenate({BstTessLwFile,    BstTessRwFile},    sprintf('white_%dV', nVertOrigL + nVertOrigR), 'Cortex');
    WhiteLowFile = tess_concatenate({BstTessLwLowFile, BstTessRwLowFile}, sprintf('white_%dV', nVertices), 'Cortex');
    % Delete separate hemispheres
    rmFiles = cat(2, rmFiles, {BstTessLwFile, BstTessRwFile, BstTessLwLowFile, BstTessRwLowFile});
    rmInd   = [rmInd, iLw, iRw, iLwLow, iRwLow];
end

%% ===== HEAD AND SKULL SURFACES =====
bst_progress('start', 'Import BrainSuite folder', 'Importing scalp and skull surfaces...');
% Head
if ~isempty(HeadFile)
    % Import file
    bst_progress('start', 'Import BrainSuite folder', 'Imported scalp surface...');
    [iHead, BstHeadHiFile] = import_surfaces(iSubject, HeadFile, 'DFS', 0);
    BstHeadHiFile = BstHeadHiFile{1};
    % Downsample
    bst_progress('start', 'Import BrainSuite folder', 'Downsampling: scalp...');
    BstHeadFile = tess_downsize( BstHeadHiFile, 1082, 'reducepatch' );
    % Load MRI
    bst_progress('start', 'Import BrainSuite folder', 'Filling holes in the head surface...');
    sMri = bst_memory('LoadMri', BstMriFile);
    % Load head surface
    sHead = in_tess_bst(BstHeadFile);
    % Remove holes
    [sHead.Vertices, sHead.Faces] = tess_fillholes(sMri, sHead.Vertices, sHead.Faces, 2);
    % Save back to file
    sHeadNew.Vertices = sHead.Vertices;
    sHeadNew.Faces = sHead.Faces;
    sHeadNew.Comment = sHead.Comment;
    bst_save(file_fullpath(BstHeadFile), sHeadNew, 'v7');
    % Delete initial file
    rmFiles = cat(2, rmFiles, BstHeadHiFile);
    rmInd   = [rmInd, iHead];
% Or generate one from Brainstorm
else
    % Generate head surface
    BstHeadFile = tess_isohead(iSubject, 10000, 0, 2);
end

% Inner Skull
if ~isempty(InnerSkullFile)
    % Import file
    [iIs, BstInnerSkullHiFile] = import_surfaces(iSubject, InnerSkullFile, 'DFS', 0);
    BstInnerSkullHiFile = BstInnerSkullHiFile{1};
    % Downsample
    bst_progress('start', 'Import BrainSuite folder', 'Downsampling: inner skull...');
    BstInnerSkullFile = tess_downsize(BstInnerSkullHiFile, 1000, 'reducepatch');
    % Delete initial file
    rmFiles = cat(2, rmFiles, BstInnerSkullHiFile);
    rmInd   = [rmInd, iIs];
end
if ~isempty(OuterSkullFile)
    % Import file
    [iOs, BstOuterSkullHiFile] = import_surfaces(iSubject, OuterSkullFile, 'DFS', 0);
    BstOuterSkullHiFile = BstOuterSkullHiFile{1};
    % Downsample
    bst_progress('start', 'Import BrainSuite folder', 'Downsampling: outer skull...');
    BstOuterSkullFile = tess_downsize(BstOuterSkullHiFile, 1000, 'reducepatch');
    % Delete initial file
    rmFiles = cat(2, rmFiles, BstOuterSkullHiFile);
    rmInd   = [rmInd, iOs];
end


% Delete intermediary files
if ~isempty(rmFiles)
    % Delete files
    file_delete(file_fullpath(rmFiles), 1);
    % Update subject definition
    sSubject = bst_get('Subject', iSubject);
    sSubject.Surface(rmInd) = [];
    bst_set('Subject', iSubject, sSubject);
    % Refresh tree
    panel_protocols('UpdateNode', 'Subject', iSubject);
    panel_protocols('SelectNode', [], 'subject', iSubject, -1 );
end


%% ===== UPDATE GUI =====
% Set default cortex
if ~isempty(TessLhFile) && ~isempty(TessRhFile)
    [sSubject, iSubject, iSurface] = bst_get('SurfaceFile', CortexLowFile);
    db_surface_default(iSubject, 'Cortex', iSurface);
end
% Set default scalp
db_surface_default(iSubject, 'Scalp');
% Set default skulls
db_surface_default(iSubject, 'OuterSkull');
db_surface_default(iSubject, 'InnerSkull');
% Save database
db_save();
% Unload everything
bst_memory('UnloadAll', 'Forced');
% Give a graphical output for user validation
if isInteractive
    % Display the downsampled cortex and the head
    hFig = view_surface(BstHeadFile);
    view_surface(CortexLowFile);
    % Set orientation
    figure_3d('SetStandardView', hFig, 'left');
end
% Close progress bar
bst_progress('stop');

end



%% ======================================================================================
%  ===== HELPER FUNCTIONS ===============================================================
%  ======================================================================================
%% ===== GET PREFIX OF FILENAMES =====
function FilePrefix = get_fileprefix(BsDir)
    % Default Return Value
    FilePrefix = [];
    % Determine file prefix based on BFC file
    BfcFile = file_find(BsDir, '*.bfc.nii.gz');
    if ~isempty(BfcFile)
        FilePrefix = BfcFile(1:end-11);
    end
    [tmp, FilePrefix] = fileparts(FilePrefix);
    return
end
