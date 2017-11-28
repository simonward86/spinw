% general functions
%
% This folder contains all the spectral functions and general functions
% that are related to SpinW.
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
%   sw_egrid     
%   sw_filelist  
%   sw_instrument
%   sw_magdomain 
%   sw_neutron   
%   sw_omegasum  
%   sw_plotspec  
%   sw_xray      
%
%
% #### Resolution claculation and convolution
%
% These functions can import Energy resolution function and convolute it
% with arbitrary multidimensional dataset
%
%   sw_tofres 
%
% #### SpinW model related functions
%
%   sw_fstat        
%   sw_model        
%
% #### Constraint functions
%
% Contraint functions for [spinw.optmagstr].
%
%   gm_planar      
%   gm_planard     
%   gm_spherical3d 
%   gm_spherical3dd
%
% #### Geometrical calculations
%
% Basic geometrical calculators, functions to generatate rotation
% operators, generate Cartesian coordinate system from a set of vectors,
% calculate normal vector to a set of vector, etc.
%
%   sw_fsub        
%   sw_quadell   
%
% #### Text and graphical input/output for different high level commands
%
%   sw_parstr      
%    
%
%
% #### Import functions
%
% Functions to import tables in text format.
%
%   sw_readspec 
%   sw_readtable
%
% #### Miscellaneous
%
%   swdoc
%   sw_update    
%   sw_version   
%   sw_mex       
