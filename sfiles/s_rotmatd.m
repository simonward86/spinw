function rotM = s_rotmatd(rotAxis, rotAngle)
% generates 3D rotation matrix
% 
% ### Syntax
% 
% `R = s_rotmatd(rotAxis,rotAngle)`
%
% ### Description
% 
% `R = s_rotmatd(rotAxis,rotAngle)` produces the `R` rotation matrix, for
% identically to [s_rotmat], except that here the unit of `rotAngle` is
% \\deg.
%
% ### See Also
%
% [s_rotmat] \| [s_rot]
%

if nargin==0
    help s_rotmatd
    return
end

[~, rotM] = s_rot(rotAxis,rotAngle*pi/180);

end