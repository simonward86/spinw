classdef spinwR < spinw & rserver
    %SPINWR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Hidden=true)
        sw_obj
        listners = {}
        upload_token = ''
        
    end
    
    methods
        function obj = spinwR(varargin)
            %SPINWR Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==1 && isa(varargin{1},'spinw')
                varargin{1} = struct(varargin{1});
            end
            obj@spinw(varargin{:})
            obj@rserver()
            obj.update_sw([],[])
            fnames = fieldnames(spinw());
            
            for i = 1:length(fnames)
                obj.listners{i} = addlistener(obj, fnames{i}, 'PostSet',@obj.update_sw);
            end
            
            try
                url = strcat(obj.baseURL,'/spinw/version');
                obj.version = webread(url,weboptions('ContentType','json'));
            catch ME
                if strcmp(ME.identifier,'MATLAB:webservices:ExpectedProtocol')
                    error('A valid server needs to  be specified.')
                else
                    rethrow(ME)
                end
            end
        end
        
        function disp(obj)
            disp@spinw(obj);
            fprintf('     <strong>Remote</strong>:\n       server: %s, user: %s, status: %s\n',...
                obj.baseURL,obj.username,obj.status(1:min([20 length(obj.status)])))
        end
    end
    
    methods(Hidden=true,Access = private)
        function update_sw(obj,event,src)
            temp = struct(obj);
            if isempty(event)
                fnames = fieldnames(rserver());
                for i = 1:length(fnames)
                    temp = rmfield(temp,fnames{i});
                end
                obj.sw_obj = spinw(temp);
            else
                obj.sw_obj.(event.Name) = obj.(event.Name);
            end
        end
    end
end