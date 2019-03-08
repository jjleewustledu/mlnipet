classdef (Abstract) ISessionData 
	%% ISESSIONDATA  

	%  $Revision$
 	%  was created 04-Dec-2018 15:45:39 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract)  
        compAlignMethod
        epoch
        filetypeExt
        frameAlignMethod
        itr
        outfolder        
        
        attenuationTag
        convertedTag
        epochTag
        frameTag    
        lmTag
        maxLengthEpoch
        regionTag
        resolveTag
        rnumber
        supEpoch
        taus
        times
        useNiftyPet
    end
    
    methods (Abstract)
        obj = ctRescaled(this)
        fn  = listmodeJson(this)    
        tag = resolveTagFrame(this, fr)
        loc = tracerConvertedLocation(this)
        loc = tracerLocation(this)
        obj = tracerNipet(this)
        loc = tracerOutputLocation(this)
        loc = tracerOutputPetLocation(this)
        loc = tracerOutputSingleFrameLocation(this)        
        fn  = tracerPristine(this)
        fn  = tracerResolved(this)
        fn  = tracerResolvedSumt(this)
        fn  = tracerRevision(this)
        fn  = tracerRevisionSumt(this)
        obj = umapSynth(this)
        obj = umapSynthOpT1001(this)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

