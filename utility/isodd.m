function done = isodd(number)
%ISODD.M v1.0	checks that numbers are odd integers
%
%	done = isodd(number)
%
%This is literally one line of code:
%	done = mod(number+1,2)==0;
%Returns an array of the same size as number such that each entry
%is a bool indicating if number is an odd integer.
%
%checked for octave compliance with octiave 2.9.12
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech

done = mod(number+1,2) == 0;
