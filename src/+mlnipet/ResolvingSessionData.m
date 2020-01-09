classdef (Abstract) ResolvingSessionData < mlnipet.SessionData
	%% RESOLVINGSESSIONDATA  

	%  $Revision$
 	%  was created 18-Aug-2017 16:40:39 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpipeline/src/+mlpipeline.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
    
	properties
        tracerBlurArg = 7.5
        umapBlurArg = 1.5
    end
       
    properties (Dependent)
        attenuationTag
        compositeT4ResolveBuilderBlurArg
        convertedTag
        doseAdminDatetimeTag
        fractionalImageFrameThresh % of median dynamic image-frame intensities
        lmTag
        referenceTracer        
        ReferenceTracer
        t4ResolveBuilderBlurArg
        useNiftyPet
    end
    
	methods 
        
        %% GET/SET
        
        function g    = get.attenuationTag(this)
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
        function g    = get.compositeT4ResolveBuilderBlurArg(this)
            if (~this.attenuationCorrected)
                g = this.umapBlurArg;
            else
                g = this.tracerBlurArg;
            end
        end
        function g    = get.convertedTag(this)
            if (~isnan(this.frame_))
                g = sprintf('Converted-Frame%i-%s', this.frame_, this.attenuationTag);
                return
            end
            g = ['Converted-' this.attenuationTag];
        end
        function g    = get.doseAdminDatetimeTag(this)
            re = regexp(this.scanFolder, '\w+_(?<dttag>DT\d+).\d+\w*', 'names');
            g = re.dttag;
            if (isempty(g))
                g = '';
            end
        end
        function g    = get.fractionalImageFrameThresh(this)
            if (this.attenuationCorrected)
                g = this.fractionalImageFrameThresh_;
            else
                g = 5*this.fractionalImageFrameThresh_;
            end
        end
        function this = set.fractionalImageFrameThresh(this, s)
            assert(isnumeric(s));
            assert(s < 1);
            this.fractionalImageFrameThresh_ = s;
        end
        function g    = get.lmTag(this)
            if (~this.attenuationCorrected)
                g = 'createDynamicNAC';
                return
            end
            g = 'createDynamic2Carney';
        end 
        function g    = get.referenceTracer(this)
            g = lower(this.referenceTracer_);
        end
        function this = set.referenceTracer(this, s)
            this.referenceTracer_ = lower(s);
        end
        function g    = get.ReferenceTracer(this)
            g = upper(this.referenceTracer_);
        end
        function this = set.ReferenceTracer(this, s)
            this.referenceTracer_ = lower(s);
        end
        function g    = get.t4ResolveBuilderBlurArg(this)
            g = this.tracerBlurArg;
        end   
        function g    = get.useNiftyPet(~)
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
                dt0_.TimeZone = mlpipeline.ResourcesRegistry.instance().preferredTimeZone;
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
            loc = locationType(ipr.typ, this.scanPath);
        end
        function loc  = tracerLocation(this, varargin)
            ipr = this.iprLocation(varargin{:});
            if (isempty(ipr.tracer))
                loc = locationType(ipr.typ, this.sessionPath);
                return
            end
            loc = locationType(ipr.typ, ...
                  fullfile(this.scanPath, capitalize(this.epochTag), ''));
        end
        function obj  = tracerEpoch(this, varargin)
            %% TRACEREPOCH is tracerRevision without the rnumber label.
            
            ipr = this.iprLocation(varargin{:});
            fqfn = fullfile( ...
                this.tracerLocation('tracer', ipr.tracer, 'snumber', ipr.snumber, 'typ', 'path'), ...
                sprintf('%s%s%s', lower(ipr.tracer), this.epochTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end        
        function obj  = tracerResolved(this, varargin)
            that = this;
            that.rnumber = max(1, this.rnumber - 1);
            fqfn = fullfile( ...
                this.tracerLocation, ...
                sprintf('%s_%s%s', ...
                        this.tracerRevision('typ', 'fp'), ...
                        that.resolveTag, ...
                        this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end  
        function obj  = tracerResolvedAvgt(this, varargin)
            fqfn = sprintf('%s_avgt%s', this.tracerResolved('typ', 'fqfp', varargin{:}), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end  
        function obj  = tracerResolvedSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerResolved('typ', 'fqfp', varargin{:}), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end  
        function obj  = tracerResolvedFinal(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'resolvedEpoch', this.theResolvedEpoch, @isnumeric)
            addParameter(ip, 'resolvedFrame', this.theResolvedFrame, @isnumeric)
            parse(ip, varargin{:});
            ipr = ip.Results;
             
            this.epoch = ipr.resolvedEpoch;
            that = this;
            that.rnumber = max(1, this.rnumber - 1);          
            fqfn = fullfile( ...
                this.tracerLocation, ...
                sprintf('%s_%s%s', ...
                           this.tracerRevision('typ', 'fp'), ...
                           that.resolveTagFrame(ipr.resolvedFrame), ...
                           this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalAvgt(this, varargin)
            fqfn = sprintf('%s_avgt%s', this.tracerResolvedFinal('typ', 'fqfp', varargin{:}), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerResolvedFinalSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerResolvedFinal('typ', 'fqfp', varargin{:}), this.filetypeExt);
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
        function obj  = tracerRevisionAvgt(this, varargin)
            fqfn = sprintf('%s_avgt%s', this.tracerRevision('typ', 'fqfp', varargin{:}), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end     
        function obj  = tracerRevisionSumt(this, varargin)
            fqfn = sprintf('%s_sumt%s', this.tracerRevision('typ', 'fqfp', varargin{:}), this.filetypeExt);
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end  
        function obj  = umapPhantom(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionFolder', 'CAL_PHANTOM2', @ischar);
            parse(ip, varargin{:});

            fqfn = fullfile( ...
                this.subjectsDir, upper(ip.Results.sessionFolder), ...
                sprintf('umapSynth_b40%s', this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = umapSynth(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'tracer', this.tracer, @ischar);
            addParameter(ip, 'blurTag', mlnipet.ResourcesRegistry.instance().suffixPetPointSpread, @ischar);
            parse(ip, varargin{:});
            tr = ip.Results.tracer;
            
            if (isempty(tr))
                fqfn = fullfile( ...
                    this.sessionPath, ...
                    sprintf('umapSynth_op_%s%s%s', ...
                            this.T1001('typ', 'fp'), ip.Results.blurTag, this.filetypeExt));
            else
                fqfn = fullfile( ...
                    this.scanPath, ...
                    sprintf('umapSynth_op_%s%s', ...
                            this.tracerRevision('typ', 'fp'), this.filetypeExt));
            end
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end    
        function obj  = umapSynthOpT1001(this, varargin)
            %  @returns umapSynth_op_T1001_b43 as fqfilenameObject with default blurTag->'_b43'
            
            obj  = this.umapSynth('tracer', '', varargin{:});
        end  
        function obj  = umapSynthOpTracer(this, varargin)
            obj  = this.umapSynth('tracer', this.tracer, varargin{:});
        end         
        function obj  = umapTagged(this, varargin)
            %% legacy support

            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});

            if (isempty(ip.Results.tag))
                fn = 'umapSynth';
            else 
                fn = sprintf('umapSynth_%s%s', ip.Results.tag, this.filetypeExt);
            end
            fqfn = fullfile(this.tracerRevision('typ','filepath'), fn);
            obj  = this.fqfilenameObject(fqfn, varargin{2:end});
        end
        
 		function this = ResolvingSessionData(varargin)
            %  @param fractionalImageFrameThresh \in [0, 1].
            
 			this = this@mlnipet.SessionData(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;           
            addParameter(ip, 'fractionalImageFrameThresh', 0.02, @isnumeric);
            parse(ip, varargin{:});             
            this.fractionalImageFrameThresh_ = ip.Results.fractionalImageFrameThresh;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        fractionalImageFrameThresh_
        referenceTracer_
    end
    
    methods (Access = protected)
        function ep = theResolvedEpoch(this)
            if this.attenuationCorrected
                ep = [];
            else
                ep = 1:this.supEpoch;
            end
        end
        function fr = theResolvedFrame(this)
            if this.attenuationCorrected
                fr = length(this.taus);
            else
                fr = this.supEpoch;
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

