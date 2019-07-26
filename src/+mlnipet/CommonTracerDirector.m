classdef CommonTracerDirector < mlpipeline.AbstractDirector
	%% COMMONTRACERDIRECTOR  
    %  Salient calling order:  
    %      constructResolved
    %      instanceConstructResolvedNAC
    %          mlnipet.NipetBuilder.CreatePrototypeNAC
    %              packageSingleFrameLocation - gathers NIPET frames, renames them, merges frames, saves TRACER.nii.gz, crops to tracer.nii.gz
    %          packageTracerResolvedR1 - reads tracer.nii.gz, does flip(1) to correct NIPET orientation discrepency, saves tracerr1.nii.gz

	%  $Revision$
 	%  was created 21-May-2019 21:58:04 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlnipet/src/+mlnipet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        FAST_FILESYSTEM = '/fast_filesystem_disabled'
    end
    
	properties (Dependent)
        outputDir
        outputFolder
        reconstructionDir
        reconstructionFolder
    end
    
    methods (Static)
        function this = cleanResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap, ready for use by instanceConstructResolvedAC
            %  @return this.sessionData.attenuationCorrection == false.
                      
            inst = mlpipeline.ResourcesRegistry.instance();
            inst.keepForensics = false;
            this = mlnipet.CommonTracerDirector(mlpet.TracerResolveBuilder(varargin{:}));   
            this = this.instanceCleanResolved;
        end
        function this = constructResolved(varargin)
            %  @param varargin for mlpet.TracerResolveBuilder.
            %  @return ignores the first frame of OC and OO which are NAC since they have breathing tube visible.  
            %  @return umap files generated per motionUncorrectedUmap ready
            %  for use by TriggeringTracers.js; 
            %  sequentially run FDG NAC, 15O NAC, then all tracers AC.
            %  @return this.sessionData.attenuationCorrection == false.
                      
            this = mlnipet.CommonTracerDirector(mlpet.TracerResolveBuilder(varargin{:}));
            this.fastFilesystemSetup;
            if (~this.sessionData.attenuationCorrected)
                this = this.instanceConstructResolvedNAC;                
                this.fastFilesystemTeardownWithAC(true); % intermediate artifacts
            else
                this = this.instanceConstructResolvedAC;
            end
            this.fastFilesystemTeardown;
            this.fastFilesystemTeardownProject;
        end
        function ic2  = flipKLUDGE____(ic2)
            if (mlnipet.ResourcesRegistry.instance().FLIP1)
                assert(isa(ic2, 'mlfourd.ImagingContext2'), 'mlnipet:TypeError', 'TracerDirector2.flipKLUDGE____');
                warning('mlnipet:RuntimeWarning', 'KLUDGE:TracerDirector2.flipKLUDGE____ is active');
                ic2 = ic2.flip(1);
                ic2.ensureSingle;
            end
        end
        function tmp  = migrationTeardown(fps, logs, dest_fqfp0, dest)
            tmp = protectFiles(fps, fps{1}, logs);
            deleteFiles(dest_fqfp0, fps{1}, fps, dest);   
            unprotectFiles(tmp);
                        
            function tmp = protectFiles(fps, fps1, logs)
                
                % in tempFilepath
                tmp = tempFilepath('protectFiles');
                ensuredir(tmp);                
                for f = 1:length(fps)
                    moveExisting([fps{f} '.4dfp.*'], tmp);
                    moveExisting([fps{f} 'r1_b43.4dfp.*'], tmp);
                end
                moveExisting( 'T1001.4dfp.*', tmp);
                moveExisting(['T1001r1_op_' fps1 '.4dfp.*'], tmp);
                moveExisting(sprintf('T1001_to_op_%s_t4', fps1), tmp)
                moveExisting( 'T1001_to_TRIO_Y_NDC_t4', tmp)

                % in Log
                moveExisting('*.mat0', logs);
                moveExisting('*.sub',  logs);
                moveExisting('*.log',  logs);  
            end
            function deleteFiles(dest_fqfp0, fps1, fps, dest)
                assert(lstrfind(dest_fqfp0{end}, '_sumt'));
                deleteExisting([dest_fqfp0{end} 'r1.4dfp.*']);
                deleteExisting([dest_fqfp0{end} 'r1_op_' fps1 '.4dfp.*']);
                deleteExisting([dest_fqfp0{end} 'r1_to_op_' fps1 '_t4']);
                deleteExisting([dest_fqfp0{end} 'r1_to_T1001r1_t4']);
                for f = 1:length(fps)
                    deleteExisting(fullfile(dest, ['T1001r1_to_' fps{f} 'r1_t4']));
                end
                deleteExisting('T1001r1.4dfp.*');
                deleteExisting('T1001r1_b43.4dfp.*');
                deleteExisting('*_mskt.4dfp.*');
                deleteExisting('*_g11.4dfp.*');       
            end
            function unprotectFiles(tmp)
                movefile(fullfile(tmp, '*'), pwd);
                rmdir(tmp);
            end
        end
        function lst  = prepareFreesurferData(varargin)
            %% PREPAREFREESURFERDATA prepares session-specific copies of data enumerated by this.freesurferData.
            %  @param named sessionData is an mlpipeline.ISessionData.
            %  @return 4dfp copies of this.freesurferData in sessionData.sessionPath.
            %  @return lst, a cell-array of fileprefixes for 4dfp objects created on the local filesystem.            
        
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});            
            sess = ip.Results.sessionData;
            
            pwd0    = pushd(sess.sessionPath);
            fv      = mlfourdfp.FourdfpVisitor;
            fsd     = { 'aparc+aseg' 'aparc.a2009s+aseg' 'brainmask' 'T1' 'wmparc' };  
            safefsd = fsd; safefsd{4} = 'T1001';
            safefsd = fv.ensureSafeFileprefix(safefsd);
            lst     = cell(1, length(safefsd));
            sess    = ip.Results.sessionData;
            for f = 1:length(fsd)
                if (~fv.lexist_4dfp(fullfile(sess.sessionPath, safefsd{f})))
                    try
                        sess.mri_convert([fullfile(sess.mriLocation, fsd{f}) '.mgz'], [safefsd{f} '.nii']);
                        ic2 = mlfourd.ImagingContext2([safefsd{f} '.nii']);
                        ic2.saveas([safefsd{f} '.4dfp.hdr']);
                        lst{f} = fullfile(pwd, safefsd{f});
                    catch ME
                        dispwarning(ME);
                    end
                end
            end
            if (~lexist('T1001_to_TRIO_Y_NDC_t4', 'file')) % redundant with prepareMprToAtlasT4 && ~sessionData.noclobber
                fv.msktgenMprage('T1001');
            end
            popd(pwd0);
        end
    end

	methods
        
        %% GET/SET
        
        function g = get.outputDir(this)
            g = fullfile(this.sessionData.tracerConvertedLocation, this.outputFolder, '');
        end
        function g = get.outputFolder(~)
            g = 'output';
        end
        function g = get.reconstructionDir(this)
            g = fullfile(this.sessionData.tracerConvertedLocation, this.reconstructionFolder, '');
        end
        function g = get.reconstructionFolder(~)
            g = 'reconstructed';
        end
        
        %%        
        
        function pwdLast = fastFilesystemSetup(this)
            slowd = this.sessionData.scanPath;
            if (~isdir(this.FAST_FILESYSTEM))
                pwdLast = pushd(slowd);
                return
            end
            
            pwdLast = pwd;
            fastd = fullfile(this.FAST_FILESYSTEM, slowd, '');
            fastdParent = fileparts(fastd);
            slowdParent = fileparts(slowd);
            try
                mlbash(sprintf('mkdir -p %s', fastd));
                mlbash(sprintf('rsync -rav %s/* %s', slowd, fastd))
                mlbash(sprintf('if [[ -e %s/ct ]];      then rm  %s/ct; fi', fastdParent, fastdParent));
                mlbash(sprintf('if [[ -e %s/mri ]];     then rm  %s/mri; fi', fastdParent, fastdParent));
                mlbash(sprintf('if [[ -e %s/rawdata ]]; then rm  %s/rawdata; fi', fastdParent, fastdParent));
                mlbash(sprintf('if [[ -e %s/SCANS ]];   then rm  %s/SCANS; fi', fastdParent, fastdParent));
                mlbash(sprintf('if [[ -e %s/umaps ]];   then rm  %s/umaps; fi', fastdParent, fastdParent));
                mlbash(sprintf('ln -s  %s/ct %s/ct', slowdParent, fastdParent));
                mlbash(sprintf('ln -s  %s/mri %s/mri', slowdParent, fastdParent));
                mlbash(sprintf('ln -s  %s/rawdata %s/rawdata', slowdParent, fastdParent));
                mlbash(sprintf('ln -s  %s/SCANS %s/SCANS', slowdParent, fastdParent));
                mlbash(sprintf('ln -s  %s/umaps %s/umaps', slowdParent, fastdParent));
                cd(fastd);
            catch ME
                handexcept(ME);
            end
            
            % redirect projectsDir
            inst = mlraichle.StudyRegistry.instance;
            inst.projectsDir = fullfile(this.FAST_FILESYSTEM, getenv('PROJECTS_DIR'));
            inst.subjectsDir = fullfile(this.FAST_FILESYSTEM, getenv('SUBJECTS_DIR'));
            
        end
        function pwdLast = fastFilesystemTeardown(this)
            pwdLast = this.fastFilesystemTeardownWithAC(this.sessionData.attenuationCorrected);
        end
        function pwdLast = fastFilesystemTeardownWithAC(this, ac)
            assert(islogical(ac));
            this.sessionData.attenuationCorrected = ac;
            slowd = fullfile(this.sessionData.projectPath, this.sessionData.sessionFolder, this.sessionData.scanFolder, '');
            if (~isdir(this.FAST_FILESYSTEM))
                pwdLast = popd(slowd);
                return
            end
            
            pwdLast = pwd;   
            fastd = fullfile(this.FAST_FILESYSTEM, slowd, '');  
            try
                mlbash(sprintf('rsync -rav %s/* %s', fastd, slowd))             
                mlbash(sprintf('rm -rf %s', fastd))
                cd(slowd);
            catch ME
                handexcept(ME);
            end
            
            % redirect projectsDir
            inst = mlraichle.StudyRegistry.instance;
            inst.projectsDir = fullfile(getenv('PROJECTS_DIR'));
            inst.subjectsDir = fullfile(getenv('SUBJECTS_DIR'));
        end
        function           fastFilesystemTeardownProject(this)
            try
                fastProjPath = fullfile(this.FAST_FILESYSTEM, ...
                                        getenv('SUBJECTS_DIR'), ...
                                        this.sessionData.projectFolder, '');
                mlbash(sprintf('rm -rf %s', fastProjPath))
            catch ME
                handexcept(ME);
            end
        end
        function this = instanceCleanResolved(this)
            %  @return removes non-essential files from workspaces to conserve storage costs.
            
            sess = this.sessionData;
            mlnipet.NipetBuilder.CleanPrototype(sess);
            
            pwd0 = pushd(this.sessionData.tracerLocation);
            this.deleteExisting__;
            this.moveLogs__;
            for e = 1:sess.supEpoch
                sess1 = sess;
                sess1.epoch = e;                
                this.deleteRNumber__(sess1, 1);
                this.deleteRNumber__(sess1, 2);
            end
            sess1.epoch = 1:sess.supEpoch;
            this.deleteRNumber__(sess1, 1);
            this.deleteRNumber__(sess1, 2);
            popd(pwd0);            
        end
        function this = instanceConstructResolvedAC(this)
            mlnipet.NipetBuilder.CreatePrototypeAC(this.sessionData);
            this          = this.packageTracerResolvedR1;   
            this.builder_ = this.builder_.reconstituteFramesAC;
            this.sessionData.frame = nan;
            this.builder_.sessionData.frame = nan;
            this.builder_ = this.tryMotionCorrectFrames(this.builder_);  
            this.builder_ = this.builder_.reconstituteFramesAC3;
            this.builder_ = this.builder_.avgtProduct;
            this.builder_.logger.save; 
            if (mlpipeline.ResourcesRegistry.instance().debug)
                save('mlnipet_CommonTracerDirector_instanceConstructResolvedAC.mat');
            else                
                this.builder_.deleteWorkFiles;
                this.builder_.markAsFinished;
            end
        end
        function this = instanceConstructResolvedNAC(this)
            mlnipet.NipetBuilder.CreatePrototypeNAC(this.sessionData);
            this          = this.packageTracerResolvedR1;
            this.builder_ = this.builder_.prepareMprToAtlasT4;
            [this.builder_,epochs,reconstituted] = this.tryMotionCorrectFrames(this.builder_);          
            reconstituted = reconstituted.motionCorrectCTAndUmap;             
            this.builder_ = reconstituted.motionUncorrectUmap(epochs);     
            this.builder_ = this.builder_.aufbauUmaps;     
            this.builder_.logger.save;       
            p = this.flipKLUDGE____(this.builder_.product); % KLUDGE:  bug at interface with NIPET
            p.save;
            if (mlpipeline.ResourcesRegistry.instance().debug)
                save('mlnipet_CommonTracerDirector_instanceConstructResolvedNAC.mat');
            else
                this.builder_.deleteWorkFiles;
                this.builder_.markAsFinished;
            end
        end
        function this = packageTracerResolvedR1(this)
            %% copies reduced-FOV NIfTI tracer images to this.sessionData.tracerLocation in 4dfp format.
            
            import mlfourd.*;
            assert(isdir(this.outputDir));
            ensuredir(this.sessionData.tracerRevision('typ', 'path'));
            if (~lexist_4dfp(this.sessionData.tracerRevision('typ', 'fqfp')) || ...
                    this.sessionData.ignoreFinishMark)
                ic2 = ImagingContext2(this.sessionData.tracerNipet('typ', '.nii.gz')); % e.g., fdg.nii.gz
                ic2.addLog( ...
                    sprintf('mlraichle.TracerDirector2.packageTracerResolvedR1.sessionData.tracerListmodeDcm->%s', ...
                    this.sessionData.tracerListmodeDcm));
                ic2 = this.flipKLUDGE____(ic2); % KLUDGE:  bug at interface with NIPET
                ic2.saveas(this.sessionData.tracerRevision('typ', '.4dfp.hdr')); % e.g., fdgr1.nii.gz
            end
            this.builder_ = this.builder_.packageProduct( ...
                ImagingContext2(this.sessionData.tracerRevision('typ', '.4dfp.hdr')));
        end
        function [bldr,epochs,reconstituted] = tryMotionCorrectFrames(this, bldr)
            %% TRYMOTIONCORRECTFRAMES will partition monolithic image into epochs, 
            %  then motion-correct frames within each epoch.
            %  Stale Epoch folders can correct motion-correction, so for thrown MException, 
            %  removing Epoch folders and try again
            %  @param TracerResolveBuilder
            %  @return TracerResolveBuilder, TracerResolveBuilder.^(SessionData.supEpoch), ImagingContext2
            
            epochs = [];
            reconstituted = [];
            if (this.sessionData.attenuationCorrected)
                try
                    this.builder_ = this.builder_.partitionMonolith;
                    this.builder_ = this.builder_.motionCorrectFrames; % returns composite builder
                catch ME
                    handexcept(ME, 'mlnipet:RuntimeError', 'CommonTracerDirector.tryMotionCorrectFrames');
                    this.deleteEpochs__;
                    this.builder_ = this.builder_.partitionMonolith;
                    this.builder_ = this.builder_.motionCorrectFrames;
                end
            else
                try
                    this.builder_ = this.builder_.partitionMonolith;
                    [this.builder_,epochs,reconstituted] = this.builder_.motionCorrectFrames; % returns composite builder
                catch ME
                    handexcept(ME, 'mlnipet:RuntimeError', 'CommonTracerDirector.tryMotionCorrectFrames');
                    this.deleteEpochs__;
                    this.builder_ = this.builder_.partitionMonolith;
                    [this.builder_,epochs,reconstituted] = this.builder_.motionCorrectFrames;
                end
            end
        end        
		  
 		function this = CommonTracerDirector(varargin)
 			%% COMMONTRACERDIRECTOR
 			%  @param .

 			this = this@mlpipeline.AbstractDirector(varargin{:});
 		end
    end

    %% PROTECTED
    
    methods (Static, Access = protected)
        function ipr = adjustIprConstructResolvedStudy(ipr)
            ss = strsplit(ipr.foldersExpr, filesep);
            assert(3 == length(ss));
            ipr.projectsExpr = ss{1};
            ipr.sessionsExpr = ss{2};
            ipr.tracersExpr = ss{3};
            results = {'projectsExpr' 'sessionsExpr' 'tracersExpr'};
            for r = 1:length(results)
                if (~lstrfind(ipr.(results{r}), '*'))
                    ipr.(results{r}) = [ipr.(results{r}) '*'];
                end
            end
        end  
    end
    
    methods (Access = protected)
        function deleteEpochs__(this)
            for e = 1:this.sessionData.supEpoch
                mlbash(sprintf('rm -rf %s', fullfile(this.sessionData.scanPath, sprintf('E%i', e), '')));
            end
        end
        function deleteExisting__(~)
            deleteExisting('*_b75.4dfp.*');
            deleteExisting('*_g11.4dfp.*');
            deleteExisting('*_mskt.4dfp.*');
        end
        function deleteRNumber__(this, sess_, r)
            pwd_ = pushd(sess_.tracerLocation);
            dt = mlsystem.DirTool('*_t4');
            if (isempty(dt.fns))
                return; 
            end
                
            this.deleteExisting__;
            this.moveLogs__;
            sess_.rnumber = r;
            deleteExisting([sess_.tracerRevision('typ','fp') '_frame*.4dfp.*']);  
            popd(pwd_);
        end
        function moveLogs__(~)
            ensuredir('Log');
            %movefile('*.log', 'Log');
            moveExisting('*.mat0', 'Log');
            moveExisting('*.sub', 'Log');
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

