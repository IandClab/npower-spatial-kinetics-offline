function done = density(data, varargin)
%DENSITY.M
%
%   rho = density(data, species, mass, T, P)
%       or
%   rho = density(data, state)
%
%Computes a 2-D array of density for various mixtures
%at various temperatures.  
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
%
%rho   	    -   a 2-D numeric array containing the computed property values.
%               rho(n,m) = density at temperature (n) and mixture (m)
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
    P = varargin{1}.P;
else
    statemode = 0;
    species = varargin{1};
    mass = varargin{2};
    T = varargin{3};
    P = varargin{4};
end


done = P./(igconstant(data,species,mass).*T);
