function varargout = process_extract_pthresh( varargin )
% PROCESS_EXTRACT_PTHRESH: Apply a statistical threshold to a stat file.
%
% USAGE:  OutputFiles = process_extract_pthresh('Run', sProcess, sInput)
%           threshmap = process_extract_pthresh('Compute', StatMat, StatThreshOptions)
%                pmap = process_extract_pthresh('GetPmap', tmap, df)

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
% Authors: Francois Tadel, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Apply statistic threshold';
    sProcess.FileTag     = '| cluster';
    sProcess.Category    = 'File';
    sProcess.SubGroup    = 'Extract';
    sProcess.Index       = 370;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'pdata', 'presults', 'ptimefreq'};
    sProcess.OutputTypes = {'data',  'results',  'timefreq'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    
    % === P-VALUE THRESHOLD
    sProcess.options.pthresh.Comment = 'p-value threshold: ';
    sProcess.options.pthresh.Type    = 'value';
    sProcess.options.pthresh.Value   = {0.05,'',4};
    % === CORRECTION
    sProcess.options.label1.Comment = '<HTML><BR>Correction for multiple comparisons:';
    sProcess.options.label1.Type    = 'label';
    sProcess.options.correction.Comment = {'Uncorrected', 'Bonferroni', 'False discovery rate (FDR)'};
    sProcess.options.correction.Type    = 'radio';
    sProcess.options.correction.Value   = 1;
    % === CONTROL 
    sProcess.options.label2.Comment = '<HTML><BR>Contol over dimensions:';
    sProcess.options.label2.Type    = 'label';
    sProcess.options.control1.Comment = '1: Signals';
    sProcess.options.control1.Type    = 'checkbox';
    sProcess.options.control1.Value   = 1;
    sProcess.options.control2.Comment = '2: Time';
    sProcess.options.control2.Type    = 'checkbox';
    sProcess.options.control2.Value   = 1;
    sProcess.options.control3.Comment = '3: Frequency';
    sProcess.options.control3.Type    = 'checkbox';
    sProcess.options.control3.Value   = 1;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Get options
    [StatThreshOptions, strCorrect] = GetOptions(sProcess);
    % Final process string
    Comment = [sProcess.Comment ': ' strCorrect];
end


%% ===== GET OPTIONS =====
function [StatThreshOptions, strCorrect] = GetOptions(sProcess)
    % Get threshold
    StatThreshOptions.pThreshold = sProcess.options.pthresh.Value{1};
    % Get controlled dimensions
    StatThreshOptions.Control = [];
    if (sProcess.options.control1.Value == 1)
        StatThreshOptions.Control(end+1) = 1;
    end
    if (sProcess.options.control2.Value == 1)
        StatThreshOptions.Control(end+1) = 2;
    end
    if (sProcess.options.control3.Value == 1)
        StatThreshOptions.Control(end+1) = 3;
    end
    % Get type of correction
    switch (sProcess.options.correction.Value)
        case 1
            strCorrect = '';
            StatThreshOptions.Correction = 'none';
        case 2
            strCorrect = ' (Bonferroni:';
            StatThreshOptions.Correction = 'bonferroni';
        case 3
            strCorrect = ' (FDR:';
            StatThreshOptions.Correction = 'fdr';
    end
    % Format string for correction
    if isempty(strCorrect) || isempty(StatThreshOptions.Control)
        strCorrect = '';
    else
        for i = 1:length(StatThreshOptions.Control)
            if (i == length(StatThreshOptions.Control))
                strCorrect = [strCorrect, num2str(StatThreshOptions.Control(i)), ')'];
            else
                strCorrect = [strCorrect, num2str(StatThreshOptions.Control(i)), ','];
            end
        end
    end
    % Final process string
    strCorrect = ['p<' num2str(StatThreshOptions.pThreshold) strCorrect];
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInput) %#ok<DEFNU>
    % Get options
    [StatThreshOptions, strCorrect] = GetOptions(sProcess);
    % Process separately the three types of files
    switch (sInput.FileType)
        case 'pdata'
            % Load input stat file
            StatMat = in_bst_data(sInput.FileName, 'pmap', 'tmap', 'df', 'Comment', 'ChannelFlag', 'Time', 'History', 'ColormapType');
            % Create a new data file structure
            DataMat = db_template('datamat');
            DataMat.F            = Compute(StatMat, StatThreshOptions);
            DataMat.Comment      = [StatMat.Comment ' | ' strCorrect];
            DataMat.ChannelFlag  = StatMat.ChannelFlag;
            DataMat.Time         = StatMat.Time;
            DataMat.DataType     = 'tmap';
            DataMat.Device       = 'stat';
            DataMat.nAvg         = 1;
            DataMat.Events       = [];
            DataMat.History      = StatMat.History;
            DataMat.ColormapType = StatMat.ColormapType;
            
        case 'presults'
            % Load input stat file
            StatMat = in_bst_results(sInput.FileName, 0, 'pmap', 'tmap', 'df', 'Comment', 'ChannelFlag', 'Time', 'History', 'ColormapType', 'GoodChannel', 'SurfaceFile', 'Atlas', 'GridLoc', 'nComponents', 'HeadModelType');
            % New results structure
            DataMat = db_template('resultsmat');
            DataMat.ImageGridAmp  = Compute(StatMat, StatThreshOptions);
            DataMat.ImagingKernel = [];
            DataMat.Comment       = [StatMat.Comment ' | ' strCorrect];
            DataMat.Function      = 'pthresh';
            DataMat.Time          = StatMat.Time;
            DataMat.DataFile      = [];
            DataMat.HeadModelFile = [];
            DataMat.HeadModelType = StatMat.HeadModelType;
            DataMat.nComponents   = StatMat.nComponents;
            DataMat.GridLoc       = StatMat.GridLoc;
            DataMat.Atlas         = StatMat.Atlas;
            DataMat.SurfaceFile   = StatMat.SurfaceFile;
            DataMat.GoodChannel   = StatMat.GoodChannel;
            DataMat.ChannelFlag   = StatMat.ChannelFlag;
            DataMat.History       = StatMat.History;
            DataMat.ColormapType  = StatMat.ColormapType;
            
        case 'ptimefreq'
            % Load input stat file
            StatMat = in_bst_timefreq(sInput.FileName, 0,  'pmap', 'tmap', 'df', 'Type', 'Comment', 'ChannelFlag', 'Time', 'History', 'ColormapType', 'GoodChannel', 'SurfaceFile', 'Atlas', 'GridLoc', 'nComponents', 'HeadModelType', 'DataType', 'TimeBands', 'Freqs', 'RefRowNames', 'RowNames', 'Measure', 'Method', 'Options');
            % New results structure
            DataMat = db_template('timefreqmat');
            DataMat.TF            = Compute(StatMat, StatThreshOptions);
            DataMat.Comment       = [StatMat.Comment ' | ' strCorrect];
            DataMat.Options       = StatMat.Options;
            DataMat.Type          = StatMat.Type;
            DataMat.Time          = StatMat.Time;
            DataMat.ChannelFlag   = StatMat.ChannelFlag;
            DataMat.HeadModelType = StatMat.HeadModelType;
            DataMat.GridLoc       = StatMat.GridLoc;
            DataMat.GoodChannel   = StatMat.GoodChannel;
            DataMat.ColormapType  = StatMat.ColormapType;
            DataMat.DataFile      = [];
            DataMat.Atlas         = StatMat.Atlas;
            DataMat.History       = StatMat.History;
            DataMat.DataType      = StatMat.DataType;
            DataMat.SurfaceFile   = StatMat.SurfaceFile;
            DataMat.TimeBands     = StatMat.TimeBands;
            DataMat.Freqs         = StatMat.Freqs;
            DataMat.RefRowNames   = StatMat.RefRowNames;
            DataMat.RowNames      = StatMat.RowNames;
            DataMat.Measure       = StatMat.Measure;
            DataMat.Method        = StatMat.Method;
            DataMat.Options       = StatMat.Options;
    end
    
    % Add history entry
    DataMat = bst_history('add', DataMat, 'pthresh', ['Setting the stat threshold: ' strCorrect]);
    DataMat = bst_history('add', DataMat, 'pthresh', ['Original file: ' sInput.FileName]);
    % Output file tag
    FileTag = bst_process('GetFileTag', sInput.FileName);
    FileTag = [FileTag(2:end) '_pthresh'];
    % Output filename
    DataFile = bst_process('GetNewFilename', bst_fileparts(sInput.FileName), FileTag);
    % Save on disk
    bst_save(DataFile, DataMat, 'v6');
    % Register in database
    db_add_data(sInput.iStudy, DataFile, DataMat);
    % Return data file
    OutputFiles{1} = DataFile;
end


%% ===== APPLY THRESHOLD =====
function threshmap = Compute(StatMat, StatThreshOptions)
    % If options not provided, read them from the interface
    if (nargin < 2) || isempty(StatThreshOptions)
        StatThreshOptions = bst_get('StatThreshOptions');
    end
    % Get or calculate p-values map
    if isfield(StatMat, 'pmap') && ~isempty(StatMat.pmap)
        pmap = StatMat.pmap;
    elseif isfield(StatMat, 'df') && ~isempty(StatMat.df)
        pmap = GetPmap(StatMat.tmap, StatMat.df);
    else
        error('Missing information to apply a statistical threshold.');
    end
    % Correction for multiple comparisons
    pmask = bst_stat_thresh(pmap, StatThreshOptions);
    % Compute pseudo-recordings file : Threshold tmap with pmask
    threshmap = zeros(size(StatMat.tmap));
    threshmap(pmask) = StatMat.tmap(pmask);
end


%% ===== GET PMAP ====
function pmap = GetPmap(tmap, df)
    % Calculate p-values from t-values
    pmap = betainc( df ./ (df + tmap .^ 2), df/2, 0.5);
    % Produces the same as this code:
    % prob = tcdf(abs(t),df);
    % p = 2 * (1-prob);
end



