function fid = out_mri_nii( BstFile, OutputFile, typeMatlab, Nt )
% OUT_MRI_NII: Exports a MRI to a NIFTI-1 file (.NII or .HDR/.IMG)).
% 
% USAGE:        out_mri_nii( BstFile, OutputFile, typeMatlab)
%         fid = out_mri_nii(    sMri, OutputFile, typeMatlab, Nt=1 )
%
% INPUT: 
%    - BstFile    : full path to Brainstorm file to export
%    - sMri       : Brainstorm MRI structure
%    - OutputFile : full path to output file (with '.img' or '.nii' extension)
%    - typeMatlab : string, type of data to write in the file: uint8, int16, int32, float32, double
%    - Nt         : Number of time points to write in the file
%                   If specified, writes only the header of the file (time frames will be written from calling function)
%
% NOTE: store binary files in Little Endian only

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

% ===== PARSE INPUTS =====
% Write header of full file
if (nargin < 4) || isempty(Nt)
    Nt = 1;
    isHdrOnly = 0;
else
    isHdrOnly = 1;
end
if (nargin < 3) || isempty(typeMatlab)
    typeMatlab = [];
end
% Load file
if ischar(BstFile)
    sMri = in_mri_bst(BstFile);
else
    sMri = BstFile;
end
% Little Endian
byteOrder = 'l'; 
% Output file
[OutputPath, OutputBase, OutputExt] = bst_fileparts(OutputFile);

% ===== LOAD BRAINSTORM MRI =====
% Get maximum
MaxVal = max(abs(sMri.Cube(:)));
% Check value range
if isempty(typeMatlab)
    if (MaxVal <= 255)
        typeMatlab   = 'uint8';
    elseif all(MaxVal < 32767)
        typeMatlab   = 'int16';
    elseif all(MaxVal < 2147483647)
        typeMatlab   = 'int32';
    else
        typeMatlab   = 'float32';
    end
end
switch (typeMatlab)
    case 'uint8'
        hdr.datatype = 2;
        hdr.bitpix   = 8;
        sMri.Cube  = uint8(sMri.Cube);
    case 'int16'
        hdr.datatype = 4;
        hdr.bitpix   = 16;
        sMri.Cube  = int16(sMri.Cube);
    case 'int32'
        hdr.datatype = 8;
        hdr.bitpix   = 32;
        sMri.Cube  = int32(sMri.Cube);
    case 'float32'
        hdr.datatype = 16;
        hdr.bitpix   = 32;
        sMri.Cube  = single(sMri.Cube);
    case 'double'
        hdr.datatype = 32;
        hdr.bitpix   = 64;
        sMri.Cube  = double(sMri.Cube);
end
% Size of the volume
volDim = size(sMri.Cube);
pixDim = sMri.Voxsize;
% Set up other field values
hdr.dim    = [4 volDim Nt 0 0 0];
hdr.pixdim = [1 pixDim 1  0 0 0];
hdr.glmax  = MaxVal;
% Default origin of the volume: AC, if not middle of the volume
if isfield(sMri, 'NCS') && isfield(sMri.NCS, 'AC') && ~isempty(sMri.NCS.AC) 
    Origin = sMri.NCS.AC;
else
    Origin = volDim / 2;
end
% sform matrix
srow_x = [pixDim(1), 0, 0, -Origin(1)];
srow_y = [0, pixDim(2), 0, -Origin(2)];
srow_z = [0, 0, pixDim(3), -Origin(3)];  


%% ===== SAVE ANALYZE HEADER (.NII or .HDR) =====
% Header file
switch(lower(OutputExt))
    case {'.hdr', '.img'}
        HeaderFile = bst_fullfile(OutputPath, [OutputBase '.hdr']);
        DataFile   = bst_fullfile(OutputPath, [OutputBase '.img']);
        isNifti = 0;
        hdr.vox_offset = 0;
    case '.nii'
        HeaderFile = bst_fullfile(OutputPath, [OutputBase '.nii']);
        DataFile   = [];
        isNifti = 1;
        hdr.vox_offset = 352;
    otherwise
        error(['Invalid format: "' OutputExt '"']);
end
% Open file for binary writing
[fid, message] = fopen(HeaderFile, 'wb', byteOrder);
if (fid == -1)
   error('Error opening header file \n%s', message);
end


% ===== SECTION 'header_key' =====
z = @(n)zeros(1,n);
fwrite(fid, 348,     'uint32');   % sizeof_hdr
fwrite(fid, z(10),   'uchar');    % data_type
fwrite(fid, z(18),   'uchar');    % db_name
fwrite(fid, 0,       'uint32');   % extents
fwrite(fid, 0,       'uint16');   % session_error
fwrite(fid, 'r',     'uchar');    % regular
if isNifti
    fwrite(fid, 32,  'uchar');    % dim_info
else
    fwrite(fid, 0, 'uchar');      % hkey_un0
end


% ===== SECTION 'image_dimension' =====
fwrite(fid, hdr.dim, 'uint16');     % dim
if isNifti
    fwrite(fid, [0 0 0], 'float32');% intent_p1, intent_p2, intent_p3
    fwrite(fid, 0,       'uint16'); % intent_code
else
    fwrite(fid, 'mm  ', 'uchar');   % vox_units
    fwrite(fid, z(8),   'uchar');   % cal_units
    fwrite(fid, 0,      'uint16');  % unused1
end
fwrite(fid, hdr.datatype, 'uint16');% datatype
fwrite(fid, hdr.bitpix, 'uint16');  % bitpix
if isNifti 
    fwrite(fid, 0, 'uint16');       % slice_start
else
    fwrite(fid, 0, 'uint16');       % dim_un0
end
fwrite(fid, hdr.pixdim,     'float32'); % pixdim
fwrite(fid, hdr.vox_offset, 'float32'); % vox_offset
if isNifti
    fwrite(fid, 0,  'float32');     % scl_slope
    fwrite(fid, 0,  'float32');     % scl_inter
    fwrite(fid, 0,  'uint16');      % slice_end
    fwrite(fid, 0,  'uchar');       % slice_code
    fwrite(fid, 18, 'uchar');       % xyzt_units
else
    fwrite(fid, 1, 'float32');      % funused1
    fwrite(fid, 0, 'float32');      % funused2  
    fwrite(fid, 0, 'float32');      % funused3
end
fwrite(fid, 0,         'float32');  % cal_max
fwrite(fid, 0,         'float32');  % cal_min
fwrite(fid, 0,         'float32');  % compressed
fwrite(fid, 0,         'uint32');   % verified
fwrite(fid, hdr.glmax, 'uint32');   % glmax
fwrite(fid, 0,         'uint32');


% ===== SECTION 'data_history' =====
desc = z(80);
desc(1:23) = 'Written with Brainstorm';
fwrite(fid, desc,  'uchar');         % descrip
fwrite(fid, z(24), 'uchar');         % aux_file
if isNifti 
    fwrite(fid, 0,     'uint16');    % qform_code
    fwrite(fid, 2,     'uint16');    % sform_code: NIFTI_XFORM_ALIGNED_ANAT
    fwrite(fid, z(6),  'float');     % quatern_b, quatern_c, quatern_d, qoffset_x, qoffset_y, qoffset_z
    fwrite(fid, srow_x,  'float');   % sform
    fwrite(fid, srow_y,  'float');   % sform
    fwrite(fid, srow_z,  'float');   % sform
    fwrite(fid, z(16), 'uchar');     % intent_name
    fwrite(fid, ['n+1' 0], 'uchar'); % magic
    fwrite(fid, z(4),      'uchar'); % end...
else    
    fwrite(fid, 0, 'uchar');         % orient
    fwrite(fid, z(5), 'int16');      % originator
    fwrite(fid, z(10), 'uchar');     % generated
    fwrite(fid, z(10), 'uchar');     % scannum
    fwrite(fid, z(10), 'uchar');     % patient_id
    fwrite(fid, z(10), 'uchar');     % exp_date
    fwrite(fid, z(10), 'uchar');     % exp_time
    fwrite(fid, z(3), 'uchar');      % hist_un0
    fwrite(fid, 0, 'uint32');        % views
    fwrite(fid, 0, 'uint32');        % vols_added
    fwrite(fid, 0, 'uint32');        % start_field
    fwrite(fid, 0, 'uint32');        % field_skip
    fwrite(fid, 0, 'uint32');        % omax
    fwrite(fid, 0, 'uint32');        % omin
    fwrite(fid, 0, 'uint32');        % smax
    fwrite(fid, 0, 'uint32');        % smin
end
      

%% ===== SAVE ANALYZE VOLUME (.IMG) =====
if ~isempty(DataFile)
    % Close header file and open image file
    fclose(fid);
    [fid, message] = fopen(DataFile, 'wb', byteOrder);
    if fid == -1
        error('Error opening image file: "%s".', message);
    end
else
    % Continue with the same 
    % Pad with zeros to reach minimum header size
    npad = hdr.vox_offset - ftell(fid);
    fwrite(fid, z(npad), 'uchar');
end

% Dimensions
% Nx = hdr.dim(2);    % Number of pixels in X
% Ny = hdr.dim(3);    % Number of pixels in Y
Nz = hdr.dim(4);      % Number of Z slices
% Nt = hdr.dim(5);    % Number of time frames

% Write image file
if ~isHdrOnly
    %Nxy = Nx*Ny;
    % for t = 1:Nt
       for z = 1:Nz
          count = fwrite(fid, sMri.Cube(:,:,z), typeMatlab);
    %       if (count ~= Nxy)
    %           fclose(fid);
    %           error('Error writing file'); 
    %       end
       end
    % end
    fclose(fid);
end

end

