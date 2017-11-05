function varargout = mparsef(filename, format, varargin)
%MPARSEF.M v1.0  parse text data from a file
%
%   done = mparsef(filename, format);
%   [done, I, buffer] = mparsef([], format, I, buffer, fid);
%
%done is a cell array containing the parsed and converted data from
%string.  
%
%"I", "buffer", and "fid" are all parameters that are used when mparsef
%is called in slave mode.  Usually, this mode won't be used, but it 
%can occasionally be very powerful.  Modes are described below.
%
%format is a string containing format descriptor similar to those
%accepted by the fortran, C, and matlab printf and scanf functions.
%The following flags are recognized:
%
%**Format Flags**
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
%  mparsef can be called in two modes; master and slave.  In master 
%mode, mparsef takes responsibility for opening the file,
%initializing a buffer, and tracking positiong within the file. 
%In slave mode, however, the script calling mparsef must perform 
%these operations.
%
%The buffer is a string into which text from the file is loaded one line
%at a time.  If the parser needs to track text across multiple lines
%it will extend the buffer to hold multiple lines.  "I" is the parser
%position within the buffer.  
%
%Though mparsef is usually easier to run in master mode, slave
%mode has a number of uses.  For example, mparsef uses slave mode
%to call itself recursively when the %t or %r options are executd. 
%Also, users may want to parse later portions of text differently
%based on options parsed at the head of the file by doing the follwing:
%
%buffer = '';
%fid = fopen('myfile.txt');
%I = 0;
%format = %...format string here...
%
%[first_data I buffer] = mparsef([],format,I,buffer,fid);
%%...
%% INSERT NIFTY CODE HERE TO BUILD A NEW FORMAT STRING
%%...
%second_data = mparsef([],format,I,buffer,fid);
%fclose(fid);
%
%In the above example, the I, buffer, and fid variables are all that
%are necessary to completely track the parser progress through the
%file, so in slave mode, the calling script can essentually pause
%parsing to do something else, and then resume where it left off.
%
%written to relieve compatibility problems between octave and legacy matlab
%tested for octave compatibility with octave 2.9.12 and Matlab 7.1.0 (R14)
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech

if nargin % if the function is called in slave mode
    fid = varargin{3};      % use the already opened file
    buffer = varargin{2};   % and use the passed buffer
    I_s = varargin{1};      % and string position
else
    fid = fopen(filename);
    buffer = '';
    I_s = 0;
end

N_format = length(format);
N_done = 1;
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
                        elseif format(I_f) == 'r'
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
				% move curser to the end of the entry (and check for EOS error)
				[I_s buffer] = inc_s(I_s,buffer,fid,N_entry,~ignore_flag);
				% grab the character array
				if ~ignore_flag
					done{I_d} = buffer(I_s+1+[-N_entry:-1]);
				end
			% if there is an escape sequence
			else
				J_s = I_s;
				while I_s-J_s<N_entry
					[I_s buffer] = inc_s(I_s,buffer,fid,1,~ignore_flag);
					if ~any(string(I_s)==escape)
						error(['Expected one of "' escape '", but found "' string(I_s) '".'])
					end
				end
				if ~ignore_flag
					done{I_d} = buffer(J_s+1:I_s);
				end
                end			
            [I_s buffer] = cleanbuffer(I_s,buffer);
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
                        elseif format(I_f) == 'r'
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
		                [temp buffer] = peekin_s(I_s+1, buffer, fid, sprintf(' \r\n\f'));
				while ~temp & ~(feof(fid) & I_s==length(buffer))
					[I_s buffer] = inc_s(I_s, buffer, fid, 1, ~ignore_flag);
                   			 [temp buffer] = peekin_s(I_s+1, buffer, fid, sprintf(' \r\n\f'));
               			end
				if ~ignore_flag
					done{I_d} = buffer(J_s:I_s);
                		end
			% if there is an escape sequence
			else
				J_s = I_s+1;
				% scan for the escape sequence or EOF
                		[temp buffer] = peek_s(I_s+1, buffer, fid, escape);
				while ~temp & ~(feof(fid) & I_s==length(buffer))
					[I_s buffer] = inc_s(I_s, buffer, fid, 1, ~ignore_flag);
                    			[temp buffer] = peek_s(I_s+1, buffer, fid, escape);
				end
				if ~ignore_flag
					done{I_d} = buffer(J_s:I_s);
				end
            end
            [I_s buffer] = cleanbuffer(I_s,buffer);
		% integers - scan until non-numeric
		elseif format(I_f) == 'd'
			% if the entry length is not set
			if isempty(N_entry)
				J_s = I_s;
				% scan until the next character is the EOS or a non-numeric character
                		[temp buffer] = peekin_s(I_s+1, buffer, fid, ['0':'9' '-']);
				while temp
					[I_s buffer] = inc_s(I_s, buffer, fid, 1, 1);
                    			[temp buffer] = peekin_s(I_s+1, buffer, fid, ['0':'9' '-']);
                		end

                		% do the conversion
                		temp = str2num(buffer(J_s+1:I_s));
                		if isempty(temp)
	                        	error(['Invalid numeric string, "' buffer(J_s+1:I_s) '".'])
        		        end
				if ~ignore_flag
					done{I_d} = temp;
				end
			else
				
				[I_s buffer] = inc_s(I_s, buffer, fid, N_entry, 1);
				temp = str2num(buffer(I_s-N_entry+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' string(I_s-N_entry+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
            end
            [I_s buffer] = cleanbuffer(I_s,buffer);
		% unsigned integers - scan until non-numeric
		elseif format(I_f) == 'u'
			% if the entry length is not set
			if isempty(N_entry)
				J_s = I_s;
				% scan until the next character is the EOS or a non-numeric character
		                [temp buffer] = peekin_s(I_s+1, buffer, fid, ['0':'9']);
				while temp
					[I_s buffer] = inc_s(I_s, buffer, fid, 1, 1);
                			[temp buffer] = peekin_s(I_s+1, buffer, fid, ['0':'9']);
                		end

				% do the conversion
				temp = str2num(buffer(J_s+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' buffer(J_s+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
			else
				
				[I_s buffer] = inc_s(I_s, buffer, fid, N_entry);
				temp = str2num(buffer(I_s-N_entry+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' buffer(I_s-N_entry+1:I_s) '".'])
				elseif done{I_d}<0
					error('Unsigned integer returned a negative.  Try "%d" instead?')
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
            end
            [I_s buffer] = cleanbuffer(I_s,buffer);
		% floats - scan until non numeric/exponential characters
		elseif format(I_f) == 'f'
			% if the entry length is not set
			if isempty(N_entry)
				J_s = I_s;
				
				% scan until the next character is the EOS or a non-numeric character
                		[temp buffer] = peekin_s(I_s+1, buffer, fid, ['0':'9' '.+-eE']);
				while temp
					[I_s buffer] = inc_s(I_s, buffer, fid, 1, 1);
                    			[temp buffer] = peekin_s(I_s+1, buffer, fid, ['0':'9' '.+-eE']);
                		end

				% do the conversion
				temp = str2num(buffer(J_s+1:I_s));
				if isempty(temp)
					error(['Invalid numeric string, "' buffer(J_s+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
            		else
            		% if the entry length is set
				[I_s buffer] = inc_s(I_s,buffer,fid, N_entry);
				temp = str2num(buffer(I_s-N_entry+1:I_s));
				if isempty(done{I_d})
					error(['Invalid numeric string, "' buffer(I_s-N_entry+1:I_s) '".'])
				end
				if ~ignore_flag
					done{I_d} = temp;
				end
            end
            [I_s buffer] = cleanbuffer(I_s,buffer);
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
                    elseif format(I_f) == 'r'
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
            		[temp buffer] = peekin_s(I_s+1, buffer, fid, escape);
            		while xor(invert_flag,temp) & ~(feof(fid) & I_s==length(buffer))
                		[I_s buffer] = inc_s(I_s, buffer, fid, 1, 1);
                		[temp buffer] = peekin_s(I_s+1, buffer, fid, escape);
            		end
			if ~ignore_flag
				done{I_d} = buffer(J_s+1:I_s);
            end

            [I_s buffer] = cleanbuffer(I_s,buffer);
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
							[temp I_s buffer] = mparsef([],format(J_f:I_f-1),I_s,buffer,fid);
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
						end
					end
					I_d = I_d-1;	% back up I_d.  At this point in the code, I_d should be pointing to an occupied data element

				% if N_entry is specified
				else
					% call recursive function N_entry times
					while N_entry
						[temp I_s buffer] = mparsef([],format(J_f:I_f-1),I_s,buffer,fid);
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
            [I_s buffer] = cleanbuffer(I_s,buffer);
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
                		% call mparsef recursively to evaluate the contents of {}
                		[temp I_s buffer] = mparsef([],format(J_f:I_f-1),I_s,buffer,fid);
                
                		% initialize the output
                		done{I_d} = [];
                		J = 1; % row index
                		K = 1; % column index
                		for I = 1:length(temp)
        				% if a string is encountered, start a new row
					if ischar(temp{I})
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
		elseif format(I_f) == 'm'
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
                        elseif format(I_f) == 'r'
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
            [I_s buffer] = cleanbuffer(I_s,buffer);
		elseif format(I_f)=='n'
			if N_entry
				error(['Multiple entries not defined for %n. Failed at position ' num2str(I_f)])
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
				temp2 = num2str(temp);
				if isempty(temp2)
					error(['Invalid numeric string, "' temp '".'])
				end
			end
			done{I_d} = temp2;
            [I_s buffer] = cleanbuffer(I_s,buffer);
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
		elseif format(I_f)=='t'
			temp = sprintf('\t');
        elseif format(I_f)=='r'
            temp = sprintf('\r');
		else
			temp = format(I_f);
		end
		[I_s buffer] = inc_s(I_s, buffer, fid);
		go_flag = go_flag & ~(feof(fid) & I_s==length(buffer));

		if temp ~= buffer(I_s)
			error(['Expected "' temp '", but found "'  buffer(I_s) '", at position ' num2str(I_s) '.'])
		end
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% normal characters
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	else
		[I_s buffer] = inc_s(I_s, buffer, fid);
		go_flag = go_flag & ~(feof(fid) & I_s==length(buffer));
		if format(I_f) ~= buffer(I_s)
			error(['Expected "' format(I_f) '", but found "'  buffer(I_s) '".'])
		end
	end

	% increment the counter and check for EOS
	I_f=I_f+1;
	go_flag = go_flag & I_f<=N_format;
end


% eliminate empty elements of done
done = done(1:I_d);


if nargout==3
	varargout = {done I_s buffer};
else
	varargout = {done};
end

if nargin==0
	fclose(fid);
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% increment subfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function I = inc(I, N, varargin)
if isempty(varargin)
	I = I+1;
else
	I = I+varargin{1};
end

if I>N
    error('Unexpected end of string')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% increment into the buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [I buffer] = inc_s(I, buffer, fid, varargin)
if isempty(varargin)
	I = I+1;
else
	I = I+varargin{1};
end

% if I has overrun the buffer, ask for more
if I>length(buffer)
    % if there's no more to give
    if feof(fid)
        error('Unexpected end of file')
    % if the keep flag is passed
    elseif length(varargin)==2
        if ~varargin{2}
            I = I-length(buffer);
        end
        [buffer failed] = bufferupdate(buffer, fid, I-length(buffer), varargin{2});
    % otherwise, default the keep flag to 0
    else
        I = I-length(buffer);
        [buffer failed] = bufferupdate(buffer, fid, I, 0);
    end
    if failed
        error('Unexpected end of file')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
% buffer update function (should ONLY be called by inc_s)
%%%%%%%%%%%%%%%%%%%%%%%%%%
function [buffer fail] = bufferupdate(buffer, fid, depth, keep)
if ~keep
    buffer = '';
end
while depth>0 & ~feof(fid)
    temp = fgets(fid);
    buffer = [buffer temp];
    depth = depth - length(temp);
end
fail = feof(fid)&(depth>0);

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% peek buffer subfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flag buffer] = peek_s(I, buffer, fid, sequence)
flag = 0;
temp = I+length(sequence)-1;
if temp<=length(buffer)
    flag = strcmp(buffer([I:temp]),sequence);
else
    try
        [buffer fail] = bufferupdate(buffer, fid, temp-length(buffer), 1);
        flag = strcmp(buffer([I:temp]),sequence);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% peek in buffer subfunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [flag buffer] = peekin_s(I, buffer, fid, charset)
flag = 0;
if I<=length(buffer)
	flag = any(buffer(I) == charset);
else
    try
        [buffer fail] = bufferupdate(buffer, fid, I-length(buffer), 1);
        flag = any(buffer(I)==charset);
    end
end

	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [I buffer] = cleanbuffer(I,buffer)
buffer = buffer(I:end);
I = 1;