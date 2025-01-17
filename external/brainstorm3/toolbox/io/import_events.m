function [sFile, newEvents] = import_events(sFile, EventFile, FileFormat)
% IMPORT_EVENTS: Reads events from a file/structure and add them to a Brainstorm raw file structure.
%
% USAGE:  [sFile, newEvents] = import_events(sFile, EventFile, FileFormat)
%         [sFile, newEvents] = import_events(sFile, EventMat)
%         [sFile, newEvents] = import_events(sFile)  : Opens a dialog box to select the file

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
% Authors: Francois Tadel, 2010-2013

%% ===== PARSE INPUTS =====
% CALL:  import_events(sFile, EventMat)
if (nargin == 2) && isstruct(EventFile)
    newEvents = EventFile;
    EventFile = [];
    FileFormat = [];
% CALL:  import_events(sFile)
elseif (nargin < 3)
    EventFile = [];
    FileFormat = [];
    newEvents = [];
% CALL:  import_events(sFile, EventFile, FileFormat)
else
    newEvents = [];
end


%% ===== SELECT FILE =====
if isempty(EventFile) && isempty(newEvents)
    % Get raw path
    [fPath, fBase, fExt] = bst_fileparts(sFile.filename);
    % Get default directories and formats
    %defFileFormat = upper(sFile.format);
    % Get default directories and formats
    DefaultFormats = bst_get('DefaultFormats');
    % Get file
    [EventFile, FileFormat] = java_getfile( 'open', 'Import events...', ...    % Window title
        fPath, ...              % Default directory
        'single', 'files', ...  % Selection mode
        bst_get('FileFilters', 'events'), ...
        DefaultFormats.EventsIn);
    % If no file was selected: exit
    if isempty(EventFile)
        return
    end
    % Save default export format
    DefaultFormats.EventsIn = FileFormat;
    bst_set('DefaultFormats',  DefaultFormats);
end

%% ===== READ FILE =====
if isempty(newEvents)
    % Progress bar
    bst_progress('start', 'Import events', 'Loading file...');
    % Switch according to file format
    switch (FileFormat)
        case 'ANT'
            newEvents = in_events_ant(sFile, EventFile);
        case 'BRAINAMP'
            newEvents = in_events_brainamp(sFile, EventFile);
        case 'BST'
            FileMat = load(EventFile);
            % Convert structure to local structure
            newEvents = repmat(db_template('event'), 1, length(FileMat.events));
            for iEvt = 1:length(FileMat.events)
                for f = fieldnames(newEvents(1))'
                    newEvents(iEvt).(f{1}) = FileMat.events(iEvt).(f{1});
                end
            end
        case 'FIF'
            newEvents = in_events_fif(sFile, EventFile);
        case 'CTF'
            newEvents = in_events_ctf(sFile, EventFile);
        case 'CURRY'
            newEvents = in_events_curry(sFile, EventFile);
        case 'LENA'
            newEvents = in_events_lena(sFile, EventFile);
        case 'NEUROSCAN'
            newEvents = in_events_neuroscan(sFile, EventFile);
        case 'KIT'
            newEvents = in_events_kit(sFile, EventFile);
        case 'ARRAY-TIMES'
            newEvents = in_events_array(sFile, EventFile, 'times');
        case 'ARRAY-SAMPLES'
            newEvents = in_events_array(sFile, EventFile, 'samples');
        case 'CTFVIDEO'
            newEvents = in_events_video(sFile, EventFile);
        otherwise
            error('Unsupported file format.');
    end
    % Progress bar
    bst_progress('stop');
    % If no new events: return
    if isempty(newEvents)
        bst_error('No events found in this file.', 'Import events', 0);
        return
    end
end


%% ===== MERGE EVENTS LISTS =====
% Get events color table
ColorTable = panel_record('GetEventColorTable');
% Add each new event
for iNew = 1:length(newEvents)
    % Look for an existing event
    if ~isempty(sFile.events)
        iEvt = find(strcmpi(newEvents(iNew).label, {sFile.events.label}));
    else
        iEvt = [];
    end
    % Make sure that the sample indices are round values
    newEvents(iNew).samples = round(newEvents(iNew).samples);
    newEvents(iNew).times   = newEvents(iNew).samples ./ sFile.prop.sfreq;
    % If event does not exist yet: add it at the end of the list
    if isempty(iEvt)
        if isempty(sFile.events)
            iEvt = 1;
            sFile.events = newEvents(iNew);
        else
            iEvt = length(sFile.events) + 1;
            sFile.events(iEvt) = newEvents(iNew);
        end
    % Event exists: merge occurrences
    else
        % Merge events occurrences
        sFile.events(iEvt).times      = [sFile.events(iEvt).times, newEvents(iNew).times];
        sFile.events(iEvt).samples    = [sFile.events(iEvt).samples, newEvents(iNew).samples];
        sFile.events(iEvt).epochs     = [sFile.events(iEvt).epochs, newEvents(iNew).epochs];
        sFile.events(iEvt).reactTimes = [sFile.events(iEvt).reactTimes, newEvents(iNew).reactTimes];
        % Sort by sample indices
        if (size(sFile.events(iEvt).samples, 2) > 1)
            [tmp__, iSort] = unique(sFile.events(iEvt).samples(1,:));
            sFile.events(iEvt).samples = sFile.events(iEvt).samples(:,iSort);
            sFile.events(iEvt).times   = sFile.events(iEvt).times(:,iSort);
            sFile.events(iEvt).epochs  = sFile.events(iEvt).epochs(iSort);
            if ~isempty(sFile.events(iEvt).reactTimes)
                sFile.events(iEvt).reactTimes = sFile.events(iEvt).reactTimes(iSort);
            end
        end
    end
    % Add color if does not exist yet
    if isempty(sFile.events(iEvt).color)
        iColor = mod(iEvt-1, length(ColorTable)) + 1;
        sFile.events(iEvt).color = ColorTable(iColor,:);
    end
end

% %% ===== SORT EVENTS BY LABEL =====
% [tmp__, iSort] = sort({sFile.events.label});
% sFile.events = sFile.events(iSort);
    





