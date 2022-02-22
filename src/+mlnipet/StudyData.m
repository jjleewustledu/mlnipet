classdef StudyData < handle & mlpipeline.StudyData
	%% STUDYDATA  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:43
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2017 John Joowon Lee.
    
    
    properties (Dependent)
        dicomExtension
        freesurfersDir
        rawdataDir
    end
    
    methods
        
        %% GET
        
        function g = get.dicomExtension(~)
            g = '.dcm';
        end
        function d = get.freesurfersDir(~)
            error('mlnipet:StudyData', '')
        end
        function d = get.rawdataDir(this)
            d = this.registry_.rawdataDir;
        end
        
        %%
        
        function a = seriesDicomAsterisk(this, fqdn)
            assert(isfolder(fqdn));
            assert(isfolder(fullfile(fqdn, 'DICOM')));
            a = fullfile(fqdn, 'DICOM', ['*' this.dicomExtension]);
        end
        
 		function this = StudyData(varargin)
 			this = this@mlpipeline.StudyData(varargin{:});
        end        
    end  

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

