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
        subjectsDir
        subjectsFolder
    end
    
    methods
        
        %% GET
        
        function g = get.dicomExtension(~)
            g = '.dcm';
        end
        function d = get.freesurfersDir(~)
            d = fullfile(getenv('PPG'), 'freesurfer', '');
        end
        function d = get.rawdataDir(~)
            d = mlnipet.Resourcese.instance.rawdataDir;
        end
        function g = get.subjectsDir(~)
            g = mlnipet.Resourcese.instance.subjectsDir;
        end
        function g = get.subjectsFolder(this)
            g = basename(this.subjectsDir);
        end
        
        %%
        
        function a    = seriesDicomAsterisk(this, fqdn)
            assert(isdir(fqdn));
            assert(isdir(fullfile(fqdn, 'DICOM')));
            a = fullfile(fqdn, 'DICOM', ['*' this.dicomExtension]);
        end        
        function f    = subjectsDirFqdns(this)
            if (isempty(this.subjectsDir))
                f = {};
                return
            end
            
            dt = mlsystem.DirTools(this.subjectsDir);
            f = {};
            for di = 1:length(dt.dns)
                if (strncmp(dt.dns{di}, 'NP', 2) || strncmp(dt.dns{di}, 'HY', 2))
                    f = [f dt.fqdns(di)]; %#ok<AGROW>
                end
            end
        end
        
 		function this = StudyData(varargin)
 			this = this@mlpipeline.StudyData(varargin{:});
        end        
    end  

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

