function [hFig, iDS, iFig] = view_spectrum(TimefreqFile, DisplayMode, RowName, isNewFigure)
% VIEW_SPECTRUM: Display power spectrum density in a new figure.
%
% USAGE: [hFig, iDS, iFig] = view_spectrum(TimefreqFile, DisplayMode, RowName, isNewFigure)
%        [hFig, iDS, iFig] = view_spectrum(TimefreqFile, DisplayMode, RowName)
%        [hFig, iDS, iFig] = view_spectrum(TimefreqFile, DisplayMode)
%        [hFig, iDS, iFig] = view_spectrum(TimefreqFile)
%
% INPUT: 
%     - TimefreqFile : Path to time-frequency file to visualize
%     - DisplayMode  : {'Spectrum', 'TimeSeries'}
%     - RowName      : Name of the row to display from the input timefreq file
%                      If empty, displays everything
%     - isNewFigure  : If 1, force the creation of a new figure
%
% OUTPUT : 
%     - hFig : Matlab handle to the figure that was created or updated
%     - iDS  : DataSet index in the GlobalData variable
%     - iFig : Indice of returned figure in the GlobalData(iDS).Figure array

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
% Authors: Francois Tadel, 2012


%% ===== INITIALIZATION =====
% GlobalData : create if not existing yet
global GlobalData;
% Parse inputs
if (nargin < 2)
    DisplayMode = 'Spectrum';
end
if (nargin < 3) || isempty(RowName)
    RowName = [];
elseif ischar(RowName)
    RowName = {RowName};
end
if (nargin < 4) || isempty(isNewFigure) || (isNewFigure == 0)
    CreateMode = '';
else
    CreateMode = 'AlwaysCreate';
end
   

%% ===== GET ALL ACCESSIBLE DATA =====
% Get study
[sStudy, iStudy, iItem, DataType, sTimefreq] = bst_get('AnyFile', TimefreqFile);
if isempty(sStudy)
    error('File is not registered in database.');
end

%% ===== LOAD TIME-FREQUENCY FILE =====
bst_progress('start', 'View time-frequency map', 'Loading data...');
% Load file
[iDS, iTimefreq] = bst_memory('LoadTimefreqFile', TimefreqFile);
if isempty(iDS)
    % error('Cannot load timefreq file.');
    hFig = [];
    iFig = [];
    return
end
% Detect modality
Modality = GlobalData.DataSet(iDS).Timefreq(iTimefreq).Modality;


%% ===== CREATE A NEW FIGURE =====
% Prepare FigureId structure
FigureId.Type     = 'Spectrum';
FigureId.SubType  = DisplayMode;
FigureId.Modality = Modality;
% Create TimeSeries figure
[hFig, iFig] = bst_figures('CreateFigure', iDS, FigureId, CreateMode, sTimefreq.FileName);
if isempty(hFig)
    bst_error('Cannot create figure', 'View spectrum', 0);
    return;
end

%% ===== INITIALIZE FIGURE =====
% Configure app data
setappdata(hFig, 'DataFile',     GlobalData.DataSet(iDS).DataFile);
setappdata(hFig, 'StudyFile',    GlobalData.DataSet(iDS).StudyFile);
setappdata(hFig, 'SubjectFile',  GlobalData.DataSet(iDS).SubjectFile);
% Static dataset
setappdata(hFig, 'isStatic', (GlobalData.DataSet(iDS).Timefreq(iTimefreq).NumberOfSamples <= 2));
isStaticFreq = (size(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TF,3) <= 1);
setappdata(hFig, 'isStaticFreq', isStaticFreq);
% Get figure data
TfInfo = getappdata(hFig, 'Timefreq');
% Create time-freq information structure
TfInfo.FileName    = sTimefreq.FileName;
TfInfo.Comment     = sTimefreq.Comment;
TfInfo.DisplayMode = DisplayMode;
TfInfo.InputTarget = RowName;
TfInfo.RowName     = RowName;
% Get function to apply
TfMethod = lower(GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method);
if ismember(TfMethod, {'fft', 'psd'})
    TfInfo.Function = 'log';
else
    TfInfo.Function = process_tf_measure('GetDefaultFunction', GlobalData.DataSet(iDS).Timefreq(iTimefreq).Method);
end
% Frequency selection: depends on the display type
if isStaticFreq || strcmpi(DisplayMode, 'Spectrum')
    TfInfo.iFreqs = [];
elseif strcmpi(DisplayMode, 'TimeSeries')
    TfInfo.iFreqs = GlobalData.UserFrequencies.iCurrentFreq;
end
% Set figure data
setappdata(hFig, 'Timefreq', TfInfo);
% Display options panel
isDisplayTab = ~strcmpi(TfInfo.Function, 'other') || ~isempty(TfInfo.RowName);
if isDisplayTab
    gui_brainstorm('ShowToolTab', 'Display');
end

% Save time series display mode
TsInfo = db_template('TsInfo');
if strcmpi(DisplayMode, 'Spectrum')
    TsInfo.DisplayMode = 'butterfly';
else
    TsInfo.DisplayMode = bst_get('TSDisplayMode');
end
setappdata(hFig, 'TsInfo', TsInfo);


%% ===== PLOT TIME SERIES =====
figure_spectrum('UpdateFigurePlot', hFig);


%% ===== UPDATE ENVIRONMENT =====
% Update figure selection
bst_figures('SetCurrentFigure', hFig, 'TF');
% Select display options
if isDisplayTab
    panel_display('UpdatePanel', hFig);
end
% Set figure visible
set(hFig, 'Visible', 'on');
% Set the time label visible
figure_timeseries('SetTimeVisible', hFig, 1);
bst_progress('stop');








