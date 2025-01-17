function DataMat = in_bst_data( DataFile, varargin )
% IN_BST_DATA: Load a Brainstorm Data file, and compute missing fields.
%
% USAGE:  DataMat = in_bst_data( DataFile, FieldsToRead );
%         DataMat = in_bst_data( DataFile );
% INPUT: 
%     - DataFile    : full path to a recordings file
%     - FieldsToRead: List of strings decribing the fields to be read in the file
% OUTPUT:
%     - DataMat:  Brainstorm MRI structure

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
% Authors: Francois Tadel, 2009-2014


% ===== PARSE INPUTS =====
ProtocolInfo = bst_get('ProtocolInfo');
% Get full filename and relative filename
if file_exist(DataFile)
    DataFileFull = DataFile;
    DataFile = strrep(DataFile, ProtocolInfo.STUDIES, '');
else
    DataFileFull = bst_fullfile(ProtocolInfo.STUDIES, DataFile);
end
if ~file_exist(DataFileFull)
    error(['Data file was not found: ' 10 file_short(DataFileFull) 10 'Please reload this protocol (right-click > reload).']);
end
% Get file in database
isRaw = (length(DataFile) > 9) && ~isempty(strfind(DataFile, 'data_0raw'));

% Fields to read
isAddF = 0;
isAddZScore = 0;
if isempty(varargin)
    file_whos = whos('-file', DataFileFull);
    FieldsToRead = {file_whos.name};
else
    FieldsToRead = varargin;
    % Remove empty strings
    FieldsToRead = setdiff(FieldsToRead, {''});
    % If there is F without ChannelFlag, add it
    if ismember('F', FieldsToRead) && ~ismember('ChannelFlag', FieldsToRead)
        FieldsToRead{end + 1} = 'ChannelFlag';
    end
    % If reading Time in a raw file: need F (=sFile)
    if isRaw && ismember('Time', FieldsToRead) && ~ismember('F', FieldsToRead)
        FieldsToRead{end + 1} = 'F';
        isAddF = 1;
    end
    % Always read ZScore field
    if ~isRaw && ismember('F', FieldsToRead) && ~ismember('ZScore', FieldsToRead)
        FieldsToRead{end + 1} = 'ZScore';
        isAddZScore = 1;
    end
end

% ===== LOAD FILE =====
try
    warning off
    DataMat = load(DataFileFull, FieldsToRead{:});
    warning on
catch
    error(['Cannot load recordings file: "' DataFileFull '".' 10 10 lasterr]);
end

% ===== RAW: TIME VECTOR =====
if isRaw && ismember('Time', FieldsToRead)
    DataMat.Time = panel_time('GetRawTimeVector', DataMat.F);
end

% ===== MISSING FIELDS =====
for i = 1:length(FieldsToRead)
    if ~isfield(DataMat, FieldsToRead{i})
        switch(FieldsToRead{i}) 
            case 'nAvg'
                DataMat.nAvg = 1;
            case 'DataType'
                DataMat.DataType = 'recordings';
            otherwise
                DataMat.(FieldsToRead{i}) = [];
        end
    end
end
% Remove F field
if isAddF
    DataMat = rmfield(DataMat, 'F');
    FieldsToRead = setdiff(FieldsToRead, 'F');
end

% ===== RAW FILE + PROJECTORS =====
% Make sure that they are in the right format
if isRaw && ismember('F', FieldsToRead) && ~isempty(DataMat.F.channelmat) && isfield(DataMat.F.channelmat, 'Projector') && ~isempty(DataMat.F.channelmat.Projector)
    if ~isstruct(DataMat.F.channelmat.Projector)
        DataMat.F.channelmat.Projector = process_ssp('ConvertOldFormat', DataMat.F.channelmat.Projector);
    end
end

% ===== APPLY Z-SCORE =====
if ismember('ZScore', FieldsToRead) && ~isempty(DataMat.ZScore)
    DataMat.F = process_zscore_dynamic('Compute', DataMat.F, DataMat.ZScore);
    DataMat = rmfield(DataMat, 'ZScore');
elseif isAddZScore
    DataMat = rmfield(DataMat, 'ZScore');
end

                