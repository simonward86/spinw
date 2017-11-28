function rootdir = s_rootdir
% path to the SpinW folder
% 
% ### Syntax
% 
% `rootdir = s_rootdir`
% 
% ### Description
% 
% `rootdir = s_rootdir` returns the parent folder of the `swfiles` folder.
% 
% ### See Also
% 
% [spinw]
%

rootdir = mfilename('fullpath');
idx     = strfind(rootdir,filesep);
rootdir = rootdir(1:idx(end-1));

end