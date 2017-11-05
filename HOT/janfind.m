function indices = janfind(data, namefield, names)
%JANFIND  find entries in a janaf library
%
%   index = janfind(data, 'namefield', names)
%
%given the cell array strings in name, JANFIND
%returns indices such that
%   data(index(k)).namefield = names{k}
%
%JANFIND also accepts a single string for the 
%names variable
%
%JANFIND will return an error if there are 
%multiple instances of one of the name strings
%
% 
%HOT-tdb release 2.0
%(c) 2007-2009 Christopher R. Martin, Virginia Tech

if iscell(names)
    N = length(names);
    indices = zeros(N,1);
    for index = 1:N    
        eval(['temp = find(strcmp({data.' namefield '}, names{index}));'])
        if length(temp)>1
            error(['Found multiple instances where data.' namefield ' = ' names{index}])
        end
        indices(index) = temp;
    end
elseif ischar(names)
    eval(['indices = find(strcmp({data.' namefield '}, names));'])
    if length(indices)>1
        warning(['Found multiple instances where data.' namefield ' = ' names{index}])
    end
else
    error('Illegal names specifier.')
end
