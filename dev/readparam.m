classdef readparam < dynamicprops
    % class to store and retrieve persistent settings
    %
    % ### Syntax
    %
    % `pref = swpref`
    %
    % `pref = swpref('default')`
    %
    % ### Description
    %
    % `pref = swpref` retrieves and creates a preference object.
    %
    % `pref = swpref('default')` resets all preferences to default values.
    %
    % The settings sotred in the `swpref` class for spinw objects will
    % persist during a single Matlab session. It is different from the
    % Matlab built-in preferences, as swpref resets all settings to factory
    % default after every restart of Matlab.
    %
    % ### Examples
    %
    % We change the fontsize value and show that it is retained even when a
    % new instance of the object is created:
    %
    % ```
    % >>pref = swpref
    % >>pref.fontsize>>
    % >>pref.fontsize = 18
    % >>pref2 = swpref
    % >>pref.fontsize>>
    % >>pref2.fontsize>>
    % ```
    %
    % ### Properties
    %
    % Properties can be changed by directly assigning a new value to them.
    % Once a new value to a given property is assigned, it will be retained
    % until the end of a MATLAB session, even if a new class instance is
    % created.
    %
    % ### Methods
    %
    % Methods are the different commands that require an `swpref` object as
    % a first input, thus they can be called as `method1(obj,...)`,
    % alternatively the equivalent command is `obj.method1(...)`.
    %
    % swpref.get
    % swpref.set
    % swpref.export
    % swpref.import
    %
    % Commands are methods which can be called without first creating a
    % preference object `swpref.command(....)`.
    %
    % swpref.getpref
    % swpref.setpref
    %
    
    properties(Hidden = true, Access=private)
        % stores the details to create and check dynamic properties.
        %
        % `Name` a cell array giving the name of each dynamic property.
        %
        % `Validation` a cell array with functions to evaluate when a
        % property is set.
        %
        % `Value` a cell array giving the default value of a dynamic property
        %
        % `Label` a cell array giving a short description on the dynamic
        % property.
        %
        % These details are retrieved from the private file `datastruct.m`.
        %
        Name
        Validation
        Value
        Label
    end
    
    properties (Hidden=true, Access = private)
        % stores the details of the dynamic properties.
        props = meta.DynamicProperty.empty
    end
    
    methods
        function obj = readparam(varargin)
            % Spin preference constructor.
            %
            % ### Syntax
            %
            % `pref = swpref`
            %
            % `pref = swpref('default')`
            %
            %
            % ### Description
            %
            % `pref = swpref` retrieves and creates a preference object.
            %
            % `pref = swpref('default')` resets all preferences to default values.
            %
            %
            % {{note The preferences are reset after every restart of Matlab, unlike the
            % Matlab built-in preferences that are persistent between Matlab sessions.
            % If you want certain preferences to keep after closing matlab, use the
            % 'pref.export(fileLocation)' and 'pref.import(fileLocation)' functions.
            % These can be added to your startup file.}}
            %
            % ### See Also
            %
            % [swpref.get], [swpref.set]
            %
            
            mustHave_Names = {'fname', 'defval','size'};
            optional_Names = {'validation','label'};
            Name_value = cellfun(@(x) {x ,[]},[mustHave_Names optional_Names],'UniformOutput',false);
            Name_value = horzcat(Name_value{:});
            Name_value = struct(Name_value{:});
            
            if nargin == 0
                error('readparam:InvalidOptions','A format structure or options must be given.')
            elseif nargin > 1
                if ~mod(nargin,2)
                    error('readparam:InvalidOptions','Valid parameter/value pairs must be give.')
                else
                    supplied_opt_p = varargin{1:2:end};
                    supplied_opt_v = varargin{2:2:end};
                    for i = 1:length(supplied_opt_p)
                       if ~any(strcmp(supplied_opt_p{i},[mustHave_Names optional_Names]))
                           error('readparam:InvalidOptions','%s is not a parameter/value pairs must be give.', supplied_opt_p{i})
                       elseif strcmp(supplied_opt_p{i},'size')
                            if isempty(Name_value.validation)
                                Name_value.validation = cellfun(@str2func,cellfun(@(x) sprintf('obj.check_size(obj.(''%s'')[%s, %s])',...
                                    supplied_opt_p{i},x(1), x(2)), supplied_opt_v{i},'UniformOutput',false),'UniformOutput',false);
                                ind = cellfun(@(x) x(2) < 0, supplied_opt_v{i});
                                unique_match = unique(cellfun(@(x) x(2),supplied_opt_v{i}(ind)));
                                if length(unique_match) == length(supplied_opt_v{i}(ind))
                                    % The length is not fixed, replace by NaN 
                                    Name_value.validation(ind) = cellfun(@str2func,cellfun(@(x) sprintf('obj.check_size(obj.(''%s'')[%s, NaN])',...
                                    supplied_opt_p{i},x(1)), supplied_opt_v{i}(ind),'UniformOutput',false),'UniformOutput',false);
                                else
                                    % One vairable depends on another one..
                                    
                                end
                            else
                                
                            end
                       else
                           Name_value.(supplied_opt_p{i}) = supplied_opt_v{i};
                       end
                    end
                    
                end
                    
            end
            
            obj.Name = Name_value.fname;
            obj.Value = Name_value.defval;
            obj.Label = data.Label;
            obj.Validation = data.Validation;

            if opt && ~isempty(sPref)
                f = fieldnames(sPref);
                for i = 1:length(f)
                    ind = strcmp(f{i},obj.Name);
                    if any(ind)
                        obj.Value{ind} = sPref.(f{i});
                    end
                end
            else
                f = obj.Name;
                for i = 1:length(f)
                    obj.get_set_static(f{i},obj.Value{i});
                    sPref.(f{i}) = obj.Value{i};
                end
            end
            
            for i = 1:length(data.Name)
                obj.props(i) = addprop(obj,obj.Name{i});
                obj.props(i).SetMethod = @(obj, val) set_data(obj,obj.Name{i}, val);
                obj.props(i).GetMethod = @(obj) get_data(obj,obj.Name{i});
                if isfield(sPref,obj.Name{i})
                    obj.(obj.Name{i}) = sPref.(obj.Name{i});
                else
                    obj.(obj.Name{i}) = obj.Value{i};
                end
            end
        end
        
        function varargout = get(obj,names)
            % retrieves a preference value
            %
            % ### Syntax
            %
            % `value = get(obj, name)`
            %
            % `value = obj.get(name)`
            %
            % ### Description
            %
            % `value = get(obj, name)` gets the preference `name`.
            %
            % `value = obj.get(name)` gets the preference `name`.
            %
            % ### See Also
            %
            % [swpref.set]
            %
            
            if nargin == 1
                error('swpref:GetError','You need to supply a parameter to get!');
            end
            
            if iscell(names)
                j = 1;
                for i = 1:legth(names)
                    if obj.check_names(names{i})
                        varargout{j} = obj.(names{i}); %#ok<AGROW>
                        j = j+1;
                    else
                        error('swpref:GetError','There is no field %s in swpref',names{i});
                    end
                end
            else
                if obj.check_names(names)
                    varargout{1} = obj.(names);
                else
                    error('swpref:GetError','There is no field %s in swpref',names);
                end
            end
        end
        
    end
    
    methods (Hidden=true, Access = private)
        
        function val = get_data(obj, name)
            % Function called when a vairable is retrieved.
            %
            %  {{warning Internal function for the Spin preferences.}}
            %
            % ### Syntax
            %
            % 'value = get_data(obj, name)'
            %
            % ### Description
            %
            % 'value = get_data(obj, name)' returns the value of parameter
            % 'name' from persistent storage.
            %
            % ### See Also
            %
            % [swpref.setpref], [swpref.set_data]
            %
            
            if obj.check_names(name)
                val = obj.get_set_static(name);
            else
                error('swpref:GetError','There is no field %s in swpref',name);
            end
        end
        
        function valid = check_names(obj,name)
            % Checking to see if a get/set name is valid.
            %
            %  {{warning Internal function for the Spin preferences.}}
            %
            % ### Syntax
            %
            % 'logical = obj.check_names(name)'
            %
            % ### Description
            %
            % 'logical = obj.check_names(name)' returns true if 'name' is a
            % valid field of 'obj' and false otherwise.
            %
            
            valid = any(strcmp(name,fieldnames(obj)));
        end
        
        function out = check_size(obj,S)
            % checks to see if an object is the wrong size.
            %
            %  {{warning Internal function for the Spin preferences.}}
            %
            % ### Syntax
            %
            % 'logical = check_size(toBeChecked,size)'
            %
            % ### Description
            %
            % 'logical = check_size(toBeChecked,size)' checks to see if an
            % object 'obj 'is the expected size given by 'size'. An error is
            % thrown if there is a difference.
            %
            
            sz = size(obj);
            if isnan(S(2))
               S(2) = sz(end); 
            end
            if ~all(sz == S)
                error('spref:WrongSize','Value to be asigned is the wrong size [%i, %i] not [%i, %i]',sz(1), sz(2), S(1), S(2))
            else
                out = 1;
            end
        end
    end
end
