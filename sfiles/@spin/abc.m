function abc = abc(obj,ind)
% returns lattice parameters and angles
% 
% ### Syntax
% 
% `latvect = abc(obj)`
% 
% ### Description
% 
% `latvect = abc(obj)` extracts the lattice vectors and angles from a
% [spin] object.
% 
% ### Input Arguments
% 
% `obj`
% : [spin] object.
% 
% ### Output Arguments
% 
% `latVect`
% : Vetor with elements `[a, b, c, \\alpha, \\beta, \\gamma]`,
%   contains the lattice parameters and angles by default in \\ang and
%   degree units respectively (see [spin.unit] for details).
% 
% ### See Also
% 
% [spin.horace]
%

abc = [obj.lattice.lat_const obj.lattice.angle*180/pi];

if nargin>1
    abc = abc(ind);
end

end