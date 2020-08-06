classdef (Abstract) StudyRegistry < handle & mlpet.StudyRegistry
	%% STUDYREGISTRY  

	%  $Revision$
 	%  was created 11-Jun-2019 19:28:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties 
        umapType
    end
    
    properties (Dependent)
        earliestCalibrationDatetime
        fslroiArgs        
        projectsDir
        subjectsDir
    end    
    
    methods (Static)        
        function ses  = experimentID_to_ses(eid)
            split = strsplit(eid, '_');
            ses = ['ses-' split{2}];
        end
        function sub  = subjectID_to_sub(sid)
            split = strsplit(sid, '_');
            sub = ['sub-' split{2}];
        end
    end
    
    methods
        
        %% GET
        
        function g = get.earliestCalibrationDatetime(~)
            g = datetime(2016,7,19, 'TimeZone', 'America/Chicago');
        end
        function g = get.fslroiArgs(~)
            g = mlnipet.ResourcesRegistry.instance().fslroiArgs;
        end        
        function g = get.projectsDir(~)
            g = getenv('PROJECTS_DIR');
        end        
        function     set.projectsDir(~, s)
            assert(isfolder(s));
            setenv('PROJECTS_DIR', s);
        end
        function g = get.subjectsDir(~)
            g = getenv('SUBJECTS_DIR');
        end        
        function     set.subjectsDir(~, s)
            assert(isfolder(s));
            setenv('SUBJECTS_DIR', s);
        end
        
    end

    %% PROTECTED
    
	methods (Access = protected)		  
 		function this = StudyRegistry(varargin)
 			%% STUDYREGISTRY
 			%  @param .

 			this = this@mlpet.StudyRegistry(varargin{:});            
            this.atlVoxelSize = 222;
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

