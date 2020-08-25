#!/bin/bash
# this code should run after surface_recon
# Yuhui Chai, postdoc in NIMH/NIH
# contact yhchai@outlook.com for any question

# data directory
dataDIR=/Volumes/Samsung_T5/MTEPI/200306COS_TUC.wholebrain/anat_soscomb.sft
# input file of the mt weighted EPI image
mt3depi=mean.sub_d_dant.nii

# 1. go to the directory of suma folder, which is the results folder of "@SUMA_Make_Spec_FS -fspath Surf/surf -sid SUMA -NIFTI"
sumaDir=${top_dir}/${patDir}/SUMA
cd ${sumaDir}

# take use of gm, wm, all mask generated by freesurfer
3dcalc -a aparc+aseg_REN_gm.nii.gz -expr "step(a-45)*1000" \
	-prefix gm_boosted.nii -overwrite
3dcalc -a aparc+aseg_REN_wmat.nii.gz -expr "step(a)*1000" \
	-prefix wm_boosted.nii -overwrite
3dcalc -a aparc+aseg_REN_all.nii.gz -expr "step(a)*1000" \
	-prefix all_boosted.nii -overwrite

# 2. go to the directory having mt weighted epi images
cd ${dataDIR}

template=mean.sub_d_dant.masked.nii # original mt weighted anatomical image

delta_x=$(3dinfo -adi $template)
delta_y=$(3dinfo -adj $template)
delta_z=$(3dinfo -adk $template)
sdelta_x=$(echo "(($delta_x / 4))"|bc -l)
sdelta_y=$(echo "(($delta_x / 4))"|bc -l)
sdelta_z=$(echo "(($delta_z / 4))"|bc -l) # here I only upscale in 2 dimensions.

echo "************** upscale by factor of 4 ******************"
3dresample -dxyz $sdelta_x $sdelta_y $sdelta_z -rmode NN -overwrite -prefix scaledXYZ_$template -input $template

# upsample gm, wm, all mask in the same way
3dresample -master scaledXYZ_mean.sub_d_dant.masked.nii -rmode NN \
	-overwrite -prefix gm_upsamp.nii -input ${sumaDir}/gm_boosted.nii

3dresample -master scaledXYZ_mean.sub_d_dant.masked.nii -rmode NN \
	-overwrite -prefix wm_upsamp.nii -input ${sumaDir}/wm_boosted.nii

3dresample -master scaledXYZ_mean.sub_d_dant.masked.nii -rmode NN \
	-overwrite -prefix all_upsamp.nii -input ${sumaDir}/all_boosted.nii

3dresample -master scaledXYZ_mean.sub_d_dant.masked.nii -rmode NN \
	-overwrite -prefix brain_upsamp.nii -input ${sumaDir}/brain.nii

3dcalc -a wm_upsamp.nii -expr "step(a-500)" \
	-prefix wm_upsamp_thr.nii -overwrite
3dcalc -a all_upsamp.nii -expr "step(a-500)" \
	-prefix all_upsamp_thr.nii -overwrite
3dcalc -a gm_upsamp.nii -expr "step(a-200)" \
	-prefix gm_upsamp_thr.nii -overwrite

# 3. extract pial and wm boundaries through dilating and eroding gm and wm masks
3dmask_tool -dilate_inputs 1 -prefix gm_upsamp_thr_d1.nii -overwrite -inputs gm_upsamp_thr.nii

# extract white matter edge
3dmask_tool -dilate_inputs -1 -prefix wm_upsamp_thr_e1.nii -overwrite -inputs wm_upsamp_thr.nii
3dcalc -a wm_upsamp_thr.nii -b wm_upsamp_thr_e1.nii  -c gm_upsamp_thr_d1.nii -expr '(step(a)-step(b))*step(c)' \
	-prefix wm_upsamp_edge.nii -overwrite

# extract csf edge
3dmask_tool -dilate_inputs 1 -prefix all_upsamp_thr_d1.nii -overwrite -inputs all_upsamp_thr.nii
3dcalc -a all_upsamp_thr.nii -b all_upsamp_thr_d1.nii -c gm_upsamp_thr_d1.nii -expr '(step(b)-step(a))*step(c)' \
	-prefix all_upsamp_edge.nii -overwrite

# generate cortical layermask
3dcalc -a all_upsamp_edge.nii -b wm_upsamp_edge.nii -c gm_upsamp_thr.nii \
	-expr "(step(a)+2*step(b)+3*step(c)*iszero(a+b))" \
	-prefix LayerMask4smooth.nii -overwrite

rm *thr_d* *thr_e* csfMask.nii wmMask.nii *edge*.nii *upsamp.nii *upsamp_thr.nii

echo "************** grow cortical layers with RENZO's program ******************"
3dcalc -a LayerMask4smooth.nii -expr a -datum short -overwrite -prefix sht_LayerMask4smooth.nii

# input for LN_GROW_LAYERS always needs to be in datatype SHORT
LN_GROW_LAYERS -rim sht_LayerMask4smooth.nii -threeD
mv layers.nii layers3D_4smooth.nii
rm sht_LayerMask4smooth.nii


