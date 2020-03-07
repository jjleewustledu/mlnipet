classdef (Sealed) ResourcesRegistry < handle & mlpatterns.Singleton2
	%% RESOURCESREGISTRY  

	%  $Revision$
 	%  was created 11-Jun-2019 21:46:40 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties 		
        FLIP1 = true % bug at interface with NIPET
        fslroiArgs = '86 172 86 172 0 -1'
    end
    
    properties (Dependent)
        noiseFloorOfActivity
        petPointSpread
        reconstructionVersion
        suffixPetPointSpread
    end
    
    methods (Static)
        function this = instance(varargin)
            %% INSTANCE
            %  @param optional qualifier is char \in {'initialize' ''}
            
            ip = inputParser;
            addOptional(ip, 'qualifier', '', @ischar)
            parse(ip, varargin{:})
            
            persistent uniqueInstance
            if (strcmp(ip.Results.qualifier, 'initialize'))
                uniqueInstance = [];
            end          
            if (isempty(uniqueInstance))
                this = mlnipet.ResourcesRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end 
    
    methods
        
        %% GET
        
        function g = get.noiseFloorOfActivity(~)
            g = 0; % Bq/mL
        end
        function g = get.petPointSpread(~)
            g = mlsiemens.MMRRegistry.instance.petPointSpread;
        end
        function g = get.reconstructionVersion(~)
            g = sprintf('nipet=1.1');
            %g = sprintf('Siemens e7 E11p');
        end
        function g = get.suffixPetPointSpread(~)
            g = mlsiemens.MMRRegistry.instance.petPointSpread('imgblur_4dfp', true);
        end
    end

    %% PRIVATE
    
	methods	(Access = private)
 		function this = ResourcesRegistry(varargin)
 			%% RESOURCESREGISTRY
 			%  @param .
 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

