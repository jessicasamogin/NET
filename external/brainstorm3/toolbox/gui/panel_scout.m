function varargout = panel_scout(varargin)
% PANEL_SCOUT: Create a panel to add/remove/edit scouts attached to a given 3DViz figure.
% 
% USAGE:  bstPanelNew = panel_scout('CreatePanel')
%                       panel_scout('UpdatePanel')
%                       panel_scout('UpdateScoutsList')
%                       panel_scout('UpdateScoutProperties')
%                       panel_scout('CurrentFigureChanged_Callback')
%                       panel_scout('SetCurrentSurface', newSurfaceFile)
% [sScouts, sSurf, iSurf] = panel_scout('GetScouts', SurfaceFile)
% [sScouts, sSurf, iSurf] = panel_scout('GetScouts', iScouts)
% [sScouts, sSurf, iSurf] = panel_scout('GetScouts')
%    [sScout, iScout] = panel_scout('GetScoutWithHandle', hScout)
%                       panel_scout('SetScouts', SurfaceFile=CurrentSurface, iScouts=[], sScouts)
%                       panel_scout('SetScouts', SurfaceFile=CurrentSurface, 'Add', sScouts)
%  [sScouts, iScouts] = panel_scout('GetSelectedScouts')
%    [sScout, iScout] = panel_scout('CreateScout', newVertices, newSeed, SurfaceFile)
%    [sScout, iScout] = panel_scout('CreateScout', newVertices, newSeed)
%                       panel_scout('SetSelectedScouts', iSelScouts)
%                       panel_scout('SetSelectionState', isSelected)
%                       panel_scout('CreateScoutMouse', hFig)
%                       panel_scout('EditScoutSurface')
%                       panel_scout('EditScoutMri', 'Add')   : Create a new scout using the MRI
%                       panel_scout('EditScoutMri', iScout)  : Edit a given scout
%                       panel_scout('EditScoutMri')          : Edit the first of the currently selected scout
%                       panel_scout('EditScoutLabel')
%                       panel_scout('EditScoutsSize', action)
%                       panel_scout('EditScoutsColor', newColor)
%                       panel_scout('PlotScouts', iScouts, hFigures)   : Plot some scouts
%                       panel_scout('PlotScouts')                      : Plot all scouts
%                       panel_scout('RemoveScoutsFromFigure', hFig)
%                       panel_scout('RemoveScouts', iScouts) : remove a list of scouts
%                       panel_scout('RemoveScouts', )        : remove the scouts selected in the JList 
%                       panel_scout('JoinScouts')
%                       panel_scout('UpdateScoutsVertices', SurfaceFile)
%                       panel_scout('SaveScouts')
%                       panel_scout('LoadScouts')
%                       panel_scout('ForwardModelForScout')
%          ColorTable = panel_scout('GetScoutsColorTable')
%       ScoutsOptions = panel_scout('GetScoutsOptions') 

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

macro_methodcall;
end


%% ===== CREATE PANEL =====
function bstPanelNew = CreatePanel() %#ok<DEFNU>
    panelName = 'Scout';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    import org.brainstorm.icon.*;
    % Create tools panel
    jPanelNew = gui_component('Panel');
    TB_DIM = Dimension(25,25);

    % ===== TOOLBAR =====
    jMenuBar = gui_component('MenuBar', jPanelNew, BorderLayout.NORTH);
        jToolbar = gui_component('Toolbar', jMenuBar);
        jToolbar.setPreferredSize(TB_DIM);
        jToolbar.setOpaque(0);
        % First buttons
        jButtonAddScout = gui_component('ToolbarToggle', jToolbar,[],[], IconLoader.ICON_SCOUT_NEW, ...
            ['<HTML><B>Create scout</B>:<BR><BLOCKQUOTE> - Select this button<BR> - Click on the cortex surface</BLOCKQUOTE>' ...
             '<B>Add vertex to scout</B>:<BR><BLOCKQUOTE> - Select this button<BR> - Select the scout to edit<BR> - Click on the vertex to add</BLOCKQUOTE>', ...
             '<B>Remove vertex from scout</B>:<BR><BLOCKQUOTE> - Select this button<BR> - Select the scout to edit<BR> - Hold the <B>SHIFT</B> key<BR> - Click on the vertex to remove</BLOCKQUOTE>'], @ButtonAddScout);
        gui_component('ToolbarButton', jToolbar,[],[], IconLoader.ICON_TS_DISPLAY, '<HTML><B>Display scouts time series</B>&nbsp;&nbsp;&nbsp;&nbsp;[ENTER]</HTML>', @(h,ev)ViewTimeSeries());        
        % Menu: Atlas
        jMenuAtlas = gui_component('Menu', jMenuBar, [], 'Atlas', IconLoader.ICON_MENU, [], [], 11);
        jMenuAtlas.setBorder(BorderFactory.createEmptyBorder(0,2,0,2));
        % Menu: Scout
        jMenuScout = gui_component('Menu', jMenuBar, [], 'Scout', IconLoader.ICON_MENU, [], [], 11);
        jMenuScout.setBorder(BorderFactory.createEmptyBorder(0,2,0,2));
        % Menu: Sources
        jMenuSources = gui_component('Menu', jMenuBar, [], 'Sources', IconLoader.ICON_MENU, [], [], 11);
        jMenuSources.setBorder(BorderFactory.createEmptyBorder(0,2,0,2));

    % ===== PANEL MAIN =====
    jPanelMain = gui_component('Panel');
    jPanelMain.setBorder(BorderFactory.createEmptyBorder(7,7,7,7));
        % ===== VERTICAL TOOLBAR =====
        jToolbar2 = gui_component('Toolbar', jPanelMain, BorderLayout.EAST);
        jToolbar2.setOrientation(jToolbar2.VERTICAL);
        jToolbar2.setPreferredSize(Dimension(26,20));
        jToolbar2.setBorder([]);
            % Load/save
            gui_component('ToolbarButton', jToolbar2,[],[], {IconLoader.ICON_FOLDER_OPEN, TB_DIM}, 'Load atlas', @(h,ev)LoadScouts());
            gui_component('ToolbarButton', jToolbar2,[],[], {IconLoader.ICON_SAVE, TB_DIM},        'Save selected scouts to file', @(h,ev)SaveScouts());
            % Selection of displayed scouts
            jToolbar2.addSeparator();
            jRadioShowAll  = gui_component('ToolbarToggle', jToolbar2, [], [], {IconLoader.ICON_SCOUT_ALL, TB_DIM}, 'Show all the scouts', @SetShowSelection);
            jRadioShowSel  = gui_component('ToolbarToggle', jToolbar2, [], [], {IconLoader.ICON_SCOUT_SEL, TB_DIM}, 'Show only the selected scouts', @SetShowSelection);
            jRadioShowAll.setSelected(1);
            % Selection of scouts parts to display
            jToolbar2.addSeparator();
            jCheckContour = gui_component('ToolbarToggle', jToolbar2, [], [], {IconLoader.ICON_SCOUT_CONTOUR, TB_DIM}, 'Show/hide the contour lines', @(h,ev)UpdateScoutsDisplay('all'));
            jCheckText    = gui_component('ToolbarToggle', jToolbar2, [], [], {IconLoader.ICON_SCOUT_TEXT, TB_DIM},    'Show/hide the scouts labels', @(h,ev)UpdateScoutsDisplay('all'));
            jCheckContour.setSelected(1);
            jCheckText.setSelected(1);
            % Transparency of the scouts
            jToolbar2.addSeparator();
            jButtonGroup = ButtonGroup();
            jCheckTransp0   = gui_component('ToolbarToggle', jToolbar2, [], [], {IconLoader.ICON_SCOUT_TR0,   jButtonGroup, TB_DIM}, 'Scout patch: opaque', @(h,ev)SetScoutTransparency(0));
            jCheckTransp70  = gui_component('ToolbarToggle', jToolbar2, [], [], {IconLoader.ICON_SCOUT_TR70,  jButtonGroup, TB_DIM}, 'Scout patch: transparent', @(h,ev)SetScoutTransparency(.7));
            jCheckTransp100 = gui_component('ToolbarToggle', jToolbar2, [], [], {IconLoader.ICON_SCOUT_TR100, jButtonGroup, TB_DIM}, 'Scout patch: none', @(h,ev)SetScoutTransparency(1));
            jCheckTransp70.setSelected(1);
            jToolbar2.addSeparator();
            % Display region colors
            jCheckRegionColor = gui_component('ToolbarToggle', jToolbar2, [], [], IconLoader.ICON_LOBE, 'Identify the regions with colors', @ButtonRegionCallback);
            % Center MRI on scouts
            gui_component('ToolbarButton', jToolbar2, [], [], {IconLoader.ICON_VIEW_SCOUT_IN_MRI, TB_DIM}, 'Center MRI on scout', @CenterMriOnScout);
        % ===== FIRST PART =====
        jPanelFirstPart = gui_component('Panel');
            % ===== Atlas list =====
            jPanelAtlas = gui_component('Panel');
                % Combo box to select the current protocol
                jComboAtlas = gui_component('ComboBox', jPanelAtlas, BorderLayout.NORTH, [], [], [], [], []);
                jComboAtlas.setFocusable(0);
                jComboAtlas.setMaximumRowCount(15);
                % ComboBox change selection callback
                jModel = jComboAtlas.getModel();
                java_setcb(jModel, 'ContentsChangedCallback', @ComboAtlasChanged_Callback);
            jPanelFirstPart.add(jPanelAtlas, BorderLayout.CENTER);

            % ===== Scouts list =====
            jPanelScoutsList = gui_component('Panel');
                jBorder = BorderFactory.createTitledBorder('');
                jBorder.setTitleFont(bst_get('Font', 11));
                jPanelScoutsList.setBorder(jBorder);
                % Scouts list
                jListScouts = java_create('org.brainstorm.list.BstClusterList');
                jListScouts.setCellRenderer(java_create('org.brainstorm.list.BstClusterListRenderer'));
                jListScouts.setBackground(Color(.9,.9,.9));
                java_setcb(jListScouts, ...
                    'ValueChangedCallback', @ScoutsListValueChanged_Callback, ...
                    'KeyTypedCallback',     @ScoutsListKeyTyped_Callback, ...
                    'MouseClickedCallback', @ScoutsListClick_Callback);
                jPanelScrollList = JScrollPane();
                jPanelScrollList.getLayout.getViewport.setView(jListScouts);
                jPanelScrollList.setBorder([]);
                jPanelScoutsList.add(jPanelScrollList);
            jPanelAtlas.add(jPanelScoutsList, BorderLayout.CENTER);
        jPanelMain.add(jPanelFirstPart);

        jPanelBottom = gui_river([0,0], [0,0,0,0]);
            % ===== Scouts options panel =====
            jPanelScoutOptions = gui_river([0,3], [0,5,10,3], 'Scout size');
                % Scout growth            
                gui_component('button', jPanelScoutOptions,[], '<<', {Insets(0,0,0,0), Dimension(26,20)}, 'Decrease scout size',                   @(h,ev)EditScoutsSize('Shrink'));
                gui_component('button', jPanelScoutOptions,[], '<',  {Insets(0,0,0,0), Dimension(22,20)}, 'Decrease scout size (only one vertex)', @(h,ev)EditScoutsSize('Shrink1'));
                gui_component('button', jPanelScoutOptions,[], '>',  {Insets(0,0,0,0), Dimension(22,20)}, 'Increase scout size (only one vertex)', @(h,ev)EditScoutsSize('Grow1'));
                gui_component('button', jPanelScoutOptions,[], '>>', {Insets(0,0,0,0), Dimension(26,20)}, 'Increase scout size',                   @(h,ev)EditScoutsSize('Grow'));
                % Separator
                gui_component('label', jPanelScoutOptions, [], '  ');
                % Constrained to data
                jToggleConst = gui_component('toggle', jPanelScoutOptions,'tab hfill', 'Constrained', {Insets(0,0,0,0), Dimension(10,20)}, 'Constrain patch growth to vertices with data above threshold.');
                % Scout size in vertices/area
                %gui_component('Label', jPanelScoutOptions, 'br', 'Number of vertices:');
                jLabelScoutSize = gui_component('Label', jPanelScoutOptions, 'br hfill', '  No scout selected');
                jLabelAreaSize  = gui_component('Label', jPanelScoutOptions, '', ' ');
            jPanelBottom.add('hfill', jPanelScoutOptions);
                
            % ===== TIME SERIES OPTIONS =====
            jPanelDisplay = gui_river([0,1], [2,4,4,0], 'Time series options');
                % Add extra space when not on a Mac
                if strncmp(computer,'MAC',3)
                    strSpace = '';
                else
                    strSpace = '   ';
                end
                % OPTIONS: Overlay scouts/conditions
                gui_component('Label', jPanelDisplay, 'br', ['Overlay:' strSpace]);
                jCheckOverlayScouts     = gui_component('CheckBox', jPanelDisplay, 'tab', 'Scouts',     Insets(0,0,0,0));
                jCheckOverlayConditions = gui_component('CheckBox', jPanelDisplay, 'tab', 'Conditions', Insets(0,0,0,0));
                % Absolute values
                gui_component('Label', jPanelDisplay, 'br', ['Values:' strSpace]);
                jButtonGroup = ButtonGroup();
                jRadioAbsolute = gui_component('Radio', jPanelDisplay, 'tab', 'Absolute', {Insets(0,0,0,0), jButtonGroup});
                jRadioRelative = gui_component('Radio', jPanelDisplay, 'tab', 'Relative', {Insets(0,0,0,0), jButtonGroup});
                jRadioAbsolute.setSelected(1);
            jPanelBottom.add('br hfill', jPanelDisplay);
            
        jPanelMain.add(jPanelBottom, BorderLayout.SOUTH)
    jPanelNew.add(jPanelMain, BorderLayout.CENTER);
    
    % Create the BstPanel object that is returned by the function
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct('jComboAtlas',           jComboAtlas, ...
                                  'jPanelScoutsList',      jPanelScoutsList, ...
                                  'jToolbar',              jToolbar, ...
                                  'jToolbar2',             jToolbar2, ...
                                  'jMenuBar',              jMenuBar, ...
                                  'jMenuAtlas',            jMenuAtlas, ...
                                  'jMenuScout',            jMenuScout, ...
                                  'jMenuSources',          jMenuSources, ...
                                  'jButtonAddScout',       jButtonAddScout, ...
                                  'jRadioAbsolute',        jRadioAbsolute, ...
                                  'jRadioRelative',        jRadioRelative, ...
                                  'jPanelScoutOptions',    jPanelScoutOptions, ...
                                  'jPanelDisplay',         jPanelDisplay, ...
                                  'jLabelScoutSize',       jLabelScoutSize, ...
                                  'jLabelAreaSize',        jLabelAreaSize, ...
                                  'jRadioShowSel',         jRadioShowSel, ...
                                  'jRadioShowAll',         jRadioShowAll, ...
                                  'jToggleConst',          jToggleConst, ...
                                  'jCheckContour',         jCheckContour, ...
                                  'jCheckText',               jCheckText, ...
                                  'jCheckTransp100',          jCheckTransp100, ...
                                  'jCheckTransp70',           jCheckTransp70, ...
                                  'jCheckTransp0',            jCheckTransp0, ...
                                  'jCheckRegionColor',        jCheckRegionColor, ...
                                  'jCheckOverlayScouts',      jCheckOverlayScouts, ...
                                  'jCheckOverlayConditions',  jCheckOverlayConditions, ...
                                  'jListScouts',                jListScouts));
                              
    
                              
%% =================================================================================
%  === INTERNAL CALLBACKS  =========================================================
%  =================================================================================
    %% ===== BUTTON: ADD SCOUT =====
    function ButtonAddScout(h,ev)
        % Prevent edition of read-only atlas
        if isAtlasReadOnly()
            SetSelectionState(0);
        elseif (nargin == 2) && ~isempty(ev)
            SetSelectionState(ev.getSource.isSelected());
        else
            SetSelectionState(1);
        end
    end
        
    %% ===== ATLAS SELECTION =====
    function ComboAtlasChanged_Callback(varargin)
        % Get selected item in the combo box
        jItem = jComboAtlas.getSelectedItem();
        if isempty(jItem)
            return
        end
        % Select protocol
        SetCurrentAtlas(jItem.getUserData());
    end

    %% ===== LIST SELECTION CHANGED CALLBACK =====
    function ScoutsListValueChanged_Callback(h, ev)
        if ~ev.getValueIsAdjusting()
            % Update panel "Scouts" fields
            UpdateScoutProperties();
            % Get scouts display options
            ScoutsOptions = GetScoutsOptions();
            if isempty(ScoutsOptions)
                return;
            end
            % Display/hide scouts
            if strcmpi(ScoutsOptions.showSelection, 'select')
                bst_progress('start', 'Selection changed', 'Updating display...');
                % Update structure alpha (display only selected Structures)
                UpdateStructureAlpha();
                % Display only selected scouts
                UpdateScoutsDisplay('current');
                bst_progress('stop');
            end
        end
    end

    %% ===== LIST KEY TYPED CALLBACK =====
    function ScoutsListKeyTyped_Callback(h, ev)
        switch(uint8(ev.getKeyChar()))
            % DELETE
            case ev.VK_DELETE
                RemoveScouts();
            case ev.VK_ENTER
                view_scouts();
            case uint8('+')
                EditScoutsSize('Grow1');
            case uint8('-')
                EditScoutsSize('Shrink1');
            case ev.VK_ESCAPE
                SetSelectedScouts(0);
        end
    end

    %% ===== LIST CLICK CALLBACK =====
    function ScoutsListClick_Callback(h, ev)
        % If DOUBLE CLICK
        if (ev.getClickCount() == 2)
            % Rename selection
            EditScoutLabel();
        end
    end
    %% ===== BUTTON: REGION COLOR =====
    function ButtonRegionCallback(h, ev)
        % Update scouts list
        UpdateScoutsList();
        % Update scouts
        UpdateScoutsDisplay('all');
    end
end
                   


%% =================================================================================
%  === EXTERNAL PANEL CALLBACKS  ===================================================
%  =================================================================================
%% ===== UPDATE CALLBACK =====
function UpdatePanel()
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Get current scouts
    [sScouts, sSurf] = GetScouts();
    % Update atlas list
    UpdateAtlasList(sSurf);
    % If a surface is available for current figure
    if ~isempty(sSurf)
        gui_enable([ctrl.jPanelScoutsList, ctrl.jPanelScoutOptions, ctrl.jPanelDisplay, ctrl.jToolbar, ctrl.jToolbar2, ctrl.jMenuBar], 1);
        ctrl.jListScouts.setBackground(java.awt.Color(1,1,1));
    % Else : no figure associated with the panel : disable all controls
    else
        gui_enable([ctrl.jPanelScoutsList, ctrl.jPanelScoutOptions, ctrl.jPanelDisplay, ctrl.jToolbar, ctrl.jToolbar2, ctrl.jMenuBar], 0);
        ctrl.jListScouts.setBackground(java.awt.Color(.9,.9,.9));
        ctrl.jButtonAddScout.setSelected(0);
    end
    % Update scouts JList
    UpdateScoutsList();
    % Update menus
    if ~isempty(sSurf) && ~isempty(sSurf.Atlas) && ~isempty(sSurf.iAtlas) && (sSurf.iAtlas <= length(sSurf.Atlas))
        UpdateMenus(sSurf.Atlas(sSurf.iAtlas));
    end
end


%% ===== SHOW MENU =====
function UpdateMenus(sAtlas)
    import org.brainstorm.icon.*;
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Get atlas property
    isReadOnly = isAtlasReadOnly(sAtlas, 0);
    
    % === MENU: ATLAS ===
    jMenu = ctrl.jMenuAtlas;
    % Remove all previous menus
    jMenu.removeAll();
    % Menu: New atlas
    jMenuNew = gui_component('Menu', jMenu, [], 'New atlas', IconLoader.ICON_ATLAS, [], [], []);
        gui_component('MenuItem', jMenuNew, [], 'Empty atlas', IconLoader.ICON_ATLAS, [], @(h,ev)SetAtlas([], 'Add'));
        jMenuNew.addSeparator();
        gui_component('MenuItem', jMenuNew, [], 'Copy atlas',            IconLoader.ICON_COPY, [], @(h,ev)CreateAtlasSelected(1,0), []);
        gui_component('MenuItem', jMenuNew, [], 'Copy selected scouts',  IconLoader.ICON_COPY, [], @(h,ev)CreateAtlasSelected(0,0), []);
        % Create an "Inverse" atlas
        if ~strcmpi(sAtlas.Name, 'Source model')
            jMenuNew.addSeparator();
            gui_component('MenuItem', jMenuNew, [], 'Source modeling options', IconLoader.ICON_RESULTS, [], @(h,ev)CreateAtlasInverse());
        end
    jMenu.addSeparator();
    gui_component('MenuItem', jMenu, [], 'Load atlas...', IconLoader.ICON_FOLDER_OPEN, [], @(h,ev)LoadScouts(), []);
    if ~isReadOnly
        gui_component('MenuItem', jMenu, [], 'Rename atlas',  IconLoader.ICON_EDIT,        [], @(h,ev)EditAtlasLabel(), []);
        gui_component('MenuItem', jMenu, [], 'Delete atlas',  IconLoader.ICON_DELETE,      [], @(h,ev)RemoveAtlas(), []);
        jMenu.addSeparator();
        gui_component('MenuItem', jMenu, [], 'Add scouts to atlas...', IconLoader.ICON_FOLDER_OPEN, [], @(h,ev)LoadScouts([],0), []);
    end
    jMenu.addSeparator();
    gui_component('MenuItem', jMenu, [], 'Subdivide atlas',           IconLoader.ICON_ATLAS, [], @(h,ev)SubdivideScouts(1), []);
    gui_component('MenuItem', jMenu, [], 'Subdivide selected scouts', IconLoader.ICON_ATLAS, [], @(h,ev)SubdivideScouts(0), []);
    % Menu: Clustering
    jMenuCluster = gui_component('Menu', jMenu, [], 'Surface clustering',      IconLoader.ICON_ATLAS, [], [], []);
        gui_component('MenuItem', jMenuCluster, [], 'Random',     IconLoader.ICON_ATLAS, [], @(h,ev)CreateAtlasCluster(), []);
        jMenuCluster.addSeparator();
        gui_component('MenuItem', jMenuCluster, [], 'Maximum leadfield [under development]',  IconLoader.ICON_ATLAS, [], @(h,ev)CreateMLCCluster(), []);
        gui_component('MenuItem', jMenuCluster, [], 'Multiresolution [under development]',    IconLoader.ICON_ATLAS, [], @(h,ev)CreateMRACluster(), []);
        gui_component('MenuItem', jMenuCluster, [], 'Functional clustering [under development]',    IconLoader.ICON_ATLAS, [], @(h,ev)CreateFunctionalCluster(), []);
    jMenu.addSeparator();
    gui_component('MenuItem', jMenu, [], 'Save modifications', IconLoader.ICON_SAVE, 'Force all the recent modifications to be saved to the surface file', @(h,ev)SaveModifications(), []);
    gui_component('MenuItem', jMenu, [], 'Undo all modifications', IconLoader.ICON_ARROW_LEFT, 'Revert back to the version currently saved in the surface file', @(h,ev)Undo(), []);

    % === MENU: SCOUT ===
    jMenu = ctrl.jMenuScout;
    % Remove all previous menus
    jMenu.removeAll();
    if ~isReadOnly
        gui_component('MenuItem', jMenu, [], 'Add vertices', IconLoader.ICON_SCOUT_NEW,         [], @EditScoutSurface, []);
        gui_component('MenuItem', jMenu, [], 'Edit in MRI',  IconLoader.ICON_EDIT_SCOUT_IN_MRI, [], @(h,ev)EditScoutMri(), []);
        jMenu.addSeparator();
    end
    % Menu: Set cluster function
    if strcmpi(sAtlas.Name, 'Source model')
        gui_component('Menu', jMenu, [], 'Set modeling options', IconLoader.ICON_PROPERTIES, [], @(h,ev)CreateMenuInverse(ev.getSource()), []);
    else
        gui_component('Menu', jMenu, [], 'Set function', IconLoader.ICON_PROPERTIES, [], @(h,ev)CreateMenuFunction(ev.getSource()), []);
        if ~isReadOnly
            gui_component('Menu', jMenu, [], 'Set region', IconLoader.ICON_PROPERTIES, [], @(h,ev)CreateMenuRegion(ev.getSource()), []);
        end
    end
    jMenu.addSeparator();
    gui_component('MenuItem', jMenu, [], 'Rename',       IconLoader.ICON_EDIT,    [], @EditScoutLabel, []);
    gui_component('MenuItem', jMenu, [], 'Set color',    IconLoader.ICON_COLOR_SELECTION, [], @(h,ev)EditScoutsColor, []);
    if ~isReadOnly
        gui_component('MenuItem', jMenu, [], 'Delete',       IconLoader.ICON_DELETE,  [], @(h,ev)RemoveScouts, []);
        gui_component('MenuItem', jMenu, [], 'Merge',        IconLoader.ICON_FUSION,  [], @JoinScouts, []);
        jMenu.addSeparator();
    end
    gui_component('MenuItem', jMenu, [], 'Export to Matlab', IconLoader.ICON_MATLAB_EXPORT, [], @(h,ev)ExportScoutsToMatlab(), []);
    if ~isReadOnly
        gui_component('MenuItem', jMenu, [], 'Import from Matlab', IconLoader.ICON_MATLAB_IMPORT, [], @(h,ev)ImportScoutsFromMatlab(), []);
    end
    jMenu.addSeparator();
    jMenuSurf = gui_component('Menu', jMenu, [], 'Edit surface', IconLoader.ICON_SURFACE_CORTEX, [], [], []);
        gui_component('MenuItem', jMenuSurf, [], 'Remove selected scouts',    IconLoader.ICON_SURFACE_CORTEX, [], @(h,ev)NewSurface(0), []);
        gui_component('MenuItem', jMenuSurf, [], 'Keep only selected scouts', IconLoader.ICON_SURFACE_CORTEX, [], @(h,ev)NewSurface(1), []);

    % === MENU SOURCES ===
    jMenu = ctrl.jMenuSources;
    % Remove all previous menus
    jMenu.removeAll();
    if ~isReadOnly
        gui_component('MenuItem', jMenu, [], 'Correlation with sensor (new scout)', IconLoader.ICON_FIND_MAX, [], @CreateScoutCorr, []);
        gui_component('MenuItem', jMenu, [], 'Expand with correlation (selected scout)', IconLoader.ICON_RESIZE, 'Expand scout based on correlation with other sources.', @ExpandWithCorrelation, []);
        jMenu.addSeparator();
        gui_component('MenuItem', jMenu, [], 'Maximal value (new scout)', IconLoader.ICON_FIND_MAX, [], @(h,ev)CreateScoutMax(), []);
        gui_component('MenuItem', jMenu, [], 'Maximal value (selected scout)', IconLoader.ICON_FIND_MAX, [], @EditScoutMax, []);
        jMenu.addSeparator();
    end
    gui_component('MenuItem', jMenu, [], 'Simulate recordings', IconLoader.ICON_EEG_NEW, ['<HTML><B>Simulation: Forward model of selected scouts</B>:<BR>' ...
                                        '<BLOCKQUOTE>Simulate the scalp data that would be recorded if<BR>only the selected cortex region was activated.<BR><BR>' ...
                                        'If no scout is selected: simulate recordings produced<BR>by the activity of the whole cortex.</BLOCKQUOTE></HTML>'], @ForwardModelForScout, []);

end
    
%% ===== CREATE MENU: FUNCTION =====
function CreateMenuFunction(jMenu)
    % Remove all previous menus
    jMenu.removeAll();
    % Get selected scouts
    sScouts = GetSelectedScouts();
    if isempty(sScouts)
        return;
    end
    % List the functions
    jMenuMean = gui_component('RadioMenuItem', jMenu, [], 'Mean',       [], [], @(h,ev)SetScoutFunction('Mean'), []);
    jMenuPca  = gui_component('RadioMenuItem', jMenu, [], 'PCA',        [], [], @(h,ev)SetScoutFunction('PCA'), []);
    jMenuFast = gui_component('RadioMenuItem', jMenu, [], 'FastPCA',    [], [], @(h,ev)SetScoutFunction('FastPCA'), []);
    jMenuNorm = gui_component('RadioMenuItem', jMenu, [], 'Mean(norm)', [], [], @(h,ev)SetScoutFunction('Mean_norm'), []);
    jMenuMax  = gui_component('RadioMenuItem', jMenu, [], 'Max',        [], [], @(h,ev)SetScoutFunction('Max'), []);
    jMenuPow  = gui_component('RadioMenuItem', jMenu, [], 'Power',      [], [], @(h,ev)SetScoutFunction('Power'), []);
    jMenuAll  = gui_component('RadioMenuItem', jMenu, [], 'All',        [], [], @(h,ev)SetScoutFunction('All'), []);
    % Get the selected functions
    allFun = unique({sScouts.Function});
    if (length(allFun) > 1)
        return;
    end
    % Select the function used by selected scouts
    switch allFun{1}
        case 'Mean',      jMenuMean.setSelected(1);
        case 'PCA',       jMenuPca.setSelected(1);
        case 'FastPCA',   jMenuFast.setSelected(1);
        case 'Mean_norm', jMenuNorm.setSelected(1);
        case 'Max',       jMenuMax.setSelected(1);
        case 'Power',     jMenuPow.setSelected(1);
        case 'All',       jMenuAll.setSelected(1);
    end
end


%% ===== CREATE MENU: FUNCTION =====
function CreateMenuRegion(jMenu)
    % Remove all previous menus
    jMenu.removeAll();
    % Get selected scouts
    sScouts = GetSelectedScouts();
    if isempty(sScouts)
        return;
    end
    % Hemisphere
    jMenuLeft  = gui_component('RadioMenuItem', jMenu, [], 'Left',  [], [], @(h,ev)SetScoutRegion('L.'), []);
    jMenuRight = gui_component('RadioMenuItem', jMenu, [], 'Right',  [], [], @(h,ev)SetScoutRegion('R.'), []);
    jMenu.addSeparator();
    % Region
    jMenuPF = gui_component('RadioMenuItem', jMenu, [], 'Prefrontal',  [], [], @(h,ev)SetScoutRegion('.PF'), []);
    jMenuF  = gui_component('RadioMenuItem', jMenu, [], 'Frontal',     [], [], @(h,ev)SetScoutRegion('.F'), []);
    jMenuC  = gui_component('RadioMenuItem', jMenu, [], 'Central',     [], [], @(h,ev)SetScoutRegion('.C'), []);
    jMenuP  = gui_component('RadioMenuItem', jMenu, [], 'Pariental',   [], [], @(h,ev)SetScoutRegion('.P'), []);
    jMenuT  = gui_component('RadioMenuItem', jMenu, [], 'Temporal',    [], [], @(h,ev)SetScoutRegion('.T'), []);
    jMenuO  = gui_component('RadioMenuItem', jMenu, [], 'Occipital',   [], [], @(h,ev)SetScoutRegion('.O'), []);
    jMenuL  = gui_component('RadioMenuItem', jMenu, [], 'Limbic',      [], [], @(h,ev)SetScoutRegion('.L'), []);
    jMenu.addSeparator();
    gui_component('MenuItem', jMenu, [], 'Custom region...',   [], [], @(h,ev)SetScoutRegion(), []);
    % Get the selected functions
    allHemi = {};
    allRegions = {};
    for i = 1:length(sScouts)
        if (length(sScouts(i).Region) >= 1)
            allHemi = union(allHemi, {sScouts(i).Region(1)});
        end
        if (length(sScouts(i).Region) >= 3) && strcmpi(sScouts(i).Region(2:3), 'PF')
            allRegions = union(allRegions, {sScouts(i).Region(2:3)});
        elseif (length(sScouts(i).Region) >= 2)
            allRegions = union(allRegions, {sScouts(i).Region(2)});
        end
    end
    % Select the hemisphere used by selected scouts
    if (length(allHemi) == 1)
        switch allHemi{1}
            case 'L',   jMenuLeft.setSelected(1);
            case 'R',   jMenuRight.setSelected(1);
        end
    end
    if (length(allRegions) == 1)
        switch allRegions{1}
            case 'PF', jMenuPF.setSelected(1);
            case 'F',  jMenuF.setSelected(1);
            case 'C',  jMenuC.setSelected(1);
            case 'P',  jMenuP.setSelected(1);
            case 'T',  jMenuT.setSelected(1);
            case 'O',  jMenuO.setSelected(1);
            case 'L',  jMenuL.setSelected(1);
        end
    end
end


%% ===== SET INVERSE OPTIONS =====
function CreateMenuInverse(jMenu)
    % Remove all previous menus
    jMenu.removeAll();
    % Get selected scouts
    sScouts = GetSelectedScouts();
    if isempty(sScouts)
        return;
    end
    % Region(2): X=ignore, S=surface, V=volume, D=dba    
    jMenuSurf    = gui_component('RadioMenuItem', jMenu, [], 'Surface',  [], [], @(h,ev)SetScoutRegion('.S.'), []);
    jMenuVol     = gui_component('RadioMenuItem', jMenu, [], 'Volume',   [], [], @(h,ev)SetScoutRegion('.V.'), []);
    jMenuDba     = gui_component('RadioMenuItem', jMenu, [], 'Deep brain', [], [], @(h,ev)SetScoutRegion('.D.'), []);
    jMenuExclude = gui_component('RadioMenuItem', jMenu, [], 'Exclude',    [], [], @(h,ev)SetScoutRegion('.X.'), []);
    jMenu.addSeparator();
    % Region(3): C=constrained, L=loose, U=unconstrained
    jMenuConstr   = gui_component('RadioMenuItem', jMenu, [], 'Constrained',   [], [], @(h,ev)SetScoutRegion('..C'), []);
    jMenuUnconstr = gui_component('RadioMenuItem', jMenu, [], 'Unconstrained', [], [], @(h,ev)SetScoutRegion('..U'), []);
    jMenuLoose    = gui_component('RadioMenuItem', jMenu, [], 'Loose',         [], [], @(h,ev)SetScoutRegion('..L'), []);
    % Get the selected functions
    allForward = {};
    allInverse = {};
    for i = 1:length(sScouts)
        if (length(sScouts(i).Region) >= 2)
            allForward = union(allForward, {sScouts(i).Region(2)});
        end
        if (length(sScouts(i).Region) >= 3)
            allInverse = union(allInverse, {sScouts(i).Region(3)});
        end
    end
    % Select the hemisphere used by selected scouts
    if (length(allForward) == 1)
        switch allForward{1}
            case 'S',   jMenuSurf.setSelected(1);
            case 'V',   jMenuVol.setSelected(1);
            case 'D',   jMenuDba.setSelected(1);
            case 'X',   jMenuExclude.setSelected(1);
        end
    end
    if (length(allInverse) == 1)
        switch allInverse{1}
            case 'C', jMenuConstr.setSelected(1);
            case 'U',  jMenuUnconstr.setSelected(1);
            case 'L',  jMenuLoose.setSelected(1);
        end
    end
end


%% ===== UPDATE ATLAS LIST =====
function UpdateAtlasList(sSurf)
    import org.brainstorm.list.*;
    % Get the current surface
    if (nargin < 1)
        [sScouts, sSurf] = GetScouts();
    end
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Save combobox callback
    jModel = ctrl.jComboAtlas.getModel();
    bakCallback = java_getcb(jModel, 'ContentsChangedCallback');
    java_setcb(jModel, 'ContentsChangedCallback', []);
    % Empty the ComboBox
    ctrl.jComboAtlas.removeAllItems();
    % Add all the database entries in the list of the combo box
    if ~isempty(sSurf) && isfield(sSurf, 'Atlas') && ~isempty(sSurf.Atlas)
        ctrl.jComboAtlas.setEnabled(1);
        for i = 1:length(sSurf.Atlas)
            ctrl.jComboAtlas.addItem(BstListItem('protocol', '', sSurf.Atlas(i).Name, i))
        end
        % Select current atlas
        ctrl.jComboAtlas.setSelectedIndex(sSurf.iAtlas - 1);
    else
        ctrl.jComboAtlas.setEnabled(0);
    end
    % Restore callback
    java_setcb(jModel, 'ContentsChangedCallback', bakCallback);
end


%% ===== FOCUS CHANGED ======
function FocusChangedCallback(isFocused) %#ok<DEFNU>
    if ~isFocused
        SetSelectionState(0);
    end
end


%% ===== UPDATE SCOUTS LIST =====
function UpdateScoutsList()
    import org.brainstorm.list.*;
    % Get current scouts
    sAtlas = GetAtlas();
    if ~isempty(sAtlas)
        sScouts = sAtlas.Scouts;
    else
        sScouts = [];
    end
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Get scouts display options
    ScoutsOptions = GetScoutsOptions();
    if isempty(ScoutsOptions)
        return;
    end
    % Create a new empty list
    listModel = java_create('javax.swing.DefaultListModel');
    % Add an item in list for each scout found for target figure
    for i = 1:length(sScouts)
        % Change the scouts color according to current configuration
        if ScoutsOptions.displayRegionColor
            scoutColor = GetRegionColor(sScouts(i).Region);
        else
            scoutColor = sScouts(i).Color;
        end
        % Depending on the atlas name: display scouts differently
        switch (sAtlas.Name)
            case 'Source model'
                % Region(1): Hemisphere
                % Region(2): X=ignore, S=surface, V=volume, D=dba
                % Region(3): C=constrained, L=loose, U=unconstrained
                itemType = '';
                if (length(sScouts(i).Region) >= 2) && (sScouts(i).Region(2) == 'X')
                    itemType = '-';
                elseif (length(sScouts(i).Region) >= 3)
                    switch sScouts(i).Region(2)
                        case 'S', itemType = 'surf';
                        case 'V', itemType = 'vol';
                        case 'D', itemType = 'dba';
                    end
                    switch sScouts(i).Region(3)
                        case 'C', itemType = [itemType ' | constr'];
                        case 'L', itemType = [itemType ' | loose'];
                        case 'U', itemType = [itemType ' | unconstr'];
                    end
                end
                % Label: "hemisphere scout"
                scout = sScouts(i);
                if ~isempty(scout.Region)
                    scout.Region = scout.Region(1);
                end
                itemText = FormatScoutLabel(scout, 1);
            otherwise
                itemText = FormatScoutLabel(sScouts(i), 1);
                itemType = sScouts(i).Function;
        end
        % Create list entry
        listModel.addElement(BstListItem(itemType, [], itemText, i, scoutColor(1), scoutColor(2), scoutColor(3)));
    end
    % Update list model
    ctrl.jListScouts.setModel(listModel);
    % Reset Scout comments
    ctrl.jLabelScoutSize.setText('  No scout selected');
    ctrl.jLabelAreaSize.setText(' ');
end


%% ===== FORMAT SCOUT LABEL =====
function labels = FormatScoutLabel(sScouts, isHtml)
    % Empty structure: return
    if isempty(sScouts)
        labels = {};
        return;
    end
    % Get default scouts labels
    labels = {sScouts.Label};
    % Loop on scouts
    for i = 1:length(sScouts)
        % Remove the possible " R" and " L" at the end of the scouts names
        if (length(labels{i}) > 3) && (strcmp(labels{i}(end-1:end), ' R') || strcmp(labels{i}(end-1:end), ' L'))
            labels{i} = labels{i}(1:end-2);
        end
        % Label = "RegionCode ScoutName"
        if isempty(sScouts(i).Region) || strcmpi(sScouts(i).Region, 'UU')
            continue;
        elseif strcmpi(sScouts(i).Region, 'LU')
            strRegion = 'L';
        elseif strcmpi(sScouts(i).Region, 'RU')
            strRegion = 'R';
        else
            strRegion = sScouts(i).Region;
        end
        % HTML or Text
        if isHtml
            labels{i} = ['<HTML><FONT COLOR=#909090>' strRegion '</FONT>&nbsp;' labels{i}];
        else
            labels{i} = [strRegion ' ' labels{i}];
        end
    end
end


%% ===== UPDATE SCOUT PROPERTIES =====
function UpdateScoutProperties()
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Get selected scouts
    [sScouts, iScouts, sSurf] = GetSelectedScouts();
    % Estimate size of current scouts
    if ~isempty(sScouts)
        % Concatenate all the selected scouts
        allVertices = unique([sScouts.Vertices]);
        % Compute the total area (cm2)
        totalArea = sum(sSurf.VertArea(allVertices)) * 100 * 100;
        strSize = sprintf('  Vertices: %d', length(allVertices));
        strArea = sprintf('Area: %1.2f cm2  ', totalArea);
    else
        strSize = '  No scout selected';
        strArea = ' ';
    end
    % Update panel
    ctrl.jLabelScoutSize.setText(strSize);
    ctrl.jLabelAreaSize.setText(strArea);
end


%% ===== CURRENT FIGURE CHANGED =====
function CurrentFigureChanged_Callback(oldFig, hFig)
    global GlobalData;
    % If no figure is available
    if isempty(hFig) || ~ishandle(hFig)
        % Reset current surface
        GlobalData.CurrentScoutsSurface = '';
        return
    end
    % Get surfaces in new figure
    TessInfo = getappdata(hFig, 'Surface');
    iTess = getappdata(hFig, 'iSurface');
    if isempty(iTess) || isempty(TessInfo)
        SurfaceFile = [];
    else
        SurfaceFile = TessInfo(iTess).SurfaceFile;
    end
    % If the current surface didn't change: nothing to do
    if file_compare(GlobalData.CurrentScoutsSurface, SurfaceFile)
        return;
    end
    % If surface file is an MRI: take the associated results on a surface instead
    if ~isempty(iTess) && strcmpi(TessInfo(iTess).Name, 'Anatomy') && ~isempty(TessInfo(iTess).DataSource) && ~isempty(TessInfo(iTess).DataSource.FileName)
        FileMat.SurfaceFile = [];
        if strcmpi(TessInfo(iTess).DataSource.Type, 'Source')
            FileMat = in_bst_results(TessInfo(iTess).DataSource.FileName, 0, 'SurfaceFile');
        elseif strcmpi(TessInfo(iTess).DataSource.Type, 'Timefreq')
            FileMat = in_bst_timefreq(TessInfo(iTess).DataSource.FileName, 0, 'SurfaceFile', 'DataFile', 'DataType');
            if isempty(FileMat.SurfaceFile) && ~isempty(FileMat.DataFile) && strcmpi(FileMat.DataType, 'results')
                FileMat = in_bst_results(FileMat.DataFile, 0, 'SurfaceFile');
            end
        end
        if ~isempty(FileMat.SurfaceFile) && strcmpi(file_gettype(FileMat.SurfaceFile), 'cortex')
            SurfaceFile = FileMat.SurfaceFile;
        end
    end
    % Update current surface
    SetCurrentSurface(SurfaceFile);
    
    % === UPDATE SELECTED SCOUTS ===
    % Get current scouts (for new figure)
    sScouts = GetScouts();
    % If 3D figure: scouts have graphic handles
    FigureId = getappdata(hFig, 'FigureId');
    switch(FigureId.Type)
        case 'MriViewer'
            iVisibleScouts = 1:length(sScouts);
        case '3DViz'
            % Process each scout, to get if it is displayed in this figure
            iVisibleScouts = [];
            for i = 1:length(sScouts)
                % Get handles corresponding to this figure
                allhandles = [sScouts(i).Handles];
                iFigHandles = find([allhandles.hFig] == hFig);
                % If scout is displayed in this figure, and is VISIBLE in this figure: add it to the visible list
                if ~isempty(iFigHandles) && (strcmpi(get(sScouts(i).Handles(iFigHandles).hScout, 'Visible'), 'on') || strcmpi(get(sScouts(i).Handles(iFigHandles).hPatch, 'Visible'), 'on'))
                    iVisibleScouts = [iVisibleScouts, i];
                end
            end
        otherwise
            iVisibleScouts = [];
    end
    % Get scout options
    ScoutsOptions = GetScoutsOptions();
    if isempty(ScoutsOptions)
        return;
    end
    % Select visible scouts (only if not creating a new scout)
    if (GetSelectionState() == 0) && strcmpi(ScoutsOptions.showSelection, 'select') && ~isequal(hFig, oldFig)
        SetSelectedScouts(iVisibleScouts);
    end
end



%% =================================================================================
%  === SCOUTS SELECTION ============================================================
%  =================================================================================
%% ===== IS READ ONLY =====
function isReadOnly = isAtlasReadOnly(sAtlas, isInteractive)
    global GlobalData;
    % Parse inputs
    if (nargin < 1) || isempty(isInteractive)
        isInteractive = 1;
    end
    % Get current atlas
    if (nargin < 2) || isempty(sAtlas)
        % Get current surface
        sSurf = bst_memory('GetSurface', GlobalData.CurrentScoutsSurface);
        % If there are no surface, or atlases: return
        if isempty(sSurf) || isempty(sSurf.Atlas) || isempty(sSurf.iAtlas) || (sSurf.iAtlas > length(sSurf.Atlas))
            isReadOnly = 0;
            return;
        end
        sAtlas = sSurf.Atlas(sSurf.iAtlas);
    end
    % If it is an "official" atlas: read-only
    if ismember(lower(sAtlas.Name), {...
            'brainvisa_tzourio-mazoyer', ... % Old default anatomy
            'freesurfer_destrieux_15000V', 'freesurfer_desikan-killiany_15000V', 'freesurfer_brodmann_15000V', ... % Old default anatomy
            'destrieux', 'desikan-killiany', 'brodmann', 'brodmann-thresh', 'mindboggle', 'structures'})  % New freesurf
        if isInteractive
            java_dialog('warning', [...
                'This atlas is a reference and cannot be modified or deleted.' 10 10 ...
                'To modify the selected scouts, make a copy of them first using the menu:' 10 ...
                '"Atlas > New atlas > Copy selected scouts".' 10], 'Read-only atlas');
        end
        isReadOnly = 1;
    else
        isReadOnly = 0;
    end
end


%% ===== SET CURRENT ATLAS =====
function SetCurrentAtlas(iAtlas, isForced)
    global GlobalData;
    % Parse inputs
    if (nargin < 2) || isempty(isForced)
        isForced = 0;
    end
    % Get the current surface
    [sScouts, sSurf, iSurf] = GetScouts();
    if isempty(sSurf) || (iAtlas > length(sSurf.Atlas))
        disp('BST> Error: Invalid atlas index.');
        return;
    end
    % Update menus
    UpdateMenus(sSurf.Atlas(iAtlas));
    % If current atlas did not change: exit
    if ~isForced && isequal(sSurf.iAtlas, iAtlas)
        return;
    end
    % Progress bar
    isProgress = ~bst_progress('isVisible');
    if isProgress
        bst_progress('start', 'Set selected atlas', 'Updating display...');
    end
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % If the selected index in the combo box is incorrect: select item
    if isForced || (iAtlas ~= ctrl.jComboAtlas.getSelectedIndex()+1)    
        % Save combobox callback
        jModel = ctrl.jComboAtlas.getModel();
        bakCallback = java_getcb(jModel, 'ContentsChangedCallback');
        java_setcb(jModel, 'ContentsChangedCallback', []);
        % Select the new atlas
        ctrl.jComboAtlas.setSelectedIndex(iAtlas - 1);
        % Restore callback
        drawnow;
        java_setcb(jModel, 'ContentsChangedCallback', bakCallback);
    end
    % Update selection of atlas in the current surface
    GlobalData.Surface(iSurf).iAtlas = iAtlas;
    GlobalData.Surface(iSurf).isAtlasModified = 1;
    % Update scouts list
    UpdateScoutsList();
    % Reload scouts
    ReloadScouts();
    % Close progress bar
    if isProgress
        bst_progress('stop');
    end
end


%% ===== SET CURRENT SURFACE =====
function SetCurrentSurface(newSurfaceFile)
    global GlobalData;
    % Get previously selected surface
    oldSurfaceFile = GlobalData.CurrentScoutsSurface;
    % If SurfaceFile did not change did not change : return
    if strcmpi(newSurfaceFile, oldSurfaceFile)
        return;
    end
    % Update current surface file
    GlobalData.CurrentScoutsSurface = newSurfaceFile;
    % Update panel display
    UpdatePanel();
end


%% ===== GET SCOUTS =====
% USAGE:  [sScouts, sSurf, iSurf] = GetScouts(SurfaceFile)
%         [sScouts, sSurf, iSurf] = GetScouts(iScouts)
%         [sScouts, sSurf, iSurf] = GetScouts()
function [sScouts, sSurf, iSurf] = GetScouts(SurfaceFile)
    global GlobalData;
    sScouts = [];
    sSurf   = [];
    iSurf   = [];
    % Parse input
    if (nargin < 1) || isempty(SurfaceFile)
        SurfaceFile = GlobalData.CurrentScoutsSurface;
        iScouts = [];
    elseif ischar(SurfaceFile)
        iScouts = [];
    else
        iScouts = SurfaceFile;
        SurfaceFile = GlobalData.CurrentScoutsSurface;
    end
    % If no surface is defined : do nothing
    if isempty(SurfaceFile)
        return
    end
    % Get loaded surface
    [sSurf, iSurf] = bst_memory('GetSurface', SurfaceFile);
    % Get the selected scouts
    if ~isempty(sSurf) && ~isempty(sSurf.Atlas) && ~isempty(sSurf.iAtlas)
        sScouts = sSurf.Atlas(sSurf.iAtlas).Scouts;
        % Select only the required scouts
        if (any(iScouts) > length(sScouts))
            error('Invalid scout indice.');
    	elseif ~isempty(iScouts)
            if any(iScouts > length(sScouts))
                disp('Error: Invalid indices');
            else
                sScouts = sScouts(iScouts);
            end
        end
    end
end


%% ===== SET SCOUTS =====
% USAGE:  iScouts = SetScouts(SurfaceFile=CurrentSurface, iScouts=[], sScouts)
%         iScouts = SetScouts(SurfaceFile=CurrentSurface, 'Add', sScouts)
function iScouts = SetScouts(SurfaceFile, iScouts, sScouts)
    global GlobalData;
    % Parse input
    if isempty(SurfaceFile)
        SurfaceFile = GlobalData.CurrentScoutsSurface;
    end
    isAdd = ~isempty(iScouts) && ischar(iScouts) && strcmpi(iScouts, 'Add');
    % Get loaded surface
    [sSurf, iSurf] = bst_memory('GetSurface', SurfaceFile);
    % If there is no selected atlas: return
    if isempty(sSurf.Atlas) || isempty(sSurf.iAtlas)
        return;
    end
    % Save the previous scouts configuration
    sScoutsOld = GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts;
    % Detect region if not defined yet (only for new scouts)
    if isAdd
        for i = 1:length(sScouts)
            if ~isempty(sScouts(i).Seed) && (isempty(sScouts(i).Region) || strcmpi(sScouts(i).Region, 'UU'))
                sScouts(i) = SetRegionAuto(sSurf, sScouts(i));
            end
        end
    end
    % Replace all the scouts
    if isempty(iScouts) || isempty(GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts)
        GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts = sScouts;
        iScouts = 1:length(sScouts);
    % Set specific scouts
    else
        % Add new scout
        if isAdd
            iScouts = length(GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts) + (1:length(sScouts));
        end
        % Set scout in global structure
        GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts(iScouts) = sScouts;
    end
    % Add color if not defined yet
    for i = 1:length(GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts)
        if isempty(GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts(i).Color)
            % Try to get the color matching with the label (if the label is an integer)
            iScoutColor = str2double(GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts(i).Label);
            if isempty(iScoutColor) || (length(iScoutColor) ~= 1) || any(isnan(iScoutColor)) || any(~isreal(iScoutColor))
                iScoutColor = i;
            end
            % Set color
            GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts(i) = SetColorAuto(GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts(i), iScoutColor);
        end
    end
    % Check if any modifications were done
    if ~GlobalData.Surface(iSurf).isAtlasModified 
        % Get new scouts list
        sScoutsNew = GlobalData.Surface(iSurf).Atlas(sSurf.iAtlas).Scouts;
        % If number of scouts is different: it obviously changed
        if (length(sScoutsNew) ~= length(sScoutsOld))
            GlobalData.Surface(iSurf).isAtlasModified = 1;
        % Else: check scout by scout
        else
            for i = 1:length(sScoutsNew)
                if ~isequal(sScoutsOld(i).Vertices, sScoutsNew(i).Vertices) || ...
                   ~isequal(sScoutsOld(i).Color,    sScoutsNew(i).Color)    || ...
                   ~isequal(sScoutsOld(i).Label,    sScoutsNew(i).Label)    || ...
                   ~isequal(sScoutsOld(i).Function, sScoutsNew(i).Function) || ...
                   ~isequal(sScoutsOld(i).Region,   sScoutsNew(i).Region)
                    GlobalData.Surface(iSurf).isAtlasModified = 1;
                end
            end
        end
    end
end


%% ===== GET SELECTED SCOUTS =====
function [sSelScouts, iSelScouts, sSurf, iSurf] = GetSelectedScouts()
    sSelScouts = [];
    iSelScouts = [];
    sSurf = [];
    iSurf = [];
    % Get panel handles
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Get current scouts
    [sScouts, sSurf, iSurf] = GetScouts();
    if isempty(sScouts)
        return
    end
    % Get JList selected indices
    iSelScouts = uint16(ctrl.jListScouts.getSelectedIndices())' + 1;
    sSelScouts = sScouts(iSelScouts);
end


%% ===== SET SELECTED SCOUTS =====
function SetSelectedScouts(iSelScouts)
    % === GET SCOUT INDICES ===
    % No selection
    if isempty(iSelScouts) || (any(iSelScouts == 0))
        iSelItem = -1;
    % Find the selected scouts in the JList
    else
        iSelItem = iSelScouts - 1;
    end
    % === CHECK FOR MODIFICATIONS ===
    % Get figure controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl) || isempty(ctrl.jListScouts)
        return
    end
    % Get previous selection
    iPrevItems = ctrl.jListScouts.getSelectedIndices();
    % If selection did not change: exit
    if isequal(iPrevItems, iSelItem) || (isempty(iPrevItems) && isequal(iSelItem, -1))
        return
    end
    % === UPDATE SELECTION ===
    % Temporality disables JList selection callback
    jListCallback_bak = java_getcb(ctrl.jListScouts, 'ValueChangedCallback');
    java_setcb(ctrl.jListScouts, 'ValueChangedCallback', []);
    % Select items in JList
    ctrl.jListScouts.setSelectedIndices(iSelItem);
    % Scroll to see the selected scout in the list
    if (length(iSelItem) == 1) && ~isequal(iSelItem, -1)
        selRect = ctrl.jListScouts.getCellBounds(iSelItem, iSelItem);
        ctrl.jListScouts.scrollRectToVisible(selRect);
        ctrl.jListScouts.repaint();
    end
    % Restore JList callback
    java_setcb(ctrl.jListScouts, 'ValueChangedCallback', jListCallback_bak);
    % Update panel "Scouts" fields
    UpdateScoutProperties();
    % Get scouts display options
    ScoutsOptions = GetScoutsOptions();
    if isempty(ScoutsOptions)
        return;
    end
    % Display/hide scouts
    if strcmpi(ScoutsOptions.showSelection, 'select')
        UpdateScoutsDisplay('current');
    end
end


%% ===== GET SCOUT OPTIONS =====
% ScoutsOptions:
%    |- overlayScouts     : {0, 1}
%    |- overlayConditions : {0, 1}
%    |- showSelection     : {'all', 'select', 'none'}
%    |- patchAlpha        : [0, 1]
%    |- displayAbsolute   : {0, 1}
%    |- displayContour    : {0, 1}
%    |- displayText       : {0, 1}
%    |- displayRegionColor: {0, 1}
function ScoutsOptions = GetScoutsOptions()
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        ScoutsOptions = [];
        return;
    end
    % Get current scouts
    ScoutsOptions.overlayScouts     = ctrl.jCheckOverlayScouts.isSelected();
    ScoutsOptions.overlayConditions = ctrl.jCheckOverlayConditions.isSelected();
    % Absolute values
    ScoutsOptions.displayAbsolute = ctrl.jRadioAbsolute.isSelected();
    % Show selection
    if ~ctrl.jRadioShowSel.isSelected() && ~ctrl.jRadioShowAll.isSelected()
        ScoutsOptions.showSelection = 'none';
    elseif ctrl.jRadioShowSel.isSelected()
        ScoutsOptions.showSelection = 'select';
    else
        ScoutsOptions.showSelection = 'all';
    end
    % Scout patch transparency
    if ctrl.jCheckTransp100.isSelected()
        ScoutsOptions.patchAlpha = 1;
    elseif ctrl.jCheckTransp70.isSelected()
        ScoutsOptions.patchAlpha = .7;
    else
        ScoutsOptions.patchAlpha = 0;
    end
    % Selected parts of the scouts
    ScoutsOptions.displayContour = ctrl.jCheckContour.isSelected();
    ScoutsOptions.displayText = ctrl.jCheckText.isSelected();
    ScoutsOptions.displayRegionColor = ctrl.jCheckRegionColor.isSelected();
end


%% ===== GET SCOUT WITH HANDLE =====
function [sScout, iScout] = GetScoutWithHandle(hScout) %#ok<DEFNU>
    % Initialize returned variables
    sScout = [];
    iScout = [];
    % Get current scouts
    sScouts = panel_scout('GetScouts');
    % Loop through scouts to find the clicked one
    for i = 1:length(sScouts)
        allHandles = [sScouts(i).Handles.hScout, sScouts(i).Handles.hLabel, sScouts(i).Handles.hVertices, sScouts(i).Handles.hPatch, sScouts(i).Handles.hContour];
        if any(allHandles == hScout)
            sScout = sScouts(i);
            iScout = i;
            return;
        end
    end
end


%% ===== SET SHOW SELECTION =====
function SetShowSelection(hObj, ev)
    % Get panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    % If the other button is selected: unselect it
    if ctrl.jRadioShowSel.isSelected() && ctrl.jRadioShowAll.isSelected()
        if (ev.getSource() == ctrl.jRadioShowSel)
            ctrl.jRadioShowAll.setSelected(0);
        else
            ctrl.jRadioShowSel.setSelected(0);
        end
    end
    % Update surface alpha
    UpdateStructureAlpha();
    % Update display
    UpdateScoutsDisplay('all');
end


%% ===== SET SCOUT FUNCTION =====
function SetScoutFunction(Function)
    % Get clusters
    [sScouts, iScouts] = GetSelectedScouts();
    if isempty(iScouts)
        return
    end
    % Set function
    if ~isempty(Function)
        [sScouts.Function] = deal(Function);
    end
    % Save clusters
    SetScouts([], iScouts, sScouts);
    % Update JList
    UpdateScoutsList();
    % Select edited scouts (selection was lost during update)
    SetSelectedScouts(iScouts);
end


%% ===== SET SCOUT REGION =====
% USAGE:  SetScoutRegion(Region)
%         SetScoutRegion()       : Asks region to the user
function SetScoutRegion(Region)
    % Ask region if not defined
    if (nargin < 1) || isempty(Region)
        Region = java_dialog('input', 'Brain region for the selected scouts:', 'Set scout region', [], 'UU');
        if isempty(Region)
            return
        end
    end
    if (length(Region) < 2)
        bst_error('Invalid region identifier', 'Set region', 0);
    end
    % Get clusters
    [sScouts, iScouts] = GetSelectedScouts();
    if isempty(iScouts)
        return
    end
    % Set region
    for i = 1:length(sScouts)
        scoutRegion = Region;
        if (Region(1) == '.')
            scoutRegion(1) = sScouts(i).Region(1);
        end
        if (Region(2) == '.')
            scoutRegion(2) = sScouts(i).Region(2);
        end
        if (length(Region) >= 3) && (Region(3) == '.')
            if (length(sScouts(i).Region) >= 3)
                scoutRegion(3) = sScouts(i).Region(3);
            else
                scoutRegion(3:end) = [];
            end
        end
        sScouts(i).Region = scoutRegion;
    end
    % Save clusters
    SetScouts([], iScouts, sScouts);
    % Update JList
    UpdateScoutsList();
    % Select edited scouts (selection was lost during update)
    SetSelectedScouts(iScouts);
end


%% ===== SET SCOUT TRANSPARENCY =====
function SetScoutTransparency(alpha)
    % Progress bar
    isProgress = ~bst_progress('isVisible');
    if isProgress
        bst_progress('start', 'Scouts options', 'Updating display...');
    end
    % Get all the scout patches in the environment
    hPatch = findobj(0, 'Tag', 'ScoutPatch');
    % Update the alpha
    if ~isempty(hPatch)
        set(hPatch, 'FaceAlpha', 1-alpha);
    % Investigating why...
    else
        % Get current scouts
        sScouts = GetScouts();
        % Get scouts display options
        ScoutsOptions = GetScoutsOptions();
        if isempty(ScoutsOptions)
            return;
        end
        % View mode: all, select, none
        switch (ScoutsOptions.showSelection)
            case 'all'
                iVisibleScouts = 1:length(sScouts);
            case 'select'
                [tmp, iVisibleScouts] = GetSelectedScouts();
            case 'none'
                iVisibleScouts = [];
        end
        % If there are some visible scouts and no patches: redraw all scouts
        if ~isempty(iVisibleScouts)
            PlotScouts();
        end
    end
    if isProgress
        bst_progress('stop');
    end
end

%% ===== SET SCOUT CONTOUR VISIBLE =====
function SetScoutContourVisible(isVisible, isUpdate) %#ok<DEFNU>
    % Update by default
    if (nargin < 2) || isempty(isUpdate)
        isUpdate = 1;
    end
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Set the button status
    ctrl.jCheckContour.setSelected(isVisible);
    % Execute update callback
    if isUpdate
        UpdateScoutsDisplay('all');
    end
end

%% ===== SET SCOUT TEXT VISIBLE =====
function SetScoutTextVisible(isVisible, isUpdate)
    % Update by default
    if (nargin < 2) || isempty(isUpdate)
        isUpdate = 1;
    end
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Set the button status
    ctrl.jCheckText.setSelected(isVisible);
    % Execute update callback
    if isUpdate
        UpdateScoutsDisplay('all');
    end
end

%% ===== SET SCOUT DISPAY SELECTION =====
function SetScoutShowSelection(showSelection) %#ok<DEFNU>
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return;
    end
    % Select the appropriate button
    switch (showSelection)
        case 'none'
            ctrl.jRadioShowSel.setSelected(0);
            ctrl.jRadioShowAll.setSelected(0);
        case 'select'
            ctrl.jRadioShowSel.setSelected(1);
            ctrl.jRadioShowAll.setSelected(0);
        case 'all'
            ctrl.jRadioShowSel.setSelected(0);
            ctrl.jRadioShowAll.setSelected(1);
    end
    % Update display
    UpdateScoutsDisplay('all');
end

%% ===== SET DEFAULT OPTIONS =====
function SetDefaultOptions(isFullUpdate)
    % Parse inputs
    if (nargin < 1) || isempty(isFullUpdate)
        isFullUpdate = 0;
    end
    % Get all the current atlas
    sAtlas = GetAtlas();
    if isempty(sAtlas)
        return;
    end
    % Get all the figures
    hFigs = bst_figures('GetAllFigures');
    % Get current scout display options
%     ScoutOptions = GetScoutsOptions();
    % If there is only one figure: set the default scout options depending on what is displayed
    if (length(hFigs) == 1)
        % Structures atlas
        if strcmpi(sAtlas.Name, 'Structures')
            SetScoutTextVisible(0, 0);
        else
            % First atlas (user scouts): always show labels
            if (length(sAtlas.Scouts) < 10)
                SetScoutTextVisible(1, 0);
    %             if isFullUpdate && strcmpi(ScoutOptions.showSelection, 'select')
    %                 SetScoutShowSelection('all');
    %             end
            % Too many scouts scouts: hide labels
            elseif (length(sAtlas.Scouts) > 10)
                SetScoutTextVisible(0, 0);
    %             if isFullUpdate && strcmpi(ScoutOptions.showSelection, 'all')
    %                 SetScoutShowSelection('select');
    %             end
            end
        end
    end
end


%% ===== GET SCOUTS COLOR TABLE =====
function ColorTable = GetScoutsColorTable()
    ColorTable = [0    .8    0   ;
                  1    0    0   ; 
                  .4   .4   1   ;
                  1    .694 .392;
                  0    1    1   ;
                  1    0    1   ;
                  .4   0    0  ; 
                  0    .4   0];
end


%% ===== GET REGION COLOR =====
function Color = GetRegionColor(Region)
    if isempty(Region)
        Region = 'UU';
    end
    ColorTable = GetScoutsColorTable();
    switch lower(Region(2:end))
        case 'f',    Color = ColorTable(1,:);
        case 'pf',   Color = ColorTable(2,:);
        case 'p',    Color = ColorTable(3,:);
        case 'o',    Color = ColorTable(4,:);
        case 't',    Color = ColorTable(5,:);
        case 'c',    Color = ColorTable(6,:);
        case 'l',    Color = ColorTable(7,:);
        case 's',    Color = ColorTable(8,:);
        otherwise,   Color = [.2 .2 .2];
    end
end


%% ===== SET COLOR AUTO =====
function sScout = SetColorAuto(sScout, iScout)
    % Parse inputs
    if (nargin < 2) || isempty(iScout)
        iScout = [];
    end
    % Get color in the colortable
    if ~isempty(iScout)
        ColorTable = GetScoutsColorTable();
        iColor = mod(iScout-1, length(ColorTable)) + 1;
        sScout.Color = ColorTable(iColor,:);
    % Try to detect base on the name
    else
        lab = lower(sScout.Label);
        lab = strrep(lab, ' l', '');
        lab = strrep(lab, ' r', '');
        switch (lab)
            case 'brainstem',    sScout.Color = [119 159 176] / 255;
            case 'cerebellum',   sScout.Color = [230 148  34] / 255;
            case 'accumbens',    sScout.Color = [255 165   0] / 255;
            case 'amygdala',     sScout.Color = [103 255 255] / 255;
            case 'caudate',      sScout.Color = [122 186 220] / 255;
            case 'hippocampus',  sScout.Color = [220 216  20] / 255;
            case 'pallidum',     sScout.Color = [ 12  48 255] / 255;
            case 'putamen',      sScout.Color = [236  13 176] / 255;
            case 'thalamus',     sScout.Color = [  0 118  14] / 255;
            case 'cortex',       sScout.Color = [190 190 190] / 255;
            otherwise,           sScout.Color = rand(1,3);
        end
    end
end


%% ===== SET REGION AUTO =====
function sScout = SetRegionAuto(sSurf, sScout)
    % Get atlases we want to test
    iAtlases = [find(strcmpi({sSurf.Atlas.Name}, 'Mindboggle')), find(strcmpi({sSurf.Atlas.Name}, 'Desikan-Killiany')), find(strcmpi({sSurf.Atlas.Name}, 'Destrieux')), find(strcmpi({sSurf.Atlas.Name}, 'Structures'))];
    % Test them one after the other after we find one that contains the target point
    for i = 1:length(iAtlases)
        for iScout = 1:length(sSurf.Atlas(iAtlases(i)).Scouts)
            sScoutTest = sSurf.Atlas(iAtlases(i)).Scouts(iScout);
            % If the target was found: return
            if ismember(sScout.Seed, sScoutTest.Vertices)
                sScout.Region = sScoutTest.Region;
                return;
            end
        end
    end
end


%% ===== SET SELECTION STATE =====
% Manual selection of a cortical spot : start(1), or stop(0)
function SetSelectionState(isSelected)
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        return
    end
    % Get list of figures where it is possible to select a scout
    hFigures = bst_figures('GetFiguresForScouts');
    % If nothing available: get the first random surface
    if isempty(hFigures)
        hFigures = bst_figures('GetFigureWithSurfaces');
    end
    % No figure available
    if isempty(hFigures)
        if isSelected
            java_dialog('warning', 'You need to display a cortex surface before creating scouts.', 'Select a cortical spot');
        end
        % Release toolbar "AddScout" button 
        ctrl.jButtonAddScout.setSelected(0);
        return
    end
    % Start scout selection
    if isSelected
        % Push toolbar "AddScout" button 
        ctrl.jButtonAddScout.setSelected(1);
        % Unselect all the scouts in JList
        SetSelectedScouts([]);
        % Set 3DViz figures in 'SelectingCorticalSpot' mode
        for hFig = hFigures
            setappdata(hFig, 'isSelectingCorticalSpot', 1);
            set(hFig, 'Pointer', 'cross');
        end
    % Stop scout selection
    else
        % Release toolbar "AddScout" button 
        ctrl.jButtonAddScout.setSelected(0);
        % Exit 3DViz figures from SelectingCorticalSpot mode
        for hFig = hFigures
            set(hFig, 'Pointer', 'arrow');
            setappdata(hFig, 'isSelectingCorticalSpot', 0);      
        end
    end
end

%% ===== GET SELECTION STATE =====
function isSelected = GetSelectionState()
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    if isempty(ctrl)
        isSelected = 0;
        return
    end
    % Return status
    isSelected = ctrl.jButtonAddScout.isSelected();
end


%% ===============================================================================
%  ====== ATLAS CREATION/EDITION =================================================
%  ===============================================================================
%% ===== GET ATLAS =====
% USAGE:  [sAtlas, iAtlas, sSurf, iSurf] = GetAtlas(SurfaceFile=CurrentScoutsSurface, iAtlasIn=iAtlas)
%         [sAtlas, iAtlas, sSurf, iSurf] = GetAtlas()
function [sAtlas, iAtlas, sSurf, iSurf] = GetAtlas(SurfaceFile, iAtlasIn)
    global GlobalData;
    % Initialize returned values
    sAtlas = [];
    iAtlas = [];
    sSurf = [];
    iSurf = [];
    % Parse input
    if (nargin < 1) || isempty(SurfaceFile)
        SurfaceFile = GlobalData.CurrentScoutsSurface;
        if isempty(SurfaceFile)
            return;
        end
    end
    % Get loaded surface
    [sSurf, iSurf] = bst_memory('GetSurface', SurfaceFile);
    if isempty(sSurf)
        return;
    end
    % Target atlas
    if (nargin < 2) || isempty(iAtlasIn)
        iAtlas = sSurf.iAtlas;
    else
        iAtlas = iAtlasIn;
    end
    sAtlas = sSurf.Atlas(iAtlas);
end


%% ===== SET ATLAS =====
% USAGE:  iAtlas = SetAtlas(SurfaceFile=[], iAtlas, sAtlas=[])
%         iAtlas = SetAtlas(SurfaceFile=[], 'Add',  sAtlas=[])                  % Create an empty atlas
function iAtlas = SetAtlas(SurfaceFile, iAtlasIn, sAtlas)
    global GlobalData;
    iAtlas = [];
    % Stop scout edition
    SetSelectionState(0);
    % Parse input
    if (nargin < 1) || isempty(SurfaceFile)
        SurfaceFile = GlobalData.CurrentScoutsSurface;
        if isempty(SurfaceFile)
            java_dialog('warning', 'No surface available.', 'Set atlas');
            return;
        end
    end
    % Get loaded surface
    [sSurf, iSurf] = bst_memory('GetSurface', SurfaceFile);
    % Target atlas
    if (nargin < 2) || isempty(iAtlasIn)
        iAtlas = sSurf.iAtlas;
    elseif ischar(iAtlasIn) && strcmpi(iAtlasIn, 'Add')
        iAtlas = length(sSurf.Atlas) + 1;
    else
        iAtlas = iAtlasIn;
    end
    % Default atlas
    if (nargin < 3) || isempty(sAtlas)
        % Empty atlas structure
        sAtlas = db_template('Atlas');
        % Ask user for a name
        newLabel = java_dialog('input', 'Please enter a name for the new group of scouts:', 'New atlas', [], sprintf('Atlas #%d', iAtlas));
        if isempty(newLabel)
            return;
        end
        sAtlas.Name = newLabel;
    end
    % Fix the structure of the file
    sAtlas = FixAtlasStruct(sAtlas);
    % Make the atlas name unique
    if ~isempty(GlobalData.Surface(iSurf).Atlas)
        sAtlas.Name = file_unique(sAtlas.Name, {GlobalData.Surface(iSurf).Atlas.Name});
    end
    % Add atlas to the current atlases
    if isempty(GlobalData.Surface(iSurf).Atlas)
        GlobalData.Surface(iSurf).Atlas = sAtlas;
        iAtlas = 1;
    else
        GlobalData.Surface(iSurf).Atlas(iAtlas) = sAtlas;
    end
    GlobalData.Surface(iSurf).isAtlasModified = 1;
    % Update list of atlases
    UpdateAtlasList();
    SetCurrentAtlas(iAtlas, 1);
end


%% ===== CREATE ATLAS: INVERSE =====
function CreateAtlasInverse()
    % Get current surface
    [sScouts, sSurf] = GetScouts();
    % Find existing Inverse atlas
    [sAtlas, iAtlas, sSurf, iSurf] = GetAtlas();
    iInverse = find(strcmpi('Source model', {sSurf.Atlas.Name}));
    if ~isempty(iInverse)
        java_dialog('warning', 'Atlas "Inverse" already exists.', 'Create new atlas');
        return;
    end
    % Find "Structures" atlas
    iStruct = find(strcmpi('Structures', {sSurf.Atlas.Name}));
    % If the Structures atlas exist: copy it
    if ~isempty(iStruct)
        % Copy Structures atlas
        sAtlasInv = sSurf.Atlas(iStruct);
        for i = 1:length(sAtlasInv.Scouts)
            sAtlasInv.Scouts(i).Function = '';
            if ~isempty(sAtlasInv.Scouts(i).Region)
                Region = [sAtlasInv.Scouts(i).Region(1), 'SC'];
            else
                Region = 'USC';
            end
            sAtlasInv.Scouts(i).Region = Region;
        end
    % Else: Create a new empty structure
    else
        sAtlasInv = db_template('Atlas');
    end
    % Create new atlas
    sAtlasInv.Name = 'Source model';
    SetAtlas([], 'Add', sAtlasInv);
end


%% ===== CREATE ATLAS: SELECTED SCOUTS =====
function CreateAtlasSelected(isAllScouts, isAskName)
    % Parse inputs    
    if (nargin < 2) || isempty(isAskName)
        isAskName = 1;
    end
    if (nargin < 1) || isempty(isAllScouts)
        isAllScouts = 0;
    end
    % Get all scouts
    if isAllScouts
        [sScouts, sSurf] = GetScouts();
        if isempty(sScouts)
            java_dialog('warning', 'No scouts in the current atlas.', 'Create new atlas');
            return;
        end
        iScouts = 1:length(sScouts);
    % Get selected scouts
    else
        [sScouts, iScouts, sSurf] = GetSelectedScouts();
        if isempty(iScouts)
            java_dialog('warning', 'No scouts selected.', 'Create new atlas');
            return;
        end
    end
    % Get the full atlas
    sAtlas = GetAtlas();
    % Keep only the selected scouts
    sAtlas.Scouts = sAtlas.Scouts(iScouts);
    % Reset all the handles
    for i = 1:length(sAtlas.Scouts)
        sAtlas.Scouts(i).Handles = [];
    end
    % Ask user for a name
    if isAskName
        newLabel = java_dialog('input', 'Please enter a name for the new atlas:', 'New atlas', [], sprintf('Atlas #%d', length(sSurf.Atlas) + 1));
        if isempty(newLabel)
            return;
        end
    else
        newLabel = sAtlas.Name;
    end
    % Check for unicity
    newLabel = file_unique(newLabel, {sSurf.Atlas.Name});
    % Set new atlas name
    sAtlas.Name = newLabel;
    % Create new atlas with only the selected scouts
    SetAtlas([], 'Add', sAtlas);
end


%% ===== CREATE ATLAS: CLUSTERING =====
function CreateAtlasCluster()
    % Get the current surface
    [sAtlas, sSurf] = GetScouts();
    if isempty(sSurf)
        return;
    end
    % Ask the number of scouts
    nClustStr = java_dialog('input', 'Number of scouts:', 'Surface clustering', [], '400');
    if isempty(nClustStr) || isempty(str2num(nClustStr))
        return
    end
    nClust = str2num(nClustStr);

    % ===== CLUSTERING =====
    % Progress bar
    bst_progress('start', 'Surface clustering', 'Clustering...');
    % Split hemispheres
    [rH, lH, isConnected] = tess_hemisplit(sSurf);
    % Clustering
    if isConnected
        Labels = tess_cluster(sSurf.VertConn, nClust);
    else
        Labels = ones(length(sSurf.Vertices), 1);
        Labels(lH) = tess_cluster(sSurf.VertConn(lH,lH), round(nClust / 2));
        Labels(rH) = tess_cluster(sSurf.VertConn(rH,rH), round(nClust / 2)) + max(Labels(lH));
    end
    uniqueLabels = unique(Labels);

    % ===== CREATE NEW ATLAS =====
    bst_progress('start', 'Surface clustering', 'Creating scouts...');
    % Create a new atlas
    sAtlas = db_template('Atlas');
    sAtlas.Name = ['Surface clustering: ' num2str(nClust)];
    % String format depends on the number of clusters
    if (nClust > 99)
        strFormat = '%03d';
    else
        strFormat = '%02d';
    end
    % Plot new scouts
    for iScout = 1:length(uniqueLabels)
        sAtlas.Scouts(iScout).Vertices = find(Labels == uniqueLabels(iScout));
        sAtlas.Scouts(iScout).Seed     = sAtlas.Scouts(iScout).Vertices(1);
        sAtlas.Scouts(iScout).Label    = sprintf(strFormat, uniqueLabels(iScout));
        sAtlas.Scouts(iScout).Color    = rand(1,3);
        sAtlas.Scouts(iScout).Function = 'Mean';
        % Assign hemisphere
        if isConnected
            sAtlas.Scouts(iScout).Region = 'UU';
        else
            if (uniqueLabels(iScout) <= max(Labels(lH)))
                sAtlas.Scouts(iScout).Region = 'LU';
            else
                sAtlas.Scouts(iScout).Region = 'RU';
            end
        end
    end
    % Update the seeds
    sAtlas.Scouts = SetScoutsSeed(sAtlas.Scouts, sSurf.Vertices);
    % Save atlas
    SetAtlas([], 'Add', sAtlas);
    % Progress bar
    bst_progress('stop');
end

%% ===== CREATE ATLAS: LEADFIELD CLUSTERING =====
function [iAtlas, err] = CreateMLCCluster()
    % Init varout
    err = [];
    % Get selected figure
    hFig = bst_figures('GetCurrentFigure', '3D');
    if isempty(hFig) || ~ishandle(hFig) || isempty(getappdata(hFig, 'ResultsFile'))
        err = 'No sources available for this figure.';
        return
    end   
    % Get current atlas
    [sAtlas, iAtlas, sSurf, iSurf] = GetAtlas();
    % If atlas empty: do not use it
    if isempty(sAtlas.Scouts)
        sAtlas = [];
    end
    
    % Get ResultsFile and Surface
    ResultsFile = getappdata(hFig, 'ResultsFile');
    % Load results file
    sResults = in_bst_results(ResultsFile, 0, 'ImagingKernel', 'GoodChannel', 'HeadModelFile', 'SurfaceFile');
    % Get head model
    HeadModel = in_headmodel_bst(sResults.HeadModelFile, 0, 'Gain');
    if isempty(HeadModel)
        err = 'Could not load Head Model';
        return;
    end
    % Get leadfield matrix with only good channels 
    Leadfield = HeadModel.Gain(sResults.GoodChannel, :);
    if isempty(Leadfield)
        err = 'Could not retrieve Leadfield matrix from result file';
        return;
    end
    
    % Progress bar
    bst_progress('start', 'Surface clustering', 'Clustering...');
    % Clustering
    [Labels,err] = tess_cluster_leadfield(sSurf, sResults.ImagingKernel, Leadfield, sAtlas);
    if isempty(Labels)
        exp = 'MLC is currently only supported on actual model. (Not Downsampled Atlas).';
        bst_error([err exp], 'Maximum Leadfield Clustering', 0);
        return;
    end
    iAtlasNew = CreateAtlasBasedOnCluster(Labels, sResults.SurfaceFile);
    if isempty(iAtlasNew)
        err = 'An error occured during the Atlas creation.';
        return;        
    end
    % Progress bar
    bst_progress('stop');
end

%% ===== CREATE ATLAS: MULTIRESOLUTION ANALYSIS SCOUTS =====
function [iAtlas,err] = CreateMRACluster()
    % Init varout
    iAtlas = [];
    err = [];
    % Ask the number of iteration
    nIter = java_dialog('input', 'Number of iterations:', 'Multiresolution Analysis', [], '1');
    if isempty(nIter) || isempty(str2num(nIter))
        return
    end
    nIter = str2num(nIter);
    % Progress bar
    bst_progress('start', 'Surface clustering', 'Clustering...');
    % Get results file name
    global GlobalData;
    ResultsFile = GlobalData.DataSet.Results(1).FileName;
    % Load results file
    Results = in_bst_results(ResultsFile, 1, 'ImagingKernel', 'ImageGridAmp', 'GoodChannel', 'HeadModelFile', 'SurfaceFile');
    if isempty(Results)
        err = 'Could not load results file';
        return;
    end
    % Get surface
    Surface = in_tess_bst(Results.SurfaceFile);
    if isempty(Surface)
        err = 'Could not load surface';
        return;
    end
    % Multiresolution is only supported for whole cortex model
    if size(Results.ImageGridAmp,1) ~= size(Surface.Vertices,1)
        err = 'Multiresolution is currently only supported for whole cortex models';
        bst_error(err, 'Multiresolution ROI', 0);
        return;
    end
    %
    Options.method      = 'corr';
    Options.partial     = 0;
    Options.order       = 10;
    Options.nTrials     = 1;
    Options.standardize = true;
    Options.flagFPE     = false;
    Options.nSitesX     = [];
    Options.nSitesY     = [];
    %
    Labels = zeros(size(Surface.Vertices,1),1);
    for i=1:nIter
        fprintf('BST> Multiresolution Analysis Iteration #%i/%i\n', i, nIter);
        Labels = Labels + bst_connectivity_mra(Results.ImageGridAmp, Surface, Options);
    end
    Labels = round(Labels / nIter);
        
    % The choice of which region to keep is up to the user
    %   Labels = zeros(length(IterationMap),1);
    %   Highest = IterationMap == max(IterationMap);
    %   Labels(Highest) = 1;%1:sum(Highest);
    iAtlas = CreateAtlasBasedOnCluster(Labels, Results.SurfaceFile);
    if isempty(iAtlas)
        err = '';
        return;
    end
    % ===== Color the scouts =====
    % 
    uScouts = unique(Labels);
    % Note: Maybe use the current colormap
    cMap = jet(length(uScouts));
    % 
    SurfaceColor = cMap(uScouts,:);
    % Get the current surface
    [tmp, sSurf] = GetScouts();
    sAtlas = sSurf.Atlas(iAtlas);
    for iScout = 1:length(sAtlas.Scouts)
        sAtlas.Scouts(iScout).Color = SurfaceColor(iScout,:);
    end
    % Update atlas and graphical objects
    SetAtlas([], iAtlas, sAtlas);
    % Progress bar
    bst_progress('stop');
end

%% ===== CREATE ATLAS: LEADFIELD CLUSTERING =====
function [iAtlas, err] = CreateFunctionalCluster()
    % Init varout
    err = [];
    % Get selected figure
    hFig = bst_figures('GetCurrentFigure', '3D');
    if isempty(hFig) || ~ishandle(hFig) || isempty(getappdata(hFig, 'ResultsFile'))
        err = 'No sources available for this figure.';
        return
    end   
    % Get current atlas
    [sAtlas, iAtlas, sSurf, iSurf] = GetAtlas();
    % If atlas empty: do not use it
    if isempty(sAtlas.Scouts)
        sAtlas = [];
    end
    
    % Get ResultsFile and Surface
    ResultsFile = getappdata(hFig, 'ResultsFile');
    % Load results file
    sResults = in_bst_results(ResultsFile, 0, 'ImagingKernel', 'GoodChannel', 'HeadModelFile', 'SurfaceFile');
    % Get head model
    HeadModel = in_headmodel_bst(sResults.HeadModelFile, 0, 'Gain');
    if isempty(HeadModel)
        err = 'Could not load Head Model';
        return;
    end
    % Get leadfield matrix with only good channels 
    Leadfield = HeadModel.Gain(sResults.GoodChannel, :);
    if isempty(Leadfield)
        err = 'Could not retrieve Leadfield matrix from result file';
        return;
    end
    
    % Progress bar
    bst_progress('start', 'Surface clustering', 'Clustering...');
    % Clustering
    [Labels,err] = tess_cluster_functional(sSurf, sResults.ImagingKernel, Leadfield, sAtlas);
    if isempty(Labels)
        exp = 'MLC is currently only supported on actual model. (Not Downsampled Atlas).';
        bst_error([err exp], 'Maximum Leadfield Clustering', 0);
        return;
    end
    iAtlasNew = CreateAtlasBasedOnCluster(Labels, sResults.SurfaceFile);
    if isempty(iAtlasNew)
        err = 'An error occured during the Atlas creation.';
        return;        
    end
    % Progress bar
    bst_progress('stop');
end


%% ===== CREATE ATLAS BASED ON PROVIDED LABELS =====
function [iAtlas,errMessage] = CreateAtlasBasedOnCluster(Labels, SurfaceFile)
    global GlobalData;
    % Init varout
    iAtlas = [];
    errMessage = [];
    % Progress bar
    bst_progress('start', 'Surface clustering', 'Creating scouts...');
    % If no specified file
    if isempty(SurfaceFile)
        % Get current surface if possible
        SurfaceFile = GlobalData.CurrentScoutsSurface;
    end
    % Is surface file is loaded
    SurfaceLoaded = 0;
    if strcmpi(SurfaceFile, GlobalData.CurrentScoutsSurface)
        SurfaceLoaded = 1;
    end
    % Get surface from specified file
    sSurf = in_tess_bst(SurfaceFile);
    if isempty(sSurf)
        errMessage = 'Could not load surface';
        return;
    end
    % 
    uniqueLabels = unique(Labels(Labels ~= 0));
    nClust = length(uniqueLabels);
    % Split hemispheres
    [tmp, lH, isConnected] = tess_hemisplit(sSurf);
    lH = find(lH);
    % Create a new atlas
    sAtlas = db_template('Atlas');
    sAtlas.Name = ['Cluster Atlas: ' num2str(nClust)];
    % String format depends on the number of clusters
    if (nClust > 99)
        strFormat = '%03d';
    else
        strFormat = '%02d';
    end
    % Plot new scouts
    for iScout = 1:nClust
        sAtlas.Scouts(iScout).Vertices = find(Labels == uniqueLabels(iScout));
        sAtlas.Scouts(iScout).Seed     = sAtlas.Scouts(iScout).Vertices(1);
        sAtlas.Scouts(iScout).Label    = sprintf(strFormat, uniqueLabels(iScout));
        sAtlas.Scouts(iScout).Color    = rand(1,3);
        sAtlas.Scouts(iScout).Function = 'Mean';
        % Assign hemisphere
        if isConnected
            sAtlas.Scouts(iScout).Region = 'UU';
        else
            if (any(sAtlas.Scouts(iScout).Vertices(1) == lH))
                sAtlas.Scouts(iScout).Region = 'LU';
            else
                sAtlas.Scouts(iScout).Region = 'RU';
            end
        end
    end
    % Update the seeds
    sAtlas.Scouts = SetScoutsSeed(sAtlas.Scouts, sSurf.Vertices);
    % Saving atlas
    if (SurfaceLoaded)
        % Usual way
        iAtlas = SetAtlas(SurfaceFile, 'Add', sAtlas);
    else
        % Save ourself
        Atlas = sSurf.Atlas;
        % Assign index
        iAtlas = length(Atlas) + 1;
        % 
        sAtlas = FixAtlasStruct(sAtlas);
        % Add atlas to the specified surface
        Atlas(iAtlas) = sAtlas;
        % Save file
        s.Atlas = Atlas;
        s.iAtlas = iAtlas;
        bst_save(file_fullpath(SurfaceFile), s, 'v7', 1);
    end
    % Update list of atlases
    UpdateAtlasList();
    % Progress bar
    bst_progress('stop');
end

%% ===== SUBDIVIDE SCOUTS =====
% USAGE:  SubdivideScouts(isAllScouts=1, Method=ask, param=ask)
% INPUTS:
%    - isAllScouts : If 0, use only the selected scouts
%    - Method      : {'fixed', 'area', 'vertices'}
%    - param       : Input value for the selected method
function SubdivideScouts(isAllScouts, Method, param)
    % === PARSE INPUTS ===
    if (nargin < 1)
        isAllScouts = 1;
    end
    % Ask for methid if not provided
    if (nargin < 2) || isempty(Method)
        Method = [];
    end
    % Ask for parameter value if not provided
    if (nargin < 3) || isempty(param)
        param = [];
    end
    
    % === GET SCOUTS ===
    % Get surface
    [sAtlas, iAtlas, sSurf] = GetAtlas();
    if isempty(sSurf)
        return;
    end
    % Get all scouts
    if (isAllScouts)
        sSelScouts = GetScouts();
        iSelScouts = 1:length(sSelScouts);
    % Get selected scouts
    else
        [sSelScouts, iSelScouts] = GetSelectedScouts();
    end
    % If not selected scout: return
    if isempty(iSelScouts)
        return;
    end
    
    % === GET PARAMETERS ===
    % Ask for methid if not provided
    if isempty(Method)
        Method = java_dialog('question', ['Subdivide each scout in:' 10 ...
            ' - a fixed number of sub-regions (fixed)' 10 ...
            ' - sub-regions with a given area (area)' 10, ...
            ' - sub-regions with a given number of vertices (vertices)' 10 10], ...
            'Subdivide scouts', [], {'Fixed', 'Area', 'Vertices', 'Cancel'}, 'Fixed');
        if isempty(Method) || strcmpi(Method, 'Cancel')
            return;
        end
        Method = lower(Method);
    end
    % Ask for parameter value if not provided
    if isempty(param)
        switch lower(Method)
            case 'fixed',    param = java_dialog('input', 'Number of sub-regions:',    'Clustering: Fixed number', [], '5');
            case 'area',     param = java_dialog('input', 'Area of the sub-regions (cm2):', 'Clustering: Area', [], '1');
            case 'vertices', param = java_dialog('input', 'Number of vertices in the sub-regions:', 'Clustering: Number of vertices', [], '50');
        end
        if isempty(param) || isempty(str2num(param))
            return
        end
        param = str2num(param);
    end
    
    % === COPY ATLAS IF NEEDED ===
    if isAtlasReadOnly(sAtlas, 0)
        isNewAtlas = 1;
    else
        isNewAtlas = 0;
    end
    
    % === SUBDIVIDE SCOUTS ===
    % Progress bar
    bst_progress('start', 'Subdivide scouts', 'Clustering...');
    % Init new scouts id
    sNewScouts = repmat(db_template('Scout'), 0);
    iDelScouts = [];
    % For each scout we apply a K-mean clustering
    for i = 1:length(sSelScouts)
        nVertices = length(sSelScouts(i).Vertices);
        switch lower(Method)
            case 'fixed'
                nClust = param;
            case 'area'
                % Compute the total area (cm2)
                totalArea = sum(sSurf.VertArea(sSelScouts(i).Vertices)) * 100 * 100;
                nClust = round(totalArea / param);
            case 'vertices'
                nClust = round(nVertices / param);
        end
        % Make sure we have enough vertices to make a triangular region
        % Using a threshold of < 5 causes too many "line" regions..
        if (nClust > nVertices / 5)
            nClust = floor(nVertices / 5);
        end
        % No subdivision: jump to the next scout
        if (nClust <= 1)
            if isNewAtlas
                sNewScouts(end+1) = sSelScouts(i);
            end
            continue;
        end
        % K-Mean the vertices
        % Labels = kmeans(sSurf.Vertices(sSelScouts(i).Vertices,:), nClust);
        Labels = tess_cluster(sSurf.VertConn(sSelScouts(i).Vertices, sSelScouts(i).Vertices), nClust);
        uniqueLabels = unique(Labels);
        % Create new scouts
        for iLabel = 1:length(uniqueLabels)
            sNewScouts(end+1) = db_template('Scout');
            sNewScouts(end).Vertices = sSelScouts(i).Vertices(Labels == uniqueLabels(iLabel));
            sNewScouts(end).Label    = [sSelScouts(i).Label '.' num2str(iLabel)];
            sNewScouts(end).Function = sSelScouts(i).Function;
            sNewScouts(end).Region   = sSelScouts(i).Region;
            sNewScouts(end).Color    = sSelScouts(i).Color .* (1 - iLabel/length(uniqueLabels)/2);
        end
        iDelScouts(end+1) = iSelScouts(i);
    end
    % No scout 
    if isempty(iDelScouts)
        bst_progress('stop');
        return;
    end
    
    % === UPDATE GUI ===
    % Generate seeds for the new scouts
    sNewScouts = SetScoutsSeed(sNewScouts, sSurf.Vertices);
    % Create new atlas
    if isNewAtlas
        sAtlas.Scouts = sNewScouts;
        sAtlas.Name   = [sAtlas.Name ' [' num2str(length(sNewScouts)) ']'];
        SetAtlas([], 'Add', sAtlas);
    % Subdivide existing scouts
    else
        % Delete replaced scouts
        RemoveScouts(iDelScouts);
        % Add new scouts
        iNewScouts = SetScouts([], 'Add', sNewScouts);
        % Update scouts panel
        UpdateScoutsList();   
        % Display new scout
        PlotScouts(iNewScouts);
    end
    % Progress bar
    bst_progress('stop');
end


%% ===== EDIT ATLAS LABEL =====
function EditAtlasLabel(varargin)
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Get surface
    [sAtlas, iAtlas, sSurf] = GetAtlas();
    if isempty(sAtlas)
        return;
    end
    % Ask user for a new Atlas name
    newLabel = java_dialog('input', 'Please enter a name for the atlas:', 'Rename selected atlas', [], sAtlas.Name);
    if isempty(newLabel) || strcmpi(newLabel, sAtlas.Name)
        return
    end
    % Check if if already exists
    if any(strcmpi({sSurf.Name}, newLabel))
        java_dialog('warning', 'Atlas name already exists.', 'Rename selected atlas');
        return;
    end
    % Update Scout definition
    sAtlas.Name = newLabel;
    % Update atlas and graphical objects
    SetAtlas([], iAtlas, sAtlas);
end

%% ===== REMOVE ATLAS =====
function RemoveAtlas(varargin)
    global GlobalData;
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Get surface
    [sAtlas, iAtlas, sSurf, iSurf] = GetAtlas();
    if isempty(sAtlas)
        return;
    end
    if (iAtlas == 1)
        java_dialog('warning', 'The list of user scouts cannot be deleted.', 'Delete selected atlas');
        return;
    end
    % Set the previous atlas as the selected one (there is always at least one)
    SetCurrentAtlas(iAtlas - 1);
    % Remove atlas
    GlobalData.Surface(iSurf).Atlas(iAtlas) = [];
    % Update list of atlases
    UpdateAtlasList();
end

%% ===== GET SCOUT FOR VERTEX =====
function iScouts = GetScoutForVertex(Atlas, iVertices)
    iScouts = [];
    for i = 1:length(Atlas.Scouts)
        if any(ismember(iVertices, Atlas.Scouts(i).Vertices))
            iScouts = union(iScouts, i);
        end
    end
end


%% ===== UNDO =====
function Undo()
    global GlobalData;
    % Get current atlas
    [sAtlas, iAtlas, sSurf, iSurf] = GetAtlas();
    % If the atlas was not modified: skip
    if ~GlobalData.Surface(iSurf).isAtlasModified
        disp('BST> No modifications to undo.');
        return;
    end
    % Progress bar
    bst_progress('start', 'Undo', 'Reloading previous version...');
    % Load previous version of the surface
    TessMat = load(file_fullpath(sSurf.FileName), 'Atlas', 'iAtlas');
    % Get current figures
    hFigures = bst_figures('GetFigureWithSurface', sSurf.FileName);
    % Remove all scouts
    for i = 1:length(hFigures)
        RemoveScoutsFromFigure(hFigures(i), 1);
    end
    % Redefine the current atlas
    if (iAtlas > length(TessMat.Atlas))
        iAtlas = TessMat.iAtlas;
    end
    % Replace current version
    GlobalData.Surface(iSurf).Atlas = panel_scout('FixAtlasStruct', TessMat.Atlas);
    GlobalData.Surface(iSurf).iAtlas = iAtlas;
    GlobalData.Surface(iSurf).isAtlasModified = 0;
    % Update the atlas list
    UpdateAtlasList(GlobalData.Surface(iSurf));
    % Set the current atlas again
    SetCurrentAtlas(iAtlas, 1);
    % Re-plot the scouts
    ReloadScouts();
    % Progress bar
    bst_progress('stop');
end


%% ===== SAVE MODIFICATIONS =====
function SaveModifications()
    global GlobalData;
    % Loop on all the loaded surfaces
    for iSurf = 1:length(GlobalData.Surface)
        % If the atlas was not modified: skip
        if ~GlobalData.Surface(iSurf).isAtlasModified
            continue;
        end
        disp(['BST> Saving scouts in surface: ' GlobalData.Surface(iSurf).FileName]);
        % Remove handles
        s.Atlas  = GlobalData.Surface(iSurf).Atlas;
        s.iAtlas = GlobalData.Surface(iSurf).iAtlas;
        for ia = 1:length(s.Atlas)
            for is = 1:length(s.Atlas(ia).Scouts)
                s.Atlas(ia).Scouts(is).Handles = [];
            end
        end
        % Save file
        bst_save(file_fullpath(GlobalData.Surface(iSurf).FileName), s, 'v7', 1);
        % Reset the modified state
        GlobalData.Surface(iSurf).isAtlasModified = 0;
    end
end


%% ===============================================================================
%  ====== SCOUTS CREATION/EDITION ================================================
%  ===============================================================================
%% ===== CREATE SCOUT =====
% USAGE:  [sNewScout, iNewScout] = CreateScout(newVertices, newSeed=[], SurfaceFile=Current)
function [sNewScout, iNewScout] = CreateScout(newVertices, newSeed, SurfaceFile)
    global GlobalData;
    % Parse inputs
    if (nargin < 3) || isempty(SurfaceFile)
        SurfaceFile = GlobalData.CurrentScoutsSurface;
    end
    if (nargin < 2) || isempty(newSeed)
        newSeed = [];
    end
    % Get other scouts with same surface file
    [sScouts, sSurf] = GetScouts(SurfaceFile);
    % Store current scout coordinates
    sNewScout = db_template('Scout');
    sNewScout.Vertices = newVertices;
    % Seed
    if isempty(newSeed)
        sNewScout = SetScoutsSeed(sNewScout, sSurf.Vertices);
    else
        sNewScout.Seed = newSeed;
    end
    % Define scouts labels (Label=index)
    iDisplayIndice = length(sScouts) + 1;
    sNewScout.Label = int2str(iDisplayIndice);
    % Check that the scout name does not exist yet (else, add a ')
    if ~isempty(sScouts)
        while ismember(sNewScout.Label, {sScouts.Label})
            iDisplayIndice = iDisplayIndice + 1;
            sNewScout.Label = int2str(iDisplayIndice);
        end
    end
    % Register new scout
    iNewScout = SetScouts(SurfaceFile, 'Add', sNewScout);
end


%% ===== CREATE SCOUT: MOUSE =====
function CreateScoutMouse(hFig) %#ok<DEFNU>
    global GlobalData;
    % Get current surface
    TessInfo = getappdata(hFig, 'Surface');
    iTess    = getappdata(hFig, 'iSurface');
    if isempty(iTess)
        return;
    end

    % === POINT SELECTION ON SURFACE ===
    if ~strcmpi(TessInfo(iTess).Name, 'Anatomy')
        hSurface = TessInfo(iTess).hPatch;
        % Get mouse 3D selection
        [pout, vout, vi] = select3d(hSurface);
        
    % === POINT SELECTION ON MRI ===
    else
        % Get vertices
        sSubject = bst_get('MriFile', sMri.FileName);
        % If there is no cortex for this subject: exit
        if isempty(sSubject.iCortex)
            return
        end
        CortexFile = sSubject.Surface(sSubject.iCortex).FileName;
        sSurfCortex = bst_memory('LoadSurface', CortexFile);
       
        % Select a point in the MRI slices
        [TessInfo, iTess, pout] = panel_coordinates('ClickPointInSurface', hFig, 'Anatomy');
        % Find the closest cortical point from this MRI coordinates
        dist = (sSurfCortex.Vertices(:,1) - pout(1)) .^ 2 + ...
               (sSurfCortex.Vertices(:,2) - pout(2)) .^ 2 + ...
               (sSurfCortex.Vertices(:,3) - pout(3)) .^ 2;
        [minDist, iMinDist] = min(dist);
        % If selected point is too far away from cortical surface : return
        if (sqrt(minDist) > 0.01)
            return
        end
        % Select the closest point
        vout = sSurfCortex.Vertices(iMinDist, :)';
        vi   = iMinDist;
    end
    % Check that a point was selected
    if isempty(vout)
        return
    end   

    % === CREATING SCOUT OR ADDING POINTS ===
    % Get selected scouts
    [sSelScouts, iSelScouts] = GetSelectedScouts();
    % If there is more that one selected scout: select only the first one
    if (length(iSelScouts) > 1)
        SetSelectedScouts(iSelScouts(1));
        sSelScouts = sSelScouts(1);
        iSelScouts = iSelScouts(1);
    end
    isNewScout = (length(sSelScouts) ~= 1);

    % ==== NEW SCOUT ====
    if isNewScout
        % If scout surface not defined (happens it is NOT a cortex or anatomy surface)
        if isempty(GlobalData.CurrentScoutsSurface)
            GlobalData.CurrentScoutsSurface = TessInfo(iCortex).SurfaceFile;
        end
        % Create new scout
        [sScout, iScout] = CreateScout(vi, vi);
    % ==== ADD/REMOVE POINT TO SELECTED SCOUT ====
    else
        % Check if the SHIFT key is pressed
        isShift = getappdata(hFig, 'isShiftKeyDown');
        % Remove vertex
        if isShift
            % Cannot remove the seed
            if (sSelScouts.Seed == vi)
                return;
            end
            sSelScouts.Vertices = setdiff(sSelScouts.Vertices, vi);
        % Add vertex
        else
            sSelScouts.Vertices = unique([sSelScouts.Vertices, vi]);
        end
        % Save updated scout
        iScout = SetScouts([], iSelScouts, sSelScouts);
    end
    
    % === UPDATE INTERFACE ===
    % Display scout patch
    PlotScouts(iScout);
    % Create new scout: update everything
    if isNewScout
        % Update "Scouts" panel
        UpdatePanel();
        % Select new scout
        SetSelectedScouts(iScout);
        % Deselect "AddScout" button (only if creating new scout)
        SetSelectionState(0);
    % Just update the scout properties
    else
        UpdateScoutProperties();
    end
    % OverlayCube for 3D MRI display is not updated => Need to update it
    UpdateScoutsDisplay('current');
end


%% ===== CREATE SCOUT: CORRELATION =====
function CreateScoutCorr(varargin)
    global GlobalData;
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Stop scout edition
    SetSelectionState(0);
    
    % ===== GET FIGURE INFO ====
    % Get selected figure
    [hFig,iFig,iDS] = bst_figures('GetCurrentFigure', '3D');
    if isempty(hFig)
        return
    end
    % Get results file
    ResultsFile = getappdata(hFig, 'ResultsFile');
    DataFile    = getappdata(hFig, 'DataFile');
    if isempty(ResultsFile)
        bst_error('No sources displayed in this figure.', 'Expand with correlation', 0);
        return
    end
    if isempty(DataFile)
        bst_error('This operation can only be performed with sources saved in kernel mode.', 'Correlation with sensor', 0);
        return;
    end
    % Get loaded results file 
    iResult = bst_memory('GetResultInDataSet', iDS, ResultsFile);
    
    % ===== OPTIONS =====
    % Channel name
    ChannelName = java_dialog('combo', 'Select the channel name:', 'Correlation with sensor', [], {GlobalData.DataSet(iDS).Channel.Name});
    if isempty(ChannelName)
        return
    end    
    % Default values
    TimeWindow = GlobalData.DataSet(iDS).Measures.Time;
    Threshold  = 0.98;
    % Ask confirmation of the thresolh level to the user
    res = java_dialog('input', ...
        {'Time window for correlation computation (in ms):',...
         'Minimum correlation coefficient (<1):'}, ...
        'Correlation with sensor', [], {sprintf('%3.2f %3.2f', TimeWindow * 1000), num2str(Threshold)});
    if isempty(res)
        return;
    end
    % Read options
    TimeWindow  = str2num(res{1}) ./ 1000;
    Threshold   = str2num(res{2});
    if (length(TimeWindow) ~= 2) || isempty(Threshold)
        bst_error('Invalid options.', 'Correlation with sensor', 0);
        return;
    end
    % Get channel
    iChannel = channel_find(GlobalData.DataSet(iDS).Channel, ChannelName);
    if (length(iChannel) ~= 1)
        bst_error(['Channel "' ChannelName '" does not exist.'], 'Correlation with sensor', 0);
        return;
    end
    
    % ===== LOAD RESULTS =====
    % Find time indices for correlation computation
    TimeVector = bst_memory('GetTimeVector', iDS, iResult);
    iTime = bst_closest(TimeWindow, TimeVector);
    iTime = iTime(1):iTime(2);
    % Invalid time window
    if isempty(iTime)
        bst_error('Invalid time window.', 'Correlation with sensor', 0);
        return;
    end
    % Get recordings
    F = bst_memory('GetRecordingsValues', iDS, iChannel, iTime);
    if isempty(F)
        bst_error('This operation can only be performed with sources saved in kernel mode.', 'Correlation with sensor', 0);
        return;
    end
    % Get results values over the current time window
    [ResultsValues, nComponents] = bst_memory('GetResultsValues', iDS, iResult, [], iTime);
    % Error if unconstrained sources
    if (nComponents > 1)
        bst_error('Not supported yet for unconstrained sources.', 'Correlation', 0);
        return;
    end
    
    % ===== COMPUTE CORRELEATION =====
    % Compute correlation coefficients for all sources
    CorrCoeff = bst_corrn(F, ResultsValues);
    % Find maximum correlation value
    [MaxCorr, iMaxCorr] = max(abs(CorrCoeff));
    % Keep only sources which correlate best
    iverts = find(abs(CorrCoeff) >= Threshold);
    if isempty(iverts)
        iverts = iMaxCorr;
        java_dialog('warning', sprintf(['Correlation threshold too high: no source was found matching specified correlation score.' 10 ...
                                        'Adjusting to best correlation found: %1.3f'], MaxCorr), 'Correlation with sensor');
    end
    % Convert to atlas-based sources if necessary
    if ~isempty(GlobalData.DataSet(iDS).Results(iResult).Atlas)
        iVertSeed = GlobalData.DataSet(iDS).Results(iResult).Atlas.Scouts(iMaxCorr).Seed;
        iVertices = unique([GlobalData.DataSet(iDS).Results(iResult).Atlas.Scouts(iverts).Vertices]);
    else
        iVertSeed = iMaxCorr;
        iVertices = iverts;
    end
    % Create new scout
    sScout             = db_template('Scout');
    sScout.Vertices    = iVertices;
    sScout.Seed        = iVertSeed;
    sScout.Label       = ['Corr with ' ChannelName];
    % Add to list of loaded scouts
    iScout = SetScouts([], 'Add', sScout);
    
    % ===== DISPLAY =====
    UpdatePanel();
    PlotScouts(iScout);
    UpdateScoutsDisplay('current');
    SetSelectedScouts(iScout);
end


%% ===== CREATE SCOUT: MAXIMUM VALUE =====
% Usage:  CreateScoutMax(iScout) : Keep only the maximum value in the selected scout
%         CreateScoutMax()       : Create new scout with the vertex with maximum value at current time
function CreateScoutMax(iScout)
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Parse input
    if (nargin < 1)
        isNewScout = 1;
    else
        isNewScout = 0;
        sScout = GetScouts(iScout);
    end
    % Stop scouts edition
    SetSelectionState(0);
    % Get current cortical surface  
    [iTess, TessInfo] = panel_surface('GetSelectedSurface');
    % If no cortex surface available
    if isempty(iTess) || isempty(TessInfo(iTess).Data) || isempty(TessInfo(iTess).DataSource.FileName)
        java_dialog('warning', 'No 3D figure with sources available.', 'Find maximum value');
        return;
    end
    
    % Get the vertices with maximal value, at the present time ONLY
    if isNewScout
        % Get surface file to which the scout will be attached
        if strcmpi(TessInfo(iTess).Name, 'Anatomy')
            % If anatomy surface : use correspondant cortex surface instead
            sSurfCortex = bst_get('SurfaceFileByType', TessInfo(iTess).SurfaceFile, 'Cortex');
            SurfaceFile = sSurfCortex.FileName;
        else
            SurfaceFile = TessInfo(iTess).SurfaceFile;
        end
        % If creating scout: look for max in the whole surface
        [valMax, iVertMax] = max(abs(TessInfo(iTess).Data));
        % If it is a downsampled version of the sources matrix, get what vertex it is for real
        if ~isempty(TessInfo(iTess).DataSource.Atlas)
            iVertSeed = TessInfo(iTess).DataSource.Atlas.Scouts(iVertMax).Seed;
            iVertices = TessInfo(iTess).DataSource.Atlas.Scouts(iVertMax).Vertices;
        else
            iVertSeed = iVertMax(1);
            iVertices = iVertMax(1);
        end
        % Create a new scout with the maximum (Keep only the FIRST maximal vertex)
        [sScout, iScout] = CreateScout(iVertices, iVertSeed, SurfaceFile);
    else
        % If it is a downsampled version: error
        if ~isempty(TessInfo(iTess).DataSource.Atlas)
            java_dialog('warning', 'This menu is not available for atlas-based source files.', 'Find maximum value');
            return;
        end
        % If editing scout: look for max only in the scout's vertices
        [valMax, iVertMax] = max(abs(TessInfo(iTess).Data(sScout.Vertices)));
        iVertMax = sScout.Vertices(iVertMax);
        % Update scout (Keep only the FIRST maximal vertex)
        sScout.Vertices = iVertMax;
        sScout.Seed     = iVertMax(1);
        SetScouts([], iScout, sScout);
    end
    
    % Display scout patch
    PlotScouts(iScout);
    % Update "Scouts" panel
    if isNewScout
        UpdatePanel();
        % Select new scout
        SetSelectedScouts(iScout);
    else
        % Update panel "Scouts" fields
        UpdateScoutProperties();
        % Display/hide scouts and update MRI overlay mask
        UpdateScoutsDisplay('current');
    end
end


%% ===== EDIT SCOUT: SURFACE =====
function EditScoutSurface(varargin)
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Get selected scouts
    [sSelScouts, iSelScouts] = GetSelectedScouts();
    % Warning message if no scout selected
    if isempty(sSelScouts)
        java_dialog('warning', 'No scout selected.', 'Edit existing scout');
        return;
    end
    % Start edition of a scout (will deselect the scout)
    SetSelectionState(1);
    % Select again the first selected scout
    SetSelectedScouts(iSelScouts(1));
end


%% ===== EDIT SCOUT: MAX =====
function EditScoutMax(varargin)
    % Get selected scouts
    [sScouts, iScouts] = GetSelectedScouts();
    % Warning message if no scout selected
    if isempty(sScouts)
        java_dialog('warning', 'No scout selected.', 'Find maximum value');
        return;
    end
    % Process all the selected scouts
    for i = 1:length(iScouts)
        CreateScoutMax(iScouts(i));
    end
end


%% ===============================================================================
%  ====== SCOUTS EDITION =========================================================
%  ===============================================================================
%% ===== EDIT SCOUT LABEL =====
% Rename one and only one selected scout
function EditScoutLabel(varargin)
    % Stop scout edition
    SetSelectionState(0);
    % Get selected scouts
    [sScout, iScout] = GetSelectedScouts();
    % Get all scouts
    sAllScouts = GetScouts();
    % Warning message if no scout selected
    if isempty(sScout)
        java_dialog('warning', 'No scout selected.', 'Rename selected scout');
        return;
    % If more than one scout selected: keep only the first one
    elseif (length(sScout) > 1)
        iScout = iScout(1);
        sScout = sScout(1);
        SetSelectedScouts(iScout);
    end
    % Ask user for a new Scout Label
    newLabel = java_dialog('input', sprintf('Please enter a new label for scout "%s":', sScout.Label), ...
                             'Rename selected scout', [], sScout.Label);
    if isempty(newLabel) || strcmpi(newLabel, sScout.Label)
        return
    end
    % Check if if already exists
    if any(strcmpi({sAllScouts.Label}, newLabel))
        java_dialog('warning', 'Scout name already exists.', 'Rename selected cluster');
        return;
    end
    % Update Scout definition
    sScout.Label = newLabel;
    % Update graphical objects
    set([sScout.Handles.hLabel], 'String', newLabel);
    % Save modifications
    SetScouts([], iScout, sScout);
    % Update JList
    UpdateScoutsList();
    % Select back selected scout
    SetSelectedScouts(iScout);
end

%% ===== EDIT SCOUTS SIZE =====
function EditScoutsSize(action)
    global mutexGrowScout;
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Stop scouts edition
    SetSelectionState(0);
    % Get "Scouts" panel controls
    ctrl = bst_get('PanelControls', 'Scout');
    % Use a mutex to prevent the function from being executed more than once at the same time
    if isempty(mutexGrowScout) || (mutexGrowScout > 1)
        % Entrance accepted
        tic
        mutexGrowScout = 0;
    else
        % Entrance rejected (another call is not finished,and was call less than 1 seconds ago)
        mutexGrowScout = toc;
        disp('Call to EditScoutsSize ignored...');
        return
    end
    
    % Get selected scouts
    [sScouts, iScouts] = GetSelectedScouts();
    % Can grow only scouts that are DISPLAYED IN AT LEAST ONE FIGURE
    if isempty(sScouts) || isempty(sScouts(1).Handles)
        return
    end
    % Get figure
    hFig = sScouts(1).Handles(1).hFig;
    % If constrained growth
    isContrained = ctrl.jToggleConst.isSelected();
    
    % Get cortex and anatomy surface handle
    [iTess, TessInfo, hFig, sSurf] = panel_surface('GetSelectedSurface', hFig);
    % Just for the special purpose of editing the scalp surface (remove imperfections)
    patchVertices = get(TessInfo(iTess).hPatch, 'Vertices');
    
    % Process all the selected scouts
    for i = 1:length(sScouts)
        % Get vertices of the scout (indices)
        vi = sScouts(i).Vertices;
        % Get coordinates of the seed
        seedXYZ = patchVertices(sScouts(i).Seed, :);
        % Get vertices with values below the data threshold
        iUnderThresh = [];
        if isContrained
            if ~isempty( TessInfo(iTess).Data )
                % Apply threshold
                if (TessInfo(iTess).DataThreshold > 0)
                    ColormapInfo = getappdata(hFig, 'Colormap');
                    sColormap = bst_colormaps('GetColormap', ColormapInfo.Type);
                    TessInfo(iTess).Data = figure_3d('ThresholdSurfaceData', TessInfo(iTess).Data, TessInfo(iTess).DataLimitValue, TessInfo(iTess).DataThreshold, sColormap);
                end
                % Find values that are below the thresolhd (set to zero)
                iUnderThresh = find(abs(TessInfo(iTess).Data) == 0);
            end
        end
        
        % Now grow/shrink a patch around the selected probe by adding/removing a ring neighbors
        switch (action)
            case 'Grow'
                viNew = tess_scout_swell(vi, sSurf.VertConn);
                % Remove vertices under the threshold
                viNew = setdiff(viNew, iUnderThresh);
                if ~isempty(viNew)
                    % Get vertices of the scout (coordinates)
                    vXYZ = patchVertices(viNew, :);
                    % Compute the distance from each point to the seed
                    distFromSeed = sqrt((vXYZ(:,1)-seedXYZ(1)).^2 + (vXYZ(:,2)-seedXYZ(2)).^2 + (vXYZ(:,3)-seedXYZ(3)).^2);
                    % === LIMIT GROWTH WITH A SPHERE ===
                    % Radius of the sphere = mean(dist(v, seed)) + 1.5*std
                    sphereRadius = mean(distFromSeed) + 1.5 * std(distFromSeed);
                    % Keep only vertices in a sphere around the Scout seed
                    vi = union(vi, viNew(distFromSeed <= sphereRadius));
                    % Check if there are vertices that are completely surrounded by the current scout (all its connections are with the scout)
                    iOut = setdiff(1:size(sSurf.VertConn,1), vi);
                    iAlone = iOut(~any(sSurf.VertConn(iOut,iOut)));
                    if ~isempty(iAlone)
                        iConn = find(sSurf.VertConn(iAlone,:));
                        if all(ismember(iConn, vi))
                            vi = union(vi, iAlone);
                        end
                    end
                end
                
            case 'Grow1'
                % Get closest neighbours
                viNew = setdiff(tess_scout_swell(vi, sSurf.VertConn), vi);
                % Remove vertices under the threshold
                viNew = setdiff(viNew, iUnderThresh);
                if ~isempty(viNew)
                    % Get new vertices of the scout (coordinates)
                    vXYZ = patchVertices(viNew, :);
                    % Compute the distance from each point to the seed
                    distFromSeed = sqrt((vXYZ(:,1)-seedXYZ(1)).^2 + (vXYZ(:,2)-seedXYZ(2)).^2 + (vXYZ(:,3)-seedXYZ(3)).^2);
                    % === ADD ONLY THE CLOSEST VERTEX ===
                    % Get the minimum distance
                    [minVal, iMin] = min(distFromSeed);
                    iMin = iMin(1);
                    % Add this vertex to scout vertices
                    vi = union(vi, viNew(iMin));
                end
                
            case 'Shrink1'
                % Remove a layer of connected vertices
                Expanded = tess_scout_swell(vi, sSurf.VertConn);
                viToRemove = tess_scout_swell(Expanded, sSurf.VertConn);
                viToRemove = intersect(viToRemove, vi);
                % Get vertices of the scout (coordinates)
                vXYZ = patchVertices(viToRemove, :);
                % Compute the distance from each point to the seed
                distFromSeed = sqrt((vXYZ(:,1)-seedXYZ(1)).^2 + (vXYZ(:,2)-seedXYZ(2)).^2 + (vXYZ(:,3)-seedXYZ(3)).^2);
                % === REMOVE ONLY THE FAREST VERTEX ===
                % Get the maximum distance
                [maxVal, iMax] = max(distFromSeed);
                iMax = iMax(1);
                % Remove this vertex from the scout vertices
                vi = setdiff(vi, viToRemove(iMax));
                
            case 'Shrink'
                % Remove a layer of connected vertices
                Expanded = tess_scout_swell(vi, sSurf.VertConn);
                viToRemove = tess_scout_swell(Expanded, sSurf.VertConn);
                % Get vertices of the scout (coordinates)
                vXYZ = patchVertices(vi, :);
                % Compute the distance from each point to the seed
                distFromSeed = sqrt((vXYZ(:,1)-seedXYZ(1)).^2 + (vXYZ(:,2)-seedXYZ(2)).^2 + (vXYZ(:,3)-seedXYZ(3)).^2);
                % === DEFINE SHRINK WITH A SPHERE ===
                % Radius of the sphere = mean(dist(v, seed)) + 1.5*std
                sphereRadius = mean(distFromSeed);
                % Keep only vertices in a sphere around the Scout seed
                viOutsideSphere = vi(distFromSeed > sphereRadius);
                % Remove only vertices that are removed by the two methods
                viToRemove = intersect(viToRemove, viOutsideSphere);
                vi = setdiff(vi, viToRemove);
                % Check if there are vertices that are completely isolated in the scout
                iAlone = vi(~any(sSurf.VertConn(vi,vi)));
                if ~isempty(iAlone)
                    vi = setdiff(vi, iAlone);
                end
        end
        
        % Save new list of vertices
        sScouts(i).Vertices = vi;       
        % If all the vertices were removed, keep initial scout vertex
        if isempty(sScouts(i).Vertices)
            sScouts(i).Vertices = sScouts(i).Seed;
        end
        % Update scout
        SetScouts([], iScouts(i), sScouts(i));
        % Display scout patch
        PlotScouts(iScouts(i));
    end

	% Release mutex 
    mutexGrowScout = [];
    % Update panel "Scouts" fields
    UpdateScoutProperties();
    % Display/hide scouts and update MRI overlay mask
    UpdateScoutsDisplay('current');
end

%% ===== EDIT SCOUTS COLOR =====
function EditScoutsColor(newColor)
    % Get selected scouts
    [sSelScouts, iSelScouts] = GetSelectedScouts();
    if isempty(iSelScouts)
        java_dialog('warning', 'No scout selected.', 'Edit scout color');
        return
    end
    % If color is not specified in argument : ask it to user
    if (nargin < 1)
        % Use previous scout color
        newColor = uisetcolor(sSelScouts(1).Color, 'Select scout color');
        % If no color was selected: exit
        if (length(newColor) ~= 3) || all(sSelScouts(1).Color == newColor)
            return
        end
    end
    % Update scouts color
    for i = 1:length(sSelScouts)
        sSelScouts(i).Color = newColor;
        % Update color for all graphical instances
        set([sSelScouts(i).Handles.hScout],    'MarkerEdgeColor', newColor, 'MarkerFaceColor', newColor);
        set([sSelScouts(i).Handles.hVertices], 'MarkerEdgeColor', newColor, 'MarkerFaceColor', newColor);  
        set([sSelScouts(i).Handles.hPatch], 'FaceColor', newColor);
        set([sSelScouts(i).Handles.hContour], 'Color', newColor);
    end
    % Save scouts
    SetScouts([], iSelScouts, sSelScouts);
    % Update scouts list
    UpdateScoutsList();
end


%% ===== JOIN SCOUTS =====
% Join the scouts selected in the JList 
function JoinScouts(varargin)
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Stop scout edition
    SetSelectionState(0);
    % Get selected scouts
    [sScouts, iScouts] = GetSelectedScouts();
    % Need TWO scouts
    if (length(sScouts) < 2)
        java_dialog('warning', 'You need to select at least two scouts.', 'Join selected scouts');
        return;
    end

    % === Remove old scouts ===
    RemoveScouts(iScouts);
    % === Join scouts ===
    % Create new scout
    sNewScout = db_template('Scout');
    % Copy unmodified fields
    sNewScout.Seed = sScouts(1).Seed;
    % Vertices : concatenation
    sNewScout.Vertices = unique([sScouts.Vertices]);
    % Label : "Label1 & Label2 & ..."
    sNewScout.Label = sScouts(1).Label;
    for i = 2:length(sScouts)
        sNewScout.Label = [sNewScout.Label ' & ' sScouts(i).Label];
    end

    % Save new scout
    iNewScout = SetScouts([], 'Add', sNewScout);
    % Display new scout
    PlotScouts(iNewScout);
    % Update "Scouts Manager" panel
    UpdateScoutsList();   
    % Select last scout in list (new scout)
    SetSelectedScouts(iNewScout);
end


%% ===============================================================================
%  ====== OTHER SCOUTS OPERATIONS ================================================
%  ===============================================================================

%% ===== VIEW TIME SERIES =====
function ViewTimeSeries(varargin)
    % Stop scout editing
    SetSelectionState(0);
    % Get selected scouts
    sSelScouts = GetSelectedScouts();
    % Warning message if no scout selected
    if isempty(sSelScouts)
        java_dialog('warning', 'No scout selected.', 'Display time series');
        return;
    end
    % Display scouts
    view_scouts();
end

%% ===== SET SCOUT SEED =====
% USAGE:  sScouts = panel_scout('SetScoutsSeed', sScouts, Vertices)
function sScouts = SetScoutsSeed(sScouts, Vertices)
    % Process each scout
    for i = 1:length(sScouts)
        % Get center of the region
        V = Vertices(sScouts(i).Vertices,:);
        center = mean(V, 1);
        % Find the vertex that is closer to the center of the ROI
        [tmp, imin] = min(sum(bst_bsxfun(@minus, V, center) .^ 2, 2));
        sScouts(i).Seed = sScouts(i).Vertices(imin(1));
    end
end


%% ===== FORWARD MODEL FOR SCOUTS =====
% Simulate the surface data that could be recorded if only the selected scouts were activated
function ForwardModelForScout(varargin)
    % Stop scout edition
    SetSelectionState(0);
    
    % ===== GET ALL ACCESSIBLE DATA =====
    % Get selected figure
    hFig = bst_figures('GetCurrentFigure', '3D');
    if isempty(hFig) || ~ishandle(hFig) || isempty(getappdata(hFig, 'ResultsFile'))
        return
    end
    % Get ResultsFile and Surface
    ResultsFile = getappdata(hFig, 'ResultsFile');

    % Get selected scouts
    sScouts = GetSelectedScouts();
    % Some scouts were found : get their vertices
    if ~isempty(sScouts) && ~isempty(sScouts(1).Handles)
        % Get all source vertices to perform simulation
        iVertices = unique([sScouts.Vertices]);
    % No scouts: use all vertices to do simulation
    else
        iVertices = [];
    end
    
    % ===== BUILD COMMENT =====
    % Get a string to represent scouts
    strScouts = '';
    if ~isempty(sScouts)
        if (length(sScouts) > 1)
            strScouts = '(';
        end
        for i=1:length(sScouts)
            strScouts = [strScouts, sScouts(i).Label, ','];
        end
        if (length(sScouts) > 1)
            strScouts(end) = ')';
        else
            strScouts(end) = [];
        end
        strScouts = [strScouts, '@'];
    end
    
    % ===== CALL SIMULATION FILE =====
    bst_simulation(ResultsFile, iVertices, strScouts);
end

%% ===== EXPAND WITH CORRELATION =====
function ExpandWithCorrelation(varargin)
    global GlobalData;
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Stop scout edition
    SetSelectionState(0);
    % ===== GET ALL NEEDED INFO =====
    % Get selected scouts
    [sScout, iScout] = GetSelectedScouts();
    if isempty(sScout)
        java_dialog('warning', 'No scout selected.', 'Expand scout using correlation');
        return
    elseif (length(sScout) > 1)
        % More than one scout selected: select only the first one
        sScout = sScout(1);
        iScout = iScout(1);
        SetSelectedScouts(iScout);
    end

    % Get selected figure
    hFig = bst_figures('GetCurrentFigure', '3D');
    if isempty(hFig)
        return
    end
    % Get results file
    ResultsFile = getappdata(hFig, 'ResultsFile');
    if isempty(ResultsFile)
        bst_error('No sources displayed in this figure.', 'Expand with correlation', 0);
        return
    end
    
    % ===== THRESHOLD =====
    % For selected scout, find sources that are strongly correlated
    Threshold = 0.95;
    % Ask confirmation of the thresolh level to the user
    res = java_dialog('input', 'Thresold value for correlation', 'Sources correlation', [], num2str(Threshold));
    if isempty(res)
        return;
    end
    Threshold = str2num(res);
    if isempty(Threshold)
        return;
    end
    
    % ===== LOAD RESULTS =====
    % Progress bar
    bst_progress('start', 'Sources correlation', 'Loading results...');
    % Load results file 
    [iDS, iResult] = bst_memory('LoadResultsFileFull', ResultsFile);
    % If no DataSet is accessible : error
    if isempty(iDS)
        warning(['Cannot load file : "', ResultsFile, '"']);
        return
    end
    % Get results values over the current time window
    [ResultsValues, nComponents] = bst_memory('GetResultsValues', iDS, iResult, [], 'UserTimeWindow');
    % Error if unconstrained sources
    if (nComponents > 1)
        bst_error('Not supported yet for unconstrained sources.', 'Correlation', 0);
        return;
    end
    
    % ===== CORRELATION BETWEEN SOURCES =====
    % Convert from atlas-based results if necessary
    if ~isempty(GlobalData.DataSet(iDS).Results(iResult).Atlas)
        iRow = GetScoutForVertex(GlobalData.DataSet(iDS).Results(iResult).Atlas, sScout.Seed);
    else
        iRow = sScout.Seed;
    end
    % Compute correlation coefficients for all sources
    CorrCoeff = bst_corrn(ResultsValues(iRow,:), ResultsValues);
    % Vertices above threshold
    iRowCorr = find(abs(CorrCoeff) > Threshold);
    % Convert back to atlas-based
    if ~isempty(GlobalData.DataSet(iDS).Results(iResult).Atlas)
        sScout.Vertices = unique([GlobalData.DataSet(iDS).Results(iResult).Atlas.Scouts(iRowCorr).Vertices]);
    else
        sScout.Vertices = iRowCorr;
    end
    % Make sure there is at least the seed in the vertex list
    sScout.Vertices = union(sScout.Vertices, sScout.Seed);
            
    % ===== DISPLAY =====
    % Update scout
    SetScouts([], iScout, sScout);
    % Display scout patch
    PlotScouts(iScout);
    % Update panel "Scouts" fields
    UpdateScoutProperties();
    % Display/hide scouts and update MRI overlay mask
    UpdateScoutsDisplay('current');
    % Hide progress bar
    bst_progress('stop');
end

%% ===== NEW SURFACE: FROM SELECTED SCOUTS =====
function NewSurface(isKeep)
    % === GET VERTICES TO REMOVE ===
    % Get selected scouts
    [sScouts, iScouts, sSurf] = GetSelectedScouts();
    % Check whether a scout is selected
    if isempty(sScouts)
        java_dialog('warning', 'No scouts selected.', 'Remove vertices from surface');
        return
    end
    % Join scouts to get vertices to remove
    if isKeep
        iRemoveVert = setdiff(1:size(sSurf.Vertices,1), [sScouts.Vertices]);
        tag = 'keep';
    else
        iRemoveVert = [sScouts.Vertices];
        tag = 'rm';
    end
    % Unload everything
    bst_memory('UnloadAll', 'Forced');

    % === REMOVE VERTICES FROM SURFACE FILE ===
    % Remove vertices
    [Vertices, Faces, Atlas] = tess_remove_vert(sSurf.Vertices, sSurf.Faces, iRemoveVert, sSurf.Atlas);
    % Remove the handles of the scouts
    for iAtlas = 1:length(Atlas)
        for is = 1:length(Atlas(iAtlas).Scouts)
            Atlas(iAtlas).Scouts(is).Handles = [];
        end
%         if isfield(Atlas(iAtlas).Scouts, 'Handles');
%             Atlas(iAtlas).Scouts = rmfield(Atlas(iAtlas).Scouts, 'Handles');
%         end
    end
    % Build new surface
    sSurfNew = db_template('surfacemat');
    sSurfNew.Comment  = [sSurf.Comment ' | ' tag];
    sSurfNew.Vertices = Vertices;
    sSurfNew.Faces    = Faces;
    sSurfNew.Atlas    = Atlas;
    sSurfNew.iAtlas   = sSurf.iAtlas;

    % === SAVE NEW FILE ===
    % Output filename
    NewTessFile = strrep(file_fullpath(sSurf.FileName), '.mat', ['_' tag '.mat']);
    NewTessFile = file_unique(NewTessFile);
    % Save file back
    bst_save(NewTessFile, sSurfNew, 'v7');
    % Get subject
    [sSubject, iSubject] = bst_get('SurfaceFile', sSurf.FileName);
    % Register this file in Brainstorm database
    db_add_surface(iSubject, NewTessFile, sSurfNew.Comment);
    % Re-open one to show the modifications
    view_surface(NewTessFile);
end

%% ===== EXPORT SCOUTS TO MATLAB =====
function ExportScoutsToMatlab()
    % Get selected scouts
    sScouts = GetSelectedScouts();
    % If nothing selected, take all scouts
    if isempty(sScouts)
        sScouts = GetScouts();
    end
    % If nothing: exit
    if isempty(sScouts)
        return;
    end
    % Export to the base workspace
    export_matlab(sScouts, []);
    % Display in the command window the selected scouts
    disp([10 'List of vertices for each scout:']);
    for i = 1:length(sScouts)
        disp(['   ' sScouts(i).Label ': ' sprintf('%d ', sScouts(i).Vertices)]);
    end
    disp(' ');
end

%% ===== IMPORT SCOUTS FROM MATLAB =====
function ImportScoutsFromMatlab()
    % Export to the base workspace
    sScouts = in_matlab_var([], 'struct');
    if isempty(sScouts) 
        return;
    end
    % Check structure
    sTemplate = db_template('scout');
    if isempty(sScouts) || ~(isequal(fieldnames(sScouts), fieldnames(sTemplate)) || isequal(fieldnames(sScouts), fieldnames(db_template('scoutmat'))))
        bst_error('Invalid scouts structure.', 'Import from Matlab', 0);
        return;
    end
    % Remove handles
    sScouts.Handles = sTemplate.Handles;
    % Save new scout
    iNewScout = SetScouts([], 'Add', sScouts);
    % Display new scout
    PlotScouts(iNewScout);
    % Update "Scouts Manager" panel
    UpdateScoutsList();   
    % Select last scout in list (new scout)
    SetSelectedScouts(iNewScout);
end


%% ===============================================================================
%  ====== DISPLAY SCOUTS =========================================================
%  ===============================================================================

%% ===== PLOT SCOUT =====
% Find all the figures where these scouts should be displayed, and plot them.
% USAGE:  PlotScouts(iScouts, hFigures)
%         PlotScouts()                 : Plot all the scouts
function PlotScouts(iScouts, hFigSel)
    % Selected surfaces
    if (nargin < 2) || isempty(hFigSel)
        hFigSel = [];
    end
    % All scouts
    if (nargin < 1) || isempty(iScouts)
        [sScouts, sSurf] = GetScouts();
        iScouts = 1:length(sScouts);
    % Only selected scouts
    else
        [sScouts, sSurf] = GetScouts(iScouts);
    end
    % Return is nothing to plot
    if isempty(sScouts)
        return;
    end
    % Get cortex file
    SurfaceFiles{1} = sSurf.FileName;
    % Get anatomy file
    [sSubject, iSubject] = bst_get('SurfaceFile', SurfaceFiles{1});
    % Get all the figures concerned with Scout cortex and MRI surface
    [hFigures, iFigures, iDataSets, iSurfaces] = bst_figures('GetFigureWithSurface', SurfaceFiles);
    if isempty(hFigures)
        return
    end
    % If some specific figures are selected 
    if isempty(hFigSel)
        iFigSel = find(ismember(hFigures, hFigSel));
        if ~isempty(iFigSel)
            hFigures  = hFigures(iFigSel);
            iSurfaces = iSurfaces(iFigSel);
        end
    end
    % Get display options
    ScoutsOptions = GetScoutsOptions();
    if isempty(ScoutsOptions)
        return;
    end
    % Update more than 5 scouts: display progress bar
    isProgress = ~bst_progress('isVisible');
    if (length(sScouts) > 5) && isProgress
        bst_progress('start', 'Scout display', 'Updating scouts display...');
    end
    
    % Process all figures
    for ih = 1:length(hFigures)
        hFig = hFigures(ih);
        % Get Surface definition
        TessInfo = getappdata(hFig, 'Surface');
        iSurface = iSurfaces(1);
        sSurface = TessInfo(iSurface);
        % Get Faces and Vertices list of target surface
        if strcmpi(sSurface.Name, 'Anatomy')
            sDbCortex   = bst_get('SurfaceFileByType', iSubject, 'Cortex');
            sSurfCortex = bst_memory('LoadSurface', sDbCortex.FileName);
            Faces       = sSurfCortex.Faces;
            Vertices    = sSurfCortex.Vertices;
            VertexNormals = [];
            iVisibleVert = 1:length(Vertices);
        else
            [Vertices, Faces, VertexNormals, iVisibleVert] = panel_surface('GetSurfaceVertices', sSurface.hPatch);
        end

        % Process each scout
        for i = 1:length(sScouts)
            % Skip completely the display of the "Cortex" scouts
            if ismember(sScouts(i).Label, {'Cortex L', 'Cortex R', 'Cortex'}) && (length(sScouts(i).Region) >= 2) && strcmpi(sScouts(i).Region(2), 'U')
                continue;
            end
            % Get indice of the target figure in the sScouts.Handles array
            iHnd = find([sScouts(i).Handles.hFig] == hFig);
            % If figure is not referenced yet : add it
            if isempty(iHnd)
                iHnd = length(sScouts(i).Handles) + 1;
                sScouts(i).Handles(iHnd).hFig = hFig;
            end
            % Get axes handles 
            hAxes = findobj(hFig, '-depth', 1, 'tag', 'Axes3D');
            % Choose scout color
            if ScoutsOptions.displayRegionColor
                scoutColor = GetRegionColor(sScouts(i).Region);
            else
                scoutColor = sScouts(i).Color;
            end
            % Get visible scouts vertices
            iScoutVert = intersect(sScouts(i).Vertices, iVisibleVert);

            % === SCOUT 3D MARKER ===
            % Force scout location to be XYZ because scouts may be dispatched on a smoothed surface, 
            % i.e. with surface vertices being away from true locations
            MarkerLocation = GetScoutPosition(Vertices, VertexNormals, sScouts(i).Seed, 0.00001);
            % Plot scout marker (if it does not exist yet)
            if ScoutsOptions.displayText && ~isempty(iScoutVert)
                if isempty(sScouts(i).Handles(iHnd).hScout) || ~ishandle(sScouts(i).Handles(iHnd).hScout)
                    sScouts(i).Handles(iHnd).hScout = line(...
                        MarkerLocation(1), MarkerLocation(2), MarkerLocation(3), ...
                        'Marker',          'o', ...
                        'MarkerFaceColor', scoutColor, ...
                        'MarkerEdgeColor', scoutColor, ...
                        'MarkerSize',      5, ...
                        'Tag',             'ScoutMarker', ...
                        'Parent',          hAxes);
                % If scout marker already exist, just update its position
                else
                    set(sScouts(i).Handles(iHnd).hScout, ...
                        'XData', MarkerLocation(1), ...
                        'YData', MarkerLocation(2), ...
                        'ZData', MarkerLocation(3));
                end
            end
            
            % === SCOUT 3D LABEL ===
            % Only plot text with < 4 chars
            if ScoutsOptions.displayText && ~isempty(iScoutVert)
                % Place the text a little away from the marker itself
                textPos = GetScoutPosition(Vertices, VertexNormals, sScouts(i).Seed, 0.004);
                % Plot scout label (if it does not exist yet)
                if isempty(sScouts(i).Handles(iHnd).hLabel) || ~ishandle(sScouts(i).Handles(iHnd).hLabel)
                    try
                        % Plot text
                        sScouts(i).Handles(iHnd).hLabel = text(...
                            textPos(1), textPos(2), textPos(3), sScouts(i).Label, ...
                            'Fontname',     'helvetica', ...
                            'FontUnits',    'Point', ...
                            'FontSize',     bst_get('FigFont') + 2, ...
                            'FontWeight',   'normal', ...
                            'Color',        [.9 1 .9], ...
                            'HorizontalAlignment', 'center', ...
                            'Tag',          'ScoutLabel', ...
                            'Parent',       hAxes, ...
                            'Interpreter',  'none');
                    catch
                        warning('Brainstorm:GraphicsError', 'Unknown error: could not display scout label.');
                    end
                % If label is already displayed: just update its position
                else
                    set(sScouts(i).Handles(iHnd).hLabel, 'Position', textPos);
                end
            end

            % ===== SCOUT PATCH =====
            % If there are more than one vertex available for the scout
            if (length(iScoutVert) > 1)
                % === BUILD FACES/VERTICES ===
                % Move vertices away from the surface
                patchVertices = Vertices(iScoutVert, :);
                % Get all the full faces in the scout patch
                vertMask = false(length(Vertices),1);
                vertMask(iScoutVert) = true;
                % This syntax is faster but equivalent to: 
                % patchFaces = Faces(all(vertMask(Faces),2),:);
                iFacesTmp = find(vertMask(Faces(:,1)));
                iFacesTmp = iFacesTmp(vertMask(Faces(iFacesTmp,2)));
                iFacesTmp = iFacesTmp(vertMask(Faces(iFacesTmp,3)));
                patchFaces = Faces(iFacesTmp,:);
                % Renumber vertices in patchFaces
                vertMask = zeros(length(Vertices),1);
                vertMask(iScoutVert) = 1:length(iScoutVert);
                patchFaces = vertMask(patchFaces);
                % Re-orient if the orientation is wrong because of this last operation
                if (size(patchFaces,2) == 1)
                    patchFaces = patchFaces';
                end
                               
                % === DRAW PATCH ===
                if (ScoutsOptions.patchAlpha ~= 1)
                    % If a patch is available (enough faces and vertices)
                    if ~isempty(patchFaces)
                        % If patch does not exist yet : create it
                        if isempty(sScouts(i).Handles(iHnd).hPatch) || ~ishandle(sScouts(i).Handles(iHnd).hPatch)
                            sScouts(i).Handles(iHnd).hPatch = patch(...
                                'Faces',            patchFaces, ...
                                'Vertices',         patchVertices, ...
                                'FaceVertexCData',  scoutColor, ...
                                'FaceColor',        scoutColor, ...
                                'EdgeColor',        'none',...
                                'FaceAlpha',        1 - ScoutsOptions.patchAlpha, ...
                                'BackFaceLighting', 'lit', ...
                                'Tag',              'ScoutPatch', ...
                                'Parent',           hAxes) ;
                        % Else : only update vertices and faces
                        else
                            set(sScouts(i).Handles(iHnd).hPatch, 'Faces', patchFaces, 'Vertices', patchVertices);
                        end
                    % Else: delete existing patch
                    elseif ~isempty(sScouts(i).Handles(iHnd).hPatch)
                        delete(sScouts(i).Handles(iHnd).hPatch(ishandle(sScouts(i).Handles(iHnd).hPatch)));
                        sScouts(i).Handles(iHnd).hPatch = [];
                    end
                end
                
                % === DRAW CONTOUR ===
                if ScoutsOptions.displayContour
                    % Delete existing contours object
                    if ~isempty(sScouts(i).Handles(iHnd).hContour)
                        delete(sScouts(i).Handles(iHnd).hContour(ishandle(sScouts(i).Handles(iHnd).hContour)));
                        sScouts(i).Handles(iHnd).hContour = [];
                    end
                    % Vert-vert connect matrix of all the pairs of vertices
                    VertConn = sSurf.VertConn(iScoutVert, iScoutVert);
                    % Remove the edges inside the contiguous faces
                    if ~isempty(patchFaces)
                        % Build pairs of connected vertices
                        nFaces = size(patchFaces,1);
                        nVert = size(patchVertices,1);
                        pairsVert1 = sparse([patchFaces(:,1); patchFaces(:,2)], [patchFaces(:,2); patchFaces(:,1)], ones(2*nFaces,1), nVert, nVert);
                        pairsVert2 = sparse([patchFaces(:,1); patchFaces(:,3)], [patchFaces(:,3); patchFaces(:,1)], ones(2*nFaces,1), nVert, nVert);
                        pairsVert3 = sparse([patchFaces(:,2); patchFaces(:,3)], [patchFaces(:,3); patchFaces(:,2)], ones(2*nFaces,1), nVert, nVert);
                        % Vert-vert connect matrix for vertex of an inside face (that have to be removed from the coutour)
                        VertConnFaces = (pairsVert1 + pairsVert2 + pairsVert3 >= 2);
                        % Remove pairs from the vert-vert connectivity
                        VertConn(VertConnFaces) = 0;
                    end
                    % Plot contour 
                    vpath = {};
                    if nnz(VertConn)
                        iv = [];
                        % Loop to process all the links of the connectivity matrix
                        while nnz(VertConn)
                            % Find all the links for the last element of path
                            if ~isempty(iv)
                                jv = find(VertConn(iv,:));
                                if (length(jv) > 1)
                                    [maxconn, imax] = max(sum(VertConn(:,jv)));
                                    jv = jv(imax(1));
                                end
                                if ~isempty(jv)
                                    % Add link to current path
                                    vpath{end}(end+1) = jv;
                                    % If a link was consumed: remove it from the connectivity matrix
                                    VertConn(iv,jv) = false;
                                    VertConn(jv,iv) = false;
                                end
                                % Next node
                                iv = jv;
                            % No path: Create a new path, with the first link in the connectivity matrix
                            else
                                % Start from a weak node (end of chain: only one connection)
                                minConn = sum(VertConn);
                                iNonZero = find(minConn);
                                [tmp, imin] = min(minConn(iNonZero));
                                imin = iNonZero(imin);
                                % Start a new path
                                iv = imin;
                                vpath{end+1} = iv;
                            end
                        end
                        % Create new contours
                        for iPath = 1:length(vpath)
                            sScouts(i).Handles(iHnd).hContour(iPath) = line(...
                                patchVertices(vpath{iPath},1), patchVertices(vpath{iPath},2), patchVertices(vpath{iPath},3), ...
                                'Marker',          'none', ...
                                'LineStyle',       '-', ...
                                'LineWidth',       2, ...
                                'Color',           scoutColor, ...
                                'Tag',             'ScoutContour', ...
                                'UserData',        vpath{iPath}, ...
                                'Parent',          hAxes)';
                        end
                    end

                    % === DRAW VERTICES MARKERS === 
                    % Get only the points that are not in a face
                    iVertAlone = setdiff(1:size(patchVertices,1), unique([[vpath{:}], patchFaces(:)']));
                    % Plot scout vertices (if graphic object does not exist yet)
                    if ~isempty(iVertAlone)
                        if isempty(sScouts(i).Handles(iHnd).hVertices) || ~ishandle(sScouts(i).Handles(iHnd).hVertices)
                            sScouts(i).Handles(iHnd).hVertices = line(...
                                patchVertices(iVertAlone,1), patchVertices(iVertAlone,2), patchVertices(iVertAlone,3), ...
                                'Marker',          'o', ...
                                'MarkerFaceColor', scoutColor, ...
                                'MarkerEdgeColor', scoutColor, ...
                                'MarkerSize',      4, ...
                                'LineStyle',       'none', ...
                                'Tag',             'ScoutContour', ...
                                'UserData',        iVertAlone, ...
                                'Parent',          hAxes);
                        else
                            set(sScouts(i).Handles(iHnd).hVertices, ...
                                'XData', patchVertices(iVertAlone,1), ...
                                'YData', patchVertices(iVertAlone,2), ...
                                'ZData', patchVertices(iVertAlone,3));
                        end
                    elseif ~isempty(sScouts(i).Handles(iHnd).hVertices)
                        delete(sScouts(i).Handles(iHnd).hVertices(ishandle(sScouts(i).Handles(iHnd).hVertices)));
                        sScouts(i).Handles(iHnd).hVertices = [];
                    end
                end
                
            % Else : Remove previous scout patch, if it existed
            else
                if ~isempty(sScouts(i).Handles(iHnd).hVertices)
                    delete(sScouts(i).Handles(iHnd).hVertices(ishandle(sScouts(i).Handles(iHnd).hVertices)));
                    sScouts(i).Handles(iHnd).hVertices = [];
                end
                if ~isempty(sScouts(i).Handles(iHnd).hPatch)
                    delete(sScouts(i).Handles(iHnd).hPatch(ishandle(sScouts(i).Handles(iHnd).hPatch)));
                    sScouts(i).Handles(iHnd).hPatch = [];
                end
                if ~isempty(sScouts(i).Handles(iHnd).hContour)
                    delete(sScouts(i).Handles(iHnd).hContour(ishandle(sScouts(i).Handles(iHnd).hContour)));
                    sScouts(i).Handles(iHnd).hContour = [];
                end
            end
        end
        set(0, 'CurrentFigure', hFig);
        set(hFig, 'CurrentAxes', findobj(hFig, '-depth', 1, 'tag', 'Axes3D'));
        material([ 0.5 0.50 0.20 1.00 0.5 ]);
        lighting phong;
    end
    % Update scout defintion
    SetScouts([], iScouts, sScouts);
    % Close progress bar
    if isProgress
        bst_progress('stop');
    end
end

%% ===== RELOAD SCOUTS =====
function ReloadScouts(hFig)
    global GlobalData;
    % If figure not defined: process current 3D figure
    if (nargin < 1) || isempty(hFig)
        hFigures = bst_figures('GetFigureWithSurface', GlobalData.CurrentScoutsSurface);
        if isempty(hFigures)
            return;
        end
        hFig = hFigures(1);
    else
        hFigures = hFig;
    end
    % Update scouts surface
    CurrentFigureChanged_Callback(hFig, hFig);
    % Set default options
    SetDefaultOptions();
    % Remove all scouts
    for i = 1:length(hFigures)
        RemoveScoutsFromFigure(hFigures(i), 1);
    end
    % Plot all scouts again
    PlotScouts([], hFig);
    % Update selected/displayed scouts
    UpdateScoutsDisplay(hFig);
end


%% ===== GET SCOUT POSITION =====
function vertPos = GetScoutPosition(Vertices, VertexNormals, iVert, factor)
    % Normals are available
    if ~isempty(VertexNormals)
        orient = VertexNormals(iVert,:);
        vertPos = double(Vertices(iVert,:)) + orient ./ norm(orient) * factor;
    % Normals are not available
    else
        vertPos = double(Vertices(iVert,:)) * (1 + factor);
    end
end

%% ===== REMOVE SCOUTS FROM FIGURE =====
% USAGE:  RemoveScoutsFromFigure(hFig, isDeleteObj)
%         RemoveScoutsFromFigure()     : Remove scouts from all the figures
function RemoveScoutsFromFigure(hFig, isDeleteObj)
    global GlobalData;
    % No figure selected: process all the figures
    if (nargin < 2) || isempty(isDeleteObj)
        isDeleteObj = 0;
    end
    if (nargin < 1)
        hFig = [];
    end
    % If removing scouts from a given figure
    for iSurf = 1:length(GlobalData.Surface)
        for iAtlas = 1:length(GlobalData.Surface(iSurf).Atlas)
            for iScout = 1:length(GlobalData.Surface(iSurf).Atlas(iAtlas).Scouts)
                iHandles = 1;
                while (iHandles <= length(GlobalData.Surface(iSurf).Atlas(iAtlas).Scouts(iScout).Handles))
                    if isempty(hFig) || (GlobalData.Surface(iSurf).Atlas(iAtlas).Scouts(iScout).Handles(iHandles).hFig == hFig)
                        % Delete graphical objects
                        if isDeleteObj
                            sHandles = GlobalData.Surface(iSurf).Atlas(iAtlas).Scouts(iScout).Handles(iHandles);
                            hDelete = [sHandles.hScout, sHandles.hLabel, sHandles.hVertices, sHandles.hPatch, sHandles.hContour];
                            delete(hDelete(ishandle(hDelete)));
                        end
                        % Clear handles structure
                        GlobalData.Surface(iSurf).Atlas(iAtlas).Scouts(iScout).Handles(iHandles) = [];
                    else
                        iHandles = iHandles + 1;
                    end
                end
            end
        end
    end
end


%% ===== REMOVE SCOUTS =====
% Usage : RemoveScouts(iScouts) : remove a list of scouts
%         RemoveScouts()        : remove the scouts selected in the JList 
function RemoveScouts(iScouts, isForced)
    % Parse inputs
    if (nargin < 2) || isempty(isForced)
        isForced = 0;
    end
    if (nargin < 1) || isempty(iScouts)
        iScouts = [];
    end
    % Prevent edition of read-only atlas
    if ~isForced && isAtlasReadOnly()
        return;
    end
    % Stop scout edition
    SetSelectionState(0);
    % If scouts list is not defined
    if isempty(iScouts)
        % Get selected scouts
        [sScouts, iScouts] = GetSelectedScouts();
        if isempty(sScouts)
            return
        end
    else
        sScouts = GetScouts(iScouts);
    end
    hAllFig = [];
    % Delete graphical objects
    for i = 1:length(sScouts)
        hAllFig = [hAllFig, [sScouts(i).Handles.hFig]];
        % Delete graphical scout markers
        hMarkers = [sScouts(i).Handles.hScout];
        delete(hMarkers(ishandle(hMarkers)));
        % Delete graphical scout labels
        hLabels = [sScouts(i).Handles.hLabel];
        delete(hLabels(ishandle(hLabels)));
        % Delete graphical scout patches
        hPatches = [sScouts(i).Handles.hPatch];
        delete(hPatches(ishandle(hPatches)));
        % Delete graphical scout vertices
        hVertices = [sScouts(i).Handles.hVertices];
        delete(hVertices(ishandle(hVertices)));
        % Delete graphical scout contour
        hContour = [sScouts(i).Handles.hContour];
        delete(hContour(ishandle(hContour)));
    end
    
    % Remove scouts definitions from global data structure
    SetScouts([], iScouts, []);
    % Update "Scouts Manager" panel
    UpdateScoutsList();
    % Update MRI display in all figures
    panel_surface('UpdateOverlayCubes', unique(hAllFig));
end


%% ===== UPDATE SCOUTS VERTICES =====
% Update vertices of scouts for a given surface
function UpdateScoutsVertices(SurfaceFile) %#ok<DEFNU>
    % Get scouts to update
    sScouts = GetScouts(SurfaceFile);
    % Update vertices of all scouts
    for i = 1:length(sScouts)
        % Update vertices for all graphical instances
        for ihand = 1:length(sScouts(i).Handles)
            % Get surface information in figure appdata
            TessInfo = getappdata(sScouts(i).Handles(ihand).hFig, 'Surface');
            iSurface = find(file_compare({TessInfo.SurfaceFile}, SurfaceFile));
            if isempty(iSurface)
                return;
            end
            % Get displayed vertices of surface
            [Vertices, Faces, VertexNormals, iVisibleVert] = panel_surface('GetSurfaceVertices', TessInfo(iSurface).hPatch);
            % Get seed and vertices positions
            markerVert = GetScoutPosition(Vertices, VertexNormals, sScouts(i).Seed, 0.00001);
            iScoutVert = intersect(sScouts(i).Vertices, iVisibleVert);
            patchVertices = Vertices(iScoutVert,:);
            % Scout label
            VertexNormals = get(TessInfo(iSurface).hPatch, 'VertexNormals');
            textPos = GetScoutPosition(Vertices, VertexNormals, sScouts(i).Seed, 0.004);
            set(sScouts(i).Handles(ihand).hLabel, 'Position', textPos);
            % Scout seed
            set(sScouts(i).Handles(ihand).hScout, ...
                'XData', markerVert(1), ...
                'YData', markerVert(2), ...
                'ZData', markerVert(3));
            % Scout patch
            set(sScouts(i).Handles(ihand).hPatch, 'Vertices', patchVertices);
            % Scout vertices
            iDots = get(sScouts(i).Handles(ihand).hVertices, 'UserData');
            set(sScouts(i).Handles(ihand).hVertices, ...
                'XData', patchVertices(iDots,1), ...
                'YData', patchVertices(iDots,2), ...
                'ZData', patchVertices(iDots,3))
            % Scout contour
            for ic = 1:length(sScouts(i).Handles(ihand).hContour)
                vpath = get(sScouts(i).Handles(ihand).hContour(ic), 'UserData');
                set(sScouts(i).Handles(ihand).hContour(ic), ...
                    'XData', patchVertices(vpath,1), ...
                    'YData', patchVertices(vpath,2), ...
                    'ZData', patchVertices(vpath,3));
            end
        end
    end
end


%% ===== UPDATE SCOUTS DISPLAY =====
% Display/hide scouts
% USAGE:  UpdateScoutsDisplay(hFig)       : Update the specified figures
%         UpdateScoutsDisplay('current')  : Update the figures for the current surface
%         UpdateScoutsDisplay('all')      : Update all the figures
%         UpdateScoutsDisplay()           : Update all the figures
function UpdateScoutsDisplay(target)
    global GlobalData;
    % Parse inputs
    if (nargin < 1) || isempty(target)
        target = 'all';
    end
    % Progress bar
    isProgress = ~bst_progress('isVisible');
    if isProgress
        bst_progress('start', 'Scouts options', 'Updating display...');
    end
    % Get target scouts
    if ~ischar(target)
        hFigTarget = target;
        TessInfo = getappdata(hFigTarget, 'Surface');
        iTess = getappdata(hFigTarget, 'iSurface');
        if isempty(TessInfo) || isempty(iTess)
            hFigTarget = [];
            SurfaceFile = [];
        else
            SurfaceFile = TessInfo(iTess).SurfaceFile;
        end
    elseif strcmpi(target, 'all')
        SurfaceFile = [];
        hFigTarget = [];
    elseif strcmpi(target, 'current')
        SurfaceFile = GlobalData.CurrentScoutsSurface;
        hFigTarget = [];
    else
        error('Invalid target.');
    end
    % Get scouts display options
    ScoutsOptions = GetScoutsOptions();
    if isempty(ScoutsOptions)
        return;
    end
    % Processing all the surfaces and atlases
    for iSurf = 1:length(GlobalData.Surface)
        % Check if this is the target surface
        if ~isempty(SurfaceFile) && ~file_compare(GlobalData.Surface(iSurf).FileName, SurfaceFile)
            continue;
        end
        % Is it the current surface used in the Scout tab
        isCurrentSurf = file_compare(GlobalData.Surface(iSurf).FileName, GlobalData.CurrentScoutsSurface);
        % Loop on all the atlases
        for iAtlas = 1:length(GlobalData.Surface(iSurf).Atlas)
            % Get selected scouts (only for current atlas)
            if isCurrentSurf && (iAtlas == GlobalData.Surface(iSurf).iAtlas)
                [tmp, iSelectedScouts] = GetSelectedScouts();
            else
                iSelectedScouts = [];
            end
            % View mode: all, select, none
            switch (ScoutsOptions.showSelection)
                case 'all',     iVisibleScouts = 1:length(GlobalData.Surface(iSurf).Atlas(iAtlas).Scouts);
                case 'select',  iVisibleScouts = iSelectedScouts;
                case 'none',    iVisibleScouts = [];
            end
            iScoutPlot = [];
            % Loop on the scouts
            for iScout = 1:length(GlobalData.Surface(iSurf).Atlas(iAtlas).Scouts)
                sScout = GlobalData.Surface(iSurf).Atlas(iAtlas).Scouts(iScout);
                % Is this scout supposed to be visible
                isVisible = ismember(iScout, iVisibleScouts);
                % Process each figure in which this scout is accessible
                for iFig = 1:length(sScout.Handles)
                    % Current figure
                    hFig = sScout.Handles(iFig).hFig;
                    % If it is not the target figure: skip
                    if ~isempty(hFigTarget) && (hFigTarget ~= hFig)
                        continue;
                    end
                    
                    % === SET THE VISIBILITIES ===
                    hScout    = [sScout.Handles(iFig).hScout];
                    hLabel    = [sScout.Handles(iFig).hLabel];
                    hPatch    = [sScout.Handles(iFig).hPatch];
                    hVertices = [sScout.Handles(iFig).hVertices];
                    hContour  = [sScout.Handles(iFig).hContour];
                    % Scout marker+text
                    if ~isempty([hScout, hLabel])
                        if isVisible && ScoutsOptions.displayText
                            set([hScout, hLabel], 'Visible', 'on');
                        else
                            set([hScout, hLabel], 'Visible', 'off');
                        end
                    elseif isVisible && ScoutsOptions.displayText
                        iScoutPlot(end+1) = iScout;
                    end
                    % Scout patch
                    if ~isempty([hPatch hVertices])
                        if isVisible
                            set([hPatch hVertices], 'Visible', 'on');
                        else
                            set([hPatch hVertices], 'Visible', 'off');
                        end
                    elseif isVisible && (ScoutsOptions.patchAlpha ~= 1)
                        iScoutPlot(end+1) = iScout;
                    end
                    % Scout contour
                    if ~isempty(hContour)
                        if isVisible && ScoutsOptions.displayContour
                            set(hContour, 'Visible', 'on');
                        else
                            set(hContour, 'Visible', 'off');
                        end
                    elseif isVisible && ScoutsOptions.displayContour
                        iScoutPlot(end+1) = iScout;
                    end
                    % === SET COLOR ===
                    if ScoutsOptions.displayRegionColor
                        scoutColor = GetRegionColor(sScout.Region);
                    else
                        scoutColor = sScout.Color;
                    end
                    set([hScout, hVertices], 'MarkerFaceColor', scoutColor, 'MarkerEdgeColor', scoutColor);
                    set(hPatch,   'FaceVertexCData', scoutColor, 'FaceColor', scoutColor);
                    set(hContour, 'Color', scoutColor);
                end
            end
            % Redraw completely the missing scouts
            if ~isempty(iScoutPlot)
                PlotScouts(unique(iScoutPlot));
            end
        end
    end
    drawnow;
    if isProgress
        bst_progress('stop');
    end
end


%% ===== UPDATE STRUCTURE ALPHA =====
function UpdateStructureAlpha()
    global GlobalData;
    % Get all the figures for current surface
    [hFigures, iFigures, iDataSets, iSurfaces] = bst_figures('GetFigureWithSurface', GlobalData.CurrentScoutsSurface);
    % Display only the selected structures
    for i = 1:length(hFigures)
        FigureId = getappdata(hFigures(i), 'FigureId');
        if strcmpi(FigureId.Type, '3DViz')
            figure_3d('UpdateSurfaceAlpha', hFigures(i), iSurfaces(i));
        end
    end
end


%% ===============================================================================
%  ====== SCOUTS IN MRI ==========================================================
%  ===============================================================================

%% ===== EDIT SCOUT IN MRI =====
% USAGE:  iScout = EditScoutMri('Add')   : Create a new scout using the MRI
%         iScout = EditScoutMri(iScout)  : Edit a given scout
%         iScout = EditScoutMri()        : Edit the first of the currently selected scout
function iScout = EditScoutMri(iScout)
    % Prevent edition of read-only atlas
    if isAtlasReadOnly()
        return;
    end
    % Get current scouts and surface
    [sAllScouts, sSurf, iSurf] = GetScouts();
    if isempty(sSurf)
        java_dialog('warning', 'No surface loaded.', 'Edit scout in MRI');
        return;
    end
    % Parse input
    if (nargin < 1) || isempty(iScout)
        % Get selected scouts
        [sScout, iScout] = GetSelectedScouts();
        % Warning message if no scout selected
        if isempty(sScout)
            java_dialog('warning', 'No scout selected.', 'Edit scout in MRI');
            return;
        % If more than one scout selected: keep only the first one
        elseif (length(sScout) > 1)
            iScout = iScout(1);
            SetSelectedScouts(iScout);
        end
        isNewScout = 0;
    elseif ischar(iScout) && strcmpi(iScout, 'Add')
        sScout = [];
        isNewScout = 1;
    else
        sScout = sAllScouts(iScout);
        isNewScout = 0;
    end
    % Stop scout edition
    SetSelectionState(0);

    % === LOAD MRI AND SURFACE ===
    % Get subject for this surface
    [sSubject, iSubject] = bst_get('SurfaceFile', sSurf.FileName);
    % Get the anatomy file for this subject
    if isempty(sSubject) || isempty(sSubject.iAnatomy)
        java_dialog('error', 'No MRI defined for this subject.', 'Edit scout in MRI');
        return
    end
    % Progress bar
    bst_progress('start', 'Edit mask', 'Initialization...');
    % Load Mri
    sMri = bst_memory('LoadMri', iSubject);
    % Get interpolation matrix MRI<->Surface
    tess2mri_interp = bst_memory('GetTess2MriInterp', iSurf);
    % Compute the position of the vertices in MRI coordinates
    mriVertices = cs_scs2mri(sMri, sSurf.Vertices' * 1000) ./ repmat(sMri.Voxsize', 1, length(sSurf.Vertices));

    % === BUILD INITIAL MASK ===
    % If scout already exist, generate a mask for it
    if ~isNewScout
        % Get vertices to display
        iVertices = sScout.Vertices;
        % Display only specified vertices
        isMask = (sum(tess2mri_interp(:,iVertices),2) > 0);
        % Create mask volume (same size than the MRI)
        initMask = reshape(uint8(full(isMask)) * 255, size(sMri.Cube));
    else
        % No scout: empty initial mask
        initMask = [];
    end
 
    % === INITIAL POSITION ===
    % If scout already exist,
    if ~isNewScout
        % Orientation: Display in axial slices
        initPosition(1) = 3;
        % Position: mean of the scout vertices
        initPosition(2) = round(mean(mriVertices(initPosition(1), sScout.Vertices)));
    else
        % No scout: Default display
        initPosition = [];
    end
       
    % === COLORMAP ===
    % Get colormap
    sColormap = bst_colormaps('GetColormap', 'anatomy');
    
    % === EDIT MASK ===
    % Open mask editor
    newMask = mri_editMask(sMri.Cube, sMri.Voxsize, initMask, initPosition, sColormap.Name);
    if isempty(newMask)
        return
    end
    % Dilatation of the mask
    newMask = mri_dilate(newMask);
    % Mask was modified: find the vertices inside the new mask
    rVertices = round(mriVertices);
    iVerticesInMri = sub2ind(size(sMri.Cube), rVertices(1,:), rVertices(2,:), rVertices(3,:));
    % Find the vertices inside the mask
    iVerticesInMask = find(newMask(iVerticesInMri));
    % If no vertices : cannot define a scout
    if isempty(iVerticesInMask)
        java_dialog('error', ['The mask you designed does not contain any surface vertices,' 10 'it cannot be used to create a scout.'], 'Edit scout in MRI');
        return
    end
    
    % === OUTPUT SCOUT ===
    % Create new scout
    if isNewScout
        [sScout, iScout] = CreateScout(iVerticesInMask, [], sSurf.FileName);
    % Update vertices
    else
        sScout.Vertices = iVerticesInMask;
        % If seed is not anymore inside the scout : use the first vertex available
        if ~ismember(sScout.Seed, sScout.Vertices)
            sScout = SetScoutsSeed(sScout, sSurf.Vertices);
        end
        % Save updated scout
        iScout = SetScouts([], iScout, sScout);
    end   
    % Update scout display
    PlotScouts(iScout);
    % Update display or Scouts properties
    UpdatePanel();
    % Select new scout
    SetSelectedScouts(iScout);
    % Close progress bar
    bst_progress('stop');
end


%% ===== CENTER MRI ON SCOUT =====
function CenterMriOnScout(varargin)
    % === GET SELECTED SCOUT ===
    % Get selected scouts
    [sScout, iScout, sSurf] = GetSelectedScouts();
    if isempty(sScout)
        java_dialog('warning', 'No scouts selected.', 'Center MRI on scout');
        return
    elseif (length(sScout) > 1)
        % More than one scout selected: select only the first one
        sScout = sScout(1);
        iScout = iScout(1);
        SetSelectedScouts(iScout);
    end
    % Get the subject associated with the first selected scout
    sSubject = bst_get('SurfaceFile', sSurf.FileName);
    % Get the anatomy file for this subject
    if isempty(sSubject) || isempty(sSubject.iAnatomy)
        java_dialog('error','No MRI defined for this subject', 'Center MRI on scout');
    end
    MriFile = sSubject.Anatomy(sSubject.iAnatomy).FileName;

    % === GET FIGURE ===
    % Get current 3D figure
    hFig = bst_figures('GetCurrentFigure', '3D');
    % Get the list of figures that show the MRI
    hMriFigs = [bst_figures('GetFigureWithSurface', MriFile, '', '3DViz', ''), ...
                bst_figures('GetFigureWithSurface', MriFile, '', 'MriViewer', '')];
    % If the current figure doesn't contain the MRI, try to get another one
    if isempty(hFig) || ~ismember(hFig, hMriFigs)
        % Some MRI figures are available: use the first one
        if ~isempty(hMriFigs)
            hFig = hMriFigs(1);
        % Else: Open a new figure
        else
            % Try to overlay the current results in the MRI Viewer; Else: overlay the surface
            OverlayFile = sSurf.FileName;
            if ~isempty(hFig) && ~isempty(getappdata(hFig, 'ResultsFile'))
                OverlayFile = getappdata(hFig, 'ResultsFile');
            end
            % Open MRI Viewer
            hFig = view_mri(MriFile, OverlayFile);            
        end
    end
    % Get anatomy surface
    [sMri, TessInfo, iAnatomy] = panel_surface('GetSurfaceMri', hFig);    

    % === CENTER MRI VIEW ===
    % Get MRI structure
    sMri = bst_memory('GetMri', TessInfo(iAnatomy).SurfaceFile);
    % Get cortex surface
    sDbCortex   = bst_get('SurfaceFileByType', TessInfo(iAnatomy).SurfaceFile, 'Cortex');
    sSurfCortex = bst_memory('LoadSurface', sDbCortex.FileName);
    % Get new slices coordinates
    newPosScs = sSurfCortex.Vertices(sScout.Seed,:);
    newPosMri = cs_scs2mri(sMri, newPosScs' * 1000)' ./ sMri.Voxsize;
    % Get figure properties
    FigureId = getappdata(hFig, 'FigureId');
    % If figure is a MRIViewer
    switch (FigureId.Type)
        case 'MriViewer'
            figure_mri('SetLocation', 'mri', hFig, [], newPosMri);
        case '3DViz'
            TessInfo(iAnatomy).CutsPosition = round(newPosMri);
            figure_3d('UpdateMriDisplay', hFig, [1 2 3], TessInfo, iAnatomy);
    end
end


%% ===============================================================================
%  ====== LOAD / SAVE ============================================================
%  ===============================================================================

%% ===== LOAD SCOUT =====
% USAGE:  LoadScouts(ScoutFiles, isNewAtlas=1) : Files to import
%         LoadScouts()                         : Ask the user for the files to read
function LoadScouts(ScoutFiles, isNewAtlas)
    % Parse inputs
    if (nargin < 2) || isempty(isNewAtlas)
        isNewAtlas = 1;
    end
    if (nargin < 1) || isempty(ScoutFiles)
        ScoutFiles = [];
    end
    % If editing existing atlas: Prevent edition of read-only atlas
    if ~isNewAtlas && isAtlasReadOnly()
        return;
    end
    % Stop scout edition
    SetSelectionState(0);
    % Save current scouts modifications
    SaveModifications();
    % If surface is defined: return scouts associated to this surface
    [sScouts, sSurf] = GetScouts();
    if isempty(sSurf)
        java_dialog('error', 'No surface loaded.', 'Load atlas');
        return
    end
    % Progress bar
    isProgress = ~bst_progress('isVisible');
    if isProgress
        bst_progress('start', 'Load atlas', 'Loading...');
    end
    % Load all files selected by user
    [sAtlas, Messages] = import_label(sSurf.FileName, ScoutFiles, isNewAtlas);
    % Display error messages
    if ~isempty(Messages)
        java_dialog('error', Messages, 'Load atlas');
    end
    % Close all the 
    if isProgress
        bst_progress('stop');
    end
end


%% ===== SAVE SCOUT =====
function SaveScouts(varargin)
    % Stop scout edition
    SetSelectionState(0);
    % Get current atlas
    sAtlas = GetAtlas();
    if isempty(sAtlas.Scouts)
        disp('BST> No scouts selected.');
        return;
    end
    % Get selected scouts (no selection: export all the scouts)
    [sScouts, iScouts, sSurf] = GetSelectedScouts();
    if ~isempty(iScouts)
        sAtlas.Scouts = sAtlas.Scouts(iScouts);
    end
    % Remove the file "Handles"
    %sAtlas.Scouts = rmfield(sAtlas.Scouts, 'Handles');
    for is = 1:length(sAtlas.Scouts)
        sAtlas.Scouts(is).Handles = [];
    end
    % Prepare structure for saving
    sAtlas.TessNbVertices = length(sSurf.Vertices);
    
    % Build a default file name
    LastUsedDirs = bst_get('LastUsedDirs');
    if strcmpi(sAtlas.Name, 'User scouts')
        if (length(sScouts) <= 3)
            ScoutFile = bst_fullfile(LastUsedDirs.ExportAnat, ['scout', sprintf('_%s', sScouts.Label), '.mat']);
        else
            ScoutFile = bst_fullfile(LastUsedDirs.ExportAnat, sprintf('scout_%d.mat', length(sAtlas.Scouts)));
        end
    else
        ScoutFile = bst_fullfile(LastUsedDirs.ExportAnat, ['scout_', file_standardize(sAtlas.Name), sprintf('_%d.mat', length(sAtlas.Scouts))]);
    end
    % Get filename where to store the filename
    ScoutFile = java_getfile('save', 'Save selected scouts', ScoutFile, ... 
                             'single', 'files', ...
                             {{'_scout'}, 'Brainstorm cortical scouts (*scout*.mat)', 'BST'}, 1);
    if isempty(ScoutFile)
        return;
    end
    % Save last used folder
    LastUsedDirs.ExportAnat = bst_fileparts(ScoutFile);
    bst_set('LastUsedDirs',  LastUsedDirs);
    % Make sure that filename contains the 'scout' tag
    if isempty(strfind(ScoutFile, '_scout')) && isempty(strfind(ScoutFile, 'scout_'))
        [filePath, fileBase, fileExt] = bst_fileparts(ScoutFile);
        ScoutFile = bst_fullfile(filePath, ['scout_' fileBase fileExt]);
    end
    % Save file
    bst_save(ScoutFile, sAtlas, 'v7');
end


%% ===== FIX ATLAS STRUCTURE =====
function sAtlasFix = FixAtlasStruct(sAtlas)
    % Atlases
    sAtlasFix = repmat(db_template('Atlas'), 0);
    % Reformat the structure of the loaded atlas
    for ia = 1:length(sAtlas)
        % Atlas name
        if isfield(sAtlas(ia), 'Name') && ~isempty(sAtlas(ia).Name)
            sAtlasFix(ia).Name = sAtlas(ia).Name;
        else
            sAtlasFix(ia).Name = sprintf('Atlas #%d', ia);
        end
        % Copy all the scouts
        for is = 1:length(sAtlas(ia).Scouts)
            % Base structure on template
            sAtlasFix(ia).Scouts(is) = db_template('Scout');
            % Copy common fields
            %listFields = setdiff(fieldnames(sAtlas(ia).Scouts(is)), 'Handles');
            listFields = fieldnames(sAtlas(ia).Scouts(is));
            for ie = 1:length(listFields)
                if isfield(sAtlasFix(ia).Scouts(is), listFields{ie}) && ~(strcmpi(listFields{ie}, 'Handles') && isempty(sAtlas(ia).Scouts(is).Handles))
                    sAtlasFix(ia).Scouts(is).(listFields{ie}) = sAtlas(ia).Scouts(is).(listFields{ie});
                end
            end
            % Check vertices matrix orientation
            if (size(sAtlasFix(ia).Scouts(is).Vertices, 1) > 1)
                sAtlasFix(ia).Scouts(is).Vertices = sAtlasFix(ia).Scouts(is).Vertices';
            end
        end
    end
end









