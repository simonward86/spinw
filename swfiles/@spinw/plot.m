function varargout = plot(obj, varargin)
% plots 3D model
% 
% ### Syntax
% 
% `plot(obj,Name,Value)`
% `hFigure = plot(obj,Name,Value)`
% 
% ### Description
% 
% `plot(obj,Name,Value)` plots the atoms and couplings stored in `obj` onto
% an [swplot] figure (see [swplot.figure]). The generated 3D plot can be
% rotated using the mouse and panning works by keeping the Ctrl/Control
% button pressed. There is information about every object on the figure
% (here called tooltips) that is shown when clicked on the object. The 3D
% view direction can be changed programatically using [swplot.view] while
% translations are controlled using the [swplot.translate]. Arbitrary
% transformation (combination of rotation and translation) can be
% introduced using the [swplot.transform]. All these transformation act as
% a global transformation, relative transformation of the 3D objects is
% only possible at creation by defining the transformed coordinates.
%  
% The `spinw.plot` function calls several high level plot routines to draw
% the different types of objects: [swplot.plotatom] (atoms),
% [swplot.plotmag] (magnetic moments), [swplot.plotion] (single ion
% properties), [swplot.plotbond] (bonds), [swplot.plotbase] (basis vectors)
% and [swplot.plotcell] (unit cells).
%  
% The high level `spinw.plot` function can send send parameters to any of
% the above plot group functions. The paramer name has to be of the format:
% `['plot group name' 'group option']`. For example to set the `color` option
% of the cell (change the color of the unit cell) use the option
% 'cellColor'. In this case `spinw.plot` will call the [swplot.plotcell]
% function with the `color` parameter set to the given value. For all the
% possible group plot function options see the corresponding help.
%  
% It is possible to switch off calling any of the subfunctions by using the
% option `['plot group name' 'mode']` set to `'none'`. For example to skip
% plotting of the atoms set the `'atomMode'` parameter to `'none'`:
% `spinw.plot('atomMode','none')`.
%  
% ### Name-Value Pair Arguments
%  
% These are global options, that each plot group function recognizes, these global
% options can be added without the group name.
% 
% `'range'`
% : Plotting range of the lattice parameters in lattice units,
%   in a matrix with dimensions of $[3\times 2]$. For example to plot the
%   first unit cell, use: `[0 1;0 1;0 1]`. Also the number unit cells can
%   be given along the $a$, $b$ and $c$ directions, e.g. `[2 1 2]`, this is
%   equivalent to `[0 2;0 1;0 2]`. Default value is the single unit cell.
% 
% `'unit'`
% : Unit in which the range is defined. It can be the following
%   string:
%   * `'lu'`        Lattice units (default).
%   * `'xyz'`       Cartesian coordinate system in \\ang units.
% 
% `'figure'`
% : Handle of the [swplot] figure. Default is the active figure.
% 
% `'legend'`
% : Whether to add legend to the plot, default value is `true`, for details
%   see [swplot.legend].
% 
% `'fontSize'`
% : Font size of the atom labels in pt units, default value is stored in
%   `swpref.getpref('fontsize')`.
% 
% `'nMesh'`
% : Resolution of the ellipse surface mesh. Integer number that is
%   used to generate an icosahedron mesh with $n_{mesh}$ number of
%   additional triangulation, default value is stored in
%   `swpref.getpref('nmesh')`.
% 
% `'nPatch'`
% : Number of points on the curve for the arrows and cylinders,
%   default value is stored in `swpref.getpref('npatch')`.
% 
% `'tooltip'`
% : If `true`, the tooltips will be shown when clicking on the plot.
%   Default value is `true`.
% 
% `'shift'`
% : Column vector with 3 elements, all objects will be shifted by
%   the given value. Default value is `[0;0;0]`.
% 
% `'replace'`
% : Replace previous plot if `true`. Default value is `true`.
% 
% `'translate'`
% : If `true`, all plot objects will be translated to the figure
%   center. Default is `true`.
% 
% `'zoom'`
% : If `true`, figure will be automatically zoomed to the ideal scale.
%   Default value is `true`.
%
% ### See Also
%  
% [swplot.plotatom] \| [swplot.plotmag] \| [swplot.plotion] \| 
% [swplot.plotbond] \| [swplot.plotbase] \| [swplot.plotcell]
%

% Plot types
fn_wrapper.plotName = {'atom' 'mag' 'bond' 'ion' 'cell' 'base' 'chem'};
% list of plot functions
fn_wrapper.plotFun = {@swplot.plotatom @swplot.plotmag @swplot.plotbond @swplot.plotion @swplot.plotcell @swplot.plotbase @swplot.plotchem};

if nargout > 0
    varargout = cell(1,numel(nargout));
    [varargout{:}] = plot_base(obj,fn_wrapper,varargin{:});
else
    plot_base(obj,fn_wrapper,varargin{:});
end

end