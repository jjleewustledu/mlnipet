classdef (Abstract) StudyRegistry < handle & mlpatterns.Singleton2
	%% STUDYREGISTRY  

	%  $Revision$
 	%  was created 11-Jun-2019 19:28:49 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        PREFERRED_TIMEZONE = 'America/Chicago'
    end

    properties 
        atlasTag = '_111'
        atlasCode = 111
        comments = ''
        noclobber = true
        numberNodes
        voxelTime = 60 % sec
        wallClockLimit = 168*3600 % sec
    end
    
    properties (Dependent)
        earliestCalibrationDatetime
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
    
    methods
        
        %% GET
        
        function g = get.earliestCalibrationDatetime(~)
            %g = datetime(2015,1,1, 'TimeZone', 'America/Chicago'); % accomodates sub-S33789
            g = datetime(2016,7,19, 'TimeZone', 'America/Chicago');
        end
        
    end

    %% PROTECTED
    
	methods (Access = protected)		  
 		function this = StudyRegistry(varargin)
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

