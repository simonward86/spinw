classdef readparam < dynamicprops
% parse input arguments
%
% ### Syntax
%
% `parser = readparam(format)`
%
% `parser.parse(Name,Value,....)`
% `parser.parse(Structure)`
%
% ### Description
%
% `parser = readparam(format)` create a parser object which can then parse
% Name, Value pairs to the specification given by `format`. 
% The parsing is controlled by the given `format` input. 
% 
% `[valid_parameters, invalid_parameters] = parser(Name,Value,....)` The 
% name-value pairs are converted into the parsed struct `valid_parameters` 
% which has field names identical to the given parameter names and corresponding
% values taken from the input. `format` can also define required dimensionality of
% a given value and default values for select parameters. 
%
%
% ### Input Arguments
%
% `format`
% : A struct with the following fields:
%   * `fname` Field names, $n_{param}$ strings in cell.
%   * `size` Required dimensions of the corresponding value in a cell of
%     $n_{param}$ vectors. Negative integer means dimension has to match with
%     any other dimension which has the identical negative integer.
%   * `defval` Cell of $n_{param}$ values, provides default values for
%     missing parameters.
%   * `soft` Cell of $n_{param}$ logical values, optional. If `soft(i)` is
%     true, in case of missing parameter value $i$, no warning will be
%     given.
%   * `validation` Cell of $n_{param}$ function handles, optional. the
%   function handles can be in the form @(obj,)
%   * `needed` Cell of $n_{param}$ logical values, optional. If `needed(i)` is
%     true, then on first parse an error will occour if the default value
%     is left.
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
        % `Soft` a cell array saying if this can be set empty
        %
        % `Needed` a cell array saying if the property is required to be set 
        % on first parse 
        %
        % `ValidateStore` a structure containing internal information.
        %
        % `Datastore` a structure containing all the data. 
        %
        Name
        Validation
        Value
        Label
        Soft
        Needed
        ValidateStore = struct('nums',0);
        Datastore
    end
    
    properties (Hidden=true, Access = private)
        % stores the details of the dynamic properties.
        props   = meta.DynamicProperty.empty
    end
    
    methods
        function obj = readparam(varargin)
            % Parameter parser constructor.
            %
            % ### Syntax
            %
            % `parser = readparam(format)`
            %
            %
            % ### Description
            %
            % `parser = readparam(format)` 
            %
            %
            % {{note See the class description for the format of `format` 
            % and the valid fields which it can hold.}}
            %
            % ### See Also
            %
            % [readparam.get], [readparam.validate], [readparam.parse]
            %
            
            mustHave_Names = {'fname', 'defval', 'size'};
            optional_Names = {'validation','label','soft','needed'};
            Name_value = cellfun(@(x) {x ,[]},[mustHave_Names optional_Names],'UniformOutput',false);
            Name_value = horzcat(Name_value{:});
            Name_value = struct(Name_value{:});
            % We need to have an input.
            if nargin == 0
                e = MException('readparam:InvalidOptions','A format structure or options must be given.');
                e.throwAsCaller;
            elseif nargin > 0
                % Invalid parameter/value pairing
                if nargin > 1 && mod(nargin,2)
                    e = MException('readparam:InvalidOptions','Valid parameter/value pairs must be give.');
                    e.throwAsCaller;
                else
                    % Split into parameter and value
                    supplied_opt_p = varargin(1:2:end);
                    supplied_opt_v = varargin(2:2:end);
                end
                % Convert a structure to cell
                if nargin == 1 && isstruct(varargin{1})
                    supplied_opt_p = fieldnames(varargin{1});
                    supplied_opt_v = struct2cell(varargin{1});
                end
                % Deal with no validation.
                if any(strcmp('validation',supplied_opt_p))
                    Name_value.validation = supplied_opt_v{strcmp('validation',supplied_opt_p)};
                else
                    Name_value.validation = {};
                end
                
                for i = 1:length(supplied_opt_p)
                    if ~any(strcmp(supplied_opt_p{i},[mustHave_Names optional_Names]))
                        error('readparam:InvalidOptions','%s is not a parameter/value pairs must be give.', supplied_opt_p{i})
                    elseif strcmp(supplied_opt_p{i},'size')
                        % Create placeholder validation functions...
                        this_validation = ...
                            cellfun(@(x) sprintf('@(obj,x) check_size(obj,[%i, %i],x)', x(1), x(2)),...
                            supplied_opt_v{i},'UniformOutput',false);
                        ind = cellfun(@(x) x(2) < 0, supplied_opt_v{i});
                        unique_match = unique(cellfun(@(x) x(2),supplied_opt_v{i}(ind)));
                        if length(unique_match) == length(supplied_opt_v{i}(ind))
                            % The length is not fixed, replace by NaN
                            this_validation(ind) = ...
                                cellfun(@(x) sprintf('@(obj,x) check_size(obj,[%i, NaN],x)', ...
                                x(1)),supplied_opt_v{i}(ind),'UniformOutput',false);
                        else
                            % One vairable depends on another one..
                            for j = 1:length(unique_match)
                                this_ind = cellfun(@(x) x(2) == unique_match(j), supplied_opt_v{i});
                                % Now we have to build up the dependencies..
                                this_validation(ind & this_ind) =...
                                    cellfun(@(x) sprintf('@(obj,x) check_size(obj,[%i, %i],x)',x(1),...
                                    length(supplied_opt_v{strcmp('defval',supplied_opt_p)}{find(ind & this_ind,1,'first')})),...
                                    supplied_opt_v{i}(ind & this_ind),'UniformOutput',false);
                            end
                        end
                        % Set up the validation functions. Append if need be.
                        if isempty(Name_value.validation)
                            Name_value.validation = this_validation;
                        else
                            for j = 1:length(Name_value.validation)
                                temp = Name_value.validation(j);
                                if iscell(temp)
                                    Name_value.validation{j} = [temp this_validation{j}];
                                else
                                    Name_value.validation{j} = [temp this_validation{j}];
                                end
                            end
                        end
                    else
                        % Do all other fields (NOT VALIDATION).
                        if any(strcmp('validation',supplied_opt_p{i}))
                            continue
                        end
                        Name_value.(supplied_opt_p{i}) = supplied_opt_v{i};
                    end
                end
            end
            
            % Asign parsed options
            obj.Name = Name_value.fname;
            obj.Value = Name_value.defval;
            obj.Label = Name_value.label;
            obj.Validation = Name_value.validation;
            
            % Create the soft field if empty
            if ~isempty(Name_value.soft)
                if iscell(Name_value.soft)
                    Name_value.soft = cell2mat(Name_value.soft);
                end
                obj.Soft = Name_value.soft;
            else
                obj.Soft = false(1,length(Name_value.fname));
            end
            
            % Create the needed field if empty
            if ~isempty(Name_value.needed)
                if iscell(Name_value.needed)
                    Name_value.needed = cell2mat(Name_value.needed);
                end
                obj.Needed = Name_value.needed;
            else
                obj.Needed = false(1,length(Name_value.fname));
            end
            
            % Set the actual values and read/write functions.
            for i = 1:length(obj.Name)
                obj.props(i) = addprop(obj,obj.Name{i});
                obj.props(i).SetMethod = @(obj, val) set_data(obj,obj.Name{i}, val);
                obj.props(i).GetMethod = @(obj) get_data(obj,obj.Name{i});
                obj.(obj.Name{i}) = obj.Value{i};
            end
        end
        
        function varargout = get(obj,names)
            % Retrieves a parameter value
            %
            % ### Syntax
            %
            % `value = get(obj, name)`
            %
            % `value = obj.get(name)`
            %
            % ### Description
            %
            % `value = get(obj, name)` gets the parameter `name`.
            %
            % `value = obj.get(name)` gets the parameter `name`.
            %
            %
            
            if nargin == 1
                e = MException('readparam:GetError','You need to supply a parameter to get!');
                e.throwAsCaller;
            end
            
            if iscell(names)
                j = 1;
                for i = 1:legth(names)
                    if obj.check_names(names{i})
                        varargout{j} = obj.(names{i}); %#ok<AGROW>
                        j = j+1;
                    else
                        e = MException('readparam:GetError','There is no field %s in swpref',names{i});
                        e.throwAsCaller;
                    end
                end
            else
                if obj.check_names(names)
                    varargout{1} = obj.(names);
                else
                    e = MException('readparam:GetError','There is no field %s in swpref',names);
                    e.throwAsCaller;
                end
            end
        end
        
        function varargout =  validate(obj,varargin)
            % Validates a Name/Value pairing or struct
            %
            % ### Syntax
            %
            % `[valid_parameters, invalid_parameters] = parser.validate(Name,Value,....)`
            % 
            % `[valid_parameters, invalid_parameters] = parser.validate(Structure)`
            %
            % ### Description
            %
            % `[valid_parameters, invalid_parameters] =
            % parser.validate(Name,Value,....)` uses the template supplied in the
            % creation of the parser to retun a stucture of valid and invalid
            % parsed options as a struct
            %
            % `[valid_parameters, invalid_parameters] =
            % parser.validate(struct)` uses the template supplied in the
            % creation of the parser to retun a stucture of valid and invalid
            % parsed options             %
            %
            
            % Check parameter/value pair and convert a structure
            if (length(varargin) > 1) && mod(nargin-1,2)
                e = MException('readparam:InvalidOptions','Valid parameter/value pairs must be give.');
                e.throwAsCaller;
            else
                supplied_opt_p = varargin(1:2:end);
                supplied_opt_v = varargin(2:2:end);
            end
            if (length(varargin) == 1) && isstruct(varargin{1})
                supplied_opt_p = fieldnames(varargin{1});
                supplied_opt_v = struct2cell(varargin{1});
            end
            % We get the valid options. 
            match_matrix = cell2mat(cellfun(@(x) strcmp(x,obj.Name),supplied_opt_p,'UniformOutput',false)');
            matched_ind = any(match_matrix,2);
            % Now we check to see if these follow the validation rules...            
            validator = obj.Validation(any(match_matrix,1));
            valid_ind = logical(obj.doValidation(validator,supplied_opt_v(matched_ind)));
            valid_p = supplied_opt_p(matched_ind);
            valid_v = supplied_opt_v(matched_ind);
            % Now create a structured output of valid options
            temp = cellfun(@(x,y) {x,y},valid_p(valid_ind),valid_v(valid_ind),'UniformOutput',false);
            temp = [temp{:}];
            varargout{1} = struct(temp{:});
            
            if nargout == 2
                % Now create a structured output of invalid options if the
                % user asks for it.
                temp = cellfun(@(x,y) {x,y},supplied_opt_p(~matched_ind),supplied_opt_v(~matched_ind),'UniformOutput',false);
                temp = [temp{:}];
                if numel(temp) == 0
                    varargout{2} = [];
                else
                    varargout{2} = struct(temp{:});
                end
            end
        end
        
        function varargout = parse(obj,varargin)
            % Parses a Name/Value pairing or struct
            %
            % ### Syntax
            %
            % `parser.parse(Name,Value,....)`
            %
            % `invalid_parameters = parser.parse(Name,Value,....);`
            % 
            % `parser.parse(struct)`
            % 
            % `invalid_parameters = parser.parse(struct);`
            %
            % ### Description
            %
            % `invalid_parameters = parser.validate(Name,Value,....)` uses 
            % the template supplied in the creation of the parser to parse 
            % and set values. Invalid parsed options can be returned as a struct
            %
            %
            
            % Check to see if everything is OK
            [valid_options, invalid_options] = obj.validate(varargin{:});
            f = fieldnames(valid_options);
            % Check if a needed value is given
            inds = obj.Needed(:) & ~any(cell2mat(cellfun(@(x) strcmp(x,obj.Name),f,'UniformOutput',false))',2);
            if any(inds)
                text = cellfun(@(x)sprintf('The parameter ''%s'' is missing. It should have supplied.\n',x),obj.Name(inds),'UniformOutput',false);
                e = MException('readparam:MissingParameter',[text{:}]);
                e.throwAsCaller;
            end            
            for i = 1:length(f)
                % Check to see if the value is empty and it is allowed to
                % be.
                if isempty(valid_options.(f{i})) && obj.Soft(strcmp(f{i},obj.Name))
                    e = MException('readparam:EmptyParameter','The parameter %s can not be empty.',f{i});
                    e.throwAsCaller;
                end
                % Set the value
                obj.(f{i}) = valid_options.(f{i});
            end
            % How many times have we done this....
            obj.ValidateStore.nums = obj.ValidateStore.nums+1; 
            if nargout == 1
                % Return invalid options if the user wants.
                varargout{1} = invalid_options;
            end
        end
    end
    
    methods (Hidden=true, Access = public)
        function out = check_size(obj,reference,value)
            % checks to see if an object is the wrong size.
            %
            %  {{warning Internal function for readparam.}}
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
            if ischar(reference)
                % Can we get the reference from the object?
                if any(strcmp(reference,fieldnames(obj)))
                    ref_mat = obj.(reference);
                else
                    try
                        % Can we get the reference from evaluation?
                        ref_mat = eval(reference);
                    catch
                        e = MException('readparam:InternalError','There has been an internal error evaluating a size reference.');
                        e.throwAsCaller;
                    end
                end
                % This is our reference size.
                ref_size = size(ref_mat);
            else
                % Reference size has been explicitly given.
                ref_size = reference;
            end
            % The current size
            val_size = size(value);
            % Replace a NaN with the current size (unbounded.)
            if isnan(ref_size(2))
                ref_size(2) = val_size(end);
            end
            % Support putting in placeholders. Not a fan of this logic....
            if isempty(value) && all(ref_size == [1 0] | ref_size == [1 1])
                ref_size = [0 0];
            end
            % Do the check
            if ~all(ref_size == val_size)
                e = MException('readparam:WrongSize','Value to be asigned is the wrong size [%i, %i] not [%i, %i]',...
                    val_size(1), val_size(2), ref_size(1), ref_size(2));
                e.throwAsCaller;
            else
                out = 1;
            end
        end
    end
    
    methods (Hidden=true, Access = private)
        
        function set_data(obj, name, val)
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
                % What are we validating?
                ind = strcmp(name,obj.Name);
                % Validation function
                validation = obj.Validation{ind};
                obj.doValidation(validation,val)
                % Set the value if everything is OK
                obj.Datastore.(name) = val;
            else
                % We can't set that field.
                e = MException('readparam:SetError','There is no field %s in readparam',name);
                e.throwAsCaller;
            end
        end
        
        function varargout = doValidation(obj,validation,val)
            ret = zeros(1,length(validation));
            % Is it not in a cell
            if ~iscell(validation)
                validation = {validation};
            end
            % Is it not in a cell
            if ~iscell(val)
                val = {val};
            end
            % Are the cells nested
            if any(cellfun(@iscell,validation))
                validation = [validation{:}];
            end
            % Do each validation
            for i = 1:length(validation)
                % Did someone use an empty to pad?
                if isempty(validation{i})
                    continue
                end
                % Convert to a function if a string
                if ischar(validation{i})
                    validation{i} = str2func(validation{i});
                end
                % Are we operating on the object or value
                if nargin(validation{i}) == 1
                    ret(i) = feval(validation{i},val{i});
                else
                    ret(i) = feval(validation{i},obj,val{i});
                end
                % Do we have an error?
                if ret(i) == 0 && nargout == 0
                    e = MException('readparam:ValidationError','%s has been triggered by the update',func2str(validation{i}));
                    e.throwAsCaller;
                end
            end
            
            if nargout == 1
                varargout{1} = ret;
            end
        end
            
        
        function val = get_data(obj, name)
            % Function called when a vairable is retrieved.
            %
            %  {{warning Internal function for the readparam class.}}
            %
            % ### Syntax
            %
            % 'value = get_data(obj, name)'
            %
            % ### Description
            %
            % 'value = get_data(obj, name)' returns the value of parameter
            % 'name' from the datastore.
            %
            % ### See Also
            %
            % [swpref.setpref], [swpref.set_data]
            %
            
            if obj.check_names(name)
                val = obj.Datastore.(name);
            else
                e = MException('readparam:GetError','There is no field %s in readparam',name);
                e.throwAsCaller;
            end
        end
        
        function valid = check_names(obj,name)
            % Checking to see if a get/set name is valid.
            %
            %  {{warning Internal function for the readparam class.}}
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
    end
    
end
