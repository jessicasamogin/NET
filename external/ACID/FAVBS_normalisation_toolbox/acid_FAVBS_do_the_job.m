function out = FAVBS_do_the_job(rVb0, rVFA, rVmean, FA_on, iter,MSKperc, VGstemp, SCI, cutoffIN)
% function out = FAVBS_do_the_job(rVb0, rVFA, rVmean, FA_on, iter, stemp)
% function out = FAVBS_do_the_job(rVb0, rVFA, rVmean, FA_on, iter, VG)
% Begin VARIABLES
% rVb0      = b0 images
% rVFA      = FA images
% rVmean    = average of all DW images
% FA_on     = dummy for normalization contrast
% iter      = iteration (used for normalisation parameter selection)
% stemp     = dummy for template symmetrization
% VG        = template (in this case, no template is created)
% End VARIABLES
%%%%%%%%%%%%%%%%%%%%%%
% TODOs:
% Schnittstellen zu aufgerufenen Funktionen anpassen
% rP -> rVXX
% rPmean -> rVmean
% (File names durch spm_vol structs ersetzen)
% Wenn File names als Liste, dann als cellstr '{','}'
% spm_get durch cfg_getfile('FPlist',...) ersetzen
%%%%%%%%%%%%%%%%%%%%%%
% step zero: creating first subject-averaged meanDW image, FA image and b0
% image
% Volkmar Glauche and Siawoosh Mohammadi 10/01/09

% SM defaults
smk_ext = 3;

if(~exist('SCI','var'))
    SCI =1;
end
if(~exist('cutoffIN','var'))
    cutoffIN = '';
end

if isnumeric(VGstemp)
    doloop=false; % false: run iterative template generation
    dotemplate = true;
    stemp = VGstemp;
else
    doloop = true;
    dotemplate = false;
    VG = VGstemp;
end

if dotemplate
    if(FA_on==0)
        [p,n,e]     = spm_fileparts(rVb0(1).fname);
        pname       = fullfile(p, ['template-' num2str(0) '_b0' e]); % ->KANN NACHHER WEG?
        VTemplate(1) = rVb0(1);
        VTemplate(1).fname = pname;
        VTemplate(1) = spm_imcalc(rVb0, VTemplate(1), 'mean(X)', {1});
    else
        [p,n,e]      = spm_fileparts(rVmean(1).fname); 
        mname           = fullfile(p, ['Average_rmeanDWI' e]);   %->KANN NACHHER WEG?
        VGmean = rmfield(rVmean(1),'private');
        VGmean.fname = mname;
        VGmean      = spm_imcalc(rVmean, VGmean, 'mean(X)', {1});
        [p,n,e]      = spm_fileparts(rVFA(1).fname); 
        % begin: creation of brain- (FA_on==1) or left-brain mask  (FA_on==2 and FA_on==3)    
        if(FA_on==1)
            % VG: BMSK_average output of find_mask_meanDWI
              % VG: BMSK_average output of find_mask_meanDWI
            vxg                 = sqrt(sum( VGmean.mat(1:3,1:3).^2)); 
            smk                 = vxg*smk_ext;
            
            VBMSK_average = find_mask_meanDWI(VGmean, MSKperc,smk); % ->HIER FEHLER!!!
            pname           = fullfile(p, ['template-' num2str(0) '_FA' e]);  % ->KANN NACHHER WEG?
            VTemplate(1) = rVFA(1);
            VTemplate(1).fname = pname;
            VTemplate(1) = spm_imcalc([rVFA(:); VBMSK_average], VTemplate(1), 'mean(X(1:end-1,:)).*X(end,:)', {1});
        else
            [VrL_MSK,VrfL_MSK]= main_creat_LBMSK_iii(VGmean); % ->KANN NACHHER WEG?
            Lpname          = fullfile(p, ['Ltemplate-' num2str(0) '_LFA' e]); % ->KANN NACHHER WEG?
            VLTemplate(1) = rVFA(1);
            VLTemplate(1).fname = Lpname;
            VLTemplate(1) = spm_imcalc([rVFA(:); VrL_MSK], VLTemplate(1), 'mean(X(1:end-1,:)).*X(end,:)', {1});
            fLpname          = fullfile(p, ['fLtemplate-' num2str(0) '_LFA' e]); % ->KANN NACHHER WEG?
            VfLTemplate(1) = rVFA(1);
            VfLTemplate(1).fname = fLpname;
            VfLTemplate(1) = spm_imcalc([rVFA(:); VrfL_MSK], VfLTemplate(1), 'mean(X(1:end-1,:)).*X(end,:)', {1});
        end
    end
    % begin: symmetrization
    if(FA_on==0 || FA_on==1)
        if (stemp==1)
            [p,n,e]     = spm_fileparts(VTemplate(1).fname);
            VfTemplate = VTemplate(1);
            VfTemplate.mat = diag([-1 1 1 1])*VTemplate(1).mat;
            Average_wP  = fullfile(p, [n '_sym' e]);
            VsTemplate(1)  = VTemplate(1);
            VsTemplate(1).fname = Average_wP;
            VsTemplate(1) = spm_imcalc([VTemplate(1) VfTemplate], VsTemplate(1), '(i1+i2)/2');
            VG = VsTemplate(1);
            clear p n e;
        else % no symmetrization of template
            VG = VTemplate(1);
        end
    else
        [p,n,e]     = spm_fileparts(VLTemplate(1).fname);
        VsTemplate(1)  = VLTemplate(1);
        Average_wP  = fullfile(p, [n '_sym' e]);
        VsTemplate(1).fname = Average_wP;
        VsTemplate(1) = spm_imcalc([VLTemplate(1) VfLTemplate(1)], VsTemplate(1), '(i1+i2)/2');
        VG = VsTemplate(1);
        clear p n e;
    end
    % end: symmetrization
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% begin loop:
k=1;
% iter kann als eingabeparmeter verwendet werden.


if ~exist('iter','var')
    iter=1;
end

procent_diff    = 100;
ddiff           = 100;
while(procent_diff>2 && ddiff>2),
    if dotemplate
        disp('Template generation, step:')
        disp(k)
        if(k==1)
            tmp_VG           = VG;
            tmp_diff         = 100;
        end
    end
    % normalisation
    switch FA_on
        case 0
            if(SCI==1)
                matnames = norm_spm_FAVBS_SM_SC(VG,rVb0,'',FA_on,iter,MSKperc,cutoffIN);
            else
                matnames = norm_spm_FAVBS(VG,rVb0,'',FA_on,iter,MSKperc);
            end
        case 1 
            if(SCI==1)
                matnames = norm_spm_FAVBS_SM_SC(VG,rVFA,rVmean,FA_on,iter,MSKperc);
            else
                matnames = norm_spm_FAVBS(VG,rVFA,rVmean,FA_on,iter,MSKperc);
            end
        case 2 
            if(SCI==1)
                matnames = norm_spm_FAVBS_SM_SC(VG,rVFA,rVmean,FA_on,iter,MSKperc);
            else
                [matnames, fmatnames] = norm_spm_FAVBS(VG,rVFA,rVmean,FA_on,iter,MSKperc);
            end
    end

    % begin: creating average k

%%%%%%begin: write normalisation%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
    switch FA_on
        case 0
            [wrVb0 wrVFA wrVmean]   = write_norm(rVb0,rVFA,rVmean,FA_on);  
        case 1
            [wrVFA wrVb0 wrVmean]   = write_norm(rVFA,rVb0,rVmean,FA_on) ;  % es wir rVb0 auch weggeschrieben!!!
        case 2
            % keyboard
            [wrVFA wfrVFA]          = write_norm(rVFA,'','',FA_on) ;
    end
    if dotemplate
        switch FA_on
            case 0
                % b0 template
                [p,n,e]                 = spm_fileparts(rVb0(1).fname); % get the path
                wpname                  = fullfile(p, ['template-' num2str(k) '_b0' e]);
                VTemplate(k+1)          = wrVb0(1);
                VTemplate(k+1).fname    = wpname;
                VTemplate(k+1)          = spm_imcalc(wrVb0, VTemplate(k+1), 'mean(X)', {1});
            case 1
                [p,n,e]                 = spm_fileparts(rVFA(1).fname); % get the path
                wpname                  = fullfile(p, ['template-' num2str(k) '_FA' e]);
                VTemplate(k+1)          = wrVFA(1);
                VTemplate(k+1).fname    = wpname;
                % weighted mean of normalised FA images
                VTemplate(k+1)          = spm_imcalc([wrVFA(:); VBMSK_average], VTemplate(k+1), 'mean(X(1:end-1,:)).*X(end,:)', {1});
            case 2
                [p,n,e]                 = spm_fileparts(rVFA(1).fname); % get the path
                LMFApname               = fullfile(p, ['Ltemplate-' num2str(k) '_LFA' e]);
                VLTemplate(k+1)         = wrVFA(1);
                VLTemplate(k+1).fname   = LMFApname;
                VLTemplate(k+1)         = spm_imcalc([wrVFA(:); VrL_MSK], VLTemplate(k+1), 'mean(X(1:end-1,:)).*X(end,:)', {1});
                fLMFApname              = fullfile(p, ['fLtemplate-' num2str(k) '_LFA' e]);
                VfLTemplate(k+1)        = wrVFA(1);
                VfLTemplate(k+1).fname  = fLMFApname;
                VfLTemplate(k+1)        = spm_imcalc([wfrVFA(:); VrfL_MSK], VfLTemplate(k+1), 'mean(X(1:end-1,:)).*X(end,:)', {1});
        end
        %%%%%%%%%%%%%%%%%%%%%%end: write normalize%%%%%%%%%%%%%%%%%%%%%%%%%%%5

        % begin: symmetrization
        if(FA_on==0 || FA_on==1)
            if(stemp==1)
                [p,n,e]     = spm_fileparts(VTemplate(k+1).fname);
                VfTemplate = VTemplate(k+1);
                VfTemplate.mat = diag([-1 1 1 1])*VTemplate(k+1).mat;
                Average_wP  = fullfile(p, [n '_sym' e]);
                VsTemplate(k+1)  = VTemplate(k+1);
                VsTemplate(k+1).fname = Average_wP;
                VsTemplate(k+1) = spm_imcalc([VTemplate(k+1) VfTemplate], VsTemplate(k+1), '(i1+i2)/2');
                VG = VsTemplate(k+1);
                clear p n e;
            else % no symmetrization of template
                VG = VTemplate(k+1);
            end
        else
            [p,n,e]     = spm_fileparts(VLTemplate(k+1).fname);
            VsTemplate(k+1)  = VLTemplate(k+1);
            Average_wP  = fullfile(p, [n '_sym' e]);
            VsTemplate(k+1).fname = Average_wP;
            VsTemplate(k+1) = spm_imcalc([VLTemplate(k+1) VfLTemplate(k+1)], VsTemplate(k+1), '(i1+i2)/2');
            VG = VsTemplate(k+1);
            clear p n e;
        end
        % end: symmetrization
    end
    if doloop
        % end while loop
        break;
    else
        % check the amount of difference between Average_wP and Average_rP
        % HIER FEHLT: DIE DATEN VORHER GLAETTEN
        A_tVG    = spm_read_vols(tmp_VG);
        A_wVG    = spm_read_vols(VG);
        msk      = isfinite(A_wVG(:)) & isfinite(A_tVG(:));
        procent_diff    = sum((A_wVG(msk)-A_tVG(msk)).^2)/sum(A_wVG(msk).^2)*100;
        ddiff           = tmp_diff-procent_diff;
        disp(procent_diff);
        disp(ddiff);
        tmp_diff        = procent_diff;
        tmp_VG          = VG;
        k=k+1;
    end
    clear wP wLP wfLP;
end

% Outputs
switch FA_on
    case 0
        out.matnames = matnames;
        out.wrb0names = {wrVb0.fname};
        out.wrFAnames = {wrVFA.fname};
        out.wrPmeans = {wrVmean.fname};
        if dotemplate
            out.templates = {VTemplate.fname};
            if(stemp==1)
                out.stemplates = {VsTemplate.fname};
            end
        end
    case 1
        out.matnames = matnames;
        out.wrb0names = {wrVb0.fname};
        out.wrFAnames = {wrVFA.fname};
        out.wrPmeans = {wrVmean.fname};
        if dotemplate
            out.templates = {VTemplate.fname};
            if(stemp==1)
                out.stemplates = {VsTemplate.fname};
            end
        end
    case 2
        out.matnames = matnames;
        out.fmatnames = fmatnames;
        out.wrFAnames = {wrVFA.fname};
        out.wfrFAnames = {wfrVFA.fname};
        if dotemplate
            out.Ltemplates = {VLTemplate.fname};
            out.fLtemplates = {VfLTemplate.fname};
            out.stemplates = {VsTemplate.fname};
        end
end
%
function varargout = write_norm(Vsource,Vother1,Vother2,FA_on)
% Outputs: volume handles for
% FA_on == 0 - wVsource (b0), wVFA, wVmean
% FA_on == 1 - wVsource (FA), wVb0, wVmean
% FA_on == 2 - wV, wfV
% copied from write_norm.m
defaults_n.write.preserve   = 0;
defaults_n.write.vox        = [NaN NaN NaN];
defaults_n.write.bb         = ones(2,3)*NaN;
defaults_n.write.interp     = 7;
defaults_n.write.wrap       = [0 0 0];
fdefaults_n = defaults_n;
fdefaults_n.write.prefix = 'wf';

n=size(Vsource,1);

for i=1:n,
    [pth,fname,ext] = fileparts(Vsource(i).fname);
    if(FA_on==0 || FA_on==1)
        matname         = char(cfg_getfile('FPList',pth,['^' fname '_sn.mat']));
        % get output struct from spm_write_sn
        % explicitly write the data to disk
        % remove data field from struct
        Vo = spm_write_sn(Vsource(i),matname,defaults_n.write);
        Vo = spm_write_vol(Vo, Vo.dat);
        varargout{1}(i) = rmfield(Vo,'dat');
        Vo = spm_write_sn(Vother1(i),matname,defaults_n.write);
        Vo = spm_write_vol(Vo, Vo.dat);
        varargout{2}(i) = rmfield(Vo,'dat');
        Vo = spm_write_sn(Vother2(i),matname,defaults_n.write);
        Vo = spm_write_vol(Vo, Vo.dat);
        varargout{3}(i) = rmfield(Vo,'dat');
    end
    if(FA_on==2)
        matname         = char(cfg_getfile('FPList',pth,['^LM-' fname '_sn.mat']));
        fmatname        = prepend(matname, 'f');
        fV  =   Vsource(i);
        fV.mat = diag([-1 1 1 1])*Vsource(i).mat;
        Vo = spm_write_sn(Vsource(i),matname,defaults_n.write);
        Vo = spm_write_vol(Vo, Vo.dat);
        varargout{1}(i) = rmfield(Vo,'dat');
        Vo = spm_write_sn(fV,fmatname,fdefaults_n.write);
        Vo = spm_write_vol(Vo, Vo.dat);
        varargout{2}(i) = rmfield(Vo,'dat');
    end
end
%_______________________________________________________________________
function PO = prepend(PI,pre)
[pth,nm,xt,vr] = spm_fileparts(deblank(PI));
PO             = fullfile(pth,[pre nm xt vr]);
return;
%_______________________________________________________________________
