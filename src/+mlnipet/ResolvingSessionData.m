classdef (Abstract) ResolvingSessionData < mlpipeline.SessionData & mlnipet.ISessionData
	%% RESOLVINGSESSIONDATA  

	%  $Revision$
 	%  was created 18-Aug-2017 16:40:39 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpipeline/src/+mlpipeline.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	    
	properties
        compAlignMethod = 'align_multiSpectral'
        epoch
        fractionalImageFrameThresh = 0.01 % of median
        frameAlignMethod = 'align_2051'
        %indexOfReference % INCIPIENT BUG
        itr = 4
        outfolder = 'output'
        tracerBlurArg = 7.5
        umapBlurArg = 1.5
    end
       
    properties (Dependent)
        attenuationTag
        compositeT4ResolveBuilderBlurArg
        convertedTag
        dbgTag
        epochTag
        frameTag    
        lmTag
        maxLengthEpoch
        regionTag
        resolveTag
        rnumber
        supEpoch
        t4ResolveBuilderBlurArg
        taus
        times
        useNiftyPet
    end
    
	methods 
        
        %% GET/SET
        
        function g = get.attenuationTag(this)
            if (this.attenuationCorrected)
                if (this.absScatterCorrected)
                    g = 'Abs';
                    return
                end
                g = 'AC';
                return
            end
            g = 'NAC';
        end
        function g = get.compositeT4ResolveBuilderBlurArg(this)
            if (~this.attenuationCorrected)
                g = this.umapBlurArg;
            else
                g = this.tracerBlurArg;
            end
        end
        function g = get.convertedTag(this)
            if (~isnan(this.frame_))
                g = sprintf('Converted-Frame%i-%s', this.frame_, this.attenuationTag);
                return
            end
            g = ['Converted-' this.attenuationTag];
        end
        function g = get.dbgTag(~)
            if (~isempty(getenv('DEBUG')))
                g = '_DEBUG';
            else
                g = '';
            end
        end
        function g    = get.epochTag(this)
            if (isempty(this.epoch))
                g = '';
                return
            end
            assert(isnumeric(this.epoch));
            if (1 == length(this.epoch))
                g = sprintf('e%i', this.epoch);
            else
                g = sprintf('e%ito%i', this.epoch(1), this.epoch(end));
            end
        end     
        function g = get.frameTag(this)
            assert(isnumeric(this.frame));
            if (isnan(this.frame))
                g = '';
                return
            end
            g = sprintf('_frame%i', this.frame);
        end   
        function g = get.lmTag(this)
            if (~this.attenuationCorrected)
                g = 'createDynamicNAC';
                return
            end
            g = 'createDynamic2Carney';
        end
        function g = get.maxLengthEpoch(this)
            if (~this.attenuationCorrected)
                g = 8;
                return
            end 
            g = 24;
        end
        function g = get.regionTag(this)
            if (isempty(this.region))
                g = '';
                return
            end
            if (isnumeric(this.region))                
                g = sprintf('_%i', this.region);
                return
            end
            if (ischar(this.region))
                g = sprintf('_%s', this.region);
                return
            end
            error('mlnipet:TypeError', ...
                'SessionData.get.regionTag');
        end
        function g    = get.resolveTag(this)
            if (~isempty(this.resolveTag_))
                g = this.resolveTag_;
                return
            end
            g = ['op_' this.tracerRevision('typ','fp')];
        end
        function this = set.resolveTag(this, s)
            assert(ischar(s));
            this.resolveTag_ = s;
        end  
        function g    = get.rnumber(this)
            g = this.rnumber_;
        end
        function this = set.rnumber(this, r)
            assert(isnumeric(r));
            this.rnumber_ = r;
        end  
        function g = get.supEpoch(this)
            if (~isempty(this.supEpoch_))
                g = this.supEpoch_;
                return
            end
            g = ceil(length(this.taus) / this.maxLengthEpoch);
        end
        function this = set.supEpoch(this, s) 
            assert(isnumeric(s));
            this.supEpoch_ = s;
        end  
        function g = get.t4ResolveBuilderBlurArg(this)
            g = this.tracerBlurArg;
        end
        function g = get.taus(this)
            if (lexist(this.listmodeJson, 'file'))
                j = jsondecode(fileread(this.listmodeJson));
                g = j.taus';
                return
            end
            g = this.alternativeTaus;
        end
        function g = get.times(this)
            t = this.taus;
            g = zeros(size(t));
            for ig = 1:length(t)-1
                g(ig+1) = sum(t(1:ig));
            end
        end   
        function g = get.useNiftyPet(~)
            g = true;
        end 
        
        %%		   
        
        function obj  = aparcA2009sAsegBinarized(this, varargin)
            fqfn = fullfile(this.tracerLocation, sprintf('aparcA2009sAseg_%s_binarized%s', this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = aparcAsegBinarized(this, varargin)
            fqfn = fullfile(this.tracerLocation, sprintf('aparcAseg_%s_binarized%s', this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = brainmaskBinarized(this, varargin)
            fqfn = fullfile(this.tracerLocation, sprintf('brainmask_%s_binarized%s', this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = brainmaskBinarizeBlended(this, varargin)
            fn   = sprintf('brainmask_%s_binarizeBlended%s', this.resolveTag, this.filetypeExt);
            fqfn = fullfile(this.sessionPath, fn);
            if (~lexist(fqfn, 'file'))
                fqfn = fullfile(this.tracerLocation, fn);
            end
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = ctRescaled(this, varargin)
            fqfn = fullfile( ...
                this.sessionLocation('typ', 'path'), ...
                sprintf('ctRescaled%s', this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function f    = listmodeJson(this)
            dt = mlsystem.DirTool(fullfile(this.tracerOutputPetLocation, [upper(this.tracer) 'dt*.json']));
            assert(1 == dt.length);
            f = dt.fqfns{1};
        end
        function p    = petPointSpread(~, varargin)
            inst = mlsiemens.MMRRegistry.instance;
            p    = inst.petPointSpread(varargin{:});
        end
        function suff = petPointSpreadSuffix(this, varargin)
            suff = sprintf('_b%i', floor(10*mean(this.petPointSpread(varargin{:}))));
        end
        function [dt0_,date_] = readDatetime0(this)
            %% reads study date, study time from this.tracerListmodeDcm
            
            try
                frame0 = this.frame;
                this.frame = nan;
                dcm = this.tracerListmodeDcm;
                this.frame = frame0;
                lp = mlio.LogParser.load(dcm);
                [dateStr,idx] = lp.findNextCell('%study date (yyyy:mm:dd):=', 1);
                 timeStr      = lp.findNextCell('%study time (hh:mm:ss GMT+00:00):=', idx);
                dateNames     = regexp(dateStr, '%study date \(yyyy\:mm\:dd\)\:=(?<Y>\d\d\d\d)\:(?<M>\d+)\:(?<D>\d+)', 'names');
                timeNames     = regexp(timeStr, '%study time \(hh\:mm\:ss GMT\+00\:00\)\:=(?<H>\d+)\:(?<MI>\d+)\:(?<S>\d+)', 'names');
                Y  = str2double(dateNames.Y);
                M  = str2double(dateNames.M);
                D  = str2double(dateNames.D);
                H  = str2double(timeNames.H);
                MI = str2double(timeNames.MI);
                S  = str2double(timeNames.S);

                dt0_ = datetime(Y,M,D,H,MI,S,'TimeZone','Etc/GMT');
                dt0_.TimeZone = mlnipet.Resources.PREFERRED_TIMEZONE;
                date_ = datetime(Y,M,D);
            catch ME 
                dispwarning(ME, 'mlraichle:RuntimeWarning', ...
                    'SessionData.readDatetime0');
                [dt0_,date_] = readDatetime0@mlpipeline.SessionData(this);
            end
        end
        function tag  = resolveTagFrame(this, varargin)
            ip = inputParser;
            addRequired( ip, 'f', @isnumeric);
            addParameter(ip, 'reset', true, @islogical);
            parse(ip, varargin{:});
            
            if (ip.Results.reset)
                this.resolveTag = '';
            end
            tag = sprintf('%s_frame%i', this.resolveTag, ip.Results.f);
        end       
        function loc  = tracerConvertedLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, this.tracerPath);
        end
        function obj  = tracerListmodeDcm(this, varargin)
            dt   = mlsystem.DirTool(fullfile(this.tracerConvertedLocation, 'LM', '*.dcm'));
            assert(1 == length(dt.fqfns));
            fqfn = dt.fqfns{1};            
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.sessionPath);
                return
            end
            loc = locationType(ipr.typ, ...
                  fullfile(this.tracerPath, capitalize(this.epochTag), ''));
        end
        function obj  = tracerEpoch(this, varargin)
            %% TRACEREPOCH is tracerRevision without the rnumber label.
            
            ipr = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s%s', lower(ipr.tracer), this.epochTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
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
                this.tracerConvertedLocation('tracer', ipr.tracer, 'snumber', ipr.snumber), ...
                'output', 'PET', ...
                sprintf('%s.nii.gz', tr));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function loc  = tracerOutputLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.tracerConvertedLocation(varargin{:}), this.outfolder, ''));
        end
        function loc  = tracerOutputPetLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.tracerConvertedLocation(varargin{:}), this.outfolder, 'PET', ''));
        end
        function loc  = tracerOutputSingleFrameLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.tracerOutputPetLocation(varargin{:}), 'single-frame', ''));
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
        function obj  = tracerResolved(this, varargin)
            fqfn = fullfile( ...
                this.tracerPath, ...
                sprintf('%s_%s%s', this.tracerRevision('typ', 'fp'), this.resolveTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end  
        function obj  = tracerResolvedFinal(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'resolvedEpoch', 1:this.supEpoch, @isnumeric); 
            addParameter(ip, 'resolvedFrame', this.supEpoch, @isnumeric); 
            parse(ip, varargin{:});
            
            sessd1 = this;
            sessd1.rnumber = 1;
            if (~this.attenuationCorrected)
                this.epoch = ip.Results.resolvedEpoch;
            end
            sessd1.epoch = ip.Results.resolvedEpoch;
            fqfn = sprintf('%s_%s%s', ...
                this.tracerRevision('typ', 'fqfp'), ...
                sessd1.resolveTagFrame(ip.Results.resolvedFrame), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerResolvedFinal('typ', 'fqfp'), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedSumt(this, varargin)
            fqfn = sprintf('%s_%s_sumt%s', this.tracerRevision('typ', 'fqfp'), this.resolveTag, this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end  
        function obj  = tracerRevision(this, varargin)
            %  @param named rLabel is char and overrides any specifications of r-number;
            %  it may be useful for generating filenames such as '*r1r2_to_resolveTag_t4'.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'rLabel', sprintf('r%i', this.rnumber), @ischar);
            parse(ip, varargin{:});
            
            ipr = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s%s%s%s', ...
                        lower(ipr.tracer), this.epochTag, ip.Results.rLabel, this.regionTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerRevisionSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerRevision('typ', 'fqfp'), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end           
        function obj  = umapSynth(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracer', this.tracer, @ischar);
            addParameter(ip, 'blurTag', mlpet.Resources.instance.suffixBlurPointSpread, @ischar);
            parse(ip, varargin{:});
            tr = ip.Results.tracer;
            
            if (isempty(tr))
                fqfn = fullfile(this.sessionLocation('typ', 'path'), ...
                                ['umapSynth_op_T1001' ip.Results.blurTag this.filetypeExt]);
                obj  = this.fqfilenameObject(fqfn, varargin{:});
                return
            end
            fqfn = fullfile( ...
                this.tracerLocation('typ', 'path'), ...
                sprintf('umapSynth_op_%s%s', ...
                    this.tracerRevision('typ', 'fp'), this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end    
        function obj  = umapSynthOpT1001(this, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('umapSynth_op_%s%s.4dfp.hdr', ...
                        this.T1001('typ', 'fp'), mlpet.Resources.instance.suffixBlurPointSpread));
            obj  = this.fqfilenameObject(fqfn, varargin{2:end});
        end 
        
 		function this = ResolvingSessionData(varargin)
            % @param 'resolveTag' is char
            % @param 'rnumber'    is numeric
            
 			this = this@mlpipeline.SessionData(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;           
            addParameter(ip, 'resolveTag', '', @ischar);
            addParameter(ip, 'rnumber', 1,     @isnumeric);
            parse(ip, varargin{:});             
            this.resolveTag_ = ip.Results.resolveTag;
            this.rnumber_    = ip.Results.rnumber;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        resolveTag_
        rnumber_
        supEpoch_
    end
    
    methods (Access = protected)
        function t = alternativeTaus(this) %#ok<STOUT,MANU>
            error('mlnipet:NotImplementedError', 'ResolvingSessionData.alternativeTaus');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

