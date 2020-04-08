classdef SessionData < mlpipeline.ResolvingSessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 14-Jun-2019 17:09:40 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties (Dependent)        
        absScatterCorrected
        atlVoxelSize
        attenuationCorrected   
        builder
        indicesLogical     
        isotope
        itr
        scannerKit
        studyCensus
        tauIndices % use to exclude late frames from builders of AC; e.g., taus := taus(tauIndices)
        tauMultiplier
        tracer 		
 	end

	methods 
        
        %% GET, SET
        
        function g    = get.absScatterCorrected(this)
            if (this.useNiftyPet)
                g = false;
                return
            end
            if (strcmpi(this.tracer, 'OC') || strcmp(this.tracer, 'OO'))
                g = true;
                return
            end
            g = this.absScatterCorrected_;
        end
        function this = set.absScatterCorrected(this, s)
            assert(islogical(s));
            this.absScatterCorrected_ = s;
        end
        function g    = get.atlVoxelSize(this)
            g = this.studyData.atlVoxelSize;
        end
        function g    = get.attenuationCorrected(this)
            if (~isempty(this.attenuationCorrected_))
                g = this.attenuationCorrected_;
                return
            end
            g = mlpet.DirToolTracer.folder2ac(this.scanFolder);
        end
        function this = set.attenuationCorrected(this, s)
            assert(islogical(s));
            if (this.attenuationCorrected_ == s)
                return
            end
            this.scanFolder_ = this.scanFolderWithAC(s);
            this.attenuationCorrected_ = s;
        end
        function g    = get.builder(this)
            g = this.builder_;
        end
        function this = set.builder(this, s)
            assert(isa(s, 'mlpipeline.IBuilder'));
            this.builder_ = s;
        end
        function g    = get.indicesLogical(this) %#ok<MANU>
            g = true;
            return
        end
        function g    = get.isotope(this)
            tr = lower(this.tracer);
            
            % N.B. order of testing by lstrfind
            if (lstrfind(tr, {'ho' 'oo' 'oc' 'co'}))
                g = '15O';
                return
            end
            if (lstrfind(tr, 'fdg'))
                g = '18F';
                return
            end 
            if (lstrfind(tr, 'g'))
                g = '11C';
                return
            end            
            error('mlpipeline:indeterminatePropertyValue', ...
                'SessionData.isotope could not recognize tracer %s', this.sessionData.tracer);
        end
        function g    = get.itr(this)
            if strcmpi(this.tracer, 'OC') || ...
               strcmpi(this.tracer, 'CO') || ...
               strcmpi(this.tracer, 'OO')
                g = 2;
                return
            end
            g = 4;
        end
        function g    = get.scannerKit(this)
            g = this.scannerKit_;
        end
        function g    = get.studyCensus(this)
            g = this.getStudyCensus;
        end
        function g    = get.tauIndices(this)
            g = this.tauIndices_;
        end 
        function g    = get.tauMultiplier(this)
            g = this.tauMultiplier_;
        end
        function g    = get.tracer(this)
            if (~isempty(this.tracer_))
                g = this.tracer_;
                return
            end   
            % ask forgiveness not permission
            try
                g = mlpet.DirToolTracer.folder2tracer(this.scanFolder);
            catch ME
                handwarning(ME);
                g = '';
            end
        end
        function this = set.tracer(this, t)
            assert(ischar(t));
            if (~strcmpi(this.tracer_, t))
                this.scanFolder_ = '';
            end
            this.tracer_ = t;
        end        
        
        %% IMRData
        
        function obj  = mpr(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = mprage(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = mrObject(this, varargin)
            %  @override

            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'desc', @ischar);
            addParameter(ip, 'orientation', '', @(x) lstrcmp({'sagittal' 'transverse' 'coronal' ''}, x));
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});

            fqfn = fullfile(this.fourdfpLocation, ...
                            sprintf('%s%s%s', ip.Results.desc, ip.Results.tag, this.filetypeExt));
            fqfn = this.ensureOrientation(fqfn, ip.Results.orientation);
            obj  = imagingType(ip.Results.typ, fqfn);
        end
        function obj  = studyAtlas(this, varargin)
            ip = inputParser;
            addParameter(ip, 'desc', 'HYGLY_atlas', @ischar);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'mlfourd.ImagingContext2', @ischar);
            parse(ip, varargin{:});

            obj = imagingType(ip.Results.typ, ...
                fullfile(this.subjectsDir, 'atlasTest', 'source', ...
                         sprintf('%s%s%s', ip.Results.desc, ip.Results.tag, this.filetypeExt)));
        end
        function obj  = T1(this, varargin)
            obj = this.T1001(varargin{:});
        end
        function obj  = T1001(this, varargin)
            fqfn = fullfile(this.sessionPath, ['T1001' this.filetypeExt]);
            if (~lexist(fqfn, 'file') && isfolder(this.freesurferLocation))
                mic = T1001@mlpipeline.SessionData(this, 'typ', 'mlfourd.ImagingContext2');
                mic.nifti;
                mic.saveas(fqfn);
            end
            obj = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = T1001BinarizeBlended(this, varargin)
            fqfn = fullfile(this.tracerLocation, sprintf('T1001_%s_binarizeBlendedd%s', this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = t1(this, varargin)
            obj = this.T1(varargin{:});
        end
        
        %% IPETData
        
        function obj  = arterialSamplerCalCrv(this, varargin)
            [pth,fp] = this.arterialSamplerCrv(varargin{:});
            fqfn = fullfile(pth, [fp '_cal.crv']);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = arterialSamplerCrv(this, varargin)
            fqfn = fullfile( ...
                this.sessionLocation('typ', 'path'), ...
                sprintf('%s.crv', this.sessionFolder));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = cbf(this, varargin)
            this.tracer = 'HO';
            obj = this.petObject('cbf', varargin{:});
        end
        function obj  = cbv(this, varargin)
            this.tracer = 'OC';
            obj = this.petObject('cbv', varargin{:});
        end
        function obj  = CCIRRadMeasurements(this)
            obj = mlpet.CCIRRadMeasurements.date2filename(this.datetime);
        end
        function obj  = cmro2(this, varargin)
            this.tracer = 'OO';
            obj = this.petObject('cmro2', varargin{:});
        end
        function obj  = ct(this, varargin)
            obj = this.ctObject('ct', varargin{:});
        end
        function obj  = ctMasked(this, varargin)
            obj = this.ctObject('ctMasked', varargin{:});
        end
        function obj  = ctMask(this, varargin)
            obj = this.ctObject('ctMask', varargin{:});
        end        
        function obj  = ctObject(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'desc', @ischar);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            
            fqfn = fullfile(this.sessionLocation, ...
                            sprintf('%s%s%s', ip.Results.desc, ip.Results.tag, this.filetypeExt));
            obj = imagingType(ip.Results.typ, fqfn);
        end
        function dt   = datetime(this)
            dt = mlpet.DirToolTracer.folder2datetime(this.scanFolder);
        end
        function obj  = fdg(this, varargin)
            this.tracer = 'FDG';
            obj = this.petObject('fdg', varargin{:});
        end
        function obj  = gluc(this, varargin)
            obj = this.petObject('gluc', varargin{:});
        end 
        function loc  = hdrinfoLocation(this, varargin)
            loc = this.sessionLocation(varargin{:});
        end
        function obj  = ho(this, varargin)
            this.tracer = 'HO';
            obj = this.petObject('ho', varargin{:});
        end
        function obj  = oc(this, varargin)
            this.tracer = 'OC';
            obj = this.petObject('oc', varargin{:});
        end
        function obj  = oef(this, varargin)
            this.tracer = 'OO';
            obj = this.petObject('oef', varargin{:});
        end
        function obj  = oo(this, varargin)
            this.tracer = 'OO';
            obj = this.petObject('oo', varargin{:});
        end
        function loc  = petLocation(this, varargin)
            loc = this.tracerLocation(varargin{:});
        end
        function obj  = petObject(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'tracer', @ischar);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'fqfp', @ischar);
            parse(ip, varargin{:});
            suff = ip.Results.tag;
            if (~isempty(suff) && ~strcmp(suff(1),'_'))
                suff = ['_' suff];
            end
            fqfn = fullfile(this.petLocation, ...
                   sprintf('%sr%i%s%s', ip.Results.tracer, this.rnumber, suff, this.filetypeExt));
            obj = imagingType(ip.Results.typ, fqfn);
        end 
        function [dt0_,date_] = readDatetime0(~)
            dt0_ = NaT;
            date_ = NaT;
        end
        function f    = scanFolderWithAC(this, varargin)
            ip = inputParser;
            addOptional(ip, 'b', true, @islogical);            
            parse(ip, varargin{:});
            if (ip.Results.b)
                if (this.attenuationCorrected_)
                    f = this.scanFolder;
                    return
                end
                fsplit = strsplit(this.scanFolder, '-NAC');
                f = [fsplit{1} '-AC'];
            else
                if (~this.attenuationCorrected_)
                    f = this.scanFolder;
                    return
                end
                fsplit = strsplit(this.scanFolder, '-AC');
                f = [fsplit{1} '-NAC'];
            end
        end
        function f    = scanPathWithAC(this, varargin)
            f = fullfile(this.sessionPath, this.scanFolderWithAC(varargin{:}));
        end
        function obj  = tr(this, varargin)
            %% transmission scan
            
            obj = this.petObject('tr', varargin{:});
        end 
        function obj  = tracerListmodeBf(this, varargin)
            dt   = mlsystem.DirTool(fullfile(this.scanPath, 'LM', '*.bf'));
            assert(1 == length(dt.fqfns));
            fqfn = dt.fqfns{1};            
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerListmodeDcm(this, varargin)
            dt   = mlsystem.DirTool(fullfile(this.scanPath, 'LM', '*.dcm'));            
            if (isempty(dt.fqfns))
                error('mlnipet:FileNotFoundError', 'SessionData.tracerListmodeDcm found no listmode DICOM')
            end
            if (length(dt.fqfns) > 1)
                error('mlnipet:RuntimeError', 'SessionData.tracerListmodeDcm found multiple listmode DICOMs')
            end
            fqfn = dt.fqfns{1};            
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerListmodeLocation(this, varargin)
            %% Siemens legacy
            
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.sessionPath, ...
                         sprintf('%s-%s', ipr.tracer,  this.convertedTag), ...
                         sprintf('%s-LM-00', ipr.tracer), ''));
        end
        function loc  = tracerLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, this.scanPath);
        end
        function obj  = tracerNipet(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'nativeFov', false, @islogical);
            parse(ip, varargin{:});
            
            this.epoch = [];
            this.rnumber = 1;
            ipr = this.iprLocation(varargin{:});
            if (ip.Results.nativeFov)
                tr = upper(ipr.tracer);
            else
                tr = lower(ipr.tracer);
            end
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber), ...
                'output', 'PET', ...
                sprintf('%s.nii.gz', tr));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerOutputLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.scanPath, this.outfolder, ''));
        end
        function loc  = tracerOutputPetLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.scanPath, this.outfolder, 'PET', ''));
        end
        function loc  = tracerOutputSingleFrameLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.scanPath, this.outfolder, 'PET', 'single-frame', ''));
        end
        function obj  = tracerPristine(this, varargin)
            this.epoch = [];
            this.rnumber = 1;
            ipr = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%sr1%s', lower(ipr.tracer), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerScrubbed(this, varargin)
            fqfn = sprintf('%s_scrubbed%s', this.tracerResolved('typ', 'fqfp'), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end        
        function obj  = tracerSuvr(this, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_suvr_%i%s', this.tracerRevision('typ', 'fp'), this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerSuvrAveraged(this, varargin)   
            ipr = this.iprLocation(varargin{:});         
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%sa%sr%i_suvr_%i%s', ...
                lower(ipr.tracer), this.epochTag, ipr.rnumber, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerSuvrNamed(this, name, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%sr%i_suvr_%i%s', lower(name), this.rnumber, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerTimeWindowed(this, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_timeWindowed%s', this.tracerRevision('typ', 'fp'), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerTimeWindowedOnAtl(this, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_timeWindowed_%i%s', this.tracerRevision('typ', 'fp'), this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        
        %%
        
        function g    = getScanFolder(this)
            if (~isempty(this.scanFolder_))
                g = this.scanFolder_;
                return
            end
            if isempty(this.tracer_) || isempty(this.attenuationCorrected_)
                g = '';
                dt = datetime(datestr(now));
                for globbed = globFoldersT(fullfile(this.sessionPath, '*_DT*.000000-Converted-*'))
                    base = mybasename(globbed{1});
                    re = regexp(base, ...
                        '\S+_DT(?<yyyy>\d{4})(?<mm>\d{2})(?<dd>\d{2})(?<HH>\d{2})(?<MM>\d{2})(?<SS>\d{2})\.\d{6}-Converted\S*', ...
                        'names');
                    assert(~isempty(re))
                    dt1 = datetime(str2double(re.yyyy), str2double(re.mm), str2double(re.dd), ...
                        str2double(re.HH), str2double(re.MM), str2double(re.SS));
                    if dt1 < dt
                        dt = dt1; % find earliest scan
                        g = base;
                    end                    
                end                
                return
            end
            dtt = mlpet.DirToolTracer( ...
                'tracer', fullfile(this.sessionPath, this.tracer_), ...
                'ac', this.attenuationCorrected_);            
            assert(~isempty(dtt.dns));
            g = dtt.dns{1};
        end
        function g    = getStudyCensus(this) %#ok<MANU>
            g = [];
        end
        function [ipr,this] = iprLocation(this, varargin)
            %% IPRLOCATION
            %  @param named ac is the attenuation correction; is logical
            %  @param named tracer is a string identifier.
            %  @param named frame is a frame identifier; is numeric.
            %  @param named rnumber is the revision number; is numeric.
            %  @param named snumber is the scan number; is numeric.
            %  @param named typ is string identifier:  folder path, fn, fqfn, ...  
            %  See also:  imagingType.
            %  @returns ipr, the struct ip.Results obtained by parse.            
            %  @returns schr, the s-number as a string.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'ac',      this.attenuationCorrected, @islogical);
            addParameter(ip, 'tracer',  this.tracer, @ischar);
            addParameter(ip, 'frame',   this.frame, @isnumeric);
            addParameter(ip, 'rnumber', this.rnumber, @isnumeric);
            addParameter(ip, 'snumber', this.snumber, @isnumeric);
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});            
            ipr = ip.Results;
            this.attenuationCorrected_ = ip.Results.ac;
            this.tracer_  = ip.Results.tracer; 
            this.rnumber  = ip.Results.rnumber;
            this.snumber_ = ip.Results.snumber;
            this.frame_   = ip.Results.frame;
        end
        function f    = jsonFilename(this)
            glob_expr = '*_DT*.json';
            try
                glob_expr = fullfile(this.tracerOutputPetLocation, [upper(this.tracer) '_DT*.json']);
                dt = mlsystem.DirTool(glob_expr);
                assert(1 == dt.length, [evalc('disp(dt)') '\n' evalc('disp(dt.fqfns)')]);
                f = dt.fqfns{1};
            catch ME
                warning('mlpipeline:RuntimeWarning', 'SessionData.jsonFilename could not find %s', glob_expr);
                handwarning(ME);
                f = '';
            end
        end
        function this = setScanFolder(this, s)
            assert(ischar(s));
            this.scanFolder_ = s;
            this = this.adjustAttenuationCorrectedFromScanFolder;
        end
		  
 		function this = SessionData(varargin)
 			%% SESSIONDATA
 			%  @param [param-name, param-value[, ...]]
            %
            %         'abs'          is logical
            %         'ac'           is logical
            %         'tracer'       is char

 			this = this@mlpipeline.ResolvingSessionData(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'abs', false, @islogical);
            addParameter(ip, 'ac', false, @islogical);
            addParameter(ip, 'scannerKit', 'mlsiemens.BiographMMRKit', @ischar)
            addParameter(ip, 'tracer', '', @ischar);
            parse(ip, varargin{:}); 
            ipr = ip.Results;

            this.absScatterCorrected_ = ipr.abs;
            this.attenuationCorrected_ = ipr.ac;
            this.scannerKit_ = ipr.scannerKit;
            this.tracer_ = ipr.tracer;
            this = this.adjustAttenuationCorrectedFromScanFolder;
            
            %% taus
            
            if (~isempty(this.scanFolder_) && lexist(this.jsonFilename, 'file'))
                j = jsondecode(fileread(this.jsonFilename));
                this.taus_ = j.taus';
            end
 		end
    end
    
    %% PROTECTED  
    
    properties (Access = protected)
        absScatterCorrected_
        attenuationCorrected_
        scannerKit_
        tracer_
    end
    
    methods (Access = protected)
        function this = adjustAttenuationCorrectedFromScanFolder(this)
            if (contains(this.scanFolder, '-NAC'))
                this.attenuationCorrected_ = false;
                return
            end
            if (contains(this.scanFolder, '-AC'))
                this.attenuationCorrected_ = true;
                return
            end
        end        
        function g    = alternativeTaus(this)
            %% see also t0_and_dt()
            
            if (~this.attenuationCorrected)
                switch (upper(this.tracer))
                    case 'FDG'
                        g = [30,35,39,43,47,51,55,59,64,68,72,76,81,85,89,93,98,102,106,111,115,120,124,129,133,138,142,147,151,156,161,165,170,175,171];
                        % length == 35, nudge = 4, dur == 3601
                    case {'OC' 'CO' 'OO' 'HO'}
                        g = [12,13,14,15,17,18,20,23,26,30,35,43,55,75,114,91];
                        % length == 16, dur = 601
                    otherwise
                        error('mlnipet:IndexError', 'NAC:SessionData.alternativeTaus.this.tracer->%s', this.tracer);
                end
            else            
                switch (upper(this.tracer))
                    case 'FDG'
                        g = [10,13,14,16,17,19,20,22,23,25,26,28,29,31,32,34,35,37,38,40,41,43,44,46,47,49,50,52,53,56,57,59,60,62,63,65,66,68,69,71,72,74,76,78,79,81,82,84,85,87,88,91,92,94,95,97,98,100,101,104,105,108];
                        % length == 62, nudge = 1.5, dur == 3601
                    case 'HO'
                        g = [3,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,11,12,13,14,15,16,18,20,22,25,29,34,41,51,52];
                        % length == 54, dur == 601
                    case {'OC' 'CO'}
                        g = [3,3,3,3,3,3,3,3,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,11,12,13,14,15,16,18,19,22,24,28,33,39,49,64,49];
                        % length == 45, dur == 601
                    case 'OO'
                        g = [2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,15];
                        % length == 63, dur == 301
                    otherwise
                        error('mlnipet:IndexError', 'AC:SessionData.alternativeTaus.this.tracer->%s', this.tracer);
                end
            end
            if (~isempty(this.tauIndices))
                g = g(this.tauIndices);
            end
            if (this.tauMultiplier > 1)
                g = this.multiplyTau(g);
            end
        end
        function tau1 = multiplyTau(this, tau)
            %% MULTIPLYTAU increases tau durations by scalar this.tauMultiplier, decreasing the sampling rate,
            %  decreasing the number of frames for dynamic data and
            %  potentially increasing SNR.

            N1   = ceil(length(tau)/this.tauMultiplier);
            tau1 = zeros(1, N1);

            ti = 1;
            a  = 1;
            b  = this.tauMultiplier;
            while (ti <= N1)                
                tau1(ti) = sum(tau(a:b));                
                ti = ti + 1;
                a  = min(a  + this.tauMultiplier, length(tau));
                b  = min(b  + this.tauMultiplier, length(tau));
                if (a > length(tau) || b > length(tau)); break; end
            end
        end
        function obj  = visitMapOnAtl(this, map, varargin)
            fqfn = fullfile(this.vLocation, ...
                sprintf('%s_on_%s_%i%s', map, this.studyAtlas.fileprefix, this.atlVoxelSize, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

