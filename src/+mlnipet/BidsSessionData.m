classdef BidsSessionData < mlnipet.ResolvingSessionData
	%% BIDSSESSIONDATA  

	%  $Revision$
 	%  was created 05-May-2019 00:05:43 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpipeline/src/+mlpipeline.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
        function loc  = bidsDerivLocation(this, varargin)
            %  e.g.:  /subjectsDir/derivatives/sub-123456/cmrglc
            ip = inputParser;
            addParameter(ip, 'derivFolder', 'new-deriv', @ischar);
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.projectsDir, 'derivatives', this.subjectFolder, ip.Results.derivFolder, ''));
        end
        function loc  = bidsSubjectAnatLocation(this, varargin)
            %  e.g.:  /subjectsDir/sub-123456/anat
            ip = inputParser;
            addParameter(ip, 'anatFolder', 'anat', @ischar);
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, fullfile(this.subjectPath, ip.Results.anatFolder, ''));
        end
        function loc  = bidsSubjectFuncLocation(this, varargin)
            %  e.g.:  /subjectsDir/sub-123456/func
            ip = inputParser;
            addParameter(ip, 'funcFolder', 'func', @ischar);
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, fullfile(this.subjectPath, ip.Results.funcFolder, ''));
        end
        function loc  = bidsSubjectPetLocation(this, varargin)
            %  e.g.:  /subjectsDir/sub-123456/pet
            ip = inputParser;
            addParameter(ip, 'petFolder', 'pet', @ischar);
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, fullfile(this.subjectPath, ip.Results.petFolder, ''));
        end
		  
 		function this = BidsSessionData(varargin)
 			%% BIDSSESSIONDATA
 			%  @param .

 			this = this@mlnipet.ResolvingSessionData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

