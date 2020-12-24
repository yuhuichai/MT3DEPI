# !/bin/bash

# set data directories
dataDir=/Volumes/VAPER/MTEPI/ # replace with your own data directory
cd ${dataDir}

for patDir in 200306COS_TUC.wholebrain.Subj03.tutorial; do # replace with your own patient name
{
	top_dir=${dataDir}/${patDir}
	echo "*****************************************************************************************************"
	echo ++ start with ${patDir} 
	echo "*****************************************************************************************************"
	for filePre in anat_wholebrain_mt; do # prefix name of all runs including anatomical and functional images
	{
		cd $top_dir/Func
		sl_dsets=($(ls -f *${filePre}*e00*.nii*)) # nii in short while nii.gz in float
		run_num=${#sl_dsets[@]}

		tr=`3dinfo -tr ${sl_dsets[0]}`
		echo "************** actual TR = ${tr}, changing with 3drefit -TR xx * ******************"
		trdouble=`bc -l <<< "2*$tr"`
		
		echo "*************** extract bold and dant images, skip first 2 time points ***************"
		run=0
		for img in ${sl_dsets[@]}; do
			let "run+=1"

			nVol=`3dinfo -nv ${img}`

			# 3dTcat -overwrite -prefix ${filePre}_bold${run}.nii ${img}'[2..'`expr $nVol - 3`'(2)]'
			3dTcat -overwrite -prefix ${filePre}_bold${run}.nii ${img}'[2..$(2)]'
			3drefit -TR ${trdouble} ${filePre}_bold${run}.nii

			3dTcat -overwrite -prefix ${filePre}_dant${run}.nii ${img}'[3..$(2)]'
			3drefit -TR ${trdouble} ${filePre}_dant${run}.nii
		done

		cd $top_dir
		[ ! -d ${filePre}.sft ] && mkdir ${filePre}.sft
		for run in `seq 1 ${run_num}`; do
		{
			mv $top_dir/Func/${filePre}_bold${run}.nii ${filePre}.sft/bold${run}.nii
			mv $top_dir/Func/${filePre}_dant${run}.nii ${filePre}.sft/dant${run}.nii
		}&
		done
		wait 

		# *****************************************************************************************************
		cd $top_dir/${filePre}.sft
		# *****************************************************************************************************

		echo "************** create mask for functional and anatomical runs ******************"
		for img in bold*nii dant*nii; do
		{
		    3drefit -duporigin bold1.nii ${img}
		    3dAutomask -prefix rm.mask_${img} ${img}
		}
		done
		wait
		# create union of inputs, output type is byte
		3dmask_tool -inputs rm.mask_* -union -prefix brain_mask.nii -overwrite
		rm rm.mask*

	}&
	done
	wait

	cd $top_dir

	echo "************** create combined mask for motion correction ******************"
	3dmask_tool -inputs *sft/brain_mask.nii -union -prefix brain_mask_comb.nii -overwrite
	echo "******************** do motion correction in spm ******************"

}&
done
wait

