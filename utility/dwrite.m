function dwrite(filename, data, varargin)
%DWRITE.M  write struct data to an ascii file readable by dread
%
%	dwrite(filename, data, param1, value1, ...)
%
%filename is the string path and name of the ascii file to write.  Once dwrite is
%executed, if the file exists, it will be overwritten and otherwise will be
%created.
%
%data is the structure array containing elements to be written.
%
%The parameter-value pairs are used to configure the operation.  dwrite accepts 
%the following parameters:
%
%**HEAD***
%  The head option takes a string path to a file containing an appropriately 
%formatted header.  The header contains a list of the structure fields and their
%data types.  It identifies any tables or lists and the variables they name.  A
%valid header always begins with "$head$" and ends with "$/head$".  Lines that 
%begin with the "#" character are comments.  All other lines are parsed as field
%declarations.  dwrite uses the head as a template for printing a single element
%of the structure array.  It repeats the pattern in the head once for every 
%element in the array, reprinting the comments.
%  Lines that indicate text to be printed from the data array obey the follwoing
%format...
%	type: field1, field2, field3, ...
%the type specifies the format and type of data to be written.  The field names
%identify the structure array fields to be written.
%
%dwrite supports the following types:
%
%string - character array.  Takes only one field of type string.
%
%float - numerical data.  Takes only one field that is a scalar numeric type.
%
%list - array of numerical data.  Takes only one field that must be a numeric
%	array.
%
%table1d - table of numerical data with a single independent variable and any
%	   number of dependent variables.  The first field is the title of the
%	   table.  The second field is the independent variable and all the 
%	   following fields are dependent variables.  Each variable will be printed
%	   as a column with the same number of elements with the independent 
%	   variable first and separated by a column of "|" characters.
%	   
%table2d - table of numerical data with two indepdendent variables and a single
%	   dependent variable.  The first field is the table title.  The second
%	   and third fields are the independent variable field names.  The fourth
%	   field is the dependent variable field.  The dependent variable is 
%	   printed in a grid with each row corresponding to an element of the 
%	   first independent variable and each column corresponding to an element
%	   of the second independent variable.
%
%** list, table1d, table2d **
%  When any of the three numerical data types is passed as a parameter, the 
%value is a string list corresponding to the header information to the right
%of the ":" character as described above.  If the "head" parameter is found,
%these options are ignored.  
%
%Example:
% to save a data array given by
%data(1).name = 'stuff';
%data(1).a = [0:1:10];
%data(1).b = [0:0.1:1];
%data(1).c = ones(11,11);
%data(1).d = data(1).a.^2;
%
%data(2).name = 'thing';
%data(2).a = [1 2];
%data(2).b = [0.1 0.2];
%data(2).c = [1 2;3 4];
%data(2).d = data(2).a.^2;
%
%>>dwrite(data,'table1d','mytable-1,a,b,d','table2d','mytable-2,a,b,c')
%   OR
%>>dwrite(data,'head','headfile')
%both have the same results when headfile appears
%
%   $head$
%   string:name
%   table1d:mytable-1,a,b,d
%   table2d:mytable-2,a,b,c
%   $/head$
%
% **FORMAT**
%The format specifier allows the user to configure the manner in which each
%field is written to the file.  The format of a field is specified by the
%field name, followed by the %- string associated with fprintf.
%
%To specify the format of an integer field, "X" for example, one might 
%type the following:
%   ... 'format', 'X%10d', ...
%
%See also:
%   dread.m
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech

% get passed values
parameters = {'list--ms', 'table1d--ms', 'table2d--ms', 'format--ms', 'head--s'};
values = varargparam(parameters,varargin{:});

% get table info
list = values{1};
table1d = values{2};
table2d = values{3};
% check for header file
headfile = values{5};


% get info from the passed struct array
N = numel(data);	% number of data groups
if isstruct(data)
	struct_flag = 1;
	F = fieldnames(data);	% field names
else
	error('dwrite only supports struct data types.')
end
m = length(F);		% number of fields


format = cell(numel(F),1);
% get format specifiers
if ~isempty(values{4})
    % if there's only one string specifier,
    % nest it in a cell array just as if there were multiple.
    if ischar(values{4})
        values{4} = {values{4}};
    end
    % loop through the specified fields
    for I = 1:length(values{4})
        % parse the user-input string
        temp = mparses(values{4}{I},'%[^%]%s');
        if isempty(temp{1}) | isempty(temp{2})
            error(['Illegal format specifier, "' values{4}{I} '".'])
        end
        % search for the specified field
        J = find(strcmp(temp{1},F));
        if isempty(J)
            error(['Unrecognized field in format specifier, "' values{4}{I} '".'])
        end
        % assign the specifier
        format{J} = temp{2};
    end
end

head = '';
% if there is no header file specified, generate the header automatically
if isempty(headfile)
	% number of each type of table
	N_list = length(list);
	N_1d = length(table1d);
	N_2d = length(table2d);
	
	head = [head sprintf('\n\n')];	% insert a newline to be entered at the beginning of every entry

	intab_flag = zeros(1,length(F));	% array of flags indicating if a parameter is in a table

	% check the lists
	for I = 1:N_list
		J = find(strcmp(list{I},F));
		if isempty(J)
			error(['Field name, "' list{I} '", in list ' num2str(I) ', not found.'])
		end
		intab_flag(J) = 1;
	end
	% check the 1d tables
	for I = 1:N_1d
		% replace the table specifier string with a cell array of the parsed field names
		table1d{I} = mparses(table1d{I},'%r{%[^,],%*[ \t\n]}%[^ \t\n]');
		for J = 2:length(table1d{I})
			K = find(strcmp(table1d{I}{J},F));
			if isempty(K)
				error(['Field name, "' table1d{I}{J} '", in 1-D table ' num2str(I) ', not found.'])
			end
			intab_flag(K) = 1;
		end
	end
	% check the 2d tables
	for I = 1:N_2d
		% replace the table specifier string with a cell array of the parsed field names
		try
			table2d{I} = mparses(table2d{I},'%r{%[^,],%*[ \t\n]}%[^ \t\n]');
		catch
			error(['Improper table format string, "' table2d{I} '".'])
		end
		for J = 2:4
			K = find(strcmp(table2d{I}{J},F));
			if isempty(K)
				error(['Field name, "' table2d{I}{J} '", in 2-D table ' num2str(I) ', not found.'])
			end
			intab_flag(K) = 1;
		end
	end

	% compile a list of the fields not in tables
	nontab = find(~intab_flag);
	%%%%%%%%
	% auto-build a header
	%%%%%%%%
	for I=nontab
		% get each field from the first element to determine type
		temp = getfield(data,{1},F{I});
		if isnumeric(temp)
			head = [head sprintf('float:%s\n',F{I})];
		elseif ischar(temp)
			head = [head sprintf('string:%s\n',F{I})];
		else
			error(['Unsupported data type in field, "' F{I} '".'])
		end
	end
	% lists
	for I=1:N_list
		head = [head sprintf('list:%s\n',list{I})];
	end
	% 1-d tables
	for I=1:N_1d
		head = [head sprintf('table1d:')];
		head = [head sprintf('%s,',table1d{I}{1:end-1})];
		head = [head sprintf('%s\n',table1d{I}{end})];
	end
	% 2-d tables
	for I=1:N_2d
		head = [head sprintf('table2d:%s,%s,%s,%s\n',table2d{I}{:})];
	end
% if there is a header file specified, try to open it and extract a header string
else		
	head = mparsef(headfile, '%*s[$head$]%*6c%s[$/head$]');
	head = head{1};
	if isempty(head)
		error(['No header found in file, "' headfile '".'])
	elseif ~isempty(list) | ~isempty(table1d) | ~isempty(table2d)
		warning('Explicit header definition found. Ignoring list, table1d, and table2d parameters.')
	end
end


% wait until this point to open the file so if there is a problem, the file will not be overwritten or corrupted
% try to open the file
try
	fid = fopen(filename,'w+');
catch
	error(['Could not open file, "' filename '".'])
end

%Generate the header
fprintf(fid,'Data file generated using DWRITE.M v1.0\nWritten on %s.\n',date);
fprintf(fid,'$head$%s$/head$\n',head);
%%%%%%%%%%%%%%%%%%%%%%%%%%
%write out the data!
%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize format arguments for parsing header data
ws = '%*[ \t]';		% ignore whitespace
findcomments = '%*[\n]%r{#%*[^\n]%*[\n]}';	% find and ignore all commented lines and empty lines
finddata = [	ws '%s[:]:' ...			% find a string ending in ':'
		'%r{' ws '%[^, \t\n],}' ...	% repeatedly find a string ending in ','
		ws '%[^ \t\n]'];		% find a string terminating in whitespace (the last string in the list)

% loop through the elements of "data"
for I = 1:N
	J = 0;
	while J<length(head)
		% find all comments and format text not relevant to the data			
		J_s = J+1;
		[element J] = mparses(head,findcomments,J);
		% print the format text
		fprintf(fid,'%s',head(J_s:J));

		% unless the findcomments parse ended at the EOS, it must have found a line with data!			
		if J<length(head)
			J_s = J+1;
			[element J] = mparses(head,finddata,J);
			% if a string
			if strcmp(element{1}, 'string')
				if length(element) == 2
                    % check for user-specified format
                    K = find(strcmp(F,element{2}));
                    if isempty(format{K})
    					fprintf(fid,'%s=%s',element{2},getfield(data,{I},element{2}));
                    else
                        fprintf(fid,['%s=' format{K}],element{2},getfield(data,{I},element{2}));
                    end
				else
					fclose(fid);
					error(['Invalid head entry, "' head(J_s:J) '". Type "string" only takes one variable entry.'])
				end
			elseif strcmp(element{1}, 'float')
				if length(element) == 2
					% check for user-specified format
                    K = find(strcmp(F,element{2}));
                    if isempty(format{K})
    					fprintf(fid,'%s=%f',element{2},getfield(data,{I},element{2}));
                    else
                        fprintf(fid,['%s=' format{K}],element{2},getfield(data,{I},element{2}));
                    end
				else
					fclose(fid);
					error(['Invalid head entry, "' head(J_s:J) '". Type "float" only takes one variable entry.'])
				end
			elseif strcmp(element{1}, 'list')
				if length(element) == 2
                    % check for user-specified format
                    K = find(strcmp(F,element{2}));
                    temp = getfield(data,{I},element{2});
                    fprintf(fid,'%s=',element{2});
                    if isempty(format{K})
                        fprintf(fid,'%f,',temp(1:end-1));
                        fprintf(fid,'%f',temp(end))
                    else
                        fprintf(fid,[format{K} ','],temp(1:end-1));
                        fprintf(fid,format{K},temp(end))
                    end
				else
					fclose(fid);
					error(['Invalid head entry, "' head(J_s:J) '". Type "list" only takes one variable entry.'])
				end
			elseif strcmp(element{1}, 'table1d')
				%get dimensions
				N_cols = length(element)-2;
				temp2 = getfield(data,{I},element{3});
				N_rows = numel(temp2);
				temp = zeros(N_rows,N_cols);
                temp3 = cell(N_cols,1);
				%collect table data & check for user-specified format
				for K=1:N_cols
					temp2 = getfield(data,{I},element{K+2});
					if numel(temp2)~=N_rows
						fclose(fid);
						error(['1-D table size missmatch: field, "' element{K+2} '", does not match the other fields.'])
					end
					temp(:,K) = reshape(temp2,N_rows,1);
                    P = find(strcmp(F,element{K+2}));
                    if isempty(format{P})
                        temp3{K} = '%17.8e';
                    else
                        temp3{K} = format{P};
                    end
				end
				%print table header
				fprintf(fid,'%s=\n',element{2});
				%print table
				for K=1:N_rows
					fprintf(fid,[' ' temp3{1} ' |'],temp(K,1));
                    for P = 2:N_cols-1
                        fprintf(fid,[' ' temp3{P}],temp(K,P));
                    end
					fprintf(fid,[' ' temp3{end} '\n'],temp(K,end));
				end
			elseif strcmp(element{1}, 'table2d')
				if length(element)~=5
					fclose(fid);
					error(['Error in table2d header entry. Must have a title and 3 variables.'])
				end
				%get dimensions and collect table data
				Z = getfield(data,{I},element{5});
				X = getfield(data,{I},element{3});
				Y = getfield(data,{I},element{4});
				N_rows = numel(X);
				N_cols = numel(Y);
				if numel(Z) == N_rows*N_cols
					Z = reshape(Z,N_rows,N_cols);
				else
					fclose(fid);
					error(['Size missmatch.  Field, "' element{5} '", does not fit in 2-d table, "' element{2} '", at data element ' num2str(I)])
				end
				%print table header
				fprintf(fid,'%s=\n',element{2});
				%print table
				%  print Y data                
				fprintf(fid,'                   ');
                %    check for user-specified Y format
                P = find(strcmp(F,element{4}));
                if isempty(format{P})
    				fprintf(fid,' %17.8e',Y(:));
                else
                    fprintf(fid,['  ' format{P}], Y(:));
                end
				%  print divider between Y-data and Z-data
				fprintf(fid,'\n                  +');
				for K=1:N_cols
					fprintf(fid,'------------------');
				end
				fprintf(fid,'\n');
                % look for X and Z user-specified format
                temp3 = {'%17.8e' '%17.8e'};
                P = find(strcmp(F,element{3})); % x first
                if ~isempty(format{P})
                    temp3{1} = format{P};
                end
                P = find(strcmp(F,element{5})); % then z
                if ~isempty(format{P})
                    temp3{2} = format{P};
                end
				%  print the X-data element and the Z-data from each row
				for K=1:N_rows
					fprintf(fid,[temp3{1} ' |'],X(K));
					fprintf(fid,[' ' temp3{2}],Z(K,:));
					fprintf(fid,'\n');
				end
				fprintf(fid,'\n');
			else
				fclose(fid);
				error(['Found unrecognized variable style, "' element{1} '", in header.'])
			end
		end
	end
end
fclose(fid);

