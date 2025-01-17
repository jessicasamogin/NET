function [pout, vout, viout, facevout, faceiout]  = select3d(obj, cp)
%SELECT3D(H) Determines the selected point in 3-D data space.
%  P = SELECT3D determines the point, P, in data space corresponding 
%  to the current selection position. P is a point on the first 
%  patch or surface face intersected along the selection ray. If no 
%  face is encountered along the selection ray, P returns empty.
%
%  P = SELECT3D(H) constrains selection to graphics handle H and,
%  if applicable, any of its children. H can be a figure, axes, 
%  patch, or surface object.
%
%  [P V] = SELECT3D(...), V is the closest face or line vertex 
%  selected based on the figure's current object. 
%
%  [P V VI] = SELECT3D(...), VI is the index into the object's 
%  x,y,zdata properties corresponding to V, the closest face vertex 
%  selected.
%
%  [P V VI FACEV] = SELECT3D(...), FACE is an array of vertices 
%  corresponding to the face polygon containing P and V. 
%  
%  [P V VI FACEV FACEI] = SELECT3D(...), FACEI is the row index into 
%  the object's face array corresponding to FACE. For patch 
%  objects, the face array can be obtained by doing 
%  get(mypatch,'faces'). For surface objects, the face array 
%  can be obtained from the output of SURF2PATCH (see 
%  SURF2PATCH for more information).
%
%  RESTRICTIONS:
%  SELECT3D supports surface, patch, or line object primitives. For surface 
%  and patches, the algorithm assumes non-self-intersecting planar faces. 
%  For line objects, the algorithm always returns P as empty, and V will
%  be the closest vertex relative to the selection point. 
%
%  Example:
%
%  h = surf(peaks);
%  zoom(10);
%  disp('Click anywhere on the surface, then hit return')
%  pause
%  [p v vi face facei] = select3d;
%  marker1 = line('xdata',p(1),'ydata',p(2),'zdata',p(3),'marker','o',...
%                 'erasemode','xor','markerfacecolor','k');
%  marker2 = line('xdata',v(1),'ydata',v(2),'zdata',v(3),'marker','o',...
%                 'erasemode','xor','markerfacecolor','k');
%  marker2 = line('erasemode','xor','xdata',face(1,:),'ydata',face(2,:),...
%                 'zdata',face(3,:),'linewidth',10);
%  disp(sprintf('\nYou clicked at\nX: %.2f\nY: %.2f\nZ: %.2f',p(1),p(2),p(3)'))
%  disp(sprintf('\nThe nearest vertex is\nX: %.2f\nY: %.2f\nZ: %.2f',v(1),v(2),v(3)'))
% 
%  Version 1.3 11-11-04
%  Copyright Joe Conti 2004 
%  Send comments to jconti@mathworks.com
%
%  See also GINPUT, GCO.

% ===== MODIFIED BY FRANCOIS TADEL 28-Jul-2008 =====
% - Ignore hidden vertices
% ==================================================

% Output variables
pout = [];
vout = [];
viout = [];
facevout = [];
faceiout = [];

% other variables
ERRMSG = 'Input argument must be a valid graphics handle';
isline = logical(0);
isperspective = logical(0);

% Parse input arguments
if (nargin<1)
   obj = gco;
end

if isempty(obj) | ~ishandle(obj) | length(obj)~=1
    error(ERRMSG);
end

% if obj is a figure
if strcmp(get(obj,'type'),'figure')
    fig = obj;
    ax = get(fig,'currentobject');
    currobj = get(fig,'currentobject');
    
    % bail out if not a child of the axes
    if ~strcmp(get(get(currobj,'parent'),'type'),'axes')
        return;
    end
    
% if obj is an axes
elseif strcmp(get(obj,'type'),'axes')
    ax = obj;
    fig = get(ax,'parent');
    currobj = get(fig,'currentobject');
    currax = get(currobj,'parent');
    
    % Bail out if current object is under an unspecified axes
    if ~isequal(ax,currax)
        return;
    end

% if obj is child of axes    
elseif strcmp(get(get(obj,'parent'),'type'),'axes')
    currobj = obj;
    ax = get(obj,'parent');
    fig = get(ax,'parent');
    
% Bail out
else 
    return
end

axchild = currobj;
obj_type = get(axchild,'type');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Get vertex, face, and current point data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% If surface object
if strcmp(obj_type,'surface')
    % Get surface face and vertices
    fv = surf2patch(axchild);
    vert = fv.vertices;
    faces = fv.faces;
    
% If patch object
elseif strcmp(obj_type,'patch')
    vert = get(axchild,'vertices');
    faces = get(axchild,'faces');
    
    % ===== REMOVE HIDDEN FACES (FT 27/07/08 and 26Oct12) =====
    % Get alpha data
    FaceAlphaData = get(axchild, 'FaceVertexAlphaData');
    % One alpha value only
    if (length(FaceAlphaData) == 1) && (FaceAlphaData == 0)
        % No vertices are visible => return
        return;
    % One alpha value per face
    elseif (length(FaceAlphaData) == length(faces))
        % Remove faces that are not visible
        faces(FaceAlphaData == 0, :) = [];
    end
    % ===============================================================
    
% If line object     
elseif strcmp(obj_type,'line')
    xdata = get(axchild,'xdata');
    ydata = get(axchild,'ydata');
    zdata = get(axchild,'zdata');
    vert = [xdata', ydata',zdata'];
    faces = []; 
    isline = logical(1);

% Ignore all other objects
else     
   return;
end

% Get current point
if (nargin<2) || isempty(cp)
    cp = get(ax,'currentpoint');
end
cp = cp';
    
% Add z if empty
if size(vert,2)==2
   vert(:,3) = zeros(size(vert(:,2)));
   if isline
       zdata = vert(:,3);
   end
end

% NaN and Inf check 
nan_inf_test1 = isnan(faces) | isinf(faces);
nan_inf_test2 = isnan(vert) | isinf(vert);
if any(nan_inf_test1(:)) | any(nan_inf_test2(:))
    warning(sprintf('%s does not support NaNs or Infs in face/vertex data.',mfilename));
end

% For debugging
% if 0    
%     ax1 = getappdata(ax,'testselect3d');
%     if isempty(ax1) | ~ishandle(ax1)
%         fig = figure; 
%         ax1 = axes;
%         axis(ax1,'equal');
%         setappdata(ax,'testselect3d',ax1);
%     end
%     cla(ax1);
%     patch('parent',ax1,'faces',faces,'vertices',xvert','facecolor','none','edgecolor','k'); 
%     line('parent',ax1,'xdata',xcp(1,2),'ydata',xcp(2,2),'zdata',0,'marker','o','markerfacecolor','r','erasemode','xor');
% end

% Transform vertices from data space to pixel space
xvert = local_Data2PixelTransform(ax,vert)';
xcp = local_Data2PixelTransform(ax,cp')';

% Translate vertices so that the selection point is at the origin.
xvert(1,:) = xvert(1,:) - xcp(1,2);
xvert(2,:) = xvert(2,:) - xcp(2,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% simple algorithm (almost naive algorithm!) for line objects %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isline

    % Ignoring line width and marker attributes, find closest 
    % vertex in 2-D view space.
    d = xvert(1,:).*xvert(1,:) + xvert(2,:).*xvert(2,:);
    [val i] = min(d);
    i = i(1); % enforce only one output
    
    % Assign output
    vout = [ xdata(i) ydata(i) zdata(i)];
    viout = i;
    
    return % Bail out early
end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Perform 2-D crossing test (Jordan Curve Theorem) %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find all vertices that have y components less than zero
vert_with_negative_y = zeros(size(faces));
face_y_vert = xvert(2,faces);
ind_vert_with_negative_y = find(face_y_vert<0); 
vert_with_negative_y(ind_vert_with_negative_y) = logical(1);

% Find all the line segments that span the x axis
is_line_segment_spanning_x = abs(diff([vert_with_negative_y, vert_with_negative_y(:,1)],1,2));

% Find all the faces that have line segments that span the x axis
ind_is_face_spanning_x = find(any(is_line_segment_spanning_x,2));

% Ignore data that doesn't span the x axis
candidate_faces = faces(ind_is_face_spanning_x,:);
vert_with_negative_y = vert_with_negative_y(ind_is_face_spanning_x,:);
is_line_segment_spanning_x = is_line_segment_spanning_x(ind_is_face_spanning_x,:);

% Create line segment arrays
pt1 = candidate_faces;
pt2 = [candidate_faces(:,2:end), candidate_faces(:,1)];

% Point 1
x1 = reshape(xvert(1,pt1),size(pt1));
y1 = reshape(xvert(2,pt1),size(pt1));

% Point 2
x2 = reshape(xvert(1,pt2),size(pt2));
y2 = reshape(xvert(2,pt2),size(pt2));

% Cross product of vector to origin with line segment
cross_product_test = -x1.*(y2-y1) > -y1.*(x2-x1);

% Find all line segments that cross the positive x axis
crossing_test = (cross_product_test==vert_with_negative_y) & is_line_segment_spanning_x;

% If the number of line segments is odd, then we intersected the polygon
s = sum(crossing_test,2);
s = mod(s,2);
ind_intersection_test = find(s~=0);

% Bail out early if no faces were hit
if isempty(ind_intersection_test)
   return;    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plane/ray intersection test %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform plane/ray intersection with the faces that passed 
% the polygon intersection tests. Grab the only the first 
% three vertices since that is all we need to define a plane).
% assuming planar polygons.
candidate_faces = candidate_faces(ind_intersection_test,1:3);
candidate_faces = reshape(candidate_faces',1,prod(size(candidate_faces)));
vert = vert';
candidate_facev = vert(:,candidate_faces);
candidate_facev = reshape(candidate_facev,3,3,length(ind_intersection_test));

% Get three contiguous vertices along polygon 
v1 = squeeze(candidate_facev(:,1,:));
v2 = squeeze(candidate_facev(:,2,:));
v3 = squeeze(candidate_facev(:,3,:));

% Get normal to face plane
vec1 = [v2-v1];
vec2 = [v3-v2];
crs = cross(vec1,vec2);
mag = sqrt(sum(crs.*crs));
nplane(1,:) = crs(1,:)./mag;
nplane(2,:) = crs(2,:)./mag;
nplane(3,:) = crs(3,:)./mag;

% Compute intersection between plane and ray
cp1 = cp(:,1);  
cp2 = cp(:,2);  
d = cp2-cp1;
dp = dot(-nplane,v1);

%A = dot(nplane,d);
A(1,:) = nplane(1,:).*d(1);
A(2,:) = nplane(2,:).*d(2);
A(3,:) = nplane(3,:).*d(3);
A = sum(A,1);

%B = dot(nplane,pt1) 
B(1,:) = nplane(1,:).*cp1(1);
B(2,:) = nplane(2,:).*cp1(2);
B(3,:) = nplane(3,:).*cp1(3);
B = sum(B,1);

% Distance to intersection point
t = (-dp-B)./A;

% Find "best" distance (smallest)
[tbest ind_best] = min(t);

% Determine intersection point
pout = cp1 + tbest .* d;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Assign additional output variables %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargout>1
    
    % Get face index and vertices
    faceiout = ind_is_face_spanning_x(ind_intersection_test(ind_best));
    facevout = vert(:,faces(faceiout,:));
    
    % Determine index of closest face vertex intersected 
    facexv = xvert(:,faces(faceiout,:));
    dist = sqrt(facexv(1,:).*facexv(1,:) +  facexv(2,:).*facexv(2,:));
    min_dist = min(dist);
    min_index = find(dist==min_dist);
    
    % Get closest vertex index and vertex
    viout = faces(faceiout,min_index);
    vout = vert(:,viout);
end

%--------------------------------------------------------%
function [p] = local_Data2PixelTransform(ax,vert)
% Transform vertices from data space to pixel space.

% Get needed transforms
xform = get(ax,'x_RenderTransform');
offset = get(ax,'x_RenderOffset');
scale = get(ax,'x_RenderScale');

% Equivalent: nvert = vert/scale - offset;
nvert(:,1) = vert(:,1)./scale(1) - offset(1);
nvert(:,2) = vert(:,2)./scale(2) - offset(2);
nvert(:,3) = vert(:,3)./scale(3) - offset(3);

% Equivalent xvert = xform*xvert;
w = xform(4,1) * nvert(:,1) + xform(4,2) * nvert(:,2) + xform(4,3) * nvert(:,3) + xform(4,4);
xvert(:,1) = xform(1,1) * nvert(:,1) + xform(1,2) * nvert(:,2) + xform(1,3) * nvert(:,3) + xform(1,4);
xvert(:,2) = xform(2,1) * nvert(:,1) + xform(2,2) * nvert(:,2) + xform(2,3) * nvert(:,3) + xform(2,4);

% w may be 0 for perspective plots 
ind = find(w==0);
w(ind) = 1; % avoid divide by zero warning
xvert(ind,:) = 0; % set pixel to 0

p(:,1) = xvert(:,1) ./ w;
p(:,2) = xvert(:,2) ./ w;
