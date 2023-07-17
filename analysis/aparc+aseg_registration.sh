#!/bin/bash
#
# purpose: register given aparc.aseg.mgz files to given functional day to later use for ROIs
# For given subject, will go through their fmriprep folder to register for each day, 
# saving in that day's func folder

set -e

# load in project variables
source ../preprocessing/globals.sh
register_new_subject=1
make_amygdala=1


for subjectNumber in  "1" ; do
SUBJECT=sub-$(printf "%03d" $subjectNumber)
echo $SUBJECT
FREESURFER_DIR=$bids_dir/derivatives/freesurfer/$SUBJECT/mri

for sessionNumber in `seq 1`; do
SES=ses-$(printf "%02d" $sessionNumber)
echo $SES
# BOLD_DIR is where the fmriprep outputs functional images
BOLD_DIR=$bids_dir/derivatives/fmriprep/${SUBJECT}/${SES}/func
# BOLD_EX is going to be your example functional file
BOLD_EX=$BOLD_DIR/${SUBJECT}_${SES}_task-faces_run-01_bold_space-T1w_preproc.nii.gz
# MASK_EX is going to be your brainmask that fmriprep gives you
MASK_EX=$BOLD_DIR/${SUBJECT}_${SES}_task-faces_run-01_bold_space-T1w_brainmask.nii.gz

# run this once for each new subject
if [ $register_new_subject -eq 1 ]
then
    # make example functional if you didn't get one from fmriprep
    fslmaths $BOLD_EX -Tmean -mas $MASK_EX $BOLD_DIR/fmriprep_BOLD_T1w_preproc_Tmean.nii.gz
    # now convert from .nii data type to .mgz
    mri_convert $BOLD_DIR/fmriprep_BOLD_T1w_preproc_Tmean.nii.gz $BOLD_DIR/fmriprep_BOLD_T1w_preproc_Tmean.mgz
    # now register aparc+asec (old & new) to T1w space/BOLD resolution
    mri_label2vol --seg $FREESURFER_DIR/aparc+aseg.mgz --temp $BOLD_DIR/fmriprep_BOLD_T1w_preproc_Tmean.mgz \
        --o $BOLD_DIR/aparc+aseg-in-BOLD.nii.gz --fillthresh 0.5 --regheader $FREESURFER_DIR/aparc+aseg.mgz
    mri_label2vol --seg $FREESURFER_DIR/aparc.a2009s+aseg.mgz --temp $BOLD_DIR/fmriprep_BOLD_T1w_preproc_Tmean.mgz \
        --o $BOLD_DIR/aparc.a2009+aseg-in-BOLD.nii.gz --fillthresh 0.5 --regheader $FREESURFER_DIR/aparc.a2009s+aseg.mgz
fi
# check registration - compare this version with what fmriprep gives you
#fslview $BOLD_DIR/aparc+aseg-in-BOLD.nii.gz $BOLD_DIR/${SUBJECT}_${SES}_task-faces_run-01_bold_space-T1w_label-aparcaseg_roi.nii.gz

# for amygdala masks use FSL to extract from the segmentation values notes for the L/R amygdala:
if [ $make_amygdala -eq 1 ]
then
    fslmaths $BOLD_DIR/aparc+aseg-in-BOLD.nii.gz -thr 18 -uthr 18 -bin $BOLD_DIR/LAMYG.nii.gz
    fslmaths $BOLD_DIR/aparc+aseg-in-BOLD.nii.gz  -thr 54 -uthr 54 -bin $BOLD_DIR/RAMYG.nii.gz
    fslmaths $BOLD_DIR/LAMYG.nii.gz -add $BOLD_DIR/RAMYG.nii.gz -bin $BOLD_DIR/AMYG.nii.gz
fi

done
done

