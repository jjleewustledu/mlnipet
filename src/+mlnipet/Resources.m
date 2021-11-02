classdef Resources < handle & mlpatterns.Singleton
	%% RESOURCES 

	%  $Revision$
 	%  was created 15-Oct-2015 16:31:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties (Constant)
        CCIR_RAD_MEASUREMENTS_DIR = getenv('CCIR_RAD_MEASUREMENTS_DIR')
        FLIP1 = true % bug at interface with NIPET
        PREFERRED_TIMEZONE = 'America/Chicago'
        PROJECTS_DIR = getenv('PROJECTS_DIR')
        SINGULARITY_HOME = getenv('SINGULARITY_HOME')
        SUBJECTS_DIR = getenv('SUBJECTS_DIR')
    end
    
    
    properties 
        atlVoxelSize = 222
        comments = ''
        keepForensics = true
    end
    
    properties (Dependent)
        debug
        dicomExtension
        fslroiArgs
    end
    
    methods 
        
        %% GET, SET
        
        function g = get.debug(~)
            g = getenv('DEBUG');
            g = ~isempty(g);
        end
        function     set.debug(~, s)
            if (isempty(s))
                setenv('DEBUG', '');
                return
            end
            if (islogical(s))
                if (s)
                    s = 'TRUE';
                else
                    s = '';
                end
            end
            if (isnumeric(s))
                if (s ~= 0)
                    s = 'TRUE';
                else
                    s = '';
                end
            end
            assert(ischar(s));
            setenv('DEBUG', s);            
        end
        function g = get.dicomExtension(~)
            g = '.dcm';
        end
        function g = get.fslroiArgs(~)
            g = '86 172 86 172 0 -1';
        end
        
        %%
        
        function       diaryOff(~)
            diary off;
        end
        function       diaryOn(this, varargin)
            ip = inputParser;
            addOptional(ip, 'path', this.projectsDir, @isdir);
            parse(ip, varargin{:});            
            diary( ...
                fullfile(ip.Results.path, sprintf('%s_diary_%s.log', mfilename, mydatetimestr(now))));
        end
        function tf  = isChpcHostname(~)
            [~,hn] = mlbash('hostname');
            tf = lstrfind(hn, 'gpu') || lstrfind(hn, 'node') || lstrfind(hn, 'login') || lstrfind(hn, 'cluster');
        end
        function loc = saveWorkspace(this, varargin)
            ip = inputParser;
            addOptional(ip, 'path', this.projectsDir, @isdir);
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
    
	methods (Access = protected)		  
 		function this = Resources(varargin)
 			this = this@mlpatterns.Singleton(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

