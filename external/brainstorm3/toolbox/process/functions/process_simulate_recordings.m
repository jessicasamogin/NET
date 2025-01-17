function varargout = process_simulate_recordings( varargin )
% PROCESS_SIMULATE_SOURCES: Simulate source files based on some scouts.
%
% USAGE:  OutputFiles = process_simulate_recordings('Run', sProcess, sInputA)
 
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
    sProcess.Comment     = 'Simulate recordings from scouts';
    sProcess.FileTag     = '';
    sProcess.Category    = 'File';
    sProcess.SubGroup    = 'Simulate'; 
    sProcess.Index       = 915; 
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'matrix'};
    sProcess.OutputTypes = {'data'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;

    % === CLUSTERS
    sProcess.options.scouts.Comment = '';
    sProcess.options.scouts.Type    = 'cluster';
    sProcess.options.scouts.Value   = [];
    % === SAVE SOURCES
    sProcess.options.savesources.Comment = 'Save full sources';
    sProcess.options.savesources.Type    = 'checkbox';
    sProcess.options.savesources.Value   = 0;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInput) %#ok<DEFNU>
    OutputFiles = {};

    % === GET OPTIONS ===
    % Get scouts
    sScouts = sProcess.options.scouts.Value;
    if isempty(sScouts)
        bst_report('Error', sProcess, [], 'No scouts selected.');
        return;
    end
    % Get other optinos
    SaveSources = sProcess.options.savesources.Value;
    
    % === LOAD INPUT FILE ===
    % Read input file
    sMatrix = in_bst_matrix(sInput.FileName);
    % Check dimensions
    if (length(sScouts) ~= size(sMatrix.Value,1))
        bst_report('Error', sProcess, [], sprintf('The number of selected scouts (%d) does not match the number of signals (%d).', length(sScouts), size(sMatrix.Value,1)));
        return;
    end
    
    % === LOAD CHANNEL FILE / HEAD MODEL===
    % Get condition
    sStudy = bst_get('Study', sInput.iStudy);
    % Get channel file
    [sChannel, iStudyChannel] = bst_get('ChannelForStudy', sInput.iStudy);
    if isempty(sChannel)
        bst_report('Error', sProcess, [], ['No channel file available.' 10 'Please import a channel file in this study before running simulations.']);
        return;
    end
    % Get study channel
    sStudyChannel = bst_get('Study', iStudyChannel);
    % Check head model
    if isempty(sStudyChannel.iHeadModel)
        bst_report('Error', sProcess, [], ['No head model file available.' 10 'Please calculate a head model before running simulations.']);
        return;
    end
    % Load channel file
    ChannelMat = in_bst_channel(sChannel.FileName);
    % Load head model
    HeadModelFile = sStudyChannel.HeadModel(sStudyChannel.iHeadModel).FileName;
    HeadModelMat = in_headmodel_bst(HeadModelFile);
    % If no orientations: error
    if isempty(HeadModelMat.GridOrient)
        bst_report('Error', sProcess, [], 'No source orientations available in this head model.');
        return;
    end
    % Apply the fixed orientation to the Gain matrix (normal to the cortex)
    HeadModelMat.Gain = bst_gain_orient(HeadModelMat.Gain, HeadModelMat.GridOrient);
    % Get all the MEG/EEG channels
    Modalities = {};
    if ~isempty(HeadModelMat.MEGMethod)
        Modalities{end+1} = 'MEG';
    end
    if ~isempty(HeadModelMat.EEGMethod)
        Modalities{end+1} = 'EEG';
    end
    if ~isempty(HeadModelMat.SEEGMethod)
        Modalities{end+1} = 'SEEG';
    end
    if ~isempty(HeadModelMat.ECOGMethod)
        Modalities{end+1} = 'ECOG';
    end
    iChannels = channel_find(ChannelMat.Channel, Modalities);
    
    
    % === LOAD CORTEX ===
%     % Get subject
%     sSubject = bst_get('Subject', sInput.SubjectFile);
%     if isempty(sSubject.iCortex)
%         bst_report('Error', sProcess, [], 'No default cortex available.');
%         return;
%     end
%     % Get cortex file
%     SurfaceFile = sSubject.Surface(sSubject.iCortex).FileName;
    % Get surface from the head model
    SurfaceFile = HeadModelMat.SurfaceFile;
    % Load surface
    SurfaceMat = in_tess_bst(SurfaceFile);
    
    % === GENERATE SOURCE MATRIX ===
    nSources = length(SurfaceMat.Vertices);
    nTime = size(sMatrix.Value,2);
    % Initialize space matrix
    ImageGridAmp = sparse([],[],[],nSources, nTime, length([sScouts.Vertices])*nTime);
    % Fill matrix
    for i = 1:length(sScouts)
        ImageGridAmp(sScouts(i).Vertices,:) = repmat(sMatrix.Value(i,:), length(sScouts(i).Vertices), 1);
    end
    % Set unit range to pAm
    ImageGridAmp = 1e-9 .* ImageGridAmp;
    
    % === SAVE RECORDINGS ===
    % Generate data matrix
    F = zeros(length(ChannelMat.Channel), nTime);
    F(iChannels,:) = HeadModelMat.Gain(iChannels,:) * ImageGridAmp;
    % Create a new data file structure
    DataMat = db_template('datamat');
    DataMat.F           = F;
    DataMat.Comment     = sMatrix.Comment;
    DataMat.ChannelFlag = ones(length(ChannelMat.Channel), 1);
    DataMat.Time        = sMatrix.Time;
    DataMat.DataType    = 'recordings';
    DataMat.Device      = 'simulation';
    DataMat.nAvg        = 1;
    DataMat.Events      = [];
    % Add history entry
    DataMat = bst_history('add', DataMat, 'simulate', ['Simulated from file: ' sInput.FileName]);
    % Output filename
    DataFile = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), 'data_sim');
    % Save on disk
    bst_save(DataFile, DataMat, 'v6');
    % Register in database
    db_add_data(sInput.iStudy, DataFile, DataMat);
    % Return data file
    OutputFiles{1} = DataFile;
    
    % === SAVE SOURCE FILE ===
    if SaveSources
        % Create a new source file structure
        ResultsMat = db_template('resultsmat');
        ResultsMat.ImagingKernel = [];
        ResultsMat.ImageGridAmp  = full(ImageGridAmp);
        ResultsMat.nComponents   = 1;
        ResultsMat.Comment       = sMatrix.Comment;
        ResultsMat.Function      = 'Simulation';
        ResultsMat.Time          = sMatrix.Time;
        ResultsMat.DataFile      = file_short(DataFile);
        ResultsMat.HeadModelFile = HeadModelFile;
        ResultsMat.HeadModelType = HeadModelMat.HeadModelType;
        ResultsMat.ChannelFlag   = [];
        ResultsMat.GoodChannel   = iChannels;
        ResultsMat.SurfaceFile   = SurfaceFile;
        ResultsMat.GridLoc       = [];
        % Add history entry
        ResultsMat = bst_history('add', ResultsMat, 'simulate', ['Simulated from file: ' sInput.FileName]);
        % Output filename
        ResultsFile = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), 'results_sim');
        % Save on disk
        bst_save(ResultsFile, ResultsMat, 'v6');
        % Register in database
        db_add_data(sInput.iStudy, ResultsFile, ResultsMat);
    end
end



