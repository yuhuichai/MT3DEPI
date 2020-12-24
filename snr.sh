#!/bin/bash

# set data directories
top_dir=/Volumes/VAPER/MTEPI/

cd ${top_dir}
for patDir in 200306COS_TUC.wholebrain.Subj03.tutorial; do #  *.Subj*/anat*.sft *.Subj*/Wholebrain/anat*.sft
{
	
	echo "*********************************************************************************************"
	echo " start working in ${patDir} "
	echo "*********************************************************************************************"


	cd ${top_dir}/${patDir}

	# SNR after averaging across different measurement numbers
	for subj in sub_d_dant; do # rbold
	{	

		3dTcat -prefix all_runs.${subj}.nii ${subj}*nii -overwrite

		[ -f mean_gwmsubc_${subj}.1D ] && rm mean_gwmsubc_${subj}.1D
		[ -f std_gwmsubc_${subj}.1D ] && rm std_gwmsubc_${subj}.1D

		nVol=`3dinfo -nv all_runs.${subj}.nii`

		for vols0 in `seq 10 10 ${nVol}`; do # averaging across 10, 20, 30, 40, 50 measurements
		{
			let "vols1=${vols0}-1"
			3dTstat -overwrite -mean -prefix mean${vols0}.${subj}.odd.nii all_runs.$subj.nii"[0..${vols1}(2)]"
			3dTstat -overwrite -mean -prefix mean${vols0}.${subj}.even.nii all_runs.$subj.nii"[1..${vols1}(2)]"
			3dcalc -a mean${vols0}.${subj}.odd.nii -b mean${vols0}.${subj}.even.nii -expr "a-b" \
				-prefix mean${vols0}.${subj}.dif.nii -overwrite
			3dcalc -a mean${vols0}.${subj}.odd.nii -b mean${vols0}.${subj}.even.nii -expr "a+b" \
				-prefix mean${vols0}.${subj}.sum.nii -overwrite

			# ROI of gm_wm_subc_rb_upsamp_thr.nii has a matrix size same with scaledXYZ_mean.sub_d_dant.masked.nii
			# which are upsampled from the original mean.sub_d_dant.masked.nii
			3dresample -master scaledXYZ_mean.sub_d_dant.masked.nii -rmode NN -overwrite \
				-prefix scaledXYZ_mean${vols0}.${subj}.dif.nii -input mean${vols0}.${subj}.dif.nii
			3dresample -master scaledXYZ_mean.sub_d_dant.masked.nii -rmode NN -overwrite \
				-prefix scaledXYZ_mean${vols0}.${subj}.sum.nii -input mean${vols0}.${subj}.sum.nii

			3dROIstats -nomeanout -nzmean -quiet -mask gm_wm_subc_rb_upsamp_thr.nii scaledXYZ_mean${vols0}.${subj}.sum.nii \
				>> mean_gwmsubc_${subj}.1D
			3dROIstats -nomeanout -nzsigma -quiet -mask gm_wm_subc_rb_upsamp_thr.nii scaledXYZ_mean${vols0}.${subj}.dif.nii \
				>> std_gwmsubc_${subj}.1D

			rm scaledXYZ_mean${vols0}.${subj}.*.nii
		}&
		done
		wait

		# snr can be computed by mean_gwmsubc_${subj}.1D ./ std_gwmsubc_${subj}.1D
		3dcalc -a mean_gwmsubc_${subj}.1D\' -b std_gwmsubc_${subj}.1D\' -expr "a/b" -prefix rm.snr_gwmsubc_${subj}.1D -overwrite
		1dcat rm.snr_gwmsubc_${subj}.1D\' > snr_gwmsubc_${subj}.1D

		rm all_runs.${subj}.nii mean*.${subj}.odd.nii mean*.${subj}.even.nii mean*.${subj}.dif.nii mean*.${subj}.sum.nii rm.*

	}
	done
	wait



}
done
wait

