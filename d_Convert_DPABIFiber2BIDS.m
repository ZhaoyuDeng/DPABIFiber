function SubjectID_BIDS = d_Convert_DPABIFiber2BIDS(InDir, OutDir, Cfg)
% Convert DPABI_Inputpreparer out format DTIImg to BIDS data structure

% Written by Zhaoyu Deng 220601. Refer to y_Convert_DPARSFA2BIDS.m
% dengzy@psych.ac.cn

disp('Converting DPABIFiber to BIDS structure...')

if ~isempty(InDir)
    Cfg.WorkingDir=InDir;
end

Cfg.SubjectNum=length(Cfg.SubjectID);

% Generate new subject ID
SubjectID_BIDS=cell(Cfg.SubjectNum,1);
for i=1:Cfg.SubjectNum
    Temp=strfind(Cfg.SubjectID{i},'sub-');
    if ~isempty(Temp)
        SubjectID_BIDS{i}=Cfg.SubjectID{i};
    else
        TempStr=Cfg.SubjectID{i};
        Temp=strfind(TempStr,'-');
        TempStr(Temp)=[];
        Temp=strfind(TempStr,'_');
        TempStr(Temp)=[];
        SubjectID_BIDS{i}=['sub-',TempStr];
    end
end

% Write the ID
fid = fopen([Cfg.WorkingDir,filesep,'SubjectID_DPABIFiber2BIDS.tsv'],'w');
fprintf(fid,'SubjectID_BIDS');
fprintf(fid,['\t','SubjectID_Original']);
fprintf(fid,'\n');
for i=1:Cfg.SubjectNum
    fprintf(fid,'%s',SubjectID_BIDS{i});
    fprintf(fid,'\t%s',Cfg.SubjectID{i});
    fprintf(fid,'\n');
end
fclose(fid);

% Only consider single session data
for i=1:length(SubjectID_BIDS)
    %Dealing with anatomical data
    mkdir([OutDir,filesep,SubjectID_BIDS{i},filesep,'anat']);
    %First check T1w image started with co (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum)
    DirImg=dir([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,'c*.img']);
    if ~isempty(DirImg)
        [Data, Header]=y_Read([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,DirImg(1).name]);
        y_Write(Data,Header,[OutDir,filesep,SubjectID_BIDS{i},filesep,'anat',filesep,SubjectID_BIDS{i},'_T1w.nii'])
    else
        DirImg=dir([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,'c*.nii.gz']);
        if ~isempty(DirImg)
            copyfile([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,DirImg(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'anat',filesep,SubjectID_BIDS{i},'_T1w.nii.gz'])
        else
            DirImg=dir([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,'c*.nii']);
            if ~isempty(DirImg)
                copyfile([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,DirImg(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'anat',filesep,SubjectID_BIDS{i},'_T1w.nii'])
            else
                DirImg=dir([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,'*Crop*.nii']); %YAN Chao-Gan, 191121. For BIDS format. Change searching c* to *Crop*
                if ~isempty(DirImg)
                    copyfile([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,DirImg(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'anat',filesep,SubjectID_BIDS{i},'_T1w.nii'])
                end
            end
        end
    end

    %If there is no co* T1w images
    if isempty(DirImg)
        DirImg=dir([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,'*.img']);
        if ~isempty(DirImg)
            [Data, Header]=y_Read([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,DirImg(1).name]);
            y_Write(Data,Header,[OutDir,filesep,SubjectID_BIDS{i},filesep,'anat',filesep,SubjectID_BIDS{i},'_T1w.nii'])
        else
            DirImg=dir([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,'*.nii.gz']);
            if ~isempty(DirImg)
                copyfile([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,DirImg(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'anat',filesep,SubjectID_BIDS{i},'_T1w.nii.gz'])
            else
                DirImg=dir([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,'*.nii']);
                if ~isempty(DirImg)
                    copyfile([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,DirImg(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'anat',filesep,SubjectID_BIDS{i},'_T1w.nii'])
                end
            end
        end
    end

    DirJSON=dir([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,'*.json']); %YAN Chao-Gan, 191121. For BIDS format. Copy JSON
    if ~isempty(DirJSON)
        copyfile([Cfg.WorkingDir,filesep,'T1Img',filesep,Cfg.SubjectID{i},filesep,DirJSON(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'anat',filesep,SubjectID_BIDS{i},'_T1w.json'])
    end
    
    %Dealing with diffusion weighted data
    mkdir([OutDir,filesep,SubjectID_BIDS{i},filesep,'dwi'])
    DirImg=dir([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,'*.img']);
    DirNii=dir([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,'*.nii']);
    DirNiiGZ=dir([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,'*.nii.gz']);
    if ~isempty(DirImg) || length(DirNii)>=2  || length(DirNiiGZ)>=2
        [Data,~,~, Header] =y_ReadAll([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i}]);
        y_Write(Data,Header,[OutDir,filesep,SubjectID_BIDS{i},filesep,'dwi',filesep,SubjectID_BIDS{i},'_dwi.nii']) % suffix dwi
    elseif length(DirNii)==1
        copyfile([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,DirNii(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'dwi',filesep,SubjectID_BIDS{i},'_dwi.nii'])
    elseif length(DirNiiGZ)==1
        copyfile([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,DirNiiGZ(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'dwi',filesep,SubjectID_BIDS{i},'_dwi.nii.gz'])
    end
    DirBval=dir([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,'*.bval']);
    DirBvec=dir([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,'*.bvec']);
    copyfile([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,DirBval(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'dwi',filesep,SubjectID_BIDS{i},'_dwi.bval'])
    copyfile([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,DirBvec(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'dwi',filesep,SubjectID_BIDS{i},'_dwi.bvec'])
    
    DirJSON=dir([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,'*.json']); %YAN Chao-Gan, 191121. For BIDS format. Copy JSON
    if ~isempty(DirJSON)
        copyfile([Cfg.WorkingDir,filesep,'DTIImg',filesep,Cfg.SubjectID{i},filesep,DirJSON(1).name],[OutDir,filesep,SubjectID_BIDS{i},filesep,'dwi',filesep,SubjectID_BIDS{i},'_dwi.json'])
    end
end

%Save JSON files
clear JSON
JSON.BIDSVersion='1.0.0';
JSON.Name='DPABIFiber2BIDS';
spm_jsonwrite([OutDir,filesep,'dataset_description.json'],JSON);
