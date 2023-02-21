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
        SURFER_OBJECTS = { 'aparc+aseg' 'aparc.a2009s+aseg' 'brain' 'brainmask' 'T1' 'wmparc' }
    end
    
	properties (Dependent)
        outputDir
        outputFolder
        reconstructionDir
        reconstructionFolder
    end
    
    methods (Static)
        function ic2  = addMirrorUmap(ic2, sessd)
            assert(isa(ic2, 'mlfourd.ImagingContext2'))
            assert(isa(sessd, 'mlnipet.SessionData'))
            
            try
                if strcmpi(sessd.tracer, 'OO')
                    mirrorUmap = mlnipet.CommonTracerDirector.alignMirrorUmapToOO(sessd);
                    mirrorUmap.ensureSingle;
                    ic2 = ic2 + mirrorUmap;
                end
                if strcmpi(sessd.tracer, 'OC') || strcmpi(sessd.tracer, 'HO')                    
                    mirrorUmap = mlnipet.CommonTracerDirector.getOOMirrorForTracer(sessd);
                    if ~isempty(mirrorUmap)
                        mirrorUmap.ensureSingle;
                        ic2 = ic2 + mirrorUmap;
                    end
                end
            catch ME
                handwarning(ME, 'mlnipet:RuntimeWarning', ...
                    'CommonTracerDirector.addMirrorUmap could not generate registered mirror umap')
            end
        end
        function ipr = adjustIprConstructResolvedStudy(ipr)
            %% adjusts ip.Results with new fields: 'projectsExpr', 'sessionsExpr', 'tracersExpr'.
            
            ss = strsplit(ipr.foldersExpr, filesep);
            ipr.projectsExpr = ss{contains(ss, 'CCIR_')};
            ipr.sessionsExpr = ss{contains(ss, 'ses-')};
            ipr.tracersExpr = ss{contains(ss, 'Converted-')};
            results = {'projectsExpr' 'sessionsExpr' 'tracersExpr'};
            for r = 1:length(results)
                if (~lstrfind(ipr.(results{r}), '*'))
                    ipr.(results{r}) = [ipr.(results{r}) '*'];
                end
            end
        end  
        function umap = alignMirrorUmapToOO(sessd)
            pwd0 = pushd(sessd.tracerOutputPetLocation());
            
            [OO,weights] = theOO(sessd);            
            [mirrorOnOO,umap] = prepareMirror('', OO, weights);
            if overlap(OO, mirrorOnOO) < 0.5
                [mirrorOnOO,umap] = prepareMirror('_facing_console', OO, weights);
                assert(overlap(OO, mirrorOnOO) >= 0.5)
            end
            
            deleteExisting('mirror_*4dfp*')
            deleteExisting('*_b86*4dfp*')
            popd(pwd0)
            
            %% INTERNAL
            
            function ol = overlap(b, a)
                num = b .* a;
                a2  = a .* a;
                b2  = b .* b;
                ol  = num.dipsum/(sqrt(a2.dipsum) * sqrt(b2.dipsum));
            end
            function [mirrorOnOO,umap] = prepareMirror(tag, OO, weights)
                import mlfourd.ImagingContext2
                fv = mlfourdfp.FourdfpVisitor;
                mirror = theMirror(tag);
                fv.align_translationally( ...
                    'dest', OO.fileprefix, ...
                    'source', mirror.fileprefix, ...
                    'destMask', weights.fqfileprefix)  
                mirrorOnOO = ImagingContext2([mirror.fileprefix '_on_' OO.fileprefix '.4dfp.hdr']);
                umapSourceFp = fullfile(getenv('HARDWAREUMAPS'), ['mirror_umap_344x344x127' tag]);
                umapFp = ['mirror_umap_344x344x127_on_' OO.fileprefix];
                fv.t4img_4dfp( ...
                    [mirror.fileprefix '_to_' OO.fileprefix '_t4'], ...
                    umapSourceFp, ...
                    'out', umapFp, ...
                    'options', ['-O' OO.fileprefix])
                umap = ImagingContext2([umapFp '.4dfp.hdr']);
                umap.nifti
            end
            function [ic2,w] = theOO(sessd)                
                import mlfourd.ImagingContext2
                w   = ImagingContext2(fullfile(getenv('HARDWAREUMAPS'), 'mirror_weights_344x344x127.4dfp.hdr'));
                ic2 = ImagingContext2(fullfile(sessd.tracerOutputPetLocation, 'OO.nii.gz'));
                ic2 = ic2.timeAveraged;
                ic2 = ic2.blurred(8.6);
                ic2 = ic2.thresh(300);
                ic2.filepath = pwd;
                ic2.filesuffix = '.4dfp.hdr';
                ic2 = ic2 .* w;
                ic2.save
            end
            function ic2 = theMirror(tag)
                ic2 = mlfourd.ImagingContext2(fullfile(getenv('HARDWAREUMAPS'), ['mirror_OO_344x344x127' tag '.4dfp.hdr']));
                ic2 = ic2.blurred(8.6);
                ic2 = ic2.thresh(300);
                ic2.filepath = pwd;
                ic2.save
            end
        end
        function tf = ccir_folder_islink(fold)
            %  Args:
            %      fold (folder): e.g., '~/jjlee/Singularity/CCIR_00993/derivatives/nipet/ses-E19850'.
            %  Returns:
            %      tf: ~/jjlee/Singularity/CCIR_00993 is a sym-link.

            assert(isfolder(fold));            
            ss = strsplit(fold, filesep);
            [~,idx] = max(contains(ss, 'CCIR'));
            singfold = strcat(filesep, fullfile(ss{1:idx}));
            tf = ~logical(system(sprintf('test -L %s', singfold)));
        end
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
        function constructNiftyPETy(varargin)
            %  @param sessionData is mlpipeline.{ISessionData,ImagingData}.

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData');
            parse(ip, varargin{:});
            
            bldr = mlpet.NiftyPETyBuilder(varargin{:});
            bldr.setupTracerRawdataLocation();
        end
        function constructPhantom(varargin)   

            assert(contains(pwd, '-Converted-'));

            % clean up working area
            deleteExisting('*fdg*')
            deleteExisting('*T1001*')
            deleteExisting('umap*')
            deleteExisting('msk*')
            mlbash('rm -rf Log')
            mlbash('rm -rf output')
            
            % rename working dir -NAC to -AC
            if lstrfind(pwd, '-NAC')
                pwdNAC = pwd;
                pwdAC = strrep(pwdNAC, '-NAC', '-AC');
                cd(fileparts(pwdNAC));
                mlbash(sprintf('mv %s %s', pwdNAC, pwdAC))
                cd(pwdAC);
            elseif lstrfind(pwd, '-AC')
                pwdAC = pwd;
            else
                error('mlan:RuntimeError', 'TracerDirector2.constructPhantom')
            end
            
            % retrieve Head_MRAC_Brain_HiRes_in_UMAP_*; convert to NIfTI; resample for emissions
            % Siemens DICOMs needed for bed positions, etc.
            pwdUmaps = fullfile(fileparts(pwdAC), 'umaps');
            globbed = globT(fullfile(pwdUmaps, 'Head_MRAC_*5min_in_UMAP*'));
            if isempty(globbed)
                globbed = globT(fullfile(pwdUmaps, '*UMAP*'));
            end
            assert(~isempty(globbed))
            pwdDcms = globbed{end};
            cd(pwdUmaps);
            globbedniix = glob('umapSiemens*.nii.gz');
            if ~isempty(globbedniix)
                ensuredir('Previous')
                mlbash(sprintf('mv -f %s Previous', cell2str(globbedniix)))
            end
            mlbash(sprintf('dcm2niix -f umapSiemens -o %s -b y -z y %s', pwdUmaps, pwdDcms));
            copyfile(fullfile(getenv('SINGULARITY_HOME'), 'zeros_frame.nii.gz'));            
            globbedniix = glob('umapSiemens*.nii.gz');
            mlbash(sprintf('reg_resample -ref zeros_frame.nii.gz -flo %s -res umapSynth.nii.gz', globbedniix{1}));
            delete('zeros_frame.nii.gz');
            movefile('umapSynth.nii.gz', pwdAC);
            cd(pwdAC);
            
            % adjust quantification:  blur, use expected phantom mu
            umap = mlfourd.ImagingContext2('umapSynth.nii.gz');
            umap = umap.blurred(mlnipet.NipetRegistry.instance().petPointSpread);
            umap = umap .* (0.09675 / 1e3);
            umap = umap.nifti;
            umap.img(umap.img < 0) = 0;
            umap.datatype = 'single';
            umap.saveas('umapSynth.nii.gz');
        end
        function [m,s,vol,N,min_,max_] = constructPhantomStats(varargin) 
            
            ip = inputParser;
            addParameter(ip, 'sessionData', [])
            addParameter(ip, 'mask', [])
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if isfile('mlan_TracerDirector2_constructPhantomStats.mat')
                mat = load('mlan_TracerDirector2_constructPhantomStats.mat');
                mat.stats.m = mat.stats.m/1e3;
                mat.stats.s = mat.stats.s/1e3;
                mat.stats.min_ = mat.stats.min_/1e3;
                mat.stats.max_ = mat.stats.max_/1e3;
                fprintf('#############################################################################################\n')
                fprintf('mlan.TracerDirector2.constructPhantomStats():\n')
                fprintf('\t%s\n', basename(pwd))
                disp(mat.stats)                
                fprintf('\n')
                return
            end
            
            pwd0 = pushd('output/PET/single-frame');
            
            globbed = glob('a*t-0*sec*createPhantom.nii.gz');
            emissions = mlfourd.ImagingContext2(globbed{1});
            if ~isempty(ipr.mask)
                emissions = emissions.masked(ipr.mask);
            end
            emissions = emissions.nifti;
            thresh = max(0, dipmax(emissions)/2);
            emissionsVec = emissions.img(emissions.img > thresh);
            m = mean(emissionsVec);
            s = std(emissionsVec);            
            N = numel(emissionsVec);
            vol = N*prod([2.0863 2.0863 2.0312])/1e3; % mL
            min_ = min(emissionsVec);
            max_ = max(emissionsVec);
            histogram(emissionsVec)
            emissions.fsleyes(fullfile(pwd0, 'umapSynth.nii.gz'))
            
            stats.m = m;
            stats.s = s;
            stats.vol = vol;
            stats.N = N;
            stats.min_ = min_;
            stats.max_ = max_;
            save(fullfile(pwd0, 'mlan_TracerDirector2_constructPhantomStats.mat'), 'stats')
            
            fprintf('#############################################################################################')
            fprintf('mlan.TracerDirector2.constructPhantomStats():\n')
            fprintf('\t%s\n', basename(pwd))
            fprintf('\tspecific activity:  mean %g std %g vol %g N %g min %g max %g\n', me, sd, vol, N, min_, max_)
            
            popd(pwd0)
        end
        function ic2  = flipKLUDGE____(ic2)
            assert(isa(ic2, 'mlfourd.ImagingContext2'), 'mlnipet:TypeError', 'TracerDirector2.flipKLUDGE____');
            warning('mlnipet:RuntimeWarning', 'KLUDGE:TracerDirector2.flipKLUDGE____ is active');
            ic2 = ic2.flip(1);
            ic2.ensureSingle;
            ic2.fileprefix = 'umapSynth';
        end
        function umap = getOOMirrorForTracer(sessd)
            import mlnipet.CommonTracerDirector.*
            import mlfourd.ImagingContext2
            umap = [];
            pwd0 = pushd(sessd.tracerOutputPetLocation());
            mirrorLoc = getProximalOOLocation(sessd);
            ooUmapSynth = ImagingContext2(fullfile(mirrorLoc, 'umapSynth.nii.gz'));
            if isfile(ooUmapSynth.fqfilename)
                ooUmapSynth = flipKLUDGE____(ooUmapSynth);
                nii = ooUmapSynth.nifti;
                img = zeros(344,344,127);
                img(141:205,251:300,25:127) = nii.img(141:205,251:300,25:127,1);
                nii.img = img;
                umap = ImagingContext2(nii);
            end            
            popd(pwd0)
        end
        function loc = getProximalOOLocation(sessd)
            loc = pwd;
            tracerdt = location2datetime(sessd.tracerLocation);
            separation = days(1);
            for ooLocations = globFoldersT(fullfile(sessd.sessionPath, 'OO_DT*.000000-Converted-AC'))
                oodt = location2datetime(ooLocations{1});
                if abs(tracerdt - oodt) < separation
                    separation = tracerdt - oodt;
                    loc = ooLocations{1};
                end
            end
        end
        function tmp = migrationTeardown(fps, logs, dest_fqfp0, dest)
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
                %deleteExisting([dest_fqfp0{end} 'r1_to_op_' fps1 '_t4']); % may break mlpet.SessionResolverToTracer.{oc,oo,ho}glob()
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
        function populateTracerUmapFolder(varargin)
            %% NIPET requires Siemens UMAP DICOMs in fullfile(this.sessionData.tracerLocation(), 'umap', '').
            %  Populate these locations with time-stamped folders from fullfile(this.sessionData.sessionLocation(), 'umaps')                        
            %  @param named sessionData is an mlpipeline.{ISessionData,ImagingData}.
        
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData');
            parse(ip, varargin{:});            
            ipr = ip.Results;
            
            pwd0 = pushd(ipr.sessionData.sessionLocation());        
            tracerFold = ipr.sessionData.tracerLocation('typ', 'folder');
            tracerDT = regexp(tracerFold, '\w+_DT(?<adatetime>\d{14})(|.\d+)-Converted-(NAC|AC)', 'names');
            tracerDT = datetime(tracerDT.adatetime, 'InputFormat', 'yyyyMMddHHmmss');
            
            umapFolds = globFoldersT(fullfile('umaps', '*_DT*', '')); % cell row-array without filesep
            for ui = 1:length(umapFolds)
                umapDT_ = regexp(mybasename(umapFolds{ui}), '\S+_DT(?<adatetime>\d{14})(|.\d+)', 'names');
                assert(~isempty(umapDT_), ...
                    'mlnipet:RuntimeError', 'CommonTracerDirector.populateTracerUmapFolder.umapDT_ was empty')
                umapDT(ui) = datetime(umapDT_.adatetime, 'InputFormat', 'yyyyMMddHHmmss'); %#ok<AGROW>
            end
            tbl = table(umapDT', umapFolds', 'VariableNames', {'umapDT' 'umapFolds'});
            deltaDT = abs(tbl.umapDT - tracerDT);
            foundUmapFold = umapFolds(deltaDT == min(deltaDT));
            copyfile(foundUmapFold{1}, fullfile(tracerFold, 'umap'), 'f')
            assert(~isempty(glob(fullfile(tracerFold, 'umap', '*'))), ...
                'mlnipet:RuntimeError', 'CommonTracerDirector.populateTracerUmapFolder found empty umap folder')
            popd(pwd0)
        end
        function lst = prepareFreesurferData(varargin)
            %% PREPAREFREESURFERDATA prepares session-specific copies of data enumerated by this.freesurferData.
            %  @param named sessionData is an mlpipeline.{ISessionData,ImagingData}.
            %  @return 4dfp copies of this.freesurferData in sessionData.sessionPath.
            %  @return lst, a cell-array of fileprefixes for 4dfp objects created on the local filesystem.            
        
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData');
            parse(ip, varargin{:});            
            sess = ip.Results.sessionData;
            
            pwd0    = pushd(sess.sessionPath);
            fv      = mlfourdfp.FourdfpVisitor;
            fsd     = mlnipet.CommonTracerDirector.SURFER_OBJECTS;  
            safefsd = fsd; safefsd{5} = 'T1001';
            safefsd = fv.ensureSafeFileprefix(safefsd);
            lst     = cell(1, length(safefsd));
            sess    = ip.Results.sessionData;
            for f = 1:length(fsd)
                if (~fv.lexist_4dfp(fullfile(sess.sessionPath, safefsd{f})))
                    try
                        sess.mri_convert([fullfile(sess.mriLocation, fsd{f}) '.mgz'], [safefsd{f} '.nii.gz']);
                        ic2 = mlfourd.ImagingContext2([safefsd{f} '.nii.gz']);
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
            if (~isfolder(this.FAST_FILESYSTEM))
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
            if (~isfolder(this.FAST_FILESYSTEM))
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
        function fastFilesystemTeardownProject(this)
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
            this.builder_.deleteWorkFiles;
            this.builder_.markAsFinished;
        end
        function this = instanceConstructResolvedNAC(this)
            mlnipet.NipetBuilder.CreatePrototypeNAC(this.sessionData);
            try
                this = this.packageTracerResolvedR1;
            catch ME
                if (strcmp(ME.identifier, 'mlnipet:FileNotFoundError'))

                    %% recover umap, LM, norm folders from Converted-AC; e.g., after restarting from failure

                    sessd = this.sessionData;
                    sessd.attenuationCorrected = true;  
                    if isfolder(fullfile(sessd.scanPath, 'umap', ''))
                        movefile(fullfile(sessd.scanPath, 'umap', ''), this.sessionData.scanPath)                                                
                    end                  
                    if isfolder(fullfile(sessd.scanPath, 'LM', '')) && ...
                       isfolder(fullfile(sessd.scanPath, 'norm', ''))

                        movefile(fullfile(sessd.scanPath, 'LM', ''), this.sessionData.scanPath)
                        movefile(fullfile(sessd.scanPath, 'norm', ''), this.sessionData.scanPath)
                        this = this.packageTracerResolvedR1;
                    end
                else
                    rethrow(ME)
                end
            end                
            this.builder_ = this.builder_.prepareMprToAtlasT4;
            [this.builder_,epochs,reconstituted] = this.tryMotionCorrectFrames(this.builder_);          
            reconstituted = reconstituted.motionCorrectCTAndUmap;
            this.builder_ = reconstituted.motionUncorrectUmap(epochs);     
            this.builder_ = this.builder_.aufbauUmaps;     
            this.builder_.logger.save;
            if lstrfind(this.sessionData.reconstructionMethod, 'NiftyPET')
                p = this.addMirrorUmap(this.builder_.product, this.sessionData);
                p = this.flipKLUDGE____(p); % KLUDGE:  bug at interface with NIPET
                p.save;
            end
            this.builder_.deleteWorkFiles;
            this.builder_.markAsFinished;
        end
        function this = packageTracerResolvedR1(this)
            %% copies reduced-FOV NIfTI tracer images to this.sessionData.tracerLocation in 4dfp format.
            
            import mlfourd.*;
            assert(isfolder(this.outputDir));
            ensuredir(this.sessionData.tracerRevision('typ', 'path'));
            if lstrfind(this.sessionData.reconstructionMethod, 'NiftyPET')
                if (~lexist_4dfp(this.sessionData.tracerRevision('typ', 'fqfp')) || ...
                        this.sessionData.ignoreFinishMark)
                    ic2 = ImagingContext2(this.sessionData.tracerNipet('typ', '.nii.gz')); % e.g., fdg.nii.gz
                    ic2.addLog( ...
                        sprintf('mlraichle.TracerDirector2.packageTracerResolvedR1.sessionData.tracerListmodeDcm->%s', ...
                        this.sessionData.tracerListmodeDcm));
                    ic2 = this.flipKLUDGE____(ic2); % KLUDGE:  bug at interface with NIPET
                    ic2.saveas(this.sessionData.tracerRevision('typ', '.4dfp.hdr')); % e.g., fdgr1.nii.gz
                end
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
                    handwarning(ME, 'mlnipet:RuntimeError', 'CommonTracerDirector.tryMotionCorrectFrames');
%                    this.deleteEpochs__;
%                    this.builder_ = this.builder_.partitionMonolith;
%                    [this.builder_,epochs,reconstituted] = this.builder_.motionCorrectFrames;
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

