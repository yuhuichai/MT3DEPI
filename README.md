These codes were used in the article of "Magnetization Transfer Weighted EPI Facilitates Cortical Depth Determination in Native fMRI Space". It used publicly available software packages, including AFNI, SPM, ANTs, FreeSurfer, and LAYNII. The data are available in https://osf.io/s4bqe/?view_only=dd8a1142ecd74d708526476b7776b717 

Authors: Yuhui Chai, Linqing Li, Yicun Wang, Laurentius Huber, Benedikt A. Poser, Jeff Duyn, Peter A. Bandettini

*Address correspondence to Dr. Yuhui Chai, Section on Functional Imaging Methods, Laboratory of Brain and Cognition, NIMH, NIH, Bethesda, MD 20892, USA. E-mail: yuhui.chai@nih.gov or yhchai@outlook.com


(1) Script used to split original time series into even (CTRL, can be treated as BOLD signal) and odd (DANTE-prepared images in functional runs, or MT-prepared in anatomical run) time points and create mask for motion correction: https://github.com/yuhuichai/MT3DEPI/blob/master/split_ctrl_dant.sh This script read the nifti images of all runs. It is writen in bash shell and depends on AFNI program (tested in AFNI_19.3.13). The run time is around several minutes.

(2) Script used for motion correction: https://github.com/yuhuichai/MT3DEPI/blob/master/mc_run.m This script read the all functional and anatomical runs, and replace the input in mc_job.m with these nifti names. It runs in MATLAB (tested in MATLAB R2016b) and depends on the SPM12 and REST (http://restfmri.net/forum/, tested with REST_V1.8_130615) package. The run time can be up to 2 hours or even more.

Motion correction was applied to the images of control and MT-prepared volumes in MT-3D-EPI imaging, together with the images of control and DANTE-prepared volumes in VAPER-3D-EPI imaging when functional measurements were conducted in the same session. This strategy of applying motion correction to all runs acquired by different sequences only work when an identical EPI acquisition was applied across all.

(3) Script used to censor time points whenever the Euclidean norm of the motion derivatives exceeded 0.4 mm or when at least 10% of image voxels were seen as outliers from the trend: https://github.com/yuhuichai/MT3DEPI/blob/master/motion_censor.sh It reads the motion parameters estimated by SPM12 in step 2, and runs AFNI programs as in bash shell. The run time is around 10 mins.

(4) The time series of MT-weighted anatomical images (e.g.,sub_d_dant1.nii) were generated via dynamic subtraction of the paired control and MT-prepared time points and further division by the MT-prepared images. VAPER time series (e.g.,sub_d_bold1.nii) were generated via dynamic subtraction of the paired control and DANTE-prepared time points and further division of the control. The mean MT-weighted anatomical images were further denoised using ANTs program DenoiseImage (output as mean.sub_d_dant.masked.denoised.nii) and then used for histogram analysis and cortical depth reconstruction. The script of this step is available in https://github.com/yuhuichai/MT3DEPI/blob/master/vaper.sh This script is writen in bash shell and depends on AFNI programs. The run time is around 10 mins.

(5) The script used to evaluate SNR of MT-weighted anatomical EPI image: https://github.com/yuhuichai/MT3DEPI/blob/master/snr.sh
The SNR was evaluated by averaging separately the even and odd numbered MT-weighted anatomical images in the time series (S_anat=(S_CTRL-S_MT)/S_MT ), and adding and subtracting these two average images to obtain sum and difference images. The SNR was calculated as the ratio of the mean value from a region-of-interest (ROI) in the sum image and the standard deviation in the same ROI in the difference image. This method has been used to calculate SNR of fMRI images (Glover and Lai, 1998; Kruger et al., 2001).

(6) The script used to do brain segmentation and cortical surface reconstruction: https://github.com/yuhuichai/MT3DEPI/blob/master/reconall_mtepi.sh
For the whole-brain MT-weighted EPI images, WM/GM segments and cortical surface were generated using FreeSurfer program recon-all. As the cerebellum was not included in our whole brain EPI coverage and it is needed for a proper atlas alignment in recon-all program, we added this missing part from the registered MP2RAGE image to MT-weighted EPI image. The cerebellum was not included in the resulted cortical surface and thus all cortical surface/depth related analysis in EPI space was solely based on EPI data. 

(7) The script used to grow cortical layers: https://github.com/yuhuichai/MT3DEPI/blob/master/layer_seg_MT3DEPI.sh
With the cortical surface automatically generated by FreeSurfer, we calculated cortical depths based on the equi-volume approach (Waehnert et al., 2014) using the LAYNII software suite (Huber et al., 2020) and divided the cortex into 20 equi-volume layers. Since a voxel in the acquired spatial resolution (0.8mm) can lie across several cortical depths, MT-weighted anatomical image was upsampled by a factor of 4 for the cortical layer reconstruction. The number of 20 layers was chosen in order to improve layer profile visualization and to minimize partial voluming between neighboring voxels (Huber et al., 2018). This layer computation was conducted in EPI volume space.

(8) The script used to register MP2RAGE into EPI space: To compare the image properties in identical brain regions, MP2RAGE was registered to MT-3D-EPI anatomical imaging using antsRegistration and the script is available in https://github.com/yuhuichai/MT3DEPI/blob/master/align_mp2rage2epi.sh.

(9) Protocol for whole-brain MT-3D-EPI: https://github.com/yuhuichai/MT3DEPI/blob/master/wholebrain_MT.pdf
Protocol for VAPER-3D-EPI in V1 layer fMRI experiment: https://github.com/yuhuichai/MT3DEPI/blob/master/VAPER_V1.pdf
