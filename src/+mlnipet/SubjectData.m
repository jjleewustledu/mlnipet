classdef SubjectData < mlpipeline.SubjectData
	%% SUBJECTDATA performs aufbau of 
    %  subjectsDir/sub-S00000/ses-E000000 |
    %                                     |----- aparc*
    %                                     |----- brainmask*
    %                                     |----- T1001*
    %                                     |----- wmparc*
    %                                     |----- FDG_DT<%Y%M%D%h%m%s.000000>-Converted-AC
    %                                     |----- OC_DT<%Y%M%D%h%m%s.000000>-Converted-AC
    %                                     |----- OO_DT<%Y%M%D%h%m%s.000000>-Converted-AC
    %                                     |----- HO_DT<%Y%M%D%h%m%s.000000>-Converted-AC |
    %                                                                                    |----- ho.4dfp.*
    %                                                                                    |----- ho_avgt.4dfp.*
    %                                                                                    |----- T1001.4dfp.* (on ho_avgt)  

	%  $Revision$
 	%  was created 05-May-2019 22:07:18 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        SURFER_OBJECTS = {'aparcA2009sAseg' 'aparcAseg' 'brain' 'brainmask' 'wmparc' 'T1001'}
    end
    
	properties (Dependent)
 		subjectsJson % see also aufbauSubjectsDir, subclass ctors
    end
    
    methods (Abstract)
        createProjectData(session_string)
    end

	methods 
        
        %% GET
        
        function g = get.subjectsJson(this)
            g = this.subjectsJson_;
        end
        
        %%
        
        function        aufbauSubjectsDir(this)
            %% e. g., /subjectsDir/{sub-S123456, sub-S123457, ...}
            
            S = this.subjectsJson_;
            for sub = fields(S)'
                d = this.ensuredirSub(S.(sub{1}).sid);
                this.aufbauSessionPath(d, S.(sub{1}));
            end
        end
        function        aufbauSessionPath(this, sub_pth, S_sub, varargin)
            %% refreshes subjects/ses-S12345/ses-E12345/TRA_DT123456.000000-Converted-AC with short-name sym-links to 
            %            CCIR_00123/ses-S12345/ses-E12345/TRA_DT123456.000000-Converted-AC. 
            %  e. g., /subjectsDir/sub-S40037/{ses-E182819, ses-E182853, ...}/tracer.4dfp.*, with sym-linked tracer.4dfp.*
            
            ip = inputParser;
            addParameter(ip, 'experimentPattern', '_E', @ischar)
            parse(ip, varargin{:})
            
            if isfield(S_sub, 'aliases')
                for asub = fields(S_sub.aliases)'
                    this.aufbauSessionPath(sub_pth, S_sub.aliases.(asub{1}), varargin{:});
                end
            end
            
            % base case
            assert(isfield(S_sub, 'experiments'))
            if ischar(S_sub.experiments)
                S_sub.experiments = {S_sub.experiments};
            end
            for e = asrow(S_sub.experiments)
                
                % look to studyRegistry for experiments to skip
                if lstrfind(e{1}, this.studyRegistry_.ignoredExperiments)
                    continue
                end
                
                if lstrfind(e{1}, ip.Results.experimentPattern)
                    d = this.ensuredirSes(sub_pth, e{1});
                    [fcell, prjData] = this.ensuredirsScans(d);
                    if (~isempty(fcell))
                        e1 = this.studyRegistry_.experimentID_to_ses(e{1});
                        try
                            this.lns_tracers( ...
                                fullfile(prjData.projectSessionPath(e1), ''), ...
                                fullfile(sub_pth, e1, ''), ...
                                fcell);
                            this.lns_surfer( ...
                                fullfile(prjData.projectSessionPath(e1), ''), ...
                                fullfile(sub_pth, e1, ''));
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
        end
        function d    = ensuredirSub(this, sid)
            %  @return d is f.q. path to subject

            d = fullfile(this.subjectsDir, this.studyRegistry_.subjectID_to_sub(sid), '');
            ensuredir(d);
        end
        function d    = ensuredirSes(this, sub_pth, eid)
            %  @return d is f.q. path to session
            
            d = fullfile(sub_pth, this.studyRegistry_.experimentID_to_ses(eid), '');
            ensuredir(d);            
        end
        function [fcell,prjData] = ensuredirsScans(this, sub_ses_pth)
            %  @return fcell is cell array of scan-folders
            %  @return prjData := this.createProjectData is mlnipet.ProjectData.
            
            ses = mybasename(sub_ses_pth);
            prjData = this.createProjectData('sessionStr', ses);
            prj_ses_pth = prjData.projectSessionPath(ses);
            prj_ses_scn_pth = cellfun(@(x) fullfile(prj_ses_pth, [x '*-Converted']), this.TRACERS, 'UniformOutput', false);
            dtt = mlpet.DirToolTracer('tracer', prj_ses_scn_pth, 'ac', true);
            fcell = dtt.dns;
            for id = fcell
                ensuredir(fullfile(sub_ses_pth, id{1}));
            end
        end
        function        lns_surfer(~, prj_ses_pth, sub_ses_pth)
            %% sym-links project-session-scan surfer objects to subject-session-tracer path
            %  @param prj_ses_pth is f.q. path
            %  @param sub_ses_pth is f.q. path
            
            system(sprintf('ln -s %s %s', ...
                fullfile(prj_ses_pth, 'mri', ''), fullfile(sub_ses_pth)))
            lns_4dfp(fullfile(prj_ses_pth, 'T1001'), fullfile(sub_ses_pth, 'T1001'))
        end
        function        lns_tracers(this, prj_ses_pth, sub_ses_pth, scncell)
            %% sym-links tracers in project-session path, first FDG scan, to subject-session path
            %  @param prj_ses_pth is f.q. path
            %  @param sub_ses_pth is f.q. path
            %  @param fcell is cell of scan-folders for prj_ses_pth and sub_ses_pth
                                        
            if ischar(scncell)
                scncell = {scncell};
            end
            for scn = asrow(scncell)
                for t = lower(this.TRACERS)
                    if strncmpi(t{1}, scn{1}, length(t{1}))    
                        
                        % tracer images
                        try
                            tracerfp = this.tracer_fileprefix(prj_ses_pth, scn{1}, t{1});
                            deleteExisting(fullfile(sub_ses_pth, scn{1}, [t{1} '.4dfp.*']))
                            deleteDeadLink(fullfile(sub_ses_pth, scn{1}, [t{1} '.4dfp{.hdr,.img}']))
                            lns_4dfp( ...
                                fullfile(prj_ses_pth, scn{1}, tracerfp), ...
                                fullfile(sub_ses_pth, scn{1}, t{1}))
                            deleteExisting(fullfile(sub_ses_pth, scn{1}, [t{1} '_avgt.4dfp.*']))
                            deleteDeadLink(fullfile(sub_ses_pth, scn{1}, [t{1} '_avgt.4dfp{.hdr,.img}']))
                            lns_4dfp( ...
                                fullfile(prj_ses_pth, scn{1}, [tracerfp '_avgt']), ...
                                fullfile(sub_ses_pth, scn{1}, [t{1} '_avgt']))
                        catch ME
                            handwarning(ME)
                        end  
                        
                        % T1001 images
                        try
                            deleteExisting(fullfile(sub_ses_pth, scn{1}, 'T1001.4dfp.*'))
                            deleteDeadLink(fullfile(sub_ses_pth, scn{1}, 'T1001.4dfp{.hdr,.img}'))
                            lns_4dfp( ...
                                fullfile(prj_ses_pth, scn{1}, 'T1001'), ...
                                fullfile(sub_ses_pth, scn{1}, 'T1001'))
                        catch ME
                            handwarning(ME)
                        end
                    end
                end
            end
        end
        function fp   = T1001_fileprefix(~, prj_ses_pth, scn, t)
            %% tracer 'fdg' -> fileprefix 'fdgr2_op_fdge1to4r1_frame4'
            %  @param prj_ses_pth is f.q. path
            %  @param scn is folder in prj_ses_pth
            %  @param t is one of lower(this.TRACERS)
            
            dt = mlsystem.DirTool(fullfile(prj_ses_pth, scn, ['T1001r1_op_' t 'e1to*r1_frame*.4dfp.hdr']));
            assert(dt.length > 0, evalc('disp(dt)'))
            fp = myfileprefix(dt.fns{1});
        end
        function fp   = tracer_fileprefix(~, prj_ses_pth, scn, t)
            %% tracer 'fdg' -> fileprefix 'fdgr2_op_fdge1to4r1_frame4';
            %  tracer 'fdg' -> fileprefix 'fdgr1' otherwise.
            %  @param prj_ses_pth is f.q. path
            %  @param scn is folder in prj_ses_pth
            %  @param t is one of lower(this.TRACERS)
            
            import mlsystem.DirTool
            
            dt = DirTool(fullfile(prj_ses_pth, scn, [t 'r2_op_' t 'r1_frame*.4dfp.hdr']));
            if 0 == dt.length
                dt = DirTool(fullfile(prj_ses_pth, scn, [t 'r1.4dfp.hdr']));
                warning('mlnipet:RuntimeWarning', 'SubjectData.tracer_fileprefix is returning without motion corrections')
            end
            assert(~isempty(dt.fns), 'mlnipet:RuntimeError', 'SubjectData.tracer_fileprefix')
            fp = myfileprefix(dt.fns{1});
        end
		  
 		function this = SubjectData(varargin)
 			%% SUBJECTDATA
 			%  @param .

 			this = this@mlpipeline.SubjectData(varargin{:});
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        subjectsJson_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

