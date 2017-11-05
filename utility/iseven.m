function done = iseven(number)
%ISEVEN.M  v1.0	   checks if numbers are even
%
%	done = iseven(number)
%
%This code is a single line of code:
%	done = mod(number,2)==0;
%Returns an array of the same size as number with a 1 when the
%corresponding entry of number is an even integer.
%
%checked for octave compliance with octave 2.9.12
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech

done = mod(number,2) == 0;
