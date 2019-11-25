classdef NipetBuilder < mlpipeline.AbstractBuilder
	%% NIPETBUILDER accepts reconstruction results from NIPET and prepares 4dfp for other components of construct_resolved.

	%  $Revision$
 	%  was created 15-Nov-2018 19:38:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
        NIPET_PREFIX = 'a' %'1.3.12.2'
    end
    
    properties (Dependent)
        itr
        lmNamesAst
        lmNamesRE
        snumber
        tracer
    end
    
    methods (Static)
        function this = CleanPrototype(varargin)
            ip = inputParser;
            addOptional(ip, 'nipetd', [], @(x) isa(x, 'mlpipeline.ISessionData') || isstruct(x));
            parse(ip, varargin{:});
            
            this = mlnipet.NipetBuilder(ip.Results.nipetd); 
            deleteExisting(this.standardMergedName('fullFov', false));
            if (isfolder(ip.Results.nipetd.tracerOutputSingleFrameLocation))
                rmdir(ip.Results.nipetd.tracerOutputSingleFrameLocation, 's');
            end
        end
        function this = CreatePrototypeNAC(varargin)
            
            % prototypical values, inconsequential if passing ISessionData
 			nipetd_.itr = 4;
            nipetd_.tracer = 'none';
            nipetd_.tracerConvertedLocation = tempdir;
            nipetd_.tracerOutputSingleFrameLocation = tempdir;
            nipetd_.tracerOutputPetLocation = tempdir;
            nipetd_.lmTag = 'createDynamicNAC';
            
            ip = inputParser;
            addOptional(ip, 'nipetd', nipetd_, @(x) isa(x, 'mlpipeline.ISessionData') || isstruct(x));
            parse(ip, varargin{:});
            
            this = mlnipet.NipetBuilder(ip.Results.nipetd);  
            if (lexist(this.standardMergedName('fullFov', false), 'file'))
                this = this.packageProduct(this.standardMergedName('fullFov', false));
                return
            end
            this = this.packageSingleFrameLocation(ip.Results.nipetd.tracerOutputSingleFrameLocation);
        end
        function this = CreatePrototypeAC(varargin)
            
            % prototypical values, inconsequential if passing ISessionData
 			nipetd_.itr = 4;
            nipetd_.tracer = 'none';
            nipetd_.tracerConvertedLocation = tempdir;
            nipetd_.tracerOutputSingleFrameLocation = tempdir;
            nipetd_.tracerOutputPetLocation = tempdir;
            nipetd_.lmTag = 'createDynamic2Carney';            
            ip = inputParser;
            addOptional(ip, 'nipetd', nipetd_, @(x) isa(x, 'mlpipeline.ISessionData') || isstruct(x));
            parse(ip, varargin{:});
            
            this = mlnipet.NipetBuilder(ip.Results.nipetd);
            if (lexist(this.standardMergedName('fullFov', false), 'file'))
                this = this.packageProduct(this.standardMergedName('fullFov', false));
                return
            end
            singleFrameLoc = ip.Results.nipetd.tracerOutputSingleFrameLocation;
            PETLoc = fileparts(singleFrameLoc);
            assert(~isempty(glob( ...
                fullfile(PETLoc, [upper(ip.Results.nipetd.tracer) '_DT*.json']))))
            assert(isfile( ...
                fullfile(PETLoc, 'reconstruction_Reconstruction_finished.touch')))
            assert(isfile( ...
                fullfile(PETLoc, 'reconstruction_Reconstruction_started.touch')))
            %assert(isfolder(singleFrameLoc))
            %dt = mlsystem.DirTool(fullfile(singleFrameLoc, '*'));
            %if isempty(dt.fqfns)
            %    rmdir(fullfile(singleFrameLoc))
            %    return
            %end
            if isfolder(singleFrameLoc)
                this = this.packageSingleFrameLocation(singleFrameLoc);
            end
        end
    end

	methods 
        
        %% GET
        
        function g = get.lmNamesAst(this)
            g = { sprintf('%s_itr-*_t-*-*sec_%s_time*.nii.gz', this.NIPET_PREFIX, this.nipetData_.lmTag) ...
                  sprintf('%s_t-*-*sec_itr-*_%s_time*.nii.gz', this.NIPET_PREFIX, this.nipetData_.lmTag) };
        end
        function g = get.lmNamesRE(this)
            %g = sprintf('%s_\\S+_itr%i_%s_time(?<frame>\\d+).nii.gz', this.NIPET_PREFIX, this.itr, this.nipetData_.lmTag);
            g = { sprintf('%s_itr-\\d+_t-\\d+-\\d+sec_%s_time(?<frame>\\d+).nii.gz', this.NIPET_PREFIX, this.nipetData_.lmTag) ...
                  sprintf('%s_t-\\d+-\\d+sec_itr-\\d+_%s_time(?<frame>\\d+).nii.gz', this.NIPET_PREFIX, this.nipetData_.lmTag)  };
        end
        function g = get.itr(this)
            g = this.nipetData_.itr;
        end
        function g = get.snumber(this)
            g = this.nipetData_.snumber;
        end
        function g = get.tracer(this)
            g = this.nipetData_.tracer;
        end
        
        %%
        
        function this = packageSingleFrameLocation(this, loc)
            pwd0 = pushd(loc);
            this.standardizeObsoleteFileNames()
            names = this.standardizeFileNames();
            name = this.mergeFrames(names);
            name = this.crop(name);
            name = this.fillmissing(name);
            this = this.packageProduct(name);
            popd(pwd0);
        end
        function fn   = crop(this, FN)
            
            res = mlnipet.ResourcesRegistry.instance();
            
            try
                % recursion
                if (iscell(FN))
                    fn = cell(1, length(FN));
                    for i = 1:length(FN)
                        fn{i} = this.crop(FN{i});
                    end
                end
            catch ME
                dispexcept(ME, 'mlnipet:RuntimeError', 'NipetBuilder.crop could not crop %s on recursion', FN);
            end

            try
                % base case
                [pth,fp,x] = myfileparts(FN);
                fn = fullfile(pth, [lower(fp) x]);
                if (~strcmp(fn, FN))
                    pwd0 = pushd(myfileparts(FN));
                    mlbash(sprintf('fslroi %s %s %s', FN, fn, res.fslroiArgs));
                    popd(pwd0);
                end
            catch ME
                dispexcept(ME, 'mlnipet:RuntimeError', 'NipetBuilder.crop could not crop %s in the base case', FN);
            end
        end
        function fn   = fillmissing(this, fn)
            ic2 = mlfourd.ImagingContext2(this.ensureNiigz(fn));
            nii = ic2.nifti;
            nii.img = fillmissing(nii.img, 'constant', 0);
            nii.save;
        end
        function fn   = mergeFrames(this, varargin)
            ip = inputParser;
            addRequired(ip, 'carr', @(x) iscell(x) && ~isempty(x));
            addOptional(ip, 'output', this.standardMergedName, @ischar);
            parse(ip, varargin{:});
            c = ip.Results.carr;
            fn = ip.Results.output;
            
            c1 = {};
            for ci = 1:length(c)
                if (lexist(c{ci}, 'file'))
                    c1 = [c1 c{ci}]; %#ok<AGROW>
                end
            end
            mlbash(sprintf('fslmerge -t %s %s', fn, cell2str(c1, 'AsRows', true)));
            mlbash(sprintf('fslmaths %s -nan %s', fn, fn));
        end
        function fn   = standardMergedName(this, varargin)
            %% specifies standard name for given tracer for all available frames.  
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
                this.nipetData_.tracerOutputPetLocation, sprintf('%s.nii.gz', tr));
        end
        function fn   = standardFramedName(this, fr)
            %% specifies standard name for given tracer and frame.
            %  @param fr is numeric frame index | 
            %  @param fr is char for pattern matching.
            %  @return single filename.nii.gz for NIfTI.
            
            tr = upper(this.tracer);
            if (isnumeric(fr))
                fn = sprintf('%s_frame%i.nii.gz', tr, fr);
                return
            end
            if (ischar(fr))
                fn = sprintf('%s_frame%s.nii.gz', tr, fr);
                return
            end
            error('mlnipet:ValueError', 'NipetBuilder.standardFramedName');
        end
        function nn   = standardFramedNames(this, fr)
            %% specifies standard names for given tracer and frames.
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
            
            unsorted = {};
            idx = 1;
            while isempty(unsorted) && idx <= length(this.lmNamesAst)
                unsorted = glob(this.lmNamesAst{idx}); % filesystem-name sorted, not frame-number sorted
                idx = idx + 1;
            end
            if isempty(unsorted) % files were previously renamed
                nn = this.standardFramedNames('*'); 
                assert(~isempty(nn))
                return
            end
            
            mlbash('ls -alt > mlnipet.NipetBuilder.standardizeFilenames.log')            
            for f = 1:length(unsorted)
                r = struct([]);
                idx = 1;
                while isempty(r) && idx <= length(this.lmNamesRE{idx})
                    r = regexp(unsorted{f}, this.lmNamesRE{idx}, 'names');
                    idx = idx + 1;
                end
                if ~isempty(r)
                    movefile(unsorted{f}, this.standardFramedName(str2double(r.frame)));
                end
            end
            nn = this.standardFramedNames('*');
            assert(~isempty(nn))
        end 
        function        standardizeObsoleteFileNames(this)
            %% rename NiftyPET frames with obsolete lmNamesAst{1} to specification of lmNamesAst{2}.
            
            obsolete = glob(this.lmNamesAst{1}); 
            if isempty(obsolete) 
                return
            end          
            lmNamesRE1 = [ ...
                this.NIPET_PREFIX '_itr-(?<iterations>\d+)_t-(?<t0>\d+)-(?<t1>\d+)sec_' ...
                this.nipetData_.lmTag '_time(?<frame>\d+).nii.gz'];
            for ui = 1:length(obsolete)
                r = regexp(obsolete{ui}, lmNamesRE1, 'names');
                newfn = sprintf( ...
                    '%s_t-%s-%ssec_itr-%s_%s_time%s.nii.gz', ...
                    this.NIPET_PREFIX, r.t0, r.t1, r.iterations, this.nipetData_.lmTag, r.frame);
                movefile(obsolete{ui}, newfn, 'f');
            end
        end
		  
 		function this = NipetBuilder(varargin)
 			%% NIPETBUILDER
 			%  @param .
            
            ip = inputParser;
            addRequired(ip, 'nipetData', @(x) ~isempty(x));
            parse(ip, varargin{:});
            
            this.nipetData_ = ip.Results.nipetData;
            assert(ismethod(this.nipetData_, 'tracerOutputLocation'))
            output = this.nipetData_.tracerOutputLocation();
            if ~isfolder(output)
                throw(MException('mlnipet:RuntimeError', 'NipetBuilder.ctor could not find %s', output))
            end
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        nipetData_
    end
    
    methods (Access = private)
        function fn = ensureNiigz(~, fn)
            [~,~,x] = myfileparts(fn);
            if (isempty(x))
                fn = [fn '.nii.gz'];
            end            
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

