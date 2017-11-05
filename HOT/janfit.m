function done = janfit(C, F, Trange, T, varargin)
%JANFIT  evaluate curve fit data in a janaf data struct
%   JANAF data lookup toolbox
%   written by Chris Martin 5/2008
%   modified 4/2009
%
%   output = janfit(C, F, Trange, T, param1, value1, ...)
%
% Evaluates curve fit data in the JANAF struct, data.  JANFIT makes no
%assumptions about the fields of data.  
%========================================================
%
%   REWRITE NEEDED!!!
%       in- and out-put parameters here!
%
%=========================================================
%optional param, value pairs:% check that the coefficient and function fields are properly formatted
%
%   'deriv'     non-negative integer - indicates the order of derivative to 
%               compute.  For example, if C and F represent fit functions for
%               the enthalpy of a substance,
%                   janfit(C,F,400,'deriv',1)
%               will return the specific heat at 400 K
%               If C and F represent fit functions for the specific heat of a
%               substance,
%                   janfit(C,F,400,'deriv',-1)
%               will return the enthalpy at 400 K.  The integration coefficient
%               is automatically taken such that all integrals are zero when the
%               independent variable is 298.15.  This reference state can be 
%               changed using the 'reference' parameter.
%               (DEFAULT = 0)
%
%   'reference' numeric or character - indicates the reference state for 
%               integrations; the value of the independent variable at which 
%               integrations are taken to be zero.  This typically accepts a 
%               numeric value, but also recognizes 'R', 'F', 'C', and 'K';
%               corresponding to the standard reference temperatures in 
%               Rankine (527.67), Farenheit (68), Celcius (20), and Kelvin
%               (298.15)
%               (DEFAULT = 'K')
%               
%   'verbose'   logical - use verbose output? (prints extrapolation warnings)
%               accepts 0,1,'y','n'.  All other inputs will be evaluated to true
%               (DEFAULT = 0)
%
%   'onfail'    what to do if field lookup fails.
%               EX  'onfail', 'fatal':  returns an error and quits
%                   'onfail', NaN:      returns NaN and continues running
%                   'onfail', 12:       returns 12 and continues running
%               (DEFAULT = 'fatal')
%
%See also:
%   janlookup, janload, jansave

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
% order of derivative to take
deriv = 0;
% reference temperature for integrations
reference = 'K';


% fetch the optional parameters from the parameter, value pairs
params = {'verbose--ob', 'onfail', 'deriv--oi', 'reference--of'};
value = varargparam(params, varargin{:});

% error check optional parameters and set defaults to unspecified parameters

% verbose
if ~isempty(value{1})
    verbose = value{1}~=0 & value{1}~='n';
end

%onfail
if ~isempty(value{2})
    onfail = value{2};
end

% deriv
if ~isempty(value{3})
    deriv = floor(value{3});
end

if ~isempty(value{4})
    reference = value{4};
end

% deal with reference value
if ischar(reference)
    if reference == 'K'
        reference = 298.15;
    elseif reference == 'R'
        reference = 527.67;
    elseif reference == 'C'
        reference = 20.00;
    elseif reference == 'F'
        reference = 68;
    else
        if strcmp(onfail, 'fatal')
            error(['Unrecognized reference specifier.  Must be K, R, C, or F.'])
        else
            warning(['Unrecognized reference specifier.  Must be K, R, C, or F.'])
            done = onfail*ones(size(invalue));
            return;
        end
    end
elseif ~isnumeric(reference)
    if strcmp(onfail, 'fatal')
        error(['Illegal reference value.'])
    else
        warning(['Illegal reference value.'])
        done = onfail*ones(size(invalue));
        return;
    end
end

% check that the coefficient and function fields are properly formatted
if ~isnumeric(F)
    if strcmp(onfail, 'fatal')
        error(['Function specifier must be numeric.'])
    else
        warning(['Function specifier must be numeric.'])
        done = onfail*ones(size(invalue));
        return;
    end
end

if ~isnumeric(C)
    if strcmp(onfail, 'fatal')
        error(['Coefficient array must be numeric.'])
    else
        warning(['Coefficient array must be numeric.'])
        done = onfail*ones(size(invalue));
        return;
    end
end

if ~isnumeric(T)
    if strcmp(onfail, 'fatal')
        error(['Temperature array must be numeric.'])
    else
        warning(['Temperature array must be numeric.'])
        done = onfail*ones(size(invalue));
        return;
    end
end

% get the coefficient dimensions
Nc = size(C);
% get the temperature array length
NT = numel(T);

% check that there is a matching number of function specifiers
if numel(F)~=Nc(1)
    if strcmp(onfail, 'fatal')
        error(['Function-coefficient vector length missmatch'])
    else
        warning(['Function-coefficient vector length missmatch'])
        done = onfail*ones(size(invalue));
        return;
    end
% and a matching number of Temperature range specifiers
elseif numel(Trange)~=Nc(2)
    if strcmp(onfail, 'fatal')
        error(['Trange-coefficient vector length missmatch'])
    else
        warning(['Trange-coefficient vector length missmatch'])
        done = onfail*ones(size(invalue));
        return;
    end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% go



% correct the F and C arrays based on the deriv number.
%  if the derivative index is positive --> derivatives
if deriv>0
    % find all functions that have a nonzero derivative
    Inormal = find(F>=deriv | F<0);
    for index = Inormal.'
        C(index,:) = C(index,:)*prod( (F(index)-deriv+1):F(index) );
    end
    F(Inormal) = F(Inormal)-deriv;
    % find all logarithms
    Ilog = find(isnan(F) | isinf(F));
    C(Ilog,:) = C(Ilog,:).*prod( -deriv:-1 );
    F(Ilog) = -deriv*ones(size(Ilog));
    % eliminate all other functions
    if isempty(Inormal)
        I = Ilog;
    elseif isempty(Ilog)
        I = Inormal;
    else
        I = [Inormal(:) Ilog(:)];
    end
    if isempty(I)
        C = zeros(1,Nc(2));
        F = 0;
    else
        C = C(I,:);
        F = F(I,:);
    end
% if the derivative index is negative --> integrals
elseif deriv<0
    % test for integrals of log(x)
    if any((F>deriv & F<0) | isnan(F) | isinf(F))
        if strcmp(onfail, 'fatal')
            error(['Integrals of natural logs not supported.'])
        else
            warning(['Integrals of natural logs not supported.'])
            done = onfail*ones(size(invalue));
            return;
        end
    end
    
    % find the reference temperaure in the Trange array
    Iref = min([find(reference<=Trange) Nc(2)]);
    
    % loop through the integrations
    for D = deriv:-1
        % perform the integrations
        F = F+1;
        % deal with normal integrals
        I = find(F~=0);
        C(I,:) = C(I,:)./repmat(F(I),1,Nc(2));
        % deal with integrals resulting in logarithms
        I = find(F==0);
        F(I) = inf*ones(size(I));

        % deal with the integration constants
        F(end+1) = 0; % create a new constant function
        % compute the first constant based on the reference temperature
        C(Nc(1)+1,Iref) = -evaluate(C(:,Iref),F,reference); % use the sloppy method for increasing the size of C
        % update the Nc array
        Nc = size(C);        
        % compute all the other integration constants based on the Iref constant
        for index = Iref+1:Nc(2)
            C(Nc(1),index) = evaluate(C(:,index-1),F,Trange(index-1)) - evaluate(C(:,index),F,Trange(index-1));
        end
        for index = Iref-1:-1:1
            C(Nc(1),index) = evaluate(C(:,index+1),F,Trange(index)) - evaluate(C(:,index),F,Trange(index));
        end        
    end
end

% assign fit coefficients to each of the temperature data points
Irange = ones(NT,1);
for index = 1:NT
    Irange(index) = min([find(T(index)<=Trange) Nc(2)]);
end


% initialize the done array
done = zeros(size(T));
%Perform the final calculations
% loop through the Trange elements
for index = 1:Nc(2)
    % identify all temperature elements in the current Temp range
    I = find(Irange==index);
    done(I) = evaluate(C(:,index),F,T(I));
end


function done = evaluate(C,F,values)
done = zeros(size(values));
for I = 1:length(C)
    if isnan(F(I)) | isinf(F(I))
        done = done + C(I)*log(values);
    else
        done = done + C(I)*values.^F(I);
    end
end
