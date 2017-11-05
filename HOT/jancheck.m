function flags = jancheck(data, varargin)
%JANCHECK.M  test HOT data for compatibility with high-level functions
%
%   flags = jancheck(data, param1, value1, ...);
%
%data       janaf data structure array
%
%flags      string of characters describing the data format
%1) check success/failure
%           'p' (p)assed. The data is properly formated.
%           'f' (f)ailed. The data has at least one error.
%               Run verbosely to find out what's wrong.
%
%2) format/type
%           'f' (f)it. The data specifies curve fits.
%           't' (t)abular. The data is in a lookup table.
%           'n' (n)one determined.
%
%3) enthalpy computed from
%           'e' (e)xplicitly. Enthalpy is given explicitly.
%           'i' (i)mplicitly. Enthalpy must be computed from cp.
%           'n' enthalpy is (n)ot specified.
%
%4) entropy computed from
%           same as (3)
%
%5) specific heat computed from
%           'e' (e)xplicitly.
%           'i' (i)mplicitly. Specific heat must be computed from h.
%           'n' specific heat is (n)ot specified
%
%JANCHECK accepts the following parameter-value pairs:
% verbose    accepts either 1 or 0 to indicate a verbose or quiet output
%
% 
%HOT-tdb release 2.0
%(c) 2007-2009 Christopher R. Martin, Virginia Tech

verbose = 1;
flags = 'pnnnn';

params = {'verbose--bo'};
values = varargparam(params, varargin{:});

if ~isempty(values{1})
    verbose = values{1};
end

fields = fieldnames(data);
N = numel(data);

% print basic statistics
if verbose
    fprintf('Found %d data elements with fields:', N);
    fprintf(' "%s",',fields{1:end-1});
    fprintf(' "%s".\n',fields{end});
end

% field flags
% species names
species = any(strcmp('species',fields));
% molecular weight
MW = any(strcmp('MW',fields));
% enthalpy of formation
hf = any(strcmp('hf',fields));
%reference entropy
sref = any(strcmp('sref',fields));
% temperature
T = any(strcmp('T',fields));
% enthalpy table
h = any(strcmp('h',fields));
% entropy table
s = any(strcmp('s',fields));
% specific heat
cp = any(strcmp('cp',fields));
% specific heat fit coefficients
C = any(strcmp('C',fields));
% fit function specifier
F = any(strcmp('F',fields));
if verbose
    fprintf('Checking mandatory fields...');
end
% first, check fields that must ALWAYS be present
if ~MW
    flags(1) = 'f';
    if verbose
        fprintf('FAILED\nFailed to find molecular weight field, "MW".\n');
    end
elseif ~species
    flags(1) = 'f';
    if verbose
        fprintf('FAILED\nFailed to find species identifier field "species".\n');
    end
elseif ~T
    flags(1) = 'f';
    if verbose
        fprintf('FAILED\nFailed to find temperature field "T".\n');
    end
else
    flags(1) = 'p';
    if verbose
        fprintf('success.\n');
    end
end

% if C and F exist and cp, h, and s don't, then it's a specific heat fit function
if (C & F) & ~(cp | h | s)
    flags(2) = 'f';
    flags(3) = 'i';
    flags(4) = 'i';
    flags(5) = 'e';
    if verbose
        fprintf('Found curve fit data.\n');
    end
    
    if ~sref
        flags(1) = 'f';
        if verbose
            fprintf('Missing reference entropy field, "sref".\n');
        end
    elseif ~hf
        flags(1) = 'f';
        if verbose
            fprintf('Missing enthalpy of formation field, "hf".\n');
        end
    end
% if h and s exist and C and F don't, then it's tabular data
elseif ~(C | F) & (h & s)
    flags(2) = 't';
    flags(3) = 'e';
    flags(4) = 'e';
    
    if verbose
        fprintf('Found tabular data.\n');
    end
    if cp
        if verbose
            fprintf('Found explicit "cp" data.\n');
        end
        flags(5) = 'e';
    else
        flags(5) = 'i';
    end
% if fields are missing or some mix of the two above cases, then quit.
% without positively identifying the data type, it's impossible to test the data.
else
    flags(2) = 'n';
    if verbose
        fprintf('FAILURE to identify data format.\nFit data should have both "F" and "C" fields.\n');
        fprintf('Tabular data should have "h", "s", and possibly "cp".\nMixing is not allowed.\n');
    end
    return
end

if flags(1)=='f'
    if verbose
        fprintf('Not checking data elements.\nRepair the above problems first.\n')
    end
    return;
end
if verbose
    fprintf('Checking data elements');
end

out = '';
for I = 1:N
    
    if verbose
        fprintf('.');
    end

    % check field data types
    % species
    if ~ischar(data(I).species)
        flags(1) = 'f';
        if verbose
            out = sprintf('%s\n Non-string "species" field.  [#%d]',out,I);
            
        end
        name = '';
    else
        name = data(I).species;
    end
    % MW
    if ~isnumeric(data(I).MW) | size(data(I).MW)~=[1 1]
        flags(1) = 'f';
        if verbose
            out = sprintf('%s\n Non-scalar "MW" field.  [#%d, %s]',out,I,name);
            
        end
    end
    % T
    if ~isnumeric(data(I).T)
        flags(1) = 'f';
        if verbose
            fprintf('\n Non-numeric "T" field.  [#%d, %s]',out,out,I,name);
            
        end
    end
    % get the size of the temperature vector
    NT = numel(data(I).T);
    
    
    % test that the temperature vector is increasing monotonically
    if ~all(T(2:end)>T(1:end-1))
        flags(1) = 'f';
        if verbose
            out = sprintf('%s\n Non-monotonic T vector.  [#%d, %s]',out,I,name);
            
        end 
    end
    
    % on to the format-dependent stuff
    if flags(2) == 't'
        
        % h
        if ~isnumeric(data(I).h)
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n Non-numeric "h" field.  [#%d, %s]',out,I,name);
                
            end
        % test h-vector length
        elseif numel(data(I).h) ~= NT
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n  h-T vector size missmatch.  [#%d, %s]',out,I,name);
                
            end
        end
        
        % s
        if ~isnumeric(data(I).s)
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n Non-numeric "s" field.  [#%d, %s]',out,I,name);
                
            end
        % test s-vector length
        elseif numel(data(I).s) ~= NT
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n s-T vector size missmatch.  [#%d, %s]',out,I,name);
                
            end
        end
        
        if cp
            % cp
            if ~isnumeric(data(I).cp)
                flags(1) = 'f';
                if verbose
                    out = sprintf('%s\n Non-numeric "h" field.  [#%d, %s]',out,I,name);
                    
                end
            % test cp-vector length
            elseif numel(data(I).h) ~= NT
                flags(1) = 'f';
                if verbose
                    out = sprintf('%s\n h-T vector size missmatch.  [#%d, %s]',out,I,name);
                    
                end
            end
        end
    % check fit coefficient data        
    else
        % C
        if ~isnumeric(data(I).C)
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n Non-numeric "C" field.  [#%d, %s]',out,I,name);
                
            end
        % test s-vector length
        elseif size(data(I).C,2) ~= NT
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n C-T missmatch.  Columns in C must match T.  [#%d, %s]',out,I,name);
                
            end
        end
        % F
        if ~isnumeric(data(I).F)
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n Non-numeric "F" field.  [#%d, %s]',out,I,name);
                
            end
        
        % test s-vector length
        elseif size(data(I).C,1) ~= numel(data(I).F)
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n C-F missmatch.  Rows in C must match F.  [#%d, %s]',out,I,name);
                
            end
        end
        % hf
        if ~isnumeric(data(I).hf) | size(data(I).hf)~=[1 1]
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n Non-scalar "hf" field.  [#%d, %s]',out,I,name);

            end
        end
        % sref
        if ~isnumeric(data(I).sref) | size(data(I).hf)~=[1 1]
            flags(1) = 'f';
            if verbose
                out = sprintf('%s\n Non-scalar "sref" field.  [#%d, %s]',out,I,name);

            end
        end
    end
    
end
if verbose
    if isempty(out)
        out = 'No errors.';
    end
    fprintf('%s\ndone.\n',out)
end
