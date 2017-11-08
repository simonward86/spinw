function upload(obj)
if isempty(obj.token)
    error('You need to login')
end
if (obj.token_expire - datetime('now')) < 0
    obj.getToken();
end

url = strcat(obj.baseURL,'/spinw/upload');
filename = strcat(tempname,'.mat');
d = char(getByteStreamFromArray(obj.sw_obj));

[~,remoteFName, remoteExt] = fileparts(filename);
opt = weboptions('Username',obj.token,'Password','x',...
    'characterEncoding','ISO-8859-1',...
    'MediaType','application/octet-stream',...
    'RequestMethod','post',...
    'HeaderFields',string({'Content-Length',string(length(d))}),...
    'ContentType','json',...
    'Timeout',60);
try
    upload_data = webwrite(sprintf(strcat(url,'/%s%s'),remoteFName,remoteExt), d, opt);
catch someException
    % Sometimes a timeout issue or something.....
    jobs = obj.getJobs;
    if isempty(jobs.Waiting)
        throw(addCause(MException('uploadToSpinW:unableToUploadFile','Unable to upload file.'),someException));
    else
        % This might be correct....
        upload_data.status = sprintf('%s/spinw/status/%s',obj.baseURL,jobs.Waiting(end).token);
    end
end
obj.status = 'Uploaded File';
obj.statusURL = upload_data.status;
obj.isUploaded = true;
end