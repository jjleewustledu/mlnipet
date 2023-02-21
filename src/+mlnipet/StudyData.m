classdef StudyData < handle
	%% STUDYDATA 

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:43
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.  Copyright 2017 John Joowon Lee.
    
    properties
        comments
    end

    properties (Dependent)
        dicomExtension
        freesurfersDir
        rawdataDir

        projectsDir
        subjectsDir
        subjectsFolder
        
        noclobber
        referenceTracer
    end
    
    methods % GET        
        function g = get.dicomExtension(~)
            g = '.dcm';
        end
        function d = get.freesurfersDir(~)
            error('mlnipet:StudyData', '')
        end
        function d = get.rawdataDir(this)
            d = this.registry_.rawdataDir;
        end
        
        function g = get.projectsDir(this)
            g = this.registry_.projectsDir;
        end
        function g = get.subjectsDir(this)
            g = this.registry_.subjectsDir;
        end
        function g = get.subjectsFolder(this)
            g = basename(this.subjectsDir);
        end
        
        function g = get.noclobber(this)
            g = this.registry_.noclobber;
        end
        function g = get.referenceTracer(this)
            g = this.registry_.referenceTracer;
        end
        function     set.referenceTracer(this, s)
            assert(ischar(s));
            this.registry_.referenceTracer = s;
        end
    end

    methods
        function a = seriesDicomAsterisk(this, fqdn)
            assert(isfolder(fqdn));
            assert(isfolder(fullfile(fqdn, 'DICOM')));
            a = fullfile(fqdn, 'DICOM', ['*' this.dicomExtension]);
        end
        
        function this = StudyData(varargin)
            ip = inputParser;
            addRequired(ip, 'registry')
            parse(ip, varargin{:});
            this.registry_ = ip.Results.registry;
        end        
    end  
    
    %% PROTECTED
    
    properties (Access = protected)
        registry_
    end

    %% HIDDEN

    methods (Hidden)
        function diaryOff(~)
            diary off;
        end
        function diaryOn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'path', this.projectsDir, @isfolder);
            parse(ip, varargin{:});
            loc = fullfile(ip.Results.path, diaryfilename('obj', class(this)));
            diary(loc);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

