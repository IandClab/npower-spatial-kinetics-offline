function done = shuffle(varargin)
%SHUFFLE v1.0 shuffle multiple arrays or cell arrays together
%
%	X = shuffle(X1, X2, X3, ..., XN)
%
%Shuffle assembles the arrays X1 through XN into X so that
%X will be
%
%  X = [ X1(1) X2(1) X3(1) ... XN(1) X1(2) X2(2) X3(2) ... 
%	XN(2) ... ]
%
% 
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech



N = numel(varargin);
n = zeros(N,1);
needcell = 0;
% get the length of each array
for I = 1:N
	n(I) = numel(varargin{I});
	needcell = needcell | iscell(varargin{I});
end

% get the total number of elements and initialize the done array
m = sum(n);
if needcell
	done = cell(m,1);
else
	done = zeros(m,1);
end
% create an array of counters - one for each array
J = zeros(1,N);
% keep a counter to indicate which array is currently being referenced
K = 0;
for I = 1:m
    % continue to increment the array counter until the current array is
    % not at its end
    K = K+1;
    if K>N
        K=1;
    end
    while J(K) == n(K)
		K=K+1;
		if K>N
			K = 1;
		end
    end
	% increment the position counter
	J(K) = J(K)+1;
	% if the output is a cell array
	if needcell
		% if the current array is a cell array
		if iscell(varargin{K})
			done{I} = varargin{K}{J(K)};
		else
			done{I} = varargin{K}(J(K));
		end
	else
		done(I) = varargin{K}(J(K));
    end

end
