function done = spratio(data, varargin)
%SPRATIO.M   compute a mixture's ratio of specific heats
%
%   r = spratio(data, species, mass, T)
%       or
%   r = spratio(data, state)
%
%Computes a 2-D array of the ideal gas constant for various mixtures
%at various temperatures.  If the properties being computed do not
%require temperature as an input, it may be omitted from the 
%function call.
%
%=================================================================
%data       -   janaaf data struct array 
%                    OR 
%               cell array containing multiple janaaf data struct arrays
%
%
%species    -   cell array of species names or a single species name
%
%mass       -   2-D array of mass fractions or absolute species masses
%               each row corresponds to an element in species (t.f. 
%               needs the same number of rows as species has elements)
%               In addition, each column in mass will correspond to a 
%               new set of data in the output.  In this way, one call
%               to THERMAL can return multiple mixture results.
%
%T          -   Temperature vector.  Must be a column vector of 
%               temperatures in K. 
%
%state      -   state struct as defined by STATEGEN
%
%r    	    -   a 2-D numeric array containing the computed property values.
%               r(m,n) = specific heat at temperature, m, for mixture, n.
%
%See also:
%   enthalpy, entropy
% 
%HOT-tdb release 2.0
%(c) 2007-2009 Christopher R. Martin, Virginia Tech



% check for a state structure
if isstruct(varargin{1})
    % if one is present, grab the relevant information
    statemode = 1;
    mass = varargin{1}.mass;
    species = varargin{1}.species;
    T = varargin{1}.T;
else
    statemode = 0;
    species = varargin{1};
    mass = varargin{2};
    T = varargin{3};
end


% initialize the output array.
done = spheat(data,species,mass,T);
done = done./(done-repmat(igconstant(data,species,mass),[numel(T),1]));
