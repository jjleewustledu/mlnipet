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
 	
	properties (Dependent)
        projectData
 		subjectsStruct 		
 	end

	methods 
        
        %% GET

        function g = get.projectData(this)
            g = this.projectData_;
        end
        function g = get.subjectsStruct(this)
            g = this.subjectsStruct_;
        end
        
        %%
        
        function        aufbauSubjectsDir(this)
            %% e. g., /subjectsDir/{sub-S123456, sub-S123457, ...}
            
            S = this.subjectsJson_;
            for sub = fields(S)'
                d = this.ensuredirSub(S.(sub{1}).sid);
                this.aufbauSubjectPath(d, S.(sub{1}));
            end
        end
        function        aufbauSubjectPath(this, sub_pth, S_sub)
            %% e. g., /subjectsDir/sub-S40037/{ses-E182819, ses-E182853, ...}/tracer.4dfp.*, with sym-linked tracer.4dfp.*
            
            if isfield(S_sub, 'aliases')
                for asub = fields(S_sub.aliases)'
                    this.aufbauSubjectPath(sub_pth, S_sub.aliases.(asub{1}));
                end
            end
            
            % base case
            assert(isfield(S_sub, 'experiments'))
            for e = S_sub.experiments'
                d = this.ensuredirSes(sub_pth, e{1});
                fcell = this.ensuredirsScans(d);
                if (~isempty(fcell))
                    e1 = this.experimentID_to_ses(e{1});
                    try
                        this.lns_tracers( ...
                            fullfile(this.projectData.getProjectPath(e1), e1, ''), ...
                            fullfile(sub_pth, e1, ''), ...
                            fcell);
                        this.lns_surfer( ...
                            fullfile(this.projectData.getProjectPath(e1), e1, ''), ...
                            fullfile(sub_pth, e1, ''));
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function d    = ensuredirSub(this, sid)
            %  @return d is f.q. path to subject

            d = fullfile(this.subjectsDir, this.subjectID_to_sub(sid), '');
            ensuredir(d);
        end
        function d    = ensuredirSes(this, sub_pth, eid)
            %  @return d is f.q. path to session
            
            d = fullfile(sub_pth, this.experimentID_to_ses(eid), '');
            ensuredir(d);            
        end
        function fcell = ensuredirsScans(this, sub_ses_pth)
            %  @return fcell is cell of scan-folders
            
            p = this.prj_ses_pth_from(sub_ses_pth);
            prj_ses_scn = cellfun(@(x) fullfile(p, [x '*-Converted']), this.TRACERS, 'UniformOutput', false);
            dtt = mlpet.DirToolTracer('tracer', prj_ses_scn, 'ac', true);
            fcell = dtt.dns;
            for id = fcell
                ensuredir(fullfile(sub_ses_pth, id{1}));
            end
        end
        function ses  = experimentID_to_ses(~, eid)
            split = strsplit(eid, '_');
            ses = ['ses-' split{2}];
        end
        function fold = getProjectFolder(this, ses)
            fold = this.projectData_.getProjectFolder(ses);
        end
        function pth  = getProjectPath(this, ses)
            pth = this.projectData_.getProjectPath(ses);
        end
        function        lns_surfer(this, prj_ses_pth, sub_ses_pth)
            %% sym-links project-session surfer objects to subject-session path
            
            % convert /projectsPath/PROJ_00123/ses-E123456/mri/wmparc.mgz
            system(sprintf('mri_convert %s.mgz %s.nii', ...
                fullfile(prj_ses_pth, 'mri', 'wmparc'), ...
                fullfile(prj_ses_pth, 'wmparc')));
            system(sprintf('nifti_4dfp -4 %s.nii %s.4dfp.hdr', ...
                fullfile(prj_ses_pth, 'wmparc'), ...
                fullfile(prj_ses_pth, 'wmparc')));
            
            % ln -s
            for s = {'aparcA2009sAseg' 'aparcAseg' 'brainmask' 'wmparc' 'T1001'}
                for x = [this.EXTS '.nii']
                    if ~isfile([fullfile(sub_ses_pth, s{1}) x{1}])
                        assert(isfile([fullfile(prj_ses_pth, s{1}) x{1}]))
                        system(sprintf('ln -s %s%s %s%s', ...
                            fullfile(prj_ses_pth, s{1}), x{1}, ...
                            fullfile(sub_ses_pth, s{1}), x{1}))
                    end
                end
            end
        end
        function        lns_tracers(this, prj_ses_pth, sub_ses_pth, scncell)
            %% sym-links tracers in project-session path to subject-session path
            %  @param prj_ses_pth is f.q. path
            %  @param sub_ses_pth is f.q. path
            %  @param fcell is cell of scan-folders for prj_ses_pth and sub_ses_pth
            
            if ischar(scncell)
                scncell = {scncell};
            end
            for scn = scncell
                for t = lower(this.TRACERS)
                    if strncmpi(t{1}, scn{1}, length(t{1}))                        
                        try
                            tracerfp = this.tracer_fileprefix(prj_ses_pth, scn{1}, t{1});
                            if ~lexist_4dfp(fullfile(sub_ses_pth, scn{1}, t{1}))
                                lns_4dfp( ...
                                    fullfile(prj_ses_pth, scn{1}, tracerfp), ...
                                    fullfile(sub_ses_pth, scn{1}, t{1}))
                            end
                            if ~lexist_4dfp(fullfile(sub_ses_pth, scn{1}, [t{1} '_avgt']))
                                lns_4dfp( ...
                                    fullfile(prj_ses_pth, scn{1}, [tracerfp '_avgt']), ...
                                    fullfile(sub_ses_pth, scn{1}, [t{1} '_avgt']))
                            end
                        catch ME
                            handwarning(ME)
                        end                        
                        try
                            t1fp = this.T1001_fileprefix(prj_ses_pth, scn{1}, t{1});
                            if ~lexist_4dfp(fullfile(sub_ses_pth, scn{1}, 'T1001'))
                                lns_4dfp( ...
                                    fullfile(prj_ses_pth, scn{1}, t1fp), ...
                                    fullfile(sub_ses_pth, scn{1}, 'T1001'))
                            end
                        catch ME
                            handwarning(ME)
                        end
                    end
                end
            end
        end
        function p    = prj_ses_pth_from(this, sub_ses_pth)
            ses = mybasename(sub_ses_pth);
            p = fullfile(this.getProjectPath(ses), ses);
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
            %% tracer 'fdg' -> fileprefix 'fdgr2_op_fdge1to4r1_frame4'
            %  @param prj_ses_pth is f.q. path
            %  @param scn is folder in prj_ses_pth
            %  @param t is one of lower(this.TRACERS)
            
            dt = mlsystem.DirTool(fullfile(prj_ses_pth, scn, [t 'r2_op_' t 'e1to*r1_frame*.4dfp.hdr']));
            assert(dt.length > 0, evalc('disp(dt)'))
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
        projectData_
        registry_
        subjectsStruct_
    end
    
    methods (Access = protected)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

