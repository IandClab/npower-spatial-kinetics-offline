function done = janlookup(data, outfield, infield, invalue, varargin)
%JANLOOKUP.M
%   JANAF data lookup toolbox
%   written by Chris Martin 5/2008
%
%   output = janlookup(data, outfield, infield, value, param1, value1, ...)
%
% Interpolates table data in the JANAF data struct.
%========================================================
%data           JANAF data struct.  Fields are flexible.
%
%outfield       String name of the field containing the 
%               output data vector (data.outfield)
%
%infield        String name of the field containing the
%               input data vector (data.infield)
%
%value          numeric value of the input variable
%
%output         numeric interpolated value of the output field
%=========================================================
%optional param, value pairs:
%   'deriv'     estimate the derivative of the interpolation spline
%               to the order specified. (may not exceed the interp order)
%               EX  'deriv', 0: results in direct interpolation
%                   'deriv', 2: returns the second derivative
%               (DEFAULT = 0)
%
%   'interp'    Interpolation order (spline order).  Must be
%               0 or odd.
%               EX  'interp', 0: results in low-value lookup
%                   'interp', 1: uses linear interpolation
%                   'interp', 3: uses cupic interpolation
%               (DEFAULT = 3)
%
%   'verbose'   logical - use verbose output? (prints extrapolation warnings)
%               accepts 0,1,'y','n'.  All other inputs will be evaluated to true
%               (DEFAULT = 0)
%
%   'onfail'    what to do if field lookup fails.
%               EX  'onfail', 'fatal':  returns an error and quits
%                   'onfail', NaN:      returns NaN and continues running
%                   'onfail', 12:       returns 12 and continues running
% 
%HOT-tdb release 2.0
%(c) 2007-2009 Christopher R. Martin, Virginia Tech



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% defaults

% verbose output (display extrapolation warnings: 0 suppres, 1 display)
verbose = 0;
% if a requested field does not exist and no special case exists,
% 'fatal': return an error, otherwise: return the value in onfail.
onfail = 'fatal';
% interpolation method
interpolation = 3;
% derivative order
derivative = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code

% fetch the optional parameters from the parameter, value pairs
params = {'deriv', 'interp','verbose', 'onfail'};
value = varargparam(params, varargin{:});

% error check optional parameters and set defaults to unspecified parameters

% interpolation order
if isempty(value{2})
    % use default, do nothing.
elseif isnumeric(value{2}) & value{2}>=0 & (isodd(value{2}) | value{2} == 0)
    interpolation = value{2};
else
    error('Illegal interpolation order: must be zero or positive and odd.')
end

% derivative order
if isempty(value{1})
    % use default, do nothing.
elseif isnumeric(value{1}) & value{1}>=0 & value{1} <= interpolation
    derivative = value{1};
else
    error('Illegal derivative order: must be 0 <= <= interpolation order.')
end

% verbose
if isempty(value{3})
    % use default, do nothing.
else
    verbose = value{3}~=0 & value{3}~='n';
end

%onfail
if isempty(value{4})
    % use default, do nothing
else
    onfail = value{4};
end

% force invalue to a column vector
Nvalue = numel(invalue);
invalue = reshape(invalue,Nvalue,1);

% check for existance of the infield and outfield and namefield
if ~isfield(data, infield)
    if strcmp(onfail, 'fatal')
        error(['Nonexistant field, ''' infield '''']);
    else
        done = onfail;
        return;
    end
end
if ~isfield(data, outfield)
    if strcmp(onfail, 'fatal')
        error(['Nonexistant field, ''' outfield '''']);
    else
        done = onfail;
        return;
    end
end

% check that the fields are vectors of the same size
if numel(getfield(data,infield)) ~= numel(getfield(data,outfield))
    if strcmp(onfail, 'fatal')
        error(['Field vector lengths are not equal'])
    else
        warning(['Field vector lengths are not equal'])
        done = onfail;
        return;
    end
end
N = numel(getfield(data,infield));

% ASSUMES THAT THE INFIELD VECTOR IS MONOTONIC

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% go


% Error checking is done.

done = zeros(numel(invalue),1);    % initialize the output vector
for valindex = 1:Nvalue
    % find the values in the input vector
    index = max(find(getfield(data,infield)<=invalue(valindex)));
    % check for extrapolation
	if any(isempty(index)) % lower end
        index = 1;  % set the index to the minimum value
        if verbose
            warning('Extrapolation on the lower end')
        end
    elseif any(index == N) % upper end
        index = N-1;  % set the index to the minimum value
        if verbose
            warning('Extrapolation on the upper end')
        end
	end
	% cap the interpolation order for points near the edges of the vectors
	temp = min([interpolation, 2*(index-1)+1, 2*(N-index)-1]);

	% form the subset input and output vectors
    indices = [min(index-(temp-1)/2, index) : index+(temp+1)/2];
	eval(['X = data.' infield '(indices);'])
	eval(['Y = data.' outfield '(indices);'])
	
    % center the data for fit
    mu = mean(X);
    sig = std(X);   
	C = polyfit((X-mu)/sig, Y, temp);
    % take the derivatives
	for counter = 1:derivative
        C = C(1:length(C)-1);
        C = C.*[length(C):-1:1]/sig;
	end
	
	done(valindex) = polyval(C, (invalue(valindex) - mu)/sig);
end
