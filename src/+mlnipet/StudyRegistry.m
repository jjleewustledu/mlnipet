classdef (Abstract) StudyRegistry < handle & mlpipeline.StudyRegistry
	%% STUDYREGISTRY  

	%  $Revision$
 	%  was created 11-Jun-2019 19:28:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.

    properties
        voxelTime = 60 % sec
        wallClockLimit = 168*3600 % sec
    end

    properties (Dependent)
        sessionsDir
        subjectsDir
    end    
    
    methods % GET
        function g = get.sessionsDir(this)
            g = fullfile(this.projectsDir, this.projectFolder, 'derivatives', 'nipet', '');
        end
        function g = get.subjectsDir(this)
            g = fullfile(this.projectsDir, this.projectFolder, 'derivatives', 'resolve', '');
        end
    end
    
    methods (Static)        
        function ses  = experimentID_to_ses(eid)
            assert(istext(eid));
            split = strsplit(eid, '_');
            ses = strcat('ses-', split{end});
        end
        function sub  = subjectID_to_sub(sid)
            assert(istext(sid));
            split = strsplit(sid, '_');
            sub = strcat('sub-', split{end});
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

