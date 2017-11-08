classdef rserver < handle
    properties
        baseURL = '';
        username = swpref.getpref('remoteuser',[]);
        auto_get = false;
    end
    properties(SetAccess = protected)
        status = 'Waiting'
        statusURL = ''
        token = swpref.getpref('remotetoken',[]);
        token_expire = datetime('now')
    end
    properties(Hidden=true,SetAccess = protected)
        isCalculating = false;
        version = []
        deployed = false;
        isUploaded = false;
    end
    
    methods
        
        function obj = rserver()
            obj.baseURL = swpref.getpref('remoteurl',[]);
            if isempty(obj.baseURL)
                error('A valid server needs to  be specified.')
            end
            
            if isempty(obj.token)
                obj.login();
            else
                obj.getToken(obj.token)
            end
        end
        
        function login(obj,varargin)
            % No token, so login,
            if isempty(obj.token)
                % Try make user. Catch existing user and get token.
                [obj.username, password] = obj.GetAuthentication(varargin{:});
                try
                    % Success, suername and password OK
                    url = strcat(obj.baseURL,'/users/quota');
                    [~] = webread(url,weboptions('Username',obj.username,'Password',password,'ContentType','json'));
                    obj.getToken(obj.username,password)
                catch ME
                    % The user does not exist or password is wrong.
                    if strcmp(ME.identifier,'MATLAB:webservices:HTTP403StatusCodeError')
                        obj.status = 'Unknown User';
                        obj.newUser()
                    else
                        % Something has gone wrong.
                        obj.token = '';
                        obj.status = ME.message;
                        return
                    end
                end
            else
                % A token exists but is it valid?
                url = strcat(obj.baseURL,'/users/quota');
                try
                    % If it's valid we get a new token.
                    [~] = webread(url,weboptions('Username',obj.token,'ContentType','json'));
                    obj.getToken(obj.token) % Re-issue a token.
                    obj.status = 'Logged in';
                catch ME
                    % Catch the Unauthorized error and login.
                    if strcmp(ME.identifier,'MATLAB:webservices:HTTP401StatusCodeError')
                        obj.getToken()
                        obj.status = 'Logged in';
                    else
                        obj.status = ME.message;
                        obj.token = '';
                        return
                    end
                end
            end
            swpref.setpref('remotetoken',obj.token)
            swpref.setpref('remoteuser',obj.username)
        end
        
        
        function newUser(obj,varargin)
            if length(varargin)==3
                Lusername = varargin{1};
                obj.username = varargin{2};
                password = varargin{3};
            else
                [Lusername, obj.username, password] = obj.register_GetAuthentication();
            end
            swpref.setpref('remoteuser',obj.username)
            url = strcat(obj.baseURL,'/users/register');
            try
                response = webwrite(url,'username',Lusername,'email',obj.username,'password',password,weboptions('ContentType','json'));
            catch ME
                if strcmp(ME.identifier,'MATLAB:webservices:HTTP409StatusCodeError')
                    obj.status = 'User Exists';
                    response.username = obj.username;
                else
                    obj.status = ME.message;
                    return
                end
            end
            if strcmp(response.username,obj.username)
                url = strcat(obj.baseURL,'/users/token');
                temp = webread(url,weboptions('Username',obj.username,'Password',password,'ContentType','json'));
                obj.token = temp.token;
                obj.token_expire = datetime('now') + seconds(temp.duration);
            end
        end
        
        function quota = view_quota(obj)
            if isempty(obj.token)
                error('You need to login')
            end
            if (obj.token_expire - datetime('now')) < 0
                obj.getToken();
            end
            url = strcat(obj.baseURL,'/users/quota');
            quota = webread(url,weboptions('Username',obj.token,'ContentType','json'));
        end
        
        function jobs = getJobs(obj)
            url = strcat(obj.baseURL,'/users/jobs');
            if isempty(obj.token)
                error('You need to login')
            end
            if (obj.token_expire - datetime('now')) < 0
                obj.getToken();
            end
            jobs = webread(url,weboptions('Username',obj.token,'ContentType','json'));
        end
        
        
        function jobs = killJob(obj,job_id)
            url = strcat(obj.baseURL,'/users/jobs');
            if isempty(obj.token)
                error('You need to login')
            end
            if (obj.token_expire - datetime('now')) < 0
                obj.getToken();
            end
            temp = webwrite(url,'job_id',job_id,'action','delete',weboptions('Username',obj.token,'ContentType','json'));
        end
        
        function getToken(obj,varargin)
            if isempty(varargin)
                password = [];
            elseif length(varargin) == 1
                username = varargin{1};
                password = 'token';
            elseif length(varargin) == 2
                username = varargin{1};
                password = varargin{2};
            end
            if isempty(password)
                [username, password] = obj.GetAuthentication();
                obj.username = username;
            end
            url = strcat(obj.baseURL,'/users/token');
            try
                temp = webread(url,weboptions('Username',username,'Password',password,'ContentType','json'));
                obj.token = temp.token;
                obj.token_expire = datetime('now') + seconds(temp.duration);
                obj.status = 'Logged in';
            catch ME
                % Catch the Unauthorized error and create new user.
                if strcmp(ME.identifier,'MATLAB:webservices:HTTP401StatusCodeError')
                    obj.token = '';
                    obj.newUser()
                % Catch the Unauthorized error and create new user.
                elseif strcmp(ME.identifier,'MATLAB:webservices:HTTP403StatusCodeError')
                    obj.token = '';
                    obj.login()
                    % The token is not valid
                elseif strcmp(ME.identifier,'MATLAB:webservices:ContentTypeReaderError')
                    obj.token = '';
                    obj.login()
                else
                    obj.status = ME.message;
                    obj.token = '';
                    return
                end
            end
        end  
    end
    
    methods(Hidden=true)
        
        function [username,email, password]=register_GetAuthentication(obj)
            %GetAuthentication prompts a username and password from a user and hides the
            % password input by *****
            %
            %   [user,password] = GetAuthentication;
            %   [user,password] = GetAuthentication(defaultuser);
            %
            % arguments:
            %   defaultuser - string for default name
            %
            % results:
            %   username - string for the username
            %   password - password as a string
            %
            % Created by Felix Ruhnow, MPI-CBG Dresden
            % Version 1.00 - 20th February 2009
            %
            
            defaultuser = obj.username;
            
            hAuth.fig = figure('Menubar','none','Units','normalized','Resize','off','NumberTitle','off', ...
                'Name','Authentication','Position',[0.4 0.35 0.2 0.3],'WindowStyle','normal');
            
            uicontrol('Parent',hAuth.fig,'Style','text','Enable','inactive','Units','normalized','Position',[0 0 1 1], ...
                'FontSize',12);
            
            % Username
            u_name = strsplit(obj.username,'@');
            uicontrol('Parent',hAuth.fig,'Style','text','Enable','inactive','Units','normalized','Position',[0.1 0.85 0.8 0.1], ...
                'FontSize',12,'String','Username:','HorizontalAlignment','left');
            
            hAuth.eUsername = uicontrol('Parent',hAuth.fig,'Style','edit','Tag','username','Units','normalized','Position',[0.1 0.8 0.8 0.1], ...
                'FontSize',12,'String',u_name{1},'BackGroundColor','white','HorizontalAlignment','left');
            
            % Email
            uicontrol('Parent',hAuth.fig,'Style','text','Enable','inactive','Units','normalized','Position',[0.1 0.675 0.8 0.1], ...
                'FontSize',12,'String','Email:','HorizontalAlignment','left');
            
            hAuth.eEmail= uicontrol('Parent',hAuth.fig,'Style','edit','Tag','email','Units','normalized','Position',[0.1 0.625 0.8 0.1], ...
                'FontSize',12,'String',defaultuser,'BackGroundColor','white','HorizontalAlignment','left');
            
            % Password1
            uicontrol('Parent',hAuth.fig,'Style','text','Enable','inactive','Units','normalized','Position',[0.1 0.50 0.8 0.1], ...
                'FontSize',12,'String','Password:','HorizontalAlignment','left');
            
            hAuth.ePassword1 = uicontrol('Parent',hAuth.fig,'Style','edit','Tag','password','Units','normalized','Position',[0.1 0.45 0.8 0.1], ...
                'FontSize',12,'String','','BackGroundColor','white','HorizontalAlignment','left');
            
            % Password2
            uicontrol('Parent',hAuth.fig,'Style','text','Enable','inactive','Units','normalized','Position',[0.1 0.325 0.8 0.1], ...
                'FontSize',12,'String','Password:','HorizontalAlignment','left');
            
            hAuth.ePassword2 = uicontrol('Parent',hAuth.fig,'Style','edit','Tag','password','Units','normalized','Position',[0.1 0.275 0.8 0.1], ...
                'FontSize',12,'String','','BackGroundColor','white','HorizontalAlignment','left');
            
            % Button
            uicontrol('Parent',hAuth.fig,'Style','pushbutton','Tag','OK','Units','normalized','Position',[0.1 0.05 0.35 0.2], ...
                'FontSize',12,'String','OK','Callback',@ComfirmPassword);
            
            uicontrol('Parent',hAuth.fig,'Style','pushbutton','Tag','Cancel','Units','normalized','Position',[0.55 0.05 0.35 0.2], ...
                'FontSize',12,'String','Cancel','Callback',@AbortAuthentication);
            
            set(hAuth.fig,'CloseRequestFcn',@AbortAuthentication)
            set(hAuth.ePassword1,'KeypressFcn',@PasswordKeyPress1)
            set(hAuth.ePassword2,'KeypressFcn',@PasswordKeyPress2)
            
            setappdata(0,'hAuth',hAuth);
            uicontrol(hAuth.eUsername);
            uiwait;
            
            username = get(hAuth.eUsername,'String');
            email = get(hAuth.eEmail,'String');
            
            delete(hAuth.fig);
            
            function ComfirmPassword(hObject,event)
                password1 = get(hAuth.ePassword1,'UserData');
                password2 = get(hAuth.ePassword2,'UserData');
                if strmatch(password1,password2)
                    password = password1;
                    uiresume;
                end
            end
            
            function PasswordKeyPress1(hObject,event)
                hAuth = getappdata(0,'hAuth');
                password1 = get(hAuth.ePassword1,'UserData');
                switch event.Key
                    case 'backspace'
                        password1 = password1(1:end-1);
                    case 'return'
                        uiresume;
                        return;
                    otherwise
                        password1 = [password1 event.Character];
                end
                set(hAuth.ePassword1,'UserData',password1)
                set(hAuth.ePassword1,'String',char('*'*sign(password1)))
            end
            
            function PasswordKeyPress2(hObject,event)
                hAuth = getappdata(0,'hAuth');
                password2 = get(hAuth.ePassword2,'UserData');
                switch event.Key
                    case 'backspace'
                        password2 = password2(1:end-1);
                    case 'return'
                        uiresume;
                        return;
                    otherwise
                        password2 = [password2 event.Character];
                end
                set(hAuth.ePassword2,'UserData',password2)
                set(hAuth.ePassword2,'String',char('*'*sign(password2)))
            end
            
            function AbortAuthentication(hObject,event)
                hAuth = getappdata(0,'hAuth');
                set(hAuth.eUsername,'String','');
                set(hAuth.ePassword1,'UserData','');
                set(hAuth.ePassword2,'UserData','');
                uiresume;
            end
        end
        
        
        function [username,password]=GetAuthentication(defaultuser)
            %GetAuthentication prompts a username and password from a user and hides the
            % password input by *****
            %
            %   [user,password] = GetAuthentication;
            %   [user,password] = GetAuthentication(defaultuser);
            %
            % arguments:
            %   defaultuser - string for default name
            %
            % results:
            %   username - string for the username
            %   password - password as a string
            %
            % Created by Felix Ruhnow, MPI-CBG Dresden
            % Version 1.00 - 20th February 2009
            %
            
            if nargin==0
                defaultuser='';
            end
            
            hAuth1.fig = figure('Menubar','none','Units','normalized','Resize','off','NumberTitle','off', ...
                'Name','Authentication','Position',[0.4 0.4 0.2 0.2],'WindowStyle','normal');
            
            uicontrol('Parent',hAuth1.fig,'Style','text','Enable','inactive','Units','normalized','Position',[0 0 1 1], ...
                'FontSize',12);
            % Username
            uicontrol('Parent',hAuth1.fig,'Style','text','Enable','inactive','Units','normalized','Position',[0.1 0.8 0.8 0.1], ...
                'FontSize',12,'String','Username:','HorizontalAlignment','left');
            
            hAuth1.eUsername = uicontrol('Parent',hAuth1.fig,'Style','edit','Tag','username','Units','normalized','Position',[0.1 0.675 0.8 0.1], ...
                'FontSize',12,'String',defaultuser.username,'BackGroundColor','white','HorizontalAlignment','left');
            
            uicontrol('Parent',hAuth1.fig,'Style','text','Enable','inactive','Units','normalized','Position',[0.1 0.5 0.8 0.1], ...
                'FontSize',12,'String','Password:','HorizontalAlignment','left');
            
            hAuth1.ePassword = uicontrol('Parent',hAuth1.fig,'Style','edit','Tag','password','Units','normalized','Position',[0.1 0.375 0.8 0.125], ...
                'FontSize',12,'String','','BackGroundColor','white','HorizontalAlignment','left');
            
            uicontrol('Parent',hAuth1.fig,'Style','pushbutton','Tag','OK','Units','normalized','Position',[0.1 0.05 0.35 0.2], ...
                'FontSize',12,'String','OK','Callback','uiresume;');
            
            uicontrol('Parent',hAuth1.fig,'Style','pushbutton','Tag','Cancel','Units','normalized','Position',[0.55 0.05 0.35 0.2], ...
                'FontSize',12,'String','Cancel','Callback',@AbortAuthentication);
            
            set(hAuth1.fig,'CloseRequestFcn',@AbortAuthentication)
            set(hAuth1.ePassword,'KeypressFcn',@PasswordKeyPress)
            
            setappdata(0,'hAuth1',hAuth1);
            uicontrol(hAuth1.eUsername);
            uiwait;
            
            username = get(hAuth1.eUsername,'String');
            password = get(hAuth1.ePassword,'UserData');
            delete(hAuth1.fig);
            
            function PasswordKeyPress(hObject,event)
                hAuth = getappdata(0,'hAuth1');
                password = get(hAuth.ePassword,'UserData');
                switch event.Key
                    case 'backspace'
                        password = password(1:end-1);
                    case 'return'
                        uiresume;
                        return;
                    otherwise
                        password = [password event.Character];
                end
                set(hAuth.ePassword,'UserData',password)
                set(hAuth.ePassword,'String',char('*'*sign(password)))
            end
            function AbortAuthentication(hObject,event)
                hAuth = getappdata(0,'hAuth1');
                set(hAuth.eUsername,'String','');
                set(hAuth.ePassword,'UserData','');
                uiresume;
            end
        end
    end
    
end

