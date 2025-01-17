function xls_data=net_read_data(pathx,subjects) % add subj_idx GT 03.22

xls_data = xls2struct(pathx,1); % modified (pathx,'data') GT 03.22

if ~exist('subjects','var')       % GT 06.22 to work with net_main_script
    subjects = 1:size(xls_data,1);  
end

%% check whether all the raw files are there for all the subjects

for subject_i = subjects % modified subject_i = 1:nsubjs    % GT 03.22

    if not(isnan(xls_data(subject_i).eeg_filename)) % added GT 05.22
        if not(exist( xls_data(subject_i).eeg_filename ,'file'))

        disp(['subject' num2str(subject_i) ' : no EEG file!'])
        end

    end

    if not(isnan(xls_data(subject_i).markerpos_filename)) % added GT 05.22
    if not(exist( xls_data(subject_i).markerpos_filename,'file'))
        
        disp(['subject' num2str(subject_i) ' : no electrode file.'])
    end
        
    end

    if not(isnan(xls_data(subject_i).anat_filename)) % added GT 05.22
    if not(exist( xls_data(subject_i).anat_filename,'file'))

        disp(['subject' num2str(subject_i) ' : no MR anatomy file.'])
    end
        
    end

    if isfield(xls_data(subject_i),'dwi_filename') % added GT 03.22
        if isnan( xls_data(subject_i).dwi_filename  )
            
            disp(['subject' num2str(subject_i) ' : no MR diffusion tensor file.'])
            xls_data(subject_i).dwi_filename = '';
            
        elseif not(exist( xls_data(subject_i).dwi_filename,'file'))
            
            disp(['subject' num2str(subject_i) ' : MR diffusion tensor file not found! Not used for processing.'])
            xls_data(subject_i).dwi_filename = '';
        end
    end
    
    %check CTI image, added by JS 10.Nov.2021
    if isfield(xls_data(subject_i),'cti_filename')  % added GT 03.22
        if isnan( xls_data(subject_i).cti_filename  )
            
            disp(['subject' num2str(subject_i) ' : no CT anatomy file.'])
            xls_data(subject_i).cti_filename = '';
            
        elseif not(exist( xls_data(subject_i).cti_filename,'file'))
            
            disp(['subject' num2str(subject_i) ' : CT anatomy file not found! Not used for processing.'])
            xls_data(subject_i).cti_filename = '';
        end
    end
    
    %check field of external events file, added by MZ, 11.Dec.2017
    if isfield(xls_data(subject_i),'experiment_filename')
        if isnan(xls_data(subject_i).experiment_filename)
            disp(['subject' num2str(subject_i) ' : no external events file, skip loading external events.'])
            xls_data(subject_i).experiment_filename = '';
        elseif not(exist( xls_data(subject_i).experiment_filename, 'file' ))
            disp(['subject' num2str(subject_i) ' : external events file not found! Not used for processing.'])
            xls_data(subject_i).experiment_filename = '';
        end
    end


end




