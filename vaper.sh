# # !/bin/bash

top_dir=/Volumes/VAPER/MTEPI/ # replace with your own data directory
cd $top_dir

for patDir in 200306COS_TUC.wholebrain.Subj03.tutorial; do # replace with your own patient name
{
	cd ${top_dir}/${patDir}

	echo "*****************************************************************************************************"
	echo ++ start with ${patDir} 
	echo "*****************************************************************************************************"

	for runDir in anat_wholebrain_mt; do # also add wholebrain_vaper if functional measurement was conducted in the same session
	{	
		if [ -d ${top_dir}/${patDir}/${runDir} ]; then
			cd ${top_dir}/${patDir}/${runDir}

			run_dsets=($(ls -f rbold*.nii))
			run_num=${#run_dsets[@]}

			trdouble=`3dinfo -tr rbold1.nii`
			tr=`bc -l <<< "${trdouble}/2"`

			echo "******************** compute all kinds of contrast ***********************"
			for run in `seq 1 ${run_num}`; do 
			{ 	
				
				# convert short to float
				3dcalc -a rbold${run}.nii -expr "a" \
					-float -prefix rm.rbold${run}.nii
				mv rm.rbold${run}.nii rbold${run}.nii

				3dcalc -a rdant${run}.nii -expr "a" \
					-float -prefix rm.rdant${run}.nii
				mv rm.rdant${run}.nii rdant${run}.nii


				NumVolCtrl=`3dinfo -nv rbold${run}.nii`
				NumVolTagd=`3dinfo -nv rdant${run}.nii`

				if [ "$NumVolCtrl" -gt "$NumVolTagd" ]; then
					3dTcat -overwrite -prefix rm.rbold${run}.nii \
						rbold${run}.nii'[0..'`expr $NumVolCtrl - 2`']'
					mv rm.rbold${run}.nii rbold${run}.nii
				elif [ "$NumVolCtrl" -lt "$NumVolTagd" ]; then
					3dTcat -overwrite -prefix rm.rdant${run}.nii \
						rdant${run}.nii'[0..'`expr $NumVolTagd - 2`']'
					mv rm.rdant${run}.nii rdant${run}.nii
				fi
					
				echo "******************** (dant(n)+dant(n+1))/2*bold(n+1) ***********************"
				NumVol=`3dinfo -nv rbold${run}.nii`

				3dcalc -prefix rm.bold_mdant${run}_1vol.nii \
					-a rbold${run}.nii'[0]' \
					-b rdant${run}.nii'[0]' \
					-expr '(a-b)' -float -overwrite

				# Calculate all volumes after the first one
				3dcalc -prefix rm.bold_mdant${run}_othervols.nii \
					-a rdant${run}.nii'[0..'`expr $NumVol - 2`']' \
					-b rdant${run}.nii'[1..$]' \
					-c rbold${run}.nii'[1..$]' \
					-expr '(c-(a+b)/2)' -float -overwrite

				3dTcat -overwrite -prefix bold_mdant$run.nii rm.bold_mdant${run}_1vol.nii rm.bold_mdant${run}_othervols.nii
				3drefit -TR ${trdouble} bold_mdant$run.nii


				if [[ "$runDir" == *"vaper"* ]]; then
					3dcalc -prefix rm.sub_d_bold${run}_1vol.nii \
						-a rbold${run}.nii'[0]' \
						-b rdant${run}.nii'[0]' \
						-expr '(a-b)/a' -float -overwrite

					3dcalc -prefix rm.sub_d_bold${run}_othervols.nii \
						-a rdant${run}.nii'[0..'`expr $NumVol - 2`']' \
						-b rdant${run}.nii'[1..$]' \
						-c rbold${run}.nii'[1..$]' \
						-expr '(c-(a+b)/2)/c' -float -overwrite

					3dTcat -overwrite -prefix sub_d_bold$run.nii rm.sub_d_bold${run}_1vol.nii rm.sub_d_bold${run}_othervols.nii
					3drefit -TR ${trdouble} sub_d_bold$run.nii
				fi

				if [[ "$runDir" == *"mt"* ]]; then
					3dcalc -prefix rm.sub_d_dant${run}_1vol.nii \
						-a rbold${run}.nii'[0]' \
						-b rdant${run}.nii'[0]' \
						-expr '(a-b)/b' -float -overwrite

					3dcalc -prefix rm.sub_d_dant${run}_othervols.nii \
						-a rdant${run}.nii'[0..'`expr $NumVol - 2`']' \
						-b rdant${run}.nii'[1..$]' \
						-c rbold${run}.nii'[1..$]' \
						-expr '(c-(a+b)/2)/((a+b)/2)' -float -overwrite

					3dTcat -overwrite -prefix sub_d_dant$run.nii rm.sub_d_dant${run}_1vol.nii rm.sub_d_dant${run}_othervols.nii
					3drefit -TR ${trdouble} sub_d_dant$run.nii
				fi
			}&
			done
			wait
			rm rm*

			if [[ "$runDir" == *"mt"* ]]; then
				subjList='rbold bold_mdant sub_d_dant'
			fi

			if [[ "$runDir" == *"vaper"* ]]; then
				subjList='rbold bold_mdant sub_d_bold'
			fi

			# censored TRs
			ktrs=`1d_tool.py -infile censor_combined.1D -show_trs_uncensored encoded`

			for subj in $subjList; do
			{	

				3dTcat -prefix all_runs.${subj}.nii ${subj}*nii -overwrite

				3dTstat -overwrite -mean -prefix mean.${subj}.nii all_runs.$subj.nii"[$ktrs]"

				3dcalc -a mean.${subj}.nii -b ../brain_mask_comb.nii -expr "a*step(b)" \
					-prefix mean.${subj}.masked.nii -overwrite

				DenoiseImage -d 3 -n Gaussian -i mean.${subj}.masked.nii -o mean.${subj}.masked.denoised.nii

				rm all_runs.${subj}.nii
			}&
			done
			wait
		fi
	}&
	done
	wait

}
done
wait
