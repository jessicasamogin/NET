function [hFig, iDS, iFig] = view_surface_data(SurfaceFile, OverlayFile, Modality, FigureOption)
% VIEW_SURFACE_DATA: Display a surface with overlaid data (recordings, sources, stats...).
%
% USAGE:  [hFig, iDS, iFig] = view_surface_data(SurfaceFile, OverlayFile, Modality, 'NewFigure')
%         [hFig, iDS, iFig] = view_surface_data(SurfaceFile, OverlayFile, Modality)
%         [hFig, iDS, iFig] = view_surface_data(SurfaceFile, OverlayFile)
%         [hFig, iDS, iFig] = view_surface_data(         [], OverlayFile)
%
% INPUT: 
%     - OverlayFile  : Path to the file which contains the values to display over the surface
%     - SurfaceFile  : Path to the tesselation file to display.
%                      If set to [], in case of source files, the surface to be used is detected automatically
%     - Modality     : {'MEG', 'MEG GRAD', 'MEG MAG', 'EEG', 'Other'}
%     - 'NewFigure'  : Force new figure creation (do not re-use a previously created figure)
%
% OUTPUT : 
%     - hFig : Matlab handle to the 3DViz figure that was created or updated
%     - iDS  : DataSet index in the GlobalData variable
%     - iFig : Indice of returned figure in the GlobalData(iDS).Figure array
% If an error occurs : all the returned variables are set to an empty matrix []

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
% Authors: Francois Tadel, 2008-2014


%% ===== PARSE INPUTS =====
global GlobalData;
% FigureOption
NewFigure = (nargin >= 4) && strcmpi(FigureOption, 'NewFigure');
% Modality
if (nargin < 3)
    Modality = [];
end
if (nargin < 2)
    OverlayFile = [];
end


%% ===== GET OVERLAY FILE =====
% Get file in database
[sStudy, iStudy, iFile, DataType, sFileMat] = bst_get('AnyFile', OverlayFile);
% If this data file does not belong to any study
if isempty(sStudy)
    error(['File not found in database: "', OverlayFile, '"']);
end
% Get associated data file
RelatedDataFile = bst_get('RelatedDataFile', OverlayFile);
% Results / stat
isResults  = any(strcmpi(DataType, {'results', 'presults', 'link'}));
isData     = any(strcmpi(DataType, {'data', 'pdata'}));
isStat     = any(strcmpi(DataType, {'pdata', 'presults', 'ptimefreq'}));
isTimefreq = any(strcmpi(DataType, {'timefreq', 'ptimefreq'}));

%% ===== GET SURFACE =====
% If surface was not given in input
if isempty(SurfaceFile)
    % Possible to get surface from results files
    if isResults
        % Get surface from file       
        ResultsMat = in_bst_results(OverlayFile, 0, 'SurfaceFile', 'HeadModelType');
        % Volume/surface
        if ismember(ResultsMat.HeadModelType, {'volume', 'dba'})
            sSubject = bst_get('Subject', sStudy.BrainStormSubject);
            SurfaceFile = sSubject.Anatomy(sSubject.iAnatomy).FileName;
        else
            SurfaceFile = ResultsMat.SurfaceFile;
        end
    elseif isTimefreq
        ResultsFile = sFileMat.DataFile;
        % If a result file is available: use it
        if ~isempty(ResultsFile)
            ResultsMat = in_bst_results(ResultsFile, 0, 'SurfaceFile');
            SurfaceFile = ResultsMat.SurfaceFile;
        % Else, try to read a SurfaceField field from the Timefreq file
        else
            TfMat = in_bst_timefreq(sFileMat.FileName, 0, 'SurfaceFile');
            SurfaceFile = TfMat.SurfaceFile;
        end
        % If nothing found, try to use the current cortex
        if isempty(SurfaceFile)
            disp('BST> WARNING: No source file associated with this TF decomposition. Try using the default cortex...');
            sSubject = bst_get('Subject', sStudy.BrainStormSubject);
            if ~isempty(sSubject.iCortex)
                SurfaceFile = sSubject.Surface(sSubject.iCortex).FileName;
            else
                error('The default cortex is not available, or does not match this file. The cannot be displayed.');
            end
        end
    else
        error('Surface has to be specified for this type of files.');
    end
end
% Get subject
[sSubject, iSubject, iSurf, fileType] = bst_get('AnyFile', SurfaceFile);
% If this surface does not belong to any subject
if isempty(sSubject)
    error(['File not found in database: "', SurfaceFile, '"']);
end
% Get surface type
if strcmpi(fileType, 'subjectimage')
    SurfaceType = 'Anatomy';
else
    SurfaceType = sSubject.Surface(iSurf).SurfaceType;
end


%% ===== LOAD OVERLAY FILE =====
% Display progress bar if not displayed yet
isProgressBar = bst_progress('isVisible');
if ~isProgressBar
    bst_progress('start', 'View data on surface', 'Loading recordings file...');
end
% Load overlay file
iDS = [];
switch (DataType)
    case {'data', 'pdata'}
        iDS = bst_memory('LoadDataFile', OverlayFile, 1);
        if ~isempty(iDS)
            bst_memory('LoadRecordingsMatrix', iDS);
        end
        OverlayType = 'Data';
    case {'results', 'presults', 'link'}
        [iDS, iResult] = bst_memory('LoadResultsFile', OverlayFile);
        if ~isempty(iResult)
            bst_memory('LoadResultsMatrix', iDS, iResult);
            if isempty(GlobalData.DataSet(iDS).Results(iResult).ImageGridAmp) && isempty(GlobalData.DataSet(iDS).Results(iResult).ImagingKernel)
                return;
            end
        end
        OverlayType = 'Source';
    case {'timefreq', 'ptimefreq'}
        % Force loading associated sources if displaying on the MRI
        isLoadResults = strcmpi(SurfaceType, 'Anatomy') || ~isempty(strfind(OverlayFile, '_KERNEL_'));
        % Load timefreq file
        [iDS, iTimefreq, iResult] = bst_memory('LoadTimefreqFile', OverlayFile, 1, isLoadResults);
        OverlayType = 'Timefreq';
end
% If no DataSet is accessible : error
if isempty(iDS)
    error(['Cannot load file: "', OverlayFile, '"']);
end


%% ===== MODALITY =====
if isempty(Modality)
    if isResults && isStat
        Modality = 'stat';
    elseif isempty(GlobalData.DataSet(iDS).Channel)
        Modality = [];
    elseif isData
        % Get default modality
        if isempty(Modality)
            [tmp,tmp,Modality] = bst_get('ChannelModalities', OverlayFile);
        end
    elseif isResults || isTimefreq
        if ~isempty(iResult)
            iChan = GlobalData.DataSet(iDS).Results(iResult).GoodChannel;
            AllModalities = unique({GlobalData.DataSet(iDS).Channel(iChan).Type});
        else
            AllModalities = intersect(unique({GlobalData.DataSet(iDS).Channel.Type}), {'MEG','EEG','MEG MAG','MEG GRAD'});
        end
        % Replace MEG GRAD+MEG MAG with "MEG"
        if all(ismember({'MEG GRAD', 'MEG MAG'}, AllModalities))
            AllModalities{end+1} = 'MEG';
            AllModalities = setdiff(AllModalities, {'MEG GRAD', 'MEG MAG'});
        end
        if ~isempty(AllModalities)
            Modality = AllModalities{1};
        end
    end
end

%% ===== CREATE FIGURE =====
% Try to get an existing figure with the same figures and data
if ~NewFigure
    [hFig, iFig, iOldDataSet, iSurf] = bst_figures('GetFigureWithSurface', SurfaceFile, OverlayFile, '3DViz', Modality);
else
    hFig = [];
end
% Make sure that only one figure was found
isNewFig = 0;
if (length(hFig) > 1)
    hFig  = hFig(1);
    iFig  = iFig(1);
    iDS   = iOldDataSet(1);
    iSurf = iSurf(1);
% Else: Figure was not found
elseif isempty(hFig) 
    % Try to find a non-results 3DViz figure that can host the new results
    if ~NewFigure && (isResults || isTimefreq)
        % Get 3DViz figures for this dataset
        FigureId = db_template('FigureId');
        FigureId.Type = '3DViz';
        [hFigures, iFigures] = bst_figures('GetFigure', iDS, FigureId);
        if ~isempty(hFigures)
            % Keep only the first figure that do not have Results defined
            for i=1:length(hFigures)
                % Get Surfaces existing in this figure
                TessInfo = getappdata(hFigures(i), 'Surface');
                % If the type of display we want to add is not already present in the figure
                % NOTE: IN THIS CASE, THE NEW DATA FILE HAVE TO BE THE SAME
                isNewDisplayType = isempty(TessInfo) || ...
                                   ~any(strcmpi(SurfaceType, {TessInfo.Name})) || ...
                                   ~any(file_compare(OverlayFile, {TessInfo.DataSource.FileName}));
                % Use this figure
                if ~isNewDisplayType || (isempty(getappdata(hFigures(i),'ResultsFile')) && isempty(getappdata(hFigures(i),'Timefreq')))
                    hFig = hFigures(i);
                    iFig = iFigures(i);
                    break
                end
            end
        end
    end
    % Else : create new figure
    if isempty(hFig) || NewFigure
        % === CREATE FIGURE ===
        % Prepare FigureId structure
        FigureId = db_template('FigureId');
        FigureId.Type     = '3DViz';
        FigureId.SubType  = '';
        FigureId.Modality = Modality;
        % Create figure
        [hFig, iFig, isNewFig] = bst_figures('CreateFigure', iDS, FigureId, 'AlwaysCreate');
        if isempty(hFig)
            bst_error('Could not create figure', 'View surface data', 0);
            return;
        end
    end
    % === ADD NEW SURFACE ===
    iSurf = panel_surface('AddSurface', hFig, SurfaceFile);
end


%% ===== CONFIGURE FIGURE =====
setappdata(hFig, 'StudyFile',    sStudy.FileName);
setappdata(hFig, 'DataFile',     RelatedDataFile);
setappdata(hFig, 'SubjectFile',  sStudy.BrainStormSubject);


%% ===== OVERLAY DATA ON SURFACE =====
% Set data source for this surface
isOk = panel_surface('SetSurfaceData', hFig, iSurf, OverlayType, OverlayFile, isStat);
if ~isOk
    error(['Could not display file "' OverlayFile '" on surface "' SurfaceFile '"']);
end

%% ===== UPDATE FIGURE =====
% Update figure selection
bst_figures('SetCurrentFigure', hFig, '3D');
if isappdata(hFig, 'Timefreq') && ~isempty(getappdata(hFig, 'Timefreq'))
    bst_figures('SetCurrentFigure', hFig, 'TF');
end
% Update figure name
bst_figures('UpdateFigureName', hFig);
% Set surface display to default mode
if strcmpi(SurfaceType, 'Cortex')
    panel_surface('ApplyDefaultDisplay');
end
% Camera basic orientation
if isNewFig
    figure_3d('SetStandardView', hFig, 'top');
end


%% ===== DISPLAY SCOUTS =====
% If there are some loaded scouts available for this figure
if isResults || isTimefreq
    if (iSurf > 1)
        panel_scout('ReloadScouts', hFig);
    else
        panel_scout('SetDefaultOptions');
        panel_scout('PlotScouts', [], hFig);
        panel_scout('UpdateScoutsDisplay', hFig);
    end
end
% Set figure visible
set(hFig, 'Visible', 'on');
if ~isProgressBar
    bst_progress('stop');
end
% Select surface tab
if isNewFig && ~isStat
    gui_brainstorm('SetSelectedTab', 'Surface');
end


end









