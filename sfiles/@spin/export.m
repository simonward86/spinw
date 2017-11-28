function varargout = export(obj, varargin)
% export data into file
% 
% ### Syntax
% 
% `export(obj,Name,Value)`
% 
% `outStr = export(obj,Name,Value)`
%
% ### Description
% 
% `export(obj,Name,Value)` exports different types of spin object data.
%
% `outStr = export(obj,Name,Value)` returns a string instead of writing the
% data into a file.
%
% ### Examples
% 
% In this example the crystal structure is imported from the `test.cif`
% file, and the atomic positions are saved into the `test.pcr` file for
% FullProf refinement (the pcr file needs additional text to work with
% FullProf).
%
% ```
% cryst = sw('test.cif');
% cryst.export('format','pcr','path','test.pcr');
% ```
%
% ### Input arguments
%
% `obj`
% : [spin] object.
%
% ### Name-Value Pair Arguments
%
% `'format'`
% : Determines the output data and file type. The supported file formats
%   are:
%   * `'pcr'`   Creates part of a .pcr file used by [FullProf](https://www.ill.eu/sites/fullprof). It exports the
%     atomic positions.
%
% `'path'`
% : Path to a file into which the data will be exported, `out` will
%   be `true` if the file succesfully saved, otherwise `false`.
%
% `'fileid'`
% : File identifier that is already opened in Matlab using the
%   `fileid = fopen(...)` command. Don't forget to close the file
%   afterwards.
%  
% #### File format dependent options:
%  
% `'perm'` (`pcr`)
% : Permutation of the $xyz$ atomic positions, default value is `[1 2 3]`.
%  
% `'boundary'` (`MC`)
% : Boundary conditions of the extended unit cell. Default value is `{'per'
%   'per' 'per'}`. The following strings are accepted:
%   * `'free'`  Free, interactions between extedned unit cells are omitted.
%   * `'per'`   Periodic, interactions between extended unit cells are
%     retained.
%  
% {{note If neither `path` nor `fileid` is given, the `outStr` will be a
% cell containing strings for each line of the text output.}}
%  

inpForm.fname  = {'format' 'path' 'fileid' 'perm'  'boundary'          };
inpForm.defval = {''       ''      []      [1 2 3] {'per' 'per' 'per'} };
inpForm.size   = {[1 -1]   [1 -2] [1 1]    [1 3]   [1 3]               };
inpForm.soft   = {true     true    true    false   false               };

warnState = warning('off','s_readparam:UnreadInput');
param = s_readparam(inpForm, varargin{:});
warning(warnState);

% produce the requested output
if isempty(param.path) && isempty(param.fileid) && nargout == 0
    % dialog to get a filename
    [fName, fDir] = uiputfile({'*.pcr','FullProf file (*.pcr)';'*.spt','Jmol script (*.spt)';'*.*' 'All Files (*.*)'}, 'Select an output filename');
    param.path = [fDir fName];
    if ~any(isempty(param.path))
        warning('spin:export:NoInput','No file is given, no output is produced!');
        return
    end
    if isempty(param.format)
        [~,~,fExt] = fileparts(param.path);
        param.format = fExt(2:end);
    end
end

switch param.format
    case 'pcr'
        % create .pcr text file
        outStr = createpcr(obj, param.perm);
    case 'spt'
        % create Jmol script file
        if nargin == 2
            varargin{1}.format = 'jmol';
        else
            varargin{end+1} = 'format';
            varargin{end+1} = 'jmol';
        end
        
        warnState = warning('off','s_readparam:UnreadInput');
        outStr = plot(obj, varargin{:});
        warning(warnState);
    case ''
        warning('spin:export:NoInput','No ''format'' option was given, no output is produced!');
        if nargout > 0
            varargout{1} = {};
            return
        end
    otherwise
        error('spin:export:WrongInput','''format'' has to be one of the strings given in the help!');
end

if nargout > 0
    varargout{1} = outStr;
end

% write into fid file
if ~isempty(param.fileid)
    fprintf(param.fileid,outStr);

elseif ~isempty(param.path)
    try
        fileid = fopen(param.path,'w');
        fprintf(fileid,outStr);
        fclose(fileid);
    catch
        % file couldn't be saved
        error('spin:export:UnableToOpenFile','Cannot write into file ''%s''!',param.path)
    end
    return
end

end

function out = createpcr(obj, perm)
% CREATEPCR(obj, perm) creates the structural part of a pcr file
% from a .cif file.
%
% This function will create the atomic positions from an spin object in the
% input format for FullProf Rietveld refinement software.
%
% perm  Permutation of the (x,y,z) coordinates.
%

% generate all atoms in the unit cell to count site multiplicities
atoms = obj.atom;
mult = accumarray(atoms.idx',ones(numel(atoms.idx),1));
mult = mult/max(mult);

% output string
out = sprintf('!Atom   Typ       X        Y        Z     Biso       Occ     In Fin N_t Spc /Codes\n');

nAtom = size(obj.unit_cell.r,2);

uc = obj.unit_cell;

% split labels into [aname, alabel]
% aname: name of atom (e.g. 'Cr')
% alabel: label if given (eg' 'MCr3'), otherwise the same as the name of
% the atom
uc.aname = cell(1,nAtom);
uc.alabel = cell(1,nAtom);

for ii = 1:nAtom
    lTemp = strword(uc.label{ii},[1 2],true);
    uc.alabel{ii} = lTemp{1};
    uc.aname{ii} = lTemp{2};
end

% find unique labels for atoms
for ii = 1:nAtom
    uc.ulabel(ii) = ~(sum(strcmp(uc.alabel,uc.alabel{ii}))>1);
end

% sort atoms according to the
idx = 0;
for ii = 1:nAtom
    if ~uc.ulabel(ii)
        % not unique atom labels put extra number
        strT = sprintf('%s%d',uc.alabel{ii},idx);
        idx = idx + 1;
    else
        % no extra numbering
        strT = sprintf('%s',uc.alabel{ii});
    end
    % pad the string to 6 characters with whitespace
    if numel(strT)<6
        strT((end+1):6) = ' ';
    end
    strT = [strT sprintf(' %s',uc.aname{ii})]; %#ok<*AGROW>
    % pad the string to 14 characters with whitespace
    if numel(strT)<13
        strT((end+1):13) = ' ';
    end
    
    out = [out strT sprintf('%9.5f%9.5f%9.5f%9.5f%9.5f%4d%4d%4d%4d\n',uc.r(perm,ii)',0,mult(ii),[0 0 0 0])];
    out = [out sprintf('                  0.00     0.00     0.00     0.00      0.00\n')];
end

end
