function varargout = figure_spectrum( varargin )
% FIGURE_SPECTRUM: Creation and callbacks for power density spectrums figures (x-axis = frequency).
%
% USAGE:  hFig = figure_spectrum('CreateFigure', FigureId)

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

macro_methodcall;
end


%% ===== CREATE FIGURE =====
function hFig = CreateFigure(FigureId) %#ok<DEFNU>
    import org.brainstorm.icon.*;
    % Get renderer name
%     if (bst_get('DisableOpenGL') == 1)
%         rendererName = 'zbuffer';
%     else
%         rendererName = 'opengl';
%     end
    rendererName = 'zbuffer';
    % Create new figure
    hFig = figure('Visible',       'off', ...
                  'NumberTitle',   'off', ...
                  'IntegerHandle', 'off', ...
                  'MenuBar',       'none', ...
                  'Toolbar',       'none', ...
                  'DockControls',  'on', ...
                  'Units',         'pixels', ...
                  'Interruptible', 'off', ...
                  'BusyAction',    'queue', ...
                  'Tag',           FigureId.Type, ...
                  'Renderer',      rendererName, ...
                  'CloseRequestFcn',     @(h,ev)bst_figures('DeleteFigure',h,ev), ...
                  'KeyPressFcn',         @FigureKeyPressedCallback, ...
                  'WindowButtonDownFcn', @FigureMouseDownCallback, ...
                  'WindowButtonUpFcn',   @FigureMouseUpCallback, ...
                  'ResizeFcn',           @(h,ev)figure_timeseries('ResizeCallback',h,ev));
    % Define Mouse wheel callback separately (not supported by old versions of Matlab)
    if isprop(hFig, 'WindowScrollWheelFcn')
        set(hFig, 'WindowScrollWheelFcn',  @FigureMouseWheelCallback, ...
                  'KeyReleaseFcn',         @(h,ev)figure_timeseries('FigureKeyReleasedCallback',h,ev));
    end

    % Prepare figure appdata
    setappdata(hFig, 'FigureId', FigureId);
    setappdata(hFig, 'hasMoved', 0);
    setappdata(hFig, 'isPlotEditToolbar', 0);
    setappdata(hFig, 'AllChannelsDisplayed', 0);
    setappdata(hFig, 'GraphSelection', []);
    setappdata(hFig, 'isStatic', 0);
    setappdata(hFig, 'isStaticFreq', 1);
    setappdata(hFig, 'isControlKeyDown', false);
    setappdata(hFig, 'isShiftKeyDown', false);
    setappdata(hFig, 'Colormap', db_template('ColormapInfo'));
    % Time-freq specific appdata
    TfInfo = db_template('TfInfo');
    setappdata(hFig, 'Timefreq', TfInfo);
end


%% ===========================================================================
%  ===== FIGURE CALLBACKS ====================================================
%  ===========================================================================
%% ===== CURRENT FREQ CHANGED =====
function CurrentTimeChangedCallback(hFig) %#ok<DEFNU>
    % If no time in this figure
    if getappdata(hFig, 'isStatic')
        return;
    end
    TfInfo = getappdata(hFig, 'Timefreq');
    switch (TfInfo.DisplayMode)
        % Spectrum: redraw everything
        case 'Spectrum'
            UpdateFigurePlot(hFig, 1);
        % Time series: Move cursor
        case 'TimeSeries'
            hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph');
            if ~isempty(hAxes)
                PlotCursor(hFig, hAxes);
            end
    end
end

%% ===== CURRENT FREQ CHANGED =====
function CurrentFreqChangedCallback(hFig) %#ok<DEFNU>
    global GlobalData;
    % If no frequencies for this figure
    if getappdata(hFig, 'isStaticFreq')
        return;
    end
    TfInfo = getappdata(hFig, 'Timefreq');
    switch (TfInfo.DisplayMode)
        % Spectrum: Move cursor
        case 'Spectrum'
            hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph');
            if ~isempty(hAxes)
                PlotCursor(hFig, hAxes);
            end
        % Time series: redraw everything
        case 'TimeSeries'
            TfInfo.iFreqs = GlobalData.UserFrequencies.iCurrentFreq;
            setappdata(hFig, 'Timefreq', TfInfo);
            UpdateFigurePlot(hFig, 1);
    end
end

%% ===== DISPLAY OPTIONS CHANGED =====
function DisplayOptionsChangedCallback(hFig) %#ok<DEFNU>
    % Restore intial view
    zoom out;
    % Update display
    UpdateFigurePlot(hFig, 1);
    % Get figure
    [hFig,iFig,iDS] = bst_figures('GetFigure', hFig);
    % Redraw select sensors
    SelectedRowChangedCallback(iDS, iFig);
end

%% ===== SELECTED ROW CHANGED =====
function SelectedRowChangedCallback(iDS, iFig)
    global GlobalData;
    % Get figure appdata
    hFig = GlobalData.DataSet(iDS).Figure(iFig).hFigure;
    % Get current selection for the figure
    curSelRows = figure_timeseries('GetFigSelectedRows', hFig);
    % Get new selection that the figure should show (keep only the ones available for this figure)
    allFigRows = GlobalData.DataSet(iDS).Figure(iFig).Handles.LinesLabels;
    newSelRows = intersect(GlobalData.DataViewer.SelectedRows, allFigRows);
    % Sensors to select
    rowsToSel = setdiff(newSelRows, curSelRows);
    if ~isempty(rowsToSel)
        figure_timeseries('SetFigSelectedRows', hFig, rowsToSel, 1);
    end
    % Sensors to unselect
    rowsToUnsel = setdiff(curSelRows, newSelRows);
    if ~isempty(rowsToUnsel)
        figure_timeseries('SetFigSelectedRows', hFig, rowsToUnsel, 0);
    end
end


%% ===========================================================================
%  ===== KEYBOARD AND MOUSE CALLBACKS ========================================
%  ===========================================================================
%% ===== FIGURE MOUSE DOWN =====
function FigureMouseDownCallback(hFig, ev)
    % Get selected object in this figure
    hObj = get(hFig,'CurrentObject');
    if isempty(hObj)
        return;
    end
    % Get object tag
    objTag = get(hObj, 'Tag');
    % Re-select main axes
    drawnow;
    hAxes = findobj(hFig, '-depth', 1, 'tag', 'AxesGraph');
    set(hFig,'CurrentObject', hAxes(1), 'CurrentAxes', hAxes(1));      
    % Get figure properties
    MouseStatus = get(hFig, 'SelectionType');
    
    % Switch between available graphic objects
    switch (objTag)
        case 'Spectrum'
            % Figure: Keep the main axes as clicked object
            hAxes = hAxes(1);
        case 'AxesGraph'
            % Axes: selectec axes = the one that was clicked
            hAxes = hObj;
        case 'DataLine'
            % Time series lines: select
            if (~strcmpi(MouseStatus, 'alt') || (get(hObj, 'LineWidth') > 1))
                LineClickedCallback(hObj);
                return;
            end
        case {'SelectionPatch', 'Cursor', 'TextCursor'}
            hAxes = get(hObj, 'Parent');
        case 'legend'
            legendButtonDownFcn = get(hObj, 'ButtonDownFcn');
            legendButtonDownFcn{1}(hObj, ev, legendButtonDownFcn{2});
            return
        otherwise
            % Any other object: consider as a click on the main axes
    end

    % ===== PROCESS CLICKS ON MAIN TS AXES =====
    % Start an action (Move time cursor, pan)
    switch(MouseStatus)
        % Left click
        case 'normal'
            clickAction = 'selection'; 
            % Initialize time selection
            [Xcur, iXcur, Xvector] = GetMouseX(hFig, hAxes);
            if (length(Xvector) > 1)
                setappdata(hFig, 'GraphSelection', [Xcur, Inf]);
            else
                setappdata(hFig, 'GraphSelection', []);
            end
        % CTRL+Mouse, or Mouse right
        case 'alt'
            clickAction = 'pan';
        % SHIFT+Mouse
        case 'extend'
            clickAction = 'pan';
        % DOUBLE CLICK
        case 'open'
            ResetView(hFig);
            return;
        % OTHER : nothing to do
        otherwise
            return
    end

    % Reset the motion flag
    setappdata(hFig, 'hasMoved', 0);
    % Record mouse location in the figure coordinates system
    setappdata(hFig, 'clickPositionFigure', get(hFig, 'CurrentPoint'));
    % Record action to perform when the mouse is moved
    setappdata(hFig, 'clickAction', clickAction);
    % Record axes ibject that was clicked (usefull when more than one axes object in figure)
    setappdata(hFig, 'clickSource', hAxes);
    % Register MouseMoved callbacks for current figure
    set(hFig, 'WindowButtonMotionFcn', @FigureMouseMoveCallback);
end


%% ===== FIGURE MOUSE MOVE =====
function FigureMouseMoveCallback(hFig, ev)  
    % Get current mouse action
    clickAction = getappdata(hFig, 'clickAction');
    hAxes = getappdata(hFig, 'clickSource');
    if isempty(clickAction) || isempty(hAxes)
        return
    end
    % Set the motion flag
    setappdata(hFig, 'hasMoved', 1);
    % Get current mouse location
    curptFigure = get(hFig, 'CurrentPoint');
    motionFigure = (curptFigure - getappdata(hFig, 'clickPositionFigure')) / 100;
    % Update click point location
    setappdata(hFig, 'clickPositionFigure', curptFigure);

    % Switch between different actions (Pan, Rotate, Contrast)
    switch(clickAction)                          
        case 'pan'
            % Get initial XLim and YLim
            XLimInit = getappdata(hAxes, 'XLimInit');
            YLimInit = getappdata(hAxes, 'YLimInit');
            
            % Move view along X axis
            XLim = get(hAxes, 'XLim');
            XLim = XLim - (XLim(2) - XLim(1)) * motionFigure(1);
            XLim = figure_timeseries('limitInterval', XLim, XLimInit);
            set(hAxes, 'XLim', XLim);
            
            % Move view along Y axis
            YLim = get(hAxes, 'YLim');
            YLim = YLim - (YLim(2) - YLim(1)) * motionFigure(2);
            YLim = figure_timeseries('limitInterval', YLim, YLimInit);
            set(hAxes, 'YLim', YLim);

        case 'selection'
            % Get time selection
            GraphSelection = getappdata(hFig, 'GraphSelection');
            % Time selection
            if ~isempty(GraphSelection)
                % Update time selection
                Xcur = GetMouseX(hFig, hAxes);
                GraphSelection(2) = Xcur;
                setappdata(hFig, 'GraphSelection', GraphSelection);
                % Redraw time selection
                DrawSelection(hFig);
            end
    end
end
            

%% ===== FIGURE MOUSE UP =====        
function FigureMouseUpCallback(hFig, event)   
    % Get mouse state
    hasMoved    = getappdata(hFig, 'hasMoved');
    MouseStatus = get(hFig, 'SelectionType');
    % Reset figure mouse fields
    setappdata(hFig, 'clickAction', '');
    setappdata(hFig, 'hasMoved', 0);
    % Get axes handles
    hAxes = getappdata(hFig, 'clickSource');
    if isempty(hAxes) || ~ishandle(hAxes)
        return
    end
    
    % If mouse has not moved: popup or time change
    if ~hasMoved && ~isempty(MouseStatus)
        if strcmpi(MouseStatus, 'normal')
            % Get current frequency
            [Xcur, iXcur, Xvector, Xmode] = GetMouseX(hFig, hAxes);
            % Update plot
            if ~isempty(Xcur)
                % Move time cursor to new time
                hCursor = findobj(hAxes, '-depth', 1, 'Tag', 'Cursor');
                set(hCursor, 'XData', Xcur.*[1 1]);
                drawnow;
                % Update the current time in the whole application      
                switch(Xmode)
                    case 'Spectrum'
                        panel_freq('SetCurrentFreq', iXcur);
                    case 'TimeSeries'
                        panel_time('SetCurrentTime', Xcur);
                end
                % Remove previous time selection patch
                setappdata(hFig, 'GraphSelection', []);
                DrawSelection(hFig);
            end
        else 
            % Popup
            DisplayFigurePopup(hFig);
        end
    end
    
    % Reset MouseMove callbacks for current figure
    set(hFig, 'WindowButtonMotionFcn', []); 
    % Remove mouse callbacks appdata
    setappdata(hFig, 'clickSource', []);
    setappdata(hFig, 'clickAction', []);
    % Update figure selection
    bst_figures('SetCurrentFigure', hFig, 'TF');
end


%% ===== GET MOUSE X =====
function [Xcur, iXcur, Xvector, Xmode] = GetMouseX(hFig, hAxes)
    % Get current point in axes
    Xcur    = get(hAxes, 'CurrentPoint');
    XLim = get(hAxes, 'XLim');
    TfInfo = getappdata(hFig, 'Timefreq');
    % Check whether cursor is out of display time bounds
    Xcur= bst_saturate(Xcur(1,1), XLim);
    % Get the X vector
    [Time, Freqs] = figure_timefreq('GetFigureData', hFig);
    switch (TfInfo.DisplayMode)
        case 'Spectrum',   Xvector = Freqs;
        case 'TimeSeries', Xvector = Time;
    end
    Xmode = TfInfo.DisplayMode;
    % Bands (time or freq)
    if iscell(Xvector)
        CenterBand = mean(process_tf_bands('GetBounds', Freqs), 2);
        iXcur = bst_closest(Xcur, CenterBand);
        Xcur = CenterBand(iXcur);
    else
        iXcur = bst_closest(Xcur, Xvector);
        Xcur = Xvector(iXcur);
    end
end

%% ===== DRAW SELECTION =====
function DrawSelection(hFig)
    % Get axes (can have more than one)
    hAxesList = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph');
    % Get time selection
    GraphSelection = getappdata(hFig, 'GraphSelection');
    % Get display mode
    TfInfo = getappdata(hFig, 'Timefreq');
    % Process all the axes
    for i = 1:length(hAxesList)
        hAxes = hAxesList(i);
        % Draw new time selection patch
        if ~isempty(GraphSelection) && ~isinf(GraphSelection(2))
            % Get axes limits 
            YLim = get(hAxes, 'YLim');
            % Get previous patch
            hSelPatch = findobj(hAxes, '-depth', 1, 'Tag', 'SelectionPatch');
            % Position of the square patch
            XData = [GraphSelection(1), GraphSelection(2), GraphSelection(2), GraphSelection(1)];
            YData = [YLim(1), YLim(1), YLim(2), YLim(2)];
            ZData = [0.01 0.01 0.01 0.01];
            % If patch do not exist yet: create it
            if isempty(hSelPatch)
                % Draw patch
                hSelPatch = patch('XData', XData, ...
                                   'YData', YData, ...
                                   'ZData', ZData, ...
                                   'EraseMode', 'xor', ...   %%% BUG OPENGL
                                   'LineWidth', 1, ...
                                   'FaceColor', [.3 .3 1], ...
                                   'FaceAlpha', 1, ...
                                   'EdgeColor', 'none', ...
                                   'EdgeAlpha', 1, ...
                                   'Tag',       'SelectionPatch', ...
                                   'BackfaceLighting', 'unlit', ...
                                   'Parent',    hAxes);
            % Else, patch already exist: update it
            else
                % Change patch limits
                set(hSelPatch, ...
                    'XData', XData, ...
                    'YData', YData, ...
                    'ZData', ZData, ...
                    ... 'EraseMode', 'xor', ...
                    'Visible', 'on');
            end
            
            % === UPDATE X-LABEL ===
            switch (TfInfo.DisplayMode)
                case 'Spectrum'
                    strSelection = sprintf('Selection: [%1.2f Hz - %1.2f Hz]', min(GraphSelection), max(GraphSelection));
                case 'TimeSeries'
                    % Get current time units
                    timeUnit = panel_time('GetTimeUnit');
                    % Update label according to the time units
                    switch (timeUnit)
                        case 'ms'
                            strSelection = sprintf('Selection: [%1.2f ms - %1.2f ms]', min(GraphSelection)*1000, max(GraphSelection)*1000);
                        case 's'
                            strSelection = sprintf('Selection: [%1.4f s - %1.4f s]', min(GraphSelection), max(GraphSelection));
                    end
                    strLength = sprintf('         Duration: [%d ms]', round(abs(GraphSelection(2) - GraphSelection(1)) * 1000));
                    strSelection = [strSelection, strLength];
            end
            % Get selection label
            hTextTimeSel = findobj(hFig, '-depth', 1, 'Tag', 'TextTimeSel');
            if ~isempty(hTextTimeSel)
                % Update label
                set(hTextTimeSel, 'Visible', 'on', 'String', strSelection);
            end
            
        else
            % Remove previous selection patch
            set(findobj(hAxes, '-depth', 1, 'Tag', 'SelectionPatch'), 'Visible', 'off');
            set(findobj(hFig, '-depth', 1, 'Tag', 'TextTimeSel'), 'Visible', 'off');
        end
    end
end


%% ===== SET FREQ SELECTION =====
% Define manually the freq selection for a given Spectrum figure
% 
% USAGE:  SetFreqSelection(hFig, Xsel)
%         SetFreqSelection(hFig)
function SetFreqSelection(hFig, Xsel)
    % Get figure display mode
    TfInfo = getappdata(hFig, 'Timefreq');
    % Get the X vector for this figure
    [Time, Freqs] = figure_timefreq('GetFigureData', hFig);
    switch (TfInfo.DisplayMode)
        case 'Spectrum'
            Xvector = Freqs;
            strUnits = 'Hz';
        case 'TimeSeries'
            Xvector = Time;
            strUnits = 's';
    end
    if (length(Xvector) <= 1) || iscell(Xvector)
        return;
    end
    % Ask for a frequency range
    if (nargin < 2) || isempty(Xsel)
        Xsel = panel_freq('InputSelectionWindow', Xvector([1,end]), 'Set frequency selection', strUnits);
        if isempty(Xsel)
            return
        end
    end
    % Select the closest point in time vector
    Xsel = Xvector(bst_closest(Xsel, Xvector));
    % Draw new time selection
    setappdata(hFig, 'GraphSelection', Xsel);
    DrawSelection(hFig);
end


%% ===== FIGURE MOUSE WHEEL =====
function FigureMouseWheelCallback(hFig, event)
    if isempty(event)
        return;
    elseif (event.VerticalScrollCount < 0)
        % ZOOM IN
        Factor = 1 - event.VerticalScrollCount ./ 10;
    elseif (event.VerticalScrollCount > 0)
        % ZOOM OUT
        Factor = 1./(1 + event.VerticalScrollCount ./ 10);
    end
    if getappdata(hFig, 'isControlKeyDown') 
        figure_timeseries('FigureZoom', hFig, 'vertical', Factor);
    elseif getappdata(hFig, 'isShiftKeyDown')
        figure_timeseries('UpdateTimeSeriesFactor', hFig, Factor);
    else
        figure_timeseries('FigureZoom', hFig, 'horizontal', Factor);
    end
end


%% ===== KEYBOARD CALLBACK =====
function FigureKeyPressedCallback(hFig, ev)
    global GlobalData;
    % Convert event to Matlab (in case it's coming from a java callback)
    [keyEvent, isControl, isShift] = gui_brainstorm('ConvertKeyEvent', ev);
    if isempty(keyEvent.Key)
        return
    end
    % If shift is already pressed, no need to process the "shift" press again
    if (getappdata(hFig, 'isShiftKeyDown') && strcmpi(keyEvent.Key, 'shift')) || ...
       (getappdata(hFig, 'isControlKeyDown') && strcmpi(keyEvent.Key, 'control'))     
        return
    end
    % Prevent multiple executions
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph')';
    set([hFig hAxes], 'BusyAction', 'cancel');
    % Get time freq information
    TfInfo = getappdata(hFig, 'Timefreq');
    TfFile = TfInfo.FileName;
    if isempty(TfFile)
        return;
    end
    
    % Process event
    switch (keyEvent.Key)
        % Arrows
        case {'leftarrow', 'rightarrow', 'pageup', 'pagedown', 'home', 'end'}
            switch (TfInfo.DisplayMode)
                case 'Spectrum',     panel_freq('FreqKeyCallback', keyEvent);
                case 'TimeSeries',   panel_time('TimeKeyCallback', keyEvent);
            end
        case {'uparrow', 'downarrow'}
            % UP/DOWN: Change data row
            if ~isempty(TfInfo.RowName) && (ischar(TfInfo.RowName) || (length(TfInfo.RowName) == 1))
                panel_display('SetSelectedRowName', hFig, keyEvent.Key);
            end
        % CTRL+D : Dock figure
        case 'd'
            if isControl
                isDocked = strcmpi(get(hFig, 'WindowStyle'), 'docked');
                bst_figures('DockFigure', hFig, ~isDocked);
            end
        % CTRL+I : Save as image
        case 'i'
            if isControl
                out_figure_image(hFig);
            end
        % CTRL+J : Open as image
        case 'j'
            if isControl
                out_figure_image(hFig, 'Viewer');
            end
        % CTRL+R : Recordings time series
        case 'r'
            if isControl
                % Get figure description
                [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
                % If there is an associated an available DataFile
                if ~isempty(GlobalData.DataSet(iDS).DataFile)
                    view_timeseries(GlobalData.DataSet(iDS).DataFile, GlobalData.DataSet(iDS).Figure(iFig).Id.Modality);
                end
            end
        % CTRL+T : Default topography
        case 't'           
            if isControl
                view_topography(TfFile, [], '2DSensorCap', [], 0);
            end
        % RETURN: VIEW SELECTED CHANNELS
        case 'return'
            DisplaySelectedRows(hFig);
        % ESCAPE: CLEAR SELECTION
        case 'escape'
            bst_figures('SetSelectedRows', []);
        % CONTROL: SAVE BUTTON PRESS
        case 'control'
            setappdata(hFig, 'isControlKeyDown', true);
        % SHIFT: SAVE BUTTON PRESS
        case 'shift'
            setappdata(hFig, 'isShiftKeyDown', true);
        % OTHER
        otherwise
            % Not found: test based on the character that was generated
            if isfield(keyEvent, 'Character') && ~isempty(keyEvent.Character)
                switch(keyEvent.Character)
                    % PLUS/MINUS: GAIN CONTROL
                    case '+'
                        figure_timeseries('UpdateTimeSeriesFactor', hFig, 1.1);
                    case '-'
                        figure_timeseries('UpdateTimeSeriesFactor', hFig, .9091);
                end
            end
    end
    % Restore events
    if ~isempty(hFig) && ishandle(hFig)
        hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph')';
        set([hFig hAxes], 'BusyAction', 'queue');
    end
end


%% ===== GET DEFAULT FACTOR =====
function defaultFactor = GetDefaultFactor(Modality)
    global GlobalData
    if isempty(GlobalData.DataViewer.DefaultFactor)
        defaultFactor = 1;
    else
        iMod = find(cellfun(@(c)isequal(c,Modality), GlobalData.DataViewer.DefaultFactor(:,1)));
        if isempty(iMod)
            defaultFactor = 1;
        else
            defaultFactor = GlobalData.DataViewer.DefaultFactor{iMod,2};
        end
    end
end


%% ===== LINE CLICKED =====
function LineClickedCallback(hLine, ev)
    global GlobalData;
    % Get figure handle
    hFig = get(hLine, 'Parent');
    while ~strcmpi(get(hFig, 'Type'), 'figure') || isempty(hFig)
        hFig = get(hFig, 'Parent');
    end
    if isempty(hFig)
        return;
    end
    hAxes = get(hLine, 'Parent');
    setappdata(hFig, 'clickSource', []);
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    sFig = GlobalData.DataSet(iDS).Figure(iFig);
    % Get row indice
    iRow = find(sFig.Handles.hLines == hLine);
    if isempty(iRow)
        return
    end
    RowName = sFig.Handles.LinesLabels{iRow};
    % Get click type
    isRightClick = strcmpi(get(hFig, 'SelectionType'), 'alt');
    % Right click : display popup menu
    if isRightClick
        setappdata(hFig, 'clickSource', hAxes);
        DisplayFigurePopup(hFig, RowName);   
        setappdata(hFig, 'clickSource', []);
    % Left click: Select/unselect line
    else
        bst_figures('ToggleSelectedRow', RowName);
    end             
    % Update figure selection
    bst_figures('SetCurrentFigure', hFig, '2D');
    bst_figures('SetCurrentFigure', hFig, 'TF');
end


%% ===== DISPLAY SELECTED CHANNELS =====
% USAGE:  DisplaySelectedRows(hFig)
function DisplaySelectedRows(hFig)
    % Get selected rows
    RowNames = figure_timeseries('GetFigSelectedRows', hFig);
    if isempty(RowNames)
        return;
    end
    % Reset selection
    bst_figures('SetSelectedRows', []);
    % Get figure info
    TfInfo = getappdata(hFig, 'Timefreq');
    % Plot figure
    view_spectrum(TfInfo.FileName, TfInfo.DisplayMode, RowNames, 1);
end


%% ===== RESET VIEW =====
function ResetView(hFig)
    zoom out
end


%% ===== POPUP MENU =====
function DisplayFigurePopup(hFig, menuTitle)
    import java.awt.event.KeyEvent;
    import javax.swing.KeyStroke;
    import org.brainstorm.icon.*;
    global GlobalData;
    % If menuTitle not specified
    if (nargin < 2)
        menuTitle = '';
    end
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    % Get axes handles
    hAxes = getappdata(hFig, 'clickSource');
    if isempty(hAxes)
        return
    end
    % Get time freq information
    TfInfo = getappdata(hFig, 'Timefreq');
    TfFile = TfInfo.FileName;
    if isempty(TfFile)
        return;
    end
    % Get loaded information
    iTimefreq = bst_memory('GetTimefreqInDataSet', iDS, TfFile);
    % Create popup menu
    jPopup = java_create('javax.swing.JPopupMenu');
    % Menu title
    if ~isempty(menuTitle)
        jPopup.add(javax.swing.JLabel(['<HTML><BLOCKQUOTE><B>' menuTitle '</B></BLOCKQUOTE></HTML>']));
        jPopup.addSeparator();
    end
    
    % ==== DISPLAY OTHER FIGURES ====
    % Only for MEG and EEG time series
    if strcmpi(GlobalData.DataSet(iDS).Timefreq(iTimefreq).DataType, 'data')       
        % === View RECORDINGS ===
        if ~isempty(GlobalData.DataSet(iDS).DataFile)
            jItem = gui_component('MenuItem', jPopup, [], 'Recordings', IconLoader.ICON_TS_DISPLAY, [], @(h,ev)view_timeseries(GlobalData.DataSet(iDS).DataFile, GlobalData.DataSet(iDS).Figure(iFig).Id.Modality), []);
            jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_R, KeyEvent.CTRL_MASK));
        end
        % === View TOPOGRAPHY ===
        jItem = gui_component('MenuItem', jPopup, [], '2D Sensor cap', IconLoader.ICON_TOPOGRAPHY, [], @(h,ev)bst_call(@view_topography, TfFile, [], '2DSensorCap', [], 0), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_T, KeyEvent.CTRL_MASK));
        jPopup.addSeparator();
    end

    % === VIEW SELECTED ===
    jItem = gui_component('MenuItem', jPopup, [], 'View selected', IconLoader.ICON_SPECTRUM, [], @(h,ev)DisplaySelectedRows(hFig), []);
    jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_ENTER, 0)); % ENTER  
    % === RESET SELECTION ===
    jItem = gui_component('MenuItem', jPopup, [], 'Reset selection', IconLoader.ICON_SURFACE, [], @(h,ev)bst_figures('SetSelectedRows',[]), []);
    jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_ESCAPE, 0)); % ESCAPE
    jPopup.addSeparator();

    % ==== MENU: SELECTION ====
    % No time/freq bands
    if ~iscell(GlobalData.DataSet(iDS).Timefreq(iTimefreq).Freqs) && isempty(GlobalData.DataSet(iDS).Timefreq(iTimefreq).TimeBands)
        % Menu "Selection"
        switch(TfInfo.DisplayMode)
            case 'Spectrum',    strMenu = 'Frequency selection';
            case 'TimeSeries',  strMenu = 'Time selection';
        end
        jMenuSelection = gui_component('Menu', jPopup, [], strMenu, IconLoader.ICON_TS_SELECTION, [], [], []);
        % Set selection
        gui_component('MenuItem', jMenuSelection, [], 'Set selection manually...', IconLoader.ICON_TS_SELECTION, [], @(h,ev)SetFreqSelection(hFig), []);
        % Get current time selection
        GraphSelection = getappdata(hFig, 'GraphSelection');
        isSelection = ~isempty(GraphSelection) && ~any(isinf(GraphSelection(:)));
        if isSelection
            jMenuSelection.addSeparator();
            % === EXPORT TO DATABASE ===
            if ~strcmpi(TfInfo.DisplayMode, 'TimeSeries')
                gui_component('MenuItem', jMenuSelection, [], 'Export to database', IconLoader.ICON_SPECTRUM, [], @(h,ev)bst_call(@out_figure_timefreq, hFig, 'Database', 'Selection'), []);
            end
            % === EXPORT TO FILE ===
            gui_component('MenuItem', jMenuSelection, [], 'Export to file', IconLoader.ICON_TS_EXPORT, [], @(h,ev)bst_call(@out_figure_timefreq, hFig, [], 'Selection'), []);
            % === EXPORT TO MATLAB ===
            gui_component('MenuItem', jMenuSelection, [], 'Export to Matlab', IconLoader.ICON_MATLAB_EXPORT, [], @(h,ev)bst_call(@out_figure_timefreq, hFig, 'Variable', 'Selection'), []);
        end
        jPopup.addSeparator();
    end
    
    % ==== MENU: SNAPSHOT ====
    jMenuSave = gui_component('Menu', jPopup, [], 'Snapshots', IconLoader.ICON_SNAPSHOT, [], [], []);
        % === SAVE AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Save as image', IconLoader.ICON_SAVE, [], @(h,ev)bst_call(@out_figure_image, hFig), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_I, KeyEvent.CTRL_MASK));
        % === OPEN AS IMAGE ===
        jItem = gui_component('MenuItem', jMenuSave, [], 'Open as image', IconLoader.ICON_IMAGE, [], @(h,ev)bst_call(@out_figure_image, hFig, 'Viewer'), []);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_J, KeyEvent.CTRL_MASK));
        jMenuSave.addSeparator();
        % === EXPORT TO DATABASE ===
        gui_component('MenuItem', jMenuSave, [], 'Export to database (time-freq)', IconLoader.ICON_TIMEFREQ, [], @(h,ev)bst_call(@out_figure_timefreq, hFig, 'Database'), []);
        gui_component('MenuItem', jMenuSave, [], 'Export to database (matrix)',    IconLoader.ICON_MATRIX, [], @(h,ev)bst_call(@out_figure_timefreq, hFig, 'Database', 'Matrix'), []);
        % === EXPORT TO FILE ===
        gui_component('MenuItem', jMenuSave, [], 'Export to file', IconLoader.ICON_TS_EXPORT, [], @(h,ev)bst_call(@out_figure_timefreq, hFig, []), []);
        % === EXPORT TO MATLAB ===
        gui_component('MenuItem', jMenuSave, [], 'Export to Matlab', IconLoader.ICON_MATLAB_EXPORT, [], @(h,ev)bst_call(@out_figure_timefreq, hFig, 'Variable'), []);

    % ==== MENU: FIGURE ====    
    jMenuFigure = gui_component('Menu', jPopup, [], 'Figure', IconLoader.ICON_LAYOUT_SHOWALL, [], [], []);
        % Show Matlab controls
        isMatlabCtrl = ~strcmpi(get(hFig, 'MenuBar'), 'none') && ~strcmpi(get(hFig, 'ToolBar'), 'none');
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Matlab controls', IconLoader.ICON_MATLAB_CONTROLS, [], @(h,ev)bst_figures('ShowMatlabControls', hFig, ~isMatlabCtrl), []);
        jItem.setSelected(isMatlabCtrl);
        % Show plot edit toolbar
        isPlotEditToolbar = getappdata(hFig, 'isPlotEditToolbar');
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Plot edit toolbar', IconLoader.ICON_PLOTEDIT, [], @(h,ev)bst_figures('TogglePlotEditToolbar', hFig), []);
        jItem.setSelected(isPlotEditToolbar);
        % Dock figure
        isDocked = strcmpi(get(hFig, 'WindowStyle'), 'docked');
        jItem = gui_component('CheckBoxMenuItem', jMenuFigure, [], 'Dock figure', IconLoader.ICON_DOCK, [], @(h,ev)bst_figures('DockFigure', hFig, ~isDocked), []);
        jItem.setSelected(isDocked);
        jItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D, KeyEvent.CTRL_MASK)); 
           
    % Display Popup menu
    gui_popup(jPopup, hFig);
end


%% ===========================================================================
%  ===== PLOT FUNCTIONS ======================================================
%  ===========================================================================
%% ===== PLOT FIGURE =====
function UpdateFigurePlot(hFig, isForced)
    global GlobalData;
    if (nargin < 2) || isempty(isForced)
        isForced = 0;
    end
    % ===== GET DATA =====
    % Get figure description
    [hFig, iFig, iDS] = bst_figures('GetFigure', hFig);
    sFig = GlobalData.DataSet(iDS).Figure(iFig);
    % If spectrum: get current time only
    isSpectrum = strcmpi(sFig.Id.SubType, 'Spectrum');
    if isSpectrum
        TimeDef = 'CurrentTimeIndex';
    else
        TimeDef = [];
    end
    % Get data to plot
    [Time, Freqs, TfInfo, TF, RowNames, FullTimeVector, DataType] = figure_timefreq('GetFigureData', hFig, TimeDef);
    if isempty(TF)
        return;
    end
    % Row names
    if ~isempty(RowNames) && ischar(RowNames)
        RowNames = {RowNames};
    end
    % Line labels
    if iscell(RowNames)
        LinesLabels = RowNames;
    elseif isnumeric(RowNames)
        for i = 1:length(RowNames)
            LinesLabels{i} = num2str(RowNames(i));
        end
    end
    % Remove the first frequency bin (0) : SPECTRUM ONLY
    if isSpectrum && ~iscell(Freqs) && (size(TF,3)>1)
        iZero = find(Freqs == 0);
        if ~isempty(iZero)
            Freqs(iZero) = [];
            TF(:,:,iZero) = [];
        end
    end
    % Get figure time-freq info
    TfInfo   = getappdata(hFig, 'Timefreq');
    FigureId = getappdata(hFig, 'FigureId');
    
    % ===== GET GLOBAL MAXIMUM =====
    % If maximum is not defined yet
    if isempty(sFig.Handles.DataMinMax) || isForced
        sFig.Handles.DataMinMax = [min(TF(:)), max(TF(:))];
        % In case there are infinite values, due to the log10(0) operation that may happen: look only for non-empty values
        if any(isinf(sFig.Handles.DataMinMax))
            iNotInf = ~isinf(TF(:));
            sFig.Handles.DataMinMax = [min(TF(iNotInf)), max(TF(iNotInf))];
        end
    end

    % ===== X AXIS =====
    switch (TfInfo.DisplayMode)
        case 'TimeSeries'
            X = Time;
            XLegend = 'Time (s)';
        case 'Spectrum'
            X = Freqs;
            XLegend = 'Frequency (Hz)';
        otherwise
            error('Invalid display mode');
    end
    % Bands (time/freq), or linear axes
    if iscell(X)
        Xbands = process_tf_bands('GetBounds', X);
        X    = mean(Xbands,2);
        XLim = [min(Xbands(:)), max(Xbands(:))];
    else
        XLim = [X(1), X(end)];
    end
    if (length(XLim) ~= 2) || any(isnan(XLim)) || (XLim(2) <= XLim(1))
        disp('BST> Error: No data to display...');
        XLim = [0 1];
    end
    
    % ===== DISPLAY =====
    % Plot data in the axes
    PlotHandles = PlotAxes(hFig, iDS, X, XLim, TF, FigureId.Modality, TfInfo, sFig.Handles.DataMinMax, LinesLabels);
    hAxes = PlotHandles.hAxes;
    % Store initial XLim and YLim
    setappdata(hAxes, 'XLimInit', get(hAxes, 'XLim'));
    setappdata(hAxes, 'YLimInit', get(hAxes, 'YLim'));
    % Update figure list of handles
    GlobalData.DataSet(iDS).Figure(iFig).Handles = PlotHandles;
    % X Axis legend
    xlabel(hAxes, XLegend, ...
        'FontSize',    bst_get('FigFont'), ...
        'FontUnits',   'points', ...
        'Interpreter', 'none');
    
    % ===== SCALE BAR =====
    TsInfo = getappdata(hFig, 'TsInfo');
    % For column displays: add a scale display
    if strcmpi(TsInfo.DisplayMode, 'column')
        % Get figure background color
        bgColor = get(hFig, 'Color');
        % Create axes
        PlotHandles.hColumnScale = axes('Position', [0, 0, .01, .01]);
        set(PlotHandles.hColumnScale, ...
            'Interruptible', 'off', ...
            'BusyAction',    'queue', ...
            'Tag',           'AxesColumnScale', ...
            'YGrid',      'off', ...
            'XGrid',      'off', ...
            'XMinorGrid', 'off', ...
            'XTick',      [], ...
            'YTick',      [], ...
            'TickLength', [0,0], ...
            'Color',      bgColor, ...
            'XLim',       [0 1], ...
            'YLim',       get(hAxes, 'YLim'), ...
            'Box',        'off');
        % Update figure list of handles
        GlobalData.DataSet(iDS).Figure(iFig).Handles = PlotHandles;
    end
    % Create scale buttons
    figure_timeseries('CreateScaleButtons', iDS, iFig);
        
    % Resize callback if only one axes
    figure_timeseries('ResizeCallback', hFig, []);
    % Set current object/axes
    set(hFig, 'CurrentAxes', hAxes, 'CurrentObject', hAxes);
    % Save current zoom factor
    zoom reset
    % Update selected channels 
    figure_spectrum('SelectedRowChangedCallback', iDS, iFig);
end


%% ===== PLOT AXES =====
function PlotHandles = PlotAxes(hFig, iDS, X, XLim, TF, Modality, TfInfo, DataMinMax, LinesLabels)
    %global GlobalData;

    % ===== CREATE AXES =====
    % Look for existing axes
    hAxes = findobj(hFig, '-depth', 1, 'Tag', 'AxesGraph');
    % If nothing found: Create axes
    if isempty(hAxes)
        set(0, 'CurrentFigure', hFig);
        hAxes = axes;
        set(hAxes, 'Interruptible', 'off', ...
                   'BusyAction',    'queue', ...
                   'Tag',           'AxesGraph', ...
                   'YGrid',      'off', ...
                   'XGrid',      'off', 'XMinorGrid', 'off', ...
                   'XLim',       XLim, ...
                   'Box',        'on', ...
                   'FontName',   'Default', ...
                   'FontUnits',  'Points', ...
                   'FontWeight', 'Normal',...
                   'FontSize',   bst_get('FigFont'), ...
                   'Units',     'pixels', ...
                   'Visible',    'on');
        hold on;
    else
        cla(hAxes);
    end
    % Redimension TF according to what we want to display
    switch (TfInfo.DisplayMode)
        % Convert to [rows x time]
        case 'TimeSeries'
             TF = TF(:,:,1);
        % Convert to [rows x freq]
        case 'Spectrum'
             TF = reshape(TF(:,1,:), [size(TF,1), size(TF,3)]);
    end
    % Set color table for lines
    nLines = size(TF,1);
    if (nLines > 10)
        set(hAxes, 'ColorOrder', [.2 .2 .2]);
    else
        set(hAxes, 'ColorOrder', panel_scout('GetScoutsColorTable'));
    end
    % Create handles structure
    PlotHandles = db_template('DisplayHandlesTimeSeries');
    PlotHandles.hAxes = hAxes;
    PlotHandles.DataMinMax = DataMinMax;    

    % ===== SWITCH DISPLAY MODE =====
    TsInfo = getappdata(hFig, 'TsInfo');
    switch (lower(TsInfo.DisplayMode))
        case 'butterfly'
            PlotHandles = PlotAxesButterfly(hAxes, PlotHandles, TfInfo, X, TF, Modality, LinesLabels);
        case 'column'
            PlotHandles = PlotAxesColumn(hAxes, PlotHandles, TfInfo, X, TF, Modality, LinesLabels);
        otherwise
            error('Invalid display mode.');
    end
    % Lines labels
    PlotHandles.LinesLabels = LinesLabels;
    % Get lines initial colors
    for i = 1:length(PlotHandles.hLines)
        if (PlotHandles.hLines(i) ~= -1)
            PlotHandles.LinesColor(i,:) = get(PlotHandles.hLines(i), 'Color');
        end
    end

    % ===== FREQUENCY CURSOR =====
    % Plot freq cursor
    %if (GlobalData.DataSet(iDS).Measures.NumberOfSamples > 2)
        [PlotHandles.hCursor, PlotHandles.hTextCursor] = PlotCursor(hFig, hAxes);
    %end
end


%% ===== PLOT AXES BUTTERFLY =====
function PlotHandles = PlotAxesButterfly(hAxes, PlotHandles, TfInfo, X, TF, Modality, LinesLabels)
    % ===== NORMALIZE =====
    % Get data maximum
    Fmax = PlotHandles.DataMinMax;
    % Display power of 10 in the legend rather than in the axis
    strPow = '';
    if (Fmax(1) ~= Fmax(2))
        Fpow = round(log10(max(abs(Fmax))));
        if (Fpow < -3)
            Fpow = -Fpow;
            Fmax = Fmax * 10^Fpow;
            TF   = TF * 10^Fpow;
            strPow = sprintf(' * 10^{-%d}', Fpow);
        end
    else
        Fmax = [];
    end
    
    % ===== PLOT TIME SERIES =====
    % Plot lines
    ZData = 1.5;
    PlotHandles.hLines = line(X, TF', ZData * ones(size(TF)), ...
                              'Parent', hAxes);
    set(PlotHandles.hLines, 'Tag', 'DataLine');
    PlotHandles.iDispChannels = 1:size(TF,1);
    
    % ===== YLIM =====
    % Set display Factor
    PlotHandles.DisplayFactor = 1;
    % Get automatic YLim
    if ~isempty(Fmax) && (Fmax(1) ~= Fmax(2))
        % Use the first local maximum: ignores the huge range of high frequencies
        if any(strcmpi(TfInfo.Function, {'power', 'magnitude'}))
            TFmax = max(TF,[],1);
            iStart = find(diff(TFmax)>0,1);
            if ~isempty(iStart)
                Fmax(2) = max(TFmax(iStart:end));
            end
        end
        % Compute the scale
        margin = (Fmax(2) - Fmax(1)) * 0.02;
        YLim = PlotHandles.DisplayFactor * [Fmax(1), Fmax(2) + margin];
    else
        YLim = [-1, 1];
    end
    % Set axes legend for Y axis
    switch lower(TfInfo.Function)
        case 'power',      strAmp = ['Power   (signal units^2/Hz' strPow ')'];
        case 'magnitude',  strAmp = ['Magnitude   (signal units/sqrt(Hz)' strPow ')'];
        case 'log',        strAmp = ['Log-power   (dB/Hz' strPow ')'];
        case 'phase',      strAmp = 'Angle';
        otherwise,         strAmp = 'No units';
    end
    
    ylabel(hAxes, strAmp, ...
        'FontSize',    bst_get('FigFont'), ...
        'FontUnits',   'points', ...
        'Interpreter', 'tex');
    % Set Y ticks in auto mode
    set(hAxes, 'YLim',           YLim, ...
               'YTickMode',      'auto', ...
               'YTickLabelMode', 'auto');

    % ===== LINES LEGENDS =====
    % Only if less than 10 lines
    if ~isempty(LinesLabels) && (length(LinesLabels) <= 10) && ((length(LinesLabels) > 1) || ~isempty(LinesLabels{1}))
        if (length(LinesLabels) == 1) && (length(PlotHandles.hLines) > 1)
            [hLegend, hLegendObjects] = legend(PlotHandles.hLines(1), LinesLabels{1});
        else
            [hLegend, hLegendObjects] = legend(PlotHandles.hLines, LinesLabels{:});
        end
        set(findobj(hLegendObjects, 'Type', 'Text'), ...
            'FontSize',  bst_get('FigFont'), ...
            'FontUnits', 'points');
        set(hLegend, 'Tag', 'legend', 'Interpreter', 'none');
    end
           
    % ===== EXTRA LINES =====
    % Y=0 Line
    if (YLim(1) == 0)
        hLineY0 = line(get(hAxes,'XLim'), [0 0], [ZData ZData], 'Color', [0 0 0], 'Parent', hAxes);
    else
        hLineY0 = line(get(hAxes,'XLim'), [0 0], [ZData ZData], 'Color', .8*[1 1 1], 'Parent', hAxes);
    end
end


%% ===== PLOT AXES: COLUMN =====
function PlotHandles = PlotAxesColumn(hAxes, PlotHandles, TfInfo, X, TF, Modality, LinesLabels)
    ZData = 1.5;
    nLines = size(TF,1);
    % ===== DISPLAY SETUP =====
%     sMontage = panel_montage('GetCurrentMontage', Modality);
%     if ~isempty(sMontage) && ~isempty(sMontage.ChanNames) && ~isempty(Modality) && (Modality(1) ~= '$')
%         % Get channels that are selected for display
%         selChan = sMontage.ChanNames;
%         % Remove all the spaces
%         selChan = cellfun(@(c)c(c~=' '), selChan, 'UniformOutput', 0);
%         LinesLabels = cellfun(@(c)c(c~=' '), LinesLabels, 'UniformOutput', 0);
%         % Look for each of these selected channels in the list of loaded channels
%         iDispChan = [];
%         for i = 1:length(selChan)
%             iTmp = find(strcmpi(selChan{i}, LinesLabels));
%             % If channel was found: add it to the display list
%             if ~isempty(iTmp)
%                 iDispChan(end+1) = iTmp;
%             end
%         end
%         % Sort channels
%         %iDispChan = sort(iDispChan);
%         % If no channel displayed: display all
%         if isempty(iDispChan)
%             iDispChan = 1:nLines;
%         end
%     else
%         iDispChan = 1:nLines;
%     end
    iDispChan = 1:nLines;
    
    nDispChan = length(iDispChan);
    PlotHandles.iDispChannels = iDispChan;

    % ===== SPLIT IN BLOCKS =====
    % Normalized range of Y values
    YLim = [0, 1];
    % Data minumum/maximum
    Fmax = PlotHandles.DataMinMax;
    Frange = Fmax(2) - Fmax(1);
    % Subdivide Y-range in nDispChan blocks
    blockY = (YLim(2) - YLim(1)) / (nDispChan + 2);
    selChannelOffsets = blockY * (nDispChan:-1:1) + blockY / 2;
    % Build an offset list for ALL channels (unselected channels: offset = -10)
    PlotHandles.ChannelOffsets = -10 .* ones(nLines,1);
    PlotHandles.ChannelOffsets(iDispChan) = selChannelOffsets;
    % Normalize all channels to fit in one block only
    PlotHandles.DisplayFactor = blockY ./ Frange;
    % Add previous display factor
    PlotHandles.DisplayFactor = PlotHandles.DisplayFactor * GetDefaultFactor('spectrum');
    % Center each sensor line on its average over frequencies
    TF = bst_bsxfun(@minus, TF, mean(TF,2));
    % Apply final factor to recordings + Keep only the displayed lines
    TF = TF(iDispChan,:) .* PlotHandles.DisplayFactor;

    % ===== PLOT TIME SERIES =====
    % Add offset to each channel
    TF = bst_bsxfun(@plus, TF, PlotHandles.ChannelOffsets(iDispChan));
    % Initialize array of handles
    PlotHandles.hLines = -1 * ones(nLines,1);
    % Display time series
    PlotHandles.hLines(iDispChan) = line(X, TF', ZData*ones(size(TF)), 'Parent', hAxes);
    set(PlotHandles.hLines(iDispChan), 'Tag', 'DataLine');
    
    % ===== PLOT ZERO-LINES =====
    Xzeros = repmat(get(hAxes,'XLim'), [length(iDispChan), 1]);
    Yzeros = [PlotHandles.ChannelOffsets(iDispChan), PlotHandles.ChannelOffsets(iDispChan)];
    Zzeros = repmat(.5 * [1 1], [length(iDispChan), 1]);
    hLineY0 = line(Xzeros', Yzeros', Zzeros', ...
                   'Color', .9*[1 1 1], ...
                   'Parent', hAxes);

    % ===== CHANNELS LABELS ======
    if ~isempty(LinesLabels) && ~isempty(iDispChan)
        % Special case: If scout function is "All" 
        if (length(iDispChan) > 1) && (length(LinesLabels) == 1)
            Yticklabel = [];
        else
            Yticklabel = LinesLabels(iDispChan);
        end
        % Set Y Legend
        %iDispChan = sort(iDispChan,2,'descend');
        set(hAxes, 'YTickMode',      'manual', ...
                   'YTickLabelMode', 'manual', ...
                   'YTick',          flipdim(PlotHandles.ChannelOffsets(iDispChan), 1), ...
                   'Yticklabel',     flipdim(Yticklabel, 1));
    end
    % Set Y axis scale
    set(hAxes, 'YLim', YLim);
    % Remove axes legend for Y axis
    ylabel('');
end

%% ===== PLOT TIME CURSOR =====
function [hCursor,hTextCursor] = PlotCursor(hFig, hAxes)
    global GlobalData;
    ZData = 1.6;
    % Get display mode
    TfInfo = getappdata(get(hAxes,'Parent'), 'Timefreq');
    % Get current time
    switch (TfInfo.DisplayMode)
        case 'Spectrum'
            if iscell(GlobalData.UserFrequencies.Freqs)
                BandBounds = process_tf_bands('GetBounds', GlobalData.UserFrequencies.Freqs(GlobalData.UserFrequencies.iCurrentFreq, :));
                curX = mean(BandBounds);
            else
                curX = GlobalData.UserFrequencies.Freqs(GlobalData.UserFrequencies.iCurrentFreq);
            end
            textCursor = sprintf('%1.2f Hz', curX);
        case 'TimeSeries'
            curX = GlobalData.UserTimeWindow.CurrentTime;
            textCursor = sprintf('%1.4f s', curX);
    end
    YLim = get(hAxes, 'YLim');
    
    % ===== VERTICAL LINE =====
    hCursor = findobj(hAxes, '-depth', 1, 'Tag', 'Cursor');
    if isempty(hCursor)
        hCursor = line([curX curX], YLim, [ZData ZData], ...
                           'LineWidth', 1, ...  
                           'EraseMode','xor', ...
                           'Color',     'r', ...
                           'Tag',       'Cursor', ...
                           'Parent',    hAxes);
    else
        set(hCursor, 'XData', [curX curX], 'YData', YLim, 'ZData', [ZData ZData]);
    end
    % Get background color
    bgcolor = get(hFig, 'Color');

    % ===== TEXT CURSOR =====
    hTextCursor = findobj(hFig, '-depth', 1, 'Tag', 'TextCursor');
    if isempty(hTextCursor)
        % Create text object
        hTextCursor = uicontrol(...
            'Style',               'text', ...
            'String',              textCursor, ...
            'Units',               'Pixels', ...
            'HorizontalAlignment', 'left', ...
            'FontUnits',           'points', ...
            'FontSize',            bst_get('FigFont'), ...
            'FontWeight',          'bold', ...
            'ForegroundColor',     [0 0 0], ...
            'BackgroundColor',     bgcolor, ...
            'Parent',              hFig, ...
            'Tag',                'TextCursor', ...
            'Visible',             get(hFig, 'Visible'));
    else
        set(hTextCursor, 'String', textCursor);
    end
    
    % ===== SELECTION TEXT =====
    hTextTimeSel = findobj(hFig, '-depth', 1, 'Tag', 'TextTimeSel');
    if isempty(hTextTimeSel)
        hTextTimeSel = uicontrol(...
            'Style',               'text', ...
            'String',              'Selection', ...
            'Units',               'Pixels', ...
            'HorizontalAlignment', 'center', ...
            'FontUnits',           'points', ...
            'FontSize',            bst_get('FigFont') + 1, ...
            'FontWeight',          'normal', ...
            'ForegroundColor',     [0 0 0], ...
            'BackgroundColor',     bgcolor, ...
            'Parent',              hFig, ...
            'Tag',                 'TextTimeSel', ...
            'Visible',             'off');
    end
end




