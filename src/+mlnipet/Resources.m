classdef Resources < mlpatterns.Singleton
	%% RESOURCES 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties (Constant)
        FLIP1 = true % bug at interface with NIPET
        PREFERRED_TIMEZONE = 'America/Chicago'
    end
    
    
    properties 
        keepForensics = true
    end
    
    properties (Dependent)
        dicomExtension
        fslroiArgs
        projectsDir
        subjectsDir
        YeoDir
    end
    
    methods 
        
        %% GET, SET
        
        function g = get.dicomExtension(~)
            g = '.dcm';
        end
        function x = get.fslroiArgs(~)
            x = '86 172 86 172 0 -1';
        end
        function x = get.projectsDir(this)
            x = this.projectsDir_;
        end        
        function     set.projectsDir(this, x)
            assert(ischar(x));
            this.projectsDir_ = x;
        end
        function x = get.subjectsDir(this)
            x = this.subjectsDir_;
        end        
        function     set.subjectsDir(this, x)
            assert(ischar(x));
            this.subjectsDir_ = x;
        end
        function x = get.YeoDir(this)
            x = this.subjectsDir;
        end
        
        %%
        
        function        diaryOff(~)
            diary off;
        end
        function        diaryOn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'path', this.subjectsDir, @isdir);
            parse(ip, varargin{:});            
            diary( ...
                fullfile(ip.Results.path, sprintf('%s_diary_%s.log', mfilename, mydatetimestr(now))));
        end
        function tf   = isChpcHostname(~)
            [~,hn] = mlbash('hostname');
            tf = lstrfind(hn, 'gpu') || lstrfind(hn, 'node') || lstrfind(hn, 'login');
        end
        function loc  = saveWorkspace(this, varargin)
            ip = inputParser;
            addOptional(ip, 'path', this.subjectsDir, @isdir);
            parse(ip, varargin{:});
            loc = fullfile(ip.Results.path, sprintf('%s_workspace_%s.mat', mfilename, mydatetimestr(now)));
            save(loc);
        end
    end
    
    methods (Static)
        function this = instance(qualifier)
            %% INSTANCE uses string qualifiers to implement registry behavior that
            %  requires access to the persistent uniqueInstance
            persistent uniqueInstance
            
            if (exist('qualifier','var') && ischar(qualifier))
                if (strcmp(qualifier, 'initialize'))
                    uniqueInstance = [];
                end
            end
            
            if (isempty(uniqueInstance))
                this = mlnipet.Resources();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end  
    
    %% PROTECTED
    
    properties (Access = protected)
        projectsDir_
        subjectsDir_
    end
    
	methods (Access = protected)		  
 		function this = Resources(varargin)
 			this = this@mlpatterns.Singleton(varargin{:});
            this.subjectsDir_ = getenv('PPG_SUBJECTS_DIR');
            this.projectsDir_ = getenv('PPG_SUBJECTS_DIR');
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

