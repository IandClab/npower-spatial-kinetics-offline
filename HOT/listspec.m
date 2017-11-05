function varargout = listspec(data, varargin)
%LISTSPEC.M  list the species and data type in the library.
%
%   listspec(data, param1, value1, ...)
%       or
%   [species type setnum index] = listspec(data, param1, value1, ...)
%
%Generates a table summarizing the species present in the library.
%
%data       data library
%
%species    optional argument - cell array of species present
%type       optional argument - cell array containing the string
%           "fit" or "table", identifying the data type of each
%           specie.
%setnum     optional argument - a numeric array identifying which
%           element of the library contains the corresponding data.
%index      optional argument - a numberic array indicating the 
%           specie location in the data set.
%
%LISTSPEC accepts the following parameter-value pairs:
%
%verbose    boolean indicating verbose operation
%sortby     String indicating which of the columns by which to sort.
%           Must be one of "specie", "format", "set", or "none".
%
%
%


verbose = ~nargout;
sortby = 'specie';

% check parameter-value pairs
params = {'verbose--ob', 'sortby--S(specie,format,set,none)'};
values = varargparam(params,varargin{:});

if ~isempty(values{1})
    verbose = values{1};
end
if ~isempty(values{2})
    sortby = values{2};
end

% check for a library
if isstruct(data)
    data = {data};
end
% find the number of data sets in the library
Nset = length(data);
Dset = char(zeros(Nset,5));

% Set up an array of lengths
N = zeros(Nset,1);
if verbose
    fprintf('Checking the library.\n');
end
for libindex = 1:Nset
    if verbose
        fprintf('Data set #%d.\n',libindex);
    end
    % Check the data
    Dset(libindex,:) = jancheck(data{libindex},'verbose',verbose);
    N(libindex) = length(data{libindex});
end

%initialize the outputs
species = cell(sum(N),1);
inlib = zeros(sum(N),1);
dtype = cell(sum(N),1);
index = zeros(sum(N),1);

%
I = 1;
for libindex = 1:Nset
    species(I:I+N(libindex)-1) = {data{libindex}.species};
    inlib(I:I+N(libindex)-1) = libindex*ones(N(libindex),1);
    if Dset(libindex,2)=='f'
        dtype(I:I+N(libindex)-1) = {'fit'};
    else
        dtype(I:I+N(libindex)-1) = {'table'};
    end
    index(I:I+N(libindex)-1) = 1:N(libindex);
    I=I+N(libindex);
end

% sort the fields
if strcmp(sortby,'specie')
    [species I] = sort(species);
    inlib = inlib(I);
    dtype = dtype(I);
    index = index(I);
elseif strcmp(sortby,'format')
    [dtype I] = sort(dtype);
    inlib = inlib(I);
    species = species(I);
    index = index(I);
elseif strcmp(sortby,'set')
    [inlib I] = sort(inlib);
    dtype = dtype(I);
    species = species(I);
    index = index(I);
end

if verbose
    fprintf('%5s%15s%8s%5s |',' ',' ','Data','In');
    fprintf('%5s%15s%8s%5s\n',' ',' ','Data','In');
    fprintf('%5s%15s%8s%5s |','Index','Specie','Type','Set');
    fprintf('%5s%15s%8s%5s\n','Index','Specie','Type','Set');
    for I = 1:70
        fprintf('-');
    end
    fprintf('\n');

    % print the table
    incol = floor(sum(N)/2);
    oddball = isodd(sum(N));
    for I = 1:incol
        fprintf('%5d%15s%8s%5d |',index(I),species{I},dtype{I},inlib(I));
        fprintf('%5d%15s%8s%5d\n',index(I+incol+oddball),species{I+incol+oddball},dtype{I+incol+oddball},inlib(I+incol+oddball));
    end
    if oddball
        fprintf('%5d%15s%8s%5d |',index(incol+1),species{incol+1},dtype{incol+1},inlib(incol+1));
    end
end

% assign the outputs
if nargout>0
    varargout{1} = species;
end
if nargout>1
    varargout{2} = dtype;
end
if nargout>2
    varargout{3} = inlib;
end
if nargout>3
    varargout{4} = index;
end

fprintf('\n\n');
