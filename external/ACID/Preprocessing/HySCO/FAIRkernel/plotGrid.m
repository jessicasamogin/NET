% =======================================================================================
% (c) Jan Modersitzki 2011/04/26, see FAIR.2 and FAIRcopyright.m.
% http://www.mic.uni-luebeck.de/people/jan-modersitzki.html
% 
% function varargout = plotGrid(Y,omega,m,varargin)
% 
% Plot a d-dimensional grid of size m for a domain omega
% 
% Y:     coordinates of grid points
% omega: specifies domain Omega = (0,omega(1)) x ... x (0,omega(d))
% m:     number of cells, m=(m(1),...,m(d));
%
% coding is challenging due to different options for the grid
% (cell-centered, staggered, or nodal)
%
% +--^--+--^--+--^--+
% |     |     |     |  cell-center: o
% >  o  >  o  >  o  >  nodal:       +
% |     |     |     |  staggered:   >^
% +--^--+--^--+--^--|
% |     |     |     |
% >  o  >  o  >  o  >
% |     |     |     |
% +--^--+--^--+--^--|
%
% Input:
%   Y        location of grid points
%   omega		 describing the domain
%	  m 	     number of discretization points
%   varargin optional parameters like {'spacing',[2,2,1]}
%
% Output:
%   ph       plot handle
% changes 2008-12-04:
%   modified omega
% =======================================================================================

function varargout = plotGrid(Y,omega,m,varargin)

if nargin==0
    runMinimalExample; return;
end

% setup default parameter
spacing   = [1,1,1]; % plot every spacing(j) grid line in dimensionj
color     = 'b';     % default color
linewidth = 1;       % default linewidth

for k=1:2:length(varargin),         % overwrites default parameter
  eval([varargin{k},'=varargin{',int2str(k+1),'};']);
end;

dim = length(omega)/2; % dimension can be 1,2,3
% if necessary, make spacing for every dimension
if length(spacing) == 1, spacing = spacing*ones(1,dim); end;

% -----------------------------------------------------------------------------
% identify the grid
Y =Y(:);
if numel(Y) == dim*prod(m),             % cell-centered grid
  mm = m;
elseif numel(Y) == dim*prod(m+1),       % nodal grid
  % the grid is nodal
  mm = m + 1;
elseif numel(Y) == sum(prod(ones(dim,1)*m+eye(dim),2))
  % the grid is staggered and mapped to cell-centered
  Ys = Y; Y = zeros(prod(m),dim);
  e = @(i) (1:dim == i); % i-th unit vector
  ns = cumsum([0;prod(ones(dim,1)*m+eye(dim),2)]);
  for i=1:dim,
    J = [i,setdiff(1:dim,i)];
    % extract i-th component and make i-the drection the first
    yi = permute(reshape(Ys(ns(i)+1:ns(i+1)),m+e(i)),J);
    % average the direction and permute back
    yi = ipermute((yi(1:end-1,:,:)+yi(2:end,:,:))/2,J);
    Y(:,i) = yi(:);
  end;
  mm = m;
else
  error('can not deal with this grid')
end;
% -----------------------------------------------------------------------------

Y = reshape(Y,prod(mm),dim);                % reformatting
y = @(j) reshape(Y(:,j),mm);                % picks the j-th coordinate

isHold = ishold;                            % save current hold status
if ~isHold, cla; end;                       % clear axis
hold on;                                    % hold    

switch dim,
  case 1,
    J1 = 1:spacing(1):mm(1); 
    ph = plot([0,omega(1)],[0,0],'-',Y(J1),0*Y,'o');
  case 2,
    J1 = 1:spacing(1):mm(1); y1 = reshape(y(1),mm);
    J2 = 1:spacing(2):mm(2); y2 = reshape(y(2),mm);
    p1 = plot(y1(:,J2),y2(:,J2));
    p2 = plot(y1(J1,:)',y2(J1,:)');
    ph = [p1;p2];
  case 3,
    p1 = plot3d(y(1),y(2),y(3),mm,[1,2,3],spacing); hold on;
    p2 = plot3d(y(1),y(2),y(3),mm,[2,1,3],spacing);
    p3 = plot3d(y(1),y(2),y(3),mm,[3,1,2],spacing);
    ph = [p1;p2;p3];
    view(3)
end;

if length(color) == 1, color = char(color); end;
set(ph,'color',color,'linewidth',linewidth);

if ~isHold, hold off; end;

if nargout == 1, varargout = {ph}; end;

function ph = plot3d(y1,y2,y3,m,order,s)
m  = m(order);
s  = s(order);
y  = @(y) reshape(permute(y,order),m(1),m(2)*m(3));
y1 = y(y1); y2 = y(y2); y3 = y(y3);
dx = round(m./s);
J2 = 1:s(2):m(2);
J3 = 1:s(3):m(3);
K2 = J2'*ones(1,length(J3));
K3 = ones(length(J2),1)*(m(2)*(J3-1));
K = K2(:)+K3(:);
ph = plot3(y1(:,K),y2(:,K),y3(:,K));

function runMinimalExample
m = [10, 10]; omega = [-1 1 -1 1];
xc = getCellCenteredGrid(omega, m);
yc = xc + .01 * randn(size(xc));
plotGrid(yc,omega,m);
help(mfilename)

%{
    (c) Lars Ruthotto and Jan Modersitzki 2013

    This file is part of HySCO (Version 1.0, 2013/03/28)
                           -  Hyperelastic Susceptibility Artefact Correction for DTI

    
    HySCO is free but copyright software, distributed under the terms of the 
    GNU General Public Licence as published by the Free Software Foundation 
    (Version 3, 29 June 2007) http://www.gnu.org/licenses/gpl.html

 
    This code is provided "as is", without any warranty of any kind, either
    expressed or implied, including but not limited to, any implied warranty
    of merchantibility or fitness for any purpose. In no event will any party
    who distributed the code be liable for damages or for any claim(s) by
    any other party, including but not limited to, any lost profits, lost
    monies, lost data or data rendered inaccurate, losses sustained by
    third parties, or any other special, incidental or consequential damages
    arising out of the use or inability to use the program, even if the
    possibility of such damages has been advised against. The entire risk
    as to the quality, the performace, and the fitness of the program for any
    particular purpose lies with the party using the code.

    This code is especially not intended for any clinical or diagnostic use. 
  
%}