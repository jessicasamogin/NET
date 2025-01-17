function [TimeUnits, precision] = gui_validate_text(jTextValid, jTextMin, jTextMax, TimeVector, TimeUnits, precision, initValue, fcnCallback)
% GUI_VALIDATE_TEXT: Define the callbacks to make a JTextField work as a value selection device.
%
% INPUT:
%     - jTextValid     : Java pointer to a JTextField object
%     - jTextMin       : Value in jTextValid must be superior to value in jTextMin (set to [] to ignore)
%     - jTextMax       : Value in jTextValid must be inferior to value in jTextMax (set to [] to ignore)
%     - TimeVector     : Either a full time vector or [start, stop, sfreq]
%     - TimeUnits      : Units used to represent the values: {'ms','s','scalar','list'}; detected if not specified
%     - dispPrecision  : Number of digits to display after the point (0=integer); detected if not specified
%     - initValue      : Initial value of the control
%     - fcnCallback    : Callback that is executed after each validation of the jTextValid control

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
% Authors: Francois Tadel, 2009-2013


%% ===== PARSE INPUTS =====
% Time type: full vector or bounds + frequency
if (length(TimeVector) == 3)
    bounds = TimeVector(1:2);
    sfreq  = TimeVector(3);
    TimeVector = [];
else
    bounds = [TimeVector(1), TimeVector(end)];
    sfreq = 1 ./ (TimeVector(2) - TimeVector(1)); 
end
% Detect units (s or ms)
if strcmpi(TimeUnits, 'time')
    if (max(abs(bounds)) > 2)
        TimeUnits = 's';
    else
        TimeUnits = 'ms';
    end
end
% Detect precision
if isempty(precision)
    % Duration of one time frame, in text length
    if strcmpi(TimeUnits, 'ms')
        dt = 1/sfreq * 1000;
    else
        dt = 1/sfreq;
    end
    % Number of signative digits
    if (dt < 1)
        precision = ceil(-log10(dt));
    elseif (dt == 1)
        precision = 0;
    else
        precision = 1;
    end
end
% Initialize current value
currentValue = [];
% Set init value
if ~isempty(initValue)
    SetValue(jTextValid, initValue);
    TextValidation_Callback(0);
end
% Set validation callbacks
java_setcb(jTextValid, 'ActionPerformedCallback', @(h,ev)TextValidation_Callback(1), ...
                       'FocusLostCallback',       @(h,ev)TextValidation_Callback(1));

            
%% ===== VALIDATION FUNCTION =====
    function TextValidation_Callback(isCallback)
        % Get value that was entered by user in the text field
        newVal = GetValue(jTextValid);
        % Int list: accept empty input
        if strcmpi(TimeUnits, 'list') && isempty(newVal)
            isChanged = 1;
        % If no valid value entered, use previous value
        elseif isempty(newVal) && isempty(currentValue)
            return
        elseif isempty(newVal) && ~isempty(currentValue)
            newVal = currentValue;
            isChanged = 0;
        elseif ~isempty(newVal) && isempty(currentValue)
            currentValue = newVal;
            isChanged = 1;
        else
            isChanged = ~isequal(currentValue, newVal);
        end
        % Look for the closest available value
        if ~isempty(TimeVector)
            [dist, iVal] = min(abs(TimeVector - newVal));
            newVal = TimeVector(iVal);
        else
            newVal = round(newVal * sfreq) / sfreq;
            newVal = bst_saturate(newVal, bounds);
        end
        % Get min and max values from other text fields
        if ~isempty(jTextMin)
            textMinVal = GetValue(jTextMin);
            if (newVal < textMinVal)
                %newVal = currentValue;
                SetValue(jTextMin, newVal);
            end
        end
        if ~isempty(jTextMax)
            textMaxVal = GetValue(jTextMax);
            if (newVal > textMaxVal)
                %newVal = currentValue;
                SetValue(jTextMax, newVal);
            end
        end
        % Update text field
        SetValue(jTextValid, newVal);
        % Save new value
        currentValue = newVal;
        % Call additional callback
        if ~isempty(fcnCallback) && isCallback && isChanged
            fcnCallback();
        end
    end


%% ===== GET VALUES =====
    function val = GetValue(jText)
        % Get and check value
        val = str2num(char(jText.getText()));
        if isempty(val)
            val = [];
        % Convert back to ms
        elseif strcmpi(TimeUnits, 'ms')
            val = val / 1000; 
        end
    end

%% ===== SET VALUES =====
    function SetValue(jText, val)
        strVal = panel_time('FormatValue', val, TimeUnits, precision);
        jText.setText(strVal);
    end

end

