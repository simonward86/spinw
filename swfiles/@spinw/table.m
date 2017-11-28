function T = table(obj,type,index,showVal)
% outputs easy to read tables of internal data
%
% ### Syntax
%
% `T = table(obj,type,{index},{showval})`
%
% ### Description
%
% `T = table(obj,type,{index},{showval})` returns a table that shows in an
% easy to read/export format different internal data, such as magnetic atom
% list, bond list, magnetic structure, etc.
%
% For the matrix labels in the list of bonds, the '>>' sign means that the
% matrix value is determined using the bond symmetry operators.
%
% {{note The `table` data type is only supported in Matlab R2013b or newer.
% When running older versions of Matlab, `spinw.table` returns a struct.}}
%
% ### Input Arguments
%
% `obj`
% : [spinw] object.
%
% `type`
% : String, determines the type of data to show, possible values are:
%   * `'mag'`       magnetic structure.
%
% `index`
% : Indexing into the type of data to show, its meaning depends on the
%   `type` parameter. For `'bond'` indexes the bonds (1 for first
%   neighbors, etc.), if empty all bonds will be shown. For `'mag'` it
%   indexes the propagation vectors, the magnetization of the selected
%   propagation vector will be shown. Default value is 1, if empty vector `[]` is given, all
%   bonds/propagation vector will be shown.
%
% `showVal`
% : If `true`, also the values of the single ion and exchange matrices
%   will be shown. The values shown  are the symmetry transformed exchange
%   values after the symmetry operations (if there is any). Default value
%   is `false`.
%
% ### Output Arguments
%
% `T`
% : Matlab `table` type object.
%

if verLessThan('MATLAB','8.2')
    isTable = false;
else
    isTable = true;
end

if nargin<3
    index = 1;
end

if nargin<4
    showVal = false;
end

varName = {};
var     = {};
T_spin = [];

switch type
    case 'mag'
        if ~isempty(obj.mag_str.F)
            nCell = prod(double(obj.mag_str.nExt));
            nK0    = size(obj.mag_str.k,2);
            
            if isempty(index)
                Fdisp    = reshape(obj.mag_str.F,3,[]);
                kIdx = repmat(1:nK0,[1 obj.nmagext]);
                kIdx = kIdx(:);
            else
                Fdisp    = obj.mag_str.F(:,:,index);
                kIdx = repmat(index,[obj.nmagext 1]);
            end
            
            matom = repmat(obj.unit_cell.label(obj.matom.idx),[1 nCell])';
            idx   = repmat(1:numel(obj.matom.idx),[1 nCell])';
            absRF = sqrt(sum(real(Fdisp).^2,1));
            absIF = sqrt(sum(imag(Fdisp).^2,1));
            S     = max(absRF,absIF)';
            absRF(absRF==0) = 1;
            absIF(absIF==0) = 1;
            realFhat = round(bsxfun(@rdivide,real(Fdisp),absRF)'*1e3)/1e3;
            imagFhat = round(bsxfun(@rdivide,imag(Fdisp),absIF)'*1e3)/1e3;
            pos   = round(obj.magtable.R'*1e3)/1e3;
            num   = (1:numel(matom))';
            if nK0>1 && nargin<3
                warning('spinw:table:Multik',['The stored magnetic structure has multiple '...
                    'proppagation vectors, showing only the first, use index to select '...
                    'different propagation vector!'])
            end
            
            if isempty(index)
                kSel = obj.mag_str.k;
            else
                kSel = obj.mag_str.k(:,index);
            end
            
            kvect = round(obj.mag_str.k(:,kIdx)'*1e5)/1e5;
            
            nKdisp = size(kSel,2);
            if nKdisp > 1
                num   = repmat(num,nKdisp,1);
                matom = repmat(matom(:),nKdisp,1);
                idx   = repmat(idx,nKdisp,1);
                pos   = repmat(pos,nKdisp,1);
            end
            
            if any(kSel(:))
                % show imaginary values for non-zero k-vectors
                varName = {'num' 'matom' 'idx' 'S' 'realFhat' 'imagFhat' 'pos' 'kvect'};
                var     = {num    matom   idx   S   realFhat   imagFhat   pos   kvect };
            else
                % no imag
                varName = {'num' 'matom' 'idx' 'S' 'realFhat'            'pos' 'kvect'};
                var     = {num    matom   idx   S   realFhat              pos   kvect };
            end
        end
    otherwise
        T_spin = table@spin(obj,type,index,showVal);
end

% generate table or struct
if isTable
    if isempty(T_spin)
        T = table(var{:},'VariableNames',varName);
    else
        T = T_spin;
    end
else
    if isempty(T_spin)
        T = struct;
        for ii = 1:numel(var)
            T.(varName{ii}) = var{ii};
        end
    else
        T = T_spin;
    end
end

end