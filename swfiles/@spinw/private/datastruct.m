function Datastruct = datastruct()
% DATASTRUCT defines the data structure used in spinw object It defines the
% data structure with initial values all are necessary for valid data
% structure.
%

Datastruct.mainfield = {'mag_str'};
Datastruct.subfield = {...
    'F'                 'k'         'nExt'};         % MAG_STR
Datastruct.sizefield = {...
    {3 'nMagExt' 'nK'}  {3 'nK'}    {1 3}};
Datastruct.typefield = {...
    'double'            'double'    'integer'};
Datastruct.defval = {...
    zeros(3,0,0)        zeros(3,0)  int32([1 1 1])};

end