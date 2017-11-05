function done = orderfields(input)
%ORDERFIELDS.M v1.0  sorts struct fields in ABC order
%
%	done = orderfields(input)
%
%This function is useful when dealing with fields by index rather than by name.
%input is a struct with unsorted fields
%done is a struct with fields in ABC order
%
%checked for octave compatibility with octave 2.9.12
% 
%(c) 2005-2009 Christopher R. Martin, Virginia Tech

F = sort(fieldnames(input));
done = struct(F{1},[]);
for index = 1:length(F)
    done = setfield(done, F{index}, getfield(input, F{index}));
end
