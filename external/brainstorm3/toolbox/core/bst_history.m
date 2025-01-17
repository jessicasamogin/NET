function FileMat = bst_history(action, FileMat, eventType, eventDesc)
% BST_HISTORY: Manages the History field in Brainstorm files or structures
% 
% USAGE:  FileMat = bst_history('add',  FileMat,  eventType, eventDesc);
%                   bst_history('add',  FileName, eventType, eventDesc);
%         FileMat = bst_history('add',  FileMat,  historyList, descPrefix);
%                   bst_history('add',  FileName, historyList, descPrefix);
%                   bst_history('view', FileName);
%         FileMat = bst_history('reset', FileMat);

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
% Authors: Francois Tadel, 2010

if (nargin < 4)
    eventDesc = [];
end

%% ===== PARSE INPUTS =====
if isstruct(FileMat)
    FileName = [];
    strHistory = sprintf('\nStructure history:\n\n');
elseif ischar(FileMat)
    % Check file type
    FileName = FileMat;
    fileType = file_gettype(FileName);
    if strcmpi(fileType, 'link')
        FileName = file_resolve_link(FileName);
    end
    % Load file
    warning off MATLAB:load:variableNotFound
    FileMat = load(FileName, 'History');
    warning on MATLAB:load:variableNotFound
    
    % Try to get file in database
    [sStudy, iStudy, iItem] = bst_get('AnyFile', FileName);
    % Display header : file path, file name
    if isempty(sStudy)
        [filePath, fileBase, fileExt] = bst_fileparts(FileName);
        fileBase = [fileBase, fileExt];
    else
        ProtocolInfo = bst_get('ProtocolInfo');
        [FileName, FileType, isAnatomy] = file_fullpath(FileName);
        if isAnatomy
            filePath = ProtocolInfo.SUBJECTS;
        else
            filePath = ProtocolInfo.STUDIES;
        end
        fileBase = file_win2unix(strrep(FileName, filePath, ''));
    end
    nbSeparators = 6 + max(length(filePath), length(fileBase));
    strHistory = sprintf('\nPath: %s\nName: %s\n%s\n\n', filePath, fileBase, repmat('-', [1,nbSeparators]));
else
    error('Invalid structure type.');
end

%% ===== ACTION =====
switch lower(action)
    case 'add'
        % If event to add is already an history cell list
        if iscell(eventType)
            cellHistory = eventType;
            % Add prefix to description, if specified
            if ~isempty(eventDesc)
                cellHistory(:,3) = cellfun(@(c)cat(2, eventDesc, c), cellHistory(:,3), 'UniformOutput', 0);
            end
        else
            eventTime = datestr(now);
            cellHistory = {eventTime, eventType, eventDesc};
        end
        % Add history line
        if ~isfield(FileMat, 'History') || isempty(FileMat.History)
            FileMat.History = cellHistory;
        else
            FileMat.History = cat(1, FileMat.History, cellHistory);
        end
        isModified = 1;
        
    case 'view'
        if ~isfield(FileMat, 'History') || isempty(FileMat.History)
            strHistory = [strHistory, 'No history recorded.' 10];
        else
            % Get maximum size for type
            maxLenType = max(cellfun(@length, FileMat.History(:,2)));
            % Loop on each entry in History table
            for i = 1:size(FileMat.History,1)
                strSep = repmat(' ', [1, maxLenType - length(FileMat.History{i,2})]);
                strHistory = [strHistory, ' - ', FileMat.History{i,1}, ' | ', FileMat.History{i,2}, strSep, ' | ', FileMat.History{i,3}, 10];
            end
        end
        view_text(strHistory, 'File history');
        isModified = 0;
        
    case 'reset'
        FileMat.History = [];
        isModified = 1;
        
    otherwise
        error('Unknown command.');
end

%% ===== SAVE MODIFICATIONS =====
if isModified && ~isempty(FileName)
    save(FileName, '-struct', 'FileMat', '-append');
end




