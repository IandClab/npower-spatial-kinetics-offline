function varargout = stategen(varargin)
%STATEGEN.M  build a thermodynamic state structure
%
%   mystate = stategen(species, mass)
%       or
%   mystate = stategen(species, mass, T)
%       or
%   mystate = stategen(species, mass, T, P)
%       or
%   mystate = stategen(species, mass, T, P, v)
%       or
%   [ T, P, v, mass, species] = stategen(mystate)
%       or
%   stategen(mystate)
%
%Constructs and deconstructs state structs used by PROCESS.
%
%species    cell array of species strings used by high-level
%           function like ENTHALPY and MWEIGHT.
%
%mass       A column vector of the same length as species
%           specifying the mass of each specie present.
%
%T          The scalar temperature
%
%P          The scalar pressure
%
%v          mixture velocity
%
%mystate    A state struct with fields:
%           species, mass, T, P, v
%
%The order of the outputs is purposefully changed so that the
%least interesting outputs are last.  That way, one only need
%collect the outputs of interest; e.g.
%
%   [T,P] = stategen(mystate);
%
%Also, if the temperature, pressure, velocity, or mixture 
%appear as vectors (or a maxtrix in the case of mixture)
%then STATEGEN will check the size of all other properties
%to ensure proper formatting.
%
%In the last case, STATEGEN serves only as a means of checking
%for a badly formatted state struct.  If there is a problem,
%STATEGEN will exit with an error.
%
%   See also:
%process.m
%

Tref = 298.15;
Pref = 101300;
vref = 0;


% if called in constructor mode.
if nargin>=2
    % check the variable data format
    Nspec = length(varargin{1});
    N = size(varargin{2},2);

    % initialize the struct.  struct.m outsmarts itself if we
    % try to do this in one step.
    varargout{1} = struct('species',1,'mass',1,'T',Tref,'P',Pref,'v',vref);
    varargout{1}.species = varargin{1};
    varargout{1}.mass = varargin{2};

    if nargin>=3
        temp = numel(varargin{3});
        if temp == N | temp == 1 | N == 1
            varargout{1}.T = varargin{3};
            N = max(temp,N);
        else
            error('Temperature vector size missmatch')
        end
    end
    if nargin>=4
        temp = numel(varargin{4});
        if temp == N | temp == 1 | N == 1
            varargout{1}.P = varargin{4};
            N = max(temp,N);
        else
            error('Pressure vector size missmatch')
        end
    end
    if nargin>=5
        temp = numel(varargin{4});
        if temp == N | temp == 1 | N == 1
            varargout{1}.v = varargin{5};
            N = max(temp,N);
        else
            error('Velocity vector size missmatch')
        end
    end
% if called in deconstructor mode.
elseif nargin == 1
    % check the struct format
    if ~isstruct(varargin{1})
        error('Need a struct to deconstruct!  Type "help stategen" for details.')
    elseif ~isfield(varargin{1},'species') | ~isfield(varargin{1},'mass') | ~isfield(varargin{1},'T') | ~isfield(varargin{1},'P')
        error('Struct must have fields: ''species'', ''mass'', ''T'', and ''P''.')
    end
    N = numel(getfield(varargin{1},'T'));
    Nspec = length(getfield(varargin{1},'species'));
    if numel(getfield(varargin{1},'P')) ~= N
        error('T and P vector sizes do not match.')
    elseif any(size(getfield(varargin{1},'mass')) ~= [Nspec N])
        error('Mass matrix size missmatch.')
    end

    if nargout>0
        varargout{1} = getfield(varargin{1},'T');
    end
    if nargout>1
        varargout{2} = getfield(varargin{1},'P');
    end
    if nargout>2
        varargout{3} = getfield(varargin{1},'v');
    end
    if nargout>3
        varargout{4} = getfield(varargin{1},'mass');
    end
    if nargout>4
        varargout{5} = getfield(varargin{1},'species');
    end
    if nargout>5
        warning('Only supports five outputs!')
    end
else
    error('Incorrect number of arguments')
end
