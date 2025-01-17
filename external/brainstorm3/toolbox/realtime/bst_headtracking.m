function bst_headtracking(varargin)
% BST_HEADTRACKING: Displays a subject's head position in realtime; used
% for quality control before recording MEG.
%
% USAGE:    bst_headtracking()              Defaults: hostIP='172.16.50.6' and TCPIP=1972
%           bst_headtracking(hostIP, TCPIP)
%
% Inputs:   hostIP  = IP address of host computer
%           TCPIP   = TCP/IP port of host computer
%
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
% Authors: Elizabeth Bock & Francois Tadel, 2012-2013

%% ===== DEFAULT INPUTS ====

if isempty(varargin)
    hostIP  = '172.16.50.6';    % IP address of host computer
    TCPIP   = 1972;             % TPC/IP port of host computer
    PosFile = [];
else
    hostIP  = varargin{1};
    TCPIP   = varargin{2};
    PosFile = varargin{3};
end

%% ===== CONFIGURATION ====
% User Directory
user_dir = bst_get('UserDir');

% Database
ProtocolName  =         'HeadTracking';
SubjectName   =         'HeadMaster';
ConditionHeadPoints =   'HeadPoints'; % Used to warp the head surface
ConditionChan =         'SensorPositions'; % Used to update sensor locations in real-time
% Brainstorm
bst_dir =       bst_get('BrainstormHomeDir');
bst_db_dir =    bst_get('BrainstormDbDir');
tmp_dir =       bst_get('BrainstormTmpDir');

% FieldTrip
% find the fieldtrip directory
d = dir(bst_fullfile(fileparts(bst_dir),'fieldtrip*'));
if isempty(d)
    % ask the user for the fieldtrip directory
    ft_dir = java_getfile( 'open', 'Select FieldTrip Directory...', user_dir, 'single', 'dirs', ...
            {{'*'}, 'FieldTrip directory', 'directory'}, 0);
    if isempty(ft_dir)
        error('Cannot find the FieldTrip Directory');
    end
else
    ft_dir = bst_fullfile(fileparts(bst_dir),d.name);
end

ft_rtbuffer = bst_fullfile(ft_dir, 'realtime', 'buffer', 'matlab');
ft_io = bst_fullfile(ft_dir, 'fileio');

if exist(ft_rtbuffer, 'dir') && exist(ft_io, 'dir')
    addpath(ft_rtbuffer);
    addpath(ft_io);
else
    error('Cannot find the FieldTrip buffer and/or io directories');
end

% % Warp
isWarp = 1;

%% ===== PREPARE DATABASE =====
% Get protocol
iProtocol = bst_get('Protocol', ProtocolName);
% Create if protocol doesn't exist yet
if isempty(iProtocol)
    % Define a new protocol
    sProtocol = db_template('ProtocolInfo');
    sProtocol.Comment           = ProtocolName;
    sProtocol.SUBJECTS          = bst_fullfile(bst_db_dir, ProtocolName, 'anat');
    sProtocol.STUDIES           = bst_fullfile(bst_db_dir, ProtocolName, 'data');
    sProtocol.UseDefaultAnat    = 1;
    sProtocol.UseDefaultChannel = 0;
    % Create protocol
    iProtocol = db_edit_protocol('create', sProtocol);
    % Set as current protocol
    gui_brainstorm('SetCurrentProtocol', iProtocol);
    % Set default anatomy
    sColin = bst_get('AnatomyDefaults', 'Colin27');
    db_set_template(0, sColin, 0);
else
    % Set as current protocol
    gui_brainstorm('SetCurrentProtocol', iProtocol);
end

%% ===== PREPARE SUBJECT =====
% Get subject
[sSubject, iSubject] = bst_get('Subject', SubjectName);
% If warping: we need to recreate the subject
if isWarp
    % Create if subject doesnt exist
    if isempty(iSubject)
        [sSubject, iSubject] = db_add_subject(SubjectName, [], 1, 0);
    end
    % Update subject structure
    sSubject = bst_get('Subject', iSubject);
    
    % Delete all the tess and anatomy files in the subject that are not
    % default
    for ii = 1:length(sSubject.Anatomy)
        if isempty(strfind(sSubject.Anatomy(ii).FileName, bst_get('DirDefaultSubject')))
            file_delete(file_fullpath(sSubject.Anatomy(ii).FileName), 1);
        end
    end
    for ii = 1:length(sSubject.Surface)
        if isempty(strfind(sSubject.Surface(ii).FileName, bst_get('DirDefaultSubject')))
            file_delete(file_fullpath(sSubject.Surface(ii).FileName), 1);
        end
    end
    % Reload subject
    db_reload_subjects(iSubject);
    % Update subject structure
    sSubject = bst_get('Subject', iSubject);
end
   
%% ===== PREPARE CONDITION: HEADPOINTS =====
% Get condition
[sStudy, iStudy] = bst_get('StudyWithCondition', [SubjectName '/' ConditionHeadPoints]);
% If warping: we need a channel file in HeadPoints, this will be populated
% with the head points measured and saved in a .pos file
if isWarp
    % Create if condition doesnt exist
    if isempty(sStudy)
        iStudy = db_add_condition(SubjectName, ConditionHeadPoints);
        sStudy = bst_get('Study', iStudy);
    end
    
    % Copy default channel file to this condition
    DefChannelFile = bst_fullfile(bst_dir, 'defaults', 'meg', 'channel_ctf_default.mat');
    copyfile(DefChannelFile, bst_fileparts(file_fullpath(sStudy.FileName)));
    % Reload condition
    db_reload_studies(iStudy);

    % Get updated study definition
    sStudy = bst_get('Study', iStudy);
end
 
%% ===== WARP =====
% Update the channel file with the head points
if isempty(PosFile)
    LastUsedDirs = bst_get('LastUsedDirs');
    PosFile = java_getfile( 'open', 'Select POS file...', LastUsedDirs.ImportChannel, 'single', 'files', ...
        {{'*.pos'}, 'POS files', 'POLHEMUS'}, 0);
    if isempty(PosFile)
        return;
    end
end
% Read POS file and channel file
HeadMat = in_channel_pos(PosFile);
ChannelFile = file_fullpath(sStudy.Channel.FileName);
ChannelMat = in_bst_channel(ChannelFile);

% Copy head points
ChannelMat.HeadPoints = HeadMat.HeadPoints;
% Force re-alignment on the new set of NAS/LPA/RPA (switch from CTF coil-based to SCS anatomical-based coordinate system)
ChannelMat = channel_detect_type(ChannelMat, 1, 0);
save(ChannelFile, '-struct', 'ChannelMat');
% Get the transformation for HPI head coordinates (POS file) to Brainstorm
iTrans = find(~cellfun(@isempty,strfind(ChannelMat.TransfMegLabels, 'Native=>Brainstorm/CTF')));
if isempty(iTrans)
    bst_error('No SCS transformation in the channel file')
    return;
end

%ChannelMat.TransfMeg{end+1} = [ChannelMat.SCS.R, ChannelMat.SCS.T; 0 0 0 1];
trans = ChannelMat.TransfMeg{iTrans};
R = trans(1:3, 1:3);
T = trans(1:3, 4);

% Warp surface for new head points
% bst_warp_prepare(ChannelFile, Options)
%    Options     : Structure of the options
%         |- tolerance    : Percentage of outliers head points, ignored in the calulation of the deformation. 
%         |                 Set to more than 0 when you know your head points have some outliers.
%         |                 If not specified: asked to the user (default 
%         |- isInterp     : If 0, do not do a full interpolation (default: 1)
%         |- isScaleOnly  : If 1, do not perform the full deformation but only a linear scaling in the three directions (default: 0)
%         |- isSurfaceOnly: If 1, do not warp/scale the MRI (default: 0)
%         |- isInteractive: If 0, do not ask anything to the user (default: 1)
Options.tolerance = 0.02;
Options.isInterp = [];
Options.isScaleOnly = 0;
Options.isSurfaceOnly = 1;
Options.isInteractive = 1;
hFig = bst_warp_prepare(ChannelFile, Options);

% Close figure
close(hFig);
% Update subject structure
sSubject = bst_get('Subject', iSubject);


%% ===== PREPARE CONDITION: CHANNEL POSITIONS =====
% Get condition
[sStudyChan, iStudyChan] = bst_get('StudyWithCondition', [SubjectName '/' ConditionChan]);
% Create if condition doesnt exist, this will be populated with sensor
% positions measured from real-time res4 file
if isempty(sStudyChan)
    iStudyChan = db_add_condition(SubjectName, ConditionChan);
    sStudyChan = bst_get('Study', iStudyChan);
end

%% ===== INITIALIZE FIELDTRIP BUFFER =====
% find and kill any old matlab processes
pid = feature('getpid');
[tmp,tasks] = system('tasklist');
pat = '\s+';
str=tasks;
s = regexp(str, pat, 'split'); 
iMatlab = find(~cellfun(@isempty, strfind(s, 'MATLAB.exe')));

if iMatlab > 1
    % kill the extra matlab(s)
    disp('An old MATLAB process is still running, stopping now...');
    temp = str2double(s(iMatlab+1));
    iKill = find(temp ~= pid);
    for ii=1:length(iKill)
        [status,result] = system(['Taskkill /PID ' num2str(temp(iKill(ii))) ' /F']);
        if status
            disp(result);
            disp('The process could not be stopped.  Please stop it manually');
        else
            disp(result);
        end
    end
end
    
% Initialize the buffer
try
    disp('BST> Initializing FieldTrip buffer...');
    buffer('tcpserver', 'init', hostIP, TCPIP);
catch
    disp('BST> Warning: FieldTrip buffer is already initialized.');
    buffer('flush_hdr', [], hostIP, TCPIP);
end
% Waiting for acquisition to start
disp('BST> Waiting for acquisition to start...');
while (1)
    try
        numbers = buffer('wait_dat', [1 -1 1000], hostIP, TCPIP);        
        disp('BST> Acquisition started.');
        break;
    catch
        pause(1);
    end
end

%% ===== READING RES4 INFO =====
% Reading header
hdr = buffer('get_hdr', [], hostIP, TCPIP);

% Write .res4 file
res4_file = bst_fullfile(tmp_dir, 'temp.res4');
fid = fopen(res4_file, 'w', 'l');
fwrite(fid, hdr.ctf_res4, 'uint8');
fclose(fid);
% Write empty .meg4
meg4_file = bst_fullfile(tmp_dir, 'temp.meg4');
fid = fopen(meg4_file, 'w', 'l');
fclose(fid);
% Reading structured res4
SensorPositionMat = in_channel_ctf(res4_file);
% Add channel file to the SensorPositions study
SensorPositionFile = db_set_channel(iStudyChan, SensorPositionMat, 2, 2);

%% ===== HEAD TRACKING =====
% Display subject's head
hFig = view_surface(sSubject.Surface(sSubject.iScalp).FileName);
% Set view from the left
figure_3d('SetStandardView', hFig, 'front');
% Display CTF helmet
view_helmet(SensorPositionFile, hFig);
% Get the helmet patch
hHelmetPatch = findobj(hFig, 'Tag', 'HelmetPatch'); 
% Get XYZ coordinates of the helmet patch object
InitVertices = get(hHelmetPatch, 'Vertices');

% Loop to update positions
while (1)
    % Number of samples to read
    nSamples = 300;
    % Read the last nSamples fiducial positions
    hdr = buffer('get_hdr', [], hostIP, TCPIP);
    currentSample = hdr.nsamples;
    if currentSample < nSamples-1
        continue;
    end
    dat = buffer('get_dat', [currentSample-nSamples-1,currentSample-1], hostIP, TCPIP);
    % Average in time
    buf = mean(double(dat.buf), 2);
    Fid = [buf(1:3), buf(4:6), buf(7:9)] ./ 1000;
    % Get fiducial positions
    sMri.SCS.NAS = Fid(:,1)';
    sMri.SCS.LPA = Fid(:,2)';
    sMri.SCS.RPA = Fid(:,3)';
    % Apply transformation to helmet vertices
    Vertices = cs_mri2scs(sMri, InitVertices' .* 1000)' ./ 1000;
    % Convert HPI coordinates to Brainstorm coordinates (based on cardinal points)
    Vertices = bst_bsxfun(@plus, R * Vertices', T)';
    % Stop if the window was closed
    if ~ishandle(hHelmetPatch)
        break;
    end
    % Update helmet patch
    set(hHelmetPatch, 'Vertices', Vertices);
    % Wait
    pause(.2);
end
