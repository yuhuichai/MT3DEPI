% this script reads the input nifti images for correction and feed them to the batch job of mc_job.m
% parameters for motion correction and estimation are adjusted in mc_job.m

clear;
close all;
batchDir='/Volumes/VAPER/MTEPI/batch';
subjDir='/Volumes/VAPER/MTEPI/200306wholebrain.Subj03.tutorial/';
folderList={'anat_wholebrain_mt.sft'};
% when mt-3d-epi and vaper-3d-epi were acquired together, then folderList={'wholebrain_mt.sft' 'wholebrain_vaper.sft'}; 

% prepare image runs for motion correction
image2mc=cell(1,100);
runIndex=0;
for folderIndex=1:length(folderList)
	cd([subjDir folderList{folderIndex}]);
	imageList=[dir('bold*.nii');dir('dant*.nii')];
	for imageIndex=1:length(imageList)
		runIndex=runIndex+1;
		image=rest_ReadNiftiImage(imageList(imageIndex).name);
		[~,~,~,vols]=size(image);
		image2mc{runIndex}=cell(vols,1);
		for volIndex=1:vols
			image2mc{runIndex}{volIndex}=[imageList(imageIndex).folder '/' imageList(imageIndex).name ',' num2str(volIndex)];
		end
	end
end
image2mc=image2mc(1:runIndex);

cd(batchDir);
mc_job; % load motion correction parameters

cd(subjDir);
matlabbatch{1}.spm.spatial.realign.estwrite.data=image2mc;

maskCell=cell(1,1);
if isfile('brain_mask_comb_mc.nii')
	maskCell{1}='brain_mask_comb_mc.nii,1';
else
	maskCell{1}='brain_mask_comb.nii,1';
end
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight=maskCell;

save('mc.mat','matlabbatch');

spm('defaults','FMRI');
spm_jobman('initcfg');
spm_jobman('run',matlabbatch);




