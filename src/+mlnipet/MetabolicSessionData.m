classdef (Abstract) MetabolicSessionData < mlnipet.ResolvingSessionData
	%% METABOLICSESSIONDATA  

	%  $Revision$
 	%  was created 25-Feb-2021 14:56:50 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.9.0.1592791 (R2020b) Update 5 for MACI64.  Copyright 2021 John Joowon Lee.

    properties (Abstract)
        registry
        tracers
    end
    
	methods 
        function obj  = aifsOnAtlas(this, varargin)
            tr = lower(this.tracer);
            obj = this.metricOnAtlas(['aif_' tr], varargin{:});
        end
        function obj  = brainOnAtlas(this, varargin)
            obj = this.metricOnAtlas('brain', 'datetime', '',varargin{:});
        end
        function obj  = metricOnAtlas(this, metric, varargin)
            %% METRICONATLAS appends fileprefixes with information from this.dataAugmentation
            %  @param required metric is char.
            %  @param datetime is datetime or char, .e.g., '20200101000000' | ''.
            %  @param dateonlhy is logical.
            %  @param tags is char, e.g., 'b43_wmparc1_b43', default ''.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'metric', @ischar)
            addParameter(ip, 'datetime', this.datetime, @(x) isdatetime(x) || ischar(x))
            addParameter(ip, 'dateonly', false, @islogical)
            addParameter(ip, 'tags', '', @istext)
            parse(ip, metric, varargin{:})
            ipr = ip.Results;
            
            if ~isempty(ipr.tags)
                ipr.tags = strcat("_", strip(ipr.tags, "_"));
            end
            if ischar(ipr.datetime)
                adatestr = ipr.datetime;
            end
            if isdatetime(ipr.datetime)
                if ipr.dateonly
                    adatestr = ['dt' datestr(ipr.datetime, 'yyyymmdd') '000000'];
                else
                    adatestr = ['dt' datestr(ipr.datetime, 'yyyymmddHHMMSS')];
                end
            end
            
            fqfn = fullfile( ...
                this.dataPath, ...
                sprintf('%s%s_%s%s%s', ...
                        lower(ipr.metric), ...
                        adatestr, ...
                        this.registry.atlasTag, ...
                        ipr.tags, ...
                        this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = mprForReconall(this, varargin)
            obj = this.fqfilenameObject( ...
                fullfile(this.sessionPath, ['mpr' this.filetypeExt]), varargin{:});            
        end        
        function obj  = parcOnAtlas(this, varargin)
            fqfn = fullfile( ...
                this.dataPath, ...
                sprintf('%s_%s%s', this.parcellation, this.registry.atlasTag, this.filetypeExt));
            obj  = this.fqfilenameObject(fqfn, varargin{:});
        end
        function obj  = tracerOnAtlas(this, varargin)
            obj = this.metricOnAtlas(this.tracer, varargin{:});
        end
        function obj  = venousOnAtlas(this, varargin)
            obj = this.metricOnAtlas('venous', 'datetime', '',varargin{:});
        end
        function obj  = wbrain1OnAtlas(this, varargin)
            
            % prepare as needed
            wm_fqfn = this.wmparc1OnAtlas('typ', 'fqfilename');
            assert(isfile(wm_fqfn))
            wb_fqfn = strrep(wm_fqfn, 'wmparc1', 'wbrain1');
            if ~isfile(wb_fqfn)
                ic = mlfourd.ImagingContext2(wm_fqfn);
                ic = ic.binarized();
                ic.fileprefix = strrep(ic.fileprefix, 'wmparc1', 'wbrain1');
                ic.save()
            end
            
            obj = this.metricOnAtlas('wbrain1', 'datetime', '',varargin{:});
        end
        function obj  = wmparcOnAtlas(this, varargin)
            obj = this.metricOnAtlas('wmparc', 'datetime', '',varargin{:});
        end
        function obj  = wmparc1OnAtlas(this, varargin)
            obj = this.metricOnAtlas('wmparc1', 'datetime', '',varargin{:});
        end
        
        %% Metabolism
        
        function obj  = agiOnAtlas(this, varargin)
            % dag := cmrglc - cmro2/6 \approx aerobic glycolysis
            
            obj = this.metricOnAtlas('agi', varargin{:});
        end        
        function obj  = cbfOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbf', varargin{:});
        end
        function obj  = cbvOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cbv', varargin{:});
        end
        function obj  = chiOnAtlas(this, varargin)
            obj = this.metricOnAtlas('chi', varargin{:});
        end
        function obj  = cmrglcOnAtlas(this, varargin)
            obj = this.metricOnAtlas('cmrglc', varargin{:});
        end
        function obj  = cmro2OnAtlas(this, varargin)
            obj = this.metricOnAtlas('cmro', varargin{:});
        end
        function obj  = coOnAtlas(this, varargin)
            obj = this.metricOnAtlas('co', varargin{:});
        end
        function obj  = fdgOnAtlas(this, varargin)
            obj = this.metricOnAtlas('fdg', varargin{:});
        end
        function obj  = fsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('fs', varargin{:});
        end
        function obj  = gsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('gs', varargin{:});
        end
        function obj  = hoOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ho', varargin{:});
        end
        function obj  = KsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('Ks', varargin{:});
        end
        function obj  = ksOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ks', varargin{:});
        end
        function obj  = maskOnAtlas(this, varargin)
            obj = this.metricOnAtlas('mask', varargin{:});
        end
        function obj  = ocOnAtlas(this, varargin)
            obj = this.metricOnAtlas('oc', varargin{:});
        end
        function obj  = ooOnAtlas(this, varargin)
            obj = this.metricOnAtlas('oo', varargin{:});
        end
        function obj  = osOnAtlas(this, varargin)
            obj = this.metricOnAtlas('os', varargin{:});
        end
        function obj  = oefOnAtlas(this, varargin)
            obj = this.metricOnAtlas('oef', varargin{:});
        end
        function obj  = ogiOnAtlas(this, varargin)
            obj = this.metricOnAtlas('ogi', varargin{:});
        end
        function obj  = v1OnAtlas(this, varargin)
            obj = this.metricOnAtlas('v1', varargin{:});
        end
        function obj  = vsOnAtlas(this, varargin)
            obj = this.metricOnAtlas('vs', varargin{:});
        end
        
        %%
		  
 		function this = MetabolicSessionData(varargin)
 			this = this@mlnipet.ResolvingSessionData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

