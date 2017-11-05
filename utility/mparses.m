function varargout = mparses(string, format, varargin)
%MPARSES.M  v1.0   parse string
%
%	done = mparses(string, format);
%	[done I] = mparses(string, format, I);
%
%done is a cell array containing the parsed and converted data from
%string.  
%
%I is the parser location within in the string.  I can be passed as
%an argument when mparses is run in slave mode.  The modes are
%described in more detail below.
%
%format is a string containing format descriptor similar to those
%accepted by the fortran, C, and matlab printf and scanf functions.
%The following flags are recognized:
%
%	%c	Single character including whitespace
%This can be used to collect a single character or a set of characters
%For example, %5c indicates 5 characters.
%
%	%d	Integer number
%Similar to the %c flag, %4d will stop at 4 digits.  Otherwise, %d
%continues scanning until EOS (end of string) or a non-numeric 
%character is encountered.
%
%	%f	Floating precision number
%Similar to %d, %f will collect numerical digits until a non-numeric
%character is encountered or will collect exactly the number of
%characters specified.  %f recognizes scientific notation: ie
%2.3e-4. 
%
%	%m[]	Insert string element
%Inserts the contents of [] into the result array as a string.
%
%	%n[]	Insert numeric element
%Converts the contents of [] to a number and inserts the result
%into the result array.
%
%	%r{}	repeat format string segment
%Can be declared as %Nr{...} or %r{...}.  If N is specified, it is
%the number of times the format string contained in the brackets 
%is to be applied.  If N is absent, the format string will be 
%applied repeatedly until an error occurs.  The parser supports
%nested %r{} declarations.  The parser recognizes escape sequences
%such as \} and \{ to allow these characters in the format string
%
%	%s[]	string
%Can be called in the form %s or %s[...].  %s cannot be declared
%with a numerical prefix (ie %5s).  If it is expressed in the form
%%s, the parser will scan until a whitespace character is encountered.
%If in the form %s[...] the parser will scan until it encounteres the
%string segment contained in the brackets.  The parser recognizes
%escape sequences such as \] and \[ to allow these characters to 
%appear in the brackets
%
%	%t{}	table
%Assembles the results of the contents of the brackets into a table.
%Numerical elements are treated as table entries.  String elements
%are treated as table newline flags and ignored.  For example:
%	%t{%3r{%5r{%f%*[ \n\t]}%m[//]}}
%This format string parses floats separated by whitespace characters
%into a 3x5 matrix.
%
%	%u	unsigned int
%Identical to %d except it rejects negative numbers.
%
%	%[]	character set
%Can be declared in the form %[...] or %[^...].  When in the form %[...]
%the parser will scan until it encounters a character NOT contained 
%in the brackets.  Escape combinations such as \] and \[ allow [ and ]
%to be included.  When expressed in the form %[^...], the behavior is
%reversed to scan until the parser encounters a character that IS 
% contained in the brackets.
%
%Any % flag may be modified by adding a * after the % sign to prevent
%the corresponding parsed result from being written to the output.  
%Instead the result is ignored and the parser moves on to the next result.
%This is useful when the precise header or formatting surrounding data
%is not known a-priori.
%
%**Modes**
%Similarly to mparsef.m, mparsem can also be called in master and slave
%mode.  Since mparses doesn't have to keep track of files, the operation
%is much simpler.  The optional input parameter, I, is really just the
%starting location in the string.  The default is 0.
%
%
%written to relieve compatibility problems between octave and legacy matlab
%tested for octave compatibility with octave 2.9.12
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech


if length(varargin) % if the function is called in slave mode

    I_s = varargin{1};      % use the passed string position

else

    I_s = 0;

end

N_format = length(format);
N_string = length(string);
N_done = ceil(N_string/10); 	% guess length for output cell array
done = cell(1,N_done);		% initialize output

go_flag = 1;	% flag to continue the scan
I_f = 1;	% format position counter
I_d = 0;	% done (output) array position counter
while go_flag
	%%%%%%%%%%%%%%%%%%%%%%%%
	%deal with data flags
	%%%%%%%%%%%%%%%%%%%%%%%%
	if format(I_f) == '%'
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% look for entry length and ignore flags
			
		% store the location of %
		J_f = I_f;

		% check for the ignore flag
		I_f = inc(I_f,N_format);
		ignore_flag = format(I_f) == '*';
		I_f = inc(I_f,N_format,ignore_flag);	% if * is found, move past it
		
		% scan until a non-numeric character is found
		while format(I_f)>='0' & format(I_f)<='9'
			I_f = inc(I_f,N_format);
		end
		N_entry = str2num(format(J_f+ignore_flag+1:I_f-1));

		% increment the done position counter and resize done as necessary
		if ~ignore_flag
			I_d = I_d+1;
			if I_d > N_done;
				temp = cell(1,N_done*2);
				temp(1:N_done) = done;
				done = temp;
				N_done = N_done*2;
				clear temp
			end
		end
		
		%%%%%%%%%%%%%%%%%%%%%%%%
		%input type flags

		% characters - scan a set number of characters
		if format(I_f) == 'c'
			% check for an entry length
			if isempty(N_entry)
				N_entry = 1;
			end
			% initialize the escape argument
			escape = '';
			% look for escape sequence
			if peek(format,I_f+1,'[')
				I_f = inc(I_f,N_format,2);
				%scan until ] found
				while format(I_f)~=']'
					% if an escape character is encountered, skip the next character

					if format(I_f) == '\'

						I_f = inc(I_f,N_format,1);
						if format(I_f) == 'n'
							escape = [escape sprintf('\n')];
						elseif format(I_f)=='t'
							escape = [escape sprintf('\t')];
						elseif format(I_f)=='r'
							escape = [escape sprintf('\r')];
						else
							escape = [escape format(I_f)];
						end

					else
						escape = [escape format(I_f)];
					end

					I_f = inc(I_f,N_format);
				end
			end

			% if no escape sequence is defined, default to the whitespace character set
			if isempty(escape)
				I_s = inc(I_s,N_string,N_entry);
				% scan for whitespace
				if ~ignore_flag
					done{I_d} = string(I_s+1+[-N_entry:-1]);
				end
			% if there is an escape sequence
			else
				J_s = I_s;
				while I_s-J_s<N_entry
					I_s = inc(I_s,N_string);
					if ~any(string(I_s)==escape)
						error(['Expected one of "' escape '", but found "' string(I_s) '".'])
					end
				end
				if ~ignore_flag
					done{I_d} = string(J_s+1:I_s);
				end
			end
			
		% strings - scan until whitespace or exit sequence
		elseif format(I_f) == 's'
			% error if an entry length is set
			if ~isempty(N_entry)
				error('Format string -- %s does not take an entry length argument.')
			end
			% initialize the escape argument
			escape = '';
			% look for escape sequence
			if peek(format,I_f+1,'[')
				I_f = inc(I_f,N_format,2);
				%scan until ] found
				while format(I_f)~=']'
					% if an escape character is encountered, skip the next character

					if format(I_f) == '\'

						I_f = inc(I_f,N_format,1);
						if format(I_f) == 'n'
							escape = [escape sprintf('\n')];
						elseif format(I_f)=='r'
							escape = [escape sprintf('\r')];
						elseif format(I_f)=='t'
							escape = [escape sprintf('\t')];
						else
							escape = [escape format(I_f)];
						end

					else
						escape = [escape format(I_f)];
					end

					I_f = inc(I_f,N_format);
				end
			end

			% if no escape sequence is defined, default to the whitespace character set
			if isempty(escape)
				J_s = I_s+1;
				% scan for whitespace
                		while ~peekin(string, I_s+1, sprintf(' \r\n\t')) & I_s<N_string
					I_s = inc(I_s,N_string);
				end
				if ~ignore_flag
					done{I_d} = string(J_s:I_s);
				end
			% if there is an escape sequence
			else
				J_s = I_s+1;
				% scan for the escape sequence
				while ~peek(string, I_s+1, escape) & I_s<N_string
					I_s = inc(I_s,N_string);
				end
				if ~ignore_flag
					done{I_d} = string(J_s:I_s);
				end
			end
		% integers - scan until non-numeric
		elseif format(I_f) == 'd'
			% if the entry length is not set
			if isempty(N_entry)
				J_s = I_s;
				% scan until the next character is the EOS or a non-numeric character
				while peekin(string, I_s+1, ['0':'9' '-'])
					I_s=I_s+1;
				end

				% do the conversion
				temp = str2num(string(J_s+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' string(J_s+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
			else
				
				I_s = inc(I_s,N_string, N_entry);
				temp = str2num(string(I_s-N_entry+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' string(I_s-N_entry+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
			end
		% unsigned integers - scan until non-numeric
		elseif format(I_f) == 'u'
			% if the entry length is not set
			if isempty(N_entry)
				J_s = I_s;
				% scan until the next character is the EOS or a non-numeric character
				while peekin(string, I_s+1, '0':'9')
					I_s = I_s+1;
				end

				% do the conversion
				temp = str2num(string(J_s+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' string(J_s+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
			else
				
				I_s = inc(I_s,N_string, N_entry);
				temp = str2num(string(I_s-N_entry+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' string(I_s-N_entry+1:I_s) '".'])
				elseif done{I_d}<0
					error('Unsigned integer returned a negative.  Try "%d" instead?')
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
			end

		% floats - scan until non numeric/exponential characters
		elseif format(I_f) == 'f'
			% if the entry length is not set
			if isempty(N_entry)
				J_s = I_s;
				% scan until the next character is the EOS or a non-numeric character
				while peekin(string, I_s+1, ['0':'9' '.+-eE'])
					I_s=I_s+1;
				end

				% do the conversion
				temp = str2num(string(J_s+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' string(J_s+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
			else
				
				I_s = inc(I_s,N_string, N_entry);
				temp = str2num(string(I_s-N_entry+1:I_s));
				if isempty(done{I_d})
					error(['Invalid numeric string, "' string(I_s-N_entry+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
			end

		% sets of characters - scan until finding a character in or not in the set
		elseif format(I_f) == '['
			% grab the escape character set
			%
			% initialize the escape character set
			escape = '';
			I_f = inc(I_f,N_format);
			% look for the inversion flag
			invert_flag = format(I_f)=='^';
			I_f = inc(I_f,N_format,invert_flag);
			% scan for the closing ]
			while format(I_f)~=']'
				% if an escape character is encountered, skip the next character

				if format(I_f) == '\'

					I_f = inc(I_f,N_format,1);
					if format(I_f) == 'n'
						escape = [escape sprintf('\n')];
                    elseif format(I_f)=='r'
                        escape = [escape sprintf('\r')];
					elseif format(I_f)=='t'
						escape = [escape sprintf('\t')];
					else
						escape = [escape format(I_f)];
					end

				else
					escape = [escape format(I_f)];
				end

				I_f = inc(I_f,N_format);
            end
			
			if isempty(escape)
				error(['[] escape character set is empty at position ' num2str(I_f) '.'])
			end

			% store the curser position in string
			J_s = I_s;
			while xor(invert_flag, peekin(string, I_s+1, escape)) & I_s<N_string
				I_s = inc(I_s,N_string);
			end
			if ~ignore_flag
				done{I_d} = string(J_s+1:I_s);
			end


		% repeating patterns - scan for a repeating pattern via a recursive call to mparses
		elseif format(I_f) == 'r'
			if peek(format,I_f+1,'{')
				% move format counter
				I_f = inc(I_f,N_format);
				J_f = I_f+1;
				% scan for the close }
				nesting = 1;
				while nesting
					I_f = inc(I_f,N_format);
					if format(I_f)=='\'
						I_f = inc(I_f,N_format);
					elseif format(I_f)=='}'
						nesting=nesting-1;
					elseif format(I_f)=='{'
						nesting=nesting+1;
					end
				end

				% if number of recursions are not specified
				if isempty(N_entry)
					% call recursive function until EOS or error
					recgo_flag = 1;
					while recgo_flag
						try
							[temp I_s] = mparses(string,format(J_f:I_f-1), I_s);
							if ~ignore_flag 	% if the ignore flag is cleared
								% done must be large enough to accomodate temp and an extra space for the next empty element.

								if numel(temp)>(numel(done)-I_d)
									m = ceil(log((numel(temp)+I_d)/N_done)/log(2));

									temp2 = cell(1,N_done*2^m);

									temp2(1:N_done) = done;

									done = temp2;

									N_done = N_done*2^m;

									clear temp2

								end
								done(I_d:(numel(temp)+I_d-1)) = temp;
								I_d = I_d+numel(temp);
							end
						catch
							recgo_flag = 0;
							I_d = I_d-1;	% back up I_d.  At this point in the code, I_d should be pointing to an occupied data element
						end
					end

				% if N_entry is specified
				else
					% call recursive function N_entry times
					while N_entry
						[temp I_s] = mparses(string,format(J_f:I_f-1), I_s);

						N_entry = N_entry-1;  	% decrement N_entry
						if ~ignore_flag 	% if the ignore flag is cleared
							% done must be large enough to accomodate temp and an extra space for the next empty element.

							if numel(temp)>(numel(done)-I_d)
								m = ceil(log((numel(temp)+I_d)/N_done)/log(2));

								temp2 = cell(1,N_done*2^m);

								temp2(1:N_done) = done;

								done = temp2;

								N_done = N_done*2^m;

								clear temp2

							end
							done(I_d:(numel(temp)+I_d-1)) = temp;
							I_d = I_d+numel(temp);
						end
					end
					I_d = I_d-1;	% back up I_d.  At this point, I_d should be pointing to an occupied data element.
				end
			else
				error(['Empty repeating pattern definition at position ' num2str(I_f)])
			end
		elseif format(I_f) == 't'
			if peek(format, I_f+1, '{')
				% move format counter
				I_f = inc(I_f,N_format);
				J_f = I_f+1;
				% scan for the close }
				nesting = 1;
				while nesting
					I_f = inc(I_f,N_format);
					if format(I_f)=='\'
						I_f = inc(I_f,N_format);
					elseif format(I_f)=='}'
						nesting=nesting-1;
					elseif format(I_f)=='{'
						nesting=nesting+1;
					end
                		end
                		% call mparses recursively to evaluate the contents of {}
                		[temp temp2] = mparses(string(I_s+1:end),format(J_f:I_f-1));
                
                		% initialize the output
                		done{I_d} = [];
                		J = 1; % row index
                		K = 1; % column index
                		for I = 1:length(temp)
        				% if a string is encountered, start a new row
					if isstr(temp{I})
						K = 0;
						J = J+1;
                    			elseif numel(temp{I})==1
						done{I_d}(J,K) = temp{I};
          			        else
          					error('Nested tables not supported.')
           				end
               				K=K+1;
                		end
			else
				error(['Empty table pattern definition at position ' num2str(I_f)])
			end

		% insert string
		elseif format(I_f)=='m'
			if N_entry

				error(['Multiple entries not defined for %m. Failed at position ' num2str(I_f)])

			end
			escape = '';

			% initialize the escape character set

			temp = '';
			if peek(format,I_f+1,'[')
				I_f = inc(I_f,N_format,2);
				%scan until ] found
				while format(I_f)~=']'
					% if an escape character is encountered, skip the next character

					if format(I_f) == '\'

						I_f = inc(I_f,N_format,1);
						if format(I_f) == 'n'
							escape = [escape sprintf('\n')];
						elseif format(I_f)=='r'
							escape = [escape sprintf('\r')];
						elseif format(I_f)=='t'
							escape = [escape sprintf('\t')];
						else
							escape = [escape format(I_f)];
						end

					else
						escape = [escape format(I_f)];
					end

					I_f = inc(I_f,N_format);
				end
			end

			done{I_d} = escape;
		
		% insert number
		elseif format(I_f)=='n'
			if N_entry
				error(['Multiple entries not defined for %n.  Failed at position ' num2str(I_f)])
			end
			if ~peek(format,I_f+1,'[')
				temp2 = [];
			else
				I_f = inc(I_f,N_format,2);
				J_f = I_f;
				% scan for the closing ]
				while format(I_f)~=']'
					I_f = inc(I_f,N_format);
				end
				temp = format(J_f:I_f-1);
				temp2 = str2num(temp);
				if isempty(temp2)
					error(['Invalid numeric string, "' temp '".'])
				end
			end
			done{I_d} = temp2;
			

		% catch unrecognized character error
		else
			error(['Unrecognized data flag character, ' format(I_f) ', at position, ' num2str(I_f) '.'])
		end
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%deal with escape characters
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	elseif format(I_f) == '\'
		I_f = inc(I_f,N_format,1);
		if format(I_f) == 'n'
			temp =  sprintf('\n');
        elseif format(I_f)=='r'
            temp = sprintf('\r');
		elseif format(I_f)=='t'
			temp = sprintf('\t');
		else
			temp = format(I_f);
		end
		I_s = I_s+1;
		go_flag = go_flag & I_s<=N_string;

		if temp ~= string(I_s)
			error(['Expected "' temp '", but found "'  string(I_s) '", at position ' num2str(I_s) '.'])
		end
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% normal characters
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	else
		I_s = I_s+1;
		go_flag = go_flag & I_s<=N_string;
		if format(I_f) ~= string(I_s)
			error(['Expected "' format(I_f) '", but found "'  string(I_s) '", at position ' num2str(I_s) '.'])
		end
	end

	% increment the counter and check for EOS
	I_f=I_f+1;
	go_flag = go_flag & I_f<=N_format;
end


% eliminate empty elements of done
done = done(1:I_d);


if nargout==2
	varargout = {done I_s};
else
	varargout = {done};
end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% increment subfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function I = inc(I,N, varargin)
if isempty(varargin)
	I = I+1;
else
	I = I+varargin{1};
end

if I>N
	error('Unexpected end of string.')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% peek subfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flag  = peek(string, I, sequence)
flag = 0;
if I+length(sequence)-1<=length(string)
	flag = strcmp(string(I-1+[1:length(sequence)]),sequence);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% peek in subfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flag = peekin(string, I, charset)
flag = 0;
if I<=length(string)
	flag = any(string(I) == charset);
end

	

