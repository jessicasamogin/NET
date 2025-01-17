% runemdtrialbytrial() - Perform Empirical Mode Decomposition (EMD),which was developed by Norden E. Huang (1998),
%            on the input data trials (one by one). 
%            
% Usage:
%         >> [allmodes] = runemdtrialbytrial(data); % train using defaults 
%    else
%         >> [allmodes  = runemdtrialbytrial(data,'Key1',Value1',...);
% Input:
%    data     = input data (chans,frames*epochs). 
%              
%
% Optional keywords [argument]:
% 'Nstd'     = ratio of the standard deviation of the added noise and that of data, in case of 
%              Ensemble Empirical Mode Decomposition (EEMD) (default -> 0).
% 'NE'       = Ensemble number in case of Ensemble Empirical Mode Decomposition (EEMD) (default -> 1)
% 'modes'    = Number of modes  (default -> 4)
% 'trials'   = Number of trials  (default -> 1)
%
% Outputs:    The output is a matrix of N*(m+1)*T matrix, where N is the length of the input
% data ,  m= number of modes, and T = number of trials. Column 1 is the original data, columns 2, 3, ...
% m are the IMFs from high to low frequency, and comlumn (m+1) is the
% residual (over all trend).
%
% It should be noted that when Nstd is set to zero and NE is set to 1, the
% program degenerated to a EMD program. Otherwise, it is a EEMD program
%
% This code is prepared by Zhaohua Wu (zhwu@cola.iges.org) and modified by
% Karema Al-Subari (Karema.Al-Subari@biologie.uni-regensburg.de>;)& Saad Al-Baddai (Saad.Al-Baddai@biologie.uni-regensburg.de).





function [allmodes]=runemdtrialbytrial(chans,varargin)


if nargin < 1
  help runemdtrialbytrial  
  return
end


[Nchans Nframes] = size(chans); % determine the data size

%%%%%%%%%%%%%%%%%%%%%% Declare defaults used below %%%%%%%%%%%%%%%%%%%%%%%%
%

DEFAULT_Noise        = 0;  % Default Noise
DEFAULT_Ensemble     = 1;  % Default Ensemple Number
DEFAULT_Modes        = 4;  % Default Number of Modes
DEFAULT_Trials       = 1;  % Default Number of Trials

%%%%%%%%%%%%%%%%%%%%%%% Set up keyword default values %%%%%%%%%%%%%%%%%%%%%%%%%

Nstd                 = DEFAULT_Noise;
NE                   = DEFAULT_Ensemble;
modes                = DEFAULT_Modes;
trials               = DEFAULT_Trials;


%%%%%%%%%% Collect keywords and values from argument list %%%%%%%%%%%%%%%

for i = 1:2:length(varargin) % for each Keyword
      Keyword = varargin{i};
      Value = varargin{i+1};
  if ~isstr(Keyword)
         fprintf('runemd(): keywords must be strings')
         return
  end
 Keyword = lower(Keyword); % convert upper or mixed case to lower

      if strcmp(Keyword,'Nstd') | strcmp(Keyword,'Nstd')
         if isstr(Value)
            fprintf('runemd(): noise value must be number')
            return
        elseif ~isempty(Value)
           Nstd = Value;
           if ~Nstd,
            Nstd = DEFAULT_Noise;
            end
         end
      elseif strcmp(Keyword,'NE')
         if isstr(Value)
            fprintf('runemd(): lrate value must be a number')
            return
        elseif ~isempty(Value)
         NE = Value;
          if ~NE,
            NE = DEFAULT_Ensemple;
            end
         end
      elseif strcmp(Keyword,'MODES')| strcmp(Keyword,'modes')
         if isstr(Value)
            fprintf('runemd(): modes number must be a integer')
            return
        elseif ~isempty(Value)
         modes = Value;
          if ~modes,
            modes = DEFAULT_Modes;
            end
         end
       elseif strcmp(Keyword,'Trials')| strcmp(Keyword,'trials')
         if isstr(Value)
            fprintf('runemd(): trials number must be a integer')
            return
        elseif ~isempty(Value)
         trials = Value;
          if ~trials,
            trials = DEFAULT_Trials;
            end
         end
end
end


disp('running...........................................................................................................................................');
chans=double(chans);

 for chansnum=1:size(chans,1);

    for Trialsnum=1:trials;

      Y=chans(chansnum,:,Trialsnum);
      xsize = length(Y);
      dd = 1:1:xsize;
      Ystd = std(Y);
      Y = Y/Ystd;


    TNM = modes;     % it could by fixed using fix(log2(xsize))-1;
    TNM2 = TNM + 2;
    X1=zeros(xsize,1);
    for kk = 1:1:TNM2, 
      for ii = 1:1:xsize,
        allmode(ii,kk) = 0.0;
      end
    end

    imf=[];  


   for iii = 1:1:NE,
     for i = 1:xsize,
    % rng(8000,'twister');
        temp = randn(1,1)*Nstd;
        X1(i) = Y(i) + temp;
     end

     for jj=1:1:xsize,
        mode(jj,1) = Y(jj);
     end
    
     xorigin = X1;
     xend = xorigin;
     nmode = 1;

     while nmode <= TNM,
        xstart = xend;
        iter = 1;
   
        while iter<=10,
         
            [spmax, spmin]=extrema_emd(xstart);
            upperr= spline(spmax(:,1),spmax(:,2),dd);
            lowerr= spline(spmin(:,1),spmin(:,2),dd);
            mean_ul = (upperr + lowerr)/2;
            xstart = xstart - transpose(mean_ul);
            iter = iter +1;
        end
        xend = xend - xstart;
   
   	    nmode=nmode+1;
        
        for jj=1:1:xsize,
            mode(jj,nmode) = xstart(jj);
        end
       end
   
       for jj=1:1:xsize,
        mode(jj,nmode+1)=xend(jj);
       end
   
    allmode=allmode+mode;
    
end

allmode=allmode/NE;
allmode=allmode*Ystd;


allmode=allmode(:,1:end)';

allmodechans(chansnum,:,:,Trialsnum)=allmode;
clear allmode;
end;
end

 
allmodes=allmodechans;

% if size(chans,1)==1
%   allmodechannelss=reshape(allmodechannelss,1,TNM2,size(allmodechannelss,3)*size(allmodechannelss,4));
% end

 


