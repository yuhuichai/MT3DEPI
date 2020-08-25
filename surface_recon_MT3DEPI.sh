#!/bin/sh
# Yuhui Chai, postdoc in NIMH/NIH
# contact yhchai@outlook.com for any question

# data directory
dataDIR=/Volumes/Samsung_T5/MTEPI/200306COS_TUC.wholebrain/anat_soscomb.sft
# input file of the mt weighted EPI image
mt3depi=mean.sub_d_dant.nii

cd ${dataDIR}

# masked out the region outside of the brain, including the skull, brain_mask_mc.nii was mannually created
3dcalc -a mean.sub_d_dant.nii -b brain_mask_mc.nii -expr 'a*step(b)' \
	-prefix mean.sub_d_dant.masked.nii -overwrite

template=mean.sub_d_dant.masked.nii

DenoiseImage -d 3 -n Gaussian -i ${template} -o denoise.${template}

# signal intensity of the original mt weighted EPI image was in the range of 0 - 1, need to unifized before feeding to freesurfer
3dUnifize -input denoise.${template} -prefix uni.denoise.${template} -overwrite

# brain2epi.nii was the mp2rage coverted to epi space
3dUnifize -input brain2epi.nii -prefix uni.brain2epi.nii -overwrite

echo "++ add empty slices on each direction, make sure it matchs with align_anat2func"
3dZeropad -I 40 -S 40 -A 40 -P 40 -L 40 -R 40 -prefix pad0.uni.denoise.${template} uni.denoise.${template} -overwrite

# MT-3D-EPI didn't cover cerebellum. So we borrow it from mp2rage. Cerebellum is needed for the alignment during freesurfer surface recontruction
3dcalc -a pad0.uni.denoise.${template} -b uni.brain2epi.nii -expr "a+b*iszero(a)" \
	-prefix recon.${template} -overwrite

rm uni.brain2epi.nii uni.brain2epi.nii denoise.${template} uni.denoise.${template} pad0.uni.denoise.${template}

export SUBJECTS_DIR=${patDIR}

# A: If your skull-stripped volume does not have the cerebellum, then no. If it does, then yes, however you will have to run the data a bit differently.

# First you must run only -autorecon1 like this: 
# recon-all -autorecon1 -noskullstrip -s <subjid>
recon-all -i recon.${template} -subjid Surf -autorecon1 -noskullstrip -hires

echo "++ check alignment betw input and MNI"
tkregister2 --mgz --s Surf --fstal

#@# Nu Intensity Correction Sat Oct 26 12:25:45 EDT 2019
cd ${patDIR}/Surf/mri
mri_nu_correct.mni --i orig.mgz --o nu.mgz --uchar transforms/talairach.xfm --cm --n 2
mri_add_xform_to_header -c ${patDIR}/Surf/mri/transforms/talairach.xfm nu.mgz nu.mgz
#@# Intensity Normalization Sat Oct 26 12:30:07 EDT 2019
mri_normalize -g 1 -mprage -noconform nu.mgz T1.mgz


cd ${patDIR}
cp Surf/mri/T1.mgz Surf/mri/brainmask.auto.mgz
cp Surf/mri/T1.mgz Surf/mri/brainmask.mgz

# Then you will have to make a symbolic link or copy T1.mgz to brainmask.auto.mgz and a link from brainmask.auto.mgz to brainmask.mgz. 
# Finally, open this brainmask.mgz file and check that it looks okay 
# (there is no skull, cerebellum is intact; use the sample subject bert that comes with your FreeSurfer 
# installation to make sure it looks comparable). From there you can run the final stages of recon-all: 
# recon-all -autrecon2 -autorecon3 -s <subjid>
recon-all -s Surf -autorecon2 -autorecon3 -hires -parallel -openmp 3 #-xopts-overwrite -expert ${batchDir}/reconall.expert

# convert Surface file to volume space using AFNI SUMA
@SUMA_Make_Spec_FS -fspath Surf/surf -sid SUMA -NIFTI







