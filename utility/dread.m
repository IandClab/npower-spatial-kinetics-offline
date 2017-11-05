function data = dread(filename, varargin)
%DREAD.M  read from text files written using DWRITE.M
%
%   data = dread(filename, param1, value1, ...);
%
%Loads the ascii data from 'filename' into a struct with fields
%named according to the variables defined in the file header
%(defined below).  DREAD makes no assumptions regarding the
%format of the data nor which fields will be defined.  DREAD
%loads data entirely based on the information contained in the
%header.
%
%the ascii file must have the following format:
%--------------------------------------------------
%   All text before the header flag is ignored.
%   $head$
%
%   # this is a comment in the header
%   string:string_field_name
%   float:float_field_name
%   list:list_field_name
%   table1d:1D_table_title, first_field_name, second_field_name,...
%   table2d:2D_table_title, X_field_name, Y_field_name, Z_field_name
%   $/head$
%
%   # this is a comment in the body of the file
%
%   string_field_name = string_data
%
%   float_field_name = 3.14159
%
%   list_field_name = 1,2,3,4,5,6
%
%   1D_table_title = 
%       1   |   10  100 1000
%       2   |   20  200 2000
%       3   |   30  300 3000
%
%   2D_table_title =
%               1   2   3
%   --------+---------------
%       10  |   10  20  30
%       20  |   20  40  60
%       30  |   30  60  90
%
%--------------------------------------------------
% The ascii file is divided into three sections.  A description,
%a header, and the body.  
% The description is any text prior to the flag "$head$".  This 
%text can be used to give information on the file's content, 
%it's author, when it was written, etc...
% The parser reads the header to determine the names of the fields
%that the struct array should have and what format of data will
%be contained in each of them.  Each line is a separate entry and
%there are seven types of acceptable lines:
%   empty lines - do nothing and are purly for aesthetics
%   comments - begin with the # character
%   string -    creates a field that will contain string data. The
%               line also contains the field name and will appear
%               as above.
%   float -     same as string, but for non-array numeric data.
%   list -      specs a field for a 1-d array of numeric data.
%   table1d -   tells the parser to look for a table containing
%               multiple fields in a single ascii table.  The table
%               is identified by a string title, and each field will
%               be listed as a column in the table.  As above, the
%               table title is specified first, and then the name of
%               each field in the table.
%   table2d -   similar to table1d, table2d specifies a table containing
%               only 3 fields: two 1-d arrays and a 2-d array with
%               rows and columns corresponding to each of the 1-d 
%               arrays respectively.  As indicated above, the table
%               title is specified first, followed by the X (column),
%               Y (row), and Z (2-D) arrays.
% The body contains the actual data.  Every non-empty line that does 
%not begin with a # either begins an entry or is part of an entry.
%An entry begins either with a table title or a field name and a "=" 
%sign.  The parser will scan the following characters until it has fully
%populated the field based on its type specified in the header.  Once
%every element field or table specified in the header has been found,
%the parser starts over - looking for data for the next element of the
%struct array.  The process repeats until the end of the file.
%
%*WARNING*
% It is feasible to write these files manually, but it is heavily 
%recommended that you try the dwrite utility first.  It can save
%quite a bit of heartache.  Dread has been written to be as insensitive
%to little changes in format as possible, but it has been tested with
%the output of dwrite.
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech


% open the file
fid = fopen(filename,'r');
if fid<0
    error(['Could not open "' filename '".'])
end

% deal with parameter-value pairs
parameters = {'verbose'};
values = varargparam(parameters, varargin{:});

% set up the defaults
verbose = 1;
% check values
if ~isempty(values{1})
	verbose = logical(values{1});
end

%initialize the buffer and buffer counter
I = 0;
buffer = '';
%initialize a couple of useful format string constants
ws = '%*[ \t]';	% whitespace
nl = '%*[\r\n]';  % new/empty lines
%initialize a cell array for the field descriptors
F = {};		% field names
INST = {};	% instance names
INST_type = {};	% instance type
INST_cont = {};	% instance contentF = {F{:} entry{2}};


%%%%%%%%%%%%%%%%%%%%%%%
% read & parse the header
%%%%%%%%%%%%%%%%%%%%%%%
[dummy I buffer] = mparsef([],'%*s[$head$]%*6c', I, buffer, fid);

% format string to search for indivdual header element
format = [nl '%r{#%*[^\r\n]%*[\r\n]}' ws '%[^: \r\n\t]%*c' ws '%r{%[^, \t\n\r],' ws '}%s'];

[entry I buffer] = mparsef([],format,I,buffer,fid);
while ~strcmp(entry{1},'$/head$')
	% deal with the entry
	if strcmp(entry{1},'float')
		% look for pre-existing declarations
		if ~any(strcmp(entry{2},F))
			F = {F{:} entry{2}};
			INST = {INST{:} entry{2}};
			INST_type = {INST_type{:} entry{1}};
			INST_cont = {INST_cont{:} entry{2}};
		else
			fclose(fid);
			error(['Bad header.  Float, ' entry{2} ', was encountered more than once.'])
		end
	elseif strcmp(entry{1},'string')
		% look for pre-existing declarations
		if ~any(strcmp(entry{2},F))
			F = {F{:} entry{2}};
			INST = {INST{:} entry{2}};
			INST_type = {INST_type{:} entry{1}};
			INST_cont = {INST_cont{:} entry{2}};
		else
			fclose(fid);
			error(['Bad header.  String, ' entry{2} ', was encountered more than once.'])
		end
	elseif strcmp(entry{1},'list')
		% look for pre-existing declarations
		if ~any(strcmp(entry{2},F))
			F = {F{:} entry{2}};
			INST = {INST{:} entry{2}};
			INST_type = {INST_type{:} entry{1}};
			INST_cont = {INST_cont{:} entry{2}};
		end
	elseif strcmp(entry{1},'table1d')
		if ~any(strcmp(entry{2},INST))
			INST = {INST{:} entry{2}};
			INST_type = {INST_type{:} entry{1}};
			INST_cont = {INST_cont{:} entry(3:end)};
		else
			error(['Bad header.  1-D table, "' entry{2} '", was encountered more than once.'])
		end
		for J = 3:length(entry)
			% look for pre-existing declarations
			if ~any(strcmp(entry{J},F))
				F = {F{:} entry{J}};
			end
		end
	elseif strcmp(entry{1},'table2d')
		if ~any(strcmp(entry{2},INST))
			INST = {INST{:} entry{2}};
			INST_type = {INST_type{:} entry{1}};
			INST_cont = {INST_cont{:} entry(3:end)};
		else
			error(['Bad header.  1-D table, "' entry{2} '", was encountered more than once.'])
		end
		for J = 3:5
			% look for pre-existing declarations
			if ~any(strcmp(entry{J},F))
				F = {F{:} entry{J}};
			end
		end
	end
	% grab the next header entry
	[entry I buffer] = mparsef([],format,I,buffer,fid);
end

% print the header table
if verbose
	fprintf('Successfully parsed the header.\nFound the following data...\n')
	fprintf('Fields');
	fprintf(', "%s"',F{:});
	fprintf('.\n')
	fprintf('%20s %10s %20s\n----------------------------------------------------\n','Inst. Name', 'Type','Contains');
	for J = 1:length(INST)
		fprintf('%20s %10s ',INST{J}, INST_type{J});
		if iscell(INST_cont{J})
			fprintf('  ');
			fprintf('%s ',INST_cont{J}{:});
			fprintf('\n');
		else
			fprintf('%20s\n',INST_cont{J});
		end
    end
    fprintf('Parsing');
end

temp = shuffle(shuffle(F,cell(size(F))));
data = struct(temp{:});	% initialize the data struct
N = numel(data);	% initialize the length of the data array
J = 0;			% initialize the data counter
go_flag = 1;		% initialize the go flag
found = ones(size(INST)); % initialize an array of flags for each field
			%  when the parser finds a field - its flag will be set
			%  when all the fields are found, the current array element
			%  is finished.

% done parsing header... clear buffer
buffer = '';
I = 0;

comments = [nl '%r{#%*[^\n\r]%*[\n\r]}'];
nameformat = [ws '%[^= \t]' ws '=' ws];
stringformat = ['%s' ws nl];
floatformat = ['%f' ws nl];
listformat = ['%t{%r{%f,' ws '}%f}' nl];
table1dformat = [nl '%t{' '%r{' ws '%f' ws '|' '%r{' ws '%f}%m[//]' ws nl '}}'];
table2dhead = [nl '%t{' '%r{' ws '%f' '}}'];
table2dbody = [nl '%*[^\r\n]' nl '%t{' '%r{' ws '%f' ws '|' '%r{' ws '%f}%m[//]' ws nl '}}'];

% read any leading comments
[dummy I buffer] = mparsef([],comments,I,buffer,fid);
while go_flag
	% if the array element is fully populated, move on
	if all(found)
        if verbose
            fprintf('.');
        end
		J = J+1;	% increment the position in the array
		found = zeros(size(found));	% zero the found flags
		if J>N
			data = more(data);	% if more data is needed, add more
			N = 2*N;		% and update the array length
		end
	end
	% read in the name
	[entry I buffer] = mparsef([],nameformat,I,buffer,fid);
	name = entry{1};
	K = find(strcmp(entry,INST));
	if isempty(K)
		error(['Unrecognized instance, "' name '", in element ' num2str(J) '.'])
	end

	% set the found flag
	found(K) = 1;
	% read in data
	if strcmp(INST_type{K},'float')
		[entry I buffer] = mparsef([],floatformat,I,buffer,fid);
		data(J).(name) = entry{1};
	elseif strcmp(INST_type{K},'string')
		[entry I buffer] = mparsef([],stringformat,I,buffer,fid);
		data(J).(name) = entry{1};
	elseif strcmp(INST_type{K},'list')
		[entry I buffer] = mparsef([],listformat,I,buffer,fid);
		data(J).(name) = entry{1};
	elseif strcmp(INST_type{K},'table1d')
		% read the table
		[entry I buffer] = mparsef([],table1dformat,I,buffer,fid);
		% write the table to data
		for L=1:length(INST_cont{K})
			data(J).(INST_cont{K}{L}) = entry{1}(:,L);
		end
	elseif strcmp(INST_type{K},'table2d')
		% read the first row of the table data (the Y array)
		[entry I buffer] = mparsef([],table2dhead,I,buffer,fid);
		% write the Y data
		data(J).(INST_cont{K}{2}) = entry{1};		
		% read in the table body (X array and Z matrix)
		[entry I buffer] = mparsef([],table2dbody,I,buffer,fid);
		% write the X data
		data(J).(INST_cont{K}{1}) = entry{1}(:,1);
		% write the Z data
		data(J).(INST_cont{K}{3}) = entry{1}(:,2:end);
	end
	
	% read empty lines and comments
	[dummy I buffer] = mparsef([], comments, I, buffer, fid);
	% continue unless the buffer is exhausted AND the eof flag is set
	go_flag = ~(feof(fid) & I == length(buffer));
end

% eliminate the empty elements at the end of the data array
data = data(1:J);

fclose(fid);

if verbose
    fprintf('done.\n');
end



% a function that doubles the size of the data array
function data = more(data)
N = numel(data);
F = fieldnames(data);
temp = shuffle(F,cell(size(F)));
data(N*2) = struct(temp{:});

