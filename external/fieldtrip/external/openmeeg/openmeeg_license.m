function openmeeg_license

% OPENMEEG_LICENSE prints the license only once upon the first call to this
% function. If the user does a "clear all", the license will again be shown.
% This function should be included in every openmeeg function to ensure
% that the license is displayed at least once.

% Copyright (C) 2009, Robert Oostenveld

persistent status

if isempty(status)
  % this is for the first time
  status = false;
end

if ~status
  % show the license
  try
    tmp = which('openmeeg_license');
  catch
    tmp = mfilename; 
  end
  [p, f] = fileparts(tmp);
  clc
  fprintf('==============================================================================\n');
  type(fullfile(p, 'LICENSE'));
  fprintf('==============================================================================\n');
  % remember that it has been shown
  status = true;
  pause(3)
end

