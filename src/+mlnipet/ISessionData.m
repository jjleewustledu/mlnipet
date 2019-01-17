classdef (Abstract) ISessionData 
	%% ISESSIONDATA  

	%  $Revision$
 	%  was created 04-Dec-2018 15:45:39 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract)        
        itr
        lmTag
        outfolder
        tracer
        vnumber
    end
    
    methods (Abstract)
        loc = tracerConvertedLocation(this)
        obj = tracerNipet(this)
        loc = tracerOutputSingleFrameLocation(this)
        loc = tracerOutputLocation(this)
        loc = tracerOutputPetLocation(this)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

