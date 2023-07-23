function write_DTIdataset_Kurtosis_Leipzig062016(midfix,VS0,AS0,lS0,FA,EVAL,EVEC1,ADC,DM,Asym0,MSK,bvalues,dummy_DT,Dthr,DiffVecORIG,bvalues0,ending)
% S.Mohammadi 31.05.2016

% write data:    
prefix = ['b0meas_' midfix];
if(exist('ending'))
    my_write_data(exp(lS0),VS0,prefix,AS0,MSK,ending);
else
    my_write_data(exp(lS0),VS0,prefix,AS0,MSK);
end
prefix = ['FA_' midfix];
if(exist('ending'))
    my_write_data(FA/1000,VS0,prefix,AS0,MSK,ending);
else
    my_write_data(FA/1000,VS0,prefix,AS0,MSK);
end
prefix = ['MD_' midfix];
MD = mean(EVAL,2);
if(exist('ending'))
    my_write_data(MD,VS0,prefix,AS0,MSK,ending);
else
    my_write_data(MD,VS0,prefix,AS0,MSK);
end

% prefix = ['IMD_' midfix];
% IMD = 1./MD;
% IMD(MD<Dthr)=0;
% if(exist('ending'))
%     my_write_data(IMD,VS0,prefix,AS0,MSK,ending);
% else
%     my_write_data(IMD,VS0,prefix,AS0,MSK);
% end

prefix = ['Axial_' midfix];
AD = EVAL(:,1);
if(exist('ending'))
    my_write_data(EVAL(:,1),VS0,prefix,AS0,MSK,ending);
else
    my_write_data(EVAL(:,1),VS0,prefix,AS0,MSK);
end

% IAD = 1./AD;
% IAD(AD<Dthr)=0;
% prefix = ['IAxial_' midfix];
% if(exist('ending'))
%     my_write_data(IAD,VS0,prefix,AS0,MSK,ending);
% else
%     my_write_data(IAD,VS0,prefix,AS0,MSK);
% end

if(size(EVAL,2)>2)
    prefix = ['Radial_' midfix];
    RD = (EVAL(:,2)+EVAL(:,3))/2;
    if(exist('ending'))
        my_write_data(RD,VS0,prefix,AS0,MSK,ending);
    else
        my_write_data(RD,VS0,prefix,AS0,MSK);
    end
end

if(size(EVAL,2)>2)
    IRD = 1./(RD);
    IRD(RD<Dthr)=0;
    prefix = ['IRadial_' midfix];
    if(exist('ending'))
        my_write_data(IRD,VS0,prefix,AS0,MSK,ending);
    else
        my_write_data(IRD,VS0,prefix,AS0,MSK);
    end
end
% 
% prefix = ['AD_RD_' midfix];
% if(exist('ending'))
%     my_write_data(EVAL(:,1)-(EVAL(:,2)+EVAL(:,3))/2,VS0,prefix,AS0,MSK,ending);
% else
%     my_write_data(EVAL(:,1)-(EVAL(:,2)+EVAL(:,3))/2,VS0,prefix,AS0,MSK);
% end
% 
% if(~exist('dummy_DT'))
%     dummy_DT=1;
% end

components = {'x' 'y' 'z'};
if(dummy_DT==1)
    for i=1:size(EVEC1,2)
        prefix = ['EVEC1_' midfix];
        if(exist('ending'))
            ending1 = [ending '-' components{i}];
        else
            ending1 = ['-' components{i}];
        end
        my_write_data(EVEC1(:,i),VS0,prefix,AS0,MSK,ending1);
        prefix = ['EVAL_' midfix];
        my_write_data(EVAL(:,i),VS0,prefix,AS0,MSK,ending1);
    end
else
     for j=1:size(EVEC1,3)
         for i=1:size(EVEC1,2)
            prefix = ['EVEC_' midfix];
            if(exist('ending'))
                ending1 = [ending '-' components{j} num2str(i)];
            else
                ending1 = ['-' components{j} num2str(i)];
            end
            my_write_data(EVEC1(:,j,i),VS0,prefix,AS0,MSK,ending1);
            if(j==1)
                if(exist('ending'))
                    ending1 = [ending '-' num2str(i)];
                else
                    ending1 = ['-' num2str(i)];
                end
                prefix = ['EVAL_' midfix];
                my_write_data(EVAL(:,i),VS0,prefix,AS0,MSK,ending1);
            end
         end
     end
end

if(size(Asym0,2)==7)
    % write b0 image
    prefix = ['b0_' midfix];
    if(exist('ending'))
        my_write_data(exp(Asym0(:,7)),VS0,prefix,AS0,MSK,ending);   
    else
        my_write_data(exp(Asym0(:,7)),VS0,prefix,AS0,MSK);    
    end
elseif(size(Asym0,2)==8)
    % write b0 image
    prefix = ['R2_' midfix];
    if(exist('ending'))
        my_write_data(exp(Asym0(:,7)),VS0,prefix,AS0,MSK,ending);   
    else
        my_write_data(exp(Asym0(:,7)),VS0,prefix,AS0,MSK);    
    end
    % write b0 image
    prefix = ['b0_' midfix];
    if(exist('ending'))
        my_write_data(exp(Asym0(:,8)),VS0,prefix,AS0,MSK,ending);   
    else
        my_write_data(exp(Asym0(:,8)),VS0,prefix,AS0,MSK);    
    end
end
if(isstruct(Asym0))
    %% prepare tensors
    Kp2thr = 0.0001;
    if(isfield(Asym0,'Asym_olsq'))
        Asym00 = cat(2,Asym0.Asym_olsq,Asym0.Asym_X4);
    elseif(isfield(Asym0,'Asym_ad'))
        Asym00 = cat(2,Asym0.Asym_ad,Asym0.Asym_X4_ad);
    elseif(isfield(Asym0,'Asym_robust'))
        Asym00 = cat(2,Asym0.Asym_robust,Asym0.AsymX4_robust);
    else
        warning('Something is missing');
        keyboard;
    end
    %% Residuals 
            
    ADCmodel    = -(DM'*Asym00');
    ADCmodel    = permute(ADCmodel,[2 1]);
    ADCmodel    = bsxfun(@rdivide,ADCmodel,bvalues(bvalues>min(bvalues)));
    ADCmodel    = permute(ADCmodel,[2 1]);
    resDT0      = ADC-ADCmodel;
    resDT0      = resDT0.*resDT0;
    resDT0e     = exp(ADC)-exp(ADCmodel);
    resDT0e     = resDT0e.*resDT0e;
   
    clear ADC;
    % rms of tensor fit error
    resDT0e  = mean(min(resDT0e,100),1);
    mresDT0e = sqrt(resDT0e);
    
    resDT0  = mean(resDT0,1);
    mresDT0 = sqrt(resDT0);
    clear resDT0 resDT0e;

    % normalised max-norm of tensor fit error
    % mresDT0 = max(abs(resDT0),[],2)./sqrt(mean(resDT0.^2,2));

%     % write res vector
%     prefix = ['RES_DKI_' midfix];
%     if(exist('ending','var'))
%         my_write_data(mresDT0,VS0,prefix,AS0,MSK, ending); 
%     else
%         my_write_data(mresDT0,VS0,prefix,AS0,MSK); 
%     end
    % write res vector
    prefix = ['RES_DKI_exp_' midfix];
    if(exist('ending','var'))
        my_write_data(mresDT0e,VS0,prefix,AS0,MSK, ending); 
    else
        my_write_data(mresDT0e,VS0,prefix,AS0,MSK); 
    end
    %% Kurtosis
    perc1 = 0.95;
    [Kparallel,Kperp,Dhat,MSK2,MK,Khat] = make_kurtosis_leipzig052016(Asym00,Dthr,DiffVecORIG,bvalues0);
    AWF = zeros(1,size(Asym00,1));
    mAWF = zeros(1,size(Asym00,1));
    for i=1:length(MSK2)
               
        
        Kmax   = max(Khat(MSK2(i),:));
        AWF(MSK2(i)) = Kmax/(Kmax+3);
        
        [y,x] = hist(Khat(MSK2(i),:),100);
        cy      = cumsum(y);
        sz      = size(Khat,2);
        if(numel(find(y>0))>(1-perc1)*100)
          
            tmpMSK  = find(cy>=sz*perc1);
            mKmax   = sum(x(tmpMSK).*y(tmpMSK))/sum(y(tmpMSK));
            mAWF(MSK2(i)) = mKmax/(mKmax+3);
        else
            mAWF(MSK2(i)) = 0;
        end
        
    end
    prefix = ['AWF_' midfix]; % Fieremans 2011
    my_write_data(AWF,VS0,prefix,AS0,MSK);  
    
%     prefix = ['mAWF_' midfix]; % modfied Fieremans 2011
%     my_write_data(mAWF,VS0,prefix,AS0,MSK);  
%     
    MSK1 = find((abs(Kperp))<1e+3);
    prefix = ['Kperp_' midfix]; % Tabesh
    my_write_data(Kperp(MSK1),VS0,prefix,AS0,MSK(MSK2(MSK1)));    
    prefix = ['Kparallel_' midfix]; %Tabesh
    MSK1 = find((abs(Kparallel))<1e+3);
    my_write_data(Kparallel(MSK1),VS0,prefix,AS0,MSK(MSK2(MSK1)));
    MD = mean(Asym00(MSK2,1:3),2);
    MSK22   = EVAL(MSK2,3)> Dthr;
    Kperp_hui    = zeros(size(MD));
    K1    = zeros(size(MD));
    K2    = zeros(size(MD));
    K3    = zeros(size(MD));
    Kmean    = zeros(size(MD));
    K1(MSK22)  = (MD(MSK22)./EVAL(MSK2(MSK22),1)).^2.*Dhat(MSK22,1);
    K2(MSK22)  = (MD(MSK22)./EVAL(MSK2(MSK22),2)).^2.*Dhat(MSK22,2);
    K3(MSK22)  = (MD(MSK22)./EVAL(MSK2(MSK22),3)).^2.*Dhat(MSK22,3);
%     MSKK13     = abs(K3)>abs(K1);
%     K3(MSKK13) = 0; 
    Kperp_hui(MSK22)   = (K2(MSK22)+K3(MSK22))/2;
    MSKtmp = (Kperp_hui < 0 | Kperp_hui > 1000);
    Kperp_hui(MSKtmp) = 0;
%     prefix  = ['Kperp_Hui' midfix]; %Hui et al. 2008
%     my_write_data(Kperp_hui,VS0,prefix,AS0,MSK(MSK2));
    Kmean(MSK22)   = (K1(MSK22) +K2(MSK22)+K3(MSK22))/3;
    Kp2    = zeros(size(MD));
    Kp2(MSK22)    = (K1(MSK22).^2+K2(MSK22).^2+K3(MSK22).^2);
    MSK_Kp2 = Kp2<=Kp2thr;
    Kp2(MSK_Kp2)     = Kp2thr;
    FAk     = sqrt(3/2*((K1-Kmean).^2+(K2-Kmean).^2+(K3-Kmean).^2)./Kp2);
    prefix  = ['Kmean_' midfix]; %Hui et al. 2008
    MSKtmp = (Kmean < 0 | Kmean > 1000);
    Kmean(MSKtmp) = 0;
%     my_write_data(Kmean,VS0,prefix,AS0,MSK(MSK2));

    prefix  = ['MK_' midfix]; %Zhuo et al. 2012
%     MK = mean(Dhat,2);
% MK as defined in Tabesh et al. 2011
    MSKtmp = (MK < -100 | MK > 100);
    MK(MSKtmp) = 0;
    my_write_data(MK,VS0,prefix,AS0,MSK(MSK2));

%     prefix  = ['FAk_' midfix]; %Hui et al. 2008
%     my_write_data(FAk,VS0,prefix,AS0,MSK(MSK2));
%     for i = 1:size(Asym00,2)
%         if(i<10)
%             ending = ['-0' num2str(i)];
%         else
%             ending = ['-' num2str(i)];
%         end
%         prefix = ['Tensor_' midfix];
%         my_write_data(Asym00(:,i),VS0,prefix,AS0,MSK, ending);
%         if(i<=size(Dhat,2))
%             prefix = ['DTensor_' midfix];
%             my_write_data(Dhat(:,i),VS0,prefix,AS0,MSK(MSK2), ending);
%         end
%     end
    clear ending;
    % write b0 image
    prefix = ['b0_' midfix];
    if(exist('ending'))
        my_write_data(exp(Asym00(:,end)),VS0,prefix,AS0,MSK,ending);   
    else
        my_write_data(exp(Asym00(:,end)),VS0,prefix,AS0,MSK);    
    end
    clear MSK2 MSK1;
end