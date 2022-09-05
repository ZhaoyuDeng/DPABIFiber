% preset for test
clear;clc;

WorkingDir = '/mnt/Data6/RfMRILab/Dengzhaoyu/Project_ASDSCZ/Analysis/AnalysisXiangYa';
freesurfer_license = '/mnt/Data6/RfMRILab/Dengzhaoyu/MATLAB/Toolbox/license.txt';
nthreads = 64;

% resolve subject ID
DirDCM=dir([WorkingDir,filesep,'T1Raw']);
if strcmpi(DirDCM(3).name,'.DS_Store')  %110908 YAN Chao-Gan, for MAC OS compatablie
    StartIndex=4;
else
    StartIndex=3;
end
SubjectID = {dir([WorkingDir,filesep,'T1Raw']).name}'; 
SubjectID = SubjectID(StartIndex:end);
Cfg.SubjectID = SubjectID;
SubjectNum = length(SubjectID);

%% Convert T1 & DTI DICOM to NIfTI

%Convert T1 DICOM files to NIFTI images
cd([WorkingDir,filesep,'T1Raw']);
for i=1:SubjectNum
    OutputDir=[WorkingDir,filesep,'T1Img',filesep,SubjectID{i}];
    mkdir(OutputDir);
    DirDCM=dir([WorkingDir,filesep,'T1Raw',filesep,SubjectID{i},filesep,'*']); %Revised by YAN Chao-Gan 100130. 
    if strcmpi(DirDCM(3).name,'.DS_Store')  %110908 YAN Chao-Gan, for MAC OS compatablie
        StartIndex=4;
    else
        StartIndex=3;
    end
    InputFilename=[WorkingDir,filesep,'T1Raw',filesep,SubjectID{i},filesep,DirDCM(StartIndex).name];
    %YAN Chao-Gan 120817.
    y_Call_dcm2nii(InputFilename, OutputDir, 'DefaultINI');
    fprintf(['Converting T1 Images:',SubjectID{i},' OK']);
end
fprintf('\n');

%Convert DTI DICOM files to NIFTI images
cd([WorkingDir,filesep,'DTIRaw']);
for i=1:SubjectNum
    OutputDir=[WorkingDir,filesep,'DTIImg',filesep,SubjectID{i}];
    mkdir(OutputDir);
    DirDCM=dir([WorkingDir,filesep,'DTIRaw',filesep,SubjectID{i},filesep,'*']); %Revised by YAN Chao-Gan 100130. 
    if strcmpi(DirDCM(3).name,'.DS_Store')  %110908 YAN Chao-Gan, for MAC OS compatablie
        StartIndex=4;
    else
        StartIndex=3;
    end
    InputFilename=[WorkingDir,filesep,'DTIRaw',filesep,SubjectID{i},filesep,DirDCM(StartIndex).name];
    %YAN Chao-Gan 120817.
    y_Call_dcm2nii(InputFilename, OutputDir, 'DefaultINI');
    fprintf(['Converting DTI Images:',SubjectID{i},' OK']);
end
fprintf('\n');

cd(WorkingDir);

%% Convert DPABI structure to BIDS structure

SubjectID_BIDS = d_Convert_DPABIFiber2BIDS(WorkingDir, [WorkingDir,filesep,'BIDS'], Cfg);

% DPARSFA2BIDS = readcell([working_dir,filesep,'SubjectID_DPABIFiber2BIDS.tsv'],'FileType','text');
% Cfg.SubjectID_BIDS = DPARSFA2BIDS(2:end,1);

%% run qsiprep & qsirecon seperately
t_qsiprep_start = tic;
qsiprepCMD = sprintf('docker run -ti --rm -v %s:/data:ro -v %s:/out -v %s:/opt/freesurfer/license.txt pennbbl/qsiprep --nthreads 16 --omp-nthreads 1 --low-mem --output-resolution 2 /data /out participant',[WorkingDir,'/BIDS'],WorkingDir,freesurfer_license);
system(qsiprepCMD);
t_qsiprep = toc(t_qsiprep_start);
%%
% parpool
t_qsirecon_start = tic;
qsireconCMD = sprintf('docker run -ti --rm -v /mnt/Data6/RfMRILab/Dengzhaoyu/Project_ASDSCZ/Analysis/AnalysisXiangYa/tmp/:/tmp -v %s:/data:ro -v %s:/out -v %s:/opt/freesurfer/license.txt -v %s:/qsiprep pennbbl/qsiprep --nthreads 16 --omp-nthreads 1 --low-mem --recon-only --recon_spec mrtrix_singleshell_ss3t_noACT --recon-input /qsiprep --output-resolution 2 --resource-monitor /data /out participant',[WorkingDir,'/BIDS'],WorkingDir,freesurfer_license,[WorkingDir,'/qsiprep']);
system(qsireconCMD);
t_qsirecon = toc(t_qsirecon_start);

%% generate a mif 3D colored tractography map 

parfor k = length(SubjectID_BIDS)
    Command = sprintf('docker run -ti --rm -v %s/qsirecon/%s:/data mrtrix3/mrtrix3 tckmap -dec -vox 1 /data/dwi/%s_space-T1w_desc-preproc_desc-tracks_ifod2.tck /data/figures/track-weight_3D_color_image.mif',WorkingDir,SubjectID_BIDS{k},SubjectID_BIDS{k});
    system(Command);
end