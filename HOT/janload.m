function varargout = janload(filename, varargin)
%JANLOAD.M
%
%   data = janload('filename', param1, value1, ...)
%       or
%   [data type] = janload('filename', param1, value1, ...)
% 
%   Janload uses the dread utility function to load an ascii 
%file into a struct array.  
%
%JANLOAD accepts the following optional parameter-value 
%pairs:
%
% verbose       Enable verbose operation
%
% sort          Accepts the string name of any field in the
%               data being loaded.  Janload automatically
%               sorts the data by that field (alphabetically
%               if the field contains string data).
%
% check         When true, janload runs jancheck on the data
%               if a second variable is available in the 
%               output, the jancheck type flags will be 
%               written to them.
%
%HOT-tdb release 2.0
%(c) 2007-2009 Christopher R. Martin, Virginia Tech


% DEFAULTS
verbose = 1;
sortfield = '';
check = 1;
% grab the param/value inputs
params = {'sort--so','verbose--bo','check--bo'};
values = varargparam(params,varargin{:});
% assign the param/values
if ~isempty(values{1})
    sortfield = values{1};
end

if ~isempty(values{2})
    verbose = values{2};
end

if ~isempty(values{3})
    check = values{3};
end

if verbose
    fprintf('Loading. This may take a moment...\n');
end
varargout{1} = dread(filename, 'verbose',verbose);

if ~isempty(sortfield)
    if isfield(varargout{1},sortfield)
        if ischar(getfield(varargout{1},{1},sortfield,{1}))
            [dummy, I] = sort({varargout{1}.(sortfield)});
            varargout{1} = varargout{1}(I);
        else
            [dummy, I] = sort([varargout{1}.(sortfield)]);
            varargout{1} = varargout{1}(I);
        end
    else
        warning(['Field ' varargin{1} ' not found.  Not sorting.'])
    end
end

if check
    flags = jancheck(varargout{1},'verbose',verbose);
    if length(varargout)>2
        varargout{2} = flags;
    end
end
