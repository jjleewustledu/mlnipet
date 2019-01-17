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
        function this = CleanPrototype(varargin)
            ip = inputParser;
            addOptional(ip, 'nipetd', [], @(x) isa(x, 'mlnipet.ISessionData') || isstruct(x));
            parse(ip, varargin{:});
            
            this = mlnipet.NipetBuilder(ip.Results.nipetd); 
            deleteExisting(this.standardMergedName('fullFov', false));
            if (isdir(ip.Results.nipetd.tracerOutputSingleFrameLocation))
                rmdir(ip.Results.nipetd.tracerOutputSingleFrameLocation, 's');
            end
        end
        function this = CreatePrototypeNAC(varargin)
 			nipetd_.itr = 4;
            nipetd_.tracer = 'FDG';
            nipetd_.vnumber = 1;
            nipetd_.tracerConvertedLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-NAC';
            nipetd_.tracerOutputSingleFrameLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-NAC/output/PET/single-frame';
            nipetd_.tracerOutputPetLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-NAC/output/PET';
            nipetd_.lmTag = ...
                'createDynamicNAC';
            
            ip = inputParser;
            addOptional(ip, 'nipetd', nipetd_, @(x) isa(x, 'mlnipet.ISessionData') || isstruct(x));
            parse(ip, varargin{:});
            
            this = mlnipet.NipetBuilder(ip.Results.nipetd);  
            if (lexist(this.standardMergedName('fullFov', false), 'file'))
                this = this.packageProduct(this.standardMergedName('fullFov', false));
                return
            end
            this = this.cleanSingleFrameLocation(ip.Results.nipetd.tracerOutputSingleFrameLocation);
        end
        function this = CreatePrototypeAC(varargin)
 			nipetd_.itr = 4;
            nipetd_.tracer = 'FDG';
            nipetd_.vnumber = 1;
            nipetd_.tracerConvertedLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-AC';
            nipetd_.tracerOutputSingleFrameLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-AC/output/PET/single-frame';
            nipetd_.tracerOutputPetLocation = ...
                '/home2/jjlee/Local/Pawel/NP995_24/V1/FDG_V1-Converted-AC/output/PET';
            nipetd_.lmTag = ...
                'createDynamic2Carney';
            
            ip = inputParser;
            addOptional(ip, 'nipetd', nipetd_, @(x) isa(x, 'mlnipet.ISessionData') || isstruct(x));
            parse(ip, varargin{:});
            
            this = mlnipet.NipetBuilder(ip.Results.nipetd);  
            if (lexist(this.standardMergedName('fullFov', false), 'file'))
                this = this.packageProduct(this.standardMergedName('fullFov', false));
                return
            end
            this = this.cleanSingleFrameLocation(ip.Results.nipetd.tracerOutputSingleFrameLocation);
        end
    end

	methods 
        
        %% GET
        
        function g = get.lmNamesAst(this)
            g = sprintf('%s_itr-%i_t-*-*sec_%s_time*.nii.gz', this.NIPET_PREFIX, this.itr, this.nipetData_.lmTag);
        end
        function g = get.lmNamesRE(this)
            %g = sprintf('%s_\\S+_itr%i_%s_time(?<frame>\\d+).nii.gz', this.NIPET_PREFIX, this.itr, this.nipetData_.lmTag);
            g = sprintf('%s_itr-%i_t-\\d+-\\d+sec_%s_time(?<frame>\\d+).nii.gz', this.NIPET_PREFIX, this.itr, this.nipetData_.lmTag);
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
        
        function this = cleanSingleFrameLocation(this, loc)
            if (~isdir(loc))
                return
            end            
            pwd0 = pushd(loc);        
            names = this.standardizeFileNames;
            name = this.mergeFrames(names);
            name = this.crop(name);
            this = this.packageProduct(name);
            popd(pwd0);
        end
        function fn   = crop(this, FN)
            
            try

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
            catch ME
                dispexcept(ME, 'mlnipet:RuntimeError', 'NipetBuilder.crop could not crop %s', FN);
            end
        end
        function fn   = mergeFrames(this, varargin)
            ip = inputParser;
            addRequired(ip, 'carr', @iscell);
            addOptional(ip, 'output', this.standardMergedName, @ischar);
            parse(ip, varargin{:});
            c = ip.Results.carr;
            fn = ip.Results.output;
            
            assert(~isempty(c));
            cellfun(@(x) assert( ...
                lexist(x, 'file'), 'mlnipet:RuntimeError', 'NipetBuilder.mergeFrames could not find %s', x), ...
                c, 'UniformOutput', false);
            mlbash(sprintf('fslmerge -t %s %s', fn, cell2str(c, 'AsRows', true)));
        end
        function fn   = standardMergedName(this, varargin)
            %% specifies standard name for given tracer, vnumber for all available frames.  
            %  @param fullFov is logical.
            
            ip = inputParser;
            addParameter(ip, 'fullFov', true, @islogical);
            parse(ip, varargin{:});            
            if (ip.Results.fullFov)
                tr = upper(this.tracer);
            else
                tr = lower(this.tracer);
            end            
            fn = fullfile( ...
                this.nipetData_.tracerOutputPetLocation, sprintf('%sv%i.nii.gz', tr, this.vnumber));
        end
        function fn   = standardFramedName(this, fr)
            %% specifies standard name for given tracer, vnumber and frame.
            %  @param fr is numeric frame index | 
            %  @param fr is char for pattern matching.
            %  @return single filename.nii.gz for NIfTI.
            
            if (isnumeric(fr))
                fn = sprintf('%sv%i_frame%i.nii.gz', upper(this.tracer), this.vnumber, fr);
                return
            end
            if (ischar(fr))
                fn = sprintf('%sv%i_frame%s.nii.gz', upper(this.tracer), this.vnumber, fr);
                return
            end
            error('mlnipet:ValueError', 'NipetBuilder.standardFramedName');
        end
        function nn   = standardFramedNames(this, fr)
            %% specifies standard names for given tracer, vnumber and frames.
            %  Frame corruption is mitigated by enumerating consecutive frames starting from frame0.
            %  @param fr is numeric array of frame numbers | 
            %  @param fr is pattern-matching char to be interpreted by standardFramedName for frames starting with frame0.
            %  @return cell array standardFramedName instances.
            
            if (isnumeric(fr))
                nn = cellfun(@(x) this.standardFramedName(x), num2cell(fr), 'UniformOutput', false);
                return
            end
            if (ischar(fr))
                dt = mlsystem.DirTool(this.standardFramedName(fr));
                nn  = this.standardFramedNames(0:length(dt.fns)-1);
                return
            end
            error('mlnipet:ValueError', 'NipetBuilder.standardFramedNames');
        end
        function nn   = standardizeFileNames(this)
            %% renames unsorted files matching lmNamesAst with new names specified by standardFramedName.  
            %  Frame numbers are read from filenames by regexp with lmNamesAst.
            %  Frame corruption is mitigated by enumerating consecutive frames starting from frame0.
            %  @return nn is cell array of short, mnemonic names in frame-numerical order starting from frame0 |
            %  @return previously renamed files if there are no matches with lmNamesAst.
            
            unsorted = mlsystem.DirTool(this.lmNamesAst); % filesystem-name sorted, not frame-numerically sorted
            if (isempty(unsorted.fns)) % files were previously renamed
                nn = this.standardFramedNames('*'); 
                return
            end
            
            for f = 1:length(unsorted)
                r = regexp(unsorted.fns{f}, this.lmNamesRE, 'names');
                movefile(unsorted.fns{f}, this.standardFramedName(str2double(r.frame)));
            end
            nn = this.standardFramedNames(0:length(unsorted.fns)-1);
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

