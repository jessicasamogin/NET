function x = spm_coreg_freeze_v03(varargin)
% Between modality coregistration using information theory
% FORMAT x = spm_coreg(VG,VF,params)
% VG - handle for first image (see spm_vol).
% VF - handle for second image.
% x - the parameters describing the rigid body rotation.
%     such that a mapping from voxels in G to voxels in F
%     is attained by:  VF.mat\spm_matrix_mod(x(:)')*VG.mat
% flags - a structure containing the following elements:
%          sep      - optimisation sampling steps (mm)
%                     default: [4 2]
%          params   - starting estimates (6 elements)
%                     default: [0 0 0  0 0 0]
%          cost_fun - cost function string:
%                      'mi'  - Mutual Information
%                      'nmi' - Normalised Mutual Information
%                      'ecc' - Entropy Correlation Coefficient
%                      'ncc' - Normalised Cross Correlation
%                      default: 'nmi'
%          tol      - tolerences for accuracy of each param
%                     default: [0.02 0.02 0.02 0.001 0.001 0.001]
%          fwhm     - smoothing to apply to 256x256 joint histogram
%                     default: [7 7]
%
% The registration method used here is based on the work described in:
% A Collignon, F Maes, D Delaere, D Vandermeulen, P Suetens & G Marchal
% (1995) "Automated Multi-modality Image Registration Based On
% Information Theory". In the proceedings of Information Processing in
% Medical Imaging (1995).  Y. Bizais et al. (eds.).  Kluwer Academic
% Publishers.
%
% The original interpolation method described in this paper has been
% changed in order to give a smoother cost function.  The images are
% also smoothed slightly, as is the histogram.  This is all in order to
% make the cost function as smooth as possible, to give faster
% convergence and less chance of local minima.
%
% References
% ==========
% Mutual Information
% ------------------
% Collignon, Maes, Delaere, Vandermeulen, Suetens & Marchal (1995).
% "Automated multi-modality image registration based on information theory".
% In Bizais, Barillot & Di Paola, editors, Proc. Information Processing
% in Medical Imaging, pages 263--274, Dordrecht, The Netherlands, 1995.
% Kluwer Academic Publishers.
%
% Wells III, Viola, Atsumi, Nakajima & Kikinis (1996).
% "Multi-modal volume registration by maximisation of mutual information".
% Medical Image Analysis, 1(1):35-51, 1996. 
%
% Entropy Correlation Coefficient
% -------------------------------
% F Maes, A Collignon, D Vandermeulen, G Marchal & P Suetens (1997).
% "Multimodality image registration by maximisation of mutual
% information". IEEE Transactions on Medical Imaging 16(2):187-198
%
% Normalised Mutual Information
% -----------------------------
% Studholme,  Hill & Hawkes (1998).
% "A normalized entropy measure of 3-D medical image alignment".
% in Proc. Medical Imaging 1998, vol. 3338, San Diego, CA, pp. 132-143.             
%
% Optimisation
% ------------
% Press, Teukolsky, Vetterling & Flannery (1992).
% "Numerical Recipes in C (Second Edition)".
% Published by Cambridge.
%
% At the end, the voxel-to-voxel affine transformation matrix is
% displayed, along with the histograms for the images in the original
% orientations, and the final orientations.  The registered images are
% displayed at the bottom.
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% John Ashburner
% $Id: spm_coreg.m 1143 2008-02-07 19:33:33Z spm $
%------------------------------------------------------------------------
% Modified Siawoosh Mohammadi 15/03/2011


global IN_freeze

if nargin>=4,
    x = optfun(varargin{:});
    return;
end;

% def_flags = struct('sep',[4 1],'params',[0 0 0  0 0 0  1 1 1 0 0 0], 'cost_fun','nmi','fwhm',[7 7],...
%     'tol',[0.001 0.02 0.02 0.001 0.001 0.001 0.001 0.001 0.001 0.0005 0.0005 0.0005],'graphics',1);

% FIL
% def_flags = struct('sep',[4 2],'params',[0 0 0  0 0 0  1 1 1  0 0 0 zeros(1,length(IN_freeze)-12)], ...
%     'cost_fun','nmi','fwhm',[7 5],...
% 	'tol',[0.01 0.02 0.02  0.001 0.001 0.001  0.01 0.01 0.01  0.01 0.01 0.01 0.001*ones(1,length(IN_freeze)-12)], ...
%     'graphics',1);

% sensitive
def_flags = struct('sep',[4 2],'params',[0 0 0  0 0 0  1 1 1  0 0 0 zeros(1,length(IN_freeze)-12)], ...
    'cost_fun','nmi','fwhm',[7 5],...
	'tol',[0.001 0.02 0.02  0.001 0.001 0.001  0.0005 0.001 0.001  0.0005 0.001 0.001 0.001*ones(1,length(IN_freeze)-12)], ...
    'graphics',1);

if nargin < 3,
    flags = def_flags;
else
    flags = varargin{3};
    fnms  = fieldnames(def_flags);
    for i=1:length(fnms),
        if ~isfield(flags,fnms{i}), flags.(fnms{i}) = def_flags.(fnms{i}); end;
    end;
end;

if nargin < 1,
    VG = spm_vol(spm_select(1,'image','Select reference image'));
else
    VG = varargin{1};
    if ischar(VG), VG = spm_vol(VG); end;
end;
if nargin < 2,
    VF = spm_vol(spm_select(Inf,'image','Select moved image(s)'));
else
    VF = varargin{2};
    if ischar(VF) || iscellstr(VF), VF = spm_vol(strvcat(VF)); end;
end;

if ~isfield(VG, 'uint8'),
    VG.uint8 = loaduint8_SM1(VG);
    vxg      = sqrt(sum(VG.mat(1:3,1:3).^2));
    fwhmg    = sqrt(max([1 1 1]*flags.sep(end)^2 - vxg.^2, [0 0 0]))./vxg;
    VG       = smooth_uint8(VG,fwhmg); % Note side effects
end;

sc = flags.tol(:)'; % Required accuracy
sc = sc(1:length(flags.params));
xi = diag(sc*20);
ind = 0;

for k=1:numel(VF),
    VFk = VF(k);
    if(~isempty(find(spm_read_vols(VFk))>0))
        if ~isfield(VFk, 'uint8'),
            VFk.uint8 = loaduint8_SM1(VFk);
            vxf       = sqrt(sum(VFk.mat(1:3,1:3).^2));
            fwhmf     = sqrt(max([1 1 1]*flags.sep(end)^2 - vxf.^2, [0 0 0]))./vxf;
            VFk       = smooth_uint8(VFk,fwhmf); % Note side effects
        end;
%         movie_2images(VG.uint8,VFk.uint8,[0 200],[0 200],0.2)

        xk  = flags.params(:);
        for samp=flags.sep(:)',
            xk     = spm_powell_VARTARG(xk(:), xi,sc,mfilename,flags.freeze,VG,VFk,samp,flags.cost_fun,flags.fwhm);
            x(k,:) = xk(:)';              
            % ------- NEW CODE -------------
            % extend the parameter vectors to original size

            % TODO  
            % number of parameters before cutting out brain slices

            ind = ind + 1;
            [Spth, Sfname] = fileparts (VFk.fname);

%             if(ind==2)
%                 save ([Spth filesep 'mut_p' num2str(ind) '_'  Sfname '.mat'], 'xk');
%             end
             % ------------------------------

        end;

    %    if flags.graphics,
    %        display_results(VG(1),VFk(1),xk(:)',flags);
    %    end;
%     else
%         xk  = flags.params(:);
%         x(k,:) = xk(:)'; 
%         [Spth, Sfname] = fileparts (VFk.fname);
%         ind = 2;
%         save ([Spth filesep 'mut_p' num2str(ind) '_'  Sfname '.mat'], 'xk');
    end
end;
return;
%_______________________________________________________________________

%_______________________________________________________________________
function o = optfun(x,VG,VF,s,cf,fwhm)

global P VFmat VGmat VGdim phase_encoding;

% The function that is minimised.
if nargin<6, fwhm = [7 7];   end;
if nargin<5, cf   = 'mi';    end;
if nargin<4, s    = [1 1 1]; end;

% % Voxel sizes
% % s       = [s s 1];
% vxg = sqrt(sum(VG.mat(1:3,1:3).^2));sg = s./vxg;
% % sg = floor(sg);
% %mod
% % sg = s;

% copy and paste from previous
% Voxel sizes
s       = [s s 1];
% vxg = sqrt(sum(VG.mat(1:3,1:3).^2));sg = s./vxg;
%mod
sg = s;

% Create the joint histogram
P = x;

% SM mod
switch phase_encoding
    case 1 
        sg=permute(sg,[2 1 3]);    
        VFmat = VF.mat([2 1 3 4],:);
        VGmat = VG.mat([2 1 3 4],:); % (:,[2 1 3 4])
        VGdim = VG.dim([2 1 3]);
%         x = x([2 1 3 5 4 6 8 7 9 10 11 12]);
    case 2        
        VFmat = VF.mat;
        VGmat = VG.mat;
        VGdim = VG.dim;
    case 3
        sg=permute(sg,[1 3 2]);
        VFmat = VF.mat([1 3 2 4],:);
        VGmat = VG.mat([1 3 2 4],:);
        VGdim = VG.dim([1 3 2]);
%         x = x([1 3 1 4 6 5 7 9 8 10 11 12]);
end
% VF.uint8 = VF.uint8(:,:,2:end);
% VG.uint8 = VG.uint8(:,:,2:end);


% Create the joint histogram

H = spm_hist2(VG.uint8,VF.uint8, VFmat\spm_matrix_mod(x(:)')*VGmat ,sg);
% H = spm_hist2_z_exp_polyval2(VG.uint8,VF.uint8, zeros(4) ,sg);

% Smooth the histogram
lim  = ceil(2*fwhm);
krn1 = smoothing_kernel(fwhm(1),-lim(1):lim(1)) ; krn1 = krn1/sum(krn1); H = conv2(H,krn1);
krn2 = smoothing_kernel(fwhm(2),-lim(2):lim(2))'; krn2 = krn2/sum(krn2); H = conv2(H,krn2);

% Compute cost function from histogram
H  = H+eps;
sh = sum(H(:));
H  = H/sh;
s1 = sum(H,1);
s2 = sum(H,2);

switch lower(cf)
    case 'mi',
        % Mutual Information:
        H   = H.*log2(H./(s2*s1));
        mi  = sum(H(:));
        o   = -mi;
    case 'ecc',
        % Entropy Correlation Coefficient of:
        % Maes, Collignon, Vandermeulen, Marchal & Suetens (1997).
        % "Multimodality image registration by maximisation of mutual
        % information". IEEE Transactions on Medical Imaging 16(2):187-198
        H   = H.*log2(H./(s2*s1));
        mi  = sum(H(:));
        ecc = -2*mi/(sum(s1.*log2(s1))+sum(s2.*log2(s2)));
        o   = -ecc;
    case 'nmi',
        % Normalised Mutual Information of:
        % Studholme,  Hill & Hawkes (1998).
        % "A normalized entropy measure of 3-D medical image alignment".
        % in Proc. Medical Imaging 1998, vol. 3338, San Diego, CA, pp. 132-143.
        nmi = (sum(s1.*log2(s1))+sum(s2.*log2(s2)))/sum(sum(H.*log2(H)));
        o   = -nmi;
    case 'ncc',
        % Normalised Cross Correlation
        i     = 1:size(H,1);
        j     = 1:size(H,2);
        m1    = sum(s2.*i');
        m2    = sum(s1.*j);
        sig1  = sqrt(sum(s2.*(i'-m1).^2));
        sig2  = sqrt(sum(s1.*(j -m2).^2));
        [i,j] = ndgrid(i-m1,j-m2);
        ncc   = sum(sum(H.*i.*j))/(sig1*sig2);
        o     = -ncc;
    otherwise,
        error('Invalid cost function specified');
end;

return;
%_______________________________________________________________________

%_______________________________________________________________________
function udat = loaduint8(V)
% Load data from file indicated by V into an array of unsigned bytes.
if size(V.pinfo,2)==1 && V.pinfo(1) == 2,
    mx = 255*V.pinfo(1) + V.pinfo(2);
    mn = V.pinfo(2);
else
    spm_progress_bar('Init',V.dim(3),...
        ['Computing max/min of ' spm_str_manip(V.fname,'t')],...
        'Planes complete');
    mx = -Inf; mn =  Inf;
    for p=1:V.dim(3),
        img = spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1);
        mx  = max([max(img(:))+paccuracy(V,p) mx]);
        mn  = min([min(img(:)) mn]);
        spm_progress_bar('Set',p);
    end;
end;

% Another pass to find a maximum that allows a few hot-spots in the data.
spm_progress_bar('Init',V.dim(3),...
        ['2nd pass max/min of ' spm_str_manip(V.fname,'t')],...
        'Planes complete');
nh = 2048;
h  = zeros(nh,1);
for p=1:V.dim(3),
    img = spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1);
    img = img(isfinite(img));
    img = round((img+((mx-mn)/(nh-1)-mn))*((nh-1)/(mx-mn)));
    h   = h + accumarray(img,1,[nh 1]);
    spm_progress_bar('Set',p);
end;
tmp = [find(cumsum(h)/sum(h)>0.9999); nh];
mx  = (mn*nh-mx+tmp(1)*(mx-mn))/(nh-1);

spm_progress_bar('Init',V.dim(3),...
    ['Loading ' spm_str_manip(V.fname,'t')],...
    'Planes loaded');

%udat = zeros(V.dim,'uint8'); Needs MATLAB 7 onwards
udat = uint8(0);
udat(V.dim(1),V.dim(2),V.dim(3)) = 0;

rand('state',100);
for p=1:V.dim(3),
    img = spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1);
    acc = paccuracy(V,p);
    if acc==0,
        udat(:,:,p) = uint8(max(min(round((img-mn)*(255/(mx-mn))),255),0));
    else
        % Add random numbers before rounding to reduce aliasing artifact
        r = rand(size(img))*acc;
        udat(:,:,p) = uint8(max(min(round((img+r-mn)*(255/(mx-mn))),255),0));
    end;
    spm_progress_bar('Set',p);
end;
spm_progress_bar('Clear');
return;

function udat = loaduint8_SM(V)
% Load data from file indicated by V into an array of unsigned bytes.
if size(V.pinfo,2)==1 && V.pinfo(1) == 2,
    mx = 255*V.pinfo(1) + V.pinfo(2);
    mn = V.pinfo(2);
else
    spm_progress_bar('Init',V.dim(3),...
        ['Computing max/min of ' spm_str_manip(V.fname,'t')],...
        'Planes complete');
    mx = -Inf; mn =  Inf;
    for p=1:V.dim(3),
        img = log(max(spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1),1));
        mx  = max([max(img(:))+paccuracy(V,p) mx]);
        mn  = min([min(img(:)) mn]);
        spm_progress_bar('Set',p);
    end;
end;

% Another pass to find a maximum that allows a few hot-spots in the data.
spm_progress_bar('Init',V.dim(3),...
        ['2nd pass max/min of ' spm_str_manip(V.fname,'t')],...
        'Planes complete');
nh = 2048;
h  = zeros(nh,1);
for p=1:V.dim(3),
    img = log(max(spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1),1));
    img = img(isfinite(img));
    img = round((img+((mx-mn)/(nh-1)-mn))*((nh-1)/(mx-mn)));
    if spm_matlab_version_chk('7.0')>=0,
        h = h + accumarray(img,1,[nh 1]);
    else
        h = h + full(sparse(img,1,1,nh,1));
    end
    spm_progress_bar('Set',p);
end;
tmp = [find(cumsum(h)/sum(h)>0.9999); nh];
mx  = (mn*nh-mx+tmp(1)*(mx-mn))/(nh-1);

spm_progress_bar('Init',V.dim(3),...
    ['Loading ' spm_str_manip(V.fname,'t')],...
    'Planes loaded');

%udat = zeros(V.dim,'uint8'); Needs MATLAB 7 onwards
udat = uint8(0);
udat(V.dim(1),V.dim(2),V.dim(3)) = 0;

rand('state',100);
for p=1:V.dim(3),
    img = log(max(spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1),1));
    acc = paccuracy(V,p);
    if acc==0,
        udat(:,:,p) = uint8(max(min(round((img-mn)*(255/(mx-mn))),255),0));
    else
        % Add random numbers before rounding to reduce aliasing artifact
        r = rand(size(img))*acc;
        udat(:,:,p) = uint8(max(min(round((img+r-mn)*(255/(mx-mn))),255),0));
    end;
    spm_progress_bar('Set',p);
end;
spm_progress_bar('Clear');
return;

%_______________________________________________________________________
function udat = loaduint8_SM1(V)
global phase_encoding

switch phase_encoding
    case 1
        V.mat = V.mat([2 1 3 4],:); % (:,[2 1 3 4])
        V.dim = V.dim([2 1 3]);
    case 2        
        % nothing changes
    case 3
        V.mat = V.mat([1 3 2 4],:); % (:,[2 1 3 4])
        V.dim = V.dim([1 3 2]);
end
% Load data from file indicated by V into an array of unsigned bytes.
if size(V.pinfo,2)==1 && V.pinfo(1) == 2,
    mx = 255*V.pinfo(1) + V.pinfo(2);
    mn = V.pinfo(2);
else
    spm_progress_bar('Init',V.dim(3),...
        ['Computing max/min of ' spm_str_manip(V.fname,'t')],...
        'Planes complete');
    mx = -Inf; mn =  Inf;
    for p=1:V.dim(3),
        img = spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1);
        mx  = max([max(img(:))+paccuracy(V,p) mx]);
        mn  = min([min(img(:)) mn]);
        spm_progress_bar('Set',p);
    end;
end;

% Another pass to find a maximum that allows a few hot-spots in the data.
spm_progress_bar('Init',V.dim(3),...
        ['2nd pass max/min of ' spm_str_manip(V.fname,'t')],...
        'Planes complete');
nh = 2048;
h  = zeros(nh,1);
for p=1:V.dim(3),
    img = spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1);
    img = img(isfinite(img));
    img = round((img+((mx-mn)/(nh-1)-mn))*((nh-1)/(mx-mn)));
    h   = h + accumarray(img,1,[nh 1]);
    spm_progress_bar('Set',p);
end;
tmp = [find(cumsum(h)/sum(h)>0.9999); nh];
mx  = (mn*nh-mx+tmp(1)*(mx-mn))/(nh-1);

spm_progress_bar('Init',V.dim(3),...
    ['Loading ' spm_str_manip(V.fname,'t')],...
    'Planes loaded');

%udat = zeros(V.dim,'uint8'); Needs MATLAB 7 onwards
udat = uint8(0);
udat(V.dim(1),V.dim(2),V.dim(3)) = 0;

rand('state',100);
for p=1:V.dim(3),
    img = spm_slice_vol(V,spm_matrix_mod([0 0 p]),V.dim(1:2),1);
    acc = paccuracy(V,p);
    if acc==0,
        udat(:,:,p) = uint8(max(min(round((img-mn)*(255/(mx-mn))),255),0));
    else
        % Add random numbers before rounding to reduce aliasing artifact
        r = rand(size(img))*acc;
        udat(:,:,p) = uint8(max(min(round((img+r-mn)*(255/(mx-mn))),255),0));
    end;
    spm_progress_bar('Set',p);
end;
spm_progress_bar('Clear');
return;

function acc = paccuracy(V,p)
if ~spm_type(V.dt(1),'intt'),
    acc = 0;
else
    if size(V.pinfo,2)==1,
        acc = abs(V.pinfo(1,1));
    else
        acc = abs(V.pinfo(1,p));
    end;
end;
%_______________________________________________________________________

%_______________________________________________________________________
function V = smooth_uint8(V,fwhm)
% Convolve the volume in memory (fwhm in voxels).
lim = ceil(2*fwhm);
x  = -lim(1):lim(1); x = smoothing_kernel(fwhm(1),x); x  = x/sum(x);
y  = -lim(2):lim(2); y = smoothing_kernel(fwhm(2),y); y  = y/sum(y);
z  = -lim(3):lim(3); z = smoothing_kernel(fwhm(3),z); z  = z/sum(z);
i  = (length(x) - 1)/2;
j  = (length(y) - 1)/2;
k  = (length(z) - 1)/2;
spm_conv_vol(V.uint8,V.uint8,x,y,z,-[i j k]);
return;
%_______________________________________________________________________

%_______________________________________________________________________
function krn = smoothing_kernel(fwhm,x)

% Variance from FWHM
s = (fwhm/sqrt(8*log(2)))^2+eps;

% The simple way to do it. Not good for small FWHM
% krn = (1/sqrt(2*pi*s))*exp(-(x.^2)/(2*s));

% For smoothing images, one should really convolve a Gaussian
% with a sinc function.  For smoothing histograms, the
% kernel should be a Gaussian convolved with the histogram
% basis function used. This function returns a Gaussian
% convolved with a triangular (1st degree B-spline) basis
% function.

% Gaussian convolved with 0th degree B-spline
% int(exp(-((x+t))^2/(2*s))/sqrt(2*pi*s),t= -0.5..0.5)
% w1  = 1/sqrt(2*s);
% krn = 0.5*(erf(w1*(x+0.5))-erf(w1*(x-0.5)));

% Gaussian convolved with 1st degree B-spline
%  int((1-t)*exp(-((x+t))^2/(2*s))/sqrt(2*pi*s),t= 0..1)
% +int((t+1)*exp(-((x+t))^2/(2*s))/sqrt(2*pi*s),t=-1..0)
w1  =  0.5*sqrt(2/s);
w2  = -0.5/s;
w3  = sqrt(s/2/pi);
krn = 0.5*(erf(w1*(x+1)).*(x+1) + erf(w1*(x-1)).*(x-1) - 2*erf(w1*x   ).* x)...
      +w3*(exp(w2*(x+1).^2)     + exp(w2*(x-1).^2)     - 2*exp(w2*x.^2));

krn(krn<0) = 0;
return;
%_______________________________________________________________________
% 
% %_______________________________________________________________________
% function display_results(VG,VF,x,flags)
% fig = spm_figure('FindWin','Graphics');
% if isempty(fig), return; end;
% set(0,'CurrentFigure',fig);
% spm_figure('Clear','Graphics');
% 
% %txt = 'Information Theoretic Coregistration';
% switch lower(flags.cost_fun)
%     case 'mi',  txt = 'Mutual Information Coregistration';
%     case 'ecc', txt = 'Entropy Correlation Coefficient Registration';
%     case 'nmi', txt = 'Normalised Mutual Information Coregistration';
%     case 'ncc', txt = 'Normalised Cross Correlation';
%     otherwise, error('Invalid cost function specified');
% end;
% 
% % Display text
% %-----------------------------------------------------------------------
% ax = axes('Position',[0.1 0.8 0.8 0.15],'Visible','off','Parent',fig);
% text(0.5,0.7, txt,'FontSize',16,...
%     'FontWeight','Bold','HorizontalAlignment','center','Parent',ax);
% 
% Q = inv(VF.mat\spm_matrix_mod(x(:)')*VG.mat);
% text(0,0.5, sprintf('X1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f',Q(1,:)),'Parent',ax);
% text(0,0.3, sprintf('Y1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f',Q(2,:)),'Parent',ax);
% text(0,0.1, sprintf('Z1 = %0.3f*X %+0.3f*Y %+0.3f*Z %+0.3f',Q(3,:)),'Parent',ax);
% 
% % Display joint histograms
% %-----------------------------------------------------------------------
% ax  = axes('Position',[0.1 0.5 0.35 0.3],'Visible','off','Parent',fig);
% H   = spm_hist2_z_exp_polyval2(VG.uint8,VF.uint8,VF.mat\VG.mat,[1 1 1]);
% tmp = log(H+1);
% image(tmp*(64/max(tmp(:))),'Parent',ax');
% set(ax,'DataAspectRatio',[1 1 1],...
%     'PlotBoxAspectRatioMode','auto','XDir','normal','YDir','normal',...
%     'XTick',[],'YTick',[]);
% title('Original Joint Histogram','Parent',ax);
% xlabel(spm_str_manip(VG.fname,'k22'),'Parent',ax);
% ylabel(spm_str_manip(VF.fname,'k22'),'Parent',ax);
% 
% H   = spm_hist2_z_exp_polyval2(VG.uint8,VF.uint8,VF.mat\spm_matrix_mod(x(:)')*VG.mat,[1 1 1]);
% ax  = axes('Position',[0.6 0.5 0.35 0.3],'Visible','off','Parent',fig);
% tmp = log(H+1);
% image(tmp*(64/max(tmp(:))),'Parent',ax');
% set(ax,'DataAspectRatio',[1 1 1],...
%     'PlotBoxAspectRatioMode','auto','XDir','normal','YDir','normal',...
%     'XTick',[],'YTick',[]);
% title('Final Joint Histogram','Parent',ax);
% xlabel(spm_str_manip(VG.fname,'k22'),'Parent',ax);
% ylabel(spm_str_manip(VF.fname,'k22'),'Parent',ax);
% 
% % Display ortho-views
% %-----------------------------------------------------------------------
% spm_orthviews('Reset');
%      spm_orthviews('Image',VG,[0.01 0.01 .48 .49]);
% h2 = spm_orthviews('Image',VF,[.51 0.01 .48 .49]);
% global st
% st.vols{h2}.premul = inv(spm_matrix_mod(x(:)'));
% spm_orthviews('Space');
% 
% spm_print
% return;
% 
