classdef NipetBuilder < mlpipeline.AbstractBuilder
	%% NIPETBUILDER

	%  $Revision$
 	%  was created 15-Nov-2018 19:38:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
        FSLROI_ARGS = '86 172 86 172 0 -1'
 		LISTMODE_PREFIX = '1.3.12.2.1107.5.2.38.51010'
        NIPET_PREFIX = 'a' %'1.3.12.2'
    end
    
    properties (Dependent)
        itr
        lmNamesAst
        lmNamesRE
        tracer
        vnumber
    end
    
    methods (Static)
        function this = CreatePrototypeNAC(varargin)
 			nipetd_.itr = 4;
            nipetd_.tracer = 'FDG';
            nipetd_.vnumber = 1;
            nipetd_.tracerConvertedLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-NAC';
            nipetd_.tracerOutputSingleFrameLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-NAC/output/PET/single-frame';
            nipetd_.tracerOutputLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-NAC/output/PET';
            nipetd_.lmTag = ...
                'createDynamicNAC';
            
            ip = inputParser;
            addOptional(ip, 'nipetd', nipetd_, @(x) isa(x, 'mlnipet.ISessionData') || isstruct(x));
            parse(ip, varargin{:});
            
            pwd0 = pushd(ip.Results.nipetd.tracerOutputSingleFrameLocation);
            this = mlnipet.NipetBuilder(ip.Results.nipetd);            
            names = this.standardizeFileNames;
            name = this.mergeFrames(names);
            name = this.crop(name);
            this = this.packageProduct(name);
            popd(pwd0);
        end
        function this = CreatePrototypeAC(varargin)
 			nipetd_.itr = 4;
            nipetd_.tracer = 'FDG';
            nipetd_.vnumber = 1;
            nipetd_.tracerConvertedLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-AC';
            nipetd_.tracerOutputSingleFrameLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-AC/output/PET/single-frame';
            nipetd_.tracerOutputLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-AC/output/PET';
            nipetd_.lmTag = ...
                'createDynamic2Carney';
            
            ip = inputParser;
            addOptional(ip, 'nipetd', nipetd_, @(x) isa(x, 'mlnipet.ISessionData') || isstruct(x));
            parse(ip, varargin{:});
            
            pwd0 = pushd(ip.Results.nipetd.tracerOutputSingleFrameLocation);
            this = mlnipet.NipetBuilder(ip.Results.nipetd);            
            names = this.standardizeFileNames;
            name = this.mergeFrames(names);
            name = this.crop(name);
            this = this.packageProduct(name);
            popd(pwd0);
        end
    end

	methods 
        
        %% GET
        
        function g = get.lmNamesAst(this)
            g = sprintf('%s_itr-%i_t-*-*sec_%s_time*.nii.gz', this.NIPET_PREFIX, this.itr, this.nipetData_.lmTag);
        end
        function g = get.lmNamesRE(this)
            %g = sprintf('%s_\\S+_itr%i_%s_time(?<frame>\\d+).nii.gz', this.NIPET_PREFIX, this.itr, this.nipetData_.lmTag);
            g = sprintf('%s_itr-%i_t-\\d+-\\d+sec_%stime(?<frame>\\d+).nii.gz', this.NIPET_PREFIX, this.itr, this.nipetData_.lmTag);
        end
        function g = get.itr(this)
            g = this.nipetData_.itr;
        end
        function g = get.tracer(this)
            g = this.nipetData_.tracer;
        end
        function g = get.vnumber(this)
            g = this.nipetData_.vnumber;
        end
        
        %%
        
        function fn   = crop(this, FN)
            
            % recursion
            if (iscell(FN))
                fn = cell(1, length(FN));
                for i = 1:length(FN)
                    fn{i} = this.crop(FN{i});
                end
            end
            
            % base case
            [pth,fp,x] = myfileparts(FN);
            fn = fullfile(pth, [lower(fp) x]);
            if (~strcmp(fn, FN))
                pwd0 = pushd(myfileparts(FN));
                mlbash(sprintf('fslroi %s %s %s', FN, fn, this.FSLROI_ARGS));
                popd(pwd0);
            end
        end
        function n    = mergeFrames(this, varargin)
            ip = inputParser;
            addRequired(ip, 'carr', @iscell);
            addOptional(ip, 'output', this.standardMergedName, @ischar);
            parse(ip, varargin{:});
            c = ip.Results.carr;
            n = ip.Results.output;
            
            assert(~isempty(c));
            mlbash(sprintf('fslmerge -t %s %s', n, cell2str(c, 'AsRows', true)));
        end
        function n    = standardMergedName(this)
            n = fullfile( ...
                this.nipetData_.tracerOutputLocation, ...
                sprintf('%sv%i.nii.gz', upper(this.tracer), this.vnumber));
        end
        function n    = standardFramedName(this, fr)
            if (isnumeric(fr))
                n = sprintf('%sv%i_frame%i.nii.gz', upper(this.tracer), this.vnumber, fr);
                return
            end
            if (ischar(fr))
                n = sprintf('%sv%i_frame%s.nii.gz', upper(this.tracer), this.vnumber, fr);
                return
            end
            error('mlnipet:ValueError', 'NipetBuilder.standardFramedName');
        end
        function n    = standardFramedNames(this, fr)
            if (isnumeric(fr))
                n = cellfun(@(x) this.standardFramedName(x), num2cell(fr), 'UniformOutput', false);
                return
            end
            if (ischar(fr))
                dt = mlsystem.DirTool(this.standardFramedName(fr));
                n  = this.standardFramedNames(0:length(dt.fns)-1);
                return
            end
            error('mlnipet:ValueError', 'NipetBuilder.standardFramedNames');
        end
        function n    = standardizeFileNames(this)
            %  @return n is cell array of short, mnemonic names in frame-numerical order.
            
            unsorted = mlsystem.DirTool(this.lmNamesAst); % filesystem-name sorted, not frame-numerically sorted
            if (isempty(unsorted.fns)) % files were previously renamed
                n = this.standardFramedNames('*'); 
                return
            end
            
            for f = 1:length(unsorted)
                r = regexp(unsorted.fns{f}, this.lmNamesRE, 'names');
                movefile(unsorted.fns{f}, this.standardFramedName(str2double(r.frame)));
            end
            n = this.standardFramedNames(0:length(unsorted.fns)-1);
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
    
    %% PRIVATE
    
    properties (Access = private)
        nipetData_
    end
    
    methods (Access = private)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

