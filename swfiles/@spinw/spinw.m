classdef spinw < spin
    % class to store and solve magnetic Hamiltonians
    %
    % ### Syntax
    %
    % `obj = spinw`
    %
    % `obj = spinw(obj)`
    %
    % `obj = spinw(source)`
    %
    % `obj = spinw(figure_handle)`
    %
    % ### Description
    %
    % `obj = spinw` constructs an empty spinw class object.
    %
    % `obj = spinw(obj)` constructs a spinw class object from the
    % parameters defined in `obj`. If `obj` is spinw class, it only checks
    % the integrity of its internal data structure. If `obj` is struct
    % type, it creates new spinw object and checks data integrity.
    %
    % `obj = spinw(source)` construct new spinw class object, where
    % `source` is either a file path pointing to a local `cif` or `fst`
    % file or a link to an online file.
    %
    % `obj = spinw(figure_handle)` copy the spinw object stored in a
    % previous structural 3D plot figure, referenced by `figure_handle`.
    %
    %
    % The data structure within the spinw object can be accessed by using
    % [spinw.struct] method. All fields of the struct type data behind the
    % spinw object are accessible through the main field names of the `obj`
    % object. For example the lattice parameters can be accessed using:
    %
    % ```
    % abc = obj.unit_cell.lat_const
    % ```
    %
    % spinw is a handle class, which means that only the handle of the
    % object is copied in an assinment command `swobj1 = swobj2`. To create
    % a copy (clone) of an spinw object use:
    %
    % ```
    % swobj1 = swobj2.copy
    % ```
    %
    % ### Properties
    %
    % The data within the `spinw` object is organized into a tree structure
    % with the main groups and the type of data they store are the
    % following:
    %
    % * [spinw.lattice] unit cell parameters
    % * [spinw.unit_cell] atoms in the crystallographic unit cell
    % * [spinw.twin] crystal twin parameters
    % * [spinw.matrix] 3x3 matrices for using them in the Hailtonian
    % * [spinw.single_ion] single ion terms of the Hamiltonian
    % * [spinw.coupling] list of bonds
    % * [spinw.mag_str] magnetic structure
    % * [spinw.unit] physical units for the Hamiltonian
    % * [spinw.cache] temporary values
    %
    % ### Methods
    %
    % Methods are the different commands that require a `spinw` object as a
    % first input, thus they can be called as `method1(obj,...)`,
    % alternatively the equivalent command is `obj.method1(...)`. The list
    % of public methods is below.
    %
    % #### Lattice operations
    %
    %   spinw.genlattice
    %   spinw.basisvector
    %   spinw.rl
    %   spinw.nosym
    %   spinw.newcell
    %   spinw.addatom
    %   spinw.unitcell
    %   spinw.abc
    %   spinw.atom
    %   spinw.matom
    %   spinw.natom
    %   spinw.formula
    %   spinw.disp
    %   spinw.symmetry
    %
    % #### Plotting
    %
    %   spinw.plot
    %
    % #### Crystallographic twin operations
    %
    %   spinw.addtwin
    %   spinw.twinq
    %   spinw.notwin
    %
    % #### Magnetic structure operations
    %
    %   spinw.genmagstr
    %   spinw.magstr
    %   spinw.magtable
    %   spinw.nmagext
    %   spinw.optmagstr
    %   spinw.optmagk
    %   spinw.optmagsteep
    %   spinw.anneal
    %   spinw.annealloop
    %   spinw.structfact
    %
    % #### Matrix operations
    %
    %   spinw.addmatrix
    %   spinw.getmatrix
    %   spinw.setmatrix
    %
    % #### Spin Hamiltonian generations
    %
    %   spinw.quickham
    %   spinw.gencoupling
    %   spinw.addcoupling
    %   spinw.couplingtable
    %   spinw.addaniso
    %   spinw.addg
    %   spinw.field
    %   spinw.temperature
    %   spinw.intmatrix
    %   spinw.symop
    %   spinw.setunit
    %
    % #### Solvers
    %
    %   spinw.spinwave
    %   spinw.powspec
    %   spinw.energy
    %   spinw.moment
    %   spinw.spinwavesym
    %   spinw.symbolic
    %   spinw.meanfield
    %   spinw.fourier
    %   spinw.fouriersym
    %
    % #### Fitting spin wave spectrum
    %
    %   spinw.fitspec
    %   spinw.matparser
    %   spinw.horace
    %
    % #### Miscellaneous
    %
    %   spinw.copy
    %   spinw.export
    %   spinw.table
    %   spinw.validate
    %   spinw.version
    %   spinw.struct
    %   spinw.clearcache
    %   spinw.spinw
    %
    % ### See also
    %
    % [spinw.copy], [spinw.struct], [Comparing handle and value classes](https://www.mathworks.com/help/matlab/matlab_oop/comparing-handle-and-value-classes.html)
    %
    
    properties (SetObservable)
        % stores the magnetic structure
        %
        % ### Sub fields
        %
        % `F`
        % : Complex magnetization (strictly speaking complex
        %   spin expectation value) for every spin in the magnetic
        %   cell, represented by a matrix with dimensions of $[3\times
        %   n_{magext}\times n_k]$,
        %   where `nMagExt = nMagAtom*prod(N_ext)` and $n_k$ is the number
        %   of the magnetic propagation vectors.
        %
        % `k`
        % : Magnetic propagation vectors stored in a matrix with dimensions
        %   of $[3\times n_k]$.
        %
        % `N_ext`
        % : Size of the magnetic supercell in lattice units, default value
        %   is `[1 1 1]` emaning that the magnetic cell is identical to the
        %   crystallographic cell. The $[1\times 3]$ vector extends the cell
        %   along the $a$, $b$ and $c$ axes.
        %
        mag_str
    end
    
    methods (Static)
        % Call the base blass validator with our new datastructure
        function validate(varargin)
           spin.validate(varargin{1},datastruct,varargin{2:end})  
        end
    end
    
    methods
        function obj = spinw(varargin)
            % spinw constructor
            %
            % ### Syntax
            %
            % `obj = spinw`
            %
            % `obj = spinw(struct)`
            %
            % `obj = spinw(hFigure)`
            %
            % `obj = spinw(fName)`
            %
            % `obj = spinw(obj)`
            %
            % ### Description
            %
            % `obj = spinw` creates an empty SpinW object with default
            % values.
            %
            % `obj = spinw(struct)` creates a SpinW object from a structure
            % which has fields that are compatible with the SpinW property
            % structure.
            %
            % `obj = spinw(hFigure)` clones SpinW object from an swplot
            % figure or spectral plot figure.
            %
            % `obj = spinw(fName)` imports the file referenced by `fName`.
            % SpinW is able to import .cif/.fts files for crystal or
            % magnetic structure from a local file or a web address.
            %
            % `obj = spinw(obj)` checks the input SpinW object for
            % consistency.
            %
            
            if nargin == 1
                if isa(varargin{1},'spin') % base class returns base class.
                    varargin{1} = struct(varargin{1});
                end
            end
            obj@spin(varargin{:})
            
            if nargin==0
                objS = initfield(struct);
                fNames = fieldnames(objS);
                for ii = 1:length(fNames)
                    obj.(fNames{ii}) = objS.(fNames{ii});
                end
                return
            end
            
            firstArg = varargin{1};
            
            if ishandle(firstArg)
                % get spinw object from graphics handle
                switch get(firstArg,'Tag')
                    case 'sw_crystal'
                        figDat = getappdata(firstArg);
                        obj = copy(figDat.obj);
                    case 'sw_spectra'
                        figDat = getappdata(firstArg);
                        obj    = copy(figDat.spectra.obj);
                end
                return
                
            end
            
            if isa(firstArg, 'spinw')
                %  it is used when objects are passed as arguments.
                obj = copy(firstArg);
                return
            end
            
            if isstruct(firstArg)
                objS = initfield(firstArg);
                
                % change lattice object
                if size(objS.lattice.lat_const,1)==3
                    objS.lattice.lat_const = objS.lattice.lat_const';
                end
                if size(objS.lattice.angle,1)==3
                    objS.lattice.angle = objS.lattice.angle';
                end
                
                spinw.validate(objS);
                fNames = fieldnames(objS);
                for ii = 1:length(fNames)
                    obj.(fNames{ii}) = objS.(fNames{ii});
                end
                return;
            end
            if ischar(firstArg)
                % import data from file (cif/fst are supported)
                
                objS = initfield(struct);
                fNames = fieldnames(objS);
                for ii = 1:length(fNames)
                    obj.(fNames{ii}) = objS.(fNames{ii});
                end
                
                obj = s_import(firstArg,false,obj);
                
            end
            
        end % .spinw
        
        
        function nMagExt = nmagext(obj)
            % number of magnetic sites
            %
            % ### Syntax
            %
            % `nMagExt = nmagext(obj)`
            %
            % ### Description
            %
            % `nMagExt = nmagext(obj)` returns the number of magnetic sites
            % in the magnetic supercell. If the magnetic supercell (stored
            % in `spinw.mag_str.nExt` is identical to the crystal lattice)
            % the number of magnetic sites is equal to the number of
            % magnetic atoms in the unit cell. Where the number of magnetic
            % atoms in the unit cell can be calculated using [spinw.matom].
            %
            % ### See Also
            %
            % [spinw.matom] \| [spinw.natom]
            %
            
            nMagExt = size(obj.mag_str.F,2);
        end
        function nAtom = natom(obj)
            % number of symmetry unrelated atoms
            %
            % ### Syntax
            %
            % `nAtom = natom(obj)`
            %
            % ### Description
            %
            % `nAtom = natom(obj)` return the number of symmetry unrelated
            % atoms stored in `obj`.
            %
            % ### See Also
            %
            % [spinw.nmagext] \| [spinw.atom]
            %
            
            nAtom = size(obj.unit_cell.r,2);
        end
        
        function clearcache(obj, chgField)
            % clears the cache
            %
            % ### Syntax
            %
            % `clearcache(obj)`
            %
            % ### Description
            %
            % `clearcache(obj)` clears the cache that contains
            % precalculated magnetic structure and bond symmetry operators.
            % It is not necessary to clear the cache at any point as SpinW
            % clears it whenever necessary.
            %
            % ### See Also
            %
            % [spinw.cache]
            %
            
            % listening to changes of the spinw object to clear cache is
            % necessary
            if nargin<2
                % delete the existing listener handles
                delete(obj.propl(ishandle(obj.propl)));
                % remove cache
                obj.cache.matom = [];
                obj.cache.symop = [];
                return
            end
            
            switch chgField
                case 1
                    % magnetic atoms: delete the stored magnetic atom positions
                    obj.cache.matom = [];
                    % remove the listeners
                    delete(obj.propl(1:2));
                case 2
                    % bond symmetry operators: delete the stored operators
                    obj.cache.symop = [];
                    % remove the listeners
                    delete(obj.propl(3:5));
            end
        end
        
    end
    
    methods(Hidden=true,Static=true)
        function obj = loadobj(obj)
            % restore property listeners
            % add new listeners to the new object
            if ~isempty(obj.cache.matom)
                % add listener to lattice and unit_cell fields
                obj.addlistenermulti(1);
            end
            if ~isempty(obj.cache.symop)
                % add listener to lattice, unit_cell and coupling fields
                obj.addlistenermulti(2);
            end
        end
    end
    
    methods(Hidden=true)
        
        function addlistenermulti(obj, chgField)
            % create the corresponding listeners to each cache subfield
            
            switch chgField
                case 1
                    % add listener to lattice and unit_cell fields
                    obj.propl(1) = addlistener(obj,'lattice',  'PostSet',@(evnt,src)obj.clearcache(1));
                    obj.propl(2) = addlistener(obj,'unit_cell','PostSet',@(evnt,src)obj.clearcache(1));
                case 2
                    % add listener to lattice, unit_cell and coupling fields
                    obj.propl(3) = addlistener(obj,'lattice',  'PostSet',@(evnt,src)obj.clearcache(2));
                    obj.propl(4) = addlistener(obj,'unit_cell','PostSet',@(evnt,src)obj.clearcache(2));
                    obj.propl(5) = addlistener(obj,'coupling', 'PostSet',@(evnt,src)obj.clearcache(2));
            end
        end
        
        function obj = saveobj(obj)
            % remove property change listeners
            delete(obj.propl);
            % empty pointers
            obj.propl = event.proplistener.empty;
        end
        
        function lh = addlistener(varargin)
            lh = addlistener@handle(varargin{:});
        end
        function notify(varargin)
            notify@handle(varargin{:});
        end
        function Hmatch = findobj(varargin)
            Hmatch = findobj@handle(varargin{:});
        end
        function p = findprop(varargin)
            p = findprop@handle(varargin{:});
        end
        function TF = eq(varargin)
            TF = eq@handle(varargin{:});
        end
        function TF = ne(varargin)
            TF = ne@handle(varargin{:});
        end
        function TF = lt(varargin)
            TF = lt@handle(varargin{:});
        end
        function TF = le(varargin)
            TF = le@handle(varargin{:});
        end
        function TF = gt(varargin)
            TF = gt@handle(varargin{:});
        end
        function TF = ge(varargin)
            TF = ge@handle(varargin{:});
        end
        
        function varargout = set(varargin)
            varargout = set@handle(varargin{:});
        end
        function varargout = setdisp(varargin)
            varargout = setdisp@handle(varargin{:});
        end
        function varargout = getdisp(varargin)
            varargout = getdisp@handle(varargin{:});
        end
        function varargout = get(varargin)
            varargout = get@handle(varargin{:});
        end
    end % classdef
    
end