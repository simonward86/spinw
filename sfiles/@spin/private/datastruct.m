function Datastruct = datastruct()
% DATASTRUCT defines the data structure used in spinw object It defines the
% data structure with initial values all are necessary for valid data
% structure.
%

Datastruct.mainfield = {...
    'lattice' 'unit_cell' 'twin' 'matrix' 'single_ion' 'coupling'  'unit'};
Datastruct.subfield = {...
    'angle' 'lat_const' 'sym'   'origin'  'label' ''    ''     '' '' '' '';...         % LATTICE
    'r'     'S'         'label' 'color'   'ox'  'occ'  'b' 'ff' 'A' 'Z' 'biso';...     % UNIT_CELL
    'vol'   'rotc'      ''      ''        ''    ''      ''     '' '' '' '';...         % TWIN
    'mat'   'color'     'label' ''        ''    ''      ''     '' '' '' '';...         % MATRIX
    'aniso' 'g'         'field' 'T'       ''    ''      ''     '' '' '' '';...         % SINGLE_ION
    'dl'    'atom1'     'atom2' 'mat_idx' 'idx' 'type'  'sym'  'rdip' 'nsym' '' '';... % COUPLING
    'kB'    'muB'       'mu0'   'label'   'nformula' 'qmat' '' '' '' '' ''};           % UNIT
Datastruct.sizefield = {...
    {1 3}          {1 3}          {3 4 'nSymOp'} {1 3}       {1 'nStr'}  {}          {}    {} {} {} {};...
    {3 'nAtom'}    {1 'nAtom'}    {1 'nAtom'}    {3 'nAtom'} {1 'nAtom'} {1 'nAtom'} {2 'nAtom'} {2 11 'nAtom'} {1 'nAtom'} {1 'nAtom'} {1 'nAtom'};...
    {1 'nTwin'}    {3 3 'nTwin'}  {}             {}          {}          {}          {}    {} {} {} {};...
    {3 3 'nMat'}   {3 'nMat'}     {1 'nMat'}     {}          {}          {}          {}    {} {} {} {};...
    {1 'nMagAtom'} {1 'nMagAtom'} {1 3}          {1 1}       {}          {}          {}    {} {} {} {};...
    {3 'nBond'}    {1 'nBond'}    {1 'nBond'}    {3 'nBond'} {1 'nBond'} {3 'nBond'} {3 'nBond'} {1 1} {1 1} {} {};...
    {1 1}          {1 1}          {1 1}          {1 4}       {1 1}       {3 3}       {}    {} {} {} {}};
Datastruct.typefield = {...
    'double'  'double'  'double'  'double'  'char'    ''        ''       ''       ''        ''        ''      ;...
    'double'  'double'  'char'    'integer' 'double'  'double'  'double' 'double' 'integer' 'integer' 'double';...
    'double'  'double'  ''        ''        ''        ''        ''       ''       ''        ''        ''      ;...
    'double'  'integer' 'char'    ''        ''        ''        ''       ''       ''        ''        ''      ;...
    'integer' 'integer' 'double'  'double'  ''        ''        ''       ''       ''        ''        ''      ;...
    'integer' 'integer' 'integer' 'integer' 'integer' 'integer' 'integer' 'double' 'integer' ''       ''      ;...
    'double'  'double'  'double'  'char'    'integer' 'double'  ''       ''       ''        ''        ''      };

uLabel = {char(197) 'meV' 'T' 'K'};

Datastruct.defval = {...
    pi/2*ones(1,3)    [3 3 3]           zeros(3,4,0)    zeros(1,3)  'P 0'       [] [] [] [] [] [];...
    zeros(3,0)        zeros(1,0)        cell(1,0)       int32(zeros(3,0)) zeros(1,0) zeros(1,0) zeros(2,0) zeros(2,11,0) int32(zeros(1,0)) int32(zeros(1,0)) zeros(1,0);...
    1                 eye(3)            []              []          []          []      [] [] [] [] [];...
    zeros(3,3,0)      int32(zeros(3,0)) cell(1,0)       []          []          []      [] [] [] [] [];...
    int32(zeros(1,0)) int32(zeros(1,0)) [0 0 0]         0           []          []      [] [] [] [] [];...
    int32(zeros(3,0)) int32(zeros(1,0)) int32(zeros(1,0)) int32(zeros(3,0)) int32(zeros(1,0)) int32(zeros(3,0)) int32(zeros(3,0)) 0 int32(0) [] [];...
    0.086173324       0.057883818066    201.335431      uLabel      int32(0)    eye(3) [] [] [] [] []};
% 0.086173324     Boltzmann constant: k_B [meV/K]
% 0.057883818066  Bohr magneton: mu_B [meV/T]
% 1.602176565e-19 electron charge: e [C] 
% 4*pi*10*e       vacuum permeability: mu0 [T^2*A^3/meV]
% g-tensor is given separately

end