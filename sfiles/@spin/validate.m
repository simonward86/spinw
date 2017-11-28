function validate(obj,varargin)
% validates spin object properties
%
% VALIDATE(obj, {fieldToValidate})
% VALIDATE(obj, SubclassDatstruct, {fieldToValidate})
%

% Load base class data structure.
Datstruct = datastruct();

if nargin > 1
    % Check if there is a subclass datastructure
    if isstruct(varargin{1})
        Datstruct2 = varargin{1};
        fnames1 = fieldnames(Datstruct);
        fnames2 = fieldnames(Datstruct2);
        if length(fnames1) ~= length(fnames2)
            error('spin:s_valid:IncorectInput','Input struct is not in the correct format (Missing Field)!')
        end
        if ~all(cellfun(@strcmp,fnames1,fnames2))
        	error('spin:s_valid:IncorectInput','Input struct is not in the correct format (Incorrect field)!')
        end
        % Merge if there are no errors
        Datstruct = [Datstruct Datstruct2];
        if length(varargin) > 1
            varargin = varargin(2:end);
        else
            varargin = {};
        end
    end
end


% Check and pad the arrays if it is needed.
min_max = feval(@(x) [min(x) max(x)], arrayfun(@(x) length(x.subfield),Datstruct));
if min_max(1) ~= min_max(2)
    % We need to do some padding.
    for i = 1:length(Datstruct)
        Datstruct(i).subfield  = horzcat(Datstruct(i).subfield , ...
            cell(size(Datstruct(i).subfield,1) ,min_max(2) - size(Datstruct(i).subfield,2)));
        Datstruct(i).sizefield = horzcat(Datstruct(i).sizefield, ...
            cell(size(Datstruct(i).sizefield,1),min_max(2) - size(Datstruct(i).sizefield,2)));
        Datstruct(i).typefield = horzcat(Datstruct(i).typefield, ...
            cell(size(Datstruct(i).typefield,1),min_max(2) - size(Datstruct(i).typefield,2)));
    end
end

mainfield = [Datstruct(:).mainfield];           % Should have a row vector id cells
subfield  = vertcat(Datstruct(:).subfield);     % Should add the row of cells on after
sizefield = vertcat(Datstruct(:).sizefield);    % Should add the row of cells on after
typefield = vertcat(Datstruct(:).typefield);    % Should add the row of cells on after



% Validate only selected mainfield of the struct.
indexFieldToValidate = [];
if ~isempty(varargin)
    if isa(varargin{1},'char')
        fieldToValidate = varargin(1);
    elseif isa(varargin{1},'cell')
        fieldToValidate = varargin{1};
    else
        error('spin:s_valid:IncorectInput','Input fields are not in the correct format!')
    end
    
    for ii = 1:length(fieldToValidate)
        indexFieldToValidate = [indexFieldToValidate find(strcmp(mainfield,fieldToValidate{ii}))]; %#ok<AGROW>
        
    end
end

if isempty(indexFieldToValidate)
    indexFieldToValidate = 1:length(mainfield);
end

valid  = true;
objS   = struct(obj);
fieldM = '';

for ii = indexFieldToValidate
    selectMainField = mainfield{ii};
    validT = isfield(objS,selectMainField);
    if valid && ~validT
        fieldM = selectMainField;
    end
    valid = valid && validT;
    
    for jj = 1:size(subfield,2)
        selectSubField = subfield{ii,jj};
        if ~isempty(selectSubField)
            validT = isfield(objS.(selectMainField),selectSubField);
            if valid && ~validT
                fieldM = [selectMainField '.' selectSubField];
            end
            valid  = valid && validT;
            
        end
    end
end

if ~valid
    error('spin:sw_valid:MissingField',['Input struct missing necessary field: ' fieldM '!'])
end

% Save the type of error for easier debugging.
errorType = 0;
errorData = '';

for ii = indexFieldToValidate
    selectMainField = mainfield{ii};
    for jj = 1:size(subfield,2)
        selectSubField = subfield{ii,jj};
        selectType = typefield{ii,jj};
        selectSize = sizefield{ii,jj};
        
        if ~isempty(selectSubField)
            selectField = objS.(selectMainField).(selectSubField);
            
            % Check the dimension of the selected field.
            objsize = size(selectField);
            if length(objsize) < length(selectSize)
                objsize((length(objsize)+1):length(selectSize)) = 1;
            end
            
            % Check the size of th selected field.
            for kk = 1:length(selectSize)
                if ~ischar(selectSize{kk})
                    valid = valid && (objsize(kk) == selectSize{kk});
                    if ~errorType && ~valid
                        errorType = 1;
                        errorData = ['objS.' selectMainField '.' selectSubField];
                    end
                else
                    if exist(selectSize{kk},'var')
                        valid = valid && (objsize(kk) == eval(selectSize{kk}));
                        if ~errorType && ~valid
                            errorType = 1;
                            errorData = ['objS.' selectMainField '.' selectSubField];
                        end
                    else
                        %assignin('caller',selectSize{kk},objsize(kk));
                        eval([selectSize{kk} '=' num2str(objsize(kk)) ';']);
                    end
                end
            end
            
            % Check the type of the selected field.
            if isa(selectField,'cell')
                if ~isempty(selectField)
                    selectField = selectField{1};
                    valid = valid && (isa(selectField,selectType) || isa(selectField,'sym'));
                    if ~errorType && ~valid
                        errorType = 2;
                        errorData = ['objS.' selectMainField '.' selectSubField];
                    end
                end
            else
                valid = valid && (isa(selectField,selectType) || isa(selectField,'sym'));
                if ~errorType && ~valid
                    errorType = 2;
                    errorData = ['objS.' selectMainField '.' selectSubField];
                end
            end
        end
    end
end

switch errorType
    case 1
        error('spin:sw_valid:SizeMismatch',['Input argument size mismatch in: ' errorData]);
    case 2
        error('spin:sw_valid:TypeMismatch',['Input argument type mismatch in: ' errorData]);
end

end