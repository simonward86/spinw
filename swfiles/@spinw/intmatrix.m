function [SS, SI, RR] = intmatrix(obj, varargin)
% generates interaction matrix
% 
% ### Syntax
% 
% `[SS, SI, RR] = intmatrix(obj,Name,Value)`
% 
% ### Description
% 
% `[SS, SI, RR] = intmatrix(obj,Name,Value)` lists the bonds and generates
% the corresponding exchange matrices by applying the bond symmetry
% operators on the stored matrices. Also applies symmetry on the single ion
% anisotropies and can generate the representation of bonds, anistropies
% and atomic positions in an arbitrary supercell. The output argument `SS`
% contains the different types of exchange interactions separated into
% different fields, such as `SS.DM` for the Dzyaloshinskii-Moriya
% interaction, `SS.iso` for Heisenberg exchange, `SS.all` for general
% exchange etc.
% 
% ### Input Arguments
% 
% `obj`
% : [spinw] object.
% 
% ### Name-Value Pair Arguments
% 
% `'fitmode'`
% : Can be used to speed up calculation, modes:
%   * `true`    No speedup (default).
%   * `false`   For the interactions stored in `SS`, only the
%               `SS.all` field is calculated.
% 
% `'plotmode'`
% : If `true`, additional rows are added to `SS.all`, to identify
%   the couplings for plotting. Default is `false`.
% 
% `'sortDM'`
% : If true each coupling is sorted for consistent plotting of
%   the DM interaction. Sorting is based on the `dR` bond vector that
%   points from `atom1` to `atom2`, for details see [spinw.coupling].
%   After sorting `dR` vector components fulfill the following rules in
%   hierarchical order:
%   1. `dR(x) > 0`
%   2. `dR(y) > 0`
%   3. `dR(z) > 0`.
%
%   Default is `false`.
% 
% `'zeroC'`
% : Whether to output bonds with assigned matrices that have only
%   zero values. Default is `false`.
% 
% `'extend'`
% : If `true`, all bonds in the magnetic supercell will be
%   generated, if `false`, only the bonds in the crystallographic
%   unit cell is calculated. Default is `true`.
% 
% `'conjugate'`
% : Introduce the conjugate of the couplings (by exchanging the interacting
%   `atom1` and `atom2`). Default is `false`.
% 
% ### Output Arguments
% 
% `SS`
% : structure with fields `iso`, `ani`, `dm`, `gen`, `bq`, `dip` and
%   `all`. It describes the bonds between spins. Every field is a matrix,
%               where every column is a coupling between two spins. The
%               first 3 rows contain the unit cell translation vector
%               between the interacting spins, the 4th and 5th rows contain
%               the indices of the two interacting spins in the
%               [spinw.matom] list. The following rows contains the
%               strength of the interaction. For isotropic exchange it is a
%               single number, for DM interaction it is a column vector
%               `[DMx; DMy; DMz]`, for anisotropic interaction `[Jxx; Jyy;
%               Jzz]` and for general interaction `[Jxx; Jxy; Jxz; Jyx; Jyy;
%               Jyz; Jzx; Jzy; Jzz]` and for biquadratic exchange it is also
%               a single number. For example:
%   ```
%   SS.iso = [dl_a; dl_b; dl_c; matom1; matom2; Jval]
%   ```
%   If `plotmode` is `true`, two additional rows are added to `SS.all`,
%               that contains the `idx` indices of the
%               `obj.matrix(:,:,idx)` corresponding matrix for each
%               coupling and the `idx` values of the couplings (stored in
%               `spinw.coupling.idx`). The `dip` field contains the dipolar
%               interactions that are not added to the `SS.all` field.
%
% `SI`
% : single ion properties stored in a structure with fields:
%   * `aniso`   Matrix with dimensions of $[3\times 3\times n_{magAtom}]$,
%               where the classical energy of the $i$-th spin is expressed
%               as `E_aniso = spin(:)*A(:,:,i)*spin(:)'`
% 	* `g`       g-tensor, with dimensions of $[3\times 3\times n_{magAtom}]$. It determines
%               the energy of the magnetic moment in external field:
%               `E_field = B(:)*g(:,:,i)*spin(:)'`
% 	* `field`   External magnetic field in a row vector with three elements $(B_x, B_y, B_z)$.
%
% `RR`
% : Positions of the atoms in lattice units in a matrix with dimensions of $[3\times n_{magExt}]$.
% 
% ### See Also
% 
% [spinw.table] \| [spinw.symop]
%
% *[DM]: Dzyaloshinskii-Moriya
%

%if obj.symbolic && obj.symmetry
%    if any(s_mattype(obj.matrix.mat)~=1)
%        warning('spinw:intmatrix:symmetry',['The non-isotropic symbolic matrices '...
%            'will be rotated unsing the point group operators, the result can be ugly!']);
%    end
%end

nExt0 = double(obj.mag_str.nExt);

inpForm.fname  = {'fitmode' 'plotmode' 'zeroC' 'extend' 'conjugate' 'sortDM' 'nExt'};
inpForm.defval = {false     false      false   true     false       false    nExt0 };
inpForm.size   = {[1 1]     [1 1]      [1 1]   [1 1]    [1 1]       [1 1]    [1 3] };

param = s_readparam(inpForm, varargin{:});

nExt = param.nExt;

if prod(nExt) == 1
    param.extend = false;
end

% create parameters of magnetic atoms in the unit cell
mAtom    = obj.matom;

% Send vars to the base class.
param_spin = param;
param_spin = rmfield(param_spin,{'extend','nExt'});
param_spin.conjugate = false;
[SS, SI] = intmatrix@spin(obj,param_spin);

if param.extend
    % Extend the lattice for magnetic interactions
    %nExt = obj.magstr.N_ext;
    [mAtom, SS] = s_extendlattice(nExt, mAtom, SS);
    SI.aniso = repmat(SI.aniso, [1 1 prod(nExt)]);
    SI.g     = repmat(SI.g, [1 1 prod(nExt)]);
    
    % Save the position of all atoms
    RR = mAtom.RRext;
else
    RR = mAtom.r;
end

if param.conjugate
    % Introduce the opposite couplings.
    % (i-->j) and (j-->i)
    % transpose the JJ matrix as well [1 2 3 4 5 6 7 8 9] --> [6 9 12 7 10 13 8 11 14]
    % this step is not necessary for diagonal exchange matrices and
    % biquadratic exchange
    if numel(SS.all) > 0
        new         = [SS.all(1:3,:)   -SS.all(1:3,:)  ];
        new(4:5,:)  = [SS.all([4 5],:)  SS.all([5 4],:)];
        new(6:14,:) = [SS.all(6:14,:)   SS.all([6 9 12 7 10 13 8 11 14],:)]/2;
        new(15,:)   = [SS.all(end,:)    SS.all(end,:)];
        SS.all      = new;
    end
    
    if numel(SS.dip) > 0
        new         = [SS.dip(1:3,:)   -SS.dip(1:3,:)  ];
        new(4:5,:)  = [SS.dip([4 5],:)  SS.dip([5 4],:)];
        new(6:14,:) = [SS.dip(6:14,:)   SS.dip([6 9 12 7 10 13 8 11 14],:)]/2;
        new(15,:)   = [SS.dip(end,:)    SS.dip(end,:)];
        SS.dip      = new;
    end
end

end