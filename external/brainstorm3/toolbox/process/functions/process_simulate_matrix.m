function varargout = process_simulate_matrix( varargin )
% PROCESS_SIMULATE_MATRIX: Simulate source signals and saves them as a matrix file.
%
% USAGE:   OutputFiles = process_simulate_sources('Run', sProcess,
% sInputA)% !!!!!!!!!!!!!!!
%               signal = process_simulate_sources('Compute', fnesting,
%               fnested, duration, sRate, couplingPhase, DutyCycle) % !!!!!!!!!!!!!!!
 
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
% Authors: Guiomar Niso, Francois Tadel, 2013

macro_methodcall;
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Simulate generic signals';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Simulate'; 
    sProcess.Index       = 901; 
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'import'};
    sProcess.OutputTypes = {'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 0;

    % === SUBJECT NAME
    sProcess.options.subjectname.Comment = 'Subject name:';
    sProcess.options.subjectname.Type    = 'subjectname';
    sProcess.options.subjectname.Value   = 'NewSubject';
    % === CONDITION NAME
    sProcess.options.condition.Comment = 'Condition name:';
    sProcess.options.condition.Type    = 'text';
    sProcess.options.condition.Value   = '';
    % === NUMBER OF SAMPLES
    sProcess.options.samples.Comment = 'Number of time samples:';
    sProcess.options.samples.Type    = 'value';
    sProcess.options.samples.Value   = {10000, ' (Ntime)', 0};
    % === SAMPLING FREQUENCY
    sProcess.options.srate.Comment = 'Signal sampling frequency:';
    sProcess.options.srate.Type    = 'value';
    sProcess.options.srate.Value   = {1000, 'Hz', 2};
    % === MATLAB COMMAND
    sProcess.options.matlab.Comment = ['<HTML><BR>Input variables:<BR>' ...
                                       '&nbsp;&nbsp;&nbsp;&nbsp; <B>t</B> : time vector in seconds [1 x Ntime]<BR>' ...
                                       'Output variables:<BR>' ...
                                       '&nbsp;&nbsp;&nbsp;&nbsp; <B>Data</B> : simulated signals [Nsignals x Ntime]<BR>'];
    sProcess.options.matlab.Type    = 'textarea';
    sProcess.options.matlab.Value   = ['Data(1,:) = sin(2*pi*t);' 10 ...
                                       'Data(2,:) = cos(pi*t) + 1;'];
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputA) %#ok<DEFNU>
    OutputFiles = {};
    % ===== GET OPTIONS =====
    % Get subject name
    SubjectName = file_standardize(sProcess.options.subjectname.Value);
    if isempty(SubjectName)
        bst_report('Error', sProcess, sInputs, 'Subject name is empty.');
        return
    end
    % Get condition name
    Condition = file_standardize(sProcess.options.condition.Value);
    % Get signal options
    nsamples = sProcess.options.samples.Value{1};
    srate    = sProcess.options.srate.Value{1};
    
    % ===== GENERATE SIGNALS =====
    % Set input variable for the script
    t = (0:nsamples-1) ./ srate;
    Data = [];
    % Evaluate Matlab code
    try
        eval(sProcess.options.matlab.Value);
    catch
        e = lasterr();
        bst_report('Error', sProcess, [], e);
        return;
    end
    % Check signals dimensions
    if isempty(Data)
        bst_report('Error', sProcess, [], 'The process did not generate any signals.');
        return;
    elseif (size(Data,2) ~= length(t))
        bst_report('Error', sProcess, [], sprintf('The generated signals does not have %d time samples.', nsamples));
        return;
    end
    
    % ===== GENERATE FILE STRUCTURE =====
    % Create empty matrix file structure
    FileMat = db_template('matrixmat');
    FileMat.Value       = Data;
    FileMat.Time        = t;
    FileMat.Comment     = sprintf('Simulated signals (%dx%d)', size(Data,1), nsamples);
    FileMat.Description = cell(size(Data,1),1);
    for i = 1:size(Data,1)
        FileMat.Description{i} = ['s', num2str(i)];
    end
    % Add history entry
    FileMat = bst_history('add', FileMat, 'process', ['Simulation: ' strrep(sProcess.options.matlab.Value, char(10), ' ')]);
    
    % ===== OUTPUT CONDITION =====
    % Get subject
    [sSubject, iSubject] = bst_get('Subject', SubjectName);
    % Create subject if it does not exist yet
    if isempty(sSubject)
        [sSubject, iSubject] = db_add_subject(SubjectName);
    end
    % Default condition name
    if isempty(Condition)
        Condition = 'Simulation';
    end
    % Get condition asked by user
    [sStudy, iStudy] = bst_get('StudyWithCondition', bst_fullfile(SubjectName, Condition));
    % Condition does not exist: create it
    if isempty(sStudy)
        iStudy = db_add_condition(SubjectName, Condition, 1);
        sStudy = bst_get('Study', iStudy);
    end
    
    % ===== SAVE FILE =====
    % Output filename
    OutputFiles{1} = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), 'matrix_sim_');
    % Save file
    bst_save(OutputFiles{1}, FileMat, 'v6');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, FileMat);
end




