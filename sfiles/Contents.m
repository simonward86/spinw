% general functions
%
% This folder contains all the spectral functions and general functions
% that are related to Spin.
%
% ### Files
%
% #### Transforming and plotting calculated spin wave spectrum
%
% These functions operate on the calculated spectra, which is the output of
% [spinw.spinwave] or [spinw.powspec] commands. They enable to post process
% the calculated spin-spin correlation function, including instrumental
% resolution, cross section calculation, binning etc.
%
%   s_econtract      
%
% #### Generate list of vectors in reciprocal space
%
% These two functions can generate a set of 3D points in reciprocal space
% defining either a path made out of straigh lines or a volume.
%
%   s_qgrid
%   s_qscan
%
% #### Resolution claculation and convolution
%
% These functions can import Energy resolution function and convolute it
% with arbitrary multidimensional dataset
%
%   s_res    
%   s_resconv
%
% #### Spin model related functions
%
%   s_extendlattice       
%   s_bonddim      
%
% #### Geometrical calculations
%
% Basic geometrical calculators, functions to generatate rotation
% operators, generate Cartesian coordinate system from a set of vectors,
% calculate normal vector to a set of vector, etc.
%
%   s_basismat
%   s_cartesian
%   s_mattype  
%   s_nvect    
%   s_mirror
%   s_rot      
%   s_rotmat   
%   s_rotmatd  
%
% #### Text and graphical input/output for different high level commands
%
%   s_multicolor  
%   s_timeit      
%
% #### Acessing the Spin database
%
% Functions to read the different data files that store information on
% atomic properties, such as magnetic form factor, charge, etc.
% 
%   s_atomdata
%   s_cff     
%   s_mff     
%   s_nb      
%
% #### Useful physics functions
%
% The two functions can calculate the Bose factor and convert
% energy/momentum units, both usefull for neutron and x-ray scattering.
%
%   s_bose     
%   s_converter
%
% #### Import functions
%
% Functions to import tables in text format.
%
%   s_import   
%
% #### Miscellaneous
%
%   s_freemem   
%   s_readparam 
%   s_rootdir   
%   s_uniquetol        
