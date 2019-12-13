classdef IResources < handle
	%% IRESOURCES  

	%  $Revision$
 	%  was created 16-May-2019 18:55:08 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Abstract, Constant)
        PREFERRED_TIMEZONE
    end
    
	properties (Abstract)
        keepForensics
        projectsDir
        subjectsDir
        YeoDir
 	end

	methods 
		  
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

