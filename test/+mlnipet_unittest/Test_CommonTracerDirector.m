classdef Test_CommonTracerDirector < matlab.unittest.TestCase
    %% line1
    %  line2
    %  
    %  Created 19-Apr-2022 21:04:28 by jjlee in repository /Users/jjlee/MATLAB-Drive/mlnipet/test/+mlnipet_unittest.
    %  Developed on Matlab 9.12.0.1884302 (R2022a) for MACI64.  Copyright 2022 John J. Lee.
    
    properties
        acPath
        acPath2
        nacPath
        nacPath2
        sesPath
        sesPath2
    end
    
    methods (Test)
        function test_afun(this)
            import mlnipet.*
            this.assumeEqual(1,1);
            this.verifyEqual(1,1);
            this.assertEqual(1,1);
        end
        function test_construct_resolved(this)
            % single nacPath
            construct_resolved(this.nacPath, 'umaptype', 'ct')

            % csv of nacPaths2
            construct_resolved(this.nacPaths2Csv(), 'umaptype', 'deep')
        end
        function test_construct_umaps(this)
            % single nacPath
            construct_umaps(this.nacPath, 'umaptype', 'ct')

            % csv of nacPaths2
            construct_umaps(this.nacPaths2Csv(), 'umaptype', 'deep')
        end
    end
    
    methods (TestClassSetup)
        function setupCommonTracerDirector(this)
            this.sesPath = fullfile( ...
                getenv('SINGULARITY_PATH'), 'CCIR_00559_00754', 'derivatives', 'nipet', 'ses-E03056');
            this.nacPath = fullfile(this.sesPath, 'HO_DT20190523120249.000000-Converted-NAC');
            this.acPath = fullfile(this.sesPath, 'HO_DT20190523120249.000000-Converted-AC');

            this.sesPath2 = fullfile( ...
                getenv('SINGULARITY_PATH'), 'CCIR_00993', 'derivatives', 'nipet', 'ses-E03140');
            this.nacPath2 = fullfile(this.sesPath, 'HO_DT20190530111122.000000-Converted-NAC');
            this.nacPath2 = fullfile(this.sesPath, 'HO_DT20190530111122.000000-Converted-AC');
        end
    end
    
    methods (TestMethodSetup)
        function setupCommonTracerDirectorTest(this)
            this.addTeardown(@this.cleanTestMethod)
        end
    end
    
    properties (Access = private)
        testObj_
    end
    
    methods (Access = private)
        function cleanTestMethod(this)
        end
        function fn = nacPathsCsv(this)
            g = glob(fullfile(this.sesPath, 'HO_DT*.000000-Converted-NAC'));
            T = table(g(1:2));
            fn = fullfile(strcat(tempname, '.csv'));
            writetable(T, fn, 'WriteVariableNames', false);
        end
        function fn = nacPaths2Csv(this)
            g = glob(fullfile(this.sesPath2, 'HO_DT*.000000-Converted-NAC'));
            T = table(g(1:2));
            fn = fullfile(strcat(tempname, '.csv'));
            writetable(T, fn, 'WriteVariableNames', false);
        end
    end
    
    %  Created with mlsystem.Newcl, inspired by Frank Gonzalez-Morphy's newfcn.
end
