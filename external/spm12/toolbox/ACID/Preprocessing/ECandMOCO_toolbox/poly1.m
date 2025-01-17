function [fit1] = poly1(y,x,steps,resMax)
% linear fit of N two dimensional points
% resMax = maxValueOfx - max(x)
% S. Mohammadi 07/02/2012
% Modification:
% - the second slice up to the one before last slice is interpolated

xx      = x(1):steps:x(length(x))+resMax;
dsteps  = round(size(xx,2)/size(x,2));
fit1    = zeros(1,size(xx,2));
% fit1(1)  = y(2); % mod
for i=1:size(x,2)-1,
    %using linear function: f(x) = m*x+b
    m               = (y(i+1)-y(i))/(x(i+1)-x(i));
    b               = y(i) - m*x(i);
    fit1(dsteps*(i-1)+1)  = y(i);
    for j=1:dsteps-1,
        fit1(dsteps*(i-1)+j+1)  = m*xx(dsteps*(i-1)+j+1)+b;
    end
end
% m               = (y(size(x,2))-y(size(x,2)-1))/(x(size(x,2))-x(size(x,2)-1));
fit1(dsteps*(size(x,2)-1)+1)  = y(size(x,2));
for i=1:round(resMax/steps),
    fit1(dsteps*(size(x,2)-1)+1+i)  = m*xx(dsteps*(size(x,2)-1)+1+i)+b;
end
return;

% cc1     = [y(2) y(1)]; 
% cc2     = [y(3) y(2)]; 
% cc3     = [y(4) y(3)]; 
% cc4     = [y(5) y(4)]; 
% cc5     = [y(6) y(5)]; 
% cc6     = [y(7) y(6)]; 
% cc7     = [y(8) y(7)]; 
% cc8     = [y(9) y(8)]; 
% cc9     = [y(10) y(9)]; 
% cc10    = [y(11) y(10)]; 
% cc11    = [y(12) y(11)]; 
% ppAll   = mkpp(x,[cc1;cc2;cc3;cc4;cc5;cc6;cc7;cc8;cc9;cc10;cc11]);
% for i=1:size(y,2)-1,
%     cc(i,2) = y(size(y,2)-i+1);
%     cc(i,1) = y(size(y,2)-i);
% end
% ppAll   = mkpp(x,cc)
% %keyboard
% fit12   = ppval(ppAll,x);
