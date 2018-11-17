classdef NipetBuilder 
	%% NIPETBUILDER

	%  $Revision$
 	%  was created 15-Nov-2018 19:38:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
 		LISTMODE_PREFIX = '1.3.12.2.1107.5.2.38.51010'
        NIPET_PREFIX = '1.3.12.2'
    end
    
    properties (Dependent)
        lmNamesAst
        lmNamesRE
        itr
        tracer
        visit
    end
    
    methods (Static)
        function this = CreatePrototype
 			nipetData.itr = 5;
            nipetData.tracer = 'FDG';
            nipetData.visit = 1;
            nipetData.tracerConvertedLocation = '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-NAC';
            
            this = mlnipet.NipetBuilder(nipetData);            
            names = this.standardizeFileNames;
            name = this.mergeFrames(names);
            %this.crop(names);
            this.crop(name);
        end
    end

	methods 
        
        %% GET
        
        function g = get.lmNamesAst(this)
            g = sprintf('%s*_itr%i_createDynamicNAC_time*.nii.gz', this.NIPET_PREFIX, this.itr);
        end
        function g = get.lmNamesRE(this)
            g = sprintf('%s_\\S+_itr%i_createDynamicNAC_time(?<frame>\\d+).nii.gz', this.NIPET_PREFIX, this.itr);
        end
        function g = get.itr(this)
            g = this.nipetData_.itr;
        end
        function g = get.tracer(this)
            g = this.nipetData_.tracer;
        end
        function g = get.visit(this)
            g = this.nipetData_.visit;
        end
        
        %%
        
        function fn = crop(this, FN)
            
            % recursion
            if (iscell(FN))
                fn = cell(1, length(FN));
                for i = 1:length(FN)
                    fn{i} = this.crop(FN{i});
                end
            end
            
            % base case
            fn = lower(FN);
            if (~strcmp(fn, FN));
                mlbash(sprintf('fslroi %s %s 86 172 86 172 0 -1', FN, fn));
            end
        end
        function n = mergeFrames(this, varargin)
            ip = inputParser;
            addRequired(ip, 'carr', @iscell);
            addOptional(ip, 'output', this.standardMergedName, @ischar);
            n = ip.Results.output;
            parse(ip, varargin{:});
            if (isempty(ip.Results.carr))
                return
            end

            mlbash(sprintf('fslmerge -t %s %s', n, cell2str(ip.Results.carr, 'AsRows', true)));
        end
        function n = standardMergedName(this)
            n = sprintf('%sv%i.nii.gz', upper(this.tracer), this.visit);
        end
        function n = standardFramedName(this, fr)
            assert(isnumeric(fr));
            n = sprintf('%sv%i_frame%i.nii.gz', upper(this.tracer), this.visit, fr);
        end
        function carr = standardizeFileNames(this)
            %  @return carr is cell array of short, mnemonic names.
            
            pwd0 = pushd(fullfile(this.nipetData_.tracerConvertedLocation, 'reconstructed', ''));
            lms = mlsystem.DirTool(this.lmNamesAst);
            carr = cell(1, length(lms));
            for f = 1:length(lms)
                r = regexp(lms.fns{f}, this.lmNamesRE, 'names');
                carr{f} = this.standardFramedName(str2double(r.frame));
                movefile(lms.fns{f}, carr{f});
            end
            popd(pwd0);
        end        
		  
 		function this = NipetBuilder(varargin)
 			%% NIPETBUILDER
 			%  @param .
            
            ip = inputParser;
            addRequired(ip, 'nipetData', @(x) ~isempty(x));
            parse(ip, varargin{:});
            
            this.nipetData_ = ip.Results.nipetData;
 		end
    end 
    
    %% PRIvATE
    
    properties (Access = private)
        nipetData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

