function varargout = disp(obj)
% prints information
%
% ### Syntax
%
% `{swdescr} = disp(obj)`
%
% ### Description
%
% `{swdescr} = disp(obj)` generates text summary of a [spin] object.
% Calling it with output argument, it will generate a text version of the
% internal data structure giving also the dimensions of the different
% matrices.
%
% ### Examples
%
% Here the internal data structure is generated:
%
% ```
% >>crystal = spin
% >>swFields = disp(crystal)>>
% ```
%
% ### Input Arguments
%
% `obj`
% : [spin] object.
%
% ### Output Arguments
%
% `swdescr`
% : If output variable is given, the description of the `obj` object
%   will be output into the `swdescr` variable, instead of being
%   written onto the Command Window/file. Optional.
%
% ### See Also
%
% [spin]
%



% prints the spin data structure in readable format onto the Command Window
%
% {swDescr} = DISPLAY(obj)
%
% Input:
%
% obj       spin class object.
%
% Output:
%
% swdescr   If output variable is given, the description of the obj object
%           will be output into the swdescr variable, instead of being
%           written onto the Command Window/file. Optional.
%
% Example:
%
% crystal = spin;
% swFields = display(crystal);
%
% See also spin.
%

Datastruct = datastruct;

choiceStr = {'off' 'on'};
symmStr = choiceStr{obj.symmetry+1};

fid = swpref.getpref('fid',true);
if fid == 0
    fidStr = 'none';
else
    fidStr = fopen(fid);
end

if nargout == 1
    
    swDescr = sprintf('spin object (symmetry: %s, textoutput: %s)\n',symmStr,fidStr);
    
    for ii = 1:length(Datastruct.mainfield)
        swDescr = [swDescr sprintf('%s\n', Datastruct.mainfield{ii})]; %#ok<*AGROW>
        index = 1;
        plotSize = true;
        while index <= size(Datastruct.subfield,2) && ~isempty(Datastruct.subfield{ii,index})
            swDescr = [swDescr sprintf('    %10s: ',Datastruct.subfield{ii,index})];
            sizefield = Datastruct.sizefield{ii,index};
            typefield = Datastruct.typefield{ii,index};
            
            swDescr = [swDescr sprintf('[')];
            
            for jj = 1:length(sizefield)-1
                objSize = [size(obj.(Datastruct.mainfield{ii}).(Datastruct.subfield{ii,index})) 1 1 1];
                if ischar(sizefield{jj})
                    if plotSize
                        swDescr = [swDescr sprintf('%sx', sizefield{jj})];
                        sF = sizefield{jj};
                        sS = objSize(jj);
                    else
                        swDescr = [swDescr sprintf('%sx', sizefield{jj})];
                    end
                    
                else
                    swDescr = [swDescr sprintf('%dx', sizefield{jj})];
                end
            end
            
            if ischar(sizefield{jj+1})
                if plotSize
                    swDescr = [swDescr sprintf('%s', sizefield{jj+1})];
                    sF = sizefield{jj+1};
                    sS = objSize(jj+1);
                    
                else
                    swDescr = [swDescr sprintf('%s', sizefield{jj+1})];
                end
                
            else
                swDescr = [swDescr sprintf('%d', sizefield{jj+1})];
            end
            swDescr = [swDescr sprintf(' %s]',typefield)];
            if plotSize && exist('sF','var')
                swDescr = [swDescr sprintf('  %s=%d',sF,sS)];
                clear sF sS
                plotSize = false;
            end
            swDescr = [swDescr sprintf('\n')]; %#ok<SPRINTFN>
            index = index + 1;
        end
    end
    
    varargout{1} = swDescr;
else
    
    chem = obj.formula;
    chem.chemform(chem.chemform == ' ') = [];
    chem.chemform(chem.chemform == '_') = [];
    abc  = obj.abc;
    aa   = obj.unit.label{1};
    
    if strcmp(class(obj),'spin')
        swDescr = '     <strong>Spin</strong> object, <a href="matlab:doc @spin">spin</a> class:\n';
    else
        swDescr = '';
    end
    
    swDescr = [swDescr,...
        sprintf('     <strong>Chemical formula</strong>: %s\n',chem.chemform) ...
        sprintf('     <strong>Space group</strong>:      %s\n',obj.lattice.label)...
        sprintf(['     <strong>Lattice</strong>:\n       a=%7.4f ' aa ', b=%7.4f ' aa ', c=%7.4f ' aa '\n'],abc(1),abc(2),abc(3))...
        sprintf(['       ' char(945) '=%6.2f' char(176) ',   ' char(946) '=%6.2f' char(176) ',   ' char(947) '=%6.2f' char(176) '\n'],abc(4),abc(5),abc(6))...
        sprintf('     <strong>Magnetic atoms in the unit cell</strong>: %d\n',numel(obj.matom.S))...
        ];
    
    % print the text
    fprintf(swDescr);
end

end