function install(varargin)
%INSTALL  adds the current dirrectory to the Matlab search path
%
%       traditional
%   install(options, dirpath)
%       or unix-style
%   install options dirpath
%
%Valid options include
%
%r  -   recursive: decend into subdirectories and add them to 
%       the path as well.
%
%d  -   specify directory manually: checks dirpath argument for 
%       a string specifying the directory to be added.
%
%EX:
%>>install
%adds the curent directory only to the search path.
%
%>>install rd \usr\share\octave\3.0.1\m
%adds everything in the m directory to the search path including
%all subdirectories.  For a windows system, this might appear
%>>install rd C:\programs\MATLAB_R14\work
%
%>>install r
%add the current directory and all subdirectories to the search path
%
%See also: 
%   uinstall
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech


if nargin
    % look for unix-style parameters

    % spec'd path
    if any(varargin{1}=='d')
        if length(varargin)>1
            D = varargin{2};
        else
            error('d flag was set, but no path was specified. Type "help install".')
        end
    else
        D = pwd;
    end
    
    % recursive
    if any(varargin{1}=='r')
        D = genpath(D);
    end

% DEFAULTS
else
    D = pwd;
end


addpath(D);


try
	if exist('savepath')==2
        savepath;
	else
        path2rc;
	end
catch
    error('Failed to write to the Matlab search path')
end

fprintf('Successfully added: \n')

fprintf('%s\n', D)

