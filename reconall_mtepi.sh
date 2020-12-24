#!/bin/sh
dataDIR=/Volumes/VAPER/MTEPI/

cd ${dataDIR}

for patID in 200306wholebrain.Subj03.tutorial; do
{	
	echo "***************************** start with ${patID} *********************"
	patDIR=${dataDIR}/${patID}
	cd ${patDIR}

	if [ -f ${patDIR}/../brain_mask_comb_mc.nii ]; then
		epiMask=${patDIR}/../brain_mask_comb_mc.nii
	else
		epiMask=${patDIR}/../brain_mask_comb.nii
	fi

	3dcalc -a mean.sub_d_dant.nii -b ${epiMask} \
		-expr 'step(b)*a*step(a+0.1)*step(1-a)' \
		-prefix mean.sub_d_dant.masked.nii \
		-overwrite

	template=mean.sub_d_dant.masked.nii

	DenoiseImage -d 3 -n Gaussian -i ${template} -o denoise.${template}

	3dUnifize -input denoise.${template} -prefix uni.denoise.${template} -overwrite

	# brain2epi.nii is the registered MP2RAGE in EPI space, which is generated using script align_mp2rage2epi.sh
	3dUnifize -input brain2epi.nii -prefix uni.brain2epi.nii -overwrite

	echo "++ add empty slices on each direction, make sure it matchs with align_mp2rage2epi"
	3dZeropad -I 40 -S 40 -A 40 -P 40 -L 40 -R 40 -prefix pad0.uni.denoise.${template} uni.denoise.${template} -overwrite

	3dZeropad -I 40 -S 40 -A 40 -P 40 -L 40 -R 40 -prefix pad0.mean.sub_d_dant.nii mean.sub_d_dant.nii -overwrite

	3dcalc -a pad0.uni.denoise.${template} -b uni.brain2epi.nii -c pad0.mean.sub_d_dant.nii -expr "a+b*iszero(c)" \
		-prefix recon.${template} -overwrite

	rm uni.brain2epi.nii uni.brain2epi.nii denoise.${template} uni.denoise.${template} pad0.uni.denoise.${template} pad0.mean.sub_d_dant.nii

	export SUBJECTS_DIR=${patDIR}

	# A: If your skull-stripped volume does not have the cerebellum, then no. If it does, then yes, however you will have to run the data a bit differently.

	# First you must run only -autorecon1 like this: 
	# recon-all -autorecon1 -noskullstrip -s <subjid>
	recon-all -i recon.${template} -subjid Surf -autorecon1 -noskullstrip -hires

	echo "++ check alignment betw input and MNI"
	# tkregister2 --mgz --s Surf --fstal

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

	# recon-all -s Surf_denoise_copy -autorecon2-wm -autorecon3 -hires -parallel -openmp 3 -xopts-overwrite -expert ${batchDir}/reconall.expert

	@SUMA_Make_Spec_FS -fspath Surf/surf -sid SUMA -NIFTI

}
done
wait

# check reconstructed cortical surface in freeview
# freeview -v \
# Surf/mri/brainmask.mgz \
# Surf/mri/wm.mgz:colormap=heat:opacity=0.4:visible=0 \
# -f Surf/surf/lh.white:edgecolor=blue \
# Surf/surf/lh.pial:edgecolor=red \
# Surf/surf/rh.white:edgecolor=blue \
# Surf/surf/rh.pial:edgecolor=red


