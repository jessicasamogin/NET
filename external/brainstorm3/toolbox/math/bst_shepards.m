function Wmat = bst_shepards(destLoc, srcLoc, nbNeighbors, excludeParam)
% BST_SHEPARDS: 3D nearest-neighbor interpolation using Shepard's weighting.
%
% USAGE:  Wmat = bst_shepards(destLoc, srcLoc, nbNeighbors, excludeParam)
%         Wmat = bst_shepards(destLoc, srcLoc)                            : nbNeighbors = 8, excludeParam = 0
%
% INPUT:
%    - srcLoc       : Nx3 array of original locations, or tesselation structure (Faces,Vertices,VertConn)
%    - destLoc      : NNx3 array of locations onto original data will be interpolated, or tesselation structure (Faces,Vertices,VertConn)
%    - nbNeighbors  : Number of nearest neighbors to be considered in the interpolation (default is 8)
%    - excludeParam : If > 0, the source points that are two far away from the destination surface are ignored.
%                     Excluded points #i that have: (minDist(i) > mean(minDist) + excludeParam * std(minDist))
%                     where minDist represents the minimal distance between each source point and the destination surface
% OUTPUT:
%    - Wmat : Interpolation matrix

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
% Check number of arguments
if (nargin < 2) || (nargin > 4)
    error('Usage: Wmat = bst_shepards(destLoc, srcLoc, nbNeighbors, excludeParam)');
end
% Check matrices orientation
if (size(destLoc, 2) ~= 3) || (size(srcLoc, 2) ~= 3)
    error('destLoc and srcLoc must have 3 columns (X,Y,Z).');
end
% Argument: Number of neighbors for interpolation
if (nargin < 3) || isempty(nbNeighbors)
    nbNeighbors = 8; 
end
% Argument: excludeParam
if (nargin < 4) || isempty(excludeParam)
    excludeParam = 0;
end


%% ===== SHEPARDS INTERPOLATION =====
% Allocate interpolation matrix
nDest = size(destLoc,1);
nSrc  = size(srcLoc,1);
%Wmat  = spalloc(nDest, nSrc, nbNeighbors * nDest);

% Find nearest neighbors
[I,dist] = bst_nearest(srcLoc, destLoc, nbNeighbors, 1);
% Square the distance matrix
dist = dist .^ 2;
% Eliminate zeros in distance matrix for stability
dist(dist == 0) = eps;

% One neighbor
if (nbNeighbors == 1)
    Wmat = sparse(1:nDest, I(:)', ones(1,nDest), nDest, nSrc);

% More complicated cases
elseif (nbNeighbors > 1)
    % Interpolation weights from Shepards method
    W = (bst_bsxfun(@minus, dist(:,nbNeighbors), dist) ./ bst_bsxfun(@times, dist(:,nbNeighbors), dist)) .^ 2;
    sumW = sum(W(:,1:nbNeighbors-1),2);
    % Correct zero values: points overlap exactly => take only the first point
    iZeroW = find(sumW == 0);
    if ~isempty(iZeroW)
        sumW(iZeroW) = 1;
        W(iZeroW, 1:nbNeighbors-1) = ones(length(iZeroW),1) * [1,zeros(1,nbNeighbors-2)];
    end
    W = W(:,1:nbNeighbors-1) ./ (sumW * ones(1,nbNeighbors-1));    
    % Create sparse matrix with those weights
    i = repmat((1:nDest)', nbNeighbors-1, 1);
    j = reshape(I(:, 1:nbNeighbors-1), [], 1);
    Wmat = sparse(i, j, W(:), nDest, nSrc);
end


%% ===== IGNORE VERTICES TOO FAR AWAY =====
% Set to zero the weights of the vertices tht are too far away from the sources
if (excludeParam > 0)
    % Find vertices that are too far from their nearest neighbor
    iTooFarVertices = (dist(:,1) > mean(dist(:,1)) + excludeParam * std(dist(:,1)));
    % Remove them from the interpolation matrix
    Wmat(iTooFarVertices, :) = 0;
end






