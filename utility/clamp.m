function done = clamp(low, value, high)
%CLAMP.M v1.1       force value between two rails
%
%	done = clamp(low, value, high)
%
%This file is one line of code:
%   done = min(high, max(low, value));
%when value > high, done = high
%when value < low, done = low
%otherwise done = value
%
%The clamp function looks like
%
%
%
%       	      ________  high
%       	     /
%       	    /
%	      	   /
%       	  /
%		 /    |
%low 	________/     |
%		      |
%              |      |
%	       |       value = high
%	        value = low
%
%
% checked for octave compliance with octave 2.9.12
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech

done = min(high, max(low, value));
