#!/bin/bash

dataDir=/Volumes/Samsung_T5/MTEPI/

cd ${dataDir}
for subj in *.wholebrain/anat_soscomb.sft; do
{
	subjDir=${dataDir}/${subj}
	cd ${subjDir}
	# epi=${subjDir}/anat_wholebrain_mt_tau300us_factrl27_dant24.sft/denoise.uni.mean.sub_d_dant.masked.nii
	epi=${subjDir}/anat_wholebrain_mt_tau300us_factrl27_dant24.sft/mean.sub_d_dant.masked.denoised.nii

	if [ -f ${subjDir}/brain_mask_comb_mc.nii ]; then
		epiMask=${subjDir}/brain_mask_comb_mc.nii
	else
		epiMask=${subjDir}/brain_mask_comb.nii
	fi

	if [ ! -f ${epi} ]; then
		3dcalc -a ${subjDir}/anat_wholebrain_mt_tau300us_factrl27_dant24.sft/mean.sub_d_dant.nii \
			-b ${epiMask} -expr 'step(b)*a' \
			-prefix ${subjDir}/anat_wholebrain_mt_tau300us_factrl27_dant24.sft/mean.sub_d_dant.masked.nii \
			-overwrite

		DenoiseImage -d 3 -n Rician -i ${subjDir}/anat_wholebrain_mt_tau300us_factrl27_dant24.sft/mean.sub_d_dant.masked.nii \
			-o ${subjDir}/anat_wholebrain_mt_tau300us_factrl27_dant24.sft/mean.sub_d_dant.masked.denoised.nii
	fi

	transformFile=${subjDir}/anat_wholebrain_mt_tau300us_factrl27_dant24.sft/manual_align.txt
	outDir=${subjDir}/anat*.sft

	brainDir=${dataDir}/brain_C_T
	brain=${brainDir}/brain.nii

	echo "*************** 1st step: manual alignment, save transform file ***************"

	antsApplyTransforms --interpolation BSpline[5] -d 3 -i ${epi} \
		-r ${brain} -t ${transformFile} -o ${outDir}/anat2brain_manual_aligned.nii

	3dAutomask -overwrite -prefix ${outDir}/mask.anat2brain_manual_aligned.nii -dilate 10 ${outDir}/anat2brain_manual_aligned.nii

	brainMask=${subjDir}/anat_wholebrain_mt_tau300us_factrl27_dant24.sft/mask.anat2brain_manual_aligned.nii

	echo "*************** 2nd step: antsRegistration with manual transform file ***************"

	cd ${outDir}

	echo "***********************************************************************************"
	echo " antsRegister sub_d_dant for ${subj} "
	echo "***********************************************************************************"

	antsRegistration \
		--verbose 1 \
		--dimensionality 3 \
		--float 1 \
		--output [registered_,WarpedDenoise.nii,InverseWarpedDenoise.nii] \
		--interpolation BSpline[5] \
		--use-histogram-matching 1 \
		--winsorize-image-intensities [0.005,0.995] \
		--initial-moving-transform ${transformFile} \
		--transform Rigid[0.05] \
		--metric MI[${brain},${epi},1,32,Regular,0.25] \
	    --convergence [1000x1000x1000x1000,1e-6,10] \
	    --shrink-factors 8x4x2x1 \
	    --smoothing-sigmas 3x2x1x0vox \
	    --masks [${brainMask},${epiMask}] \
		--transform Affine[0.05] \
		--metric MI[${brain},${epi},1,32,Regular,0.25] \
		--convergence [1000x1000x1000x1000,1e-6,10] \
	    --shrink-factors 8x4x2x1 \
	    --smoothing-sigmas 3x2x1x0vox \
		--masks [${brainMask},${epiMask}] \
		--transform SyN[0.1,3,0] \
		--metric CC[${brain},${epi},1,4] \
		--convergence [1000x1000x500,1e-6,10] \
		--shrink-factors 8x4x2 \
		--smoothing-sigmas 3x2x1vox \
		--masks [${brainMask},${epiMask}] \
	# # consider a mask for interested region, so the distortion correction will be focusing on the interested region, like visual cortex


	brain=${brainDir}/brain.nii


	# ############################################################
	echo "++ using ${brain} as reference leads to errors, so use it as initial point"
	antsApplyTransforms -d 3 -n BSpline[5] -i ${brain} \
		-o brain2epi.nii -t [registered_0GenericAffine.mat,1] \
		-t registered_1InverseWarp.nii.gz -r ${brain}

	template=mean.sub_d_dant.masked.nii

	DenoiseImage -d 3 -n Gaussian -i ${template} -o denoise.${template}

	3dUnifize -input denoise.${template} -prefix uni.denoise.${template} -overwrite

	3dUnifize -input brain2epi.nii -prefix uni.brain2epi.nii -overwrite

	echo "++ add empty slices on each direction"
	3dZeropad -I 40 -S 40 -A 40 -P 40 -L 40 -R 40 -prefix pad0.uni.denoise.${template} uni.denoise.${template} -overwrite

	3dresample -master pad0.uni.denoise.${template} -rmode Bk -overwrite -prefix resmp.uni.brain2epi.nii \
		-input uni.brain2epi.nii

	3dcalc -a pad0.uni.denoise.${template} -b resmp.uni.brain2epi.nii -expr "a+b*iszero(a)" \
		-prefix recon4ref.${template} -overwrite

	rm resmp.uni.brain2epi.nii uni.brain2epi.nii denoise.${template} uni.denoise.${template} pad0.uni.denoise.${template}

	antsApplyTransforms -d 3 -n BSpline[5] -i ${brain} \
		-o brain2epi.nii -t [registered_0GenericAffine.mat,1] \
		-t registered_1InverseWarp.nii.gz -r recon4ref.${template}
	# ############################################################

}&
done
wait



