These codes were used in the article of "A magnetization transfer weighted anatomical reference allows laminar analysis in native fMRI space". I am still working on it to make it friendly for a tutorial analysis.

1. prep.sh
   split original time series into control and MT-prepared
   generate mask for motion correction
   compute the MT weighted anatomical images after motion correction.
  
2. mc_run.m
   motion correction
  
3. surface_recon_MT3DEPI.sh
   surface reconstruction based on the MT weighted EPI images

4. layer_recon_MT3DEPI.sh
   cortical layer recontruction based on the cortical surface of the MT weighted EPI images
   
5. align_anat2func.sh
   alignment between MP2RAGE and MTw-EPI images
   This step is needed as MTw-EPI will borrow cerebellum from MP2RAGE for freesurfer (freesurfer only eats whole brain)
