function done = varargparam(param, varargin)
%varargparam.m v2.0  parses parameter-value pairs
%
%   written by Chris Martin 3/2008
%	updated 2/2009	- added error checking and support for repeated arguments
%			  added configurable parameter options
%			  checked for octave compatibility
%
%   support function...
%   parses string-parameter pair arguments
%
%value = varargparam(paramstring, varargin{:})
%===================================================
%   paramstring -   string or cell array of strings corresponding to the desired parameter
%
%   varargin{:} -   optional parameter, value pair cell array
%                   typically entered in the form
%       function(required1, ... requiredN, 'paramstring1', value1, ..., 'paramstrinM', valueM)
%                   the function catches the optional parameter-value pairs with varargin{:}
%
%===================================================
%   done        -   the value corresponding to paramstring
%                   or cell array of values corresponding to the cell array, paramstring
%
%==================================================
% To specify non-default settings, add '--' to the appropriate parameter 
%string, followed by the following options:
%
%	a,b,c,d,i,s	- type specifiers.  varargparam will attempt to force conversions.
%			  If the conversion fails, it will exit with an error.
%		a) any (Default)
%		b) boolean
%		c) complex
%		d) double
%		i) int
%		s) string
%
%	C,A,V,M,U	- s(C)alar, (A)rray (row), (V)ector (column), (M)atrix, 
%			  (U)nspecified (Default)
%
%	S()		- string parameters.  Explicitly defined list of acceptable string
%			  parameters.  The values should appear as a comma-separated list.
%		          If no parentheses are encountered, then varargin will accept any string.
%
%   L       - a comma separated list.  Constructs a cell aray of strings parsed
%             from the passed argument.  Whitespaces WILL be included in the returned
%             strings.
%
%	o,m		- allow only (o)ne (default) or (m)ultiple instances of each parameter
%
%	f,u		- (f)riendly or (u)nfriendly (Default).  Unfriendly will issue an error 
%			  if the above options are not met.  Friendly will only issue a warning.
%
%EX:
%	param = {'length--iS', 'name--so', 'type--S(float,char,int)'}
%
% looks for a parameter named 'length' with a 1x1 integer, a parameter named 'name' that may
%appear only once and must be a string, and a parameter named 'type' which can contain one of
%three strings; 'float','char',or 'int'.
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech


% check parameter array.  Must be a cell array of strings or a single string.
if iscell(param)
	N = numel(param);
elseif ischar(param)
	N = 1;
	param = {param};
else
	error('invalid parameter set.  Must be a cell array of strings or a single string.')
end



% create an array of flags to keep track of which parameters and values have been parsed.
% the flag will be set to zero once the element has been successfully parsed.
FLAG = ones(size(varargin(:)));

% initialize the done cell array
done = cell(size(param));

% loop through the parameter array
for I = 1:N
	% check to be sure the currentparameter is a string
	if ~ischar(param{I})
		error(['Parameter ' num2str(I) ' is not a string.'])
	end


	% look for the parameter options
	J = findstr(param{I},'--');
	if numel(J)>1
		error(['Encountered multiple ''--'' in parameter, ''' param{I} '''.'])
	elseif numel(J) == 0
		currentparam = param{I};
		currentoptions = '';
	else
		currentparam = param{I}(1:J-1);
		currentoptions = param{I}(J+2:end);
	end
	
	% set up the option defaults
	type = 'a';
	dims = 'U';
	S = {};
    Lflag = 0;
	multiple = 0;
	friendly = 0;


	% if there are options specified
	if ~isempty(currentoptions)
		% parse the options string
		% scan the options string
		J=1;
		while J<=length(currentoptions)
			if any(currentoptions(J)=='abcdis')
				type = currentoptions(J);
			elseif any(currentoptions(J)=='CAVMU')
				dims = currentoptions(J);
			elseif any(currentoptions(J)=='om')
				multiple = (currentoptions(J)=='m');
			elseif any(currentoptions(J)=='fu')
				friendly = (currentoptions(J)=='f');
			elseif currentoptions(J)=='S'
				type = 's';
				% if the 'S' isn't at the end of the string
				if J<length(currentoptions)
					% if there is a '(' character next
					if currentoptions(J+1)=='('
						% look for a ')' character
						K = min(findstr(currentoptions(J+2:end),')'));
						% if there isn't one, exit with an error.
						if isempty(K)
							error('Missing '')''')
						end
						% isolate the string argument
						temp = currentoptions(J+2:J+K);
						W = [0 findstr(temp,',') length(temp)+1]; % find the commas and add the ends
						S = cell(1,length(W)-1);
						for L = 1:length(W)-1
							S{L} = temp(W(L)+1:W(L+1)-1);
						end
						J=J+K+1;
					end
				end
            elseif currentoptions(J)=='L'
                type = 's';
                Lflag = 1;
			else
				error(['Unrecognized options character, ' currentoptions(J)])
			end
			J=J+1;
		end
	end
	% Search for the current parameter in varargin
	J = find(strcmp(varargin(:), currentparam));
	J = J(find(isodd(J))); % eliminate the values - keep it to the parameters
	% if we find anything...
	if ~isempty(J)
		if any(J==length(varargin))
			error('Parameter with no matching value.')
		end
		
		% clear the corresponding flags
		FLAG(J) = 0; FLAG(J+1) = 0;

		% deal with single-value case
		if ~multiple
			% check to be sure only one value is specified
			if numel(J)>1 & friendly
				warning(['Encountered multiple declarations for ' currentparam '.  Using the first.'])
				J = min(J);
			elseif numel(J)>1
				error(['Encountered multiple declarations for ' currentparam '.'])
			end
			
			% check the content of varargin{J+1}
			if type == 'a'
				done{I} = varargin{J+1};
			elseif type=='b'
				done{I} = ~ varargin{J+1}==0;
			elseif type=='c'
				if isnumeric(varargin{J+1})
					done{I} = varargin{J+1};
				elseif friendly
					warning(['Type mismatch: ' varargin{J} ', ' varargin{J+1}])
				else
					error(['Type mismatch: ' varargin{J} ', ' varargin{J+1}])
				end
			elseif type=='d'
				if isreal(varargin{J+1})
					done{I} = varargin{J+1};
				elseif friendly
					warning(['Type mismatch: ' varargin{J} ', ' varargin{J+1}])
				else
					error(['Type mismatch: ' varargin{J} ', ' varargin{J+1}])
				end
			elseif type=='i'
				done{I} = floor(varargin{J+1});
			elseif type=='s'
				if ischar(varargin{J+1}) & isempty(S)
					done{I} = varargin{J+1};
				elseif ischar(varargin{J+1}) & any(strcmp(varargin{J+1},S))
					done{I} = varargin{J+1};
				elseif friendly
					warning(['Argument is not in the set of expected strings for ' param{I} '.'])
				else
					error(['Argument is not in the set of expected strings for ' param{I} '.'])
				end
                if Lflag
                    done{I} = mparses(done{I},'%r{%[^,],}%s');
                end
			end

			temp = size(done{I});
			if dims=='U'
			elseif dims == 'C' & prod(temp)==1
			elseif dims == 'A' & prod(temp)==temp(2)
			elseif dims == 'V' & prod(temp)==temp(1)
			elseif dims == 'M' & prod(temp)==temp(1)*temp(2)
			elseif friendly
				warning(['Improper dimensions for ' currentparam '.'])
			else
				error(['Improper dimensions for ' currentparam '.'])
			end
			
		% deal with multiple entries
		% this is pretty much the same as the single entries, only with embedded cell arrays
		else
			if type == 'a'
				done{I} = varargin(J+1);
			elseif type == 'b'
				done{I} = cell(1,length(J));
				for K = 1:length(J)
					done{I}{K} = ~(varargin{J(K)+1}==0);
				end
			elseif type == 'c'
				K = cellfun(@isnumeric, varargin(J+1));
				if all(K)
					done{I} = varargin(J+1);
				elseif friendly
					done{I} = varargin(J(find(K))+1);
					warning(['Non-numeric inputs for ' param{I} ' ignored.'])
				else
					error(['Non-numeric inputs for ' param{I} '.'])
				end
			elseif type == 'd'
				K = cellfun('isreal', varargin(J+1))
				% if all elements are real numbers
				if all(K)
					done{I} = varargin(J+1);
				elseif friendly
					done{I} = varargin(J(find(K))+1);
					warning(['Non-real input for ' param{I} ' ignored.'])
				else
					error(['Non-real input for ' param{I} '.'])
				end
			elseif type == 'i'
				done{I} = cell(1,length(J));
				for K=1:length(J)
					done{I}{K} = floor(varargin{J(K)+1});
				end
			elseif type == 's'
				K = cellfun(@ischar,varargin(J+1));
				if all(K)
					% do nothing
				elseif friendly
					J = J(find(K));
					warning(['Non-string input(s) for ' param{I} ' ignored.'])
				else
					error(['Non-string input(s) for ' param{I} '.'])
				end
				
                if Lflag
                    done{I} = {};
					for K = 1:length(J)
                        temp = mparses(varargin{J(K)+1},'%r{%[^,],}%s');
						done{I} = {done{I}{:} temp{:}};
					end
				elseif ~isempty(S)
					done{I} = {};
					for K = 1:length(J)
						if any(strcmp(varargin{J(K)+1},S))
							done{I} = {done{I}{:} varargin{J(K)+1}};
						elseif friendly
							warning([varargin{J(K)+1} ' is not in the expected set of strings for ' param{I} '.'])
						else
							error([varargin{J(K)+1} ' is not in the expected set of strings for ' param{I} '.'])
						end
					end
                else
   					done{I} = varargin(J+1);
				end
			end

			% check matrix/vector/array/scalar agreement
			for J=1:length(done{I})
				temp = size(done{I}{J});
				if dims == 'U'
				elseif dims == 'C' &  prod(temp)==1
				elseif dims == 'A' & prod(temp)==temp(2)
				elseif dims == 'V' & prod(temp)==temp(1)
				elseif dims == 'M' & prod(temp)==temp(1)*temp(2)
				elseif friendly
					warning(['Improper dimensions for ' currentparam '.'])
				else
					error(['Improper dimensions for ' currentparam '.'])
				end
			end

		end %end multiple entries logic
	end %end if for whether param{I} was found
end %end for loop on I in param{I}

% check for unexpected parameters
if any(FLAG)
	I = find(FLAG);
	I = I(find(isodd(I)));
	
	error(['Unsupported parameter(s): ' varargin{I}])
end
