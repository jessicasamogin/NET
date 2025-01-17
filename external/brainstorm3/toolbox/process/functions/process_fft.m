function varargout = process_fft( varargin )
% PROCESS_FFT: Computes the FFT of all the trials, and average them.

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

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Fourier transform (FFT)';
    sProcess.FileTag     = 'fft';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Frequency';
    sProcess.Index       = 501;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'raw', 'data', 'results', 'matrix'};
    sProcess.OutputTypes = {'timefreq', 'timefreq', 'timefreq', 'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Options: Time window
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'timewindow';
    sProcess.options.timewindow.Value   = [];
    sProcess.options.timewindow.InputTypes = {'raw','data'};
    % Options: CLUSTERS
    sProcess.options.clusters.Comment = '';
    sProcess.options.clusters.Type    = 'cluster_confirm';
    sProcess.options.clusters.Value   = {};
    % Options: Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
    sProcess.options.sensortypes.InputTypes = {'raw','data'};
%     % === IS FREQ BANDS
%     sProcess.options.isfreqbands.Comment = 'Group by frequency bands (name/freqs/function):';
%     sProcess.options.isfreqbands.Type    = 'checkbox';
%     sProcess.options.isfreqbands.Value   = 0;
%     % === FREQ BANDS
%     sProcess.options.freqbands.Comment = '';
%     sProcess.options.freqbands.Type    = 'groupbands';
%     sProcess.options.freqbands.Value   = bst_get('DefaultFreqBands');
%     % === APPLY MEASURE
%     sProcess.options.ismeasure.Comment = '<HTML>Return power of FFT coefficients<BR>(if not, return the complex values)';
%     sProcess.options.ismeasure.Type    = 'checkbox';
%     sProcess.options.ismeasure.Value   = 1;
    % === AVERAGE OUTPUT FILES
    sProcess.options.avgoutput.Comment = '<HTML>Save average power of FFT values across files<BR>(do not save one new file per input file)';
    sProcess.options.avgoutput.Type    = 'checkbox';
    sProcess.options.avgoutput.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Call TIME-FREQ process
    OutputFiles = process_timefreq('Run', sProcess, sInputs);
end




