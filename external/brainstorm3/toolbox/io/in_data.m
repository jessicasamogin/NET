function [ImportedData, ChannelMat, nTime, ImportOptions] = in_data( DataFile, FileFormat, ImportOptions, nbCall)
% IN_DATA: Import any type of EEG/MEG recordings files.
%
% USAGE:  [ImportedData, ChannelMat, nTime, ImportOptions] = in_data( DataFile, FileFormat, ImportOptions, nbCall ) 
%         [ImportedData, ChannelMat, nTime, ImportOptions] = in_data( DataFile, FileFormat, ImportOptions )    % Considered as first call
%         [ImportedData, ChannelMat, nTime, ImportOptions] = in_data( DataFile, FileFormat )                   % Display the import GUI
%         [ImportedData, ChannelMat, nTime, ImportOptions] = in_data( sFile, ...)            % Same calls, but specify the sFile structure
%
% INPUT:
%    - DataFile      : Full path to a recordings file (called 'data' files in Brainstorm)
%    - sFile         : Structure representing a RAW file already open in Brainstorm
%    - FileFormat    : File format name
%    - ImportOptions : Structure that describes how to import the recordings
%    - nbCall        : For internal use only (indice of this call when consecutive calls from import_data.m
% 
% OUTPUT: 
%    - ImportedData : Brainstorm standard recordings ('data') structure
%    - ChannelMat   : Brainstorm standard channels structure
%    - nTime        : Number of time points that were read
%    - ImportOptions: Return the modifications made to ImportOptions, so that the next calls use the same options

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

%% ===== PARSE INPUTS ===== 
if (nargin < 4) || isempty(nbCall)
    nbCall = 1;
end
if (nargin < 3) || isempty(ImportOptions)
    ImportOptions = db_template('ImportOptions');
end
sFile = [];
if (nargin < 2)
    error('Invalid call.');
elseif isstruct(DataFile)
    sFile = DataFile;
    DataFile = sFile.filename;
elseif ~isempty(strfind(DataFile, '_0raw'))
    FileMat  = in_bst_data(DataFile, 'F');
    sFile    = FileMat.F;
    DataFile = sFile.filename;
elseif ~file_exist(DataFile)
    error('File does not exist: "%s"', DataFile);
end


%% ===== READ FILE =====
% Initialize returned variables
ImportedData = [];
ChannelMat = [];
targetFileNames = {};
nTime = [];
% Initialize list of file blocks to read
BlocksToRead = repmat(struct('iEpoch',      [], ...
                             'iTimes',      '', ...
                             'FileTag',     '', ...
                             'Comment',     '', ...
                             'TimeOffset',  0, ...
                             'isBad',       [], ...
                             'ChannelFlag', []), 0);
% Get temporary directory
tmpDir = bst_get('BrainstormTmpDir');
[filePath, fileBase, fileExt] = bst_fileparts(DataFile);
% Indicates if something is imported
isDataSaved = 0;
% Switch between file formats
switch upper(FileFormat)
    case {'FIF', 'CTF', 'CTF-CONTINUOUS', '4D', 'KIT', 'LENA', 'EEG-ANT-CNT', 'EEG-BRAINAMP', 'EEG-DELTAMED', 'EEG-EGI-RAW', 'EEG-NEUROSCAN-CNT', 'EEG-NEUROSCAN-EEG', 'EEG-NEUROSCAN-AVG', 'EEG-EDF', 'EEG-BDF', 'EEG-EEGLAB', 'EEG-MANSCAN', 'EEG-NEUROSCOPE', 'NIRS-MFIP', 'BST-DATA'}
        isDataSaved = 1;
        % If file not open yet: Open file
        if isempty(sFile)
            [sFile, errMsg] = in_fopen(DataFile, FileFormat, ImportOptions);
            if isempty(sFile)
                return
            end
            % Yokogawa non-registered warning
            if ~isempty(errMsg) && ImportOptions.DisplayMessages
                java_dialog('warning', errMsg, 'Open raw EEG/MEG recordings');
            end
        end    

        % Display import GUI
        if (nbCall == 1) && ImportOptions.DisplayMessages
            comment = ['Import ' sFile.format ' file'];
            ImportOptions = gui_show_dialog(comment, @panel_import_data, 1, [], sFile);
            % If user canceled the process
            if isempty(ImportOptions)
                bst_progress('stop');
                return
            end
        % Check number of epochs
        elseif strcmpi(ImportOptions.ImportMode, 'Epoch')
            if isempty(sFile.epochs)
                error('This file does not contain any epoch. Try importing it as continuous, or based on events.');
            elseif ImportOptions.GetAllEpochs
                ImportOptions.iEpochs = 1:length(sFile.epochs);
            elseif any(ImportOptions.iEpochs > length(sFile.epochs)) || any(ImportOptions.iEpochs < 1)
                error(['You selected an invalid epoch index.' 10 ...
                       'To import all the epochs at once, please check the "Use all epochs" option.' 10]);
            end
        end
        
        % Switch between file types
        switch lower(ImportOptions.ImportMode)
            % ===== EPOCHS =====
            case 'epoch'
                % If all data sets have the same comment: consider them as trials
                isTrials = (length(sFile.epochs) > 1) && all(strcmpi({sFile.epochs.label}, sFile.epochs(1).label));
                % Loop on all epochs
                for ieph = 1:length(ImportOptions.iEpochs)
                    % Get epoch number
                    iEpoch = ImportOptions.iEpochs(ieph);
                    % Import structure
                    BlocksToRead(end+1).iEpoch   = iEpoch;
                    BlocksToRead(end).Comment    = sFile.epochs(iEpoch).label;
                    BlocksToRead(end).TimeOffset = 0;
                    % Copy optional fields
                    if isfield(sFile.epochs(iEpoch), 'bad') && (sFile.epochs(iEpoch).bad == 1)
                        BlocksToRead(end).isBad = 1;
                    end
                    if isfield(sFile.epochs(iEpoch), 'channelflag') && ~isempty(sFile.epochs(iEpoch).channelflag)
                        BlocksToRead(end).ChannelFlag = sFile.epochs(iEpoch).channelflag;
                    end
                    % Build file tag
                    FileTag = BlocksToRead(end).Comment;
                    % Add trial number, if considering sets as a list of trials for the same condition
                    if isTrials
                        FileTag = [FileTag, sprintf('_trial%03d', iEpoch)];
                    end
                    % Add condition TAG, if required in input options structure
                    if ImportOptions.CreateConditions 
                        CondName = strrep(BlocksToRead(end).Comment, '#', '');
                        CondName = str_remove_parenth(CondName);
                        FileTag = [FileTag, '___COND', CondName, '___'];
                    end
                    BlocksToRead(end).FileTag = FileTag;
                    % Number of averaged trials
                    BlocksToRead(end).nAvg = sFile.epochs(iEpoch).nAvg;
                end
                
            % ===== RAW DATA: READING TIME RANGE =====
            case 'time'
                % Check time window
                if isempty(ImportOptions.TimeRange)
                    ImportOptions.TimeRange = sFile.prop.times;
                end
                % If SplitLength not defined: use the whole time range
                if ~ImportOptions.SplitRaw || isempty(ImportOptions.SplitLength)
                    ImportOptions.SplitLength = ImportOptions.TimeRange(2) - ImportOptions.TimeRange(1) + 1/sFile.prop.sfreq;
                end
                % Get block size in samples
                blockSmpLength = round(ImportOptions.SplitLength * sFile.prop.sfreq);
                totalSmpLength = round((ImportOptions.TimeRange(2) - ImportOptions.TimeRange(1)) * sFile.prop.sfreq) + 1;
                startSmp = round(ImportOptions.TimeRange(1) * sFile.prop.sfreq);                   
                % Get number of blocks
                nbBlocks = ceil(totalSmpLength / blockSmpLength);
                % For each block
                for iBlock = 1:nbBlocks
                    % Get samples indices for this block (start ind = 0)
                    smpBlock = startSmp + [(iBlock - 1) * blockSmpLength, min(iBlock * blockSmpLength - 1, totalSmpLength - 1)];
                    % Import structure
                    BlocksToRead(end+1).iEpoch   = 1;
                    BlocksToRead(end).iTimes     = smpBlock;
                    BlocksToRead(end).FileTag    = sprintf('block%03d', iBlock);
                    BlocksToRead(end).TimeOffset = 0;
                    % Build comment (seconds or miliseconds)
                    timeBlock = smpBlock / sFile.prop.sfreq;
                    if (timeBlock(2) > 2)
                        BlocksToRead(end).Comment = sprintf('Raw (%1.2fs,%1.2fs)', timeBlock);
                    else
                        BlocksToRead(end).Comment = sprintf('Raw (%dms,%dms)', round(1000 * timeBlock));
                    end
                    % Number of averaged trials
                    BlocksToRead(end).nAvg = sFile.prop.nAvg;
                end

            % ===== EVENTS =====
            case 'event'
                isExtended = false;
                % For each event
                for iEvent = 1:length(ImportOptions.events)
                    nbOccur = size(ImportOptions.events(iEvent).samples, 2);
                    % Detect event type: simple or extended
                    isExtended = (size(ImportOptions.events(iEvent).samples, 1) == 2);
                    % For each occurrence of this event
                    for iOccur = 1:nbOccur
                        % Samples range to read
                        if isExtended
                            samplesBounds = [0, diff(ImportOptions.events(iEvent).samples(:,iOccur))];
                        else
                            samplesBounds = round(ImportOptions.EventsTimeRange * sFile.prop.sfreq);
                        end
                        % Get epoch indices
                        samplesEpoch = round(double(ImportOptions.events(iEvent).samples(1,iOccur)) + samplesBounds);
                        if (samplesEpoch(1) < sFile.prop.samples(1))
                            % If required time before event is not accessible: 
                            TimeOffset = (sFile.prop.samples(1) - samplesEpoch(1)) / sFile.prop.sfreq;
                            samplesEpoch(1) = sFile.prop.samples(1);
                        else
                            TimeOffset = 0;
                        end
                        % Make sure all indices are valids
                        samplesEpoch = bst_saturate(samplesEpoch, sFile.prop.samples);
                        % Import structure
                        BlocksToRead(end+1).iEpoch   = ImportOptions.events(iEvent).epochs(iOccur);
                        BlocksToRead(end).iTimes     = samplesEpoch;
                        BlocksToRead(end).Comment    = sprintf('%s (#%d)', ImportOptions.events(iEvent).label, iOccur);
                        BlocksToRead(end).FileTag    = sprintf('%s_trial%03d', ImportOptions.events(iEvent).label, iOccur);
                        BlocksToRead(end).TimeOffset = TimeOffset;
                        BlocksToRead(end).nAvg       = 1;
                        % Add condition TAG, if required in input options structure
                        if ImportOptions.CreateConditions 
                            CondName = strrep(ImportOptions.events(iEvent).label, '#', '');
                            CondName = str_remove_parenth(CondName);
                            BlocksToRead(end).FileTag = [BlocksToRead(end).FileTag, '___COND' CondName '___'];
                        end
                    end
                end
                % In case of extended events: Ignore the EventsTimeRange time range field, and force time to start at 0
                if isExtended
                    %ImportOptions.ImportMode = 'time';
                    ImportOptions.EventsTimeRange = [0 1];
                end
        end
        
        
        %% ===== UPDATE CHANNEL FILE =====
        % No CTF Compensation
        if ~ImportOptions.UseCtfComp && isfield(sFile.channelmat, 'MegRefCoef')
            sFile.channelmat.MegRefCoef = [];
            sFile.prop.destCtfComp = sFile.prop.currCtfComp;
        end
        % No SSP
        if ~ImportOptions.UseSsp && isfield(sFile.channelmat, 'Projector')
            sFile.channelmat.Projector = [];
        end

        %% ===== READING AND SAVING =====
        % Get list of bad segments in file
        [badSeg, badEpochs] = panel_record('GetBadSegments', sFile);
        % Initialize returned variables
        ImportedData = repmat(db_template('Data'), 0);
        
        initBaselineRange = ImportOptions.BaselineRange;
        % Prepare progress bar
        bst_progress('start', 'Import MEG/EEG recordings', 'Initializing...', 0, length(BlocksToRead));
        % Loop on each recordings block to read
        for iFile = 1:length(BlocksToRead)
            % Set progress bar
            bst_progress('text', sprintf('Importing block #%d/%d...', iFile, length(BlocksToRead)));
            
            % ===== READING DATA =====
            % If there is a time offset: need to apply it to the baseline range...
            if (BlocksToRead(iFile).TimeOffset ~= 0) && strcmpi(ImportOptions.RemoveBaseline, 'time')
                ImportOptions.BaselineRange = initBaselineRange - BlocksToRead(iFile).TimeOffset;
            end
            % Read data block
            [F, TimeVector] = in_fread(sFile, BlocksToRead(iFile).iEpoch, BlocksToRead(iFile).iTimes, [], ImportOptions);
            % If block too small: ignore it
            if (size(F,2) < 3)
                disp(sprintf('BST> Block is too small #%03d: ignoring...', iFile));
                continue
            end
            % Add an addition time offset if defined
            if (BlocksToRead(iFile).TimeOffset ~= 0)
                TimeVector = TimeVector + BlocksToRead(iFile).TimeOffset;
            end
            % Build file structure
            DataMat = db_template('DataMat');
            DataMat.F        = F;
            DataMat.Comment  = BlocksToRead(iFile).Comment;
            DataMat.Time     = TimeVector;
            DataMat.Device   = sFile.device;
            DataMat.nAvg     = double(BlocksToRead(iFile).nAvg);
            DataMat.DataType = 'recordings';
            % Channel flag
            if ~isempty(BlocksToRead(iFile).ChannelFlag) 
                DataMat.ChannelFlag = BlocksToRead(iFile).ChannelFlag;
            else
                DataMat.ChannelFlag = sFile.channelflag;
            end
            
            % ===== GOOD / BAD TRIAL =====
            % If data block has already been marked as bad at an earlier stage, keep it bad 
            if ~isempty(BlocksToRead(iFile).isBad) && BlocksToRead(iFile).isBad
                isBad = BlocksToRead(iFile).isBad;
            % Else: Check if not reading in a bad segment
            else
                % By default: segment of data is good
                isBad = 0;
                % Get the block bounds (in samples #)
                iTimes = BlocksToRead(iFile).iTimes;
                % But if there are some bad segments in the file, check that the data we are
                % reading is not overlapping with one of these segments
                if ~isempty(iTimes) && ~isempty(badSeg)
                    % Check if this segment is outside of ALL the bad segments (either entirely before or entirely after)
                    if ~all((iTimes(2) < badSeg(1,:)) | (iTimes(1) > badSeg(2,:)))
                        isBad = 1;
                    end
                % For files read by epochs: check for bad epochs
                elseif isempty(iTimes) && ~isempty(badEpochs)
                    if ismember(BlocksToRead(iFile).iEpoch, badEpochs)
                        isBad = 1;
                    end
                end
            end
            
            % ===== ADD HISTORY FIELD =====
            % This records all the processes applied in in_fread (reset field)
            DataMat = bst_history('reset', DataMat);
            % History: File name
            DataMat = bst_history('add', DataMat, 'import', ['Import from: ' DataFile ' (' ImportOptions.ImportMode ')']);
            % History: Epoch / Time block
            DataMat = bst_history('add', DataMat, 'import', sprintf('=> Epoch #%d [%5.6f,%5.6f]s', BlocksToRead(iFile).iEpoch, TimeVector(1), TimeVector(end)));
            % History: CTF compensation
            if ~isempty(sFile.channelmat) && isfield(sFile.channelmat, 'MegRefCoef') && ~isempty(sFile.channelmat.MegRefCoef) && (sFile.prop.currCtfComp ~= sFile.prop.destCtfComp)
                DataMat = bst_history('add', DataMat, 'import', 'Apply CTF compensation matrix');
            end
            % History: SSP
            if ~isempty(sFile.channelmat) && isfield(sFile.channelmat, 'Projector') && ~isempty(sFile.channelmat.Projector)
                DataMat = bst_history('add', DataMat, 'import', 'Apply SSP projectors');
            end
            % History: Baseline removal
            switch (ImportOptions.RemoveBaseline)
                case 'all'
                    DataMat = bst_history('add', DataMat, 'import', 'Remove baseline (all)');
                case 'time'
                    DataMat = bst_history('add', DataMat, 'import', sprintf('Remove baseline: [%d, %d] ms', round(ImportOptions.BaselineRange * 1000)));
            end
            % History: resample
            if ImportOptions.Resample && (abs(ImportOptions.ResampleFreq - sFile.prop.sfreq) > 0.05)
                DataMat = bst_history('add', DataMat, 'import', sprintf('Resample: from %0.2f Hz to %0.2f Hz', sFile.prop.sfreq, ImportOptions.ResampleFreq));
            end
            
            % ===== EVENTS =====
            OldFreq = sFile.prop.sfreq;
            NewFreq = 1 ./ (TimeVector(2) - TimeVector(1));
            % Loop on all the events types
            for iEvt = 1:length(sFile.events)
                evtSamples  = sFile.events(iEvt).samples;
                readSamples = BlocksToRead(iFile).iTimes;
                % If there are no occurrences, or if it the event of interest: skip to next event type
                if isempty(evtSamples) || (strcmpi(ImportOptions.ImportMode, 'event') && any(strcmpi({ImportOptions.events.label}, sFile.events(iEvt).label)))
                    continue;
                end
                % Set the number of read samples for epochs
                if isempty(readSamples) && strcmpi(ImportOptions.ImportMode, 'epoch')
                    if isempty(sFile.epochs)
                        readSamples = sFile.prop.samples;
                    else
                        readSamples = sFile.epochs(BlocksToRead(iFile).iEpoch).samples;
                    end
                end
                % Apply resampling factor if necessary
                if (abs(OldFreq - NewFreq) > 0.05)
                    evtSamples  = round(evtSamples  / OldFreq * NewFreq);
                    readSamples = round(readSamples / OldFreq * NewFreq);
                end
                % Simple events
                if (size(evtSamples, 1) == 1)
                    if (size(evtSamples,2) == size(sFile.events(iEvt).epochs,2))
                        iOccur = find((evtSamples >= readSamples(1)) & (evtSamples <= readSamples(2)) & (sFile.events(iEvt).epochs == BlocksToRead(iFile).iEpoch));
                    else
                        iOccur = find((evtSamples >= readSamples(1)) & (evtSamples <= readSamples(2)));
                        disp(sprintf('BST> Warning: Mismatch in the events structures: size(samples)=%d, size(epochs)=%d', size(evtSamples,2), size(sFile.events(iEvt).epochs,2)));
                    end
                    % If no occurence found in current time block: skip to the next event
                    if isempty(iOccur)
                        continue;
                    end
                    % Calculate the sample indices of the events in the new file
                    newEvtSamples = round(TimeVector(evtSamples(:,iOccur) - readSamples(1) + 1) .* NewFreq);
                % Extended events: Get all the events that are not either completely before or after the time window
                else
                    iOccur = find((evtSamples(2,:) >= readSamples(1)) & (evtSamples(1,:) <= readSamples(2)) & (sFile.events(iEvt).epochs(1,:) == BlocksToRead(iFile).iEpoch(1,:)));
                    % If no occurence found in current time block: skip to the next event
                    if isempty(iOccur)
                        continue;
                    end
                    % Limit to current time window
                    evtSamples(evtSamples < readSamples(1)) = readSamples(1);
                    evtSamples(evtSamples > readSamples(2)) = readSamples(2);
                    % Calculate the sample indices of the events in the new file
                    newEvtSamples = [round(TimeVector(evtSamples(1,iOccur) - readSamples(1) + 1) .* NewFreq); ...
                                     round(TimeVector(evtSamples(2,iOccur) - readSamples(1) + 1) .* NewFreq)];
                end
                % Add new event category in the output file
                iEvtData = length(DataMat.Events) + 1;
                DataMat.Events(iEvtData).label   = sFile.events(iEvt).label;
                DataMat.Events(iEvtData).color   = sFile.events(iEvt).color;
                DataMat.Events(iEvtData).samples = newEvtSamples;
                DataMat.Events(iEvtData).times   = newEvtSamples ./ NewFreq;
                DataMat.Events(iEvtData).epochs  = sFile.events(iEvt).epochs(iOccur);
                if ~isempty(sFile.events(iEvt).reactTimes)
                    DataMat.Events(iEvtData).reactTimes = sFile.events(iEvt).reactTimes(iOccur);
                end
                DataMat.Events(iEvtData).select = sFile.events(iEvt).select;
            end
            
            % ===== SAVE FILE =====
            % Add extension, full path, and make valid and unique
            newFileName = ['data_', BlocksToRead(iFile).FileTag, '.mat'];
            newFileName = file_standardize(newFileName);
            newFileName = bst_fullfile(tmpDir, newFileName);
            newFileName = file_unique(newFileName);
            % Save new file
            bst_save(newFileName, DataMat, 'v6');
            % Information to store in database
            ImportedData(end+1).FileName = newFileName;
            ImportedData(end).Comment    = DataMat.Comment;
            ImportedData(end).DataType   = DataMat.DataType;
            ImportedData(end).BadTrial   = isBad;
            % Count number of time points
            nTime(end+1) = length(TimeVector);
            % Increment progress bar
            bst_progress('inc', 1);
        end
        % Get channel file
        ChannelMat = sFile.channelmat;

    case 'EEG-ASCII'
        DataMat = in_data_ascii(DataFile, nbCall);
    case 'EEG-BESA'
        DataMat = in_data_besa(DataFile);
    case 'EEG-BRAINVISION'
        % Override some options of the default ASCII interface for Cartool .EP files
        OPTIONS = bst_get('ImportEegRawOptions');
        OPTIONS.MatrixOrientation = 'timeXchannel';
        OPTIONS.VoltageUnits      = '\muV';
        OPTIONS.SkipLines         = 1;
        bst_set('ImportEegRawOptions', OPTIONS);
        % Read file
        DataMat = in_data_ascii(DataFile, nbCall);
    case 'EEG-CARTOOL'
        if strcmpi(fileExt, '.ep')
            % Override some options of the default ASCII interface for Cartool .EP files
            OPTIONS = bst_get('ImportEegRawOptions');
            OPTIONS.MatrixOrientation = 'timeXchannel';
            OPTIONS.VoltageUnits      = '\muV';
            OPTIONS.SkipLines         = 0;
            bst_set('ImportEegRawOptions', OPTIONS);
            % Read file
            DataMat = in_data_ascii(DataFile, nbCall);
        else
            DataMat = in_data_cartool(DataFile);
        end
    case 'EEG-ERPCENTER'
        [DataMat, targetFileNames] = in_data_erpcenter(DataFile);
    case 'EEG-MAT'
        DataMat = in_data_mat(DataFile, nbCall);
    case 'EEG-NEUROSCAN-DAT'
        DataMat = in_data_neuroscan_dat(DataFile);
    otherwise
        warning('Brainstorm:UnknowFormat', 'Unknown MEG/EEG file format.');
        return;
end

% Add history field to channel structure
if ~isempty(ChannelMat)
    ChannelMat = bst_history('add', ChannelMat, 'import', ['Import from: ' DataFile ' (Format: ' FileFormat ')']);
end


%% ===== SAVE DATA MATRIX IN BRAINSTORM FORMAT =====
% If data has not been saved yet
if ~isDataSaved
    % Get imported base name
    importedBaseName = strrep(fileBase, 'data_', '');
    importedBaseName = strrep(importedBaseName, '_data', '');
   
    % Process all the DataMat structures that were created
    ImportedData = repmat(db_template('Data'), [1, length(DataMat)]);
    for iData = 1:length(DataMat)
        if ~isempty(targetFileNames) && (iData <= length(targetFileNames)) && ~isempty(targetFileNames{iData})
            newFileName = targetFileNames{iData};
        else
            newFileName = importedBaseName;
        end
        % Produce a default data filename          
        BstDataFile = bst_fullfile(tmpDir, ['data_' newFileName '.mat']);
        BstDataFile = file_unique(BstDataFile);
        
        % Add History: File name
        FileMat = DataMat(iData); 
        FileMat = bst_history('add', FileMat, 'import', ['Import from: ' DataFile ' (Format: ' FileFormat ')']);
        FileMat.DataType = 'recordings';
        % Save new MRI in Brainstorm format
        bst_save(BstDataFile, FileMat, 'v6');
        
        % Create returned data structure
        ImportedData(iData).FileName = BstDataFile;
        % Add a Comment field (from DataMat if possible)
        if isfield(DataMat(iData), 'Comment') && ~isempty(DataMat(iData).Comment)
            ImportedData(iData).Comment = DataMat(iData).Comment;
        else
            DataMat(iData).Comment = [fileBase ' (' FileFormat ')'];
        end
        ImportedData(iData).DataType = FileMat.DataType;
        ImportedData(iData).BadTrial = 0;
        % Count number of time points
        nTime(iData) = length(FileMat.Time);
    end
end


