classdef readparamTests < matlab.unittest.TestCase
    %SPECTRAMATHSTESTS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        names
        values
        sizes
        validation
        labels
    end
    
    methods (Test)
        % This should test if compatible
        function basic_createObject(testCase)
            for i = 1:length(testCase.names)
                testCase.verifyClass(readparam('fname', testCase.names(1:i), 'defval',testCase.values(1:i), 'size', testCase.sizes(1:i)),'readparam')
            end
        end
        % These are the features of the new class
        function advanced_createObject(testCase)
            for i = 1:length(testCase.names)
                testCase.verifyClass(...
                    readparam('fname', testCase.names(1:i), 'defval',testCase.values(1:i), 'size', testCase.sizes(1:i),...
                    'validation',testCase.validation(1:i)),'readparam');
            end
            for i = 1:length(testCase.names)
                testCase.verifyClass(...
                    readparam('fname', testCase.names(1:i), 'defval',testCase.values(1:i), 'size', testCase.sizes(1:i),...
                    'validation',testCase.validation(1:i),'label',testCase.labels(1:i)),'readparam');
            end
        end
        % Now test the getting of values...
        function test_getObject(testCase)
            these_values = testCase.values;
            for i = 1:length(testCase.names)
                this_param(i) = readparam('fname', testCase.names(1:i), 'defval',testCase.values(1:i), 'size', testCase.sizes(1:i));
                fnames = testCase.names(1:i);
                for j = 1:length(fnames)
                   testCase.verifyEqual(this_param(i).(fnames{j}),these_values{strcmp(fnames{j},testCase.names)})
                   testCase.verifyEqual(this_param(i).get(fnames{j}),these_values{strcmp(fnames{j},testCase.names)})
                end
            end
        end
        % Now test the setting of values...
        function test_setObject(testCase)
            these_values = testCase.values;
            for i = 1:length(testCase.names)
                this_param(i) = readparam('fname', testCase.names(1:i), 'defval',testCase.values(1:i), 'size', testCase.sizes(1:i));
                fnames = testCase.names(1:i);
                fvalues = testCase.values(1:i);
                for j = 1:length(fnames)
                   testCase.verifyEqual(this_param(i).(fnames{j}),these_values{strcmp(fnames{j},testCase.names)})
                end
            end
        end
        
        
        
    end
    
    methods (TestMethodSetup)
        function makeIN(testCase)
            rng(314152, 'twister');
            testCase.names = {...
                'this', 'that' , 'master', ...
                'slave', 'first', 'second',...
                'red', 'green', 'blue'...
                };
            testCase.values = {...
                rand(1,1), rand(5,3), 'why', ...
                'me', rand(1,1) 'men',...
                rand(1,1), {'test'}, @isstr...
                };
            testCase.sizes = {...
                [1, 1], [5, 3], [1, -1],...
                [1, 2], [1, -2], [1, -3],...
                [1, -2], [1, 1], [1,1]...
                };
            testCase.validation = {...
                @(x) x > 0, @isreal, '',...
                @ischar, '', @ischar,...
                {@isreal, @isnumeric}, '', @(x) isa(x,'function_handle')...
                };
            testCase.labels = {...
                'a', 'b', 'c',...
                '' , 'd', 'e',...
                'this', 'is a', 'label'...
                };
        end
    end
end