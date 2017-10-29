function evaluate(obj,fn_name,varargin)
if isempty(obj.token)
    error('You need to login')
end
if (obj.token_expire - datetime('now')) < 0
    obj = obj.getToken();
end
url = strcat(obj.baseURL,'/spinw/compute');
if (obj.version.Deployed)
    sw_opt = struct();
    sw_opt.fun = fn_name;
    sw_opt.argin = {obj.spinw_obj,varargin{:}};
    sw_opt.nargout = 1;
else
    error('This command only works on a compiled server.')
end
filename = strcat(tempname,'.mat');
d = char(getByteStreamFromArray(sw_opt));

[~,remoteFName, remoteExt] = fileparts(filename);
opt = weboptions('Username',obj.token,'Password','x',...
    'characterEncoding','ISO-8859-1',...
    'MediaType','application/octet-stream',...
    'RequestMethod','post',...
    'HeaderFields',string({'Content-Length',string(length(d))}),...
    'ContentType','json');
try
    tempOutput = webwrite(sprintf(strcat(url,'/%s%s'),remoteFName,remoteExt), d, opt);
catch someException
    throw(addCause(MException('uploadToSpinW:unableToUploadFile','Unable to upload file.'),someException));
end
if tempOutput.Calculating && ~tempOutput.Errors
    iscomp = webread(obj.statusURL,weboptions('Username',obj.token,'ContentType','json','timeout',100));
    if strcmp(iscomp.status,'running')
        obj.status = 'Calculating';
        obj.isCalculating = true;
    end
end
end