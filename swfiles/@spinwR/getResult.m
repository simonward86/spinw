function spectra = getResult(obj,varargin)
spectra = [];
if isempty(obj.token)
    error('You need to login')
end
if (obj.token_expire - datetime('now')) < 0
    obj.getToken();
end
if isempty(varargin)
    timeout = 1;
else
    timeout = varargin{1};
end
iscomp = webread(obj.statusURL,weboptions('Username',obj.token,'ContentType','json','timeout',100));
if strcmp(iscomp.status,'done')
    obj.isCalculating = false;
    obj.status = 'Calculation complete';
end
if obj.isCalculating
    iscomp = webread(obj.statusURL,weboptions('Username',obj.token,'ContentType','json','timeout',100));
    if strcmp(iscomp.status,'running')
        obj.status = 'Calculating';
        cont = true;
        while cont
            iscomp = webread(obj.statusURL,weboptions('Username',obj.token,'ContentType','json','timeout',100));
            if strcmp(iscomp.status,'done')
                cont = false;
                obj.isCalculating = false;
                obj.status = 'Calculation complete';
            else
                pause(timeout)
            end
        end
    end
end
filename = tempname;
file = websave(filename,iscomp.url,weboptions('Username',obj.token));
if obj.version.Deployed
    temp = load(file);
    if ~isempty(temp.err)
        rethrow(temp.err)
    end
    spectra = temp.argout{:};
    disp(temp.log)
else
    load(file,'-mat','spectra')
end
obj.isUploaded = false;
end