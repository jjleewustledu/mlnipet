classdef CommonSessionData < mlnipet.BidsSessionData
	%% COMMONSESSIONDATA are mostly invariant to studies

	%  $Revision$
 	%  was created 21-May-2019 17:53:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    	properties
            filetypeExt = '.4dfp.hdr'
        end
        
    	properties (Dependent)   
            atlVoxelSize
            builder
            indicesLogical
            studyCensus
            tauIndices % use to exclude late frames from builders of AC; e.g., taus := taus(tauIndices)
            tauMultiplier
        end

	methods

        %% GET, SET

        function g    = get.atlVoxelSize(this)
            g = this.studyData.atlVoxelSize;
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
        function g    = get.studyCensus(this)
            g = this.getStudyCensus;
        end
        function g    = get.tauIndices(this)
            g = this.tauIndices_;
        end 
        function g    = get.tauMultiplier(this)
            g = this.tauMultiplier_;
        end

        function g    = getStudyCensus(this) %#ok<MANU>
            g = [];
        end

        %% IMRData

        function obj  = adc(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_ADC', varargin{:});
        end
        function obj  = atlas(this, varargin)
            ip = inputParser;
            addParameter(ip, 'desc', 'TRIO_Y_NDC', @ischar);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'typ', 'mlfourd.ImagingContext2', @ischar);
            parse(ip, varargin{:});

            obj = imagingType(ip.Results.typ, ...
                fullfile(getenv('REFDIR'), ...
                         sprintf('%s%s%s', ip.Results.desc, ip.Results.tag, this.filetypeExt)));
        end
        function obj  = dwi(this, varargin)
            obj = this.mrObject('ep2d_diff_26D_lgfov_nopat_TRACEW', varargin{:});
        end
        function obj  = mpr(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = mprage(this, varargin)
            obj = this.T1(varargin{:});
        end
        function obj  = perf(this, varargin)
            obj = this.mrObject('ep2d_perf', varargin{:});
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
            if (~lexist(fqfn, 'file') && isdir(this.freesurferLocation))
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
        function obj  = CCIRRadMeasurements(this)
            obj = mldata.CCIRRadMeasurements.date2filename(this.datetime);
        end
        function loc  = tracerListmodeLocation(this, varargin)
            %% Siemens legacy
            ipr = this.iprLocation(varargin{:});
            loc = locationType(ipr.typ, ...
                fullfile(this.sessionPath, ...
                         sprintf('%s-%s', ipr.tracer,  this.convertedTag), ...
                         sprintf('%s-LM-00', ipr.tracer), ''));
        end
        function obj  = tracerResolvedFinalOnAtl(this, varargin)
            fqfn = fullfile(this.sessionPath, ...
                sprintf('%s_on_%s_%i%s', this.tracerResolvedFinal('typ', 'fp'), this.studyAtlas.fileprefix, this.atlVoxelSize, this.filetypeExt));
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

        %%

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

      	function this = CommonSessionData(varargin)
        	%% COMMONSESSIONDATA
        	%  @param tauIndices is numeric.
        	%  @param tauMultiplier is numeric (DEPRECATED).
  
        	this = this@mlnipet.BidsSessionData(varargin{:});
        	
                ip = inputParser;
                ip.KeepUnmatched = true;
                addParameter(ip, 'tauIndices', [], @isnumeric);
                addParameter(ip, 'tauMultiplier', 1, @(x) isnumeric(x) && x >= 1);
                parse(ip, varargin{:});
                    
                this.tauIndices_ = ip.Results.tauIndices;
                this.tauMultiplier_ = ip.Results.tauMultiplier;
    	end
 	end

    %% PROTECTED

    properties (Access = protected)
        builder_
        tauIndices_
        tauMultiplier_
    end

    methods (Access = protected)
        function g    = alternativeTaus(this)
            if (~this.attenuationCorrected)
                switch (upper(this.tracer))
                    case 'FDG'
                        g = [30,32,33,35,37,40,43,46,49,54,59,65,72,82,94,110,132,165,218,315,535,1354];
                        % length == 22, dur == 3600
                    case {'OC' 'CO' 'OO' 'HO'}
                        g = [10,11,11,12,13,14,15,16,18,20,22,25,29,34,41,52,70,187];
                        % length == 18, dur = 600
                    otherwise
                        error('mlnipet:IndexError', 'NAC:SessionData.alternativeTaus.this.tracer->%s', this.tracer);
                end
            else            
                switch (upper(this.tracer))
                    case 'FDG'
                        g = [10,10,10,11,11,11,11,11,12,12,12,12,13,13,13,13,14,14,14,15,15,15,16,16,17,17,18,18,19,19,20,21,21,22,23,24,25,26,27,28,30,31,33,35,37,39,42,45,49,53,58,64,71,80,92,107,128,159,208,295,485,1097];
                        % length ==62, dur == 3887
                    case 'HO'
                        g = [3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10,11,12,13,13,15,16,17,19,21,24,27,32,38,47,62,88];
                        % length == 60, dur == 684
                    case {'OC' 'CO' 'OO'}
                        g = [5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,9,9,9,10,11,11,12,13,14,15,16,18,20,22,25,29,34,41,52,69,103];
                        % length == 36, dur ==636
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
        function fqfn = ensureOrientation(this, fqfn, orient)
            assert(lstrcmp({'sagittal' 'transverse' 'coronal' ''}, orient)); 
            [pth,fp,ext] = myfileparts(fqfn);
            fqfp = fullfile(pth, fp);   
            orient0 = this.readOrientation(fqfp);
            fv = mlfourdfp.FourdfpVisitor;             

            if (isempty(orient))
                return
            end     
            if (strcmp(orient0, orient))
                return
            end       
            if (lexist([this.orientedFileprefix(fqfp, orient) ext]))
                fqfn = [this.orientedFileprefix(fqfp, orient) ext];
                return
            end

            pwd0 = pushd(pth);
            switch (orient0)
                case 'sagittal'
                    switch (orient)
                        case 'transverse'
                            fv.S2T_4dfp(fp, [fp 'T']);
                            fqfn = [fqfp 'T' ext];
                        case 'coronal'
                            fv.S2C_4dfp(fp, [fp 'C']);
                            fqfn = [fqfp 'C' ext];
                    end
                case 'transverse'
                    switch (orient)
                        case 'sagittal'
                            fv.T2S_4dfp(fp, [fp 'S']);
                            fqfn = [fqfp 'S' ext];
                        case 'coronal'
                            fv.T2C_4dfp(fp, [fp 'C']);
                            fqfn = [fqfp 'C' ext];
                    end
                case 'coronal'
                    switch (orient)
                        case 'sagittal'
                            fv.C2S_4dfp(fp, [fp 'S']);
                            fqfn = [fqfp 'S' ext];
                        case 'transverse'
                            fv.C2T_4dfp(fp, [fp 'T']);
                            fqfn = [fqfp 'T' ext];
                    end
            end
            popd(pwd0);
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
        function fqfp = orientedFileprefix(~, fqfp, orient)
            assert(mlfourdfp.FourdfpVisitor.lexist_4dfp(fqfp));
            switch (orient)
                case 'sagittal'
                    fqfp = [fqfp 'S'];
                case 'transverse'
                    fqfp = [fqfp 'T'];
                case 'coronal'
                    fqfp = [fqfp 'C'];
                otherwise
                    error('mlnipet:switchCaseNotSupported', ...
                          'SesssionData.orientedFileprefix.orient -> %s', orient);
            end
        end
        function o    = readOrientation(this, varargin)
            ip = inputParser;
            addRequired(ip, 'fqfp', @mlfourdfp.FourdfpVisitor.lexist_4dfp);
            parse(ip, varargin{:});

            [~,o] = mlbash(sprintf('awk ''/orientation/{print $NF}'' %s%s', ip.Results.fqfp, this.filetypeExt));
            switch (strtrim(o))
                case '2'
                    o = 'transverse';
                case '3'
                    o = 'coronal';
                case '4'
                    o = 'sagittal';
                otherwise
                    error('mlnipet:switchCaseNotSupported', ...
                          'SessionData.readOrientation.o -> %s', o);
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

