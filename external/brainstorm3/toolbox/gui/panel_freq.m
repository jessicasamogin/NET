function varargout = panel_freq(varargin)
% PANEL_FREQ: Frequency selection panel.
% 
% USAGE:  bstPanel = panel_freq('CreatePanel')
%                    panel_freq('UpdatePanel')
%                    panel_freq('SetCurrentFreq',  value)
%                    panel_freq('FreqKeyCallback', keyEvent);
%       FreqWindow = panel_freq('InputSelectionWindow', maxFreqWindow, Comment, strUnits)

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
% Authors: Francois Tadel, 2010-2012

macro_methodcall;
end


%% ===== CREATE PANEL =====
function bstPanelNew = CreatePanel() %#ok<DEFNU>
    panelName = 'FreqPanel';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;

    % Create tool panel
    jPanelNew = gui_river([1,4], [2,2,6,10]);
    
    % Current frequency slider
    jSliderCurFreq = JSlider(0, 100, 0);
    jSliderCurFreq.setEnabled(0);
    java_setcb(jSliderCurFreq, 'MouseReleasedCallback', @SliderCurFreq_Callback, ...
                               'KeyPressedCallback',    @SliderCurFreq_Callback);
    jPanelNew.add('hfill', jSliderCurFreq);
    % Current frequency label
    jLabelCurFreq = gui_component('Label', jPanelNew, [], '     ');
    jLabelCurFreq.setHorizontalAlignment(JLabel.RIGHT);
    jLabelCurFreq.setPreferredSize(Dimension(40, 22));
    % Quick preview
    java_setcb(jSliderCurFreq, 'StateChangedCallback',  @(h,ev)SliderQuickPreview(jSliderCurFreq, jLabelCurFreq));

    % Create the BstPanel object that is returned by the function
    bstPanelNew = BstPanel(panelName, ...
                           jPanelNew, ...
                           struct('jPanelFreq',           jPanelNew, ...
                                  'jSliderCurFreq',       jSliderCurFreq, ...
                                  'jLabelCurFreq',        jLabelCurFreq));

    
%% =================================================================================
%  === CONTROLS CALLBACKS  =========================================================
%  =================================================================================
    %% ===== SLIDER QUICK PREVIEW =====
    function SliderQuickPreview(jSlider, jText)
        global GlobalData
        if isempty(GlobalData.UserFrequencies.Freqs)
            return
        end
        iCurFreq = jSlider.getValue();
        % Current freq label
        if ~iscell(GlobalData.UserFrequencies.Freqs)
            f = round(GlobalData.UserFrequencies.Freqs(iCurFreq) * 100) / 100;
            strFreq = [num2str(f), ' Hz'];
        % Frequency bands
        else
            BandBounds = process_tf_bands('GetBounds', GlobalData.UserFrequencies.Freqs(iCurFreq,:));
            strFreq = ['<HTML>' GlobalData.UserFrequencies.Freqs{iCurFreq, 1} '<BR>' ...
                       sprintf('%d-%d Hz', round(BandBounds))];
        end
        jText.setText(strFreq);
    end

    %% ===== SLIDER CURRENT FREQUENCY CALLBACK =====
    function SliderCurFreq_Callback(varargin)
        global GlobalData;
        % Process slider callbacks only if it has focus
        if jSliderCurFreq.hasFocus() && ~isempty(GlobalData.UserFrequencies.Freqs)
            % Set current frequency
            iCurrentFreq = jSliderCurFreq.getValue();
            SetCurrentFreq(iCurrentFreq);  
        end
    end
end

%% =================================================================================
%  === EXTERNAL PANEL CALLBACKS  ===================================================
%  =================================================================================
    
%% ===== UPDATE PANEL =====
function UpdatePanel()
    global GlobalData;
    % Get panel controls
    ctrl = bst_get('PanelControls', 'FreqPanel');
    if isempty(ctrl) || ~ctrl.jPanelFreq.getParent().isVisible()
        return;
    end
    % There is data : display values
    if ~isempty(GlobalData.UserFrequencies.Freqs)
        % Configure slider
        if iscell(GlobalData.UserFrequencies.Freqs)
            nSamples = size(GlobalData.UserFrequencies.Freqs, 1);
        else
            nSamples = length(GlobalData.UserFrequencies.Freqs);
        end
        ctrl.jSliderCurFreq.setMinimum(1);
        ctrl.jSliderCurFreq.setMaximum(nSamples);
        % Set current freq
        iCurFreq = GlobalData.UserFrequencies.iCurrentFreq;
        if ~isempty(iCurFreq)
            ctrl.jSliderCurFreq.setValue(iCurFreq);
            % Current freq label
            if ~iscell(GlobalData.UserFrequencies.Freqs)
                f = round(GlobalData.UserFrequencies.Freqs(iCurFreq) * 100) / 100;
                strFreq = [num2str(f), ' Hz'];
                ctrl.jLabelCurFreq.setHorizontalAlignment(ctrl.jLabelCurFreq.RIGHT);
                ctrl.jLabelCurFreq.setPreferredSize(java.awt.Dimension(50, 22));
                ctrl.jSliderCurFreq.setPaintTicks(0);
            else
                BandBounds = process_tf_bands('GetBounds', GlobalData.UserFrequencies.Freqs(iCurFreq,:));
                strFreq = ['<HTML>' GlobalData.UserFrequencies.Freqs{iCurFreq, 1} '<BR>' ...
                           sprintf('%d-%d Hz', round(BandBounds))];
                ctrl.jLabelCurFreq.setHorizontalAlignment(ctrl.jLabelCurFreq.LEFT);
                ctrl.jLabelCurFreq.setPreferredSize(java.awt.Dimension(60, 22));
                ctrl.jSliderCurFreq.setPaintTicks(1);
                ctrl.jSliderCurFreq.setMajorTickSpacing(1);
            end
            ctrl.jLabelCurFreq.setText(strFreq);
        end
        % Enable all panel controls
        ctrl.jSliderCurFreq.setEnabled(1);
        ctrl.jLabelCurFreq.setEnabled(1);
    else
        % Disable all panel controls
        ctrl.jSliderCurFreq.setEnabled(0);
        ctrl.jLabelCurFreq.setEnabled(0);
    end
end


%% ===== SET CURRENT FREQUENCY =====
function SetCurrentFreq(value)
    global GlobalData;
    if isempty(GlobalData.UserFrequencies.Freqs)
        return
    end
    % Save old value for CurrentTime
    iOldCurFreq = GlobalData.UserFrequencies.iCurrentFreq;

    % If value is valid: set new value
    if (~isempty(value) && ~isnan(value))
        iNewCurFreq = value;
    % Else: Use previous value
    else
        iNewCurFreq = iOldCurFreq;
    end
    
    % If current time changed
    if (iOldCurFreq ~= iNewCurFreq)
        % Actually change time
        GlobalData.UserFrequencies.iCurrentFreq = iNewCurFreq;
        % Update plots
        bst_figures('FireCurrentFreqChanged');
    end
    % Update panel
    UpdatePanel();
end

    
%% ===== FREQ SLIDER KEYBOARD ACTION =====
function FreqKeyCallback(ev)     %#ok<DEFNU>
    global GlobalData;
    if isempty(GlobalData.UserFrequencies.Freqs)
        return;
    end
    % Set a mutex to prevent to enter twice at the same time in the routine
    global FreqSliderMutex;
    if (isempty(FreqSliderMutex))
        tic
        % Set mutex
        FreqSliderMutex = 1;
        
        % === CONVERT KEY EVENT TO MATLAB ===
        [keyEvent, isControl, isShift] = gui_brainstorm('ConvertKeyEvent', ev);
        if isempty(keyEvent.Key)
            FreqSliderMutex = [];
            return
        end
        
        % === PROCESS KEY ===
        % Get current frequency
        iCurFreq  = GlobalData.UserFrequencies.iCurrentFreq;
        iNewFreq = [];
        % Switch between different keys
        switch (keyEvent.Key)
            case {'leftarrow', 'downarrow'},  iNewFreq = iCurFreq - 1;
            case {'rightarrow', 'uparrow'},   iNewFreq = iCurFreq + 1;
            case 'pageup',                    iNewFreq = iCurFreq + 10;
            case 'pagedown',                  iNewFreq = iCurFreq - 10;
        end
        % Change current frequency
        if ~isempty(iNewFreq) && (iNewFreq >= 1) && (iNewFreq <= length(GlobalData.UserFrequencies.Freqs))
            SetCurrentFreq(iNewFreq);
        end
        drawnow;
        % Release mutex
        FreqSliderMutex = [];
        
    else
        % Release mutex if last keypress was processed more than one 2s ago
        % (restore keyboard after a bug...)
        t = toc;
        if (t > 2)
            FreqSliderMutex = [];
        end
    end
end


%% ===== INPUT SELECTION WINDOW =====
function FreqWindow = InputSelectionWindow(maxFreqWindow, Comment, strUnits) %#ok<DEFNU>
    % Ask until getting a valid time window
    validFreq = 0;
    while(~validFreq)
        % Display dialog to ask user time window for baseline
        res = java_dialog('input', {['Start (' strUnits '):'], ['Stop (' strUnits '):']}, Comment, ...
                          [], {num2str(maxFreqWindow(1)), num2str(maxFreqWindow(end))});
        if isempty(res)
            FreqWindow = [];
            return
        end
        % Check values
        fStart = str2num(res{1});
        fStop = str2num(res{2});
        if isempty(fStart) || isempty(fStop) || (fStart >= fStop) || (fStart < maxFreqWindow(1)-1e-2) || (fStop > maxFreqWindow(end)+1e-2)
            java_dialog('warning', 'Invalid frequency window');
        else
            validFreq = 1;
        end
    end
    % Apply units
    FreqWindow = [fStart fStop];
end




