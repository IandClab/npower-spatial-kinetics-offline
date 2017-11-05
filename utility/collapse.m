function done = collapse(structarray, varargin)
%collapse.m
%
%   VACCG dynamic analysis toolbox.
%   Authored by Chris Martin and Joe Ranalli - 3/2008
%
%Collapses arrays of structures into a structure of arrays.
% intended for collapsing the results of dwlanalysis.m into a single struct.
%
%singlestruct = dynoptions(structarray, 'parameter1', value1, ..., 'parametern', valuen)
%=================================
%   structarray     -   an array of struct's.  The structs must have identical fieldnames.
%
%   'parameterk', valuek    -   optional parameter-value pairs specifying how the 
%                               operation is to be performed. (see below)
%==================================
%   singlestruct    -   struct containing the same field names as each element in struct array
%                       each field is now an array containing the same data.
%==================================
%parameter-value pairs:
%   parameter   |   Accepted values |   Description
% --------------+-------------------+---------------------------------------------------------
%   'unify'     |   field name      |   if all values in the specified field in structarray
%               |   (string)        |   have the same value, they will be reduced to a scalar 
%               |                   |   instead of an array.
% --------------+-------------------+---------------------------------------------------------
%   'discard'   |   field name      |   does not include the indicated field name.  This 
%               |   (string)        |   allows the indicated field to be absent in some 
%               |                   |   elements in structarray.
% --------------+-------------------+---------------------------------------------------------
%
%
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech

% error handling
if ~isstruct(structarray)   % check for a structure array
    error('Non-structre vector')
end

% grab the array dimension and shape
S = size(structarray);

% handle the optional arguments
temp = varargparam({'unify','discard'}, varargin{:});
unify = temp{1};
discard = temp{2};

fields = fieldnames(structarray);   % identify the fields
structarray = struct2cell(structarray);    % construct a cell array with the data
                                    % each row corresponds to a field.  each column to a vector element

% find the fields not included in the discard list
if iscell(discard) % handle a list of discard fields
    temp = ones(size(fields));  % array of flags corresponding to the fields (ture = use, false = discard)
	for index = 1:length(discard)   % loop through the discard list
        temp = temp.*(~strcmp(discard{index}, fields)); % if the discard item is found, exclude it from the lsit
	end
elseif ischar(discard) | isempty(discard) % if there is a single discard field
    temp = ~strcmp(discard, fields);
else
    error('Illegal field name specified in ''discard''.  Must be a cell array of strings or a string.')
end
fieldindices = find(temp);  % retrieve the indices of flags that are true
fields = fields(fieldindices);  % cut out the discarded fields
structarray = structarray(fieldindices,:);    % cut out the discarded field data

if ~length(fields)
    error('All fields discarded!')
end
% convert each field cell into an array
for index=1:length(fields)  % loop through the fields
    if ~any(strcmp(fields{index},unify)) % test to see if the current field is in the unify list
        try
            done{index,1} = cat(1,structarray{index,:});        % try to concatinate the arrays as multidimensional arrays
            done{index,1} = squeeze(reshape(done{index,1},[S size(structarray{index,1})]));     % use reshape to retain the array's shape
        catch   % if the concatination failed, then the arrays are not all the same size.  Use structs instead.
            done{index,1} = structarray(index,:);
        end

    elseif isequal(structarray{index,:})    % if  the field IS in the unify list AND it can be unified
        done{index,1} = structarray{index,1};   % unify it
    else
        % if not
        try
            done{index,1} = cat(1,structarray{index,:});        % try to concatinate the arrays as multidimensional arrays
            done{index,1} = squeeze(reshape(done{index,1},[S size(structarray{index,1})]));     % use reshape to retain the array's shape
        catch   % if the concatination failed, then the arrays are not all the same size.  Use structs instead.
            done{index,1} = structarray(index,:);
        end

    end
end

%convert back to struct
done = cell2struct(done,fields,1);