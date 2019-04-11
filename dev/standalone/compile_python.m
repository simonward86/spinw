function compile_python(varargin)
% compile SpinW code into python
%
% COMPILE_PYTHON('option1',value1,...)
%
% Options:
%
% sourcepath        Path to the source files, default value is the output
%                   of sw_rootdir().

swr0 = fileparts(sw_rootdir);

inpForm.fname  = {'sourcepath' };
inpForm.defval = {swr0 };
inpForm.size   = {[1 -1] };

param = sw_readparam(inpForm, varargin{:});

swr = param.sourcepath;

disp('Compiling SpinW to Python...')
tic

mccCommand = ['mcc -W python:spinw '...
    '-d ' swr '/dev/standalone/compiled '...
    '-a ' swr '/dat_files/* '...
    '-a ' swr '/external '...
    '-a ' swr '/swfiles '...
    '-a ' swr '/dev/standalone/ass.m '...
    '-a ' swr '/dev/standalone/ev.m '...
    '-a ' swr '/dev/standalone/evo.m '...
    swr '/dev/standalone/sw_main.m'];

eval(mccCommand);
