function uinstall(varargin)
%UINSTALL   remove current dirrectory from the search path
%
%       traditional
%   uinstall(options, dirpath)
%       or unix-style
%   uinstall options dirpath
%
%Valid options include
%
%r  -   recursive: decend into subdirectories and remove them from 
%       the path as well.
%
%d  -   specify directory manually: checks dirpath argument for 
%       a string specifying the directory to be removed.
%
%Operates identicaly to install.  
%
%See also:
%   install

if nargin    % look for unix-style parameters    
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
else    
    D = pwd;
end

rmpath(D);

try
    if exist('savepath')==2
        savepath
    else    
        path2rc
    end
catch
    error('Failed to write to the search path.')
end
fprintf('Successfully removed:\n%s\n', D);
