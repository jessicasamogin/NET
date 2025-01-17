function hFig = channel_align_manual( ChannelFile, Modality, isEdit )
% CHANNEL_ALIGN_MANUAL: Align manually an electrodes net on the scalp surface of the subject.
% 
% USAGE:  hFig = channel_align_manual( ChannelFile, Modality, isEdit )
%
% INPUT:
%     - ChannelFile : full path to channel file
%     - Modality    : modality to display and to align
%     - isEdit      : Boolean - If one, add controls to edit the positions

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
% Authors: Francois Tadel, 2008-2013

global GlobalData;

% ===== GET CHANNEL =====
% Is processing MEG?
isMeg = ismember(Modality, {'MEG', 'MEG GRAD', 'MEG MAG', 'Vectorview306', 'CTF', '4D', 'KIT'});
% Get study
sStudy = bst_get('ChannelFile', ChannelFile);
% Get subject
sSubject = bst_get('Subject', sStudy.BrainStormSubject);
% Get scalp surface
if isempty(sSubject.iScalp) || (sSubject.iScalp > length(sSubject.Surface))
    disp('BST> Warning: Cannot check the alignment sensors-MRI because no scalp surface is available.');
    return;
end
SurfaceFile = sSubject.Surface(sSubject.iScalp).FileName;
ChannelFileFull = file_fullpath(ChannelFile);
% Progress bar
isProgress = ~bst_progress('isVisible');
if isProgress
    bst_progress('start', 'Importing sensors', 'Loading sensors description...');
end

% ===== VIEW SURFACE =====
% If editing the channel file: Close all the windows before
if isEdit
    bst_memory('UnloadAll', 'Forced');
end
% View scalp surface
hFig = view_surface(SurfaceFile, .2, [], 'NewFigure');
% Set figure title
set(hFig, 'Name', 'Registration scalp/sensors');
% View XYZ axis
figure_3d('ViewAxis', hFig, 1);
% Set view from left side
figure_3d('SetStandardView', hFig, 'left');

% ===== SHOW SENSORS =====
% EEG Electrodes
if ~isMeg
    % View channels
    view_channels(ChannelFile, Modality, 1, 1, hFig);
    % Hide channels labels
    hSensorsLabels = findobj(hFig, 'Tag', 'SensorsLabels');
    SensorsLabels = get(hSensorsLabels, 'String');
    set(hSensorsLabels, 'Visible', 'off');
% MEG Helmet
else
    view_helmet(ChannelFile, hFig);
    hSensorsLabels = [];
    SensorsLabels = {};
end

% Get sensors patch
hSensorsPatch = findobj(hFig, 'Tag', 'SensorsPatch');
if isempty(hSensorsPatch) || ~ishandle(hSensorsPatch(1))
    bst_error('Cannot display sensors patch', 'Align electrodes', 0);
    return
end
% Get sensors locations from patch
SensorsVertices = get(hSensorsPatch, 'Vertices');
% Get helmet patch
hHelmetPatch = findobj(hFig, 'Tag', 'HelmetPatch');
if isempty(hHelmetPatch)
    HelmetVertices = [];
else
    HelmetVertices = get(hHelmetPatch, 'Vertices');
end

% ===== DISPLAY HEAD POINTS =====
% Display head points
figure_3d('ViewHeadPoints', hFig, 1);
% Get patch and vertices
hHeadPointsMarkers = findobj(hFig, 'Tag', 'HeadPointsMarkers');
hHeadPointsLabels  = findobj(hFig, 'Tag', 'HeadPointsLabels');
hHeadPointsFid     = findobj(hFig, 'Tag', 'HeadPointsFid');
hHeadPointsHpi     = findobj(hFig, 'Tag', 'HeadPointsHpi');
isHeadPoints = ~isempty(hHeadPointsMarkers);
HeadPointsLabelsLoc  = [];
HeadPointsMarkersLoc = [];
HeadPointsFidLoc     = [];
HeadPointsHpiLoc     = [];
if isHeadPoints
    % Get markers positions
    HeadPointsMarkersLoc = [get(hHeadPointsMarkers, 'XData')', ...
                            get(hHeadPointsMarkers, 'YData')', ...
                            get(hHeadPointsMarkers, 'ZData')'];
    % Get labels positions
    tmpLoc = get(hHeadPointsLabels,'Position');
    if ~isempty(tmpLoc)
        HeadPointsLabelsLoc = cat(1, tmpLoc{:});
    end
    % Get fiducials positions
    HeadPointsFidLoc = [get(hHeadPointsFid, 'XData')', ...
                        get(hHeadPointsFid, 'YData')', ...
                        get(hHeadPointsFid, 'ZData')'];
    % Get fiducials positions
    HeadPointsHpiLoc = [get(hHeadPointsHpi, 'XData')', ...
                        get(hHeadPointsHpi, 'YData')', ...
                        get(hHeadPointsHpi, 'ZData')'];
end
    
% ===== DISPLAY MRI FIDUCIALS =====
% Get the fiducials positions defined in the MRI volume
sMri = load(file_fullpath(sSubject.Anatomy(sSubject.iAnatomy).FileName), 'SCS');
if ~isempty(sMri.SCS.NAS) && ~isempty(sMri.SCS.LPA) && ~isempty(sMri.SCS.RPA)
    % Convert coordinates MRI => SCS
    MriFidLoc = [...
        cs_mri2scs(sMri, sMri.SCS.NAS')'; ...
        cs_mri2scs(sMri, sMri.SCS.LPA')'; ...
        cs_mri2scs(sMri, sMri.SCS.RPA')'] ./ 1000;
    % Display fiducials
    line(MriFidLoc(:,1), MriFidLoc(:,2), MriFidLoc(:,3), ...
        'Parent',          findobj(hFig, 'Tag', 'Axes3D'), ...
        'LineWidth',       2, ...
        'LineStyle',       'none', ...
        'MarkerFaceColor', [.3 .3 1], ...
        'MarkerEdgeColor', [.4 .4 1], ...
        'MarkerSize',      7, ...
        'Marker',          'o', ...
        'Tag',             'MriPointsFid');
end

% ===== CONFIGURE HEAD SURFACE =====
% Get scalp patch
TessInfo = getappdata(hFig, 'Surface');
hScalpPatch = TessInfo(1).hPatch;
% If no edition of channel file: exit now
if ~isEdit
    % Close progress bar
    if isProgress
        bst_progress('stop');
    end
    return
end

% ===== EDIT ONLY: GLOBAL DATA =====
global gChanAlign;
gChanAlign = [];
gChanAlign.ChannelFile     = ChannelFileFull;
gChanAlign.isMeg           = isMeg;
gChanAlign.FinalTransf     = eye(4);
gChanAlign.hFig            = hFig;
gChanAlign.hScalpPatch     = hScalpPatch;
gChanAlign.hSensorsLabels  = hSensorsLabels;
gChanAlign.SensorsLabels   = SensorsLabels;
gChanAlign.hSensorsPatch   = hSensorsPatch;
gChanAlign.SensorsVertices = SensorsVertices;
gChanAlign.hHelmetPatch    = hHelmetPatch;
gChanAlign.HelmetVertices  = HelmetVertices;
gChanAlign.isHeadPoints         = isHeadPoints;
gChanAlign.hHeadPointsMarkers   = hHeadPointsMarkers;
gChanAlign.hHeadPointsLabels    = hHeadPointsLabels;
gChanAlign.hHeadPointsFid       = hHeadPointsFid;
gChanAlign.hHeadPointsHpi       = hHeadPointsHpi;
gChanAlign.HeadPointsMarkersLoc = HeadPointsMarkersLoc;
gChanAlign.HeadPointsLabelsLoc  = HeadPointsLabelsLoc;
gChanAlign.HeadPointsFidLoc     = HeadPointsFidLoc;
gChanAlign.HeadPointsHpiLoc     = HeadPointsHpiLoc;

% ===== CONFIGURE FIGURE =====
% Get figure description in GlobalData structure
[gChanAlign.hFig, gChanAlign.iFig, gChanAlign.iDS] = bst_figures('GetFigure', gChanAlign.hFig);
if isempty(gChanAlign.iDS)
    return
end
% Compute a vector to convert: global indices (channel file) -> local indices (vertices)
Channel = GlobalData.DataSet(gChanAlign.iDS).Channel;
iChan = good_channel(Channel, [], Modality);
gChanAlign.iGlobal2Local = zeros(1, length(Channel));
gChanAlign.iGlobal2Local(iChan) = 1:length(gChanAlign.SensorsVertices);

% ===== HACK NORMAL 3D CALLBACKS =====
% Save figure callback functions
gChanAlign.Figure3DButtonDown_Bak   = get(gChanAlign.hFig, 'WindowButtonDownFcn');
gChanAlign.Figure3DButtonMotion_Bak = get(gChanAlign.hFig, 'WindowButtonMotionFcn');
gChanAlign.Figure3DButtonUp_Bak     = get(gChanAlign.hFig, 'WindowButtonUpFcn');
gChanAlign.Figure3DCloseRequest_Bak = get(gChanAlign.hFig, 'CloseRequestFcn');
% Set new callbacks
set(gChanAlign.hFig, 'WindowButtonDownFcn',   @AlignButtonDown_Callback);
set(gChanAlign.hFig, 'WindowButtonMotionFcn', @AlignButtonMotion_Callback);
set(gChanAlign.hFig, 'WindowButtonUpFcn',     @AlignButtonUp_Callback);
set(gChanAlign.hFig, 'CloseRequestFcn',       @AlignClose_Callback);

% ===== CUSTOMIZE FIGURE =====
% Add toolbar to window
hToolbar = uitoolbar(gChanAlign.hFig, 'Tag', 'AlignToolbar');

% Initializations
gChanAlign.selectedButton = '';
gChanAlign.isChanged = 0;
gChanAlign.mouseClicked = 0;
gChanAlign.isFirstAddWarning = 1;
gChanAlign.isFirstRmWarning = 1;

% Rotation/Translation buttons
if ~gChanAlign.isMeg
    gChanAlign.hButtonLabels    = uitoggletool(hToolbar, 'CData', java_geticon('ICON_LABELS'), 'TooltipString', 'Show/Hide electrodes labels', 'ClickedCallback', @ToggleLabels);
    gChanAlign.hButtonEditLabel = uipushtool(  hToolbar, 'CData', java_geticon('ICON_EDIT'),   'TooltipString', 'Edit selected channel label', 'ClickedCallback', @EditLabel);
else
    gChanAlign.hButtonHelmet = uitoggletool(hToolbar, 'CData', java_geticon('ICON_DISPLAY'), 'TooltipString', 'Show/Hide MEG helmet', 'ClickedCallback', @ToggleHelmet, 'State', 'on');
end
gChanAlign.hButtonTransX   = uitoggletool(hToolbar, 'CData', java_geticon('ICON_TRANSLATION_X'), 'TooltipString', 'Translation/X: Press right button and move mouse up/down', 'ClickedCallback', @SelectOperation, 'separator', 'on');
gChanAlign.hButtonTransY   = uitoggletool(hToolbar, 'CData', java_geticon('ICON_TRANSLATION_Y'), 'TooltipString', 'Translation/Y: Press right button and move mouse up/down', 'ClickedCallback', @SelectOperation);
gChanAlign.hButtonTransZ   = uitoggletool(hToolbar, 'CData', java_geticon('ICON_TRANSLATION_Z'), 'TooltipString', 'Translation/Z: Press right button and move mouse up/down', 'ClickedCallback', @SelectOperation);
gChanAlign.hButtonRotX     = uitoggletool(hToolbar, 'CData', java_geticon('ICON_ROTATION_X'),    'TooltipString', 'Rotation/X: Press right button and move mouse up/down',    'ClickedCallback', @SelectOperation, 'separator', 'on');
gChanAlign.hButtonRotY     = uitoggletool(hToolbar, 'CData', java_geticon('ICON_ROTATION_Y'),    'TooltipString', 'Rotation/Y: Press right button and move mouse up/down',    'ClickedCallback', @SelectOperation);
gChanAlign.hButtonRotZ     = uitoggletool(hToolbar, 'CData', java_geticon('ICON_ROTATION_Z'),    'TooltipString', 'Rotation/Z: Press right button and move mouse up/down',    'ClickedCallback', @SelectOperation);
if ~gChanAlign.isMeg
    gChanAlign.hButtonResizeX  = uitoggletool(hToolbar, 'CData', java_geticon('ICON_RESIZE_X'),      'TooltipString', 'Resize/X: Press right button and move mouse up/down',      'ClickedCallback', @SelectOperation, 'separator', 'on');
    gChanAlign.hButtonResizeY  = uitoggletool(hToolbar, 'CData', java_geticon('ICON_RESIZE_Y'),      'TooltipString', 'Resize/Y: Press right button and move mouse up/down',      'ClickedCallback', @SelectOperation);
    gChanAlign.hButtonResizeZ  = uitoggletool(hToolbar, 'CData', java_geticon('ICON_RESIZE_Z'),      'TooltipString', 'Resize/Z: Press right button and move mouse up/down',      'ClickedCallback', @SelectOperation);
    gChanAlign.hButtonResize   = uitoggletool(hToolbar, 'CData', java_geticon('ICON_RESIZE'),        'TooltipString', 'Resize: Press right button and move mouse up/down',        'ClickedCallback', @SelectOperation);
    gChanAlign.hButtonMoveChan = uitoggletool(hToolbar, 'CData', java_geticon('ICON_MOVE_CHANNEL'),  'TooltipString', 'Move an electrode: Select electrode, then press right button and move mouse', 'ClickedCallback', @SelectOperation, 'separator', 'on');
    gChanAlign.hButtonProject  = uipushtool(  hToolbar, 'CData', java_geticon('ICON_PROJECT_ELECTRODES'), 'TooltipString', 'Project electrodes on scalp surface', 'ClickedCallback', @ProjectElectrodesOnScalp);
    gChanAlign.hButtonRefine   = uipushtool(  hToolbar, 'CData', java_geticon('ICON_ALIGN_CHANNELS'), 'TooltipString', 'Refine registration using head points', 'ClickedCallback', @RefineWithHeadPoints);
else
    gChanAlign.hButtonRefine   = uipushtool(  hToolbar, 'CData', java_geticon('ICON_ALIGN_CHANNELS'), 'TooltipString', 'Refine registration using head points', 'ClickedCallback', @RefineWithHeadPoints, 'separator', 'on');
end
if ~gChanAlign.isMeg
    gChanAlign.hButtonAdd      = uitoggletool(hToolbar, 'CData', java_geticon('ICON_SCOUT_NEW'),     'TooltipString', 'Add a new electrode',        'ClickedCallback', @ButtonAddElectrode_Callback, 'separator', 'on');
    gChanAlign.hButtonDelete   = uipushtool(  hToolbar, 'CData', java_geticon('ICON_DELETE'),        'TooltipString', 'Remove selected electrodes', 'ClickedCallback', @RemoveElectrodes);
end
gChanAlign.hButtonOk = uipushtool(  hToolbar, 'CData', java_geticon( 'ICON_OK'), 'separator', 'on', 'ClickedCallback', @buttonOk_Callback);% Update figure localization
gui_layout('Update');
% Move a bit the figure to refresh it on all systems
pos = get(gChanAlign.hFig, 'Position');
set(gChanAlign.hFig, 'Position', pos + [0 0 0 1]);
drawnow;
set(gChanAlign.hFig, 'Position', pos);
% Close progress bar
if isProgress
    bst_progress('stop');
end
    
end



%% ===== MOUSE CALLBACKS =====  
%% ===== MOUSE DOWN =====
function AlignButtonDown_Callback(hObject, ev)
    global gChanAlign;
    SelectionType = get(gChanAlign.hFig, 'SelectionType');
    % Right-click if a button is selected
    if strcmpi(SelectionType, 'alt') && ~isempty(gChanAlign.selectedButton)
        gChanAlign.mouseClicked = 1;
        % Record click position
        setappdata(gChanAlign.hFig, 'clickPositionFigure', get(gChanAlign.hFig, 'CurrentPoint'));
    % Left-click if "Add electrode" is selected
    elseif ~gChanAlign.isMeg && strcmpi(get(gChanAlign.hButtonAdd, 'State'), 'on')
        gChanAlign.mouseClicked = 1;
        AddElectrode();
    else
        % Call the default mouse down handle
        gChanAlign.Figure3DButtonDown_Bak(hObject, ev);
    end
end

%% ===== MOUSE MOVE =====
function AlignButtonMotion_Callback(hObject, ev)
    global gChanAlign;
    if isfield(gChanAlign, 'mouseClicked') && gChanAlign.mouseClicked && ~isempty(gChanAlign.selectedButton)
        % Get current mouse location
        curptFigure = get(gChanAlign.hFig, 'CurrentPoint');
        motionFigure = (curptFigure - getappdata(gChanAlign.hFig, 'clickPositionFigure')) / 1000;
        % Update click point location
        setappdata(gChanAlign.hFig, 'clickPositionFigure', curptFigure);
        % Get channels to modify
        iSelChan = GetSelectedChannels();
        % Initialize the transformations that are done
        Rnew = [];
        Tnew = [];
        Rescale = [];
        % Selected button
        switch (gChanAlign.selectedButton)
            case gChanAlign.hButtonTransX
                Tnew = [motionFigure(2) / 5, 0, 0];
            case gChanAlign.hButtonTransY
                Tnew = [0, motionFigure(2) / 5, 0];
            case gChanAlign.hButtonTransZ
                Tnew = [0, 0, motionFigure(2) / 5];
            case gChanAlign.hButtonRotX
                a = motionFigure(2);
                Rnew = [1,       0,      0; 
                        0,  cos(a), sin(a);
                        0, -sin(a), cos(a)];
            case gChanAlign.hButtonRotY
                a = motionFigure(2);
                Rnew = [cos(a), 0, -sin(a); 
                             0, 1,       0;
                        sin(a), 0,  cos(a)];
            case gChanAlign.hButtonRotZ
                a = motionFigure(2);
                Rnew = [cos(a), -sin(a), 0; 
                        sin(a),  cos(a), 0;
                             0,  0,      1];
            case gChanAlign.hButtonResize
                Rescale = repmat(1 + motionFigure(2), [1 3]);
            case gChanAlign.hButtonResizeX
                Rescale = [1 + motionFigure(2), 0, 0];
            case gChanAlign.hButtonResizeY
                Rescale = [0, 1 + motionFigure(2), 0];
            case gChanAlign.hButtonResizeZ
                Rescale = [0, 0, 1 + motionFigure(2)];
            case gChanAlign.hButtonMoveChan
                % Works only iif one channel is selected
                if (length(iSelChan) ~= 1)
                    return
                end
                % Select the nearest sensor from the mouse
                [p, v, vi] = select3d(gChanAlign.hScalpPatch);
                % If sensor index is valid
                if ~isempty(vi) && (vi > 0) && (norm(p' - gChanAlign.SensorsVertices(iSelChan,:)) < 0.01)
                    gChanAlign.SensorsVertices(iSelChan,:) = p';
                end
            otherwise 
                return;
        end
        % Apply transformation
        ApplyTransformation(iSelChan, Rnew, Tnew, Rescale);
        % Update display 
        UpdatePoints(iSelChan);
    else
        % Call the default mouse motion handle
        gChanAlign.Figure3DButtonMotion_Bak(hObject, ev);
    end
end

%% ===== GET SELECTED CHANNELS =====
function iSelChan = GetSelectedChannels()
    global gChanAlign;
    % Get channels to modify (ONLY FOR EEG: Cannot deform a MEG helmet)
    [SelChan, iSelChan] = figure_3d('GetFigSelectedRows', gChanAlign.hFig);
    if isempty(iSelChan) || gChanAlign.isMeg 
        iSelChan = 1:length(gChanAlign.SensorsVertices);
    else
        % Convert local sensors indices in global indices (channel file)
        iSelChan = gChanAlign.iGlobal2Local(iSelChan);
    end
end

%% ===== APPLY TRANSFORMATION =====
function ApplyTransformation(iSelChan, Rnew, Tnew, Rescale)
    global gChanAlign;
    % Mark the channel file as modified
    gChanAlign.isChanged = 1;
    % Apply rotation
    if ~isempty(Rnew)
        % Update sensors positions
        gChanAlign.SensorsVertices(iSelChan,:) = gChanAlign.SensorsVertices(iSelChan,:) * Rnew';
        % Update helmet position
        if ~isempty(gChanAlign.HelmetVertices)
            gChanAlign.HelmetVertices(iSelChan,:) = gChanAlign.HelmetVertices(iSelChan,:) * Rnew';
        end
        % Update head points positions
        if gChanAlign.isHeadPoints
            % Move markers
            gChanAlign.HeadPointsMarkersLoc = gChanAlign.HeadPointsMarkersLoc * Rnew';
            % Move fiducials
            if ~isempty(gChanAlign.HeadPointsFidLoc)
                gChanAlign.HeadPointsFidLoc = gChanAlign.HeadPointsFidLoc * Rnew';
            end
            % Move HPIs
            if ~isempty(gChanAlign.HeadPointsHpiLoc)
                gChanAlign.HeadPointsHpiLoc = gChanAlign.HeadPointsHpiLoc * Rnew';
            end
            % Move labels
            if ~isempty(gChanAlign.HeadPointsLabelsLoc)
                gChanAlign.HeadPointsLabelsLoc = gChanAlign.HeadPointsLabelsLoc * Rnew';
            end
        end
        % Add this transformation to the final transformation
        newTransf = eye(4);
        newTransf(1:3,1:3) = Rnew;
        gChanAlign.FinalTransf = newTransf * gChanAlign.FinalTransf;
    end
    % Apply Translation
    if ~isempty(Tnew)
        % Update sensors positions
        gChanAlign.SensorsVertices(iSelChan,:) = bst_bsxfun(@plus, gChanAlign.SensorsVertices(iSelChan,:), Tnew);
        % Update helmet position
        if ~isempty(gChanAlign.HelmetVertices)
            gChanAlign.HelmetVertices(iSelChan,:) = bst_bsxfun(@plus, gChanAlign.HelmetVertices(iSelChan,:), Tnew);
        end
        % Update head points positions
        if gChanAlign.isHeadPoints
            % Markers
            gChanAlign.HeadPointsMarkersLoc = bst_bsxfun(@plus, gChanAlign.HeadPointsMarkersLoc, Tnew);
            % Fiducials
            if ~isempty(gChanAlign.HeadPointsFidLoc)
                gChanAlign.HeadPointsFidLoc = bst_bsxfun(@plus, gChanAlign.HeadPointsFidLoc, Tnew);
            end
            % Fiducials
            if ~isempty(gChanAlign.HeadPointsHpiLoc)
                gChanAlign.HeadPointsHpiLoc = bst_bsxfun(@plus, gChanAlign.HeadPointsHpiLoc, Tnew);
            end
            % Labels
            if ~isempty(gChanAlign.HeadPointsLabelsLoc)
                gChanAlign.HeadPointsLabelsLoc = bst_bsxfun(@plus, gChanAlign.HeadPointsLabelsLoc, Tnew);
            end
        end
        % Add this transformation to the final transformation
        newTransf = eye(4);
        newTransf(1:3,4) = Tnew;
        gChanAlign.FinalTransf = newTransf * gChanAlign.FinalTransf;
    end
    % Apply rescale
    if ~isempty(Rescale)
        for iDim = 1:3
            if (Rescale(iDim) ~= 0)
                % Resize sensors
                gChanAlign.SensorsVertices(iSelChan,iDim) = gChanAlign.SensorsVertices(iSelChan,iDim) * Rescale(iDim);
                % Resize head points
                if gChanAlign.isHeadPoints
                    % Move markers
                    gChanAlign.HeadPointsMarkersLoc(:,iDim) = gChanAlign.HeadPointsMarkersLoc(:,iDim) * Rescale(iDim);
                    % Move fiducials
                    if ~isempty(gChanAlign.HeadPointsFidLoc)
                        gChanAlign.HeadPointsFidLoc(:,iDim)  = gChanAlign.HeadPointsFidLoc(:,iDim)  * Rescale(iDim);
                    end
                    % Move HPIs
                    if ~isempty(gChanAlign.HeadPointsHpiLoc)
                        gChanAlign.HeadPointsHpiLoc(:,iDim)  = gChanAlign.HeadPointsHpiLoc(:,iDim)  * Rescale(iDim);
                    end
                    % Move labels
                    if ~isempty(gChanAlign.HeadPointsLabelsLoc)
                        gChanAlign.HeadPointsLabelsLoc(:,iDim)  = gChanAlign.HeadPointsLabelsLoc(:,iDim)  * Rescale(iDim);
                    end
                end
            end
        end
    end
end

%% ===== UPDATE POINTS =====
function UpdatePoints(iSelChan)
    global gChanAlign;
    % Update sensor patch vertices
    set(gChanAlign.hSensorsPatch, 'Vertices', gChanAlign.SensorsVertices);
    if ~isempty(gChanAlign.hSensorsLabels)
        for i = 1:length(iSelChan)
            iTextChan = length(gChanAlign.hSensorsLabels) - iSelChan(i) + 1;
            set(gChanAlign.hSensorsLabels(iTextChan), 'Position', 1.08 * gChanAlign.SensorsVertices(iSelChan(i),:));
        end
    end
    % Update helmet patch vertices
    set(gChanAlign.hHelmetPatch, 'Vertices', gChanAlign.HelmetVertices);
    % Update headpoints markers and labels
    if gChanAlign.isHeadPoints
        % Extra head points
        set(gChanAlign.hHeadPointsMarkers, ...
            'XData', gChanAlign.HeadPointsMarkersLoc(:,1), ...
            'YData', gChanAlign.HeadPointsMarkersLoc(:,2), ...
            'ZData', gChanAlign.HeadPointsMarkersLoc(:,3));
        % Fiducials
        if ~isempty(gChanAlign.hHeadPointsFid)
            set(gChanAlign.hHeadPointsFid, ...
                'XData', gChanAlign.HeadPointsFidLoc(:,1), ...
                'YData', gChanAlign.HeadPointsFidLoc(:,2), ...
                'ZData', gChanAlign.HeadPointsFidLoc(:,3));
        end
        % HPI
        if ~isempty(gChanAlign.hHeadPointsHpi)
            set(gChanAlign.hHeadPointsHpi, ...
                'XData', gChanAlign.HeadPointsHpiLoc(:,1), ...
                'YData', gChanAlign.HeadPointsHpiLoc(:,2), ...
                'ZData', gChanAlign.HeadPointsHpiLoc(:,3));
        end
        % Labels
        for i = 1:size(gChanAlign.hHeadPointsLabels, 1)
            set(gChanAlign.hHeadPointsLabels(i), 'Position', 1.08 * gChanAlign.HeadPointsLabelsLoc(i,:));
        end
    end
end


%% ===== MOUSE UP =====
function AlignButtonUp_Callback(hObject, ev)
    global gChanAlign;
    % Catch only the events if the motion is currently processed
    if gChanAlign.mouseClicked
        gChanAlign.mouseClicked = 0;
    else
        % Call the default mouse up handle
        gChanAlign.Figure3DButtonUp_Bak(hObject, ev);
    end
end


%% ===== GET CURRENT CHANNELMAT =====
function ChannelMat = GetCurrentChannelMat(isAll)
    global GlobalData gChanAlign;
    % Parse inputs
    if (nargin < 1) || isempty(isAll)
        isAll = [];
    end
    % Load ChannelFile
    ChannelMat = in_bst_channel(gChanAlign.ChannelFile);
    ChannelMat.Channel = GlobalData.DataSet(gChanAlign.iDS).Channel;
    % Get final rotation and translation
    Rfinal = gChanAlign.FinalTransf(1:3,1:3);
    Tfinal = gChanAlign.FinalTransf(1:3,4);
    % Create 4x4 transformation matrix
    newtransf = eye(4);
    newtransf(1:3,1:3) = Rfinal;
    newtransf(1:3,4)   = Tfinal;
    % Get the channels
    iMeg = good_channel(ChannelMat.Channel, [], 'MEG');
    iRef = good_channel(ChannelMat.Channel, [], 'MEG REF');
    iEeg = sort([good_channel(ChannelMat.Channel, [], 'EEG'), good_channel(ChannelMat.Channel, [], 'SEEG'), good_channel(ChannelMat.Channel, [], 'ECOG')]);
    % Ask if needed to update also the other modalities
    if isempty(isAll)
        if gChanAlign.isMeg && (length(iEeg) > 10)
            isAll = java_dialog('confirm', 'Do you want to apply the same transformation to the EEG electrodes ?', 'Align sensors');
        elseif ~gChanAlign.isMeg && ~isempty(iMeg)
            isAll = java_dialog('confirm', 'Do you want to apply the same transformation to the MEG sensors ?', 'Align sensors');
        else
            isAll = 0;
        end
    end
    
    % Update EEG electrodes locations
    if ~gChanAlign.isMeg
        % Align each channel
        for i=1:length(iEeg)
            % Position
            ChannelMat.Channel(iEeg(i)).Loc(:,1) = gChanAlign.SensorsVertices(i,:)';
            % Name
            iTextChan = length(gChanAlign.hSensorsLabels) - gChanAlign.iGlobal2Local(iEeg(i)) + 1;
            ChannelMat.Channel(iEeg(i)).Name = gChanAlign.SensorsLabels{iTextChan};
        end
    end

    % List of sensors to apply the Rotation and Translation to
    if gChanAlign.isMeg && isAll 
        iChan = union(iMeg, iRef);
        iChan = union(iChan, iEeg);
    elseif (gChanAlign.isMeg && ~isAll) || (~gChanAlign.isMeg && isAll)
        iChan = union(iMeg, iRef);
    else
        iChan = [];
    end

    % Apply the rotation and translation to selected sensors
    for i=1:length(iChan)
        Loc = ChannelMat.Channel(iChan(i)).Loc;
        Orient = ChannelMat.Channel(iChan(i)).Orient;
        nCoils = size(Loc, 2);
        % Update location
        if ~isempty(Loc)
            ChannelMat.Channel(iChan(i)).Loc = Rfinal * Loc + Tfinal * ones(1, nCoils);
        end
        % Update orientation
        if ~isempty(Orient)
            ChannelMat.Channel(iChan(i)).Orient = Rfinal * Orient;
        end
    end
    % If needed: transform the digitized head points
    if gChanAlign.isHeadPoints
        % Update points positions
        iExtra = get(gChanAlign.hHeadPointsMarkers, 'UserData');
        ChannelMat.HeadPoints.Loc(:,iExtra) = gChanAlign.HeadPointsMarkersLoc';
        % Fiducials
        if ~isempty(gChanAlign.hHeadPointsFid)
            iFid = get(gChanAlign.hHeadPointsFid, 'UserData');
            ChannelMat.HeadPoints.Loc(:,iFid) = gChanAlign.HeadPointsFidLoc';
        end
        % HPI
        if ~isempty(gChanAlign.hHeadPointsHpi)
            iHpi = get(gChanAlign.hHeadPointsHpi, 'UserData');
            ChannelMat.HeadPoints.Loc(:,iHpi) = gChanAlign.HeadPointsHpiLoc';
        end
    end

    % If a TransfMeg field with translations/rotations available
    if gChanAlign.isMeg || isAll
        if ~isfield(ChannelMat, 'TransfMeg') || ~iscell(ChannelMat.TransfMeg)
            ChannelMat.TransfMeg = {};
        end
        if ~isfield(ChannelMat, 'TransfMegLabels') || ~iscell(ChannelMat.TransfMegLabels) || (length(ChannelMat.TransfMeg) ~= length(ChannelMat.TransfMegLabels))
            ChannelMat.TransfMegLabels = cell(size(ChannelMat.TransfMeg));
        end
        % Add a new transform to the list
        ChannelMat.TransfMeg{end+1} = newtransf;
        ChannelMat.TransfMegLabels{end+1} = 'manual correction';
    end
    % If also need to apply it to the EEG
    if ~gChanAlign.isMeg || isAll
        if ~isfield(ChannelMat, 'TransfEeg') || ~iscell(ChannelMat.TransfEeg)
            ChannelMat.TransfEeg = {};
        end
        if ~isfield(ChannelMat, 'TransfEegLabels') || ~iscell(ChannelMat.TransfEegLabels) || (length(ChannelMat.TransfEeg) ~= length(ChannelMat.TransfEegLabels))
            ChannelMat.TransfEegLabels = cell(size(ChannelMat.TransfEeg));
        end
        ChannelMat.TransfEeg{end+1} = newtransf;
        ChannelMat.TransfEegLabels{end+1} = 'manual correction';
    end

    % Add number of channels to the comment
    ChannelMat.Comment = str_remove_parenth(ChannelMat.Comment, '(');
    ChannelMat.Comment = [ChannelMat.Comment, sprintf(' (%d)', length(ChannelMat.Channel))];

    % History: Align channel files manually
    ChannelMat = bst_history('add', ChannelMat, 'align', 'Align channels manually:');
    % History: Rotation + translation
    ChannelMat = bst_history('add', ChannelMat, 'transform', sprintf('Rotation: [%1.3f,%1.3f,%1.3f; %1.3f,%1.3f,%1.3f; %1.3f,%1.3f,%1.3f]', Rfinal'));
    ChannelMat = bst_history('add', ChannelMat, 'transform', sprintf('Translation: [%1.3f,%1.3f,%1.3f]', Tfinal));
    if ~gChanAlign.isMeg
        ChannelMat = bst_history('add', ChannelMat, 'transform', sprintf('+ Possible other non-recordable operations on EEG electrodes'));
    end
end


%% ===== FIGURE CLOSE REQUESTED =====
function AlignClose_Callback(varargin)
    global gChanAlign;
    if gChanAlign.isChanged
        % Ask user to save changes
        SaveChanged = java_dialog('confirm', ['The sensors locations changed.' 10 10 ...
                                       'Would you like to save changes? ' 10 10], 'Align sensors');
        % Progress bar
        bst_progress('start', 'Align sensors', 'Updating channel file...');
        % Save changes and close figure
        if SaveChanged
            % Restore standard close callback for 3DViz figures
            set(gChanAlign.hFig, 'CloseRequestFcn', gChanAlign.Figure3DCloseRequest_Bak);
            drawnow;
            % Get new positions
            ChannelMat = GetCurrentChannelMat();
            % Save new electrodes positions in ChannelFile
            bst_save(gChanAlign.ChannelFile, ChannelMat, 'v7');
            % Get study associated with channel file
            [sStudy, iStudy] = bst_get('ChannelFile', gChanAlign.ChannelFile);
            % Reload study file
            db_reload_studies(iStudy);
            % Update raw links
            panel_channel_editor('UpdateRawLinks', gChanAlign.ChannelFile, ChannelMat);
        end
        bst_progress('stop');
    end
    % Only close figure
    gChanAlign.Figure3DCloseRequest_Bak(varargin{:});       
end


%% ===== SELECT ONE CHANNEL =====
function SelectOneChannel()
    global gChanAlign;
    % Get selected channels
    SelChan = figure_3d('GetFigSelectedRows', gChanAlign.hFig);
    % If there is more than one selected channels: select only one
    if iscell(SelChan) && (length(SelChan) > 1)
        bst_figures('SetSelectedRows', SelChan(1));
    end
end


%% ===== SHOW/HIDE LABELS =====
function ToggleLabels(varargin)
    global gChanAlign;
    % Update button color
    gui_update_toggle(gChanAlign.hButtonLabels);
    if strcmpi(get(gChanAlign.hButtonLabels, 'State'), 'on')
        set(gChanAlign.hSensorsLabels, 'Visible', 'on');
    else
        set(gChanAlign.hSensorsLabels, 'Visible', 'off');
    end
end

%% ===== SHOW/HIDE HELMET =====
function ToggleHelmet(varargin)
    global gChanAlign;
    % Update button color
    gui_update_toggle(gChanAlign.hButtonHelmet);
    if strcmpi(get(gChanAlign.hButtonHelmet, 'State'), 'on')
        set(gChanAlign.hHelmetPatch, 'Visible', 'on');
    else
        set(gChanAlign.hHelmetPatch, 'Visible', 'off');
    end
end


%% ===== EDIT LABEL =====
function EditLabel(varargin)
    global GlobalData gChanAlign;
    % Get selected channels
    SelChan = figure_3d('GetFigSelectedRows', gChanAlign.hFig);
    % No channel selected: return
    if isempty(SelChan)
        return
    elseif (length(SelChan) > 1)
        % Select only one channel
        SelectOneChannel();
    end
    % Edit label
    [SelChan, iSelChan] = figure_3d('GetFigSelectedRows', gChanAlign.hFig);
    % Ask user for a new Cluster Label
    newLabel = java_dialog('input', sprintf('Please enter a new label for channel "%s":', SelChan{1}), ...
                             'Rename selected channel', [], SelChan{1});
    if isempty(newLabel) || strcmpi(newLabel, SelChan{1})
        return
    end
    % Check that sensor name does not already exist
    if any(strcmpi(newLabel, {GlobalData.DataSet(gChanAlign.iDS).Channel.Name}))
        bst_error(['Electrode "' newLabel '" already exists.'], 'Rename electrode', 0);
        return;
    end
    % Update GlobalData
    GlobalData.DataSet(gChanAlign.iDS).Channel(iSelChan).Name = newLabel;
    % Update label grapically
    iTextChan = length(gChanAlign.hSensorsLabels) - gChanAlign.iGlobal2Local(iSelChan) + 1;
    set(gChanAlign.hSensorsLabels(iTextChan), 'String', newLabel);
    gChanAlign.SensorsLabels{iTextChan} = newLabel;
    gChanAlign.isChanged = 1;
end


%% ===== SELECT OPERATION =====
function SelectOperation(hObject, ev)
    global gChanAlign;
    % Update button color
    gui_update_toggle(hObject);
    % Get the list of valid buttons
    hButtonList = [gChanAlign.hButtonTransX,  gChanAlign.hButtonTransY,  gChanAlign.hButtonTransZ, ...
                   gChanAlign.hButtonRotX,    gChanAlign.hButtonRotY,    gChanAlign.hButtonRotZ];
    if ~gChanAlign.isMeg
        hButtonList = [hButtonList, gChanAlign.hButtonResizeX, gChanAlign.hButtonResizeY, gChanAlign.hButtonResizeZ, ...
                       gChanAlign.hButtonResize, gChanAlign.hButtonMoveChan];
    end
    % Unselect all buttons excepted the selected one
    hButtonsUnsel = setdiff(hButtonList, hObject);
    hButtonsUnsel = hButtonsUnsel(strcmpi(get(hButtonsUnsel, 'State'), 'on'));
    if ~isempty(hButtonsUnsel)
        set(hButtonsUnsel, 'State', 'off');
        gui_update_toggle(hButtonsUnsel(1));
    end
    
    % If button was unselected: nothing to do
    if strcmpi(get(hObject, 'State'), 'off')
        gChanAlign.selectedButton = [];
    else
        gChanAlign.selectedButton = hObject;
    end
    % If moving channels: keep only one selected channels
    UniqueChannelSelection = ~gChanAlign.isMeg && isequal(gChanAlign.selectedButton, gChanAlign.hButtonMoveChan);
    setappdata(gChanAlign.hFig, 'UniqueChannelSelection', UniqueChannelSelection);
    if UniqueChannelSelection
        SelectOneChannel();
    end
end

%% ===== PROJECT ELECTRODES =====
function ProjectElectrodesOnScalp(varargin)
    global gChanAlign;
    % Get the list of valid buttons
    hButtonList = [gChanAlign.hButtonTransX,  gChanAlign.hButtonTransY,  gChanAlign.hButtonTransZ, gChanAlign.hButtonLabels, ...
                   gChanAlign.hButtonRotX,    gChanAlign.hButtonRotY,    gChanAlign.hButtonRotZ, gChanAlign.hButtonOk];
    if ~gChanAlign.isMeg
        hButtonList = [hButtonList, gChanAlign.hButtonResizeX, gChanAlign.hButtonResizeY, gChanAlign.hButtonResizeZ, ...
                       gChanAlign.hButtonProject, gChanAlign.hButtonResize, gChanAlign.hButtonMoveChan];
    end
    % Wait mode
    bst_progress('start', 'Align electrodes', 'Projecting electrodes on scalp...');
    set(hButtonList, 'Enable', 'off');
    drawnow();

    % Get surface patch
    TessInfo = getappdata(gChanAlign.hFig, 'Surface');
    gChanAlign.hScalpPatch = TessInfo(1).hPatch;
    % Get coordinates of vertices for each face
    Vertices   = get(gChanAlign.hScalpPatch, 'Vertices');
%     Faces      = get(gChanAlign.hScalpPatch, 'Faces');
%     vertFacesX = reshape(Vertices(reshape(Faces,1,[]), 1), size(Faces));
%     vertFacesY = reshape(Vertices(reshape(Faces,1,[]), 2), size(Faces));
%     vertFacesZ = reshape(Vertices(reshape(Faces,1,[]), 3), size(Faces));

    % Parametrize the surfaces
    p   = .2;
    th  = -pi-p   : 0.01 : pi+p;
    phi = -pi/2-p : 0.01 : pi/2+p;
    rVertices = tess_parametrize_new(Vertices, th, phi);

    % Get channels to modify 
    [ChanToProject, iChanToProject] = figure_3d('GetFigSelectedRows', gChanAlign.hFig);
    if isempty(iChanToProject)
        iChanToProject = 1:length(gChanAlign.SensorsVertices);
    else
        % Convert local sensors indices in global indices (channel file)
        iChanToProject = gChanAlign.iGlobal2Local(iChanToProject);
    end

    % Process each sensor
    for i = 1:length(iChanToProject)
        iChan = iChanToProject(i);
        % Get the closest surface from the point
        c = gChanAlign.SensorsVertices(iChan,:)';
        % Convert in spherical coordinates
        [c_th,c_phi,c_r] = cart2sph(c(1), c(2), c(3));
        % Interpolate
        c_r = interp2(th, phi, rVertices, c_th, c_phi);
        % Project back in cartesian coordinates
        [c(1),c(2),c(3)] = sph2cart(c_th, c_phi, c_r);
        gChanAlign.SensorsVertices(iChan,:) = c;
    end
    gChanAlign.isChanged = 1;

    % Update Sensors display
    set(gChanAlign.hSensorsPatch, 'Vertices', gChanAlign.SensorsVertices);
    for i=1:length(iChanToProject)
        iTextChan = length(gChanAlign.hSensorsLabels) - iChanToProject(i) + 1;
        set(gChanAlign.hSensorsLabels(iTextChan), 'Position', 1.08 * gChanAlign.SensorsVertices(iChanToProject(i),:));
    end
    drawnow();
    % Restore GUI
    bst_progress('stop');
    set(hButtonList, 'Enable', 'on');
end


%% ===== REFINE USING HEAD POINTS =====
function RefineWithHeadPoints(varargin)
    global gChanAlign;
    % Get current channel file
    ChannelMat = GetCurrentChannelMat(1);
    % Refine positions using head points
    [ChannelMat, Rnew, Tnew] = channel_align_auto(gChanAlign.ChannelFile, ChannelMat, 1, 0);
    if isempty(Rnew) && isempty(Tnew)
        return;
    end
    % Get channels to modify
    iSelChan = GetSelectedChannels();
    % Apply transformation
    ApplyTransformation(iSelChan, Rnew, Tnew(:)', []);
    % Update display
    UpdatePoints(iSelChan);
end


%% ===== VALIDATION BUTTONS =====
function buttonOk_Callback(varargin)
    global gChanAlign;
    % Close 3DViz figure
    close(gChanAlign.hFig);
end


%% ===== REMOVE ELECTRODES =====
function RemoveElectrodes(varargin)
    global GlobalData gChanAlign;
    % Display warning message
    if gChanAlign.isFirstRmWarning
        res = java_dialog('confirm', ['You are about to change the number of electrodes.', 10 ...
                           'This may cause some trouble while importing recordings.' 10 10, ...
                           'Are you sure you want to remove those electrodes ?' 10 10], 'Align sensors');
        if ~res
            return
        end
        gChanAlign.isFirstRmWarning = 0;
    end
    % Get selected channels
    [SelChan, iSelChan] = figure_3d('GetFigSelectedRows', gChanAlign.hFig);
    if isempty(SelChan)
        return
    end
    % Get indices
    iLocalChan = gChanAlign.iGlobal2Local(iSelChan);
    iTextChan = length(gChanAlign.hSensorsLabels) - iLocalChan + 1;
    % Remove them from everywhere
    bst_figures('SetSelectedRows', []);
    GlobalData.DataSet(gChanAlign.iDS).Channel(iSelChan) = [];
    delete(gChanAlign.hSensorsLabels(iTextChan));
    gChanAlign.hSensorsLabels(iTextChan) = [];
    gChanAlign.SensorsLabels(iTextChan) = [];
    gChanAlign.SensorsVertices(iLocalChan, :) = [];
    
    % Update correspondence Global/Local
    for i = 1:length(iLocalChan)
        indInc = (gChanAlign.iGlobal2Local >= iLocalChan(i));
        gChanAlign.iGlobal2Local(indInc) = gChanAlign.iGlobal2Local(indInc) - 1;
    end
    gChanAlign.iGlobal2Local(iSelChan) = [];

    % Remove from sensors patch
    Vertices = get(gChanAlign.hSensorsPatch, 'Vertices');
    Faces    = get(gChanAlign.hSensorsPatch, 'Faces');
    FaceVertexCData = get(gChanAlign.hSensorsPatch, 'FaceVertexCData');
    [Vertices, Faces] = tess_remove_vert(Vertices, Faces, iLocalChan);
    FaceVertexCData(iLocalChan, :) = [];
    set(gChanAlign.hSensorsPatch, 'Vertices', Vertices, 'Faces', Faces, 'FaceVertexCData', FaceVertexCData);
    gChanAlign.isChanged = 1;
end
        

%% ===== BUTTON: ADD ELECTRODE =====
function ButtonAddElectrode_Callback(hObject, ev)
    global gChanAlign;
    % Display warning message
    if gChanAlign.isFirstAddWarning
        res = java_dialog('confirm', ['You are about to change the number of electrodes.', 10 ...
                           'This may cause some trouble while importing recordings.' 10 10, ...
                           'Are you sure you want to add an electrode ?' 10 10], 'Align sensors');
        if ~res
            set(hObject, 'State', 'off');
            return
        end
        gChanAlign.isFirstAddWarning = 0;
    end
    % Change figure cursor
    if strcmpi(get(hObject, 'State'), 'on')
        set(gChanAlign.hFig, 'Pointer', 'cross');
    else
        set(gChanAlign.hFig, 'Pointer', 'arrow');
    end
end

%% ===== ADD ELECTRODE =====
function AddElectrode(hObject, ev)
    global GlobalData gChanAlign;
    % Select the nearest sensor from the mouse
    [p, v, vi] = select3d(gChanAlign.hScalpPatch);
    % If sensor index is not valid
    if isempty(vi) || (vi <= 0)
        return
    end
    bst_figures('SetSelectedRows', []);
    
    % Find the closest electrodes
    nbElectrodes = length(gChanAlign.SensorsVertices);
    % Get closest point to the clicked position
    [mindist, iClosestLocal] = min(sqrt(sum(bst_bsxfun(@minus, gChanAlign.SensorsVertices, p') .^ 2, 2)));
    % Get the correspondence in global listing
    iClosestGlobal = find(gChanAlign.iGlobal2Local == iClosestLocal);
    
    % Add channel to global list
    iNewGlobal = length(GlobalData.DataSet(gChanAlign.iDS).Channel) + 1;
    sChannel = GlobalData.DataSet(gChanAlign.iDS).Channel(iClosestGlobal);
    sChannel.Name = sprintf('E%d', iNewGlobal);
    sChannel.Loc = p;
    GlobalData.DataSet(gChanAlign.iDS).Channel(iNewGlobal) = sChannel;

    % Add channel to local list
    iNewLocal = nbElectrodes + 1;
    gChanAlign.SensorsVertices(iNewLocal,:) = p';
    gChanAlign.iGlobal2Local(iNewGlobal) = iNewLocal;

    % Add new vertex
    Vertices = [get(gChanAlign.hSensorsPatch, 'Vertices'); p'];
    Faces = channel_tesselate(Vertices);
    FaceVertexCData = [get(gChanAlign.hSensorsPatch, 'FaceVertexCData'); 1 1 1];
    set(gChanAlign.hSensorsPatch, 'Vertices', Vertices, 'Faces', Faces, 'FaceVertexCData', FaceVertexCData);
    % Add channel to figure selected channels
    GlobalData.DataSet(gChanAlign.iDS).Figure(gChanAlign.iFig).SelectedChannels(end + 1) = iNewGlobal;
    
    % Copy existing label object
    gChanAlign.SensorsLabels = [sChannel.Name; gChanAlign.SensorsLabels];
    iTextClosest = length(gChanAlign.hSensorsLabels) - iClosestLocal + 1;
    hClosestLabel = gChanAlign.hSensorsLabels(iTextClosest);
    hNewLabel = copyobj(hClosestLabel, get(hClosestLabel, 'Parent'));
    set(hNewLabel, 'String', sChannel.Name, 'Position', 1.08 * p');
    gChanAlign.hSensorsLabels = [hNewLabel; gChanAlign.hSensorsLabels];

    % Unselect "Add electrode" button
    set(gChanAlign.hButtonAdd, 'State', 'off');
    ButtonAddElectrode_Callback(gChanAlign.hButtonAdd, []);
    % Select new electrode
    bst_figures('SetSelectedRows', {sChannel.Name});
    % Set modified flag
    gChanAlign.isChanged = 1;
end





